# Procedural Generation Spec — The Drawdown Protocol (Phase 3)

Deterministic, seeded generation of the starting world. Parameter-level generation is the
MVP must-have (per `../Phase_0/03_MVP_Scope.md`); tile diorama generation is the Tier B
extension. Same seed ⇒ byte-identical world, on every platform, every session.

## Seed handling

One player-visible **run seed** (`int`, shown in HUD footer and debug view, copyable).
Independent sub-streams so adding or reordering one generator never perturbs another
(e.g. regenerating tiles must not shift event rolls):

```gdscript
class_name SeedUtil

# SplitMix64 - engine-version-proof, unlike relying on hash() stability.
static func sub_seed(base_seed: int, stream: int) -> int:
    var z: int = base_seed + stream * -0x61C8864680B583EB   # 0x9E3779B97F4A7C15 as signed
    z = (z ^ (z >> 30)) * -0x40A7B892E31B1A47               # 0xBF58476D1CE4E5B9
    z = (z ^ (z >> 27)) * -0x6B2FB644ECCEEE15               # 0x94D049BB133111EB
    return z ^ (z >> 31)
```

| Stream | Constant | Used by |
|---|---|---|
| 1 | `STREAM_WORLD` | Region archetypes, shares, jitter |
| 2 | `STREAM_EVENTS` | Yearly event rolls + event region targeting |
| 3 | `STREAM_TILES` | Tier B tile scatter and variants |
| 4 | `STREAM_NAMES` | Region name syllables |

Each consumer owns its own `RandomNumberGenerator` with `rng.seed = SeedUtil.sub_seed(run_seed, STREAM_X)`.
Iteration order is always fixed (region index 0..N−1, sectors in `[ind, tra, agr]` order) —
determinism dies in unordered dictionaries, so all draws loop over arrays.

## World generation algorithm (Tier A, step by step)

Region count **N = 12** (fixed for MVP): 1 player home + 11 others; with the ally cap of
6, half the world can join the coalition.

1. **Archetype assignment.** Draw archetypes from the preset table below with
   `rng_world.rand_weighted()`, respecting each preset's min/max count; assign the player
   home its fixed archetype first (index 0). Re-draw (bounded loop, ≤ 32 tries) if a
   maximum would be exceeded; fill unmet minimums last by replacing the most common type.
2. **Sector shares.** For each sector `s` in `[ind, tra, agr]`:
   `raw_r = preset_mult_s(archetype_r) × rng_world.randf_range(0.7, 1.3)` for each region
   in index order, then normalize: `share_s(r) = raw_r / Σ raw`. Guarantees Σ = 1 exactly.
3. **Sink shares.** Same normalized-draw pattern with `preset_sink_mult`.
4. **Tags.** From the preset (fixed per archetype, not rolled). Enforce world floors
   (≥ 2 coastal, ≥ 2 fire-eligible) — guaranteed by preset min counts, asserted anyway.
5. **Global start jitter** (the "parameter-level procgen" of the MVP scope): applied to
   the canonical Phase 1 starts, then clamped:
   `E` sector bases ×U(0.9, 1.1) each (total clamped 48–52) · `A_start` ×U(0.9, 1.1)
   (clamp 18–22) · `M_start` ×U(0.9, 1.1) · `H_start` +U(−3, +3).
   Warming always starts at 1.30 °C — the thresholds are facts of the world, never rolled.
6. **Names.** Syllable tables per archetype family via `rng_names` (2–3 syllables,
   capitalized; collision check with linear re-roll).

## Region archetype presets

| Archetype | Count (min–max) | Ind / Tra / Agr mult | Sink mult | Tags | Notes |
|---|---|---|---|---|---|
| Player Home ("the Signatories") | 1 | 0.4 / 0.4 / 0.4 | 0.6 | coastal | Small actor by design — your leverage is Influence, not size |
| Industrial Heartland | 2–3 | 2.5 / 1.2 / 0.8 | 0.5 | — | Big emitters; the transition's heavy lift |
| Coastal Metropolis | 2–3 | 1.2 / 2.0 / 0.6 | 0.4 | coastal | Flood-prone; transport-heavy |
| Agrarian Basin | 2–3 | 0.5 / 0.8 / 2.5 | 0.8 | arid | Heat- and fire-prone; agro lever |
| Forest Commons | 1–2 | 0.3 / 0.4 / 0.8 | 3.0 | forested | The world's lungs; mega-fire stakes |
| Arid Belt | 1–2 | 0.8 / 0.8 / 1.2 | 0.3 | arid | Heat-wave frontline |
| Island Nations | 1–2 | 0.3 / 0.6 / 0.6 | 0.7 | coastal | Alliance-affinity 1.2 flavor; first victims, first allies |

Multipliers are relative weights before normalization — the table is data
(`data/archetypes.json`), never code (golden rule 9).

## Event region targeting (runs on `STREAM_EVENTS`)

When the Phase 1 event system fires an event, pick a flavor target:
eligible = regions matching the tag requirement (flood → coastal; fire → forested or
arid; heat → all, arid weight ×2; social crisis → allies weight ×2, home eligible).
Weighted draw with `rng_events` **immediately after** the trigger roll (fixed consumption
order keeps the stream aligned). Effect magnitudes stay global per the balance model —
targeting decides only the log line, the panel flash, the scar, and which ally is lost on
a social crisis (the targeted ally if any, else highest-affinity ally).

## Tile diorama generation (Tier B)

Per region, a 12×12 grid; generated only when the isometric layer ships:

1. Build an exact terrain deck from the archetype's distribution row (e.g. Industrial
   Heartland: 25% urban, 35% industrial, 15% field, 15% forest, 10% water — counts
   rounded to sum 144), Fisher–Yates shuffle with `rng_tiles`, deal to cells row-major.
   Exact-count decks beat independent rolls: every diorama honors its archetype.
2. `variant = rng_tiles.randi_range(0, 99)` per tile (stage jitter + art variant).
3. Coastal regions: force `COAST`/`WATER` along one edge (picked by `rng_tiles`).
4. `sector` tag derived from terrain (INDUSTRIAL→IND, URBAN→TRA, FIELD→AGR,
   FOREST→SINK, WATER/COAST→NONE).

Stage rule (recomputed yearly, never stored): tile reaches stage 1/2/3 when its sector's
global progress crosses `25/60/90 + (variant mod 21 − 10)` — the ±10 jitter makes the
world transform in ripples instead of snapping, which *is* the visual arc.

## Validation (feeds `06_Done_Criteria_And_Tests.md`)

- 100-seed headless batch: all invariants from `01_World_Model_And_Tile_Schema.md` hold.
- Same seed twice ⇒ identical serialized world (deep compare).
- **Balance re-validation** (discharges Assumption #21 of `../Phase_1/06_Assumptions.md`):
  20 seeds × the 3 scripted Phase 1 strategies, run headless; structural outcomes must
  hold (Safe and Mixed win, Risky never wins) and decade metrics must stay within the
  corridors of `../Phase_1/05_Balance_Bands.md` widened by the jitter (±10%). If not,
  shrink jitter ranges — jitter is flavor, the corridor is the contract.
