# Balance Model — The Drawdown Protocol (Phase 1)

Per-turn formulas for the race against the climate clock. The numbers below are validated
by the scripted strategy runs in `02_Sample_Runs.md` (regenerable via
`src/tools/gen_fixtures.gd` and the 20-seed batch harness), so they can be implemented
without guessing. All constants belong in data files (golden rule 9): `data/climate.json`,
`data/society.json`, `data/world_actors.json`, and the catalogs.

Metric definitions live in `../Phase_0/04_Simulation_Metric_Dictionary.md`.

## Constants

| Constant | Value | Meaning |
|---|---|---|
| `START_YEAR / END_YEAR` | 2030 / 2100 | The century |
| `YEARS_PER_TURN` | 5 | One decision turn = 5 years ⇒ a run is exactly **15 turns** (turn 1 = 2030, turn 15 = 2100) |
| `T_START` | 1.30 °C | Warming at run start (clock 30%) |
| `T_WARN / T_BAND2 / T_LOSS` | 1.50 / 1.75 / 2.00 °C | Overshoot I / Overshoot II / hard loss |
| `CLOCK_T_ZERO` | 1.00 °C | Clock origin: `clock_pct = (T − 1.0) / (2.0 − 1.0) × 100` |
| `K_WARM` | 0.0011 °C per Gt | Warming per unit of positive net, per turn (see Assumptions) |
| `K_COOL` | 0.00028 °C per Gt | Cooling per unit of negative net (~4× slower) |
| `T_FLOOR` | 1.20 °C | Warming cannot drop below this in-run |
| `SECTOR_BASE` | ind 20 / tra 15 / agr 15 GtCO2e/yr | City sector emissions at 0% progress (50 total, × archetype multipliers) |
| `RESIDUAL` | 10% | Sector emissions remaining at 100% progress |
| `A_START / A_FLOOR` | 20.0 / 5.0 GtCO2e/yr | Starting / minimum absorption |
| `SINK_STRESS` | [0, 0.5, 1.2] per turn | Absorption lost per turn by warming band |
| `M_START / H_START / I_START` | 150 / 60 / 15 | Starting money, happiness, influence |
| `INCOME_BASE / INCOME_PER_ALLY` | 250 / 40 | Money income per turn |
| `INFLUENCE_BASE / PER_ALLY / MEDIA` | 6 / 2 / 2 | Influence income per turn |
| `CO_BENEFIT_MAX` | 4.0 | Happiness gained per turn at full average transition |
| `OVERSHOOT_STRESS` | [0, 2, 4] per turn | Happiness lost per turn by warming band |
| `H_REVOLT` | 0 | Happiness at which the city revolts (instant loss) |
| `TECH_CAP` | 70% | Sector progress cap until a sufficiency card is played in that sector |
| `MAX_ALLIES` | 6 | Alliance cap |
| `ACTOR_TREND_PER_ALLY` | 0.2 Gt/turn | World drift absorbed per ally (steepest curve first) |
| `CRISES_PER_TURN` | 3 | Events drawn every turn (crises + opportunities) |
| `MARKET_SIZE` | 4 | Offers dealt to the project market every turn |
| `MAX_CARDS_PER_TURN` | 5 | Card plays per turn (the only per-turn action limit) |
| `COMBO_CHAIN_STEP / CAP` | 0.1 / 10 | Combo reward multiplier `1 + 0.1 × min(chain, 10)` — ×1.0 to ×2.0 |
| `PROJECT_MAX_ACTIVE` | 2 | Long-term projects running at once (each lasts 3 turns) |
| `KP_WIN_BONUS / KP_FLOOR` | 3 / 1 | Knowledge award: win bonus; minimum for any outcome |

## The World's Actors (`data/world_actors.json`)

The clock's engine. Four blocs emit alongside the player and advance their curves at the
end of **every resolved turn** — this is why net emissions worsen by default:

| Bloc | Emissions | Trend/turn | Floor |
|---|---|---|---|
| Korvat Industrial League | 12.0 | +0.6 | 2.0 |
| Azuria Continental Union | 7.0 | +0.2 | 1.5 |
| Meridian Trade Compact | 6.0 | +0.35 | 1.0 |
| The Frontier States | 5.0 | +0.45 | 1.0 |
| **Combined** | **30.0** | **+1.6** | **5.5** |

Each ally damps combined drift by `ACTOR_TREND_PER_ALLY` (0.2), applied to the steepest
curves first. The direct levers are cards: **DIP4 Fund a Transition** (−6 Gt off the
biggest emitter above its floor, trend −0.3) and **DIP5 Emissions Treaty** (trend −0.8 on
the steepest curve). This is the local-vs-global dilemma: cutting at home is safe but
slow; a funded transition abroad is the cheapest ton anywhere.

## Turn Pipeline (strict order)

Each turn resolves in this order. Implement as one method on the run state.

### 1. Income and project upkeep

```
income    = (250 + 40 × allies) × archetype_income_mult + passive_income_money
if H < 25: income ×= 0.5           # elif: only the strongest penalty applies
elif H < 40: income ×= 0.75
M += income
I += 6 + 2 × allies + (2 if media else 0) + archetype_bonus + passive_income_influence
H += passive_happiness_per_turn (clamped);  A += passive_absorption_per_turn
if flood_rebuild: prog[tra] += 5 (capped); flood_rebuild = false
for each active project (launch order):
    if upkeep affordable: pay; turns_left -= 1
        if turns_left == 0: COMPLETE - apply completion effects, add passives
    else: FAIL - apply abandon penalty (happiness, influence); project is gone for the run
```

### 1c. Event draw — the turn's pressure

Three events are drawn from the crisis deck (no duplicates within a turn), weighted per
entry by warming band and social state:

```
weight(entry) = weights[band(T)]
if entry has weight_mods:                      # social_crisis in the shipped deck
    if H < happiness_threshold: weight ×= low_happiness_mult
    if media: weight ×= media_mult
```

Weights table: `03_Event_Probability_Table.md`. Each drawn event also draws its flavor
target region. Crises show their damages and **response tags**; opportunities show their
seize reward. Then **on-draw spikes** apply immediately (a Record Heat Wave adds +1.0 to
`E_extra` the moment it lands; answering it this turn dissipates the spike before the
ledger is read, ignoring it makes the spike permanent). This is the ONLY consumer of the
events RNG stream (2 draws per event, fixed order).

### 1d. The project market — the turn's hand

`MARKET_SIZE` (4) offers are dealt from the player's available pool, weighted by each
card's `market_weight` × the archetype's tag lean, **without replacement**, from a
dedicated RNG stream. Two RNG-free adjustments follow:

- **Guarantee rule:** if no dealt offer carries any response tag of this turn's events,
  the last slot is swapped for the cheapest answering card — every turn stays interactive.
- **Bonus injections:** a drawn event may append its bonus card when the gate is met at
  draw time (Record Heat Wave adds HWP1 Heatwave Response Plan if H ≥ 40).

### 2. Player actions — fund up to 5 offers, resource-bound

Card list and effects: `04_Policy_Effect_Matrix.md`. Playability: the card is **in the
market**, cost affordable (money AND influence AND happiness), ally requirements met,
sector not at its cap, per-turn cap not reached. Funding an offer **consumes it** — the
market shrinks as the turn proceeds. Per play, in order:

```
pay costs (M / I / H); apply effects in catalog order; grant printed rewards
  (risk cards roll their printed chance on the risk RNG stream first,
   then apply the success or failure branch)
answer: first open drawn event whose response tags intersect the card's tags
        -> contained: flagged answered, response rewards granted immediately
tags of this play join the turn's tag multiset
combo check: every not-yet-fired-this-turn combo whose tag multiset is covered FIRES:
        mult = 1 + 0.1 × min(chain, 10)      # chain BEFORE this combo
        chain += 1; apply combo effects; grant rewards × mult
        (knowledge rewards only on the combo's FIRST fire of the run)
        (2+ combos in one turn triggers the CASCADE feedback in UI)
deck growth check: unlock conditions (crises answered, combos, allies,
        sector progress, projects completed)
```

Projects may be launched (pays the first turn's upkeep immediately) or abandoned
(applies the penalty) at any point during the action phase. Passing (zero cards) is
legal and banks the money — but the post-mortem remembers a full treasury left idle.

Happiness penalty rule: a sufficiency card's negative happiness cost is **waived** if
`media` is active or a social-crisis `window` is open (window is then consumed; media
does not consume the window).

### 3. Carbon ledger

```
for each answered crisis with an on-draw spike: E_extra -= spike   # it dissipates
for each maturing restoration program: A += per_turn; turns_left -= 1
sink_stress = SINK_STRESS[band(T_prev)]        # reads LAST turn's temperature
A = max(A_FLOOR, A − sink_stress)
E_city  = Σ_sector base_s × arch_mult_s × (1 − 0.9 × prog_s / 100) + E_extra
E_world = Σ_actor emissions
N = E_city + E_world − A
```

### 4. Warming — the clock ticks

```
dT = K_WARM × N   if N > 0
dT = K_COOL × N   if N ≤ 0
T = max(T_FLOOR, T + dT)
clock_pct = (T − 1.0) / (2.0 − 1.0) × 100
```

### 5. Happiness drift (co-benefits vs Overshoot stress; band of the NEW T)

```
co_benefit = 4.0 × (average sector progress) / 100        # max +4/turn at full transition
stress     = OVERSHOOT_STRESS[band]                        # 0 | 2 | 4
H = clamp(H + co_benefit − stress, 0, 100)
```

### 6. Unanswered crises strike

Answered events are contained — no damage, no rider. Each unanswered **crisis** applies
its damages (`03_Event_Probability_Table.md`), scaled where the catalog says so:

```
R    = clamp(0.4 × H + adapt, 0, 100)   # frozen at step-6 entry
mult = 1 − R / 200                      # R = 100 halves damage
```

Only a crisis that actually strikes opens its opportunity rider (fire discount, flood
rebuild, policy window), appends its scar, and counts its fire. Unanswered
**opportunities** simply pass by — nothing lost but the chance. A comboless turn decays
the combo chain by 1 (min 0).

### 6b. Summit evaluation (turns 4 / 8 / 12)

The target was announced turns in advance (HUD next-summit line + turn-start banner);
it reads **this turn's resolved net**:

```
if turn has a summit:
    met = N ≤ goal              # Stocktake 2045: 45 | Accord 2065: 25 | Last Horizon 2085: 8
    met    -> grant reward (money / influence / happiness)
    missed -> apply penalty (influence / happiness)
    record in summit_results; emit summit_resolved
```

### 7. One-time feedback loops

```
if T ≥ 1.75 and not permafrost:  E_extra += 2.0
if T ≥ 1.90 and not ocean_weak:  A = max(A_FLOOR, A − 2.0)
if fires ≥ 3 and not amazon:     A = max(A_FLOOR, A − 3.0)
```

### 7b. The world advances (only if the run continues)

```
damp = allies × 0.2
for each actor, steepest trend first:
    use = min(damp, trend); damp -= use
    emissions = max(floor, emissions + trend − use)
```

### 8. End-of-turn check (strict precedence)

```
if T ≥ 2.00        → LOSS_LIMIT_BREACHED   (the tipping point, any turn)
if H ≤ 0           → LOSS_REVOLT           (the city rises, any turn)
if N ≤ 0           → WIN_NEUTRAL           (carbon neutrality — at ANY turn)
if year ≥ 2100     → LOSS_NOT_NEUTRAL      (survived, not neutral)
else               → year += 5; next turn
```

The win fires the moment the world absorbs more than it emits — the earlier the
drawdown moment, the better the story (and the post-mortem says so).

## Knowledge Points (meta, awarded at run end)

```
KP = (last_year − 2030) ÷ 10 (floor)          # decades survived: 0–7
   + count(sector progress ≥ 70%)             # 0–3
   + allies ÷ 2 (floor)                       # 0–3
   + 3 if WIN
   ... with a FLOOR of 1                      # every outcome pays the meta
   + kp_earned                                # in-run insight: first-fire combo
                                              # rewards, research successes,
                                              # seized opportunities (~0–4)
```

Anchor range: 3 (turn-8 revolt) to 12 (turn-14 win). A 7-node Knowledge tree priced at
5–12 KP per node gives one meaningful unlock every one-to-two runs (golden rule 10).

## The tactical economy (why the numbers hold)

- **The cheapest ton is abroad.** DIP4 (120 M + 8 I) removes 6 Gt from the world ledger
  at a stroke — no home card comes close per unit of money — but it does nothing for
  your sectors, allies, or happiness. Diplomacy is leverage, not development.
- **Answering pays, but costs tempo.** A response card (25–40 M) plus its response reward
  (~15–20 in resources) roughly cancels the avoided damage (30–60 M plus pillar hits) —
  the real cost of answering is the market slot and money NOT spent on transformation or
  treaties that turn.
- **Combos are the profit margin.** A deliberate two-card pair yields +20 to +40 base,
  ×chain; the chain (+1 per combo, −1 on quiet turns) is what funds answering three
  Overshoot-strength crises at once late-century.
- **Projects convert surplus into permanence.** 240–330 M over three turns buys income,
  sinks, wellbeing or allies for the remaining decades — the main mid-run money sink.
- **Ignoring people ends the run.** Overshoot stress (−4/turn in band 2), unanswered
  crises, and happiness-cost cards stack: the Moonshot Rush archetype revolts around
  turn 8 with money still in the bank — cash is not the binding constraint, consent is.

## Determinism

One base seed per run, split into six independent streams (`SeedUtil`): 1 world, 2 events,
3 tiles, 4 names, **5 market**, **6 risk**. Consumers are fixed-order: the event draw
(pick + target per event), the market deal (exactly `MARKET_SIZE` draws), and risk-card
rolls. Same seed + same decisions ⇒ same timeline, byte-identical JSONL replay, for tests
and balance regression. The canonical fixture seed is **2030**.

## Known model gaps (accepted for Phase 1)

- Winners bank ~1 000 by the drawdown turn (down from ~6 500 in the yearly model);
  summits, actor funding and project upkeep absorb most of the old surplus. Risk #5
  stays open but downgraded.
- The old happiness-saturation gap is resolved: winners now hold ~55–80 and end in the
  mid-60s — Overshoot stress at −2/−4 per turn keeps the social pillar live all century.
- Influence is uncapped; consider a cap in a later pass.
- Baseline assumes zero Knowledge nodes and **no archetype** (headless/test default);
  archetype multipliers are specified but not part of the corridor measurements.
