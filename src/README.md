# The Drawdown Protocol — Playable Prototype

A Godot 4 vertical slice of the rogue-lite climate strategy game specified in
`../docs/`. One run = 2030–2100. Each year **three crises** land; you answer
them with policy cards (up to five a year), chain **combos**, and sustain
**five-year projects**; win by reaching 2100 carbon-neutral (net emissions
≤ 0) below +2.0 °C of warming.

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
# full content pipeline: validator + 732-check test suite + 20-seed batch (~10 s)
src/tools/content_check.sh
# individual pieces
godot/bin/godot.linuxbsd.editor.dev.x86_64 --headless --path src --script res://tools/validate_data.gd
godot/bin/godot.linuxbsd.editor.dev.x86_64 --headless --path src --script res://tests/run_tests.gd
godot/bin/godot.linuxbsd.editor.dev.x86_64 --headless --path src --script res://tests/_ui_smoke.gd
godot/bin/godot.linuxbsd.editor.dev.x86_64 --headless --path src --script res://tools/batch_runs.gd -- \
    --seeds 20 --strategy all --enforce --csv /tmp/batch.csv
```

## The loop (one year)

1. **Year start** (automatic): income (+20 per ally, happiness penalties),
   project upkeep charges (pay, complete, or collapse), then **3 crises are
   drawn** from the crisis deck — droughts, heat waves, fires, floods, crop
   failures, energy crunches, social crises, and sometimes opportunities
   (summits, investment waves, movements). Draw weights rise with the warming
   band; social crises surge below 40 happiness and calm under media.
2. **Play cards** — up to 5 a year, bound by resources. A card costs Money /
   Influence / Happiness, applies its effects, pays its printed returns, and
   its **tags** answer the first open crisis that accepts them. Answered
   crises are contained on the spot: no damage, plus a response reward.
3. **Combos**: when the year's played tags complete a combo from
   `data/combos.json` (e.g. mobility + energy = Green Corridor), it fires
   instantly — banner, bonus resources, sometimes effects. Every combo grows
   the **chain**; each chain step adds +10% to combo rewards (×2 cap); a
   comboless year shrinks the chain by 1. Knowledge rewards on combos pay
   only on first discovery per run.
4. **Projects** (optional): launch a five-year project (max 2 active); it
   charges upkeep every year. Completion grants instant effects plus a
   permanent passive (income, influence, happiness/yr, absorption/yr).
   Abandoning — or failing to pay — costs happiness and influence, once.
5. **Space resolves**: sink maturation/stress → ledger → warming → happiness
   drift → **unanswered crises strike** (scaled by resilience; only a crisis
   that actually hits opens its opportunity rider) → feedback loops → end
   check. Passing (zero cards) needs a double-Space confirm.

Deck growth: 6 of the 26 cards start locked and join the pool mid-run when
the run earns them — crises answered, combos fired, allies won, sectors
transformed, projects completed. The unlock moment is the reward.

## Controls

| Input | Effect |
|---|---|
| Mouse | Play cards, launch/abandon projects, select regions, choose the DIP1 alliance partner |
| Space | Resolve the year (passing with zero cards needs a second Space to confirm) |
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
  catalog.gd          cards/events/combos/projects/knowledge JSON + per-run patching
  run_state.gd        the yearly pipeline: crisis draw, multi-card plays, combos,
                      projects, deck growth, resolution; signals
  climate_calc.gd     ledger/warming/feedback steps as pure functions
  society_calc.gd     income, drift, resilience, crisis weights, combo multiplier
  end_state.gd        end evaluator with reason codes + KP award
  turn_record.gd      one immutable record per year (log = analytics = HUD)
  log_formatter.gd    every player-visible line rendered from data/log_templates.json
  data_validator.gd   collected-report schema validation (boot + CI)
  strategies.gd       scripted Safe / Risky / Mixed archetypes (autoplay, batches)
scripts/sim.gd      scene-facing owner; scripts/meta_state.gd  Meta autoload (KP save)
scripts/ui/         views subscribe to sim signals and render; zero gameplay math
tools/              validate_data, batch_runs, gen_fixtures, parse_check, content_check.sh
tests/              homemade headless harness (no addon), 14 suites, 732 checks
data/               ALL balance values and content (golden rule 9) — see below
```

The UI is built programmatically from `main.gd` (one `main.tscn` root); every
view is its own class in `scripts/ui/`. Sim → UI flows only through signals
(`year_started`, `card_played`, `crisis_answered`, `combo_triggered`,
`card_unlocked`, `project_changed`, `year_advanced`, `event_struck`,
`warming_band_changed`, `ally_changed`, `run_ended`).

## Data files (single authority for all numbers)

| File | Contents |
|---|---|
| `data/cards.json` | the 26-card catalog: costs, effects, tags, rewards, unlock conditions (Phase 5 doc 01) |
| `data/events.json` | crisis deck: 7 crises + 3 opportunities (weights, damages, responses, riders) + 3 feedback loops (Phase 5 doc 02) |
| `data/combos.json` | 8 tag-set combos: required tags, rewards, effects |
| `data/projects.json` | 4 five-year projects: upkeep, completion payoff, abandon penalty |
| `data/knowledge.json` | 6 Knowledge nodes (patches + grants) |
| `data/climate.json` | Phase 1 climate constants (K_WARM, caps, floors, stress) |
| `data/society.json` | income, drift, resilience, crisis/combo/project constants |
| `data/archetypes.json` | region presets, min/max counts, jitter ranges |
| `data/log_templates.json` | every log/banner line template |
| `data/board_layout.json` | Tier A dashboard slots (copy of `../data/board_layout.json`) |
| `data/tutorial.json` | tutorial steps: spotlight target, text, advance rule (validated: rules TU1-TU4) |

## Implemented

- Full yearly loop 2030–2100 as above: income + upkeep → crisis draw →
  multi-card plays with combo/answer resolution → ledger → warming → drift →
  unanswered crisis strikes → feedbacks → end check.
- Crisis system: weighted 3-of-10 draw without replacement, band escalation,
  social-state weight modifiers, per-crisis response tags and rewards,
  answered-equals-contained semantics, riders only on real hits.
- Combo system: tag-multiset matching over the year's plays, once per combo
  per year, instant application, chain counter with reward multiplier
  (+10%/step, ×2 cap, −1 decay on comboless years), first-discovery-only
  Knowledge rewards.
- Long-term projects: launch pays year one, upkeep at every year start,
  completion effects + stacking permanent passives, fail/abandon penalties,
  two-active cap, one attempt per project per run.
- Deck growth: unlock conditions (crises answered, combos, allies, sector
  progress, projects completed) checked on play and completion; unlocked
  cards appear in the tray with a banner; locked cards are hidden until then.
- Three-sector model with the 70% tech cap lifted by sufficiency cards;
  carbon ledger (E vs A, net drives warming, 4× slower cooling, floors).
- Diplomacy as cards: Form Alliance with flavor-only partner targeting,
  Joint Transition Project, Climate Club (unlockable), ally income.
- Media/window waiver rules (C1 semantics) and the fire-discount rider on
  restoration cards; three one-time feedback loops; Overshoot bands with
  vignette + interstitials in both directions.
- Tier A world: 12 procgen regions, dashboard board, region panels with E/A
  mini-bars, ally rings, scars, tooltips + click inspector, era tint.
- UI: crisis panel (right dock) with live open/answered states, Policy Board
  grouped by category + Projects column + explicit end-year chip, combo
  banners with chain multiplier, chain label in the HUD, unlock banners.
- Turn log rendered from TurnRecords via templates: crisis draw line, per-play
  effect/reward/answer lines, combo lines, project events, unanswered hits
  (damage first, opportunity second), unlocks, feedbacks, endings.
- Meta-progression: KP formula (decades + sectors ≥ 70 + allies/2 + 3 on win)
  **plus in-run Knowledge** from combo discoveries and seized opportunities;
  Knowledge tree UI; persistence in `user://knowledge_save.json`.
- Determinism: SplitMix64 sub-seed streams; `rng_events` consumed only by the
  year-start crisis draw (3 × pick + target, fixed order); same seed + same
  decisions = byte-identical records.
- Debug: F3 overlay, headless batch harness with CSV, data validator (boot
  fail-loud + CI exit codes).
- Step-by-step tutorial (GoldenRules #7): 13 data-driven steps teaching the
  pillars, warming gauge, crisis bar, board/regions, the Policy Board with
  costs/tags/returns, answering a crisis, combos and the chain, launching a
  project, resolving, the log, Knowledge, and win/lose. Action steps advance
  on real sim signals (region selected, card played, project started, year
  resolved, hub opened); auto-opens once; persists completed/dismissed.

## Test results (at time of writing)

- `tests/run_tests.gd`: 14 suites, **732 checks, 0 failures** — covers the
  Phase 3 checklist, Phase 4 (golden climate values, evaluator truth table,
  resolver validation matrix incl. multi-play limit and locked cards,
  stacking/caps, waiver precedence, resilience multipliers, crisis weight
  formula, feedback one-shots, determinism replay, signal audit, KP anchors),
  the new crisis/combo/project suites (draw determinism, contained-vs-struck
  semantics, rider gating, combo matching/chain/decay/cap, project lifecycle
  incl. failure and abandonment, deck-growth unlocks), and Phase 5
  (validator pass + ~30-case mutation suite, discount path, additive-content
  invariance).
- `tests/_ui_smoke.gd`: boots the real scene headless and drives multi-card
  play, the turn limit, pass confirm, DIP1 targeting, project launch,
  inspector, hub, autoplay to a WIN, KP award, restart, knowledge patch
  application, and the tutorial (auto-open, real-action advancement including
  the project step, mid-way close with persisted flag, no auto-reshow,
  re-open, full 13-step completion) — passes.
- Fixture regression: canonical seed-2030 Safe/Risky/Mixed reproduce the
  stored golden CSV byte-for-byte, with the anchors:
  **Safe WIN 18 KP (6 allies, ~59 combos, Global Sink Trust completed) ·
  Risky LOSS_LIMIT_BREACHED in 2064 with 4 KP (bled by unanswered crises,
  all three feedback loops fired) · Mixed WIN 18 KP (full coalition,
  Continental Rail Compact completed).**
- 20-seed × 3-strategy batch: Safe and Mixed win on all 20 jittered seeds,
  Risky never wins (loss years 2055–2068; 0 structural violations).

## Spec deviations (deliberate, with reasons)

1. **Phase 1 sample-run decade tables are not byte-reproduced.** The paper
   model's throwaway script was never committed (golden rule 4); the
   re-authored strategy scripts hit the same structural outcomes, and the
   self-generated golden fixture (`tests/fixtures/seed2030_expected.csv`,
   regenerate via `tools/gen_fixtures.gd`) pins this implementation.
2. **Card names shortened** to fit the ≤ 24-char validator rule (C2).
3. **`ERR_INSUFFICIENT_FUNDS` does not exist in Godot** — the Phase 4 spec
   names a fictional constant; `ERR_CANT_ACQUIRE_RESOURCE` is used, and the
   UI reads string reason codes (`no_money`, `turn_limit`, …) instead.
4. **Validator rule E8** (event `order` renumbering vs the previous committed
   file version) is not implemented — it requires version history.
5. **C9 guardrail** applies to non-sufficiency sector cards only.
6. **Resolution beat is instant, not a timed replay**: values update
   immediately; banners play as a non-blocking queue and Space clears them.
7. **Card chips single-click play** (no expand-then-Enact step). DIP1 still
   opens its target prompt; project abandonment needs a second confirming
   click.
8. **Locked (unlockable) cards are hidden**, deliberately breaking the old
   "cards are never hidden" rule for the deck-growth pool only: the unlock
   moment is designed as a reward beat. Blocked-but-available cards still
   always show their reason.

## Cut / stubbed (per GoldenRules: cut, don't half-build)

- **Tier B isometric diorama** (spec frozen in Phase 3 docs;
  `STREAM_TILES` is reserved in `seed_util.gd`).
- Audio, save/load mid-run, JSONL-to-disk analytics writer (records keep the
  full run in memory; `TurnRecord.to_jsonl_line()` exists and is used by
  tests), title screen / export presets (Plan.md Phase 9).
- `alliance_affinity` is generated and displayed but has no cost effect.
- Player-directed crisis assignment (a card auto-answers the first open
  matching crisis in draw order; choosing which crisis to answer with which
  card is deferred until playtests demand it).
- Log pin glyphs for open opportunity flags.

## Content pipeline (add a card, crisis, combo or project without touching code)

1. Edit `data/cards.json` / `events.json` / `combos.json` / `projects.json`
   (templates in `../docs/Phase_5/01_Card_Catalog_Data.md` and
   `02_Event_Catalog_Data.md`).
2. `src/tools/content_check.sh` — validator + fixtures + 20-seed batch, < 15 s.
3. If a *tuning* change moved the fixtures: inspect the diff, update the
   Phase 1 docs first, then `tools/gen_fixtures.gd` to re-pin.
