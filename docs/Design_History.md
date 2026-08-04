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

## 2026-08-03 — Climate bar markers: the needle and the neutrality diamond

From the playtest note "add marker in climate bar — current warming, and the objective of neutrality with current absorption." The thermometer now carries: 0.1° scale ticks, the two crisis-band boundaries in pink (1.7°, 1.85° — the cost bumps were invisible before), a white needle at current warming, and a **◆ projection marker**: where the mercury stops if the player keeps their recent pace, with a one-line caption underneath ("at this pace: net zero ≈ 2044, at +1.70°"). Green ◆ = neutrality in reach; orange ◆ pinned at +2.0° = current pace loses.

Three interpretation decisions, since the note underdetermined the math: (1) **pace** = average structural-net decline over the last ≤3 years, counting this turn's purchases as the current year — so buying a card moves the diamond immediately (instant cause→effect feedback, the top clarity complaint); absorption gains count as pace equally with cuts, because the win condition treats them equally. (2) **Absorption frozen at today's value** in the forward simulation, per the note's "with current absorption" — the marker shows what today's engine earns, not extrapolated forests. (3) **Era floors respected** in the projection: the diamond never promises a pre-Act-III win the hard-to-abate floors forbid — on a healthy run it hovers just past 2044, teaching the act structure without a word of tutorial.

Architecture: projection lives in `ClimateCalc.neutrality_projection()` (pure, unit-tested — no-cuts pins at 2.0°, steady cuts land ≥ 2044), exposed via a read-only `Game` helper; the UI only draws. Also added `tests/screenshot_driver.gd`, a throwaway-style visual smoke check that boots the real UI, pokes the sim, and saves before/after PNGs — first tool for eyeballing code-built UI without clicking.

## 2026-08-03 — Market desync fixed: every offer mutation now announces itself

First playtest found the market UI lying: bought cards stayed face-up (and clicking the ghost silently did nothing), and a reroll took the dollar but visibly dealt nothing. Root cause was signal ordering, not the small card pool: the market repainted only from `resources_changed`, which fires **mid-mutation** when the cost is deducted — before `offer` actually changes — and nothing fired after. The "UI repaints from signals" rule had a hole: a mutation whose last signal precedes its last state change desyncs by construction.

Fix: a dedicated `market_changed` signal emitted at the single point every offer mutation flows through (`Market._fill()` — init, buy, reroll, era refresh all end there), so the last signal of any market mutation is guaranteed to fire after the state settles. `buy()` also erases the card from the offer *before* costs land, so even mid-buy repaints never see a buyable ghost. Regression-tested headless (buy removes + refills + pings, reroll redeals + pings, ghost click rejected).

Same playtest, second complaint: no reason given when a card is unbuyable. The affordability rules now live in one read-only `Market.blockers()` (money shortfall; support shortfall; and the previously invisible strict rule that support may never be spent to exactly 0 — the anti-suicide clause). The UI renders the missing resource **in red inside the cost** plus a one-line reason ("✗ need 3$ more", "would drop support to 0") via a click-transparent RichTextLabel over each card button. Reroll button states are explicit too ("Rerolled ✓" + tooltips), and a short market (era-gated pool running dry) shows "N more cards unlock in later eras" instead of looking broken. The pool-size hypothesis from the playtest note was checked and cleared: 12 Act-I cards vs. a market of 3 only shortens the offer late in an act, which is now labeled.

## 2026-08-03 — Act interstitials: the era change becomes a screen, not a whisper

Playtest note: "explicit the change of act." An era change was a 3-second fading banner plus a palette shift — miss the fade and the run's core structure (three acts, deeper tech each act) stayed invisible. Replaced with a rogue-lite **act interstitial**: a modal title card in the act's palette color showing the act name and tagline, the technologies that just reached the market by name, and the hard-to-abate floor changes ("Industry 5 → 3 …"). Act I gets the same card at run start — it announces the act structure from minute one and states the floor rule upfront, so "why won't my cuts go deeper?" is answered before it's asked. A persistent act label also sits under the year in the top bar.

Two decisions worth recording: (1) **Stacking order** — the interstitial is the topmost overlay, above the crisis modal. On an era turn the sim announces the era, then draws the crisis; the player reads the act card, dismisses it, and finds the year's crisis waiting underneath — structure first, then trouble, no information lost. (2) **The "what's new" diff lives in `Catalog.era_brief()`** (pure static content query, unit-tested: briefs partition the full card pool), not in the UI — the zero-logic-in-UI rule holds. The old fading banner survives only for combo discoveries.

## 2026-08-03 — Emissions gauge: the top bar's second instrument

Playtest ask: replace the bare "Absorb 3 / Net 20" numbers with a gauge of global carbon emissions — a green zone for what absorption soaks up, a marker for current emissions, and a marker for "emissions at 2.0° with current absorption." The top bar now carries two instruments: the thermometer (temperature — the clock) and the **emissions gauge** (the engine — what drives the clock). On the gauge: a translucent **green zone [0, absorption]** whose bright right edge is the win line (pull the needle inside = net zero), a **white needle** at current gross (same visual language as the thermometer's needle), and a **pink 2.0° line** in the thermometer's band-boundary pink, with the arithmetic spelled out in the caption ("gross 23 − absorbed 3 = net 20 · over the 2.0° line — cut faster").

The interpretation decision: the third marker is the **break-even gross** — the highest gross emissions from which the player's current pace of cuts (absorption frozen, era floors respected) still reaches net zero before +2.0°. It is the ◆ diamond's verdict re-expressed in emissions units, computed by the same forward simulation (`ClimateCalc._project()`, now shared by `neutrality_projection()` and `breakeven_gross()`, with a unit test pinning their agreement: gross ≤ line ⟺ ◆ reachable). With no cuts underway the line collapses onto the green edge — "with no pace, only absorbed emissions are safe" — which is itself a readable statement. Scale is anchored to the run's starting gross so the bar doesn't rescale under the player; needle-left-of-line = winning course is the one-glance read.

## 2026-08-04 — Card pool 21 → 38: real French climate programmes as content

Card supply grew 80%, sourced from real measures so every card is an argument a player may have heard on the news: **Convention Citoyenne pour le Climat** (110 km/h motorway limit, short-haul flight ban, heated terrace ban, high-carbon ad ban, sprawl moratorium/ZAN, bulk & deposit law, hedgerow replanting, fertilizer tax, forest plan), **The Shift Project's PTEF** (process electrification, night-train revival, cement carbon capture, circular economy), and the French-launched **4-per-1000** soil initiative. A new card archetype fell out of the sourcing: **policy cards priced in support instead of money** (110 on the Motorway and Heated Terrace Ban cost 0$ + 1 support) — sufficiency is cheap but unpopular, the inverse of the temptation trade. Two new temptations (SUV Boom, Airport Expansion) join the dirty-money test; Airport Expansion spreads +1 emissions across two sectors so late-game dirty money digs a wider hole.

Balance was verified against the §7 harness, and the pool growth surfaced two effects worth recording. (1) **A bigger pool needs a wider window**: with 38 cards behind a 3-slot market, 2/40 clean-bot seeds stalled — under +2.0° forever but unable to assemble the last cuts — and combos/run collapsed 2.8 → 1.0 (pieces diluted). **Fix: market size 3 → 4** — the visibility valve matched to pool size, not price changes. Result: 40/40 clean wins at 2044 (+1.71°), all §7 targets green (do-nothing loses 2041, absorb dies, mortgage < pay). (2) **Two new combos** knit the additions together and restore hidden-set density (2.2/run): *Sufficiency Laws* (the CCC policy trio — completable in Act I, the first-act "aha" the combo table lacked) and *Rail Nation* (night trains + rail freight). Pre-2044 absorption supply was audited before adding nature cards: start 3 + Urban Forest 1 + Hedgerow 1 = 5, safely under the Act II floor sum of 7, so the 2038 insta-win door stays closed. Standing watch item, slightly worsened: greedy still matches clean (+1.69° vs +1.71°) — the dirty-money sting needs a mechanism, not more cards; candidate for the next balance pass.

## 2026-08-04 — Onboarding: a launch intro and tooltips everywhere

Playtest ask: the Act I card was the first thing a new player saw — no theme, no rules, no idea what the numbers mean. Two additions. (1) **A launch intro** ("THE DRAWDOWN PROTOCOL — 2030. After a decade of broken pledges…") that sets the fantasy, states the mandate, and teaches the core loop, closed by a "Take office ▶" button that flows into the Act I card. It plays **once per session, not per run** — post-mortem restarts skip straight to the act card, keeping rogue-lite restart friction at zero. The rules body was extracted into one `_rules_text()` shared by the intro's short form and the ? button's full form, so the two can never drift. The intro deliberately omits the two instrument paragraphs (thermometer, emissions gauge) — those are taught in place by the second addition. (2) **Tooltips on all 22 interactive elements**: year, act, both instruments and their captions, money, support, sector panels (dynamic — live emissions/income/floor numbers per sector), market cards, reroll, end-turn, turn log. One gotcha encoded in a `_tip()` helper: Godot Labels default to `MOUSE_FILTER_IGNORE`, which silently swallows their tooltips — the helper flips them to `PASS`. A wiring assertion (every tooltip'd control must not ignore the mouse) ran clean. The shared overlay panel also gained a real stylebox — the intro/post-mortem/help text no longer floats naked over the dimmed game.

## 2026-08-04 — One climate bar: the emissions race moves onto the temperature axis

The top bar carried two instruments whose projection annotations were the same fact twice: the emissions gauge's pink break-even line was, by construction, the ◆ verdict re-expressed in emissions units (same `_project()` simulation) — and pink meant "crisis band" on one gauge but "2.0° line" on the other. Design direction: keep the absorption-vs-gross race, lose the second gauge. The key that makes the merge lossless is the warming formula itself — temp advances by net × 0.002°/yr — so any emissions quantity can be projected into degrees and drawn on the temperature axis.

The climate bar now sketches **next year's jump** anchored at the needle: an **orange segment** [needle → landing] is how far the needle moves when the year ends (net × 0.002°), a **green segment** [landing → gross end] is the slice of the gross jump absorption cancels. The race read: green eats the orange from the far end; no orange left = net zero, the needle stops. Absorption deliberately sits at the *far* end rather than adjacent to the needle — that keeps the drawing spatially truthful: the orange/green boundary is exactly where the needle stands next year (gross − absorbed = net means the remainder is the movement). At starting values the jump is ~9% of the bar (net 20 → 0.04° of the 0.5° span), so the segment is readable, and buying a card shrinks it on the spot — the instant-feedback property of the dedicated gauge survives.

What the merge deleted, and where its information went: the break-even line's verdict is carried by the ◆ and the caption's cut-faster warning; the gross/absorbed/net arithmetic moved into the single caption line; "Net N" now sits beside the temperature readout. `ClimateCalc.breakeven_gross()` and its unit tests remain (they pin the projection's semantics); only the UI stopped drawing it, and the dead `Game.breakeven_gross()` wrapper was removed. Two reads the two-gauge layout could not show spatially fall out for free: whether next year's jump crosses a pink crisis band, and whether it clamps against the +2.0° end of the bar. One fix rode along: the heat tint moved from `modulate` to `self_modulate`, because `modulate` propagates to the marker overlay and would have browned the green segment late-game. Pink now means exactly one thing: crisis band.

Amended the same day, twice. First the segment order flipped to **green-first from the needle** (the stacked "absorption soaks the first chunk of gross" read). Then it flipped back to **orange-first** after the designer asked the exact question the green-first layout invites: "shouldn't the needle end up at the right edge of the orange?" — under green-first it doesn't (the orange sits offset by the green's width, so its right edge overshoots the true landing by exactly absorption × 0.002°). Orange-first is the unique truthful-edges arrangement on a temperature axis: absorption never moves the needle, so any green drawn between the needle and its landing claims a displacement that never happens. Final form: orange [needle → landing] with a crisp landing line, green [landing → gross end] = warming avoided. Lesson recorded: on an axis where position means something, edges must be destinations, not just lengths.

## 2026-08-04 — Support becomes Popularity: an approval rate with thresholds, drift, and gates

Trigger: the playtest note "what represents current 12 support? Change it into Popularity rate" plus "too much support" from the same list. The 0–12 support pool read as an opaque video-game stat; it becomes the **government's approval rating on a 0–100% scale** (1 old point = 5%, so all existing balance translates to round numbers). Start **50%**, cap 100%.

Four mechanics replace the flat HP pool, each answering a design question:

1. **Drift ±3%/yr toward 50%** ("approval is rented, never owned"). Kills support hoarding — the old cap-sitting at 12/12 — and doubles as the spiral's second escape valve, since drift pulls *up* when below 50%.
2. **Social crisis pool below 30%.** Instead of elections (considered, rejected: periodic checkpoints felt arbitrary next to continuous pressure), low approval swaps the year's crisis draw for a pool of strikes/riots/no-confidence motions (`social: true` in crises.json — replace, never add, or the spiral is hopeless). **Anti-death-spiral rule: every social crisis carries at least one recovery choice** — expensive but popularity-positive.
3. **Collapse below 10%, not at 0** (designer's call; raised from a proposed 3% for presence). No real government polls at zero; `popularity_collapse` is config so playtests can tune it. The market's anti-suicide clause scales with it: no purchase may land inside the collapse zone — only crises can end a government.
4. **`requires_popularity` gates on radical cards** — a *requirement*, deliberately distinct from `cost_popularity` (a spend): Carbon Tax req ≥75%, Car-Free Center / Ad Ban / Sprawl Moratorium req ≥60%. With a 50% start this creates the run's political loop: pass popular measures to build approval, then spend the window on radical reform before drift claws it back — the popular-vs-effective tension of climate politics, produced by mechanics rather than told. Two **Civic** builder cards (Citizens' Climate Assembly, Green Jobs Program) make the gates reachable; pool 38 → 40.

Band scaling split into per-resource bumps (`cost_bump_money` +1/+2, `cost_bump_popularity` +5/+10) — a flat +1 on the percent scale would have made heat-driven escalation free. UI: popularity is a labeled 0–100% mini-bar with its thresholds drawn on it (red 10%, orange 30%, green gate marks pulled from the card catalog — data-driven, no magic numbers in the UI); social crises get a red border and ✊. Headless tests cover drift both directions, pool switching at the threshold, gate open/close, the collapse-zone floor, and the sub-10% loss (44/44 green).

Same-day harness run (40 seeds): do-nothing loses 2041 (in target), clean wins 38/40 at 2044 (+1.74°), and the new loss condition bites exactly where intended — always-absorb dies 37/40 by popularity collapse around 2040. Two findings to carry forward: (1) **2/40 clean-bot stalls** (alive under +2.0° but never finishing) — the bot doesn't deliberately build approval, so ≥60% gated combo pieces (Car-Free Center) stay locked; a human plays the builder loop, but the clean bot may need to learn it before the stall number is trusted. (2) **Greedy now beats clean at combos** (3.8/run vs 1.9) — buying everything includes the builders, so greedy crosses the gates first; the standing dirty-money-sting watch item sharpens.
