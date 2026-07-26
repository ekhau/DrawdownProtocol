# The Drawdown Protocol — Playable Prototype

A Godot 4 vertical slice of the rogue-lite climate strategy game specified in
`../docs/`. One run = 2030–2100, one policy card per year; win by reaching 2100
carbon-neutral (net emissions ≤ 0) below +2.0 °C of warming.

## Run it

Editor / play:

```sh
godot/bin/godot.linuxbsd.editor.dev.x86_64 --path src            # play
godot/bin/godot.linuxbsd.editor.dev.x86_64 --path src --editor   # open editor
```

(from the repo root, using the prebuilt binary in `godot/bin/`).

Headless verification (all green from a clean checkout):

```sh
# import once after checkout
godot/bin/godot.linuxbsd.editor.dev.x86_64 --headless --path src --import
# full content pipeline: validator + 501-check test suite + 20-seed batch (~5 s)
src/tools/content_check.sh
# individual pieces
godot/bin/godot.linuxbsd.editor.dev.x86_64 --headless --path src --script res://tools/validate_data.gd
godot/bin/godot.linuxbsd.editor.dev.x86_64 --headless --path src --script res://tests/run_tests.gd
godot/bin/godot.linuxbsd.editor.dev.x86_64 --headless --path src --script res://tests/_ui_smoke.gd
godot/bin/godot.linuxbsd.editor.dev.x86_64 --headless --path src --script res://tools/batch_runs.gd -- \
    --seeds 20 --strategy all --enforce --csv /tmp/batch.csv
```

## Controls

| Input | Effect |
|---|---|
| Mouse | Pick policy cards, select regions, choose the DIP1 alliance partner |
| Space | Resolve the year (passing needs a second Space to confirm) |
| H | Knowledge tree (meta-progression) |
| F1 or the "?" button (top-right) | Open/close the step-by-step tutorial |
| F3 | Debug overlay: sim internals, world table, autoplay Safe/Risky/Mixed, restart same seed / seed+1 |
| Esc / RMB | Clear selection / cancel the alliance target prompt |

The tutorial opens automatically on a fresh profile and never re-shows once
completed or dismissed (flag persisted in `user://knowledge_save.json`);
re-open it any time with `?` or F1.

## Architecture

```
scripts/core/     headless, deterministic sim (no node/scene dependencies)
  seed_util.gd        SplitMix64 sub-seed streams (world/events/tiles/names)
  world_gen.gd        Tier A procgen: 12 regions, archetypes, shares, start jitter
  region_data.gd      RegionData resource (regions render state, never own it)
  catalog.gd          cards/events/knowledge JSON + per-run knowledge patching
  run_state.gd        the 8-step yearly pipeline, signals, one-card lock
  climate_calc.gd     steps 3/4/7 as pure functions (constants from data/)
  society_calc.gd     steps 1/5/6 formulas (income, drift, resilience, crises)
  end_state.gd        step 8 evaluator with reason codes + KP award
  turn_record.gd      one immutable record per year (log = analytics = HUD)
  log_formatter.gd    every player-visible line rendered from data/log_templates.json
  data_validator.gd   collected-report schema validation (boot + CI)
  strategies.gd       scripted Safe / Risky / Mixed archetypes (autoplay, batches)
scripts/sim.gd      scene-facing owner; scripts/meta_state.gd  Meta autoload (KP save)
scripts/ui/         views subscribe to sim signals and render; zero gameplay math
tools/              validate_data, batch_runs, gen_fixtures, parse_check, content_check.sh
tests/              homemade headless harness (no addon), 11 suites, 501 checks
data/               ALL balance values and content (golden rule 9) — see below
```

The UI is built programmatically from `main.gd` (one `main.tscn` root); every
view is its own class in `scripts/ui/`. Sim → UI flows only through signals
(`year_started`, `card_played`, `year_advanced`, `event_struck`,
`warming_band_changed`, `ally_changed`, `run_ended`).

## Data files (single authority for all numbers)

| File | Contents |
|---|---|
| `data/cards.json` | the 15-card catalog (Phase 5 doc 01) |
| `data/events.json` | 4 extreme events + 3 feedback loops (Phase 5 doc 02) |
| `data/knowledge.json` | 6 Knowledge nodes (patches + grants) |
| `data/climate.json` | Phase 1 climate constants (K_WARM, caps, floors, stress) |
| `data/society.json` | income, drift, resilience, KP constants |
| `data/archetypes.json` | region presets, min/max counts, jitter ranges |
| `data/log_templates.json` | every log/banner line template |
| `data/board_layout.json` | Tier A dashboard slots (copy of `../data/board_layout.json`) |
| `data/tutorial.json` | tutorial steps: spotlight target, text, advance rule (validated: rules TU1-TU4) |

## Implemented

- Full yearly loop 2030–2100: income → one card (or explicit pass) → ledger →
  warming → happiness drift → events → feedback loops → end check.
- Three-sector model with the 70% tech cap lifted by sufficiency cards;
  carbon ledger (E vs A, net drives warming, 4× slower cooling, floors).
- Diplomacy as cards: Form Alliance with flavor-only partner targeting (modal
  prompt per interaction spec), Joint Transition Project, ally income.
- Events with opportunity riders (fire→restoration discount, flood→transport
  rebuild, social crisis→policy window) and the media/window waiver rules
  (C1 semantics: media waives without consuming a banked window).
- Three one-time feedback loops (permafrost +2E at 1.75, ocean −2A at 1.90,
  Amazon −3A after 3 fires), Overshoot bands with vignette + interstitials in
  both directions (the descent is celebrated).
- Tier A world: 12 procgen regions (seeded archetypes, shares, names, tags),
  dashboard board from `board_layout.json`, region panels with E/A mini-bars,
  ally rings (border colors), scars, hover tooltips + click inspector,
  grey→solarpunk era tint keyed to average sector progress.
- Full 15-card Policy Board (no draw — Phase 5 doc 03 reconciliation): cards
  never hidden, every blocked state shows its live reason from `can_play`
  codes, fire-discount prices shown live, forecast tooltips ("57% → 67%").
- Turn log rendered from TurnRecords via templates; banner beats damage-first
  then opportunity; run-end screen rendered from the terminal record.
- Meta-progression: KP formula (decades + sectors ≥ 70 + allies/2 + 3 on win),
  Knowledge tree UI, persistence in `user://knowledge_save.json`, catalog
  patches and grants applied at next-run init (never mid-run).
- Determinism: SplitMix64 sub-seed streams, `rng_events` consumed only in
  step 6 in fixed order; same seed + same decisions = byte-identical records.
- Debug: F3 overlay (header, flags, feedback armed/triggered, world table,
  log tail, autoplay buttons, restart same/next seed, copy seed), headless
  batch harness with CSV, data validator (boot fail-loud + CI exit codes).
- Step-by-step tutorial (GoldenRules #7): 12 data-driven steps covering the
  pillars, warming gauge, board/regions, Policy Board + one-card lock and the
  sufficiency cap, resolving/passing, events and resilience, diplomacy,
  Knowledge, and win/lose. Each step dims the screen with a spotlight cutout
  over the relevant control (non-blocking - the player performs the real
  action); action steps advance on the real sim signal (region selected, card
  enacted, year resolved, hub opened), informational steps on Next. Closable
  on every step; auto-opens once, persists completed/dismissed in Meta,
  re-openable via "?" or F1. UI-layer only; steps validated by the pipeline.

## Test results (at time of writing)

- `tests/run_tests.gd`: 11 suites, **501 checks, 0 failures** — covers the
  Phase 3 checklist (T1–T5, T8–T12 equivalents), Phase 4 (T1–T15 equivalents:
  golden climate values, evaluator truth table, resolver validation matrix,
  stacking/caps, waiver precedence, resilience multipliers, social-crisis
  formula, feedback one-shots, determinism replay, signal audit, KP anchors),
  and Phase 5 (validator pass + ~14-case mutation suite, discount path,
  additive-content invariance, social-crisis flatness).
- `tests/_ui_smoke.gd`: boots the real scene headless and drives card play,
  one-card lock, pass confirm, DIP1 targeting, inspector, hub, autoplay to a
  WIN, KP award, restart, knowledge patch application, and the tutorial
  (auto-open, real-action advancement, mid-way close with persisted flag,
  no auto-reshow, re-open, full 12-step completion) — passes.
- Fixture regression: canonical seed-2030 Safe/Risky/Mixed reproduce the
  stored golden CSV byte-for-byte, with the Phase 1 anchors:
  **Safe WIN 15 KP · Risky LOSS_LIMIT_BREACHED in 2099 with 9 KP (sectors
  frozen at 70%) · Mixed WIN 16 KP with 6 allies.**
- 20-seed × 3-strategy batch: Safe and Mixed win on all 20 jittered seeds,
  Risky never wins (0 structural violations).

## Spec deviations (deliberate, with reasons)

1. **Phase 1 sample-run decade tables are not byte-reproduced.** The paper
   model's throwaway script and its exact RNG call sequence were never
   committed (golden rule 4), so T13-P4's "reproduce every decade-table row"
   is unachievable literally. Instead: re-authored strategy scripts hit the
   same structural outcomes and KP anchors (above; Risky's warming trajectory
   matches the Run B table within ~0.01 °C per decade), and a self-generated
   golden fixture (`tests/fixtures/seed2030_expected.csv`, regenerate via
   `tools/gen_fixtures.gd`) pins this implementation against regression.
2. **Card names shortened**: "Peatland & Ocean Restoration" → "Peatland &
   Ocean Repair", "Adaptation Infrastructure" → "Adaptive Infrastructure".
   The Phase 5 catalog's own names violated its own C2 rule (≤ 24 chars);
   the validator caught it, data was fixed, rule kept.
3. **`ERR_INSUFFICIENT_FUNDS` does not exist in Godot** — the Phase 4 spec
   names a fictional constant; `ERR_CANT_ACQUIRE_RESOURCE` is used, and the
   UI reads string reason codes (`no_money`, `no_influence`, …) instead.
4. **Validator rule E8** (event `order` renumbering vs the previous committed
   file version) is not implemented — it requires version history.
5. **C9 guardrail** applies to non-sufficiency sector cards only (doc 01's
   wording); applying it to all sector cards would flag AGR1 (16.7 per 100)
   and contradict doc 06's "no warnings in cards".
6. **Resolution beat is instant, not a 0.8 s timed replay**: values update
   immediately; event banners play as a non-blocking queue and Space clears
   them. Immediate feedback (golden rule 8) kept; cinematic pacing cut.
7. **Card chips single-click enact** (no expand-then-Enact step); the model's
   one-card lock plus the pass double-confirm keep every quality gate. DIP1
   still opens its target prompt.

## Cut / stubbed (per GoldenRules: cut, don't half-build)

- **Tier B isometric diorama** (nice-to-have; spec frozen in Phase 3 docs for
  later — `STREAM_TILES` is reserved in `seed_util.gd`).
- Audio, save/load mid-run, JSONL-to-disk analytics writer (records
  keep the full run in memory; `TurnRecord.to_jsonl_line()` exists and is
  used by tests), title screen / export presets (Plan.md Phase 9).
- `alliance_affinity` is generated and displayed but has no cost effect (as
  specified: declared tuning knob, no effect in MVP).
- Log pin glyphs for open opportunity flags (flags are visible in card
  prices, banner beats and F3 instead).

## Content pipeline (add a card without touching code)

1. Edit `data/cards.json` (template in `../docs/Phase_5/01_Card_Catalog_Data.md`).
2. `src/tools/content_check.sh` — validator + fixtures + 20-seed batch, < 10 s.
3. If a *tuning* change moved the fixtures: inspect the diff, update the
   Phase 1 docs first, then `tools/gen_fixtures.gd` to re-pin.
