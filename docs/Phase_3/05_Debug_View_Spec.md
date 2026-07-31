# Debug and Developer View Spec — The Drawdown Protocol (Phase 3)

Golden rule 17: iteration speed multiplies output. The debug layer has two halves — an
in-game overlay (F3) and a headless batch harness — both reading the same sim signals,
so debugging never needs special sim builds.

## F3 overlay (CanvasLayer, monospace, updates on signals — never per frame)

### Section 1 — Run header
```
seed 184467440737  [click: copy]   turn 6/15  year 2055   band OVERSHOOT-I   clock 66%
T 1.66  Ec 24.1  Ew 33.8  A 23.9  N +34.0    M 712  H 51  I 18  allies 2  R 35 (adapt 15)
```
- The ledger is split: `Ec` city sectors + extras, `Ew` world actor blocs — the two
  halves of the local-vs-global dilemma, side by side.
- Seed click-to-copy; two buttons: **Restart same seed** · **Restart seed+1**.
  These three affordances are the whole determinism workflow: reproduce, then vary.

### Section 2 — Modifiers and pending state
- Flags: `media`, `window`, `fire_discount`, `flood_rebuild`.
- Feedback loops: `permafrost / ocean_weak / amazon` with trigger year or "armed at
  T≥1.75 / T≥1.90 / fires 2 of 3".
- `E_extra` (with any un-answered on-draw spikes flagged), fires count, reforest queue
  as `[+1.0×2t, +0.8×3t]`.
- Sector line: `ind 57% (cap 70, no suff) | tra 42% (cap 100) | agr 48% (cap 100)`.
- Actors line: `korvat 13.8 (+0.6) | azuria 7.4 (+0.2) | meridian 6.7 (+0.35) |
  frontier 6.0 (+0.45)  damp -0.4 (2 allies)`.
- Market line: the 4 dealt offer ids, guarantee swap marked `*`, bonus injections `+`.
- Summit line: `next COP: Accord of 2065 (turn 8) net<=25 | stocktake_2045: met`.

### Section 3 — World table (scrollable, from `region_hovered` highlight sync)
Per region: `id, name, archetype, ind/tra/agr/sink shares, tags, ally, scars`.
Hovering a board panel highlights its row (the only consumer of `region_hovered`).

### Section 4 — Log tail
Last 8 sim log lines verbatim (the same lines the player-facing log shows — if a debug
line has no player-facing equivalent, that is a readability bug, pillar 1).

### Dev commands row (buttons, debug builds only)
- **Autoplay: Safe / Risky / Mixed** — runs the Phase 1 scripted strategies (Steady
  Shield / Moonshot Rush / Grand Alliance) to run end at max speed. This is the living
  regression harness: after any tuning change, one click answers "do the three sample
  runs still tell their stories?"
- **Advance 2 turns** (autoplay pass-only).
- **Trigger event…** dropdown (heat/fire/flood/social on a chosen region) — visual and
  log testing only; goes through the normal event path so riders and scars fire.
- No "set warming" cheat: warping state bypasses the pipeline and produces states the
  sim could never reach; instead, autoplay to the state you need (keeps bugs honest).

## Headless batch harness

`godot --headless --path src --script res://tools/batch_runs.gd -- --seeds 20 --strategy all --csv out.csv [--canonical] [--enforce]`

- Runs N seeds × chosen strategies through the real sim (no UI instantiated).
- CSV columns: seed, strategy, outcome, end_year, kp, then decade samples of T/N/M/H
  (the exact metrics of `../Phase_1/05_Balance_Bands.md`).
- Enforces the **rate corridor**: any risky win is a structural violation; safe must win
  ≥ 50% and mixed ≥ 40% of seeds. With `--enforce`, exit code is non-zero on any
  violation — CI-friendly (`--headless` runs are already the project's test path).
- Used by: Phase 3 done criteria (world-gen invariants, determinism), Assumption
  validation (`../Phase_1/06_Assumptions.md` #23), and later Phase 8 balance passes
  (Plan.md's 20–30 session dataset, automated from day one).

## Implementation notes

- Overlay is one scene (`debug_overlay.tscn`), autoload-free; `Main` instantiates it in
  debug builds only (`OS.is_debug_build()`).
- Zero allocation on the turn path: labels update from `TurnRecord` fields; the world
  table rebuilds only on run start.
- The overlay must function with Tier A alone (no tiles); when the Tier B diorama ships,
  add one line to Section 1: hovered tile `coord / terrain / stage / variant / scar`.
