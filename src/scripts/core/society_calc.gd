class_name SocietyCalc
## Steps 1, 5 and the derived-resilience formulas as pure functions.
## Spec: docs/Phase_4/04_Society_And_Resilience_Spec.md. Constants from
## data/society.json via Tuning.


## Yearly money income with happiness penalties (strongest penalty only).
## Returns { "amount": float, "penalty": StringName }.
static func income(h: float, allies: int) -> Dictionary:
	var base := float(Tuning.s("INCOME_BASE")) + float(Tuning.s("INCOME_PER_ALLY")) * allies
	var penalties: Array = Tuning.s("INCOME_PENALTIES")
	# Penalties are sorted ascending by threshold in data; first match wins.
	for p: Dictionary in penalties:
		if h < float(p["h_below"]):
			return {"amount": base * float(p["mult"]), "penalty": StringName(p["id"])}
	return {"amount": base, "penalty": &"none"}


static func influence_income(allies: int, media: bool) -> float:
	var gain := float(Tuning.s("INFLUENCE_BASE")) + float(Tuning.s("INFLUENCE_PER_ALLY")) * allies
	if media:
		gain += float(Tuning.s("INFLUENCE_MEDIA_BONUS"))
	return gain


## Step 5 drift: co-benefits of the transition minus Overshoot stress.
## Returns { "co_benefit": float, "stress": float }.
static func happiness_drift(avg_progress: float, warming_band: int) -> Dictionary:
	var co := float(Tuning.s("CO_BENEFIT_MAX")) * avg_progress / 100.0
	var stresses: Array = Tuning.s("OVERSHOOT_STRESS")
	return {"co_benefit": co, "stress": float(stresses[warming_band])}


## Derived resilience: never stored, never a loss condition.
static func resilience(h: float, adapt: float) -> float:
	return clampf(float(Tuning.s("RESILIENCE_H_FACTOR")) * h + adapt, 0.0, 100.0)


## Event damage multiplier; R = 100 halves damage.
static func damage_mult(h: float, adapt: float) -> float:
	return 1.0 - resilience(h, adapt) / float(Tuning.s("RESILIENCE_DAMAGE_DIVISOR"))


## Social crisis probability; formula parameters come from events.json.
static func social_crisis_p(h: float, warming_band: int, media: bool, formula: Dictionary) -> float:
	var base := float(formula["base"])
	if h < float(formula["happiness_threshold"]):
		base = float(formula["base_low_happiness"])
	var scales: Array = formula["band_scale"]
	var p := base * float(scales[warming_band])
	if media:
		p *= float(formula["media_multiplier"])
	return p
