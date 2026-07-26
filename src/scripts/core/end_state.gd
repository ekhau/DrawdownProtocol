class_name EndState
## Step 8: pure end-state evaluator with reason codes.
## Spec: docs/Phase_4/05_End_State_Evaluator.md.

enum RunStatus {
	RUNNING,               # no terminal condition
	LOSS_LIMIT_BREACHED,   # T >= 2.0 C - the hard loss, any year
	WIN_NEUTRAL,           # year == 2100 and N <= 0 - carbon-neutral world
	LOSS_NOT_NEUTRAL,      # year == 2100 and N > 0 - survived, not neutral
}

const STATUS_STRINGS := {
	RunStatus.RUNNING: &"RUNNING",
	RunStatus.LOSS_LIMIT_BREACHED: &"LOSS_LIMIT_BREACHED",
	RunStatus.WIN_NEUTRAL: &"WIN_NEUTRAL",
	RunStatus.LOSS_NOT_NEUTRAL: &"LOSS_NOT_NEUTRAL",
}


static func evaluate(year: int, temp: float, n: float) -> RunStatus:
	if temp >= float(Tuning.c("T_LOSS")):        # precedence 1: the limit outranks the calendar
		return RunStatus.LOSS_LIMIT_BREACHED
	if year >= int(Tuning.c("END_YEAR")):
		return RunStatus.WIN_NEUTRAL if n <= 0.0 else RunStatus.LOSS_NOT_NEUTRAL
	return RunStatus.RUNNING


static func status_string(status: RunStatus) -> StringName:
	return STATUS_STRINGS[status]


## Knowledge Points award (Phase 1 formula, unchanged).
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
	return kp
