class_name ClimateCalc
## Steps 3, 4 and 7 of the yearly pipeline as pure functions.
## Spec: docs/Phase_4/03_Climate_Calc_Spec.md. Constants come from
## data/climate.json via Tuning; no balance values live in this file.


## Warming band: 0 stable (< T_WARN), 1 Overshoot I, 2 Overshoot II (>= T_BAND2).
static func band(t: float) -> int:
	if t >= float(Tuning.c("T_BAND2")):
		return 2
	if t >= float(Tuning.c("T_WARN")):
		return 1
	return 0


## Yearly absorption decay from warming stress; reads LAST year's temperature.
static func sink_stress(t_prev: float) -> float:
	var stresses: Array = Tuning.c("SINK_STRESS")
	return float(stresses[band(t_prev)])


## Emissions of one sector given its base and transition progress (0..100).
static func sector_emissions(base: float, progress: float) -> float:
	var residual := float(Tuning.c("RESIDUAL"))
	return base * (1.0 - (1.0 - residual) * progress / 100.0)


## Gross emissions: fixed sector order + feedback extras.
## sectors: Dictionary[StringName -> Dictionary{base, progress}] or SectorState-like.
static func gross_emissions(bases: Array[float], progresses: Array[float], e_extra: float) -> float:
	var e := e_extra
	for i in bases.size():
		e += sector_emissions(bases[i], progresses[i])
	return e


static func net(e: float, a: float) -> float:
	return e - a


## Warming delta from net emissions (warming fast, cooling 4x slower).
static func warming_delta(n: float) -> float:
	if n > 0.0:
		return float(Tuning.c("K_WARM")) * n
	return float(Tuning.c("K_COOL")) * n


static func apply_warming(temp: float, n: float) -> float:
	return maxf(float(Tuning.c("T_FLOOR")), temp + warming_delta(n))


static func a_floor() -> float:
	return float(Tuning.c("A_FLOOR"))
