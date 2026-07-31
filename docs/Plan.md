# Roadmap: Design and Build a Simple 2D Isometric Rogue-lite Prototype

## 1. Prototype Goal
Build a playable Godot prototype where each run is a tight 15-turn race (one turn = five years, 2030 to 2100) against an automatically escalating Climate Clock: every turn deals three random events and a market of project cards, the player funds cards to answer crises, bend the world actors' emission curves, and chain combos, and the simulation can be won or lost in a clear and understandable way.

### Success Criteria
- A full run is 15 decision turns, playable in 10 to 20 minutes.
- The core loop is understandable within the first 2 turns; the Climate Clock is readable as THE adversary at a glance (current %, next-turn forecast, curve history).
- Win condition: global net emissions <= 0 (city + world actors - absorption) at ANY turn before the tipping point.
- Loss conditions: clock reaches 100% (+2.0 C), OR happiness reaches 0 (the city revolts), OR 2100 arrives still net-positive.
- Each turn follows: event draw (3, with on-draw spikes and conditional bonus-card injections) -> project market (4 offers, consumed when funded) -> resolution (ledger, clock, summits, world-actor advance).
- Summits every ~4 turns set targets announced in advance, with real rewards and penalties.
- Combos fire visibly most turns for a competent player; a strong engine turn cascades; at least one project completes in a typical winning run.
- At least three selectable city archetypes force different strategies; at least one is meta-locked.
- Both victory and defeat pay meta rewards; defeat ends with a post-mortem naming the pivotal turn.

## 2. Scope Definition (Keep It Simple)

### Must Have (Prototype MVP)
- Isometric tile board with clickable tiles.
- Year-based turn loop.
- Three random crises drawn per year; policy cards (multi-play, resource-bound) as the tool to answer them.
- Card combos with an escalating chain, long-term projects, and play-driven deck growth.
- Resource and climate simulation (resilience, emissions, warming).
- Feedback loops and opportunity riders.
- Win and loss states.
- Basic meta-progression currency and unlock screen.
- Simple UI for metrics, crises, logs, and available actions.

### Nice to Have (If Time Permits)
- Multiple biome templates.
- Better art pass and transition effects.
- Accessibility options (font scale, color-safe palette).
- Save and load current run.

### Out of Scope for First Prototype
- Multiplayer.
- Advanced narrative campaign.
- Full economy simulation.
- Complex pathfinding agents on the board.

## 3. Core Gameplay Loop Specification
Each turn equals five years; a run is exactly 15 turns (2030, 2035, ... 2100).

1. Show turn/year and world metrics; apply income and project upkeep (projects run 3 turns).
2. Draw 3 random events (crises and opportunities) from the weighted deck. On-draw effects strike immediately (a record heat wave bakes in +1 Gt/yr unless answered this turn); qualifying events inject bonus cards into the market, gated by resources (heat wave -> Heatwave Response Plan if happiness >= 40).
3. Deal the project market: 4 weighted offers from the player's pool (archetype leans included), guaranteed to contain at least one card that answers an open event.
4. Player funds offers (up to 5 plays; each offer is consumed), bound by Money / Influence / Happiness costs; risk cards roll their printed odds; card tags answer matching crises immediately; completed tag sets fire combos with the chain multiplier; projects may be launched or abandoned.
5. Resolve the turn: sinks mature and strain, the global ledger closes (city sectors + world actors - absorption), the Climate Clock ticks, happiness drifts.
6. Resolve unanswered crises (damage plus opportunity riders), the turn's summit target if scheduled (reward or penalty), and climate feedbacks.
7. World actors advance their emission curves (trend, damped 0.2 per ally, cut by treaties and funded transitions).
8. Update HUD (clock, ledger, world blocs, next summit), crisis panel, and turn log.
9. Check end states: tipping point / revolt / neutrality-win / 2100 timeout. Advance 5 years.

## 4. Technical Architecture (Godot 4)

### Suggested Scene and Script Structure
- Main scene: bootstraps run, input handling, and overlays.
- BoardView: draws isometric grid and tile state changes.
- RunState: single source of truth for simulation values.
- HUD: year, resilience, warming, emissions, policy status.
- ParadigmHub: meta-progression unlock panel.

### Data-Driven Files
- biomes.json: tile distributions and biome modifiers.
- cards.json: policy effects, costs (money/influence/happiness), rewards, tags, market weights, risk odds, codex entries, unlock/meta-unlock requirements.
- events.json: crisis deck (draw weights, damages, response tags, riders, on-draw spikes, bonus-card links) and feedback triggers.
- combos.json: combo tag sets and payoffs.
- projects.json: long-term project upkeep (per turn, 3 turns), completion payoffs, penalties.
- world_actors.json: the world's blocs - emissions, trend, floor.
- city_archetypes.json: selectable starting cities - stat modifiers, market leans, unlock gates.
- summits.json: the COP calendar - turn, target, reward, penalty.

### Engineering Rules for Prototype
- Keep simulation deterministic with RandomNumberGenerator seed.
- Keep model updates inside RunState methods.
- Use signals for UI refresh instead of hard references when possible.
- Keep balance values in JSON, not hard-coded in multiple scripts.

## 5. Full Step-by-Step Roadmap with Deliverables

## Phase 0: Concept and Design Foundation (1 to 2 days)
### Tasks
- Write one-page design brief: fantasy, player goals, fail/win states.
- Define 3 to 5 design pillars (clarity, tension, replayability, hope).
- Lock prototype constraints: duration, number of systems, content counts.
- Define exact metrics for simulation (resilience, warming, emissions, sinks).

### Deliverables (Detailed)
- Design brief document with elevator pitch, player fantasy, and target audience.
- Design pillars sheet with practical examples of what to include and what to reject.
- MVP scope table split into must-have, nice-to-have, and out-of-scope items.
- Simulation metric dictionary that defines every variable, unit, and expected range.
- High-level system diagram showing board, simulation loop, events, and progression links.
- Risk register with the top production and design risks plus mitigation actions.

### Done Criteria
- Team can explain the game in 30 seconds.
- Every planned feature maps to one design pillar.

## Phase 1: Paper Prototype and Balance Skeleton (1 to 2 days)
### Tasks
- Simulate 10 turns on paper or spreadsheet.
- Test policy effects and event probabilities.
- Ensure there is at least one viable winning strategy and multiple losing paths.
- Check pacing: early game learning, mid game pressure, late game climax.

### Deliverables (Detailed)
- Balance spreadsheet with per-turn formulas for emissions, sinks, resilience, and warming.
- Three sample runs (safe, risky, mixed strategy) with timeline notes and outcomes.
- Baseline probability table for events and feedback loops by warming thresholds.
- First-pass policy effect matrix showing short-term and long-term impacts.
- Target balance bands by decade (resilience and warming expected intervals).
- Written assumptions list so balancing changes can be tracked and challenged later.

### Done Criteria
- Numbers are stable enough to implement without guessing.

## Phase 2: Project Setup and Infrastructure (1 day)
### Tasks
- Create base folders: scenes, scripts, data, art, audio.
- Configure input actions (Space for next year, H for hub toggle, mouse select).
- Add autoload singleton for meta-progression.
- Add debug overlay toggle for simulation values.

### Deliverables (Detailed)
- Clean project folder structure with naming conventions documented.
- Input map configured and verified for keyboard and mouse controls.
- Autoload singleton connected and callable from the main runtime flow.
- Base scene that loads board, HUD, and progression panel placeholders.
- Debug panel that can display seed, year, resilience, and warming in real time.
- Startup and error checklist for script load order and missing references.

### Done Criteria
- Project launches with no script errors.
- Input actions trigger expected callbacks.

## Phase 3: Isometric Board and Tile Model (2 to 4 days)
### Tasks
- Implement tile data model (type, risk level, productivity, restoration status).
- Build isometric conversion helpers (grid <-> world coordinates).
- Render board and tile states.
- Add tile hover and click feedback.
- Add biome generation with seeded randomness.

### Deliverables (Detailed)
- Tile schema with typed fields for all board-relevant simulation attributes.
- Deterministic board generator with configurable seed input.
- Isometric board renderer that supports multiple tile visual states.
- Interaction layer for hover highlight, selection, and simple tile inspection.
- Biome presets with spawn distributions and terrain modifiers.
- Developer debug view showing tile coordinates, type, and active modifiers.

### Done Criteria
- Board generation is deterministic for a fixed seed.
- Tile interactions are visually clear and responsive.

## Phase 4: Core Simulation Engine (2 to 4 days)
### Tasks
- Implement RunState with typed fields and yearly tick method.
- Apply policy effects (instant and ongoing).
- Resolve annual emissions and sink updates.
- Update resilience and warming contribution from model outputs.
- Add win/loss checks at end of each turn.

### Deliverables (Detailed)
- Central RunState model with a complete end-of-year simulation pipeline.
- Policy effect resolver with clear stacking and duration rules.
- Annual climate calculation functions (emissions, sinks, net impact, warming delta).
- Resilience update logic that reflects both systemic pressure and adaptation gains.
- End-state evaluator for success and failure conditions with reason codes.
- Structured turn log output for debugging and future analytics.

### Done Criteria
- One turn advances all systems consistently.
- Win/loss conditions always evaluate correctly.

## Phase 5: Policy Cards, Crises, Combos and Projects (3 to 5 days)
### Tasks
- Load card definitions (costs, rewards, tags, unlocks) from JSON.
- Build the multi-play card UI with the per-year card cap and resource gating.
- Load the crisis deck, combos, projects, and feedback loops from JSON.
- Draw 3 crises per year with band-weighted randomness; match card tags to crisis responses.
- Fire combos on completed tag sets with the chain multiplier; charge and complete projects.

### Deliverables (Detailed)
- Card catalog data file with 20+ balanced policies plus unlockable cards.
- Card UI with costs, rewards, tags, effects, and blocked-state visibility.
- Crisis panel showing the year's three events, their threats, response tags, and live answered state.
- Crisis deck of ~10 drawable events plus 3 feedback loops; combo and project catalogs.
- Resolver applying answered-crisis containment, unanswered damage with riders, combo payoffs, and project lifecycles.
- Crisis, combo, project, and card messages integrated into the run log and HUD.

### Done Criteria
- Exactly 3 events drawn per turn and 4 market offers dealt; every funded card resolves against crises and combos deterministically.
- Crisis outcomes, combos, summit verdicts, and project events are understandable and visible in logs.

## Phase 6: Meta-Progression Loop (2 to 3 days)
### Tasks
- Award Insight Points at run end.
- Build Paradigm Hub unlock tree (small first pass).
- Save unlocked paradigms and apply bonuses to new runs.
- Display active meta modifiers at run start.

### Deliverables (Detailed)
- Insight Points reward model tied to run outcome and performance.
- Paradigm Hub data and UI with unlock costs, dependencies, and effects.
- Persistent save layer for unlocked paradigms and accumulated points.
- Run initialization hook that applies selected meta bonuses consistently.
- Meta summary panel showing active modifiers before the first turn.
- Validation checklist for compatibility between progression data and run fields.

### Done Criteria
- Permanent unlocks persist between sessions.
- New run reflects selected meta bonuses.

## Phase 7: UX, Feedback, and Polish (2 to 4 days)
### Tasks
- Improve HUD readability and hierarchy.
- Add event popups, tooltips, and turn summary panel.
- Add screen shake, color shifts, or particle cues for major events.
- Add minimal audio feedback (policy confirm, event alert, win/loss stingers).
- Add onboarding hints for first run.

### Deliverables (Detailed)
- HUD polish pass with visual hierarchy for core metrics and warnings.
- Tooltip and glossary copy for key terms and simulation values.
- Event popup system and yearly summary panel for clear consequence communication.
- Feedback effects package (visual cues, transitions, and minimal audio set).
- First-run onboarding sequence that teaches controls and first choices.
- Accessibility pass for readability (contrast, text size baseline, color clarity).

### Done Criteria
- New player can complete at least 5 turns without confusion.

## Phase 8: Balancing and Playtest Iteration (3 to 6 days)
### Tasks
- Run 20 to 30 automated or manual simulation sessions.
- Track win rate, average failure year, and most picked policies.
- Identify dominant strategies and dead choices.
- Tune JSON values only, then retest.
- Validate difficulty curve and replayability.

### Deliverables (Detailed)
- Playtest protocol describing scenario setup, goals, and data capture method.
- Session dataset for 20 to 30 runs with comparable conditions.
- Balance report with win rate, failure causes, and policy pick-rate analysis.
- Tuning patch notes that record every changed value and design rationale.
- Updated data files for policies and events after each tuning pass.
- Priority list of unresolved balance issues for the next milestone.

### Done Criteria
- Win rate sits in target band (example 25 percent to 45 percent for first-time players).
- No single policy path auto-wins every run.

## Phase 9: Packaging and Demo Delivery (1 to 2 days)
### Tasks
- Add title screen, controls panel, and version label.
- Build export preset for desktop.
- Prepare short demo script (2 to 3 minutes).
- Capture gameplay clips and screenshots.

### Deliverables (Detailed)
- Desktop build package with versioned executable and required runtime files.
- Title screen and controls screen integrated into the launch flow.
- Short presenter script for a 2 to 3 minute guided demo run.
- Screenshot and gameplay capture pack for documentation and sharing.
- Internal release notes with known issues, severity, and workarounds.
- Smoke test checklist completed on the packaged build.

### Done Criteria
- Prototype can be launched and played outside editor with no blockers.

## 6. Suggested 6-Week Timeline
- Week 1: Phases 0 to 2.
- Week 2: Phase 3.
- Week 3: Phase 4.
- Week 4: Phase 5.
- Week 5: Phases 6 and 7.
- Week 6: Phases 8 and 9.

## 7. Quality Gates and Validation Checklist
Run this checklist before calling the prototype complete:

- Exactly 3 events are drawn every turn; the market deals 4 offers (plus event bonus injections); the play cap (5 per turn) is never exceeded; funded offers leave the market.
- Answered crises never damage (and clear their on-draw spikes); unanswered crises always leave a readable trace.
- Combos fire at most once per combo per turn and the chain multiplier matches the HUD.
- Projects charge every turn, complete after 3 paid turns, and penalize abandonment.
- The turn always advances 5 years with Space input (double-Space confirm on an empty turn).
- Hub (H) and Codex (C) toggles work consistently.
- Loss triggers when the clock reaches 100% (+2.0 C) or happiness reaches 0 (revolt).
- Win triggers the moment global net emissions <= 0, any turn; 2100 net-positive is the timeout loss.
- Summits at turns 4/8/12 announce in advance, evaluate that turn's net, and pay or penalize.
- World actors advance every turn; treaties, funded transitions, and allies verifiably bend their curves.
- HUD values (clock %, forecast, city+world ledger) match simulation state after every turn.
- The turn log explains what changed and why; the run-end post-mortem names a pivotal turn.
- Meta unlocks (knowledge, defeat-lesson cards, codex entries, archetype selection) persist and apply to new runs.
- No crash, freeze, or soft-lock during a full run.

## 8. Risks and Mitigations
- Risk: Scope creep from too many systems.
  Mitigation: lock MVP and push extras to backlog.
- Risk: Balance feels random instead of strategic.
  Mitigation: make formulas visible and tune via JSON with repeatable seeds.
- Risk: UI overload from too many metrics.
  Mitigation: show only key stats by default and expose details in tooltips.

## 9. Definition of Done (Prototype)
The prototype is done when:
- A complete 15-turn run can be played from 2030 to 2100 (or won early by bending the curve).
- The player has meaningful choices every turn: which crises to answer, which offers to fund, home vs world.
- Runs can be won and lost through transparent systems, and every defeat names its pivotal turn.
- Meta-progression (Knowledge, defeat lessons, the Codex, the locked archetype) gives a clear reason to play again.
- Team can gather useful feedback on fun, clarity, and balance.
