# Phase 5 Done Criteria and Test Checklist — The Drawdown Protocol

Plan.md's Phase 5 done criteria — "policy pick always resolves exactly once per year" and
"event triggers are understandable and visible in logs" — extended with the data-driven
guarantees this phase adds on top of the Phase 4 engine.

## Done criteria

1. **Catalogs load from data.** 15 cards, 7 events, 6 knowledge nodes load from
   `data/*.json` and pass every validator rule in doc 05; no catalog content remains in
   .gd files or scenes.
2. **Fixture regression from data.** The seed-2030 autoplay strategies reproduce the
   `../Phase_1/02` tables and outcomes **with all content flowing through the JSON
   catalogs** — proving data and engine agree with the paper model end-to-end
   (supersedes T13-P4's hard-coded-catalog baseline).
3. **One policy per year, both layers.** The model lock (Phase 4) plus the UI states:
   no input sequence can enact two cards in one year, and the pass path always requires
   its explicit confirm.
4. **Every trigger is visible.** Each event and feedback that fires produces its banner
   beat (or skipped-collapse line) *and* its log line from the same TurnRecord fields;
   no event can occur without a player-readable trace (Plan.md criterion, made
   structural by template coverage).
5. **Every card state is explained.** All 8 states of the doc 03 matrix render with
   their state line; no card is ever hidden; reasons come from `can_play()` codes only.
6. **Escalation reads.** Band transitions (both directions) produce interstitial + gauge
   badge + probability tooltip update; the three feedback interstitials fire exactly
   once each at their trigger year.
7. **Pipeline turnaround.** `tools/content_check.sh` (validate + fixtures + corridor
   batch) runs green from a clean checkout in < 60 s.

## Automated test checklist

| # | Test | Covers |
|---|---|---|
| T1-P5 | Validator accepts the shipped catalogs with zero Errors, exactly the two documented Warnings (heat_wave E7; none in cards) | Done 1 |
| T2-P5 | Mutation suite: ~20 deliberately broken catalog variants (bad op, dup id, decreasing probabilities, sufficiency tag without lifts_cap, unknown flag, missing template) each rejected with the right rule id | Validator completeness |
| T3-P5 | Catalog-driven fixture regression: Safe/Risky/Mixed via JSON catalogs vs stored golden files | Done 2 |
| T4-P5 | Card-state function: for each of the 8 matrix states, a constructed RunState yields the expected state + reason code | Done 5 |
| T5-P5 | Double-enact attempts (UI event spam, enact during RESOLVING, enact after pass-confirm) all rejected; exactly one action in the TurnRecord | Done 3 |
| T6-P5 | Event visibility sweep: forced-trigger each of the 7 catalog entries (debug dropdown path); assert banner queue entry + log line + (where applicable) opportunity beat, pin glyph, scar append | Done 4 |
| T7-P5 | Social crisis flatness: damages identical at R = 0 and R = 100 (`scaled_by_resilience: false` honored) | Data semantics |
| T8-P5 | Escalation transitions: drive T across 1.5/1.75 up and down in a scripted run; assert interstitials, badge, tooltip band column, and hopeful-variant on descent | Done 6 |
| T9-P5 | Knowledge patches from JSON: each node's effect on the in-memory catalog matches `../Phase_4/02` (re-run of T8-P4 through the data path) | Data path parity |
| T10-P5 | Additive-content invariance: append a dummy 16th card via the authoring template; fixtures byte-identical; remove it | Pipeline promise |
| T11-P5 | Template coverage: every catalog entry resolves all its required templates; every template field exists on TurnRecord | Done 4, cross-file rule |
| T12-P5 | Discount path: fire_discount halves only `restoration`-tagged cards, preview price equals paid price | A4 tag semantics |

## Manual checklist (playtest sitting, debug build)

- [ ] Read the whole Policy Board cold: every dimmed card states why; DIP2's "needs
      2 allies" reads as a goal, not an error.
- [ ] Enact each category once across years; effect lines match HUD deltas every time.
- [ ] Attempt to double-enact by rapid clicking; try Space-pass without confirm.
- [ ] Force a mega fire, then hover SNK1: discounted price on the chip, banner's
      opportunity line, pin glyph until played.
- [ ] Cross +1.5 °C and later descend (autoplay Safe to 2091): both interstitials land,
      vignette engages and lifts.
- [ ] Skip a heavy year with Space: final values correct, log holds all beats.
- [ ] Break `cards.json` on purpose (dup id): boot report lists it; fix; boot clean.

## Deviations and amendments recorded in this phase

- **Deviation (doc 03):** Plan.md's "draw policy options (example: 3 cards)" replaced by
  the full-catalog Policy Board; drawn-hand variant parked post-MVP with its cost stated.
- **A4 (doc 01):** `restoration` tag replaces `../Phase_4/02`'s "category is sink"
  special case for fire_discount; resolver spec to be updated when implemented.
- **A5 (doc 03):** free-choice assumption recorded as balance assumption #22 for the
  next `../Phase_1/06` revision.

## Explicitly not in Phase 5 (scope guard)

Tutorial/onboarding content (Phase 7 — only the `highlight_filter` seam ships);
audio (Phase 7); Knowledge Hub UI (Phase 6); the three backlog event candidates
(content work post-MVP); any visual styling (solarpunk-ui-artist owns it — this phase
ships wireframe-functional UI that is *correct*, and hands over states, slots, and
hierarchy as the artist's contract).
