# Debug and Developer View Spec — The Drawdown Protocol (Phase 3)

Golden rule 17: iteration speed multiplies output. The debug layer has two halves — an
in-game overlay (F3) and a headless batch harness — both reading the same sim signals,
so debugging never needs special sim builds.

## F3 overlay (CanvasLayer, monospace, updates on signals — never per frame)

### Section 1 — Run header
```
seed 184467440737  [click: copy]     year 2054   band OVERSHOOT-I
T 1.66  E 27.4  A 23.9  N +3.5      M 712  H 51  I 18  allies 2  R 35 (adapt 15)
```
- Seed click-to-copy; two buttons: **Restart same seed** · **Restart seed+1**.
  These three affordances are the whole determinism workflow: reproduce, then vary.

### Section 2 — Modifiers and pending state
- Flags: `media`, `window`, `fire_discount`, `flood_rebuild`.
- Feedback loops: `permafrost / ocean_weak / amazon` with trigger year or "armed at
  T≥1.75 / T≥1.90 / fires 2 of 3".
- `E_extra`, fires count, reforest queue as `[+0.3×2yr, +0.2×5yr]`.
- Sector line: `ind 57% (cap 70, no suff) | tra 42% (cap 100) | agr 48% (cap 100)`.

### Section 3 — World table (scrollable, from `region_hovered` highlight sync)
Per region: `id, name, archetype, ind/tra/agr/sink shares, tags, ally, scars`.
Hovering a board panel highlights its row (the only consumer of `region_hovered`).

### Section 4 — Log tail
Last 8 sim log lines verbatim (the same lines the player-facing log shows — if a debug
line has no player-facing equivalent, that is a readability bug, pillar 1).

### Dev commands row (buttons, debug builds only)
- **Autoplay: Safe / Risky / Mixed** — runs the Phase 1 scripted strategies to run end at
  max speed. This is the living regression harness: after any tuning change, one click
  answers "do the three sample runs still tell their stories?"
- **Advance 10 years** (autoplay pass-only).
- **Trigger event…** dropdown (heat/fire/flood/social on a chosen region) — visual and
  log testing only; goes through the normal event path so riders and scars fire.
- No "set warming" cheat: warping state bypasses the pipeline and produces states the
  sim could never reach; instead, autoplay to the state you need (keeps bugs honest).

## Headless batch harness

`godot --headless --script tools/batch_runs.gd -- --seeds 100 --strategy safe --csv out.csv`

- Runs N seeds × chosen strategy through the real Sim node (no UI instantiated).
- CSV columns: seed, outcome, loss_year, KP, then decade samples of T/N/M/H
  (the exact metrics of `../Phase_1/05_Balance_Bands.md`).
- Used by: Phase 3 done criteria (world-gen invariants, determinism), Assumption #21
  validation, and later Phase 8 balance passes (Plan.md's 20–30 session dataset,
  automated from day one).
- Exit code non-zero on any invariant violation — CI-friendly
  (`--headless` runs are already the project's test path).

## Implementation notes

- Overlay is one scene (`debug_overlay.tscn`), autoload-free; `Main` instantiates it in
  debug builds only (`OS.is_debug_build()`).
- Zero allocation on the year path: labels update from `YearReport` fields; the world
  table rebuilds only on run start.
- The overlay must function with Tier A alone (no tiles); when the Tier B diorama ships,
  add one line to Section 1: hovered tile `coord / terrain / stage / variant / scar`.
