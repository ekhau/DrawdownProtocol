# Design History

A log of the design process: decisions made, alternatives considered, and why. Chronological — newest entries at the bottom. Specs describe *what* the game is; this file remembers *how it got there*.

## Pre-restart cycles (2025 – July 2026)

Two full design cycles preceded the current restart. Their docs and Godot prototype live in git history (commits up to `8d76938`):

- **Combo/crisis cycle** (early July 2026): introduced combos, projects, crises.
- **Clock-race cycle** (late July 2026): 15×5-year turns, climate clock as adversary, market, world actors, summits, city archetypes, post-mortem, codex.

**Lessons carried forward:** the clock as the enemy, the post-mortem screen, combos as the discovery engine, market-based card buying. Playtest complaints that shaped current rules: lack of clarity ("what do the percentages mean?" → every number change must appear in the turn log) and too little money in the early game.

## 2026-07-31 — Restart: rogue-lite deckbuilder, not city builder

**Context:** blank-slate restart. Core question: how to reproduce the rogue-lite feelings (per-run discovery, getting better each run, "one more run") with the climate theme.

**Options:** (a) city builder, (b) rogue-lite deckbuilder with the city as a visual centerpiece.

**Decision:** (b). A city builder has no fail state (no tension), long sessions (no "one more run"), and heavy simulation/art cost. The city remains as a single illustrated centerpiece that turns grey → solarpunk green as sectors decarbonize — city-builder dopamine at a fraction of the cost.

**Result:** [01_Design_Brief.md](01_Design_Brief.md) and [02_MVP_Spec.md](02_MVP_Spec.md) replace all previous docs.

## 2026-07-31 — Failure is canonical: runs are simulated timelines

The player is the Drawdown Institute running scenario after scenario. Losing a timeline is expected and productive: it ends in a post-mortem and yields insights (diegetic meta-progression, like Hades making death part of the story). Keeps the tone hopeful — failure is data, never guilt.

## 2026-07-31 — Boons become "Breakthroughs"

Confusion to resolve: what distinguishes boons from cards? Answer: **cards are what your city does** (chosen from the market, paid with your money/support); **breakthroughs are what the world hands you** (free, pick 1 of 3, every ~4 years, permanent and run-shaping). Which technologies arrive, and when, is rolled per run — one timeline gets cheap solar in 2034, another never sees fusion. That per-run build identity is what Hades gets from boons.

## 2026-07-31 — Crisis dilemma engine

Replaced the single pay-or-penalty crisis with 2–3 responses per crisis, built from four archetypes: **Pay** (money now, no scars) / **Absorb** (support takes the hit) / **Mortgage** (cheap now, permanent scar) / **Invest** (over-priced build-back-better). No option may dominate; the right choice depends on wealth, support level, and timing — a mortgage taken early compounds all run. Driven by the requirement: high variability, no good answers, compromises at the right time.

## 2026-07-31 — Act structure: depth over time

**Options considered:**

1. **Scale:** city → country → world. Intuitive power escalation, but each act demands a new map and systems layer, and city-level play risks being obsoleted. *Parked: may return as meta-progression — unlocked city archetypes as cities around the world.*
2. **Depth over time** ← **CHOSEN.** Same city all game; the *nature of the problem* changes. Act 1, *The Easy Wins* (2030s): low-hanging fruit — grid, buses, insulation. Act 2, *The Hard Core* (2040s): hard-to-abate sectors (steel, cement, aviation, farming), adaptation enters. Act 3, *The Drawdown* (2050s): net-negative — capture, restoration, repair. Mirrors the real decarbonization curve (every ton gets harder), keeps single-city scope, and the game is named after Act 3.
3. **Political altitude:** mayor → national leader → summit diplomat, with elections and a final COP negotiation as bosses. Most dramatic, human antagonists — but each act is essentially a new game system (diplomacy). *Parked.*
4. **Tipping-point bosses:** acts as races against permafrost / Amazon dieback / ice-sheet windows. *Parked as a candidate boss layer on top of the eras.*

**Note:** with depth-over-time, acts are not separate maps — they are phases of the same run's timeline.

**Follow-up decision (same day): eras-lite in the MVP.** Because the MVP run already spans 2030→2050, the eras cost almost nothing to include: cards get an `available_from` year, with banners and a free market refresh when an era begins. Boundaries compressed to 2038/2044 so Act III fits inside the win window (full game restores decade boundaries). Considered and declined: act-free MVP (all cards from turn 1 — purest core-loop test, but the MVP would feel less like the real game) and full act structure with boss checkpoints (roughly doubles scope before first playtest).

## 2026-07-31 — Code architecture: headless sim, effect atoms, five-verb UI API

Spec §5 upgraded from a file-tree sketch to a layered architecture. Rule: **the simulation runs without the scene tree** (pure `RefCounted` classes) so tests run headless and balance bots can simulate hundreds of runs. Three load-bearing decisions: (1) all card/crisis/combo effects are JSON **effect atoms** resolved by a single `effects.apply()` — the only mutation path, which also emits signals and writes the turn log, making last cycle's clarity complaint impossible to regress on; (2) UI restricted to a **five-verb command API** with signals back — no rules or arithmetic in UI scripts; (3) **seeded RNG** owned by the sim for reproducible runs. Build order puts the JSON validator and the headless "do-nothing loses in 2043" proof before any UI, and ends with a balance harness (bot players × N seeds) so rebalancing = edit JSON → run harness → read table.

## 2026-07-31 — Era palettes: one scientific colormap per act

Each act keys the UI's color ramp to a scientific colormap: Act I **magma** (dark purple→orange heat — the burning 2030s), Act II **viridis** (deep blue→green — the transition), Act III **parula** (bright blue→green→yellow — solarpunk drawdown). Sector tints, thermometer accents, and banners sample the active ramp; era transitions crossfade palettes. Rationale: makes the grey→solarpunk pillar legible at the whole-screen level, gives each act a distinct mood on placeholder art (cheap — it's a gradient lookup, no assets), and the scientific-colormap nod fits the Drawdown Institute fantasy. Ramps stored as gradient stops in `config.json`.

## 2026-08-01 — First balance pass: the harness earns its keep

The MVP was implemented (per [03_Implementation_Plan.md](03_Implementation_Plan.md)) and the balance harness run on day one. Three findings, each fixed the same day:

1. **The 2038 insta-win.** Every buying bot won the moment Act II unlocked: cut supply (~35 available before Act III vs. 20 needed) let a player stockpile money and close the whole gap in one era-refresh shopping spree. Cost increases barely moved it — the problem was supply, not price. **Fix: hard-to-abate emission floors per era** (Act I 5/3/2/2, Act II 3/2/1/1, Act III 0). Net zero is now structurally unreachable before 2044 — "depth over time" made mechanical, and it mirrors the real constraint (residual emissions need carbon removal). Wasted cuts are logged and flagged on the sector panel; buying deep cuts before their era can use them is a real mistake the player can learn.
2. **The Mild Winter false win.** A windfall's one-turn −4 gross triggered "net ≤ 0" during a low-net year. **Fix: winning requires *structural* net ≤ 0** (sectors − absorption, no transient effects); transients still slow the thermometer.
3. **Always-absorb dies.** With honest win conditions the always-Absorb policy loses 40/40 runs to support collapse by ~2039 — previously masked by false wins. Kept as-is: "absorb only when support is flush" is exactly the lesson the dilemma engine wants to teach.

Post-fix table: do-nothing loses turn 13 (recorded 2042); perfect-play bots win 2044 at ~+1.73°; always-Mortgage strictly worse than always-Pay. Card costs also rose (mildly in Act I, steeply later — total clean spend 86$ → 108$); spec §1/§2 synced. Watch item for playtests: greedy (temptation-taking) bots currently match clean bots — the dirty-money sting may need sharpening.

## 2026-07-31 — Windfalls: rare good news with a sting

Added 3 windfall cards to the 10-crisis deck (~1 draw every 4–5 turns). Purpose: pacing relief — rogue-lites need valleys between spikes (Slay the Spire campfires, Hades fountains), and an unbroken crisis drumbeat would make the climate theme grinding. Rules: net-positive but never consequence-free (the transition creates losers too — coal workers march when the plant closes), immune to band scaling, and where there's a choice both options feel good-with-a-sting. Also serves the hopeful-tone pillar: the world sends good news, not only disasters.
