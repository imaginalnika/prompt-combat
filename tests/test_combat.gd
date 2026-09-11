extends SceneTree
var checks := 0
func check(value: bool, label: String) -> void:
	if not value:
		push_error(label)
		quit(1)
		assert(value, label)
	checks += 1

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var combat = preload("res://addons/prompt_combat/combat_session.gd").new()
	root.add_child(combat)
	check(combat.configure({"id": "a", "hp": 10}, {"id": "b", "hp": 10}), "configure neutral fighters")
	combat.pipeline.judge = func(_s, _m, kind):
		match kind:
			"damage": return {"action": "quick feint", "dmg": 3, "dmg_spans": ["feint", "not present", "feint"]}
			"rate": return {"success_rate": 100, "cot": "test"}
			"attack": return {"attack": "quick feint"}
			"defense": return {"defense": "step aside"}
		return {}
	check(await combat.submit_attack("quick feint"), "attack evaluation")
	check(combat.attack["dmg_spans"] == ["feint"], "span filtering")
	var resolved: Dictionary = await combat.submit_defense("step aside")
	check(resolved["hit"] and resolved["damage"] == 3, "damage resolved")
	check(combat.state.fighters[1]["hp"] == 7 and combat.state.attacker == 1, "counter turn")
	check(resolved["attack_action"] == "quick feint" and resolved["defense_action"] == "step aside", "ground truth actions preserved")
	check(await combat.generate_attack(), "generated counter attack")
	check(not (await combat.generate_defense()).is_empty(), "generated defense")
	var rules = combat.rules
	rules.failure_bonus = 15
	check(rules.effective_rate(50, 2) == 80, "failure streak bonus")
	for i in 100:
		check(not rules.resolve(0, 99)["hit"], "zero probability invariant")
		check(rules.resolve(100, 0)["hit"], "certain probability invariant")
	combat.pipeline.judge = func(_s, _m, _k): return {}
	check(not await combat.submit_attack("test"), "provider failure explicit")
	check(combat.phase == combat.Phase.ATTACK, "failure allows retry")
	combat.pipeline.judge = func(_s, _m, _k): return {"dmg": "not numeric"}
	check(not await combat.submit_attack("test"), "malformed damage rejected")
	var parser = preload("res://addons/prompt_combat/json_stream_parser.gd").new()
	var captured := {}
	parser.watch_string("action", func(_part): pass, func(value): captured["action"] = value)
	parser.watch_number("dmg", func(value): captured["dmg"] = value)
	parser.watch_array("dmg_spans", func(value): captured["spans"] = value)
	for character in '{"dmg":3,"action":"quick feint","dmg_spans":["feint"]}': parser.feed(character)
	parser.finish()
	check(captured.get("action") == "quick feint" and captured.get("dmg") == 3 and captured.get("spans") == ["feint"], "incremental JSON parsing")
	combat.free()
	print("PASS prompt-combat: %d checks" % checks)
	quit()
