# 04 — Rebalance Plan: The Compromise Pass

**Status: implemented and tuned, 2026-08-04.** This document records the plan as approved, what each step actually changed, and the evidence. The problem it solves: *"I never lose, I don't feel the compromise, I always have too much money."*

## Diagnosis (before)

The balance harness (40 seeds × 6 bot profiles) showed the game was **calendar-gated, not resource-gated**:

| profile | wins | win yr | temp |
|---|---|---|---|
| do-nothing | 0/40 | — | 2.02° |
| greedy (temptations) | **40/40** | 2044 | **1.70°** |
| clean/combo | 40/40 | 2044 | 1.73° |
| clean, always-pay | 38/40 | 2044 | 1.74° |
| clean, always-absorb | 1/40 | — | 1.68° |
| clean, always-mortgage | 34/40 | 2044 | 1.78° |

Every viable strategy won in exactly 2044 — the first year Act III's floors permit net zero — and the *greedy* bot (buys every temptation) won 40/40 with the best temperature. Arithmetic: winning needed ~20 units of cuts at ~3 M$/unit ≈ 60–70 M$; income was 9/turn *rising*, yielding ~140 M$/run. Money never ran out, so it never created a decision, and temptations were free money (+5 M$ vs ~3 M$ to undo the +1 emission).

## The seven steps

### 1. Dirty income — sector income coupled to emissions ✅

`sector income = income_clean + ⌊emissions / dirty_divisor⌋`. Config start values keep the old 9/turn total: Industry 2 + 8/2 = 6, Transport 0 + 6/6 = 1, Food 0 + 5/5 = 1, Housing 0 + 4/4 = 1. Every cut card now shrinks next year's budget; decarbonize fully and national income collapses to ~2–4 unless clean engines (Carbon Tax, Process Electrification, District Heating, Green Jobs, …) replace the fossil tax base. `sector_income` effect atoms mutate the **clean** side only. Chosen over a flat expense line because an expense is tuning (less money, same decisions) while coupling is tension (every cut has a visible price).

### 2. Carbon lock-in on temptations ✅

New `floor_lock` effect atom: temptations permanently raise the sector's hard-to-abate floor — infrastructure no later era forgives; only extra absorption can cancel it. Fossil Subsidy 🔒 Industry +2, Concrete Boom 🔒 Housing +2, SUV Boom 🔒 Transport +2, Airport Expansion 🔒 Transport +1 & Industry +1. The ◆ projection and the era-floor arithmetic both price the locks, so the climate bar tells the truth about the devil's deal. Bonus irony that emerged in tuning: locked emissions keep paying dirty income — the fossil economy keeps paying you right up until the absorption bill arrives.

### 3. Crisis scaling with temperature ✅ (mechanism existed — levers strengthened)

Band scaling already existed (`Effects.scaled`, additive bumps per band) but never bit: clean runs peaked below the 1.7° B-boundary. Bands moved and steepened: **B ≥ 1.65° (+3 M$ / +5%)**, **C ≥ 1.8° (+6 M$ / +10%)**. Slow, hot runs now bleed money through the whole endgame.

### 4. Popularity drift asymmetry ✅

`popularity_drift` split into `popularity_drift_up: 2` / `popularity_drift_down: 3`. Spent approval takes ~2.5× longer to heal than before, so 0-M$ popularity-cost cards (110 on the Motorway, Heated Terrace Ban) stop being free.

### 5. Harness targets v2 + tuning loop ✅

New bot: **income-blind** (clean but never buys an income card — the control proving the tax-base squeeze is real). Clean bot learned one behavior: when income < 8, income engines jump the buy queue. Tuning iterations (all knobs JSON-only): locks 1→2 on the pure-money temptations, band B +2→+3, Act II card costs +1, Act III card costs +2. Band C +6→+8 was tried and **reverted** (hurt always-pay more than the grinders it aimed at).

### 6. UI: the compromise made visible ✅

Top bar shows `+7M$/yr · 5 dirty`; sector panels show `Income 6 = 2 + 4 dirty` and `🔒+N` locks; every card and crisis response carries a computed **Δ income** annotation (dirty losses and floor-wasted cuts included — `RunState.projected_income_delta()`, so the zero-logic-in-UI rule holds); rules and intro teach both mechanics. The player sees the price of a cut *before* buying it.

### 7. Documentation ✅

This file; status + numbers synced in [02_MVP_Spec.md](02_MVP_Spec.md); full architecture & arithmetic reference in [05_Architecture_Reference.md](05_Architecture_Reference.md); decision log entry in [Design_History.md](Design_History.md).

## Result (after)

| profile | wins | win yr (spread) | loss yr | temp | pop-death |
|---|---|---|---|---|---|
| do-nothing | 0/40 | — | 2042 | 2.02° | 0 |
| greedy (temptations) | **5/40** | 2060 (2053–2069) | 2053 | 2.00° | 0 |
| clean/combo | **26/40** | 2058 (2050–2069) | 2062 | 1.94° | 0 |
| clean, income-blind | 12/40 | 2065 (2057–2077) | 2059 | 1.99° | 0 |
| clean, always-pay | 17/40 | 2058 (2048–2068) | 2062 | 1.96° | 0 |
| clean, always-absorb | 0/40 | — | 2037 | 1.67° | 40 |
| clean, always-mortgage | 7/40 | 2059 (2054–2066) | 2059 | 1.99° | 0 |

Targets: do-nothing 2042±1 ✅ · greedy <25% ✅ (12.5%) · clean 60–70% ✅ (65%) with a 19-year win spread ✅ · absorb dies ✅ · mortgage < pay ✅ · income-blind <25% ⚠ (30% — see watch items). Average winning temperature 1.94°: losses are close, wins are narrow. 67/67 unit tests green.

## Watch items for the next pass

1. **Income-blind at 30%** (target <25%). The gap to clean (35 points) already proves engines decide runs; push the rest with *content* (more/better engine cards creating real engine strategy) rather than more price pressure — always-pay is the canary that price pressure is spent.
2. **The win window drifted late** (2050s vs the brief's 2045–2050 real-world framing). If playtests find runs long, compress era years (2038/2044 → 2036/2042) rather than cutting prices — that moves the whole window earlier without reopening the money faucet.
3. **Bot heuristic honesty**: the clean bot's income-floor trigger (buy engines when income < 8) is one hard-coded number in `bots.gd`; if balance ever hinges on it, playtest against humans before trusting the table.
4. **One-cut income cliffs**: at divisor 6/5/4, the first cut in Transport/Food/Housing deletes that sector's whole 1 M$ income. Intended (small sectors have thin margins) but watch whether players read it as a bug.
