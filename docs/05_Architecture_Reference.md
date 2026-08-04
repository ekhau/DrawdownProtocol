# 05 — Architecture & Arithmetic Reference

As-built reference for the Godot MVP, exact as of 2026-08-04 (post compromise pass). [02_MVP_Spec.md](02_MVP_Spec.md) says what the game should be; this file documents what the code *is*: every layer, every feature, and every formula. When code and this file disagree, fix one of them — preferably in the same commit.

## 1. The three layers

```
src/
  data/                          LAYER 1 — content (all balance lives here)
    config.json                    start values, warming factor, bands, tipping points, eras+floors, sectors, palettes
    cards.json                     44 cards (effects, costs, gates, risk blocks, combo tags)
    crises.json                    13 normal (10 crises + 3 windfalls) + 3 social
    combos.json                    5 hidden sets
  scripts/
    core/                        LAYER 2 — pure simulation (RefCounted, zero Node code)
      catalog.gd                   loads + validates all JSON at boot; fails loud, names the entry
      run_state.gd                 THE state + derived values + signals
      effects.gd                   the single mutation door + band scaling + describe()
      turn_manager.gd              phase state machine + the five verbs
      market.gd                    deal/reroll/blockers/buy (incl. risk resolution)
      crisis_deck.gd               two pools, band scaling, social mode
      combo_checker.gd             set detection after every purchase
      climate_calc.gd              climate phase (incl. tipping points) + the two projection instruments
    autoload/game.gd             façade: owns Catalog + TurnManager, re-emits signals, forwards verbs
    ui/main_ui.gd                LAYER 3 — a disposable skin; calls verbs, repaints from signals
  scenes/main.tscn               single Control-node scene
  tests/
    run_tests.gd                 77 headless assertions (invariants + regressions)
    balance.gd                   the harness: 40 seeds × 7 bot profiles vs §7 targets
    bots.gd                      scripted players (buy policies × crisis policies)
    screenshot_driver.gd         boots the real UI, pokes the sim, saves before/after PNGs
```

Three rules carry the maintainability load:

1. **The sim runs without the scene tree.** Everything in `core/` is `RefCounted`, no `get_node()`, no UI references. Tests run headless; the harness simulates hundreds of runs in seconds.
2. **`Effects.apply()` is the only door into state.** Every card effect, crisis response, combo bonus, income tick, and drift tick goes through it — which emits the signals *and* writes the turn-log line, so "every number change is traceable" holds by construction.
3. **The UI computes nothing.** It may call five verbs — `choose_response(i)`, `buy_card(id, boosts)`, `reroll()`, `end_turn()`, `new_run(seed)` — and repaints from signals. Anything the UI displays that needs arithmetic (era briefs, projections, income previews, blockers) is a read-only query on the core.

### Signal flow

`RunState` emits → `Game` (autoload) re-emits → `main_ui` repaints. Signals: `resources_changed`, `sector_changed(id)`, `temperature_changed(t)`, `phase_changed(p)`, `market_changed`, `combo_discovered(id)`, `risk_resolved(id, ok)`, `tipping_point_crossed(id)`, `era_started(id)`, `log_line(text)`, `run_ended(result)`, plus `Game.run_started`. Ordering contract: `market_changed` fires at the single point every offer mutation flows through (`Market._fill()`), guaranteed *after* state settles — the fix for the 2026-08-03 desync (see Design_History).

## 2. The turn state machine

One turn = one year. Phases (`RunState.Phase`): **CRISIS → ACTION → INCOME → CLIMATE**, then next year (or **ENDED**).

1. **Turn start** (`TurnManager._start_turn`): reset transient gross delta and reroll flag; if the year enters a new era — log banner, free market refresh, `era_started`. From turn `crisis_start_turn` (2) draw a crisis *before* emitting the phase signal (the modal paints from `phase_changed`).
2. **CRISIS**: the player picks exactly one response; effects apply pre-scaled (see §6.6). A popularity collapse check runs immediately after.
3. **ACTION**: buy any number of affordable cards; ≤1 reroll (1 M$). Combo check + collapse check after every purchase.
4. **INCOME** (automatic on End Year): `money += total_income()`, then popularity drift.
5. **CLIMATE** (`ClimateCalc.run_phase`): warming, tipping-point crossings, snapshot, win/lose check — crossings land *before* the win check (§6.10).

Run end paths: **win** — structural net ≤ 0 at climate phase; **loss** — temp ≥ 2.0° at climate phase, or popularity < 10% after any crisis/purchase; bots also record a stalemate loss at 200 turns (guard, never reached in practice).

## 3. Data model

### RunState fields

| field | meaning |
|---|---|
| `turn`, `year` | 1-based turn; `year = start_year + turn − 1` |
| `temp` | global warming, °C above pre-industrial |
| `money` | M$, clamped ≥ 0 |
| `popularity` | 0–100%, government approval |
| `absorption` | carbon sink units, clamped ≥ 0 |
| `world_emissions` | permanent planetary emissions from tipping-point scars — no sector, no dirty income, uncuttable, era floors never apply; clamped ≥ 0 |
| `crossed_tipping_points` | tipping point ids in crossing order — each fires at most once per run |
| `income_bonus` | flat M$/turn from `income_per_turn` atoms (may go negative) |
| `gross_this_turn_delta` | transient gross modifier, reset each turn (Mild Winter) |
| `sectors[id]` | `{name, emissions, income_clean, dirty_divisor, start_emissions}` |
| `floor_locks[id]` | permanent floor raises from `floor_lock` atoms |
| `owned_cards`, `discovered_combos` | purchase order / discovery order |
| `history` | one snapshot per climate phase (year, temp, gross, net, money, popularity, absorption, world_emissions, per-sector emissions+income) — this *is* the post-mortem data; `end_run` also packages `tipping_points` (the crossed ids) |
| `rng`, `run_seed` | one seeded `RandomNumberGenerator` per run — shuffles and risk rolls |

### Effect atoms (the whole mutation vocabulary)

| atom | fields | does |
|---|---|---|
| `money` | amount | `money += a` (floor 0) |
| `popularity` | amount | `popularity += a` (clamped 0–cap) |
| `absorption` | amount | `absorption += a` (floor 0) |
| `sector_emissions` | sector, amount | emissions += a; **cuts clamp at the sector floor** (§6.4) |
| `sector_income` | sector, amount | `income_clean += a` — the clean side only, unclamped |
| `income_per_turn` | amount | `income_bonus += a` |
| `gross_this_turn` | amount | transient gross delta, this climate phase only |
| `floor_lock` | sector, amount | `floor_locks[sector] += a` — permanent |
| `world_emissions` | amount | `world_emissions += a` (floor 0) — planetary, joins gross and structural net but pays no income and cannot be cut by cards |

`PERM_TYPES` (flagged "⚠ perm" in crisis UI, never band-scaled): `sector_emissions`, `sector_income`, `income_per_turn`, `absorption`, `floor_lock`, `world_emissions`.

### Card schema (cards.json)

`id, name, sector, cost_money, cost_popularity, available_from, effects[]` + optional `combo` (set tag), `requires_popularity` (gate: checked, never spent), `risk` block: `{offset, boost_cost, boost_amount, boost_max, cap, on_fail[]}`. Catalog validates every key, every atom type, every sector reference, combo→card references, and duplicate ids at boot — the validator is the compiler for JSON.

### Crisis schema (crises.json)

`id, name, kind (crisis|windfall), flavor, responses[1..3]` + optional `social: true`. Each response: `name, archetype (pay|absorb|mortgage|invest), effects[]`. Archetypes are design guidance, not rules.

## 4. Features, one paragraph each

**Market.** Pool of all 44 cards, Fisher-Yates-shuffled with the run RNG. `market_size` (4) face-up; only cards with `available_from ≤ year` deal. Buying removes the card from the run's pool (no replacement) and refills only the emptied slot; unbought cards cycle back on refresh. Reroll: once per year, `reroll_cost` (1 M$). Era changes refresh free.

**Blockers (the anti-suicide clause).** `Market.blockers()` is the single read-only authority on why a card can't be bought: `money` shortfall; `popularity_gate` (below `requires_popularity`); `popularity` (can't afford the spend); `popularity_floor` (the spend would land inside the collapse zone — only crises may bring a government down); `risk_floor` (same rule extended through a gamble's failure branch). The UI renders these as red cost fragments + a one-line reason.

**Gambles (risk cards).** Buying opens a two-step confirm. Success chance = §6.7. One attempt per run, card consumed win or lose; success applies `effects`, failure applies `on_fail`. Rolls come from the run RNG and are logged ("rolled 71 vs 68%").

**Crisis deck.** Two pools partitioned by `social`, each reshuffled when empty. Below `social_crisis_threshold` (30%) the year's draw comes from the social pool — *replacing* the normal draw. Windfalls are dealt from the normal pool and never band-scale. Every social crisis carries at least one popularity-positive recovery choice (anti-death-spiral rule).

**Eras & floors.** Three acts (2030/2038/2044) gate cards (`available_from`), repaint the UI palette (magma/viridis/parula), and set per-sector `min_sector_emissions` floors — cuts below the floor are clamped and logged, never silent. `floor_lock` atoms raise floors permanently on top of the era values.

**Combos.** After every purchase, `ComboChecker` scans undiscovered combos; a completed set applies its bonus through `Effects` and banners. Era gating staggers the five sets across the acts.

**Popularity system.** Baseline drift (§6.8), social threshold 30%, collapse floor 10%, `requires_popularity` gates on radical cards, risk odds driven by popularity — one resource, five mechanical roles.

**Tipping points.** The thermometer is the boss, but it never hits back — until a threshold falls. Config-driven temperature thresholds (`tipping_points`, sorted ascending at load, validated like everything else), telegraphed on the climate bar as dark red ▲ markers with per-marker tooltips. In the climate phase, after the temperature advances and *before* the win/lose check, every not-yet-crossed point at or below the new temperature fires in ascending order: crossed id recorded, dramatic log line, effects through `Effects.apply` (source = the point's name), `tipping_point_crossed(id)` emitted, red alarm banner in the UI. Each fires at most once per run; deterministic, no RNG. Permafrost's scar introduced the `world_emissions` atom: planetary emissions outside the city's control — in gross and structural net, but no sector, no dirty income, uncuttable, immune to era floors. The ◆ projection prices not-yet-crossed points (§6.8).

**Projections (the honest UI).** Two pure instruments in `ClimateCalc`, both driven by one forward simulation (`_project`): the **◆ neutrality marker** (where warming stops if the recent pace of cuts holds) and **breakeven gross** (the highest gross from which the current pace still wins — kept tested as the ◆'s dual even though the UI no longer draws it). Both respect era floors, floor locks, and freeze absorption at today's value.

**Post-mortem.** `end_run` packages cause, year, temp, seed, full timeline, combos, cards. The one-line cause names the sector that decarbonized least.

**Bots & harness.** Buy policies: `none`, `greedy` (everything, temptations included, gambles at any odds), `clean` (combo-first, cheapest-next, never temptations, gambles ≥70%, skips floor-wasted cuts, income engines jump the queue when income < 8), `income_blind` (clean minus income cards). Crisis policies: `default` (money-only options first, else least popularity loss), or forced archetype. The harness prints wins, win-year spread, loss year, temp, popularity deaths, combos/run against the §7 targets.

## 5. Starting numbers (config.json, current)

| quantity | value |
|---|---|
| start year / temp / lose temp | 2030 / +1.50° / +2.00° |
| warming per net emission | 0.002 °/unit/yr |
| start money / popularity / absorption | 10 M$ / 50% / 3 |
| popularity cap / collapse / social threshold / baseline | 100 / 10 / 30 / 50 |
| popularity drift up / down | +2 / −3 per year |
| market size / reroll cost / crisis start turn | 4 / 1 M$ / 2 |
| bands | A base · B ≥ 1.65° (+3 M$/+5%) · C ≥ 1.8° (+6 M$/+10%) |
| tipping points | Permafrost +1.70° (world_emissions +2) · Amazon Dieback +1.85° (absorption −2) · Ice-Sheet +1.95° (income −2 M$/turn, popularity −10%) |
| sectors (emissions, clean, divisor) | Industry (8, 2, 2) · Transport (6, 0, 6) · Food (5, 0, 5) · Housing (4, 0, 4) |
| era floors I / II / III | 5-3-2-2 / 3-2-1-1 / 0-0-0-0 (Industry-Transport-Food-Housing) |

Derived at start: gross 23, net 20, income 9 (5 dirty + 4 clean-ish: industry 2 clean, +1 industry dirty rounding), warming +0.040°/yr, do-nothing breaches +2.0° on turn 13 (year 2042). Total warming budget from +1.5°: 0.5° = **250 net-emission-unit-years**.

## 6. The arithmetic, exhaustively

### 6.1 Emissions & warming

```
gross            = max(0, Σ sectors.emissions + world_emissions + gross_this_turn_delta)
net              = gross − absorption
structural_net   = Σ sectors.emissions + world_emissions − absorption   (no transients)
climate phase:     if net > 0: temp += net × warming_per_net_emission
                   then tipping-point crossings (§6.10), then snapshot
win              : structural_net ≤ 0 at climate phase       (transients can't fake it)
lose             : temp ≥ lose_temp at climate phase, or popularity < popularity_collapse any time
```
`world_emissions` delays the win exactly like a floor lock: only extra absorption can cancel it.

### 6.2 Income

```
dirty_income(s)  = ⌊ emissions_s / dirty_divisor_s ⌋            (integer division)
sector_income(s) = max(0, income_clean_s + dirty_income(s))     (clean may be negative)
total_income     = max(0, income_bonus + Σ sector_income(s))
income phase     : money += total_income
```
Consequences to know: cutting Industry by 2 always costs 1 M$/yr; the first cut in Transport/Food/Housing deletes that sector's whole 1 M$ (divisor = start emissions); a fully decarbonized economy pays only clean income + bonuses. `sector_income` atoms hit `income_clean` (unclamped — a drained clean side eats into dirty, floor 0 per sector).

### 6.3 Income preview (`RunState.projected_income_delta(atoms)`)

Simulates on copies: applies `sector_emissions` (with the §6.4 floor clamp), `sector_income`, `income_per_turn`; ignores everything else; returns `new_total − current_total`. This is the "Δ income" the UI prints on cards, crisis responses, and gamble outcomes — dirty losses and floor-wasted cuts included. Pure read; the only place the UI-visible economy math lives outside the mutation path.

### 6.4 Floors & the cut clamp

```
sector_floor(s)  = era_min_sector_emissions[s]  +  floor_locks[s]
cut clamp        : on a negative sector_emissions atom,
                   target = max(emissions + amount, min(emissions, sector_floor))
                   (waste is logged: "X is at this era's hard-to-abate floor")
```
Positive emission atoms never clamp. Locks are permanent — Act III with locks bottoms at Σ locks, so a locked run needs `absorption ≥ Σ locks` on top of everything else to win. Current locks: Fossil Subsidy +2 Industry, Concrete Boom +2 Housing, SUV Boom +2 Transport, Airport Expansion +1 Transport & +1 Industry.

### 6.5 Popularity

```
drift (income phase): popularity += clamp(baseline − popularity, −drift_down, +drift_up)
                      = +2/yr max when below 50, −3/yr max when above
collapse            : popularity < 10 after a crisis/purchase → run ends (checked, never mid-atom)
social mode         : popularity < 30 at draw time → year's crisis comes from the social pool
purchase floor      : a buy may never leave popularity < 10 (blockers: popularity_floor)
gates               : requires_popularity is checked, never spent
```

### 6.6 Band scaling of crisis costs

```
band            = highest band with temp ≥ min_temp          (A < 1.65 ≤ B < 1.8 ≤ C)
scaling         : for each NEGATIVE money/popularity atom in a crisis response:
                    money      amount −= cost_bump_money       (B +3, C +6)
                    popularity amount −= cost_bump_popularity  (B +5, C +10)
never scaled    : gains, permanent atoms, windfalls (kind = "windfall")
```
Scaling happens at *draw* time (`CrisisDeck.draw` → `Effects.scaled`), so the modal shows the true price.

### 6.7 Gamble odds

```
success_chance  = clamp(popularity + offset + boosts × boost_amount, 0, cap)
boost cost      : boost_cost M$ each, max boost_max          (all three: 2 M$, +5%, ×3, cap 90)
roll            : rng.randi_range(1, 100) ≤ chance → effects; else → on_fail
risk_floor      : blocked if popularity − cost_popularity + Σ(negative popularity in on_fail) < collapse
```

### 6.8 Projection & pace (the ◆ and the 2.0° line)

```
pace            = (structural_net(3 yrs ago) − structural_net(now)) / min(3, turn)
                  — reference read from history; this turn's purchases count immediately
_project(start_net, pace):
  temp' = temp + start_net × 0.002 ; then per future year:
    remaining = max(remaining − pace, era_floor_net(year))
    era_floor_net(y) = Σ_s (era_min[y][s] + floor_locks[s])
                       + world_emissions + world' − absorption'
    remaining ≤ 0 → reachable at (temp', year) ; temp' ≥ 2.0 → not reachable
  after every temp' advance: any not-yet-crossed tipping point with temp' ≥ its
  threshold fires IN THE PROJECTION (ascending order) — the ◆ prices the future:
    world_emissions atoms : world' += a ; remaining += a        (uncuttable: also in the floor)
    negative absorption   : absorption' = max(0, absorption' + a) ;
                            remaining += the absorption actually lost
    income/popularity     : ignored (not net-relevant)
  absorption' starts frozen at today's value; world' at 0 (today's world_emissions
  is already inside start_net and the floor)
breakeven_gross = largest gross whose (gross − absorption) still projects reachable
                  (linear search from absorption upward; = absorption when pace ≤ 0)
```
Invariant (unit-tested): `gross ≤ breakeven_gross ⟺ neutrality_projection().reachable` — it survives the tipping extension because `_project` stays monotone in `start_net` (hotter walks cross earlier and scar harder). Pace reference reads `world_emissions` from history snapshots, so a real crossing registers as a genuine slowdown of net decline for the next ≤3 years.

### 6.9 Determinism

One RNG seeded per run drives: card pool shuffle, crisis pool shuffles, risk rolls. Same seed + same actions ⇒ identical run (tested). Tests predict risk rolls by cloning `rng.seed` + `rng.state`. UI-side `Game.new_run()` picks `randi()` only when no seed is given.

### 6.10 Tipping-point crossings

```
in run_phase, AFTER temp advances and BEFORE snapshot + win/lose:
  for each tipping point in ascending threshold order (sorted at load):
    skip if id ∈ crossed_tipping_points, or temp < threshold
    else: record id → dramatic log line → Effects.apply(effects, name)
          → tipping_point_crossed(id)
```
Consequences to know: each point fires at most once per run, deterministically (no RNG); a hot year can cross several at once; and because crossings precede the win check, an Amazon Dieback can push a structural net of 0 back above zero and steal a same-year win — the planet doesn't wait for the press conference. Catalog validation: unique ids, non-empty name, temp strictly inside (start_temp, lose_temp), non-empty valid effects; the list is sorted ascending at load.

## 7. Testing & balance infrastructure

- `run_tests.gd` — 77 assertions: catalog validation (incl. malformed tipping points), determinism, dirty income, floor locks, income preview, do-nothing timing, mortgage-vs-pay ordering, band scaling + windfall exemption, era gating/briefs, market buy/reroll/ghost-click, all blockers, gamble odds/floors/branches, drift asymmetry, social pool switching, collapse, combos, both projections, and tipping points (world_emissions semantics, single-fire crossing + signal + log, multi-cross ordering, crossing-before-win-check, projection pricing + breakeven invariant). Run: `godot --headless -s res://tests/run_tests.gd` from `src/`.
- `balance.gd` — 40 seeds × 7 profiles vs targets (§7 v2 of the spec). Run the same way. Rebalancing = edit JSON → run harness → read table; the current table lives in [04_Rebalance_Plan.md](04_Rebalance_Plan.md).
- `screenshot_driver.gd` — visual smoke check: `godot -s res://tests/screenshot_driver.gd -- /out/dir` saves before/after PNGs of the real UI.

## 8. Balance knob index (what to touch, what it moves)

| knob (JSON) | moves | sensitivity notes from the 2026-08 pass |
|---|---|---|
| `dirty_divisor` / `income_clean` | how hard decarbonization starves the budget | the core difficulty lever; halving industry's divisor ≈ doubling the squeeze |
| Act II/III `cost_money` | endgame scarcity; engine necessity | +1/+2 across the acts moved clean 87%→65% and blind 47%→30% |
| `floor_lock` amounts | temptation viability | at 1 greedy still won 33/40; at 2 it fell to ~12% |
| band `min_temp` / bumps | cost of running hot | B-band money bump is the anti-grinder tax; C +8 was too blunt (hurt always-pay first) |
| `popularity_drift_up/down` | price of popularity-cost cards; spiral recovery speed | up:2 keeps social spirals escapable; up:1 untested |
| era `from_year` | win-window position | untouched this pass; compress to pull wins earlier without adding money |
| `market_size` | strategy visibility, stall risk | 4 since the pool grew to 38+; shrinking it re-creates stalls |
| `warming_per_net_emission` | everything at once | anchored by "do-nothing loses 2042" — do not touch for difficulty |
| `tipping_points` temps / amounts | cost of running hot; endgame drag | permafrost +2 & dieback −2 pushed clean wins 2044 → 2046 and shaved 2/40 wins; soften via dieback −2 → −1 or thresholds +0.02–0.05 before touching anything else |
