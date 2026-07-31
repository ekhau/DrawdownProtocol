# The Drawdown Protocol

A rogue-lite climate strategy and diplomacy simulation, built with Godot 4.

You lead one city-state in a race against the **Climate Clock**: 15 turns of
five years each, 2030–2100, to make the *whole world* absorb more carbon than
it emits — before warming crosses the +2.0 °C tipping point. Each turn deals
three events (droughts, record heat waves, unrest, the odd opportunity) and a
market of project cards to fund with Money, Influence, or even Happiness.
Answer the crises, bend the great powers' emission curves with treaties and
funded transitions, chain combos into a compounding engine, and pass the
five-yearly summits — reach global net zero at any turn and the run is won on
the spot. Overheat, or let Happiness hit zero and the city revolt, and it is
lost — but every ending pays Knowledge, some defeats unlock new cards, and
every card you ever fund teaches its real-world solution in the Codex.

Full concept: [docs/Concept.md](docs/Concept.md) · Roadmap:
[docs/Plan.md](docs/Plan.md) · Working principles:
[docs/GoldenRules.md](docs/GoldenRules.md)

## Current status

**A playable vertical slice lives in [src/](src/)** and is green end-to-end:

- The full 15-turn race 2030–2100: income + project upkeep → **3 events
  drawn** (some spike emissions on draw; some inject bonus cards into the
  market behind resource gates) → a **market of 4 offers** dealt from your
  pool → fund up to 5 cards → global ledger → the clock ticks → summit
  verdicts → feedback loops → the world's blocs advance their curves.
- **The Climate Clock as the adversary**: a single HUD gauge (0–100%, tipping
  at 100% = +2.0 °C) with next-turn forecast and the run's curve as a
  sparkline; it climbs by itself every turn because four named **world
  blocs** keep emitting — only treaties, funded transitions abroad, and
  allies bend them.
- Defeats: the tipping point, **the revolt** (Happiness 0 — and losing that
  way permanently unlocks the Public Support Fund), or a net-positive 2100.
  Victory: **carbon neutrality at any turn**, with the curve visibly
  plunging.
- 33-card catalog with happiness-cost dilemma cards (Industrial Carbon
  Levy), **push-your-luck research** with odds printed on the card (Fusion
  Moonshot 35%, Direct Air Capture 50%), event-injected bonus cards, deck
  growth, and a **codex entry on every card** (C key) unlocked by first play.
- **3 starting city archetypes** — Port City, Industrial City, and the
  meta-locked Political Capital — with different stats, market leans, and
  strategic identities; picker on first boot, persistent across runs.
- **Summits (COPs)** at turns 4/8/12 with targets announced from turn 1,
  rewards on success and faith-loss on failure; 8 tag-set **combos** with the
  chain multiplier and cascade feedback; 4 three-turn **projects** with
  permanent passives.
- **Run-end post-mortem** naming the pivotal turn per outcome family
  (overheat / revolt / timeout / the drawdown moment).
- Tier A world: 12 procedurally generated regions on a dashboard board, plus
  the world-blocs panel; meta-progression: Knowledge tree (7 nodes), defeat
  lessons, codex collection, archetype unlock; 13-step tutorial.
- Deterministic sim (six seeded streams; same seed + same decisions =
  byte-identical records), fully data-driven content in `src/data/*.json` —
  add a card, crisis, combo, project, world bloc, archetype, or summit
  without touching code.
- Tests: 17 headless suites / **727 checks passing**, a UI smoke test driving
  the real scene through the city picker, market, and post-mortem, golden
  fixture regression (canonical anchors: Safe WIN 2095 · Risky REVOLT 2065 ·
  Mixed WIN 2095), and a 20-seed × 3-strategy batch enforcing the rate
  corridor (Risky never wins; Safe ≥ 50%, Mixed ≥ 40% — market variance is a
  design feature).

See [src/README.md](src/README.md) for how to run it, controls, architecture,
and deliberate deviations from the specs.

### Design phases (docs/)

| Phase | Contents | Status |
|---|---|---|
| [Phase 0](docs/Phase_0/) | Design brief, pillars, MVP scope, metric dictionary, risks | Done (clock-race redesign) |
| [Phase 1](docs/Phase_1/) | Paper balance model, sample runs, event/policy tables | Done (per-turn model) |
| Phase 2 | Project setup | Folded into the prototype |
| [Phase 3](docs/Phase_3/) | World model, procgen, board rendering, interaction | Done (Tier A implemented; Tier B isometric diorama deferred) |
| [Phase 4](docs/Phase_4/) | Core simulation engine specs (incl. post-mortem) | Done |
| [Phase 5](docs/Phase_5/) | Card/event/actor/summit catalogs, presentation, validation | Done |
| Phases 6–7 | Meta-progression, UX and feedback | Implemented in the prototype |
| Phases 8–9 | Balancing iteration, packaging/export | Not started (open tuning list in Phase 1/06) |

Cut or stubbed for the MVP (per the golden rules: cut, don't half-build):
Tier B isometric diorama, audio, mid-run save/load, title screen, export
presets, archetype-exclusive cards.

## Quick start

Requires a Godot 4 editor binary (this checkout uses a local engine build in
`godot/bin/`, which is gitignored — any Godot 4.x should work):

```sh
godot --path src                                            # play
godot --headless --path src --import                        # first import after checkout
src/tools/content_check.sh                                  # validator + test suite + batch
```

## Repository layout

| Path | Contents |
|---|---|
| [docs/](docs/) | Concept, roadmap, golden rules, and per-phase design specs |
| [src/](src/) | The Godot 4 prototype (scripts, scenes, data, tests, tools) |
| [data/](data/) | Board layout design notes and mockup for the Tier A dashboard |
| [proto_olivier/](proto_olivier/) | Partner prototype workspace (placeholder) |
| `godot/` | Local Godot engine source + prebuilt binary (untracked) |
| [agents/](agents/), [.claude/](.claude/) | Claude Code agent profiles (game dev, solarpunk UI art) |
