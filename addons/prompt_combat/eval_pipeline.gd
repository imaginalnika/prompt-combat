extends Node
## judge(system: String, messages: Array, kind: String) -> Dictionary, optionally async.
## Prompts, model transport, and participants are supplied by the host.
const Helpers = preload("evaluation_helpers.gd")
signal evaluation_started(kind: String)
signal evaluation_finished(kind: String, result: Dictionary)
var judge: Callable
var prompts := {
	"damage": "Evaluate an attempted action, not whether it succeeds. Return JSON: action (string), dmg (number), dmg_spans (exact substrings of action), cot (brief justification).",
	"rate": "Evaluate attack versus defense. Return JSON: success_rate (number 0-100), cot (brief justification). Do not swap the attack and defense.",
	"attack": "Propose one attempted combat action. Return JSON with an attack string. Do not declare its outcome.",
	"defense": "Propose a defense against the supplied attack. Return JSON with a defense string. Do not declare success or injury.",
	"reaction": "React briefly to the supplied resolved outcome without changing it. Return JSON with a reaction string."
}
var history: Dictionary = {}
var history_limit := 12
var timeout_seconds := 30.0
var damage_min := 2
var damage_max := 7
var _generation := 0

func cancel() -> void:
	_generation += 1

func reset() -> void:
	cancel()
	history.clear()

func evaluate_damage(action: String, actor: Dictionary) -> Dictionary:
	var result := await request("damage", {"attack_action": action, "attacker": actor})
	if result.is_empty() or not _numeric(result.get("dmg")): return {}
	var normalized_action := str(result.get("action", action)).strip_edges()
	if normalized_action == "": return {}
	return {"action": normalized_action, "dmg": clampi(int(result["dmg"]), damage_min, damage_max), "dmg_spans": Helpers.filter_spans(result.get("dmg_spans", []), normalized_action), "cot": str(result.get("cot", ""))}

func evaluate_rate(attack: String, defense: String, attacker: Dictionary, defender: Dictionary) -> Dictionary:
	var result := await request("rate", {"attack_action": attack, "defense_action": defense, "attacker": attacker, "defender": defender})
	if result.is_empty() or not _numeric(result.get("success_rate")): return {}
	return Helpers.normalize_rate_eval(result)

func generate_action(kind: String, context: Dictionary) -> String:
	if kind not in ["attack", "defense", "reaction"]: return ""
	var result := await request(kind, context)
	return str(result.get(kind, "")).strip_edges()

func request(kind: String, context: Dictionary) -> Dictionary:
	if not judge.is_valid() or not prompts.has(kind): return {}
	var generation := _generation
	var messages: Array = history.get(kind, []).duplicate(true)
	var user := {"role": "user", "content": JSON.stringify(context)}
	messages.append(user)
	var pending := {"done": false, "result": {}}
	evaluation_started.emit(kind)
	_invoke.call_deferred(kind, messages, pending)
	var start := Time.get_ticks_msec()
	while not pending["done"]:
		if generation != _generation or not is_inside_tree(): return {}
		if Time.get_ticks_msec() - start >= timeout_seconds * 1000: return {}
		await get_tree().process_frame
	if generation != _generation: return {}
	var result: Dictionary = pending["result"]
	if not result.is_empty():
		messages.append({"role": "assistant", "content": JSON.stringify(result)})
		while messages.size() > maxi(2, history_limit): messages.pop_front()
		if not messages.is_empty() and messages[0].get("role") == "assistant": messages.pop_front()
		history[kind] = messages
	evaluation_finished.emit(kind, result)
	return result

func _invoke(kind: String, messages: Array, pending: Dictionary) -> void:
	var result = await judge.call(str(prompts[kind]), messages, kind)
	pending["result"] = result if result is Dictionary else {}
	pending["done"] = true

func _numeric(value) -> bool:
	return (value is int or value is float or (value is String and value.is_valid_float())) and is_finite(float(value))
