# Board Rendering Spec — The Drawdown Protocol (Phase 3)

Two rendering tiers over one world model. Tier A ships with the MVP; Tier B is the
nice-to-have isometric layer from the MVP scope table, specified now so its pipeline
(atlas layout, stage rules, scene seams) is settled before any art is commissioned
(golden rule 15).

## Architecture: sim renders nothing, views own nothing

```
Main (Node)
├── Sim (Node)                    # owns RunState + WorldGen; headless-capable
├── BoardView (Node2D)            # Tier A dashboard board
│   ├── RegionPanels (Node2D)     #   12 RegionPanel instances at layout slots
│   ├── FXLayer (Node2D)          #   pooled event flashes / scar pops
│   └── EraModulate (CanvasModulate)  # world-mood tint
├── HUD (CanvasLayer/Control)     # pillars, warming gauge, cards, log
├── KnowledgeHub (Control)        # hidden; H toggles
└── DebugOverlay (CanvasLayer)    # F3; see 05_Debug_View_Spec.md
```

Signals up, calls down. The sim emits; views subscribe and read:

```gdscript
# on Sim
signal year_advanced(report: YearReport)      # all deltas of the resolved year
signal event_struck(event_id: StringName, region_id: StringName, opportunity: StringName)
signal warming_band_changed(band: int)        # 0 stable / 1 Overshoot I / 2 Overshoot II
signal ally_changed(region_id: StringName, is_ally: bool)
signal run_ended(outcome: StringName, knowledge_points: int)
```

`YearReport` is a plain `RefCounted` snapshot (year, T, E, A, N, M, H, I, allies, log
lines) so views never reach into live sim state mid-tick.

## Tier A — dashboard board (MVP)

A stylized world: 12 `RegionPanel` scenes at fixed layout slots (positions in
`data/board_layout.json`, roughly a world-map silhouette; no geography simulation).

Each `RegionPanel` (a small `Node2D` + `Control` label block) shows:

| Element | Source | Notes |
|---|---|---|
| Region name + archetype icon | `RegionData` | Icon placeholder art per archetype |
| Emissions vs absorption mini-bar | derived region values (01 spec) | Red vs green bar pair — the region's carbon story at a glance |
| Ally ring | `ally_state` | Gold ring ALLY, dim NEUTRAL, distinct HOME badge |
| Scar icons (≤ 3 shown) | `scars` | Burned / flooded pips with year tooltip |
| Transition glow | global sector progress mirror | Panel background lerps grey→green as its dominant sector transitions |

### Visual states and the era tint

The grey-to-solarpunk arc, delivered cheaply (Risk #9 mitigation) through color, not art:

- `EraModulate.color` lerps along a ramp keyed to **average sector progress**:
  smog `#8f8f87` (0%) → neutral `#d8d8d0` (50%) → warm bright `#f2f7e8` (100%).
- **Overshoot vignette**: at `warming_band_changed`, tween a screen-edge vignette
  (band 1 faint amber, band 2 red); it reads as climate pressure without a single number.
- Event flash: targeted panel pulses (Tween on modulate + one pooled particle burst);
  opportunity riders flash green after the damage flash — crisis, then door (pillar 2).
- All state colors double-encoded (shape/icon + color) for color-blind safety.

Panels update only on signals — no per-frame polling. Full board refresh from a
`YearReport` must complete in one frame (12 panels, trivial budget).

## Tier B — isometric layer (nice-to-have, spec frozen)

**Scope status: nice-to-have per `../Phase_0/03_MVP_Scope.md` — build only after the MVP
loop is validated fun.** First increment recommendation: a single **home-region diorama**
docked beside the board (one 12×12 grid), not a whole-world tile map — 90% of the
transformation feeling for 10% of the art.

- **Node:** one `TileMapLayer` (Godot 4.3+) per diorama, diamond-down isometric,
  tile size 64×32, `y_sort_enabled = true` for future prop sprites.
- **Atlas layout:** one row per terrain type (URBAN, INDUSTRIAL, FIELD, FOREST, WATER,
  COAST), one column per stage 0–3, plus 2 scar overlay tiles (BURNED, FLOODED) drawn on
  a second `TileMapLayer` above. Art variants via alternative tiles keyed by
  `variant mod alternatives`.
- **Data flow:** on `year_advanced`, recompute each `TileVisual.stage` (threshold rule in
  `02_Procedural_Generation_Spec.md`) and call `set_cell()` only for changed cells;
  stage-up cells get a 0.3 s Tween pop and a leaf/spark particle. Expected changed cells
  per year ≈ 5–15 — no batching concerns.
- **Coordinates:** `local_to_map()` / `map_to_local()` for hover; no custom math.
- **Scars:** fire/flood on the home region set scar overlays on 3–6 tiles picked with
  `rng_tiles` (stream 3 — visual randomness must not touch event stream); cleared when a
  restoration card matures ("rebuild better", visualized).

Rejected alternative: per-tile simulation (tile carbon values, per-tile policies) — it
contradicts the readable three-dial balance and the headless model (pillars 1, and the
"tiles render state" rule). If a future phase wants tile gameplay, it re-opens Phase 0.

## Performance notes

- Pool FX nodes at scene load (8 flashes, 8 particle bursts); never instantiate per event.
- `EraModulate` is one node; no per-panel shaders in MVP.
- The board is static geometry after `_ready()` — no allocation in the year path.
