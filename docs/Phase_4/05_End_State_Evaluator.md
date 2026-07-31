# End-State Evaluator — The Drawdown Protocol (Phase 4)

Step 8 of the pipeline. Plan.md's done criterion — "win/loss conditions always evaluate
correctly" — is met by making the evaluator a pure function with reason codes, called
exactly once per resolved turn, with a truth table small enough to test exhaustively.
The race framing: the climate clock is the adversary — victory is carbon neutrality
reached at **any** turn before the tipping point, not a 2100 finish-line check.

## Reason codes

```gdscript
enum RunStatus {
    RUNNING,              # no terminal condition
    LOSS_LIMIT_BREACHED,  # T >= 2.0 °C — the tipping point (clock 100%), any turn
    LOSS_REVOLT,          # happiness <= 0 — the city rises, any turn
    WIN_NEUTRAL,          # N <= 0 — neutrality before the tipping point, any turn
    LOSS_NOT_NEUTRAL,     # year >= 2100 and N > 0 — survived, not neutral (soft loss)
}
```

Codes are serialized as stable strings (`"LOSS_LIMIT_BREACHED"`, ...) in TurnRecords and
CSV — analytics depend on them never being renamed (golden rule 13).

## Evaluation function

```gdscript
static func evaluate(year: int, temp: float, n: float, happiness: float = 100.0) -> RunStatus:
    if temp >= T_LOSS:          return RunStatus.LOSS_LIMIT_BREACHED   # precedence 1
    if happiness <= H_REVOLT:   return RunStatus.LOSS_REVOLT           # precedence 2 (H_REVOLT = 0)
    if n <= 0.0:                return RunStatus.WIN_NEUTRAL           # precedence 3 — any turn
    if year >= 2100:            return RunStatus.LOSS_NOT_NEUTRAL
    return RunStatus.RUNNING
```

- Inputs are this turn's post-step-7 values (`T_new`, N from step 3, H after drift and
  strikes) — feedback loops triggered this turn can push T over the line this same
  turn.
- **Precedence:** the tipping point outranks everything (breaching +2.0 °C on a
  net-negative turn is still `LOSS_LIMIT_BREACHED`); a revolt outranks the win (a
  neutral world in open revolt is not a run you kept); the win outranks the calendar.
- The win check runs **every turn**: the moment net ≤ 0, the run ends in
  `WIN_NEUTRAL` — the fixture strategies win in 2095, five years early.
- The +1.5 °C threshold never appears here: Overshoot is a state (band change signal),
  not an end state — warning, never defeat.

## Terminal handling in RunState

```
status := evaluate(year, temp, net, happiness)
record.end_status = status
if status == RUNNING:
    _advance_actors()                              # the world moves only while the run lives
    year += YEARS_PER_TURN; _begin_year()
else:
    phase = Phase.ENDED
    kp := knowledge_points(status, ...) + kp_earned
    run_ended.emit(status_string(status), kp)      # exactly once per run
```

The first turn with net ≤ 0 also stamps `curve_bent_year` and emits `curve_bent` —
because the win check is any-turn, the drawdown moment and the winning turn are the
same beat. After `ENDED`: `play_card()` returns `ERR_UNAVAILABLE`, `resolve_year()` is
a no-op returning the terminal record. No signal is ever emitted twice — asserted in
tests. New `can_play_reason` codes surfaced this phase: `not_in_market` (the offer is
not on this turn's market) and `no_target` extended to the actor ops (no bloc left to
fund or treaty); the ERR mapping is unchanged.

## Knowledge Points award (Phase 1 formula plus in-run insight)

```gdscript
static func knowledge_points(status: RunStatus, year: int, sector_progresses, allies: int) -> int:
    var kp := (mini(year, 2100) - 2030) / 10                  # integer division: decades survived
    for prog in sector_progresses: if prog >= 70.0: kp += 1   # KP_SECTOR_THRESHOLD
    kp += allies / 2
    if status == RunStatus.WIN_NEUTRAL: kp += 3               # KP_WIN_BONUS
    return maxi(kp, 1)                                        # KP_FLOOR: every timeline teaches
# RunState adds kp_earned on top: knowledge rewards accrued during the run from
# first-fire combo discoveries, risk breakthroughs and seized opportunities.
```

Fixture anchors (seed 2030): Safe WIN_NEUTRAL 2095 **12 KP** · Risky LOSS_REVOLT 2065
**3 KP** · Mixed WIN_NEUTRAL 2095 **12 KP**. Every outcome — win or loss — pays at
least `KP_FLOOR` (1): both ends of a run feed the meta. A `LOSS_REVOLT` additionally
unlocks its meta-lesson card (SOC4 Public Support Fund) permanently — defeat literally
teaches (pillar 4).

## Player-facing mapping (UI copy owned by `data/log_templates.json`, not scenes)

| Code | Headline (endings template) | Subtext driver |
|---|---|---|
| `WIN_NEUTRAL` | "The curve bends before the clock strikes. The world is carbon-neutral." | Drawdown year, years before the deadline, peak chain |
| `LOSS_LIMIT_BREACHED` | "The tipping point is crossed. The limit for a safe human world is breached." | Pivotal turn (avoidable-damage heuristic), world-vs-city ledger |
| `LOSS_REVOLT` | "Happiness reached zero. The city rises against its own transition — the run is lost." | The worst one-turn happiness drop and its named causes |
| `LOSS_NOT_NEUTRAL` | "We survived the century. The job is not done." | Final net and its largest remaining block (world blocs vs home sphere), pass count |

The subtext drivers come from the **post-mortem** (`06_Turn_Log_And_Analytics.md`) — a
pure heuristic over the TurnRecords, rendered on the run-end screen. The end screen is
a rendering of the log, not a second computation (one source of truth, as everywhere).

## Truth table (exhaustive test T-EVAL — `test_evaluator.gd`)

| year | T | N | H | → status |
|---|---|---|---|---|
| 2054 | 1.99 | +12 | 50 | RUNNING |
| 2054 | 2.00 | +12 | 50 | LOSS_LIMIT_BREACHED |
| 2060 | 1.60 | −1.0 | 50 | WIN_NEUTRAL (any-turn win) |
| 2100 | 1.46 | −23.5 | 50 | WIN_NEUTRAL |
| 2100 | 1.99 | +0.1 | 50 | LOSS_NOT_NEUTRAL |
| 2100 | 1.99 | 0.0 | 50 | WIN_NEUTRAL (N ≤ 0 inclusive) |
| 2100 | 2.00 | −5 | 50 | LOSS_LIMIT_BREACHED (precedence) |
| 2099 | 1.99 | +5 | 50 | RUNNING (the century is not over) |
| 2050 | 1.70 | +5 | 0 | LOSS_REVOLT (any year) |
| 2050 | 2.00 | +5 | 0 | LOSS_LIMIT_BREACHED (limit outranks revolt) |
| 2050 | 1.70 | −5 | 0 | LOSS_REVOLT (revolt outranks the win) |
| 2050 | 1.70 | +5 | 0.1 | RUNNING (any happiness above zero governs) |
