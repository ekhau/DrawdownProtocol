# Phase 0 - Deliverable 01: Design Brief

## Document Status
- Project: The Drawdown Protocol
- Phase: 0 (Concept and Design Foundation)
- Deliverable ID: D0.1
- Version: 1.0
- Date: 2026-07-24
- Status: Draft for team alignment

## 1. Purpose
This deliverable defines the core intent of the prototype, the player experience target, and the non-negotiable constraints for production. It is the reference document for design, engineering, and balancing decisions in Phases 1 to 3.

## 2. Elevator Pitch
You are an AI simulation tasked by future humanity to find the optimal path through the 21st-century climate crisis. In a 2D isometric rogue-lite, you manage a procedurally generated bioregion, choose one policy per year, and attempt to reach 2100 before resilience collapses or warming exceeds critical limits.

## 3. Player Fantasy
The player should feel like a strategic systems architect under pressure, transforming a fragile industrial landscape into a resilient, sober, and thriving region through long-term planning.

### Emotional Arc
- Early run: urgency and uncertainty.
- Mid run: tension, trade-offs, and risk management.
- Late run: either systemic recovery and hope, or cascade failure.

## 4. Target Audience
### Primary
- Strategy and simulation players who enjoy systems with meaningful trade-offs.
- Players interested in climate futures, policy design, and long-term planning.

### Secondary
- Educators, students, and communities exploring climate transition scenarios.

### Accessibility and Session Goal
- Playable run duration: 10 to 20 minutes.
- Rules understandable within first 2 turns.
- Input complexity kept low: space, mouse, and one panel toggle.

## 5. Prototype Scope Statement
### In Scope (MVP)
- One complete run from 2030 to 2100.
- One-policy-per-year decision loop.
- Isometric board with deterministic generation.
- Core metrics: resilience, emissions, sinks, warming contribution.
- Events and feedback loops tied to thresholds.
- Meta-progression with Insight Points and at least one unlock path.

### Out of Scope (Phase 0 to Prototype)
- Multiplayer and online systems.
- Branching narrative campaign.
- Full macro-economic simulation.
- High-fidelity art production pass.

## 6. Core Gameplay Contract
### Yearly Loop
1. Player reviews year and metrics.
2. Player chooses exactly one policy card.
3. Simulation resolves yearly effects.
4. Event and feedback checks execute.
5. HUD and log communicate outcomes.
6. Win/loss check executes.
7. Year advances.

### Win/Loss Conditions
- Win: year >= 2100.
- Loss: resilience <= 0.
- Loss: warming contribution >= 2.0 C.

## 7. Design Pillars
1. Systemic clarity over hidden complexity.
2. Meaningful trade-offs over obvious optimal choices.
3. Consequence visibility over black-box outcomes.
4. Replayability through variation, not content bloat.
5. Hopeful transformation through strategic sobriety.

## 8. Experience and Aesthetic Direction
- Visual direction: solarpunk transition from gray extraction landscape to lush resilient infrastructure.
- Readability priority: state changes must be visible in board visuals and HUD metrics.
- Tone: serious but empowering; avoid nihilism.

## 9. Quantitative Targets (Prototype)
- First-time win rate target after tutorial understanding: 25% to 45%.
- Dominant strategy tolerance: no single policy chain should produce near-certain wins.
- Event explainability: every major state shift must produce a visible log explanation.
- Technical baseline: no crash or soft-lock in a full run.

## 10. Production Constraints
- Engine: Godot 4.8.
- Data-driven balancing via JSON (policies, events, biomes).
- Deterministic randomness through RandomNumberGenerator seed.
- Typed GDScript in core simulation code.
- Preserve one-policy-per-year and input contract (Space, H, mouse).

## 11. Deliverable Outputs for D0.1
This first deliverable is complete when the following artifacts exist:
- This design brief document.
- Confirmed list of win/loss rules.
- Confirmed MVP scope and explicit non-goals.
- Agreed design pillars to evaluate future feature requests.

## 12. Review Questions Before Phase 1
- Are the 3 core metrics sufficient, or is a fourth system required for meaningful decisions?
- Is the 10 to 20 minute run duration realistic with one decision per year?
- Do current pillars help reject low-value features quickly?
- Is the win/loss framing clear enough for first-time players without extra tutorial text?

## 13. Approval
- Design Lead: Pending
- Gameplay Engineering: Pending
- Production: Pending

Once approved, this document becomes the baseline reference for Phase 1 (Paper Prototype and Balance Skeleton).
