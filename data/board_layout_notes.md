# Board Layout — Design Notes (Tier A dashboard board)

Companion to `data/board_layout.json` and `data/board_layout_mockup.svg`.
Spec sources: `docs/Phase_3/01_World_Model_And_Tile_Schema.md`,
`02_Procedural_Generation_Spec.md`, `03_Board_Rendering_Spec.md`,
`04_Interaction_Spec.md`.

## Silhouette logic — a world evoked, not simulated

Twelve slots in four staggered bands, reading as a stylized world-map
silhouette (soft landmass shapes in the mockup are pure decoration):

| Band | Slots (west → east) | Evokes |
|---|---|---|
| `north` (y ≈ 192–224) | region_01 · region_02 · region_03 | The old industrial boreal north — wide, heavy, first thing the eye crosses |
| `mid` (y ≈ 376–408) | region_04 · region_00 · region_05 · region_06 | Temperate mid-latitudes; **region_00 (player home) sits center-west** — the coalition at the heart of the world, on the main sight line |
| `south` (y ≈ 584–616) | region_07 · region_08 · region_09 | Tropic south — forest basin west, agrarian center/east |
| `ocean` (y ≈ 752) | region_10 · region_11 | Island nations adrift in the southern ocean — visually isolated on purpose (first victims, first allies) |

Rows are deliberately staggered ±32 px so the board reads as geography, not a
spreadsheet grid. The `band` field is exposed for view-side flourishes
(staggered intro reveal north→south, era-tint ripples); it has no gameplay
meaning.

**Slots are archetype-agnostic.** Archetypes are rolled per seed
(`02_Procedural_Generation_Spec.md`), so a slot cannot promise "Forest
Commons". The only stable fact is that **region_00 is the player home**
(procgen step 1 assigns it first, index 0). The mockup shows *one example
seed* (1 home, 3 Industrial Heartland, 2 Coastal Metropolis, 2 Agrarian
Basin, 1 Forest Commons, 1 Arid Belt, 2 Island Nations — within all preset
min/max counts); names like "Korvatna" are procgen-style placeholders.
Recommendation: the view should still resolve the home panel via
`RegionData.is_player_home`, not by slot id, so the layout never encodes a
sim rule.

## Panel size and spacing — why 208 × 128

- Fits the full RegionPanel content spec at comfortable sizes: 17 px name,
  archetype icon 24 px, two 10 px mini-bars with value text, a scar row and
  four transition-leaf pips — nothing under ~9 px at 1080p design res.
- The whole panel is the hover hit rect (Control-based per
  `04_Interaction_Spec.md`) — 208×128 is a generous target; slot spacing
  gives ≥ 144 px of clear air between same-band neighbours and ≥ 16 px
  diagonal clearance even at the 1.02 hover scale plus selection outline
  (checked programmatically, no overlap at a 1.06× envelope).
- Ally ring (+6 px) and home double ring (+10 px) draw *outside* the face and
  still never touch a neighbour or a HUD zone.
- Tooltips: every slot carries a `tooltip_side` pointing at guaranteed free
  space, so the 0.3 s tooltip never clips a screen edge, the right dock, or
  the card tray.

## Screen budget (design resolution 1920 × 1080)

- Top bar 1920×96 — pillars, warming gauge, year (HUD).
- Right dock 400×768 — Region Inspector (opens on select, per interaction
  spec) + turn log. Reserving it permanently means selection never occludes
  the board.
- Card tray 1920×216 — the hand.
- Board area 1472×736 with 16–24 px breathing gaps — panels occupy ~29% of
  it; the rest is calm ground where the era tint will be most visible.

## How the JSON maps to Godot

- Project settings: `display/window/size` 1920×1080, stretch mode
  `canvas_items`, aspect `keep`. Then every `pos` is a valid `Node2D.position`
  at any window size — **no runtime scaling math** (this is the documented
  scaling rule).
- `BoardView._ready()`:
  `JSON.parse_string(FileAccess.get_file_as_string("res://data/board_layout.json"))`,
  then for each entry of `slots` (in array order — it is already back-to-front
  draw order) instantiate `RegionPanel.tscn` under `RegionPanels`, set
  `position = Vector2(pos.x, pos.y)` (**pos is the panel CENTER**,
  `panel_origin: "center"` — build the panel scene around its origin so
  hover-scale and event-flash tweens pivot correctly), and register it in a
  `Dictionary[StringName, RegionPanel]` keyed by `region_id` for signal
  routing (`event_struck`, `ally_changed`).
- `hud_reserved` is an informative contract (HUD controls anchor themselves);
  `decor_arcs` is optional cosmetics the view may draw as faint dashed curves
  — **never** adjacency.
- Verified headless with the project's Godot build: the file parses and all
  invariants hold (12 unique ids `region_00..region_11`, every panel rect
  inside `board_area`).

## Color decisions (mockup, feeds the future Theme)

Mid-transition, era-neutral: ground `#575c55→#71766d`, panel face anchored on
the ramp midpoint `#d8d8d0`, tinted toward green by transition level. State
hues were run through a CVD validator, not eyeballed: emissions `#9c3b24`
(dark rust) vs absorption `#79a94a` (light leaf) are separated by *lightness*,
not hue alone (deutan ΔE 18.9 — a plain red/green pair fails at ΔE 4.8);
flood `#33689c`, ally gold `#d9a441`, era ramp `#8f8f87 / #d8d8d0 / #f2f7e8`
per the rendering spec. Everything is double-encoded (caret/leaf glyphs on
bars, flame/wave scar shapes, leaf-pip counts beside face tint, badge shapes
on rings), and tooltip + inspector repeat all values as text — color is never
the only channel. The green bar sits below 3:1 against the pale face, which
is why bars get a recessed dark track and glyphs (relief per the
accessibility rule).

## Deliberately left out

- **No geography simulation** — no adjacency, distances, borders, or travel;
  `decor_arcs` are set dressing and safe to delete.
- No per-slot archetype, name, or any sim value — the layout is pure
  screen-space data; all state arrives via `YearReport` signals.
- No percentage/anchor positions — plain pixels plus the stretch rule.
- No Tier B hooks — the home diorama (if it ships) docks into the right-dock
  column or replaces the inspector, a Phase-later decision.

## Open questions for the main conversation

1. **HUD budget:** top 96 px / right 400 px / bottom 216 px is my proposal;
   Phase 5 card presentation may want a taller tray — if so, shrink
   `board_area` and scale band y-values, the slot *shape* survives.
2. Should `decor_arcs` ship at all, or does even cosmetic connectivity
   over-suggest geography?
3. Ally ring at cap 6: with half the world ringed gold, consider a subtle
   coalition tint on the ground under allied bands (view-only idea).
