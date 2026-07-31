# Implementation Plan — MVP

Companion to [02_MVP_Spec.md](02_MVP_Spec.md) (§5 architecture). Ordered so the riskiest playtest questions get answered earliest and every step ends runnable. Check items off as they land.

**Hold-firm rules:** UI scripts never mutate state (all mutation through `effects.apply()`); no card is ever special-cased in code (effect atoms only); the sim never touches the scene tree.

## Steps

- [x] **1. Skeleton + data pipeline.** `project.godot`, folder tree, the four JSON files (`config`, `cards`, `crises`, `combos`) with all numbers from the spec, and `catalog.gd` with aggressive validation — unknown atom type, bad sector id, missing field → loud failure naming file and entry. The validator is the compiler for JSON: first, not last.
- [x] **2. Sim core, headless.** `run_state.gd`, `effects.apply()`, `climate_calc.gd`, income. Proof: a do-nothing loop run via `godot --headless` loses in 2043 ± 1 — done criterion #2 passes before a single pixel exists.
- [x] **3. Turn manager + market.** Phase state machine (Crisis → Action → Income → Climate), shuffle / deal 3 / reroll / buy without replacement. Bot: "buy greedily left to right" — assert the outcome changes vs. do-nothing.
- [x] **4. Crisis deck + dilemma engine.** Draw from the 13-card deck, band scaling (A/B/C on money/support costs only, never perms), windfalls exempt, responses applied through `effects.apply()`. Bots: always-Pay / always-Absorb / always-Mortgage; assert always-Mortgage loses badly.
- [x] **5. Combos + eras.** `combo_checker` re-scans owned cards after every purchase; era gating filters `market.deal()`; `era_started` triggers the free refresh.
- [x] **6. Debug UI (ugly on purpose).** One VBox of Labels/Buttons wired to the five verbs and the signals. Game playable end-to-end; sanity-check the four playtest questions before investing in real UI.
- [x] **7. Real UI.** Thermometer hero element, sector panels sampling the active era's colormap (magma → viridis → parula), crisis/windfall modal, era banners with palette crossfade, turn log, post-mortem. Pure skin — replaces the debug scene, changes nothing underneath.
- [x] **8. Balance harness.** Headless script: N seeds × each bot, printing loss years / win rates against the §7 done criteria. Rebalancing = edit JSON → run harness → read table.
- [x] **9. Playtest pass.** Help overlay, softlock check (end-turn always enabled), juice on the thermometer only.

## Five-verb API (the only surface UI may call)

`new_run(seed)` · `choose_response(i)` · `buy_card(id)` · `reroll()` · `end_turn()`

## Signals (the only way UI learns anything)

`resources_changed` · `sector_changed` · `temperature_changed` · `phase_changed` · `combo_discovered` · `era_started` · `log_line` · `run_ended`
