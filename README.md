# The Drawdown Protocol

A rogue-lite deckbuilder about fighting global warming. Each run is a simulated timeline: steer one city from **+1.5° in 2030** to **carbon neutrality before the world hits +2.0°**. Timelines fail — that's the job. Every failed run is data, every won run is a blueprint.

**Status (2026-08-01): first playable prototype.** The project restarted from a blank slate on 2026-07-31 (previous design cycles live in git history up to commit `8d76938`); the MVP was designed, specced, implemented, and balance-tested the next day. It runs, the headless test suite passes 14/14, and the balance harness hits its targets. What it needs now is human playtesting.

## The game in one paragraph

One turn = one year. Every year: face a **crisis** (2–3 responses, every one costly — pay money, spend support, or take a permanent scar; costs climb with the thermometer; rare **windfalls** bring good news with a sting), then **buy policy cards** from a market, collect **income** (dirty sectors pay now, emit forever), and watch the **climate** advance by your net emissions. Win by reaching structural net zero; lose at +2.0° or when support collapses. Three eras deepen the problem — *The Easy Wins* (2030s), *The Hard Core* (2040s), *The Drawdown* (2050s) — and hard-to-abate emission floors mean the last tons can't be cut until the era that unlocks the tech: every run must cross all three acts.

## Repository layout

```
docs/
  01_Design_Brief.md          the one-pager: fantasy, pillars, rogue-lite mapping, scope guardrails
  02_MVP_Spec.md              full MVP spec: rules, all card/crisis data, UI, architecture, done criteria
  03_Implementation_Plan.md   the 9-step build plan (all steps complete)
  Design_History.md           the decision log: every design choice, its alternatives, and why
  random_ideas.md             raw notes and playtest feedback that seeded the design
src/                          Godot 4.3 project — the playable prototype
  data/                       ALL game numbers as JSON (config, cards, crises, combos) — rebalancing needs zero code
  scripts/core/               pure headless simulation (no scene-tree dependency)
  scripts/autoload/game.gd    five-verb façade between sim and UI
  scripts/ui/ + scenes/       the interface — listens to signals, computes nothing
  tests/                      headless test suite + bot players + balance harness
```

## Running it

All commands run from the repo root, using the Godot build included in this repository (`godot/`):

- **Play:** `./godot/bin/godot.linuxbsd.editor.dev.x86_64 --path src` — mouse only; a `?` button shows the rules.
- **Tests:** `./godot/bin/godot.linuxbsd.editor.dev.x86_64 --headless --path src -s res://tests/run_tests.gd` — 14 checks covering determinism, pacing, band scaling, era gating, combos.
- **Balance harness:** `./godot/bin/godot.linuxbsd.editor.dev.x86_64 --headless --path src -s res://tests/balance.gd` — 40 seeds × 6 bot profiles printed against the done criteria. The rebalance loop is: edit JSON → run harness → read table.

Any Godot 4.3+ install works too (`godot --path src`).

## Architecture (why changes are cheap)

Three rules carry the design — details in [02_MVP_Spec.md §5](docs/02_MVP_Spec.md):

1. **The sim runs without the scene tree.** Core logic is pure `RefCounted` classes, so tests run headless and bots can simulate hundreds of runs in seconds.
2. **Effects are data.** Every card, crisis response, windfall, and combo bonus is a JSON list of effect atoms resolved by one function — the only code allowed to mutate state, which also emits the signals and writes the turn log. Adding content is a JSON edit.
3. **Five-verb UI.** The interface may only call `new_run / choose_response / buy_card / reroll / end_turn` and repaints from signals. Reskinning touches zero game logic.

## Prototype résumé — what the first balance pass found

Built per the plan, then immediately run through the harness, which caught three things on day one (full story in [Design_History.md](docs/Design_History.md)):

1. **The 2038 insta-win.** Cut supply was so generous that stockpiled money closed the whole emissions gap the moment Act II unlocked. Fix: **hard-to-abate floors per era** — net zero is structurally unreachable before Act III, making "depth over time" mechanical.
2. **The Mild Winter false win.** A windfall's one-turn emissions dip triggered victory. Fix: winning requires **structural** net zero; transient effects only slow the clock.
3. **Always-Absorb dies.** Answering every crisis with support loses 40/40 runs to support collapse — kept, because "absorb only when flush" is exactly what the dilemma engine should teach.

Current numbers: doing nothing loses on turn 13 (~2042) at +2.03°; perfect-play bots win 2044–2045 at ~+1.73°, predicting a human win window of 2045–2050 — the real-world net-zero window, on purpose.

## Known open questions (for playtesting)

- The dirty-money temptation is too cheap: greedy bots currently match clean bots. The sting likely needs sharpening.
- Bot pacing is a proxy — the four playtest questions in [02_MVP_Spec.md](docs/02_MVP_Spec.md) (temptation, tension, combo discovery, crisis dilemmas) need human answers.
- Deliberately out of scope for the MVP: meta-progression, breakthroughs, city archetypes, deckbuilding, codex, art/audio, save/load.
