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

9. **Three crises and up to five cards per year, 71 turns.** The turn is a bounded
   tactical puzzle (golden rules 5–6): the crisis draw is the pressure, resources are the
   real limit, and the 5-card cap only guards the ceiling. Everything is balanced around
   ~200–300 cards actually played per winning run (~2–3 answers plus ~1 transformation
   per year), with the old ~50-card transformation pacing preserved by halving per-card
   progress amounts.
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
14. **Income penalties ×0.75 below 40 H, ×0.5 below 25 H** and the social-crisis draw
    modifiers (×3 below 40 H, ×0.5 with media)
    are invented; they exist to make social collapse systemic rather than an instant loss
    (see resilience reconciliation in `../Phase_0/04_Simulation_Metric_Dictionary.md`).
15. **Resilience R = 0.4·H + adaptation, damage ×(1 − R/200).** Linear and memoryless;
    max builds halve event damage. Chosen for one-line explainability.

## Structure and Method

16. **Exactly three events per year, drawn without replacement** from a weighted deck —
    guaranteed presence replaces the old independent per-event rolls; escalation moves
    into the draw weights. No clustering beyond the draw, no compound-disaster modeling.
17. **Influence is uncapped** (winners bank 80–230 by 2100); a cap (e.g. 100) is likely
    in a later pass.
18. **No late-game money sink**: the Safe archetype still hoards ~5 000–6 500 after full
    transition (projects absorb only part of the surplus). Accepted; flagged as Risk #5.
19. **Baseline runs assume zero Knowledge nodes** (true first run). Knowledge modifiers
    in `04_Policy_Effect_Matrix.md` are specified but unsimulated in the corridors;
    re-check the batch with nodes before repricing the tree.
20. **Fixture runs use RNG seed 2030** and scripted strategies; other seeds shift crisis
    timing but not the structural outcomes (caps, feedback thresholds, and formulas are
    deterministic). Risky loses between 2055 and 2068 across the 20-seed batch — always
    a +2.0 °C breach, same lesson.
21. **Seeded start variation (±10–20%)** is in the batch harness; the corridor bands in
    `05_Balance_Bands.md` are measured over 20 jittered seeds.
22. **Answered crises are fully contained** (no damage, rider forfeited) rather than
    partially mitigated — chosen for one-line readability. The response reward is priced
    below the avoided damage so answering is good but never free of tempo cost.
23. **Combos are deterministic tag algebra** — no RNG, no hidden synergies; the chain
    multiplier (+10%/step, ×2 cap, −1 decay) is the entire escalation model. Knowledge
    combo rewards pay first-fire-only so insight cannot be farmed.
24. **Projects are strictly positive commitments**: no mid-project payouts, one attempt
    per project per run, and a flat happiness/influence penalty for breaking one —
    modelling credibility, not contract law.
25. **Deck growth is condition-based, never time-based** (pillar: Every Timeline
    Teaches); the six unlock conditions are chosen so a competent first run meets 4–6
    of them.
