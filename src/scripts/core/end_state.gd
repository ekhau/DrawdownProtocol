class_name EndState
## Step 8: pure end-state evaluator with reason codes.
## Spec: docs/Phase_4/05_End_State_Evaluator.md.
##
## The race framing (climate clock as the adversary): victory is carbon
## neutrality (N <= 0) reached at ANY turn before the tipping point; defeat is
## the tipping point (+2.0 C = clock 100%), a revolt (happiness at 0), or
## reaching 2100 still net-positive.

enum RunStatus {
	RUNNING,               # no terminal condition
	LOSS_LIMIT_BREACHED,   # T >= 2.0 C - the tipping point, any turn
	LOSS_REVOLT,           # happiness <= 0 - the city rises, any turn
	WIN_NEUTRAL,           # N <= 0 - carbon neutrality before the tipping point
	LOSS_NOT_NEUTRAL,      # year >= 2100 and N > 0 - survived, not neutral
}

const STATUS_STRINGS := {
	RunStatus.RUNNING: &"RUNNING",
	RunStatus.LOSS_LIMIT_BREACHED: &"LOSS_LIMIT_BREACHED",
	RunStatus.LOSS_REVOLT: &"LOSS_REVOLT",
	RunStatus.WIN_NEUTRAL: &"WIN_NEUTRAL",
	RunStatus.LOSS_NOT_NEUTRAL: &"LOSS_NOT_NEUTRAL",
}


## Precedence: the tipping point outranks everything; a revolt outranks the
## win (a neutral world in open revolt is not a run you kept); the win
## outranks the calendar.
static func evaluate(year: int, temp: float, n: float, happiness: float = 100.0) -> RunStatus:
	if temp >= float(Tuning.c("T_LOSS")):
		return RunStatus.LOSS_LIMIT_BREACHED
	if happiness <= float(Tuning.s("H_REVOLT")):
		return RunStatus.LOSS_REVOLT
	if n <= 0.0:
		return RunStatus.WIN_NEUTRAL
	if year >= int(Tuning.c("END_YEAR")):
		return RunStatus.LOSS_NOT_NEUTRAL
	return RunStatus.RUNNING


static func status_string(status: RunStatus) -> StringName:
	return STATUS_STRINGS[status]


## Knowledge Points award. Every outcome - win or loss - pays at least
## KP_FLOOR: both ends of a run feed the meta (docs/Phase_4/05).
static func knowledge_points(status: RunStatus, year: int, sector_progresses: Array, allies: int) -> int:
	var start_year := int(Tuning.c("START_YEAR"))
	var end_year := int(Tuning.c("END_YEAR"))
	@warning_ignore("integer_division")
	var kp := (mini(year, end_year) - start_year) / 10  # integer division: decades survived
	for prog in sector_progresses:
		if float(prog) >= float(Tuning.s("KP_SECTOR_THRESHOLD")):
			kp += 1
	@warning_ignore("integer_division")
	kp += allies / 2
	if status == RunStatus.WIN_NEUTRAL:
		kp += int(Tuning.s("KP_WIN_BONUS"))
	return maxi(kp, int(Tuning.s("KP_FLOOR")))
