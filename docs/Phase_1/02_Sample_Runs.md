# Sample Runs — The Drawdown Protocol (Phase 1)

Three scripted strategies simulated over the full 2030–2100 timeline with the formulas in
`01_Balance_Model.md`, canonical seed **2030** (deterministic; the tables below are decade
snapshots of the committed golden fixture `src/tests/fixtures/seed2030_expected.csv`,
regenerable with `src/tools/gen_fixtures.gd`). All three assume a first run:
**no Knowledge nodes active**.

Together they satisfy the Phase 1 pacing check: at least one viable winning strategy,
multiple losing paths, and pressure that peaks mid-century.

Column key: Net in GtCO2e/yr; Money in funds; Happiness 0–100. Rows are end-of-decade
snapshots (post-resolution).

---

## Run A — Safe (Steady Transition) — **WIN (carbon-neutral), 18 Knowledge Points**

Answers the crises first every year (cheap response cards matched to the drawn tags),
then plays the fundamentals: media, adaptation, sinks, an even three-sector transition,
four-to-six alliances, and the **Global Sink Trust** project sustained to completion.
243 cards over the run, 212 crises answered, 59 combos (final chain 33), all six
unlockable cards earned.

| Year | Warming °C | Net | Money | Happiness |
|---|---|---|---|---|
| 2040 | 1.56 | +13.0 | 96 | 91 |
| 2050 | 1.57 | −16.5 | 144 | 100 |
| 2060 | 1.50 | −36.5 | 315 | 100 |
| 2070 | 1.40 | −44.3 | 1477 | 100 |
| 2080 | 1.28 | −48.9 | 2731 | 100 |
| 2090 | 1.20 | −51.2 | 3830 | 100 |
| 2100 | 1.20 | −59.9 | 4892 | 100 |

**Decade notes.** 2030s: response cards (Relief Corps, Water Stewardship, Community
Kitchens) contain nearly every draw while media and the first sinks go down; the first
combos land (Water Cycle, Public Trust). 2040s: peak warming +1.58 °C — Overshoot I is
brushed, never held; the Sink Trust completes and absorption starts compounding. 2050s:
net emissions turn deeply negative; happiness saturates as answered crises stop hurting
and co-benefits bloom. 2070s onward: the world cools to the +1.20 °C floor. Why it wins:
answering crises is cheap insurance that also pays influence, and the chain multiplier
turns routine pairs (forest+water, civic+health) into a steady second income.

---

## Run B — Risky (Tech Rush) — **LOSS at +2.0 °C in 2064, 4 Knowledge Points**

Pure green-growth: several big tech cards per year (Clean Energy Grid, Affordable EVs,
Agroecology), never a response card, never media, sufficiency, sinks, adaptation or
diplomacy. Only 14 cards ever played — unanswered crises bleed the budget dry almost
immediately. 11 unanswered mega fires; all three feedback loops fire (Amazon dieback
2041, permafrost 2053, ocean sink weakening 2060). Sectors die at 30 / 65 / 70.

| Year | Warming °C | Net | Money | Happiness |
|---|---|---|---|---|
| 2040 | 1.54 | +16.5 | 48 | 46 |
| 2050 | 1.71 | +15.7 | 15 | 16 |
| 2060 | 1.91 | +22.8 | 0 | 0 |
| 2064 | 2.00 | — | — | — |

**Decade notes.** 2030s: a fast start on paper — but three unanswered crises a year cost
more than the cards being bought. 2040s: fires burn the sink toward the floor and the
third fire triggers Amazon dieback as early as 2041; happiness slides with every ignored
heat wave. 2050s: income penalties bite (H < 25 halves income), the tech rush stalls
short of even the 70% caps for lack of money, permafrost adds +2 E. 2060s: absorption at
the 5.0 floor, net rising, ocean sink weakens — the run dies in 2064. Why it loses: the
game's argument sharpened — ignoring people and crises now kills you decades *before*
the sufficiency ceiling would have.

---

## Run C — Mixed (Alliance Web) — **WIN (carbon-neutral), 18 Knowledge Points**

Diplomacy-first: answers the crises, then media, alliances up to six, Joint Transition
Projects as the main transition engine, sufficiency lifts, and the **Continental Rail
Compact** sustained to completion. 297 cards, 212 crises answered, 68 combos (final
chain 46 — the treaty+energy+civic Grand Bargain fires year after year).

| Year | Warming °C | Net | Money | Happiness |
|---|---|---|---|---|
| 2040 | 1.51 | +1.2 | 107 | 100 |
| 2050 | 1.47 | −26.2 | 168 | 100 |
| 2060 | 1.40 | −32.3 | 132 | 100 |
| 2070 | 1.31 | −37.6 | 114 | 100 |
| 2080 | 1.21 | −40.8 | 88 | 100 |
| 2090 | 1.20 | −41.5 | 67 | 100 |
| 2100 | 1.20 | −48.7 | 129 | 100 |

**Decade notes.** 2030s: the alliance engine spins up fast — crisis answers pay
influence, influence buys allies, allies pay income. 2040s: the Rail Compact completes
(+5% to every sector, +2 influence/yr forever); net crosses zero before 2045 — the
earliest pivot of the three runs. 2050s+: joint projects and the Grand Bargain chain
carry the transition; money runs lean (67–170 all century) because every surplus goes
straight back into answers and treaties — the intended Alliance Web texture. Why it
wins: diplomacy compounds twice — in income and in the combo chain.

---

## Cross-Run Pacing Read

- **Early game (2030s):** the crisis draw teaches immediately — every year has three
  visible questions and the response cards are the affordable answers.
- **Mid game (2040s–2050s):** the squeeze — transformation, upkeep, and answering
  compete for the same money; peak warming lands here (winners brush +1.5 °C, Risky
  sails through it).
- **Late game (2060s+):** winners ride compounding sinks, passives, and deep combo
  chains into the cooling floor; the crisis-ignoring path is already dead — Risky's
  loss lands 2055–2068 across the 20-seed batch, never reaching 2100.
- Overshoot is no longer guaranteed for winners: a sharp early transition can hold the
  world at the +1.5 °C doorstep. The escalation ladder now expresses itself through the
  crisis draw weights as much as through the bands.
