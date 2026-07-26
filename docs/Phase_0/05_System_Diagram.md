# High-Level System Diagram — The Drawdown Protocol

Two views: the run-time loop (everything inside one timeline) and the meta loop
(what persists between timelines). Simulation core stays headless and deterministic;
the UI only subscribes to it.

## Run Loop (one year = one turn)

```mermaid
flowchart TD
    GEN["Procedural world generation\n(seeded: starting emissions mix,\nsinks, money, happiness)"] --> RS

    subgraph RUN["One run: 2030 - 2100, three crises and up to five cards per year"]
        RS["Run state\nMoney - Carbon - Happiness\nWarming T, Influence, Allies\nCombo chain, Projects, Deck"]

        RS --> INC["1. Income + upkeep\nMoney: 100 + 20/ally + passives\nInfluence: 2 + 1/ally (+1 media)\nprojects pay, complete, or collapse"]
        INC --> DRAW["1b. Crisis draw: 3 events\nweighted by warming band\nand social state"]
        DRAW --> ACT["2. Player plays cards\n(<= 5, bound by Money / Influence / Happiness)\nand may launch or abandon projects"]

        ACT --> ANSWER["Card tags answer crises\ncontained: no damage + reward"]
        ACT --> COMBO["Completed tag sets fire combos\nrewards x chain multiplier\nchain +1 per combo, -1 comboless year"]
        ACT --> SECT["Sector / sink / society /\ndiplomacy effects apply"]
        ACT --> GROW["Deck growth checks\n(answers, combos, allies,\nsectors, projects)"]

        SECT --> LEDGER["3. Carbon ledger\nE = sector bases x (1 - 0.9 x progress)\nA = sinks +/- restoration, stress, fires\nN = E - A"]
        LEDGER --> WARM["4. Warming\nT += 0.001 x N (if N > 0)"]
        WARM --> HAP["5. Happiness drift\ntransition co-benefits\nminus Overshoot stress"]
        HAP --> STRIKE["6. Unanswered crises strike\ndamage x (1 - R/200)\nmissed opportunities pass by"]
        STRIKE -->|"opportunity riders:\nrebuild better, policy window"| ACT
        WARM --> FB["7. Feedback loops (one-time)\npermafrost +2E at 1.75\nocean sink -2A at 1.90\nAmazon -3A after 3 fires"]
        FB --> LEDGER
        WARM --> CHK{"8. Check"}
        CHK -->|"T >= 2.0"| LOSS["LOSS: limit breached"]
        CHK -->|"year 2100, N <= 0"| WIN["WIN: carbon-neutral world"]
        CHK -->|"year 2100, N > 0"| SOFT["Soft loss: survived, not neutral"]
        CHK -->|otherwise| RS
    end
```

## Meta Loop (between runs)

```mermaid
flowchart LR
    END["Run ends\n(win or loss)"] --> KP["Knowledge Points\ndecades + sectors + allies\n+3 on win + in-run insight\n(first combos, seized opportunities)"]
    KP --> TREE["Knowledge tree\nAffordable EVs - Healthy Sobriety\nInformed Public - ..."]
    TREE --> MOD["Next-run modifiers\ncheaper cards, happier sufficiency,\ncalmer crises"]
    MOD --> NEWMAP["New seeded world map"] --> NEWRUN["Next run starts smarter"]
```

## Coupling Notes

- **Crises → everything:** the yearly draw is the turn's pressure; answering costs
  tempo (money that could transform sectors) but pays resources back; ignoring costs
  pillars and, for fires and droughts, the sink itself.
- **Combos → economy:** combo rewards (scaled by the chain) are the main way a
  well-built turn funds the next answer — the engine of the game's energy.
- **Projects → the long game:** upkeep is a promise made against future crisis years;
  completion powers (income, sinks, wellbeing, allies) compound for the rest of the run.
- **Deck growth → options:** answered crises, combos, allies, sector progress and
  completed projects unlock new cards mid-run — more diverse answers for harder years.
- **Happiness → Money:** income ×0.75 below 40 happiness, ×0.5 below 25 — the social death
  spiral is systemic, not an instant game over.
- **Happiness + Adaptation → Resilience (derived):** `R = 0.4·H + adapt`, capped 100;
  scales all unanswered-crisis damage by `1 − R/200`.
- **Warming → everything:** past +1.5 °C (Overshoot) crisis draw weights rise, sinks
  degrade yearly, and happiness takes stress — the game's escalating tension comes from
  this single readable driver.
- **Diplomacy → scale:** allies are the only income multiplier; joint projects are the
  only cards touching all three sectors at once. Being allied must always beat being
  alone (pillar: Influence, Not Authority).
