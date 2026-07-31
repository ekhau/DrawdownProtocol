# High-Level System Diagram — The Drawdown Protocol

Two views: the run-time loop (everything inside one timeline) and the meta loop
(what persists between timelines). Simulation core stays headless and deterministic;
the UI only subscribes to it.

## Run Loop (one turn = five years; 15 turns, 2030–2100)

```mermaid
flowchart TD
    GEN["Procedural world generation\n(seeded: starting emissions mix,\nsinks, money, happiness)\n+ chosen city archetype"] --> RS

    subgraph RUN["One run: 15 turns against the climate clock"]
        RS["Run state\nMoney - Carbon - Happiness\nClock T, Influence, Allies\nWorld actor curves\nCombo chain, Projects, Deck"]

        RS --> INC["1. Income + upkeep\nMoney: 250 + 40/ally + passives\nInfluence: 6 + 2/ally (+2 media)\nprojects pay, complete, or collapse"]
        INC --> DRAW["1c. Event draw: 3 events\nweighted by warming band and social state\non-draw spikes bake in\nbonus cards may qualify"]
        DRAW --> MARKET["1d. Project market: 4 offers dealt\nweighted (card x archetype lean)\nguarantee: the turn stays answerable\nevent bonus cards append"]
        MARKET --> ACT["2. Player funds offers\n(<= 5, bound by Money / Influence / Happiness)\neach funded offer is consumed\nprojects launched or abandoned"]

        ACT --> ANSWER["Card tags answer crises\ncontained: no damage + reward\nspikes dissipate"]
        ACT --> COMBO["Completed tag sets fire combos\nrewards x chain multiplier\nchain +1 per combo, -1 comboless turn\n2+ in a turn: CASCADE"]
        ACT --> SECT["Sector / sink / society /\ndiplomacy / actor / research\neffects apply"]
        ACT --> GROW["Deck growth checks\n(answers, combos, allies,\nsectors, projects)"]

        SECT --> LEDGER["3. Carbon ledger\nE = city sectors + world actors + extras\nA = sinks +/- restoration, stress, fires\nN = E - A"]
        LEDGER --> WARM["4. Warming - the clock ticks\nT += 0.0011 x N (if N > 0)\nT += 0.00028 x N (if N <= 0)"]
        WARM --> HAP["5. Happiness drift\ntransition co-benefits (max +4)\nminus Overshoot stress (0/2/4)"]
        HAP --> STRIKE["6. Unanswered crises strike\ndamage x (1 - R/200)\nmissed opportunities pass by"]
        STRIKE -->|"opportunity riders:\nrebuild better, policy window"| ACT
        STRIKE --> SUMMIT["6b. Summit check (turns 4/8/12)\nannounced target vs this turn's net\nreward met / penalty missed"]
        WARM --> FB["7. Feedback loops (one-time)\npermafrost +2E at 1.75\nocean sink -2A at 1.90\nAmazon -3A after 3 fires"]
        FB --> LEDGER
        SUMMIT --> ACTORS["7b. World actors advance\neach curve += trend\nallies damp 0.2/ally, steepest first\nfloors hold"]
        ACTORS --> CHK{"8. Check (precedence)"}
        CHK -->|"T >= 2.0"| LOSS["LOSS: limit breached\n(clock 100%)"]
        CHK -->|"H <= 0"| REVOLT["LOSS: the city revolts"]
        CHK -->|"N <= 0, any turn"| WIN["WIN: carbon-neutral world\n(the drawdown moment)"]
        CHK -->|"year 2100, N > 0"| SOFT["Loss: survived, not neutral"]
        CHK -->|otherwise| RS
    end
```

## Meta Loop (between runs)

```mermaid
flowchart LR
    END["Run ends\n(win or loss)"] --> PM["Post-mortem\nnames the pivotal turn\n(overheat / revolt / timeout / win)"]
    PM --> KP["Knowledge Points (floor 1)\ndecades + sectors + allies/2\n+3 on win + in-run insight"]
    KP --> TREE["Knowledge tree (7 nodes)\nAffordable EVs - Healthy Sobriety\nInformed Public - Capital Charter ..."]
    END --> LESSON["Defeat lessons\nLOSS_REVOLT unlocks the\nPublic Support Fund forever\n+ codex entries per card played"]
    TREE --> MOD["Next-run modifiers\ncheaper cards, happier sufficiency,\nfaster restoration, a new archetype"]
    LESSON --> MOD
    MOD --> ARCH["Archetype choice\nPort City - Industrial City\nPolitical Capital (unlocked)"]
    ARCH --> NEWMAP["New seeded world map"] --> NEWRUN["Next run starts smarter"]
```

## Coupling Notes

- **The clock → everything:** the world's blocs add ~+1.6 Gt/turn of drift, so net
  emissions — and the clock — worsen by default. Every system is ultimately a way to
  bend that one gauge; the HUD forecasts its next tick so the race is always legible.
- **Crises → everything:** the turn's draw is immediate pressure; answering costs tempo
  (money that could transform sectors or fund transitions abroad) but pays resources
  back; ignoring costs pillars, bakes heat-wave spikes into the ledger, and — for fires
  and droughts — eats the sink itself.
- **The market → texture:** each turn's 4 offers are a different hand; reading the deal
  (and knowing a crisis-answering offer is guaranteed) is the roguelike layer on top of
  the deterministic sim.
- **Combos → economy:** combo rewards (scaled by the chain) are the main way a
  well-built turn funds the next answer — the engine of the game's energy.
- **Projects → the long game:** three turns of upkeep is a promise made against future
  crisis turns; completion powers (income, sinks, wellbeing, allies) compound for the
  rest of the run.
- **Deck growth → options:** answered crises, combos, allies, sector progress and
  completed projects unlock new cards mid-run — and defeats unlock cards across runs.
- **Happiness → Money → the revolt line:** income ×0.75 below 40 happiness, ×0.5 below
  25; at 0 the city revolts and the run ends. The spiral is systemic long before it is
  terminal.
- **Happiness + Adaptation → Resilience (derived):** `R = 0.4·H + adapt`, capped 100;
  scales all unanswered-crisis damage by `1 − R/200`.
- **Warming → escalation:** past +1.5 °C (Overshoot) crisis draw weights rise, sinks
  degrade each turn, and happiness takes stress.
- **Diplomacy → scale:** allies are the only income multiplier AND the only damper on
  world drift; funded transitions abroad are the cheapest tons in the game. Being
  allied must always beat being alone (pillar: Influence, Not Authority).
- **Summits → tempo:** announced targets convert the long race into mid-run deadlines;
  meeting them pays the treasury, missing them costs Influence and Happiness.
