# Balancing Assumptions — The Drawdown Protocol (Phase 1)

Every deliberate simplification behind the balance model, written down so it can be
challenged and revised without archaeology (Plan.md Phase 1 deliverable; pillar 5 —
science drift is only acceptable when it is documented).

## Climate Model

1. **Starting emissions 50 GtCO2e/yr** (industry 20 / transport 15 / agro-economy 15).
   Real-world 2030 projections are ~50–55 GtCO2e/yr; sector split is stylized (real
   transport is ~15%, not 30%) to give the three sectors equal strategic weight.
2. **Starting absorption 20 GtCO2e/yr** ≈ the roughly half of emissions that land and
   ocean sinks currently take up. Treated as a stock the player can grow (restoration) or
   lose (fires, warming stress) — a gameplay abstraction of sink dynamics.
3. **Warming rate 0.001 °C per GtCO2e of positive net emissions.** Roughly 2× the real
   TCRE (~0.00045 °C/Gt): compression for pacing, and a stand-in for non-CO2 forcing.
   Consequence: the remaining "budget" from +1.3 to +2.0 °C is 700 Gt net — the right
   order of magnitude versus IPCC remaining-budget estimates.
4. **Cooling at 0.00025 °C/Gt (4× slower than warming)** when net-negative, floor
   +1.20 °C. Encodes "overshoot is partly reversible, slowly"; optimistic versus current
   science on fast reversal, chosen so late-game recovery is visible on the gauge.
5. **Warming starts at +1.30 °C in 2030** — consistent with observed ~1.2–1.4 °C.
6. **Loss at exactly +2.0 °C; warning at +1.5 °C.** Paris Agreement framing (see
   Concept.md sources); in-run the thresholds are hard lines, not probability bands.
7. **Three one-time feedback loops** (permafrost +2 E at 1.75; ocean sink −2 A at 1.90;
   Amazon −3 A after 3 mega fires) stand in for all tipping-point dynamics. Few, loud,
   permanent — chosen for readability over realism.
8. **Sink stress** −0.10/yr in Overshoot I, −0.25/yr in Overshoot II, floor 5 GtCO2e/yr.
   Invented values; calibrated so neglecting sinks for ~40 Overshoot years roughly halves
   them (as in Run B).

## Economy and Society

9. **One card per year, 71 turns.** The core readability constraint (golden rules 5–6);
   everything else is balanced around ~50–56 cards actually played per run.
10. **Income 100/yr baseline, +20 per ally.** Allies are the only income scaling — makes
    "being allied always beats being alone" arithmetically true (design pillar 3).
11. **Sector tech cap at 70% without a sufficiency card.** The load-bearing gameplay
    encoding of IPCC demand-side mitigation: supply-side technology alone cannot fully
    decarbonize. The exact value (70) is tuned so a pure tech rush plateaus at ≈ +4
    GtCO2e/yr net — close enough to taste victory, structurally unable to reach it.
12. **10% residual emissions at full transition** (5 Gt total) — keeps "neutrality is a
    balance" true: even a perfect transition needs sinks ≥ 5.
13. **Happiness drift = co-benefits (up to +1.5/yr at full transition) − Overshoot stress
    (0.5/1.0).** Asserts that a transformed world is a *nicer* world (EAT-Lancet health
    co-benefits, active mobility). The claim is scientifically grounded; the numbers are
    pure tuning for the dip-then-bloom arc.
14. **Income penalties ×0.75 below 40 H, ×0.5 below 25 H** and the social-crisis formula
    are invented; they exist to make social collapse systemic rather than an instant loss
    (see resilience reconciliation in `../Phase_0/04_Simulation_Metric_Dictionary.md`).
15. **Resilience R = 0.4·H + adaptation, damage ×(1 − R/200).** Linear and memoryless;
    max builds halve event damage. Chosen for one-line explainability.

## Structure and Method

16. **Events roll independently per year** — no clustering, no compound-disaster modeling.
17. **Influence is uncapped** in the paper model (winners bank 80–230 by 2100); a cap
    (e.g. 100) is likely in implementation.
18. **No late-game money sink**: winners hoard 6 000+ funds after full transition.
    Accepted for Phase 1; flagged as Risk #5 with candidate sinks listed.
19. **Baseline runs assume zero Knowledge nodes** (true first run). Knowledge modifiers
    in `04_Policy_Effect_Matrix.md` are specified but unsimulated; re-run the paper model
    with nodes before implementing the tree's prices.
20. **Sample runs use RNG seed 2030** and scripted strategies; other seeds shift event
    timing but not the structural outcomes (caps, feedback thresholds, and formulas are
    deterministic). Run B could end as "survived, not neutral" instead of a +2.0 °C loss
    on a kinder seed — both are losses, same lesson.
21. **Procedural world generation is not yet in the balance model**; sample runs use the
    canonical starting values above. Seeded variation (±10–20% on starts) is the first
    thing to add once the corridor bands prove stable.
