# Target Balance Bands — The Drawdown Protocol (Phase 1)

The structural corridor is now a **rate corridor**. The market deals a different hand
every turn, and that variance is a deliberate roguelike feature: scripted strategies
cannot — and must not — win every seed, while human play (which reads the deal, the
summit clock and the world curves) outperforms them. Tuning is therefore judged on
**win rates over the 20-seed batch** (`src/tools/batch_runs.gd`, `--enforce` in CI)
plus anchor trajectories from the canonical seed, not on per-decade value windows.
Data-driven balance, golden rule 9: if rates drift outside the corridor while players
report playing well, retune values (not formulas) until they fit.

## The Rate Corridor (20 seeds × 3 scripted archetypes)

| Archetype | Line | Requirement | Measured | Why the requirement holds |
|---|---|---|---|---|
| **Safe — Steady Shield** | Answers everything, buys down the world's actors, sinks, even transition; Sink Trust + Universal Services | Wins **≥ 50%** of seeds | **12 / 20** | The reference competent line; below 50% the game is too random to feel strategic |
| **Mixed — Grand Alliance** | Actors and allies first; treaties, funded transitions, Continental Rail | Wins **≥ 40%** of seeds | **11 / 20** | A second viable style proves no dominant strategy |
| **Risky — Moonshot Rush** | Home tech + research bets only; no diplomacy, sufficiency, or wellbeing | Wins **NEVER** (0%) | **0 / 20** | Structural, not statistical: it ignores the world's actors, whose curves climb undamped above 5.5 Gt of floors — global net cannot reach 0 without diplomacy. It revolts around turn 8 regardless |

Any risky win on any seed is a **structural violation** (the batch exits non-zero):
it would mean the game's core argument — you cannot decarbonize alone — has a hole.

## Anchor Trajectory (canonical seed 2030, baseline city)

Checkpoints from the committed fixture (`02_Sample_Runs.md` has the full tables):

| Checkpoint | Safe / Mixed (winners) | Risky (loss) | Danger signal for a human run |
|---|---|---|---|
| 2040 (turn 3) | T ≈ 1.46, net ≈ +45, H ≈ 64 | T 1.49, net +57, H 52 | net still ≥ +55 (no world lever pulled), H < 55 |
| 2050 (turn 5) | T ≈ 1.55, net ≈ +39 | T 1.62, net +60, H 28 | net not falling turn-over-turn; H < 40 (income penalty + ×3 social draws) |
| 2060 (turn 7) | T ≈ 1.62, net ≈ +30 | T 1.75, net +58, H 4 | band 2 entered; H under 25 — the revolt is ~2 turns away |
| 2080 (turn 11) | T ≈ 1.71, net ≈ +14 | dead (revolt 2065) | net > +20 with only 4 turns left |
| 2090–2095 | net crosses 0 → **win at turn 14** | — | clock ≥ 90% with net > +5 |
| KP | 12 | 3 | — |

Winners brush the Overshoot II doorstep (~+1.72 °C, clock ~72%) without crossing it;
the pivot target is **net zero by turns 13–14**. BAU (all-pass) dies around turn 7 —
the floor every strategy must clear.

## Summit Checkpoints (the mid-run bands the player actually sees)

The three COP targets double as the human-readable corridor — they were tuned so the
competent line meets them with effort and the bleeding line misses them visibly:

| Summit | Turn | Target | Read |
|---|---|---|---|
| Global Stocktake 2045 | 4 | net ≤ 45 | "Have you started?" — one world lever or a solid home decade suffices |
| Accord of 2065 | 8 | net ≤ 25 | "Is the curve bending?" — misses here predict a timeout loss |
| Last Horizon 2085 | 12 | net ≤ 8 | "Will you make it?" — met ⇒ the win is 2–3 turns out |

## Crisis, Combo and Meta Health Metrics

Provisional watch values for the 15-turn scale, to be re-measured in the Phase 8 pass:

| Metric | Competent corridor | Danger signal |
|---|---|---|
| Crises answered per turn | 1.5 – 3 | < 1 (bleeding); a permanent 3.0 with heavy surplus (answering too cheap — Risk #13) |
| Combos per run | 8 – 15 | < 4 (deck read as 33 singletons) |
| Combo chain, peak | 4 – 10 | 0 chain past turn 8 for a player trying |
| Projects completed per run | 1 – 2 | 0 (upkeep unaffordable — economy too tight) |
| Run-unlock cards earned per run | 3 – 6 | < 2 (growth conditions out of reach) |
| World levers (DIP4/DIP5/allies) pulled per winning run | ≥ 3 | 0 (the win happened without diplomacy — structural suspect) |
| Happiness at run end (winners) | 55 – 80 | ever-falling line (revolt predictor); pinned at 100 (stress too weak) |

## How to Use These Bands

1. In playtests and automated runs (Plan.md Phase 8), run the 20-seed batch per tuning
   change; the rate corridor is the pass/fail gate (`--enforce`), the anchor trajectory
   the smoke test that the three stories still read the same.
2. Losses should be attributable to a visible, early signal (a missed summit, a falling
   happiness line, an untouched world ledger) — the teachability test; the post-mortem
   must be able to name the pivotal turn.
3. If a strategy wins from outside the corridor — especially any risky win, or a win
   with zero world levers pulled — it is a dominant-strategy or structural suspect:
   check the watch list in `04_Policy_Effect_Matrix.md`.
