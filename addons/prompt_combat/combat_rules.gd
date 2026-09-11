extends RefCounted
## Probability policy extracted from a turn-based combat runtime; no encounter-specific overrides.
var damage_min := 2
var damage_max := 7
var attack_pressure := 0.0
var failure_bonus := 0
var maximum_adjusted_rate := 99
var rng := RandomNumberGenerator.new()

func attack_favored_rate(raw_rate: int) -> int:
	var p := clampf(float(raw_rate) / 100.0, 0.0, 1.0)
	p += attack_pressure * p * (1.0 - p)
	return clampi(roundi(p * 100.0), 0, 100)

func effective_rate(rate: int, streak: int) -> int:
	if rate <= 0 or rate >= 100: return clampi(rate, 0, 100)
	return mini(rate + maxi(0, failure_bonus) * maxi(0, streak), maximum_adjusted_rate)

func resolve(raw_rate: int, streak: int) -> Dictionary:
	var favored := attack_favored_rate(raw_rate)
	var effective := effective_rate(favored, streak)
	var roll := rng.randi_range(1, 100)
	return {"raw_rate": clampi(raw_rate, 0, 100), "effective_rate": effective, "roll": roll, "hit": roll <= effective}
