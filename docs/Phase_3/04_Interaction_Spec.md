# Interaction Layer Spec — The Drawdown Protocol (Phase 3)

Hover, selection, and inspection over the Tier A board (and Tier B tiles when they ship).
Interaction is read-mostly: cards remain the only way to change the world — clicking the
board never mutates simulation state, with one flavor exception (DIP1 targeting, below).

## Input actions (consistent with Plan.md Phase 2)

| Action name | Binding | Effect |
|---|---|---|
| `advance_year` | Space | Resolve the turn — five years pass (blocked while a modal prompt or run-end screen is open; the action name is historical and stays `advance_year`) |
| `toggle_hub` | H | Open/close the Knowledge Hub (Plan.md's "Paradigm Hub" — renamed per Concept.md; the input action name stays `toggle_hub`) |
| `toggle_codex` | C | Open/close the codex (entries unlock permanently on a card's first play) |
| `toggle_tutorial` | F1 | Show/hide the tutorial panel |
| `select` | Mouse left | Select region / pick card / confirm prompt |
| `clear_selection` | Esc or Mouse right | Clear selection / cancel prompt |
| `toggle_debug` | F3 | Debug overlay (Plan.md Phase 2 lists the overlay; F3 is the assigned key) |

No other bindings in MVP. All seven are `InputMap` actions, never hardcoded keycodes.

## Region hover (Tier A)

- Hit area: panel rect (`Area2D` or Control `mouse_entered`; pick one and keep it —
  recommendation: Control-based panels for free focus/accessibility behavior).
- Immediate: highlight outline (1 px accent, plus scale 1.02 tween ≤ 0.1 s).
- After 0.3 s: tooltip with the region's full readout — name, archetype, tags,
  emissions vs absorption (derived values with formula source), ally status,
  alliance cost preview ("Form Alliance: 25 Influence + 50 Money") when neutral,
  scar history with years.
- Emits `region_hovered(region_id)` (consumed by DebugOverlay, nothing else in MVP).
- Rule: **no hover-only information** — everything in the tooltip also appears in the
  click inspector (accessibility, and controller-proofing for later).

## Selection and inspection

- LMB on a panel: `selected` state (persistent outline), opens the **Region Inspector**
  dock (right side): the tooltip content expanded, plus a "what can I do here?" line
  listing cards whose flavor relates to the region's dominant sector — informational
  only, cards stay global.
- Selection states: `none → hovered → selected`; `Esc`/RMB returns to `none`.
  Selecting another region moves selection (no multi-select).
- Space always resolves the turn regardless of selection — selection is never a
  turn-blocking mode (golden rule 8: feedback immediate, flow uninterrupted).

## The one targeting flow: Form Alliance (DIP1)

When the player plays DIP1, a **target prompt** opens: neutral regions pulse; LMB picks
which country becomes the ally; Esc cancels the card (no cost paid).

- **Balance impact: none.** Cost, ally count, and income follow
  `../Phase_1/01_Balance_Model.md` exactly; the choice decides only *which* panel gets
  the gold ring, which name the log celebrates, and which region's affinity flavor line
  plays. Rationale: "we allied with Korvatna" is the concept's diplomacy fantasy
  (pillar 3) at zero systemic cost; it also lays the UI seam for post-MVP diplomacy
  depth without amending the MVP scope table.
- While the prompt is open the game is modal: Space/H are blocked, HUD dims, prompt text
  states the cost. This is the only modal in the interaction layer.
- Ally loss (social crisis) needs no interaction: the sim picks the target
  (`02_Procedural_Generation_Spec.md`, event targeting) and the view animates the ring
  breaking.

## Tile interaction (Tier B, when the diorama ships)

- Hover via `local_to_map(get_local_mouse_position())`: tile cursor (iso diamond
  outline), tooltip with terrain, stage name ("Gridlocked / In transition / Thriving"),
  scar note and the year it happened.
- Click: no action in MVP+1 — tiles are scenery with names. Any tile-level verbs would
  re-open Phase 0 scope (stated in `03_Board_Rendering_Spec.md`).

## Feedback timing budget

| Interaction | Budget |
|---|---|
| Hover highlight | same frame |
| Tooltip | 0.3 s delay, then same frame |
| Selection / inspector | same frame open, content complete |
| Turn resolution → board settled | ≤ 0.8 s total animation, skippable by pressing Space again |

The double-Space skip still matters at 15 turns: a resolved turn carries five years of
change (ledger, clock tick, strikes, maybe a summit), so the animation earns its 0.8 s —
but a player replaying seeds must be able to blitz a run in seconds
(session shape: 10–20 min).
