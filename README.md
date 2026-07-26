# The Drawdown Protocol

A rogue-lite climate strategy and diplomacy simulation, built with Godot 4.

You lead a small but credible actor on the world stage — an NGO or pioneering
country — steering the world toward carbon neutrality between 2030 and 2100.
Each year three crises land on the table — droughts, floods, unrest, and the
occasional opportunity — and your policy cards are how you answer them. Cards
cost Money, Influence, or Happiness and pay back resources; played together
they fire combos that chain across the run, and five-year projects grant
permanent powers if you sustain their upkeep. Answering crises well grows
your deck mid-run. Lose a run and the knowledge you gained persists into the
next one.

Full concept: [docs/Concept.md](docs/Concept.md) · Roadmap:
[docs/Plan.md](docs/Plan.md) · Working principles:
[docs/GoldenRules.md](docs/GoldenRules.md)

## Current status

**A playable vertical slice lives in [src/](src/)** and is green end-to-end:

- Full yearly loop 2030–2100: income + project upkeep → **3 crises drawn** →
  play up to 5 cards to answer them → carbon ledger → warming → happiness
  drift → unanswered crises strike → feedback loops → end check.
- Crisis deck of 7 crises + 3 opportunities with response tags, damage,
  riders; a 26-card catalog (20 starting + 6 unlocked by play) with costs in
  Money/Influence/Happiness and resource returns.
- **Combo system**: 8 named tag-set combos fire instantly when the year's
  played tags complete them, with an escalating chain multiplier (+10% per
  chain step, ×2 cap) and first-discovery Knowledge rewards.
- **Long-term projects**: 4 five-year commitments charging yearly upkeep;
  completion grants permanent passive powers (income, absorption, happiness,
  allies); abandoning or failing to pay costs trust.
- 3 one-time feedback loops, Overshoot warming bands, opportunity riders on
  unanswered crises (every crisis is a door).
- Tier A world: 12 procedurally generated regions on a dashboard board with
  panels, ally rings, scars, tooltips, and the grey→solarpunk era tint.
- Meta-progression: Knowledge Points (run formula + in-run combo/opportunity
  Knowledge), Knowledge tree UI, persistent save.
- Step-by-step tutorial: 13 data-driven steps with spotlight cutouts teaching
  crises → cards → combos → projects, advancing on real player actions.
- Deterministic sim (same seed + same decisions = byte-identical records),
  fully data-driven content in `src/data/*.json` — add a card, crisis, combo
  or project without touching code.
- Tests: 14 headless suites / **732 checks passing**, a UI smoke test that
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
| [Phase 5](docs/Phase_5/) | Card/crisis/combo/project catalogs, presentation, validation pipeline | Done |
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
