# The Drawdown Protocol

A rogue-lite climate strategy and diplomacy simulation, built with Godot 4.

You lead a small but credible actor on the world stage — an NGO or pioneering
country — steering the world toward carbon neutrality between 2030 and 2100.
Each year you play one policy card, balancing three pillars (Money, Carbon
balance, Happiness) while disasters stress-test what you've built. Lose a run
and the knowledge you gained persists into the next one.

Full concept: [docs/Concept.md](docs/Concept.md) · Roadmap:
[docs/Plan.md](docs/Plan.md) · Working principles:
[docs/GoldenRules.md](docs/GoldenRules.md)

## Current status

**A playable vertical slice lives in [src/](src/)** and is green end-to-end:

- Full yearly loop 2030–2100: income → one policy card (or pass) → carbon
  ledger → warming → happiness drift → events → feedback loops → end check.
- 15-card Policy Board, 4 extreme events with opportunity riders, 3 one-time
  feedback loops, diplomacy cards, and Overshoot warming bands.
- Tier A world: 12 procedurally generated regions on a dashboard board with
  panels, ally rings, scars, tooltips, and the grey→solarpunk era tint.
- Meta-progression: Knowledge Points, Knowledge tree UI, persistent save.
- Step-by-step tutorial: 12 data-driven steps with spotlight cutouts,
  advancing on real player actions; auto-opens once, re-openable via `?`/F1.
- Deterministic sim (same seed + same decisions = byte-identical records),
  fully data-driven content in `src/data/*.json` — add a card without
  touching code.
- Tests: 11 headless suites / **501 checks passing**, a UI smoke test that
  drives the real scene to a win, golden-fixture regression, and a
  20-seed × 3-strategy batch harness (Safe/Mixed always win, Risky never
  does).

See [src/README.md](src/README.md) for how to run it, controls, architecture,
and deliberate deviations from the specs.

### Design phases (docs/)

| Phase | Contents | Status |
|---|---|---|
| [Phase 0](docs/Phase_0/) | Design brief, pillars, MVP scope, metric dictionary, risks | Done |
| [Phase 1](docs/Phase_1/) | Paper balance model, sample runs, event/policy tables | Done |
| Phase 2 | Project setup | Folded into the prototype |
| [Phase 3](docs/Phase_3/) | World model, procgen, board rendering, interaction | Done (Tier A implemented; Tier B isometric diorama deferred) |
| [Phase 4](docs/Phase_4/) | Core simulation engine specs | Done |
| [Phase 5](docs/Phase_5/) | Card/event catalogs, presentation, validation pipeline | Done |
| Phases 6–7 | Meta-progression, UX and feedback | Implemented in the prototype |
| Phases 8–9 | Balancing iteration, packaging/export | Not started |

Cut or stubbed for the MVP (per the golden rules: cut, don't half-build):
Tier B isometric diorama, audio, mid-run save/load, title screen, export
presets.

## Quick start

Requires a Godot 4 editor binary (this checkout uses a local engine build in
`godot/bin/`, which is gitignored — any Godot 4.x should work):

```sh
godot --path src                                            # play
godot --headless --path src --import                        # first import after checkout
src/tools/content_check.sh                                  # validator + test suite + batch (~5 s)
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
