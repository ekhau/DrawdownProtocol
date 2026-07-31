# The Drawdown Protocol — Design Brief

**One-liner:** A rogue-lite deckbuilder where each run is a simulated timeline: steer one city from +1.5° in 2030 to carbon neutrality before the world hits +2.0°.

**Fantasy:** *"I understand how to fix this."* You are the Drawdown Institute, running scenario after scenario. Timelines fail — that's the job. Every failed run is data, every won run is a blueprint.

## Pillars

1. **The clock is the boss.** The thermometer (+1.5° → +2.0°) is the only enemy, fed by your net emissions every turn. Dirty sectors pay money *now*; their emissions compound *forever*. Push-your-luck lives in that gap.
2. **Failure is data.** A run is a simulation, so losing is canonical. Every run ends in a post-mortem report ("Timeline #7: +2.0° in 2074. Cause: locked-in car sprawl"). Meta-progression is diegetic: insights from failed timelines unlock new tech and starting cities. Tone is hopeful (Terra Nil), never guilt.
3. **Learn the game, learn the climate.** Mastery mirrors real climate literacy: green the grid before electrifying transport; industry needs process heat, not just clean power; food is land use. Hidden combos are real solutions ("Combo discovered: 15-Minute City"). Codex entries carry real facts — Project Drawdown is the namesake.
4. **Watch it turn green.** The city is a single illustrated centerpiece that shifts grey → solarpunk as sectors decarbonize. City-builder dopamine without city-builder scope.

## Core loop (one turn = one year)

**Crisis** (draw one, choose one of 2–3 costly responses — pay money, spend support, or take a permanent scar; worse as the thermometer climbs; rare windfalls bring good news with a sting) → **Act** (buy policy/tech cards from a small market with money + political support) → **Income** → **Climate** (thermometer advances by net emissions).

**Win:** net emissions ≤ 0 before +2.0°. **Lose:** thermometer hits +2.0°, or social support collapses to 0 — decarbonize too brutally and society breaks. Speed vs. acceptance is the central tension.

## Rogue-lite mapping

| Slay the Spire / Hades | Drawdown Protocol |
|---|---|
| Boss | The thermometer |
| HP | Political support |
| Cards | Policies & tech projects |
| Relics | Infrastructure & institutions |
| Boons | Breakthroughs: every ~4 years, pick 1 of 3 shifts the world offers you |
| Enemy attacks | One crisis per turn, scaling with warming |
| Acts 1→3 | Eras: The Easy Wins (2030s) → The Hard Core (2040s) → The Drawdown (2050s) |
| Meta currency | Insights from post-mortems |
| Ascension | Start at +1.6°, faster clock, double crises |

**Cards vs. breakthroughs (boons).** Cards are what your city *does*: policies you pick from the market and pay for with your own money and support. Breakthroughs are what the world *hands you*: technology and social shifts you don't control and don't pay for. Every ~4 years the world offers a choice of 1 out of 3 free, permanent, run-shaping gifts — "Battery costs collapse: Transport & Industry cards cost −2", "Green hydrogen matures: 3 new cards join the pool", "Youth climate movement: +1 support per turn". Each run rolls a different set, so one timeline gets cheap solar in 2034 and builds around electrification, while another never sees fusion and must win through sufficiency. Cards are your actions; breakthroughs are your run's *shape* — that per-run build identity is exactly what Hades gets from boons.

**Acts — depth over time.** Same city all game; what changes is the *nature of the problem*, mirroring the real decarbonization curve where every ton gets harder. Act 1, *The Easy Wins* (2030s): cut the low-hanging fruit — grid, buses, insulation. Act 2, *The Hard Core* (2040s): the hard-to-abate sectors (steel, cement, aviation, farming) while impacts intensify and adaptation enters the game. Act 3, *The Drawdown* (2050s): go net-negative — carbon capture, ecosystem restoration, repair. The game is named after Act 3.

**Per-run discovery axes:** asymmetric starting cities (port-industrial / car-sprawl / dense-cold), a card pool ~3× larger than any single run shows, randomized breakthroughs, hidden combos to hunt.

## Scope guardrails

Run length 20–30 min (12–20 turns). MVP: one city, one screen, market-only (no deck), no meta-progression, and **eras-lite** acts — the run crosses all three acts via decade-gated cards and banners; boss checkpoints and full transitions come later. First prove the turn-to-turn decision is fun. See [02_MVP_Spec.md](02_MVP_Spec.md). Decisions and rejected alternatives are logged in [Design_History.md](Design_History.md).
