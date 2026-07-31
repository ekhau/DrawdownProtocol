# The Drawdown Protocol — Playable Prototype

A Godot 4 vertical slice of the rogue-lite climate strategy game specified in
`../docs/`. One run = **15 turns of five years each, 2030–2100** — a race
against the **Climate Clock** (100% = +2.0 °C = defeat). Each turn: **three
events** land, a **market of four project cards** is dealt, you fund what you
can — answering crises, bending the **world blocs'** emission curves, chaining
**combos**, sustaining **three-turn projects** — and the world resolves. Win
the moment global net emissions reach ≤ 0; lose at the tipping point, at zero
Happiness (revolt), or by reaching 2100 still net-positive.

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
# full content pipeline: validator + test suite + 20-seed batch
src/tools/content_check.sh
# individual pieces
godot/bin/godot.linuxbsd.editor.dev.x86_64 --headless --path src --script res://tools/validate_data.gd
godot/bin/godot.linuxbsd.editor.dev.x86_64 --headless --path src --script res://tests/run_tests.gd
godot/bin/godot.linuxbsd.editor.dev.x86_64 --headless --path src --script res://tests/_ui_smoke.gd
godot/bin/godot.linuxbsd.editor.dev.x86_64 --headless --path src --script res://tools/batch_runs.gd -- \
    --seeds 20 --strategy all --enforce --csv /tmp/batch.csv
```

## The loop (one turn = five years)

1. **Turn start** (automatic): income (250 base, +40 per ally, happiness
   penalties), project upkeep charges (pay, complete, or collapse), then
   **3 events are drawn** — droughts, record heat waves, fires, floods, crop
   failures, energy crunches, social crises, and sometimes opportunities.
   Draw weights rise with the warming band. Some events strike on draw (the
   heat wave bakes **+1 Gt/yr into e_extra**, cleared only if answered this
   turn) and some **inject bonus cards into the market** behind a resource
   gate (Heatwave Response Plan appears only while Happiness ≥ 40).
2. **The market is dealt**: 4 weighted offers from your available pool
   (archetype leans shift the odds; diplomacy levers carry raised weights;
   a guarantee rule keeps at least one offer that answers an open event).
   **Funding an offer consumes it** — what you skip is gone with the turn.
3. **Fund cards** — up to 5 a turn, bound by resources. Cards cost Money /
   Influence / **Happiness** (the Industrial Carbon Levy is the dilemma card:
   free in money, −6 Happiness, +35M back). Research bets print their odds
   (Fusion Moonshot 35%, Direct Air Capture 50%) and roll them on play. Tags
   answer the first open crisis that accepts them; tag sets fire **combos**
   whose chain multiplies rewards (+10%/step, ×2 cap); ≥2 combos in one turn
   is a **cascade** with its own fanfare.
4. **World levers**: Form Alliance (allies pay income and damp world drift by
   0.2/turn each), **Emissions Treaty** (−0.8 trend on the steepest bloc),
   **Fund a Transition** (−6 Gt off the biggest emitter — the cheapest tons
   anywhere). No run reaches global net zero without them.
5. **Space resolves**: sink maturation/stress → the global ledger (city
   sectors + world blocs − absorption) → the clock ticks → happiness drift →
   unanswered crises strike → **summit verdict** on turns 4/8/12 (targets
   announced from turn 1; reward or faith-loss) → feedback loops → end check
   → the world's blocs advance their curves. Passing needs a double-Space.

Deck growth: 6 cards unlock mid-run by deeds; the **Public Support Fund**
unlocks permanently by losing a run to the revolt; the Heatwave Response Plan
exists only when a heat wave opens its window.

## Controls

| Input | Effect |
|---|---|
| Mouse | Fund market offers, launch/abandon projects, select regions, choose the alliance partner |
| Space | Resolve the turn (passing with zero cards needs a second Space to confirm) |
| H | Knowledge tree (meta-progression) |
| C | Codex of real climate solutions (entries unlock on first play of each card) |
| F1 or the "?" button | Open/close the step-by-step tutorial |
| F3 | Debug overlay: sim internals, actors, market, autoplay Safe/Risky/Mixed |
| Esc / RMB | Clear selection / cancel the alliance target prompt |

First boot opens the **city picker**: Port City (diplomatic road, starts
allied), Industrial City (rich and filthy, must reinvent), Political Capital
(locked behind the 6-KP Capital Charter node). The choice persists; change it
from any run-end screen ("Change city").

## Architecture

```
scripts/core/     headless, deterministic sim (no node/scene dependencies)
  seed_util.gd        SplitMix64 sub-seed streams (world/events/tiles/names/market/risk)
  world_gen.gd        Tier A procgen: 12 regions, archetypes, shares, start jitter
  region_data.gd      RegionData resource (regions render state, never own it)
  catalog.gd          cards/events/combos/projects/knowledge/actors/archetypes/summits
                      JSON + per-run patching
  run_state.gd        the per-turn pipeline: crisis draw + on-draw spikes, market deal
                      + bonus injection, funded plays with risk rolls, combos, projects,
                      summits, world-actor advance, deck growth, resolution; signals
  climate_calc.gd     ledger/warming/clock/feedback steps as pure functions
  society_calc.gd     income, drift, resilience, crisis weights, combo multiplier
  end_state.gd        end evaluator (tipping/revolt/early-win/timeout) + KP award
  post_mortem.gd      run-end heuristic naming the pivotal turn (never a re-sim)
  turn_record.gd      one immutable record per turn (log = analytics = HUD)
  log_formatter.gd    every player-visible line rendered from data/log_templates.json
  data_validator.gd   collected-report schema validation (boot + CI)
  strategies.gd       scripted Safe / Risky / Mixed archetypes (market-aware autoplay)
scripts/sim.gd      scene-facing owner; scripts/meta_state.gd  Meta autoload
                    (KP, knowledge, defeat-lesson cards, codex, archetype; user:// save)
scripts/ui/         views subscribe to sim signals and render; zero gameplay math
                    (climate clock gauge, market tray, world-blocs dock, codex screen,
                     archetype picker, post-mortem end screen, banners, tutorial)
tools/              validate_data, batch_runs, gen_fixtures, parse_check, content_check.sh
tests/              homemade headless harness (no addon), 17 suites
data/               ALL balance values and content (golden rule 9) — see below
```

Sim → UI flows only through signals (`year_started`, `card_played`,
`crisis_answered`, `combo_triggered`, `card_unlocked`, `project_changed`,
`summit_resolved`, `risk_resolved`, `curve_bent`, `year_advanced`,
`event_struck`, `warming_band_changed`, `ally_changed`, `run_ended`).

## Data files (single authority for all numbers)

| File | Contents |
|---|---|
| `data/cards.json` | the 33-card catalog: costs (incl. happiness), effects, tags, rewards, market weights, risk odds, codex entries, unlock/meta-unlock/bonus-only flags |
| `data/events.json` | event deck: 7 crises + 3 opportunities (weights, damages, responses, riders, on-draw spikes, bonus-card links) + 3 feedback loops |
| `data/combos.json` | 8 tag-set combos: required tags, rewards, effects |
| `data/projects.json` | 4 three-turn projects: per-turn upkeep, completion payoff, abandon penalty |
| `data/world_actors.json` | the 4 world blocs: emissions, trend, floor |
| `data/city_archetypes.json` | 3 starting cities: stat modifiers, market leans, unlock gates |
| `data/summits.json` | the COP calendar: turn, net target, reward, penalty |
| `data/knowledge.json` | 7 Knowledge nodes (patches + grants, incl. the archetype charter) |
| `data/climate.json` | climate constants (K_WARM, clock zero, caps, floors, stress; per-turn) |
| `data/society.json` | income, drift, resilience, market size, revolt threshold, actor damping |
| `data/archetypes.json` | region presets for worldgen (min/max counts, jitter ranges) |
| `data/log_templates.json` | every log/banner line template |
| `data/tutorial.json` | tutorial steps: spotlight target, text, advance rule |

## Implemented

- The 15-turn race as above: income + upkeep → event draw with on-draw spikes
  and bonus injections → market deal → funded plays with combo/answer/risk
  resolution → global ledger → clock → drift → crisis strikes → summits →
  feedbacks → world-actor advance → end check.
- **The Climate Clock** as the single adversary gauge: percent to tipping,
  next-turn forecast tick, per-run sparkline, plunge flash on cascades,
  summit wins, and the drawdown moment.
- **World actors**: four named blocs on rising curves; treaties, funded
  transitions, and allies (0.2 drift damping each) are the only ways to bend
  them; the dock lists each bloc with its drift arrow.
- **The market**: 4 weighted offers per turn (dedicated RNG stream), consumed
  when funded, answer-guarantee rule, archetype tag leans, event bonus cards
  marked "[CRISIS WINDOW]", risk odds printed on the card.
- **Resource-vs-resource dilemmas**: happiness-cost cards (Industrial Carbon
  Levy) with the revolt defeat (happiness 0) closing the loop — and the
  Public Support Fund as that defeat's permanent lesson card.
- **Summits (COPs)** at turns 4/8/12 with pre-announced net targets, HUD
  countdown line, verdict banners, rewards and faith-loss penalties.
- **Push-your-luck research**: Fusion Moonshot (35%) and Direct Air Capture
  (50%), odds on the card, one seeded roll per play.
- **Post-mortem** on every run end: the pivotal turn named per outcome family
  (overheat / revolt / timeout / win), rendered on the end screen.
- **Codex**: every card carries a real-world solution entry; first play
  unlocks it permanently; C opens the collection screen.
- **City archetypes**: Port City / Industrial City / Political Capital
  (meta-locked), with stat modifiers, market leans, and a persistent picker.
- Crisis system, combo chain (+cascade feedback), three-turn projects, deck
  growth, media/window waivers, fire-discount rider, feedback loops,
  Overshoot bands, Tier A procgen board, step-by-step tutorial — all carried
  over and retuned to the per-turn scale.
- Determinism: six SplitMix64 streams (world, events, tiles, names, market,
  risk); same seed + same decisions = byte-identical JSONL records.

## Test results (at time of writing)

- `tests/run_tests.gd`: 17 suites, **727 checks, 0 failures** — climate/clock
  golden values, evaluator truth table incl. revolt and early win, resolver
  matrix incl. the happiness-cost card and meta-lesson gate, crisis semantics,
  combos, projects (3-turn lifecycle), **market suite** (deterministic deal,
  offer consumption, answer guarantee, bonus-card gating, on-draw spikes,
  diplomacy availability), **world suite** (actor curves, damping, fund/treaty
  ops, summit verdicts, archetype starts), pipeline (BAU dies by mid-run,
  determinism replay, curve-bent signal), post-mortem heuristics, validator
  mutation suite (~40 cases), worldgen, board layout, fixtures.
- Fixture regression (canonical seed 2030): **Safe WIN_NEUTRAL 2095, 12 KP ·
  Risky LOSS_REVOLT 2065, 3 KP · Mixed WIN_NEUTRAL 2095, 12 KP** —
  byte-for-byte against `tests/fixtures/seed2030_expected.csv`.
- 20-seed × 3-strategy batch: **rate corridor** — Risky never wins (it
  ignores the world's blocs, so global net cannot reach zero); Safe wins
  12/20, Mixed 11/20 (floors 50% / 40%). Market variance is deliberate:
  scripted strategies cannot always win; human play outperforms them.
- `tests/_ui_smoke.gd`: boots the real scene headless and drives the city
  picker, market funding with codex discovery, offer consumption, pass
  confirm, DIP1 targeting, project launch, hub + codex toggles, autoplay to a
  finished run with post-mortem, restart with archetype carry-over, knowledge
  patch application, and the full tutorial.

## Spec deviations (deliberate, with reasons)

1. **Additive-content invariance now applies to bonus-only cards.** The
   market deals from the whole pool, so adding a normal card legitimately
   shifts timelines (it changes the deal); only `bonus_only` cards are
   timeline-neutral additions. The T10-P5 test is reframed accordingly.
2. **The structural corridor is a rate corridor.** With a dealt market,
   "Safe/Mixed always win" is impossible by design; the batch enforces
   risky-never-wins plus win-rate floors instead.
3. **Card names shortened** to fit the ≤ 24-char validator rule (C2).
4. **`ERR_INSUFFICIENT_FUNDS` does not exist in Godot** — the Phase 4 spec
   names a fictional constant; `ERR_CANT_ACQUIRE_RESOURCE` is used, and the
   UI reads string reason codes (`no_money`, `not_in_market`, …) instead.
5. **Resolution beat is instant, not a timed replay**: values update
   immediately; banners play as a non-blocking queue and Space clears them.
6. **Market chips single-click fund** (no expand-then-Enact step). DIP1 still
   opens its target prompt; project abandonment needs a confirming click.
7. **Actor targeting is automatic** (fund = biggest emitter, treaty =
   steepest curve) to keep diplomacy one-click; per-bloc targeting is
   deferred until playtests demand it.

## Cut / stubbed (per GoldenRules: cut, don't half-build)

- **Tier B isometric diorama** (spec frozen in Phase 3 docs;
  `STREAM_TILES` reserved in `seed_util.gd`).
- Audio, save/load mid-run, JSONL-to-disk analytics writer, title screen /
  export presets (Plan.md Phase 9).
- `alliance_affinity` is generated and displayed but has no cost effect.
- Player-directed crisis assignment (cards auto-answer in draw order).
- Archetype-exclusive cards (archetypes shape the market by weights only, a
  noted future deepening).

## Content pipeline (add content without touching code)

1. Edit `data/cards.json` / `events.json` / `combos.json` / `projects.json` /
   `world_actors.json` / `city_archetypes.json` / `summits.json`
   (templates in `../docs/Phase_5/01` and `02`).
2. `src/tools/content_check.sh` — validator + fixtures + 20-seed batch.
3. If a *tuning* change moved the fixtures: inspect the diff, update the
   Phase 1 docs first, then `tools/gen_fixtures.gd` to re-pin.
