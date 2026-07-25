# Phase 4 Done Criteria and Test Checklist — The Drawdown Protocol

Plan.md's Phase 4 done criteria — "one turn advances all systems consistently" and
"win/loss conditions always evaluate correctly" — made concrete for this engine, plus the
determinism and fixture-regression guarantees the earlier phases established. Everything
below runs headless (GUT or gdUnit4); this phase needs no manual checklist beyond an
editor smoke run.

## Done criteria

1. **Pipeline integrity.** One `resolve_year()` executes steps 3–8 in order, exactly
   once, and `_begin_year()` executes steps 1–2's frame correctly; no field of RunState
   changes outside its audit-table column (`04_Society_And_Resilience_Spec.md`).
2. **Evaluator correctness.** The truth table in `05_End_State_Evaluator.md` passes
   exhaustively; `run_ended` fires exactly once per run; no state mutation after ENDED.
3. **Determinism.** Same `(seed, knowledge profile, decision list)` ⇒ byte-identical
   JSONL across two runs and across editor/headless builds.
4. **Fixture regression.** The three scripted strategies on seed 2030, canonical
   (unjittered) starts, reproduce `../Phase_1/02_Sample_Runs.md` exactly: outcomes
   (WIN 15 KP / LOSS_LIMIT_BREACHED 2099 9 KP / WIN 16 KP) and every decade-table row.
5. **Signal contract.** All seven signals fire at the documented step, with documented
   payloads, and never re-enter the sim (`../Phase_3/03` architecture).
6. **Data-driven.** Zero balance constants in .gd files: cards, knowledge, climate,
   society, events, log templates all load from `data/*.json`; a value change requires
   no code edit (golden rule 9; Plan.md engineering rules).
7. **Log parity.** Every in-game log line renders from TurnRecord fields via templates;
   the CSV harness produces the Phase 3 columns unchanged.

## Automated test checklist

| # | Test | Covers |
|---|---|---|
| T1-P4 | ClimateCalc golden values (table in `03_Climate_Calc_Spec.md`) | Formulas vs Phase 1 constants |
| T2-P4 | Evaluator truth table, all 7 rows + boundary sweep (T 1.999/2.000, N −0.001/0/+0.001) | Done 2 |
| T3-P4 | Full 71-turn all-pass run: BAU loses by mid-2050s via LOSS_LIMIT_BREACHED | Pipeline end-to-end sanity |
| T4-P4 | Resolver validation matrix: each `can_play` error path (funds, influence, allies, media dup, cap, action lock) | One-card lock; Plan.md quality gate |
| T5-P4 | Stacking: sector add clamps at 70 then 100 after suff; joint on capped sector reports requested vs applied; adapt clamps 60 | Clarification C2; stacking rules |
| T6-P4 | Waiver precedence: media-only, window-only, both (window survives — clarification C1), neither | C1 exact semantics |
| T7-P4 | rng_events consumption audit: run with instrumented RNG; draw count and order match spec; world/tiles/names streams untouched by sim | Determinism contract |
| T8-P4 | Knowledge patches: each of the 6 nodes alters catalog/state as specified; disk `cards.json` unchanged; `restoration_playbook` preserves totals | Resolver Knowledge section |
| T9-P4 | Event damages with R = 0 / 50 / 100 match table ×1.0 / ×0.75 / ×0.5; mult frozen at step-6 entry | Derived resilience |
| T10-P4 | Social crisis: p thresholds at H 39.9/40.0, media halving, band scaling; ally-loss picks targeted ally, never player home, no-op at 0 allies | Society spec |
| T11-P4 | Feedback one-shots: trigger once, correct order, same-year fire counts toward Amazon; e_extra visible only next year's E | Climate step 7 |
| T12-P4 | Determinism replay: two identical runs ⇒ byte-equal JSONL and CSV | Done 3 |
| T13-P4 | **Fixture regression**: Safe/Risky/Mixed vs stored Phase 1 golden files (full decade tables, outcomes, KP) | Done 4 |
| T14-P4 | Signal audit: counts and payloads per signal over a fixture run (e.g. exactly one `run_ended`; `warming_band_changed` fires on Overshoot exit in Run A, 2091) | Done 5 |
| T15-P4 | Data completeness: every card id in cards.json resolvable; every effect op known; every log template's fields exist on TurnRecord | Done 6, 7 |

T13-P4 is the load-bearing test of the whole phase: it pins the implementation to the
paper model. Store the golden files under `tests/fixtures/seed2030/` and treat any diff
as a design change requiring a Phase 1 doc update first (same rule as the golden values).

## Editor smoke checklist (10 minutes)

- [ ] New run from menu: year 2030, jittered starts within clamps, HUD matches debug F3.
- [ ] Play one card of each category; log lines render with real numbers; second card
      refused with visible feedback.
- [ ] Space through 10 years; band change shows vignette + log line together.
- [ ] Autoplay Safe to 2100 in-editor: end screen shows WIN copy, 15 KP, subtext fields.
- [ ] Restart with same seed from F3: first 5 log lines identical.

## Explicitly not in Phase 4 (scope guard)

Card-draw/hand systems (Plan.md Phase 5 owns the 3-card offer; this engine exposes
`can_play` for it), event content beyond the four types + three loops, Knowledge tree UI
(Phase 6), any UI polish (Phase 7). The engine ships when the tests above are green,
even if the only interface is F3 + autoplay (golden rule 1: the loop, provable, first).
