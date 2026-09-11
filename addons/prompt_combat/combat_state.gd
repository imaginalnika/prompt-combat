extends RefCounted
var fighters: Array = []
var attacker := 0
var round_number := 1
var failures := [0, 0]

func configure(first: Dictionary, second: Dictionary) -> bool:
	if str(first.get("id", "")) == "" or str(second.get("id", "")) == "" or first["id"] == second["id"]: return false
	if int(first.get("hp", 0)) <= 0 or int(second.get("hp", 0)) <= 0: return false
	fighters = [first.duplicate(true), second.duplicate(true)]
	attacker = 0
	round_number = 1
	failures = [0, 0]
	return true

func apply(damage: int, hit: bool) -> Dictionary:
	var defender := 1 - attacker
	var applied := maxi(0, damage) if hit else 0
	fighters[defender]["hp"] = maxi(0, int(fighters[defender]["hp"]) - applied)
	failures[attacker] = 0 if hit else failures[attacker] + 1
	var finished := int(fighters[defender]["hp"]) <= 0
	var result := {"attacker": fighters[attacker]["id"], "defender": fighters[defender]["id"], "damage": applied, "finished": finished, "winner": fighters[attacker]["id"] if finished else ""}
	if not finished:
		attacker = defender
		round_number += 1
	return result

func snapshot() -> Dictionary:
	return {"fighters": fighters.duplicate(true), "attacker": attacker, "round": round_number, "failures": failures.duplicate()}
