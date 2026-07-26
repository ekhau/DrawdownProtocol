# Phase 5 Done Criteria and Test Checklist — The Drawdown Protocol

Plan.md's Phase 5 done criteria — "exactly 3 events drawn per year; every card play
resolves against crises and combos deterministically" and "crisis outcomes, combos, and
project events are understandable and visible in logs" — extended with the data-driven
guarantees this phase adds on top of the Phase 4 engine.

## Done criteria

1. **Catalogs load from data.** 26 cards, 13 events (7 crises + 3 opportunities +
   3 feedbacks), 8 combos, 4 projects, 6 knowledge nodes load from `data/*.json` and
   pass every validator rule in doc 05; no catalog content remains in .gd files.
2. **Fixture regression from data.** The seed-2030 autoplay strategies reproduce the
   committed golden fixture with all content flowing through the JSON catalogs —
   Safe WIN 18 KP · Risky LOSS 2064 4 KP · Mixed WIN 18 KP.
3. **The crisis contract holds, both layers.** Exactly 3 events per year; the 5-card cap
   is enforced in the model; answered = contained + rewarded; unanswered = damages +
   rider; no input sequence can break either.
4. **Every trigger is visible.** Each draw, answer, combo, unlock, project event,
   strike, and feedback produces its banner beat (or log-only line where specified)
   *and* its log line from the same record fields; nothing can occur without a
   player-readable trace.
5. **Every available card state is explained.** All states of the doc 03 matrix render
   with their state line; available cards are never hidden; reasons come from
   `can_play()` codes only. (Unlockable cards are hidden until earned — amendment A7.)
6. **Escalation reads.** Band transitions (both directions) produce interstitial +
   gauge badge + a visibly heavier draw; the three feedback interstitials fire exactly
   once each at their trigger year.
7. **Pipeline turnaround.** `tools/content_check.sh` (validate + fixtures + corridor
   batch) runs green from a clean checkout in < 60 s.

## Automated test checklist

| # | Test | Covers |
|---|---|---|
| T1-P5 | Validator accepts the shipped catalogs with zero Errors and zero Warnings | Done 1 |
| T2-P5 | Mutation suite: ~30 deliberately broken catalog variants (bad op, dup id, decreasing crisis weights, opportunity with damages, missing response, unanswerable crisis, bad reward/unlock/tag, one-tag combo, ally op in combo, one-card combo coverage, free project, bad passive, missing penalty, missing template …) each rejected with the right rule id | Validator completeness |
| T3-P5 | Catalog-driven fixture regression: Safe/Risky/Mixed via JSON catalogs vs the stored golden file | Done 2 |
| T4-P5 | Card-state function: each matrix state yields the expected reason code; locked cards excluded from the pool | Done 5 |
| T5-P5 | Multi-play contract: five plays accepted, sixth rejected (`turn_limit`); exactly N actions in the TurnRecord; empty year records a pass | Done 3 |
| T6-P5 | Crisis visibility sweep: forced draws of each catalog entry; assert answered/struck/missed log lines, banner queue entries, rider gating, scar append | Done 4 |
| T7-P5 | Flat-damage crises: damages identical at R = 0 and R = 100 (`scaled_by_resilience: false` honored) | Data semantics |
| T8-P5 | Escalation transitions: interstitials in both directions; feedback one-shots exactly once | Done 6 |
| T9-P5 | Knowledge patches from JSON: each node's effect on the in-memory catalog matches `../Phase_4/02` | Data path parity |
| T10-P5 | Additive-content invariance: append a dummy card via the authoring template; fixtures byte-identical | Pipeline promise |
| T11-P5 | Template coverage: every catalog entry resolves all its required templates (crisis _hit/_answered, opportunity _seized/_missed, riders, combos, projects, unlocks) | Done 4, cross-file rule |
| T12-P5 | Discount path: fire_discount halves only `restoration`-tagged cards, preview price equals paid price, discount consumed on play | A4 tag semantics |
| T13-P5 | Combo data semantics: multiset matching, once per year, chain multiplier ×2 cap, knowledge first-fire-only | Combo catalog |
| T14-P5 | Project data semantics: launch/charge/complete/fail/abandon lifecycle with recorded project events and stacking passives | Project catalog |

## Manual checklist (playtest sitting, debug build)

- [ ] Read the crisis panel cold: every chip states its threat (or gift) and its answer
      tags; an answered chip names the card that did it.
- [ ] Answer each crisis type once across years; containment lines match HUD deltas.
- [ ] Fire each combo once; banner numbers match the chain label's multiplier.
- [ ] Launch, complete, and (separately) abandon a project; the penalty lands and the
      chip records the outcome.
- [ ] Reach an unlock (4 answers is fastest); the new card appears with its banner.
- [ ] Attempt to play a sixth card; try Space-pass without confirm.
- [ ] Force a mega fire to strike (leave it unanswered), then hover SNK1: discounted
      price on the chip, banner's opportunity line.
- [ ] Skip a heavy year with Space: final values correct, log holds all beats.
- [ ] Break `cards.json` on purpose (dup id): boot report lists it; fix; boot clean.

## Deviations and amendments recorded in this phase

- **A4:** `restoration` tag drives the fire discount (replaces "category is sink").
- **A6 (doc `../Phase_4/01`):** four new signals — `crisis_answered`, `combo_triggered`,
  `card_unlocked`, `project_changed` — for the juice layer.
- **A7 (doc 03):** unlockable cards are hidden until earned; the old "never hidden" rule
  now applies to the available pool only.
- **Deviation:** Plan.md's "draw policy options (3 cards)" remains replaced by the full
  Policy Board; the 3-draw randomness lives on the crisis side instead.

## Explicitly not in Phase 5 (scope guard)

Player-directed crisis assignment (auto-assign in draw order ships; a "choose which
crisis this card answers" picker is a post-MVP experiment); tutorial content beyond the
data file; audio (Phase 7); Knowledge Hub UI (Phase 6); the backlog event candidates;
any visual styling (solarpunk-ui-artist owns it — this phase ships wireframe-functional
UI that is *correct*, and hands over states, slots, and hierarchy as the artist's
contract).
