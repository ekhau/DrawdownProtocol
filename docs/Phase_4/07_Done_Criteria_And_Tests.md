# Phase 4 Done Criteria and Test Checklist — The Drawdown Protocol

Plan.md's Phase 4 done criteria — "one turn advances all systems consistently" and
"win/loss conditions always evaluate correctly" — made concrete for this engine, plus the
determinism and fixture-regression guarantees the earlier phases established. Everything
below runs headless; this phase needs no manual checklist beyond an editor smoke run.

## Done criteria

1. **Pipeline integrity.** `_begin_year()` executes income, project upkeep, and the
   3-crisis draw exactly once per year; one `resolve_year()` executes steps 3–8 in
   order, exactly once; no field of RunState changes outside its audit-table column
   (`04_Society_And_Resilience_Spec.md`).
2. **Evaluator correctness.** The truth table in `05_End_State_Evaluator.md` passes
   exhaustively; `run_ended` fires exactly once per run; no state mutation after ENDED.
3. **Determinism.** Same `(seed, knowledge profile, decision list)` ⇒ byte-identical
   JSONL across two runs; the crisis draw is the sole RNG consumer.
4. **Fixture regression.** The three scripted strategies on seed 2030, canonical
   (unjittered) starts, reproduce the committed golden fixture byte-for-byte with the
   anchors: Safe WIN 18 KP · Risky LOSS_LIMIT_BREACHED 2064 4 KP · Mixed WIN 18 KP.
5. **Signal contract.** All eleven signals fire at the documented step, with documented
   payloads, and never re-enter the sim.
6. **Data-driven.** Zero balance constants in .gd files: cards, combos, projects,
   knowledge, climate, society, events, log templates all load from `data/*.json`;
   a value change requires no code edit (golden rule 9).
7. **Log parity.** Every in-game log line renders from TurnRecord fields via templates;
   the CSV harness produces the established columns unchanged.

## Automated test checklist

| # | Test | Covers |
|---|---|---|
| T1-P4 | ClimateCalc golden values (table in `03_Climate_Calc_Spec.md`) | Formulas vs Phase 1 constants |
| T2-P4 | Evaluator truth table, all 7 rows + boundary sweep (T 1.999/2.000, N −0.001/0/+0.001) | Done 2 |
| T3-P4 | Full all-pass run: BAU loses in the late 2040s–early 2050s via LOSS_LIMIT_BREACHED (unanswered crises included) | Pipeline end-to-end sanity |
| T4-P4 | Resolver validation matrix: each `can_play` reason path (funds, influence, happiness, allies, media dup, cap, turn limit, locked card) | Multi-play cap; Plan.md quality gate |
| T5-P4 | Stacking: sector add clamps at 70 then 100 after suff (same-year replay legal); joint on capped sector reports requested vs applied; adapt clamps 60 | Stacking rules |
| T6-P4 | Waiver precedence: media-only, window-only, both (window survives — C1), neither | C1 exact semantics |
| T7-P4 | rng_events consumption audit: identical draws for identical seeds; plays and resolution consume no RNG (replay equality) | Determinism contract |
| T8-P4 | Knowledge patches: each node alters catalog/state as specified; disk `cards.json` unchanged; `restoration_playbook` preserves totals | Resolver Knowledge section |
| T9-P4 | Crisis damages with R = 0 / 100 match table ×1.0 / ×0.5; mult frozen at step-6 entry | Derived resilience |
| T10-P4 | Crisis weights: band scaling, low-happiness ×3, media ×0.5, threshold boundary at H 40; ally-loss picks targeted ally, never player home, no-op at 0 allies | Society spec |
| T11-P4 | Feedback one-shots: trigger once, correct order, unanswered fires count toward Amazon; e_extra visible only next year's E | Climate step 7 |
| T12-P4 | Determinism replay: two identical runs ⇒ byte-equal JSONL and CSV | Done 3 |
| T13-P4 | **Fixture regression**: Safe/Risky/Mixed vs the stored golden fixture (outcomes, KP, decade rows) | Done 4 |
| T14-P4 | Signal audit: counts and payloads per signal over a fixture run (exactly one `run_ended`; `warming_band_changed` fires on Overshoot exit) | Done 5 |
| T15-P4 | Data completeness: every card/combo/project/event id resolvable; every effect op known; every log template's fields exist on TurnRecord | Done 6, 7 |
| T16-P4 | Crisis loop: 3 drawn per year, no duplicates; answered = contained (no damage, no rider); unanswered = damages + counters + scar + rider; missed opportunities are free | Crisis semantics |
| T17-P4 | Combo loop: multiset matching, once per year, chain up/decay, ×2 cap, knowledge first-fire-only, single card never combos | Combo semantics |
| T18-P4 | Project loop: launch pays year one, completes after full term with passives, fail-to-pay and abandon apply the penalty, max 2 active, one attempt per run | Project semantics |
| T19-P4 | Deck growth: each unlock kind triggers at its threshold; unlocks recorded and signalled; locked cards rejected with `card_locked` | Growth contract |

T13-P4 remains the load-bearing test: it pins the implementation. Store the golden file
under `tests/fixtures/` and treat any diff as a design change requiring a Phase 1 doc
update first (same rule as the golden values).

## Editor smoke checklist (10 minutes)

- [ ] New run: year 2030, three crises in the panel with threats and answer tags.
- [ ] Play a matching card: crisis flips to ANSWERED, reward lands, log explains it.
- [ ] Play a deliberate pair (e.g. TRA2 + IND1): combo banner with chain multiplier.
- [ ] Launch a project; Space through years; watch charges, then completion.
- [ ] Space through 10 years; band change shows vignette + log line together.
- [ ] Autoplay Safe to 2100 in-editor: end screen shows WIN copy, 18 KP.
- [ ] Restart with same seed from F3: first 5 log lines identical.

## Explicitly not in Phase 4 (scope guard)

Player-directed crisis assignment (auto-assign to the first open match is the MVP rule),
event content beyond the shipped deck + three loops, Knowledge tree UI (Phase 6), any UI
polish (Phase 7). The engine ships when the tests above are green, even if the only
interface is F3 + autoplay (golden rule 1: the loop, provable, first).
