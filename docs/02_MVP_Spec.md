# MVP Spec — Godot Prototype

Companion to [01_Design_Brief.md](01_Design_Brief.md). The MVP answers three playtest questions:

1. Is the **dirty-money temptation** (income now vs. emissions forever) an interesting decision every turn?
2. Does the **thermometer** create real tension — do first-time players lose *close* (≥ +1.9°)?
3. Does **combo discovery** feel good enough to build the whole discovery layer on?
4. Do **crisis dilemmas** work — every response costly, no auto-pick, the right compromise depending on the moment?

Everything not needed to answer those is out of scope.

## 1. Rules

One city, one screen. **1 turn = 1 year**, starting 2030 at **+1.50°**.

### Turn structure

1. **Crisis phase** (from turn 2): draw 1 card from the crisis deck — usually a crisis (every response hurts; they differ in *which* resource they cost and *when*), occasionally a windfall: good news with a sting (see §3).
2. **Action phase**: market shows 3 face-up cards. Buy any number you can afford; effects are immediate and permanent. Once per turn, pay 1 money to reroll the market.
3. **Income phase**: gain money from sectors.
4. **Climate phase**: `net = gross emissions − absorption`; thermometer += `net × 0.002°`. Check win/lose.

### Resources

| Resource | Start | Notes |
|---|---|---|
| Money | 10 | Earned each income phase, spent on cards & crises |
| Support | 10 (cap 12) | HP. Crises and radical policies drain it. **0 = loss** |
| Absorption | 3 | Forests/ocean sink, raised by nature cards |

### Sectors

| Sector | Emissions | Income/turn |
|---|---|---|
| Industry | 8 | 6 |
| Transport | 6 | 1 |
| Food | 5 | 1 |
| Housing | 4 | 1 |
| **Total** | **23** | **9** |

Baseline net = 20 → +0.04°/turn → **doing nothing loses on turn 13** (recorded as 2042 — the year whose climate phase breaches +2.0°). Good play stretches the budget and wins around **2045–2050** — the real-world net-zero window, on purpose.

**Hard-to-abate floors (depth over time, made mechanical):** each era limits how deep a sector can cut — Act I floors **5/3/2/2** (Industry/Transport/Food/Housing), Act II **3/2/1/1**, Act III **0**. Cuts below the current floor are lost (always logged, and the sector panel shows *era floor N*) — deep-cut cards are wasted if bought before their era can use them. Net zero is therefore structurally unreachable before 2044: every run must cross all three acts, and the game is named after the last one. Floors live in `config.json` per era.

### Win / lose

- **Win:** *structural* net emissions ≤ 0 at end of climate phase — sectors minus absorption, excluding one-turn effects (a Mild Winter slows the clock but is never a win).
- **Lose:** thermometer ≥ +2.00°, or support ≤ 0.
- Both end on a **post-mortem screen**: timeline number, final year, temperature curve, sector states, one-line cause ("Industry never decarbonized").

## 2. Cards (pool of 21; each run shuffles, market draws without replacement)

Format: **Name — cost → effect**. `(C:X)` = part of combo X.

**Eras-lite:** each card has an `available_from` year; the market only deals unlocked cards. Unmarked cards are available from 2030 (Act I — *The Easy Wins*); gated cards are marked *(2038)* (Act II — *The Hard Core*) or *(2044)* (Act III — *The Drawdown*). The MVP compresses era boundaries to 2038/2044 so Act III is reachable inside the win window; the full game restores decade boundaries. When an era begins, the market refreshes for free.

**Industry**
- Efficiency Retrofit — 3$ → Industry −1
- Solar Farm — 6$ → Industry −2 (C:Clean Grid)
- Grid Storage — 7$ → Industry −1, Housing −1 (C:Clean Grid) *(2038)*
- Green Steel — 10$ → Industry −3, Industry income −1/turn *(2038)*
- Carbon Tax — 3 support → +2$/turn, Industry −1 *(2038)*

**Transport**
- Bike Network — 3$ → Transport −1, +1 support (C:15-Minute City)
- Dense Housing — 7$ → Housing −1, Transport −1 (C:15-Minute City) *(2038)*
- Car-Free Center — 6$ + 2 support → Transport −2 (C:15-Minute City) *(2038)*
- Electric Buses — 6$ → Transport −2
- Rail Freight — 9$ → Transport −2, Industry −1 *(2038)*

**Food**
- Plant-Forward Canteens — 3$ → Food −1
- Local Farms — 5$ → Food −1, +1 support
- Food Waste Program — 5$ → Food −1, +1$/turn
- Regenerative Agriculture — 8$ → Food −2, Absorption +1 (C:Living Land) *(2044)*

**Housing**
- Insulation Drive — 3$ → Housing −1, +1 support
- Heat Pumps — 6$ → Housing −2
- District Heating — 8$ → Housing −2, +1$/turn *(2038)*

**Nature**
- Urban Forest — 5$ → Absorption +1, +1 support (C:Living Land)
- Wetland Restoration — 8$ → Absorption +2 (C:Living Land) *(2044)*

**Temptation** (the dirty-money test — always tempting, never mandatory)
- Fossil Subsidy — 0$ → +5$ now, Industry +1 permanently
- Concrete Boom — 0$ → +4$ now, +1 support, Housing +1 permanently

### Combos (announced with a banner the moment the set completes)

| Combo | Cards | Bonus |
|---|---|---|
| 15-Minute City | Bike Network + Dense Housing + Car-Free Center | Transport −2, +2 support |
| Clean Grid | Solar Farm + Grid Storage | Industry −1, Housing −1 |
| Living Land | Regenerative Agriculture + Urban Forest + Wetland Restoration | Absorption +2 |

Era gating staggers combo completion across the acts: Clean Grid and 15-Minute City can only complete from 2038, Living Land from 2044 — each act delivers a new "aha" window.

## 3. Crises & windfalls (one deck of 13 — 10 crises + 3 windfalls, reshuffled when empty)

This is the dilemma engine. Design rules:

- Each crisis offers **2–3 responses and the player must pick exactly one**. There is no clean answer — every option costs something.
- Responses are priced in **different currencies and time horizons**, built from four archetypes:
  - **Pay** — money now, no scars.
  - **Absorb** — support now; society takes the hit.
  - **Mortgage** — free or even profitable now, but a permanent scar (sector +1 emissions, absorption −1, income −1$/turn).
  - **Invest** — over-priced now (money, often support too), but leaves the city structurally *better*. Build back better.
- **No option may dominate.** Pay is right when rich, Absorb when support is flush (early), Mortgage when desperate — but a mortgage taken early compounds for the whole run, the single worst mistake in the game. Invest is the "good time" compromise: crisis as opportunity, only when you can afford it.
- Archetype tags are design guidance, not rules — some crises bend them (e.g. Windfall Tax *gains* money at support cost).
- Band scaling: **A** < 1.7° base · **B** ≥ 1.7° money/support costs +1 · **C** ≥ 1.85° +2. Permanent effects never scale.

Costs below at band A. Permanent effects marked *perm*.

- **Heatwave** — *Cooling centers* (Pay: −2$) · *Ride it out* (Absorb: −2 sup) · *Green streets* (Invest: −5$ → Housing −1 perm, +1 sup)
- **Megafire** — *Firefighting surge* (Pay: −3$) · *Call on neighbour cities* (Absorb: −2 sup) · *Let it burn* (Mortgage: Absorption −1 perm)
- **River flood** — *Emergency repairs* (Pay: −3$) · *Cheap rebuild* (Mortgage: Housing +1 perm) · *Sponge city* (Invest: −6$ → Absorption +1 perm, +1 sup)
- **Drought** — *Import food* (Pay: −3$) · *Ration water* (Absorb: −2 sup) · *Intensive irrigation* (Mortgage: Food +1 perm)
- **Economic slump** — *Austerity* (Absorb: −2 sup) · *Dirty stimulus* (Mortgage: +3$ now, Industry +1 perm) · *Green stimulus* (Invest: −5$ → +1$/turn)
- **Fuel price shock** — *Subsidize the pump* (Pay: −3$) · *Let prices bite* (Absorb: −3 sup, Transport −1 perm) · *Windfall tax* (+3$ now, −2 sup)
- **Climate refugees** — *Welcome & integrate* (Invest: −3$ → +1 sup) · *Transit camps* (−1$, −1 sup) · *Close the gates* (Absorb: −2 sup)
- **Storm surge** — *Sea walls* (Pay: −4$) · *Take the hit* (Absorb: −3 sup) · *Managed retreat, wetland buffer* (Invest: −6$ → Absorption +1 perm)
- **Toxic smog** — *Health emergency* (Pay: −2$) · *Traffic ban week* (Absorb: −2 sup) · *Clean air act* (Invest: −5$, −1 sup → Transport −1 perm)
- **Insurance collapse** — *Public backstop* (Pay: −4$) · *Let it fail* (Mortgage: −1$/turn, −1 sup)

### Windfalls (3 in the deck — good news with a sting)

The pacing valleys of the run: campfire moments. Design rules: **net-positive**, so drawing one is relief — but never consequence-free, because the transition creates losers too. Windfalls ignore band scaling. Where there's a choice, both options are good-with-a-sting, so picking feels pleasant rather than punishing.

- **Record renewables year** — *Sell the surplus* (+4$) · *Retire the coal plant early* (Industry −1 perm, −1 sup — the plant's workers march)
- **Youth climate wave** — *Embrace and fund the movement* (−2$ → +2 sup) · *Warm words* (+1 sup)
- **Mild winter** — no choice: heating demand collapses (+2$, this turn's gross emissions −4), but the missing snow unsettles everyone (−1 sup)

Variability comes from 13 deck cards × 2–3 responses × band scaling × game state (the same Megafire is a different decision rich vs. broke). Post-MVP, deepen by **adding crises and windfalls, not mechanics**.

## 4. UI (single screen, mouse only, placeholder art)

- **Top bar:** thermometer +1.50°→+2.00° (the hero element — big, animated on change), year, money, support.
- **Center:** 4 sector panels (ColorRect placeholders), each showing emissions + income; panel tint samples the **active era's colormap** at `1 − emissions/start`. Absorption shown beside them.
- **Era palettes:** each act keys the UI's color ramp to a scientific colormap — Act I **magma** (dark heat: the burning 2030s), Act II **viridis** (the green transition), Act III **parula** (bright blue-green: solarpunk drawdown). Sector tints, thermometer accents, and banners all sample the active ramp, so the whole screen's mood shifts with the era. Ramps live in `config.json` as gradient stops (data-driven, like everything else).
- **Bottom:** market (3 cards), reroll button, end-turn button.
- **Turn start:** crisis modal presenting the 2–3 responses as buttons, each with its full cost/effect spelled out; permanent effects visually flagged (⚠ perm). Windfalls use the same modal with hopeful styling (green accent) — the player should feel the relief before reading a word.
- **Era transitions** (2038, 2044): full-width banner ("Act II — The Hard Core: heavy decarbonization now possible"), free market refresh, palette crossfade to the new era's colormap, one line in the log.
- **Turn log** (collapsible): one line per event — every number change must be traceable (clarity was a top playtest complaint last cycle).

## 5. Godot implementation

Godot 4.x, GDScript, data-driven so balance iteration = JSON edits, no code.

**Guiding rule: the simulation must run without the scene tree.** Core logic lives in pure `RefCounted` classes — no Nodes, no `get_node()`, no UI references. The UI is a disposable skin, tests run headless, and balance can be checked by simulating hundreds of runs in seconds.

```
src/
  project.godot
  data/                        # LAYER 1 — content
    config.json                #   start values, warming factor, bands, era years, turn rules
    cards.json  crises.json  combos.json
  scripts/
    core/                      # LAYER 2 — pure simulation, zero Node code
      catalog.gd               #   loads + validates all JSON at boot, fails loud
      run_state.gd             #   THE state: resources, sectors, thermometer, owned cards, history
      effects.gd               #   effect resolver — the only code that mutates run_state
      turn_manager.gd          #   phase state machine: Crisis → Action → Income → Climate
      market.gd  crisis_deck.gd  combo_checker.gd  climate_calc.gd
    autoload/game.gd           # thin façade: owns the sim, re-emits its signals to the UI
    ui/                        # LAYER 3 — scenes that listen to signals, never compute
  scenes/main.tscn             # single scene, Control-node UI
  tests/                       # headless bots + assertions on the done criteria (§7)
```

Three decisions carry the maintainability load:

- **Effects are data, not code.** Every card effect, crisis response, windfall, and combo bonus is expressed in one small vocabulary of effect atoms — `{"sector": "industry", "emissions": -2}`, `{"money": 4}`, `{"support": -1}`, `{"income_per_turn": 1}`, `{"absorption": 1}`, with a `perm` flag. `effects.apply(list, source)` is the **only** mutation path into `run_state`: it emits the signals *and* writes the turn-log line, so the clarity rule (§4) is enforced by construction. Adding a card = a JSON entry; a new mechanic = one new atom in one `match`.
- **Five-verb API, signals back.** The UI may only call `game.choose_response(i)`, `buy_card(id)`, `reroll()`, `end_turn()`, `new_run(seed)` — and updates only in reaction to `resources_changed`, `sector_changed`, `temperature_changed`, `phase_changed`, `combo_discovered`, `era_started`, `log_line`, `run_ended`. No arithmetic, no rules in UI scripts. Reskinning touches zero game logic, and vice versa.
- **Seeded RNG, owned by the sim.** One `RandomNumberGenerator` seeded per run drives the card shuffle and crisis deck. Every bug report becomes "seed 4821, turn 9" — reproducible, and the prerequisite for the test bots.

`run_state` snapshots itself each climate phase (year, temp, net, sector states); that history *is* the post-mortem data, and the one-line cause is a scan over it.

**Build order** (riskiest playtest questions first; every step ends runnable): ① skeleton + JSON + `catalog.gd` validation (the validator is the compiler for JSON — first, not last) → ② headless sim core; prove do-nothing loses in 2043 before any pixel exists → ③ turn manager + market → ④ crisis deck + band scaling (bots: always-Pay / always-Absorb / always-Mortgage; assert always-Mortgage loses badly) → ⑤ combos + era gating → ⑥ ugly debug UI, game playable → ⑦ real UI (pure skin swap) → ⑧ balance harness: N seeds × each bot, printed against the §7 criteria — rebalancing becomes *edit JSON → run harness → read table* → ⑨ playtest pass (help overlay, softlock check, juice on the thermometer only).

## 6. Out of scope (MVP)

Meta-progression & insights, act boss checkpoints & transitions beyond the eras-lite banner, city archetypes, deckbuilding & breakthroughs, codex, real art & audio, save/load, tutorial (a single help overlay listing the rules is enough).

## 7. Done criteria

- [ ] Full run playable start → post-mortem, mouse only, no softlocks (end-turn always available).
- [ ] Doing nothing loses in 2043 ± 1 turn.
- [ ] A first-run player loses close (reaches ≥ +1.9° or gets within ~3 emissions of net zero).
- [ ] A player who chases combos wins between 2045 and 2050.
- [ ] All 3 combos trigger and display their banner.
- [ ] Era gates fire at 2038 and 2044: banner shows, market refreshes free, gated cards never appear earlier.
- [ ] Across three playtest runs, every crisis and windfall response gets chosen at least once — no dead options, no auto-picks.
- [ ] Every resource change appears in the turn log.
- [ ] Run length ≤ 25 minutes.
- [ ] All numbers above live in JSON — rebalancing requires zero GDScript edits.
