extends Node
const State = preload("combat_state.gd")
const Rules = preload("combat_rules.gd")
const Pipeline = preload("eval_pipeline.gd")
enum Phase { UNCONFIGURED, ATTACK, EVALUATING_DAMAGE, DEFENSE, EVALUATING_RATE, FINISHED }
signal phase_changed(phase: int)
signal defense_requested(attack: Dictionary)
signal round_resolved(result: Dictionary)
signal combat_finished(winner: String)
signal evaluation_failed(stage: String)
var state = State.new()
var rules = Rules.new()
var pipeline = Pipeline.new()
var phase := Phase.UNCONFIGURED
var attack: Dictionary = {}
var _generation := 0

func _ready() -> void:
	add_child(pipeline)

func configure(first: Dictionary, second: Dictionary) -> bool:
	if not state.configure(first, second): return false
	_generation += 1
	pipeline.reset()
	attack.clear()
	_set_phase(Phase.ATTACK)
	return true

func submit_attack(text: String) -> bool:
	if phase != Phase.ATTACK or text.strip_edges() == "": return false
	var generation := _generation
	_set_phase(Phase.EVALUATING_DAMAGE)
	pipeline.damage_min = rules.damage_min
	pipeline.damage_max = rules.damage_max
	var result: Dictionary = await pipeline.evaluate_damage(text, state.fighters[state.attacker])
	if generation != _generation: return false
	if result.is_empty():
		_set_phase(Phase.ATTACK)
		evaluation_failed.emit("damage")
		return false
	attack = result
	_set_phase(Phase.DEFENSE)
	defense_requested.emit(attack.duplicate(true))
	return true

func submit_defense(text: String) -> Dictionary:
	if phase != Phase.DEFENSE: return {}
	var generation := _generation
	_set_phase(Phase.EVALUATING_RATE)
	var result: Dictionary = await pipeline.evaluate_rate(str(attack["action"]), text, state.fighters[state.attacker], state.fighters[1 - state.attacker])
	if generation != _generation: return {}
	if result.is_empty():
		_set_phase(Phase.DEFENSE)
		evaluation_failed.emit("rate")
		return {}
	var resolution: Dictionary = rules.resolve(int(result["success_rate"]), int(state.failures[state.attacker]))
	resolution.merge(state.apply(int(attack["dmg"]), resolution["hit"]))
	resolution["attack_action"] = attack["action"]
	resolution["defense_action"] = text
	resolution["dmg_spans"] = attack["dmg_spans"].duplicate()
	resolution["cot"] = str(result.get("cot", ""))
	resolution["state"] = state.snapshot()
	attack = {}
	_set_phase(Phase.FINISHED if resolution["finished"] else Phase.ATTACK)
	round_resolved.emit(resolution)
	if resolution["finished"]: combat_finished.emit(str(resolution["winner"]))
	return resolution

func generate_attack() -> bool:
	if phase != Phase.ATTACK: return false
	var generation := _generation
	_set_phase(Phase.EVALUATING_DAMAGE)
	var text: String = await pipeline.generate_action("attack", {"actor": state.fighters[state.attacker], "opponent": state.fighters[1 - state.attacker]})
	if generation != _generation: return false
	_set_phase(Phase.ATTACK)
	return await submit_attack(text)

func generate_defense() -> Dictionary:
	if phase != Phase.DEFENSE: return {}
	var generation := _generation
	_set_phase(Phase.EVALUATING_RATE)
	var text: String = await pipeline.generate_action("defense", {"attack_action": attack["action"], "actor": state.fighters[1 - state.attacker]})
	if generation != _generation: return {}
	_set_phase(Phase.DEFENSE)
	if text == "": return {}
	return await submit_defense(text)

func cancel() -> void:
	_generation += 1
	pipeline.cancel()
	if phase == Phase.EVALUATING_DAMAGE: _set_phase(Phase.ATTACK)
	elif phase == Phase.EVALUATING_RATE: _set_phase(Phase.DEFENSE)

func _set_phase(value: Phase) -> void:
	phase = value
	phase_changed.emit(value)
