extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var combat = preload("res://addons/prompt_combat/combat_session.gd").new()
	root.add_child(combat)
	combat.configure({"id": "sparrer_a", "hp": 10}, {"id": "sparrer_b", "hp": 10})
	combat.pipeline.judge = func(_system, _messages, kind):
		if kind == "damage": return {"action": "A quick feint", "dmg": 3, "dmg_spans": ["feint"]}
		return {"success_rate": 100, "cot": "Deterministic demonstration"}
	await combat.submit_attack("A quick feint")
	print(JSON.stringify(await combat.submit_defense("Step aside")))
	combat.free()
	quit()
