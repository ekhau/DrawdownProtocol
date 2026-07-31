# Balancing Assumptions — The Drawdown Protocol (Phase 1)

Every deliberate simplification behind the balance model, written down so it can be
challenged and revised without archaeology (Plan.md Phase 1 deliverable; pillar 5 —
science drift is only acceptable when it is documented).

## Climate Model

1. **City-sphere emissions 50 GtCO2e/yr** (industry 20 / transport 15 / agro-economy 15,
   residual 10%). The "city" is a gameplay abstraction of a small actor with world-scale
   reach: its three sectors carry the whole home-transition argument, split stylized
   (real transport is ~15%, not 30%) to give them equal strategic weight.
2. **World actor blocs 30 GtCO2e/yr combined, drifting +1.6/turn** (Korvat 12 +0.6,
   Azuria 7 +0.2, Meridian 6 +0.35, Frontier 5 +0.45; floors totalling 5.5). The four
   blocs stand in for everyone-who-is-not-you. Total starting emissions (80) exceed
   real-world projections (~50–55) deliberately: the surplus IS the adversary — it makes
   the clock climb by default and makes diplomacy load-bearing rather than optional.
3. **Actor curves are linear with floors and no AI**: trend per turn, damped 0.2 per ally
   (steepest first), cut only by cards (DIP4 −6 Gt / trend −0.3; DIP5 trend −0.8).
   Modelling ambition, lock-in and JETP-style finance as three numbers per bloc — no
   opinion simulation (Risk #1).
4. **Starting absorption 20 GtCO2e/yr** ≈ the roughly half of emissions that land and
   ocean sinks currently take up. Treated as a stock the player can grow (restoration) or
   lose (fires, warming stress) — a gameplay abstraction of sink dynamics.
5. **Warming rate 0.0011 °C per Gt of positive net, per five-year turn.** Compression for
   pacing and a stand-in for non-CO2 forcing. Consequence: the remaining "budget" from
   +1.3 to +2.0 °C is ~636 Gt net — the right order of magnitude versus IPCC
   remaining-budget estimates, spent over at most 15 ticks.
6. **Cooling at 0.00028 °C/Gt (~4× slower than warming)** when net-negative, floor
   +1.20 °C. Encodes "overshoot is partly reversible, slowly" — though under the
   any-turn win rule, in-run cooling is mostly moot: the run ends at the drawdown moment.
7. **Warming starts at +1.30 °C in 2030** — consistent with observed ~1.2–1.4 °C — and
   the clock displays it as 30% of the +1.0→+2.0 °C track (`CLOCK_T_ZERO` = 1.0, chosen
   so the gauge starts with visible headroom already spent).
8. **Loss at exactly +2.0 °C; warning at +1.5 °C.** Paris Agreement framing (see
   Concept.md sources); in-run the thresholds are hard lines, not probability bands.
9. **Three one-time feedback loops** (permafrost +2 E at 1.75; ocean sink −2 A at 1.90;
   Amazon −3 A after 3 mega fires) stand in for all tipping-point dynamics. Few, loud,
   permanent — chosen for readability over realism.
10. **Sink stress** −0.5/turn in Overshoot I, −1.2/turn in Overshoot II, floor
    5 GtCO2e/yr. Invented values at the five-year scale; calibrated so neglecting sinks
    through a long Overshoot meaningfully erodes them without single-handedly deciding
    the run.

## Economy and Society

11. **One decision turn = five years; 15 turns.** The turn is a bounded tactical puzzle
    (golden rules 5–6): three events and a four-offer market are the pressure, resources
    are the real limit, and the 5-card cap only guards the ceiling. Everything is
    balanced around ~30–50 cards funded per winning run. Per-card progress (8–16%) and
    event damages (~×2) are scaled to the turn representing half a decade.
12. **The market (4 offers, weighted, without replacement) replaces the open pool.**
    Variance is a design feature (rate corridor, `05_Balance_Bands.md`); the guarantee
    rule (cheapest answering card swapped into the last slot when the deal ignores the
    turn's events) bounds worst-case frustration without removing the read.
13. **Income 250/turn baseline, +40 per ally.** Allies are the only income scaling —
    makes "being allied always beats being alone" arithmetically true (design pillar 3),
    reinforced by each ally damping world drift.
14. **Sector tech cap at 70% without a sufficiency card** — the load-bearing gameplay
    encoding of IPCC demand-side mitigation: supply-side technology alone cannot fully
    decarbonize. **10% residual at full transition** keeps "neutrality is a balance"
    true: even a perfect home transition needs sinks and world cuts.
15. **Happiness drift = co-benefits (up to +4/turn at full transition) − Overshoot stress
    (2/4 per turn).** Asserts that a transformed world is a *nicer* world (EAT-Lancet
    health co-benefits, active mobility). Stress at −4/turn in band 2 is deliberately
    strong enough that a late-century run must actively maintain consent.
16. **Income penalties ×0.75 below 40 H, ×0.5 below 25 H**, social-crisis draw modifiers
    (×3 below 40 H, ×0.5 with media), and **revolt at 0 happiness as an instant loss**
    are invented; they make social collapse systemic first and terminal only at the
    floor — one readable gauge per loss (see the reconciliation note in
    `../Phase_0/04_Simulation_Metric_Dictionary.md`).
17. **Resilience R = 0.4·H + adaptation, damage ×(1 − R/200).** Linear and memoryless;
    max builds halve event damage. Chosen for one-line explainability.
18. **Research bets (RND1 35%, RND2 50%) are the only RNG a card play can carry**, rolled
    on a dedicated stream with odds printed on the card and bounded downside (−4 H /
    nothing). Two cards only: push-your-luck is seasoning, not a build.

## Structure and Method

19. **Exactly three events per turn, drawn without replacement** from a weighted deck —
    guaranteed presence; escalation lives in the draw weights. Each drawn event stands
    for the period's defining disaster; no clustering beyond the draw, no
    compound-disaster modeling. On-draw spikes (heat wave +1.0 E, cleared by answering)
    are the only within-turn ledger coupling.
20. **Influence is uncapped**; a cap is likely in a later pass.
21. **Money hoarding is largely resolved** (winners bank ~1 000 by the drawdown turn, not
    ~6 500): summits, actor funding, three-turn project upkeep and bigger card costs
    absorb the old surplus. Note the inversion: the Risky line now dies **rich** — its
    binding constraint is consent, not cash. Risk #5 stays open but downgraded.
22. **Baseline runs assume zero Knowledge nodes and no city archetype** (true first run;
    headless/test default). Archetype multipliers and Knowledge modifiers are specified
    but unsimulated in the rate corridor; re-check the batch with them before repricing.
23. **Fixture runs use RNG seed 2030** with six split streams (world, events, tiles,
    names, market, risk) and scripted strategies. The corridor is a **rate** over 20
    seeds (risky 0%, safe ≥ 50%, mixed ≥ 40%): scripted lines are deliberately beatable
    by humans who read the market — variance is the roguelike, determinism is the test
    harness.
24. **Answered crises are fully contained** (no damage, rider forfeited, spike
    dissipated) rather than partially mitigated — chosen for one-line readability. The
    response reward (~×2 the yearly model, matching damages) stays priced below the
    avoided damage so answering is good but never free of tempo cost.
25. **Combos are deterministic tag algebra** — no RNG, no hidden synergies; the chain
    multiplier (+10%/step, ×2 cap, −1 decay on comboless turns) is the entire escalation
    model. Rewards ~+60% over the yearly model because a combo now spends market slots.
    Knowledge combo rewards pay first-fire-only so insight cannot be farmed.
26. **Projects are strictly positive three-turn commitments**: no mid-project payouts,
    one attempt per project per run, and a flat happiness/influence penalty for breaking
    one — modelling credibility, not contract law.
27. **Summits are hard thresholds on that turn's net, announced in advance** (turns
    4/8/12: 45/25/8), with both reward and penalty mandatory (validator S1–S3). They
    convert the 15-turn race into three legible deadlines; penalties never touch the
    clock itself.
28. **Deck growth is condition-based, never time-based** (pillar: Every Timeline
    Teaches), now on three tiers: run unlocks (deeds), meta unlocks (defeat lessons —
    LOSS_REVOLT ⇒ SOC4 forever), and event-injected bonus cards (HWP1). A competent
    first run meets 3–6 run-unlock conditions.
29. **Knowledge Points floor at 1** — even a turn-8 revolt pays the meta. Chosen so the
    Paradigm Hub always has motion after any run; the win bonus (+3) and decade term
    keep winning strictly better.
