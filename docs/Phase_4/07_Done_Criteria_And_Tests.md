# Phase 4 Done Criteria and Test Checklist — The Drawdown Protocol

Plan.md's Phase 4 done criteria — "one turn advances all systems consistently" and
"win/loss conditions always evaluate correctly" — made concrete for this engine, plus the
determinism and fixture-regression guarantees the earlier phases established. Everything
below runs headless; this phase needs no manual checklist beyond an editor smoke run.

## Done criteria

1. **Pipeline integrity.** `_begin_year()` executes income, project upkeep, the
   3-event draw (+ on-draw spikes) and the market deal (+ guarantee rule + bonus
   injections) exactly once per turn; one `resolve_year()` executes steps 3–8 —
   including 6b (summit) and 7b (actor advance, skipped once terminal) — in order,
   exactly once; no field of RunState changes outside its audit-table column
   (`04_Society_And_Resilience_Spec.md`).
2. **Evaluator correctness.** The truth table in `05_End_State_Evaluator.md` passes
   exhaustively — including the any-turn win, the revolt, and both precedence rows;
   `run_ended` fires exactly once per run; no state mutation after ENDED.
3. **Determinism.** Same `(seed, knowledge profile, archetype, decision list)` ⇒
   byte-identical JSONL across two runs; the three streams (events / market / risk)
   are each consumed only at their documented point, and nowhere else.
4. **Fixture regression.** The three scripted strategies on seed 2030, canonical
   (unjittered) starts, reproduce the committed golden fixture byte-for-byte with the
   anchors: Safe WIN_NEUTRAL 2095 **12 KP** · Risky LOSS_REVOLT 2065 **3 KP** ·
   Mixed WIN_NEUTRAL 2095 **12 KP**.
5. **Signal contract.** All fourteen signals fire at the documented step, with
   documented payloads, and never re-enter the sim.
6. **Data-driven.** Zero balance constants in .gd files: cards, combos, projects,
   knowledge, climate, society, events, world actors, archetypes, summits, log
   templates all load from `data/*.json`; a value change requires no code edit
   (golden rule 9).
7. **Log parity.** Every in-game log line renders from TurnRecord fields via templates
   (including ledger, clock, world-drift, on-draw, bonus-card, risk, summit and
   curve-bent lines); the CSV harness produces the established columns unchanged.

## Automated test checklist (suites under `src/tests/`, run by `run_tests.gd`)

| # | Test (suite) | Covers |
|---|---|---|
| T1-P4 | ClimateCalc golden values incl. clock functions (`test_climate_calc.gd`) | Formulas vs Phase 1 constants; per-turn rates |
| T2-P4 | Evaluator truth table, all rows + boundary sweep (T 1.999/2.000, N ±0.001, H 0/0.1) and revolt precedence (`test_evaluator.gd`) | Done 2 |
| T3-P4 | Full all-pass run: BAU loses via LOSS_LIMIT_BREACHED with the world's blocs drifting un-damped (`test_pipeline.gd`) | Pipeline end-to-end sanity |
| T4-P4 | Resolver validation matrix: each `can_play` reason path incl. `not_in_market` and actor-op `no_target` (`test_resolver.gd`) | Multi-play cap; Plan.md quality gate |
| T5-P4 | Stacking: sector add clamps at 70 then 100 after suff; joint on capped sector reports requested vs applied; adapt clamps 60 (`test_resolver.gd`) | Stacking rules |
| T6-P4 | Waiver precedence: media-only, window-only, both (window survives — C1), neither (`test_resolver.gd`) | C1 exact semantics |
| T7-P4 | RNG consumption audit: identical draws/deals for identical seeds; resolution consumes no RNG; risk rolls only on play (`test_crises.gd`, `test_market.gd`) | Determinism contract |
| T8-P4 | Knowledge patches: each node alters catalog/state as specified; disk `cards.json` unchanged; `restoration_playbook` (reforest_turns 2) preserves totals; `capital_charter` grants the archetype (`test_knowledge.gd`) | Resolver Knowledge section |
| T9-P4 | Crisis damages with R = 0 / 100 match table ×1.0 / ×0.5; mult frozen at step-6 entry (`test_society.gd`, `test_crises.gd`) | Derived resilience |
| T10-P4 | Crisis weights: band scaling, low-happiness ×3, media ×0.5, threshold boundary at H 40; ally-loss picks targeted ally, never player home, no-op at 0 allies (`test_society.gd`, `test_crises.gd`) | Society spec |
| T11-P4 | Feedback one-shots: trigger once, catalog order, unanswered fires count toward Amazon; e_extra visible only next turn's E (`test_pipeline.gd`) | Climate step 7 |
| T12-P4 | Determinism replay: two identical runs ⇒ byte-equal JSONL and CSV (`test_fixtures.gd`, `test_pipeline.gd`) | Done 3 |
| T13-P4 | **Fixture regression**: Safe/Risky/Mixed vs the stored golden fixture (`test_fixtures.gd`, `tests/fixtures/seed2030_expected.csv`) | Done 4 |
| T14-P4 | Signal audit: counts and payloads per signal over a fixture run (exactly one `run_ended`; `warming_band_changed` both directions; `summit_resolved` per scheduled turn; `curve_bent` once) (`test_pipeline.gd`) | Done 5 |
| T15-P4 | Data completeness: every card/combo/project/event/actor/archetype/summit id resolvable; every effect op known; every log template's fields exist on TurnRecord (`test_validator.gd`) | Done 6, 7 |
| T16-P4 | Crisis loop: 3 drawn per turn, no duplicates; answered = contained (no damage, no rider, spike cleared); unanswered = damages + counters + scar + rider + permanent spike; missed opportunities are free (`test_crises.gd`, `test_market.gd`) | Crisis semantics |
| T17-P4 | Combo loop: multiset matching, once per turn, chain up/decay, cap, knowledge first-fire-only, single card never combos (`test_combos.gd`) | Combo semantics |
| T18-P4 | Project loop: launch pays turn one, completes after 3 turns with passives, fail-to-pay and abandon apply the penalty, max 2 active, one attempt per run (`test_projects.gd`) | Project semantics |
| T19-P4 | Deck growth: each unlock kind triggers at its threshold; unlocks recorded and signalled; locked cards rejected with `card_locked`; meta cards available from turn 1; bonus-only cards exist only while injected (`test_resolver.gd`, `test_market.gd`) | Growth contract |
| T20-P4 | Market contract: 4 offers dealt each turn, deterministic per seed, weighted by `market_weight` × archetype lean, without replacement; playing consumes the offer; guarantee rule swaps in the cheapest answer; bonus injection gated by resources at draw time (`test_market.gd`) | Market semantics |
| T21-P4 | World contract: actors initialized from data; curves advance by trend only while RUNNING; allies damp steepest-first; `actor_fund` cuts the biggest emitter above floor; `actor_treaty` bends the steepest trend; summits pay/penalize on their scheduled turn; archetypes modify starts and market lean; baseline runs carry no archetype (`test_world.gd`) | Hybrid-scale semantics |
| T22-P4 | Post-mortem: each outcome family names its pivot (worst avoidable-damage turn, biggest happiness drop, remaining-block gap, drawdown moment); summit misses weigh on the pivot; earliest turn wins ties (`test_postmortem.gd`) | Analytics consumer 4 |

T13-P4 remains the load-bearing test: it pins the implementation. The golden file lives
under `tests/fixtures/` (regenerated deliberately via `tools/gen_fixtures.gd`); treat
any diff as a design change requiring a Phase 1 doc update first (same rule as the
golden values).

## Editor smoke checklist (10 minutes)

- [ ] New run: year 2030, "Turn 1/15", three events in the panel with threats and
      answer tags, four offers in the market, the blocs panel listing four actors.
- [ ] Play a matching offer: crisis flips to ANSWERED, reward lands, the offer leaves
      the market, log explains it.
- [ ] Play a deliberate pair (e.g. TRA2 + IND1 when offered): combo banner with chain
      multiplier.
- [ ] Launch a project; Space through turns; watch charges, then completion on turn 3.
- [ ] Fund DIP4/DIP5 when offered: the named bloc's number and drift arrow move.
- [ ] Space to a summit turn: the announcement banner at turn start, the verdict at
      resolve.
- [ ] Space through several turns; the climate clock climbs; a band change shows
      vignette + log line together.
- [ ] Autoplay Safe to the end in-editor: WIN copy in 2095, 12 KP, post-mortem lines.
- [ ] Restart with same seed from F3: first 5 log lines identical.

## Explicitly not in Phase 4 (scope guard)

Player-directed crisis assignment (auto-assign to the first open match is the MVP rule),
event content beyond the shipped deck + three loops, Knowledge tree UI (Phase 6), any UI
polish (Phase 7). The engine ships when the tests above are green, even if the only
interface is F3 + autoplay (golden rule 1: the loop, provable, first).
