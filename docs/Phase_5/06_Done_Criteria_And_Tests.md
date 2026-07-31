# Phase 5 Done Criteria and Test Checklist — The Drawdown Protocol

Plan.md's Phase 5 done criteria — "exactly 3 events drawn per turn; every card play
resolves against crises and combos deterministically" and "crisis outcomes, combos, and
project events are understandable and visible in logs" — extended with the data-driven
guarantees this phase adds on top of the Phase 4 engine, now including the market, the
world catalogs and the summit calendar.

## Done criteria

1. **Catalogs load from data.** 33 cards (25 starting + 6 unlockable + 1 meta-lesson +
   1 bonus-only), 13 events (7 crises + 3 opportunities + 3 feedbacks), 8 combos,
   4 projects, 7 knowledge nodes, 4 world actors, 3 city archetypes and 3 summits load
   from `data/*.json` and pass every validator rule in doc 05; no catalog content
   remains in .gd files.
2. **Fixture regression from data.** The seed-2030 autoplay strategies reproduce the
   committed golden fixture with all content flowing through the JSON catalogs —
   Safe WIN_NEUTRAL 2095 12 KP · Risky LOSS_REVOLT 2065 3 KP · Mixed WIN_NEUTRAL 2095
   12 KP.
3. **The crisis contract holds, all layers.** Exactly 3 events per turn; exactly 4
   market offers dealt (plus injections), at least one answering an open event
   (guarantee rule); the 5-card cap is enforced in the model; answered = contained +
   rewarded + spike cleared; unanswered = damages + rider + permanent spike; no input
   sequence can break any of it.
4. **Every trigger is visible.** Each draw, spike, injection, deal, answer, risk roll,
   combo, unlock, project event, strike, summit verdict, feedback, actor drift and the
   curve-bent moment produces its banner beat (or log-only line where specified) *and*
   its log line from the same record fields; nothing can occur without a
   player-readable trace.
5. **Every offer state is explained.** All states of the doc 03 matrix render with
   their state line — including `not_in_market` ("Not offered this turn") and
   `no_happiness` ("the public cannot bear it"); reasons come from `can_play_reason()`
   codes only. (Unlockable cards stay hidden until earned — amendment A7; bonus-only
   cards exist only while injected.)
6. **Escalation reads.** Band transitions (both directions) produce interstitial +
   gauge badge + a visibly heavier draw; the three feedback interstitials fire exactly
   once each at their trigger turn; the climate clock carries percent, forecast and
   history continuously.
7. **Pipeline turnaround.** `tools/content_check.sh` (validate + test suite with
   fixtures + enforced 20-seed rate-corridor batch) runs green from a clean checkout
   in < 60 s.

## Automated test checklist (suites under `src/tests/`)

| # | Test | Covers |
|---|---|---|
| T1-P5 | Validator accepts the shipped catalogs with zero Errors and zero Warnings (`test_validator.gd`) | Done 1 |
| T2-P5 | Mutation suite: deliberately broken catalog variants (bad op, dup id, decreasing crisis weights, opportunity with damages, missing response, unanswerable crisis, bad reward/unlock/tag, risk chance ≥ 1, missing on_success, short codex body, meta+run unlock combined, zero market_weight, bonus_only with unlock, on_draw on an opportunity, bonus_card to a ghost card, one-tag combo, ally op in combo, one-card combo coverage, free project, 7-turn project, bad passive, missing penalty, one-actor world, negative trend, floor above emissions, all-unlocked archetypes, duplicate summit turn, summit without penalty, missing template …) each rejected with the right rule id (`test_validator.gd`) | Validator completeness |
| T3-P5 | Catalog-driven fixture regression: Safe/Risky/Mixed via JSON catalogs vs the stored golden file (`test_fixtures.gd`) | Done 2 |
| T4-P5 | Offer-state function: each matrix state yields the expected reason code; locked cards excluded from the pool; off-market cards report `not_in_market` (`test_resolver.gd`, `test_market.gd`) | Done 5 |
| T5-P5 | Multi-play contract: five plays accepted, sixth rejected (`turn_limit`); exactly N actions in the TurnRecord; empty turn records a pass (`test_resolver.gd`) | Done 3 |
| T6-P5 | Crisis visibility sweep: forced draws of each catalog entry; assert answered/struck/missed log lines, banner queue entries, rider gating, scar append, on-draw hit/cleared lines (`test_crises.gd`, `test_market.gd`) | Done 4 |
| T7-P5 | Flat-damage crises: damages identical at R = 0 and R = 100 (`scaled_by_resilience: false` honored) (`test_crises.gd`) | Data semantics |
| T8-P5 | Escalation transitions: interstitials in both directions; feedback one-shots exactly once (`test_pipeline.gd`) | Done 6 |
| T9-P5 | Knowledge patches from JSON: each node's effect on the in-memory catalog matches `../Phase_4/02`, incl. `reforest_turns` total preservation and the `archetype` grant (`test_knowledge.gd`) | Data path parity |
| T10-P5 | **Additive-content invariance, reframed**: append a dummy **bonus-only** card via the authoring template; fixtures byte-identical. A dummy *normal* card is asserted to legitimately shift the deal — pool growth is a tuning change by definition (`test_market.gd`, `test_fixtures.gd`) | Pipeline promise |
| T11-P5 | Template coverage: every catalog entry resolves all its required templates (crisis _hit/_answered, opportunity _seized/_missed, riders, combos, projects, unlocks, risk, summit, world-drift, curve-bent, LOSS_REVOLT ending) (`test_validator.gd`) | Done 4, cross-file rule |
| T12-P5 | Discount path: fire_discount halves only `restoration`-tagged cards, preview price equals paid price, discount consumed on play (`test_resolver.gd`) | A4 tag semantics |
| T13-P5 | Combo data semantics: multiset matching, once per turn, chain multiplier cap, knowledge first-fire-only (`test_combos.gd`) | Combo catalog |
| T14-P5 | Project data semantics: launch/charge/complete/fail/abandon lifecycle over 3 turns with recorded project events (turns_left) and stacking passives (`test_projects.gd`) | Project catalog |
| T15-P5 | Market data semantics: deterministic deal per seed, `market_weight` bias measurable, archetype tag lean deterministic, guarantee rule swaps the cheapest answer, bonus injection resource-gated at draw time, injected card answers its crisis (`test_market.gd`) | Market catalog |
| T16-P5 | World data semantics: actors advance by trend only while RUNNING, allies damp steepest-first, `actor_fund`/`actor_treaty` pick their documented targets and floor correctly, summit met pays / missed penalizes on the scheduled turn, archetypes apply their multipliers and start allies, baseline runs carry none (`test_world.gd`) | World catalogs |
| T17-P5 | Post-mortem rendering: each ending family produces its pivot headline and cause lines from records alone (`test_postmortem.gd`) | Done 4 (the last screen) |
| T18-P5 | Rate corridor: 20 canonical seeds × 3 strategies — Risky never wins; Safe ≥ 50% (≥ 10/20); Mixed ≥ 40% (≥ 8/20) (`test_fixtures.gd`, `tools/batch_runs.gd --enforce`) | Done 7; Phase 1 corridor |

## Manual checklist (playtest sitting, debug build)

- [ ] Read the crisis panel cold: every chip states its threat (or gift), its answer
      tags, and any baked-in spike; an answered chip names the card that did it.
- [ ] Read the market cold: every offer states cost, effects, tags, odds and window
      marks; a blocked offer states why.
- [ ] Answer each crisis type once across turns; containment lines match HUD deltas;
      the heat wave's spike visibly clears from the forecast.
- [ ] Trigger the HWP1 window (draw heat_wave with happiness ≥ 40): the injection
      banner plays, the chip wears [CRISIS WINDOW], and it answers the heat wave.
- [ ] Fund RND1/RND2 a few times: the odds on the chip match the verdict banners'
      stated chance; a failure visibly hurts.
- [ ] Fire each combo once; banner numbers match the chain label's multiplier; force a
      2-combo turn for the CASCADE beat.
- [ ] Fund DIP4 and DIP5; the named bloc's emissions/drift move in the blocs panel.
- [ ] Hit and miss a summit; verdict banners and the next-summit HUD line update.
- [ ] Launch, complete, and (separately) abandon a project; the penalty lands and the
      chip records the outcome.
- [ ] Reach an unlock (4 answers is fastest); the new card appears with its banner.
- [ ] Lose by revolt once; the post-mortem names the drop; SOC4 appears in later runs.
- [ ] Open the Codex: funded cards show their entries, the rest show ???.
- [ ] Attempt to play a sixth card; try Space-pass without confirm.
- [ ] Force a mega fire to strike (leave it unanswered), then find SNK1 in a later
      market: discounted price on the chip, banner's opportunity line.
- [ ] Skip a heavy turn with Space: final values correct, log holds all beats.
- [ ] Break `cards.json` on purpose (dup id): boot report lists it; fix; boot clean.

## Deviations and amendments recorded in this phase

- **A4:** `restoration` tag drives the fire discount (replaces "category is sink").
- **A6 (doc `../Phase_4/01`):** four crisis-loop signals — `crisis_answered`,
  `combo_triggered`, `card_unlocked`, `project_changed` — for the juice layer; the
  clock race added three more: `summit_resolved`, `risk_resolved`, `curve_bent`.
- **A7 (doc 03):** unlockable cards are hidden until earned; the "never hidden" rule
  applies to the dealt market only.
- **Deviation, reversed:** the full Policy Board is replaced by the dealt **Project
  Market** (4 offers + injections + guarantee rule) — Plan.md's original "draw policy
  options (example: 3 cards)" is, after a long detour, closer to what shipped; the
  3-draw randomness now lives on *both* sides, kept fair by the guarantee rule and the
  rate corridor.
- **Deviation:** win/loss reshaped for the clock race — any-turn win at net ≤ 0,
  `LOSS_REVOLT` at happiness 0 (doc `../Phase_4/05`); one turn = 5 years.

## Explicitly not in Phase 5 (scope guard)

Player-directed crisis assignment (auto-assign in draw order ships; a "choose which
crisis this card answers" picker is a post-MVP experiment); market rerolls or offer
locking (interesting, unproven — cut, don't half-build); tutorial content beyond the
data file; audio (Phase 7); Knowledge Hub UI beyond the existing tree (Phase 6); the
backlog event candidates; any visual styling (solarpunk-ui-artist owns it — this phase
ships wireframe-functional UI that is *correct*, and hands over states, slots, and
hierarchy as the artist's contract).
