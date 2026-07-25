# Phase 3 Done Criteria and Test Checklist — The Drawdown Protocol

Plan.md's Phase 3 done criteria ("board generation deterministic for a fixed seed; tile
interactions visually clear and responsive") carried over and extended for the reframed
World Model and Board View (see reconciliation in `01_World_Model_And_Tile_Schema.md`).

## Done criteria

1. **Determinism.** Same run seed ⇒ byte-identical world (serialized `RegionData` set
   deep-equal) and, with the same decisions, an identical 71-turn timeline (batch CSV
   byte-equal across two runs on the same build).
2. **Stream independence.** Regenerating tiles or names does not change event rolls or
   world shares (sub-seed streams verified by test, not by convention).
3. **Invariants hold at scale.** 100-seed headless batch passes every invariant in
   `01_World_Model_And_Tile_Schema.md` with zero violations (non-zero exit otherwise).
4. **Balance survives procgen** (discharges `../Phase_1/06_Assumptions.md` #21).
   20 seeds × 3 scripted strategies: Safe and Mixed always win, Risky never wins, and
   decade metrics stay inside the `../Phase_1/05_Balance_Bands.md` corridors widened by
   the jitter margin. If violated: shrink jitter ranges, re-run, update Assumptions.
5. **Interaction clarity.** Hover highlight same-frame; tooltip complete per
   `04_Interaction_Spec.md`; no hover-only information; Esc always returns to a clean
   state; Space never dead except during the DIP1 prompt and run-end screen.
6. **Board truthfulness.** After every turn, every visible board element (mini-bars, ally
   rings, scars, era tint, vignette) matches the `YearReport` — verified by the HUD-match
   spot-check script and by eye in the manual pass.
7. **Debug parity.** F3 overlay shows every field listed in `05_Debug_View_Spec.md`;
   autoplay Safe/Risky/Mixed reproduce the Phase 1 sample-run outcomes on seed 2030
   (the tables in `../Phase_1/02_Sample_Runs.md` are the fixture).
8. **Headless CI.** `--headless` batch harness runs green from a clean checkout via one
   command; no editor interaction required.

## Automated test checklist (GUT or gdUnit4, headless)

| # | Test | Covers |
|---|---|---|
| T1 | `sub_seed` produces documented constants for known inputs (golden values) | Seed handling stability |
| T2 | World gen twice with same seed ⇒ deep-equal region arrays | Done 1 |
| T3 | World gen with seeds `k` and `k+1` ⇒ different worlds (sanity, non-degenerate) | Generator liveness |
| T4 | Σ shares per sector and sink = 1.0 ± 0.001, all seeds in batch | Invariants |
| T5 | Archetype counts within preset min–max; exactly one player home; ≥ 2 coastal, ≥ 2 fire-eligible | Invariants |
| T6 | Derived region emissions sum equals global E every year of a full autoplay run | "Tiles render state" rule |
| T7 | Consume tile stream fully, then roll events: event sequence unchanged vs no-tile run | Done 2 |
| T8 | Flood targets only coastal regions; fire only forested/arid; home never removed as ally | Event targeting |
| T9 | DIP1 with target A vs target B: identical M/I/ally-count/warming timeline thereafter | Flavor-only targeting |
| T10 | Global jitter clamps respected across 100 seeds (E 48–52, A 18–22, H 57–63) | Procgen spec step 5 |
| T11 | Autoplay Safe/Risky/Mixed on canonical (unjittered) start, seed 2030 ⇒ outcomes and decade tables match Phase 1 fixtures | Done 7, regression |
| T12 | 20-seed × 3-strategy batch: structural outcomes + widened corridors | Done 4 |
| T13 | Tier B (when built): tile stage recompute from scratch equals incremental updates after 71 turns | Projection purity |

## Manual checklist (one sitting, debug build)

- [ ] Hover each archetype: highlight instant, tooltip complete and readable.
- [ ] Select region, open inspector, select another, Esc — no stuck outlines.
- [ ] Play DIP1: neutral regions pulse, Esc refunds, pick names the ally in the log.
- [ ] Trigger each event via debug dropdown: damage flash then green opportunity flash;
      scar pip appears with correct year in tooltip.
- [ ] Cross +1.5 °C: amber vignette + band change log line; +1.75 °C: red vignette.
- [ ] Watch era tint move over an autoplay Safe run: grey early, bright by 2080.
- [ ] Space during year animation skips it; double-tap tempo feels good for 10 turns.
- [ ] H toggles Knowledge Hub in and out mid-run without breaking selection.
- [ ] F3: copy seed, restart same seed, confirm identical first 5 log lines; restart
      seed+1, confirm different world.
- [ ] Full run start-to-end without editor errors or console spam.

## Explicitly not in Phase 3 (scope guard)

Per-region simulation of money/happiness/progress; tile-level gameplay verbs;
negotiation UI beyond the DIP1 target prompt; whole-world isometric map (first Tier B
increment is the home-region diorama only). Any of these re-opens Phase 0 scope review
before implementation (golden rules 3, 11).
