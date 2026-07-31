# Sample Runs — The Drawdown Protocol (Phase 1)

Three scripted strategies simulated over the 15-turn timeline with the formulas in
`01_Balance_Model.md`, canonical seed **2030** (deterministic; the tables below are decade
snapshots of the committed golden fixture `src/tests/fixtures/seed2030_expected.csv`,
regenerable with `src/tools/gen_fixtures.gd`). All three assume a first run:
**no Knowledge nodes, baseline city (no archetype)**.

Together they satisfy the Phase 1 pacing check: viable winning strategies, a structural
losing path, and pressure that peaks mid-century. Because the market deals a different
hand each turn, these are **anchors, not certainties** — the corridor across 20 seeds is
a rate corridor (`05_Balance_Bands.md`).

Column key: Net in GtCO2e/yr (city + world − absorption); Money in funds; Happiness
0–100. Rows are end-of-decade snapshots (post-resolution; a decade = 2 turns).

---

## Run A — Safe (Steady Shield) — **WIN (carbon-neutral) in 2095, turn 14, 12 Knowledge Points**

Answers everything, keeps happiness healthy, and pulls every lever a little: buys down
the world's actors, plants sinks, runs an even three-sector transition, and sustains the
**Global Sink Trust** and **Universal Services** projects to completion.

| Year | Warming °C | Net | Money | Happiness |
|---|---|---|---|---|
| 2040 | 1.46 | +45.0 | 151 | 64 |
| 2050 | 1.55 | +39.9 | 321 | 59 |
| 2060 | 1.62 | +30.1 | 485 | 65 |
| 2070 | 1.68 | +22.8 | 549 | 75 |
| 2080 | 1.71 | +14.7 | 570 | 70 |
| 2090 | 1.72 | +1.0 | 1002 | 66 |
| 2095 | — | **≤ 0** | — | — |

**Decade notes.** 2030s–40s: the world's blocs push net up faster than home cuts pull it
down; Overshoot I arrives in the late 2040s and never leaves. 2050s–60s: the grind —
answered crises, actor funding and project upkeep hold the line while the clock creeps
toward 72%. 2070s–80s: the curve visibly bends; happiness rides co-benefits against
Overshoot stress. 2090s: net crosses zero in 2095 — the drawdown moment, five years
before the deadline. Why it wins: it never lets any pillar bleed, and it spends on the
world ledger (allies, funded transitions) instead of only its own.

---

## Run B — Risky (Moonshot Rush) — **LOSS (revolt) in 2065, turn 8, 3 Knowledge Points**

Pure home tech and research bets, several per turn: Clean Energy Grid, Affordable EVs,
Fusion Moonshot, Direct Air Capture. Never a response card, never diplomacy, sufficiency
or wellbeing. The world's actors climb undamped; every crisis strikes unanswered.

| Year | Warming °C | Net | Money | Happiness |
|---|---|---|---|---|
| 2040 | 1.49 | +57.1 | 417 | 52 |
| 2050 | 1.62 | +60.4 | 546 | 28 |
| 2060 | 1.75 | +58.2 | 818 | 4 |
| 2065 | — | — | — | **0 — revolt** |

**Decade notes.** 2030s: a fast start on paper — but three unanswered crises a turn,
heat-wave spikes baking in, and happiness-cost policies with no counterweight. 2040s:
below 40 happiness the income penalty bites and social crises weight ×3 into every draw.
2050s: Overshoot II arrives on schedule (band 2 at 2060); stress −4 per turn with zero
co-benefit cushion. 2065: the city rises with **818 funds still banked** — money was
never the constraint; consent was. Why it loses twice over: even had the city held, the
world's blocs (untouched, still climbing) make global net-zero unreachable — the
Moonshot Rush is structurally unable to win, not merely unlucky.

---

## Run C — Mixed (Grand Alliance) — **WIN (carbon-neutral) in 2095, turn 14, 12 Knowledge Points**

Diplomacy-first: allies and the world's actors before home optimization — Form Alliance,
Emissions Treaty, Fund a Transition, joint projects, and the **Continental Rail Compact**
sustained to completion.

| Year | Warming °C | Net | Money | Happiness |
|---|---|---|---|---|
| 2040 | 1.46 | +45.0 | 192 | 64 |
| 2050 | 1.55 | +39.1 | 312 | 66 |
| 2060 | 1.62 | +30.9 | 543 | 67 |
| 2070 | 1.68 | +22.4 | 568 | 77 |
| 2080 | 1.71 | +14.2 | 590 | 70 |
| 2090 | 1.72 | +0.9 | 1023 | 63 |
| 2095 | — | **≤ 0** | — | — |

**Decade notes.** 2030s: the alliance engine spins up — crisis answers pay influence,
influence buys allies, every ally damps world drift by 0.2. 2040s–50s: treaties and
funded transitions bend the blocs' curves while the Rail Compact completes; the two
winning lines track each other closely on the global ledger but Mixed carries happiness
a shade higher through the squeeze. 2090s: net crosses zero in 2095. Why it wins:
diplomacy compounds three ways — income, drift damping, and the treaty-tagged combo
chain.

---

## Reference — BAU (all-pass)

Funding nothing at all dies around **turn 7 (~2060)** — a revolt or an overheat,
whichever the seed serves first. The clock's automatic escalation makes "do nothing"
a fast loss, not a slow one; this is the baseline every strategy must beat.

## Cross-Run Pacing Read

- **Early game (2030s):** the market teaches immediately — every turn has three visible
  questions, four visible offers, and a guaranteed affordable answer among them.
- **Mid game (2040s–2060s):** the squeeze — transformation, upkeep, actor funding,
  answering, and the first two summit targets (2045: net ≤ 45; 2065: net ≤ 25) compete
  for the same treasury; winners enter Overshoot I here and hold at the band-2 doorstep
  (~+1.72 °C, clock ~72%) without crossing it.
- **Late game (2070s–90s):** winners ride compounding sinks, passives, and deep combo
  chains through the Last Horizon target (2085: net ≤ 8) into the drawdown moment; the
  people-ignoring path is long dead — Risky's revolt lands around turn 8, never seeing
  the second summit.
- Winners never exit Overshoot in-run: the win is crossing net zero *before* the clock
  runs out, not cooling the world back down — the cooling is the epilogue the victory
  screen promises.
