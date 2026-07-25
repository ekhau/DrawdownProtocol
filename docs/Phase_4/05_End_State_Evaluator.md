# End-State Evaluator — The Drawdown Protocol (Phase 4)

Step 8 of the pipeline. Plan.md's done criterion — "win/loss conditions always evaluate
correctly" — is met by making the evaluator a pure function with reason codes, called
exactly once per resolved year, with a truth table small enough to test exhaustively.

## Reason codes

```gdscript
enum RunStatus {
    RUNNING,              # no terminal condition
    LOSS_LIMIT_BREACHED,  # T >= 2.0 °C — the hard loss, any year
    WIN_NEUTRAL,          # year == 2100 and N <= 0 — carbon-neutral world
    LOSS_NOT_NEUTRAL,     # year == 2100 and N > 0 — survived, not neutral (soft loss)
}
```

Codes are serialized as stable strings (`"LOSS_LIMIT_BREACHED"`, ...) in TurnRecords and
CSV — analytics depend on them never being renamed (golden rule 13).

## Evaluation function

```gdscript
static func evaluate(year: int, temp: float, n: float) -> RunStatus:
    if temp >= 2.0:      return RunStatus.LOSS_LIMIT_BREACHED   # precedence 1
    if year >= 2100:
        return RunStatus.WIN_NEUTRAL if n <= 0.0 else RunStatus.LOSS_NOT_NEUTRAL
    return RunStatus.RUNNING
```

- Inputs are this year's post-step-7 values (`T_new`, N from step 3) — feedback loops
  triggered this year can push T over the line this same year (Run B dies in 2099 partly
  on feedback-degraded sinks).
- **Precedence:** breaching +2.0 °C in 2100 is still `LOSS_LIMIT_BREACHED` — the
  temperature limit outranks the calendar, exactly as the concept frames it.
- The +1.5 °C threshold never appears here: Overshoot is a state (band change signal),
  not an end state — warning, never defeat.

## Terminal handling in RunState

```
status := evaluate(year, temp, net)
record.end_status = status
if status == RUNNING: year += 1; _begin_year()
else:
    phase = Phase.ENDED
    kp := knowledge_points(status)
    run_ended.emit(status_string(status), kp)      # exactly once per run
```

After `ENDED`: `play_card()` returns `ERR_UNAVAILABLE`, `resolve_year()` is a no-op
returning the terminal record. No signal is ever emitted twice — asserted in tests.

## Knowledge Points award (Phase 1 formula, unchanged)

```gdscript
static func knowledge_points(status: RunStatus, year: int, sectors, allies: int) -> int:
    var kp := (mini(year, 2100) - 2030) / 10                  # integer division: decades survived
    for s in sectors: if s.progress >= 70.0: kp += 1
    kp += allies / 2
    if status == RunStatus.WIN_NEUTRAL: kp += 3
    return kp
```

Fixture anchors (seed 2030): Safe WIN 15 · Risky LOSS_LIMIT_BREACHED (2099) 9 ·
Mixed WIN 16. Soft loss earns everything except the +3 — reaching 2100 with a
transformed-but-not-neutral world must feel like progress, not a wipe (pillar 4:
every timeline teaches).

## Player-facing mapping (UI copy owned here, not in scenes)

| Code | Headline | Subtext driver |
|---|---|---|
| `WIN_NEUTRAL` | "The balance holds." | Final N, peak T, allies count |
| `LOSS_LIMIT_BREACHED` | "The limit for a safe human world is breached." | Year, which feedback loops had triggered |
| `LOSS_NOT_NEUTRAL` | "We survived the century. The job is not done." | Final N and its largest remaining source (sector or lost sinks) |

The subtext driver fields come straight from the terminal TurnRecord — the end screen is
a rendering of the log, not a second computation (one source of truth, as everywhere).

## Truth table (exhaustive test T-EVAL)

| year | T | N | → status |
|---|---|---|---|
| 2054 | 1.99 | +12 | RUNNING |
| 2054 | 2.00 | +12 | LOSS_LIMIT_BREACHED |
| 2100 | 1.46 | −23.5 | WIN_NEUTRAL |
| 2100 | 1.99 | +0.1 | LOSS_NOT_NEUTRAL |
| 2100 | 1.99 | 0.0 | WIN_NEUTRAL (N ≤ 0 inclusive) |
| 2100 | 2.00 | −5 | LOSS_LIMIT_BREACHED (precedence) |
| 2099 | 1.99 | −5 | RUNNING (the century is not over) |
