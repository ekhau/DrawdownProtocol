# Data Validation and Content Pipeline — The Drawdown Protocol (Phase 5)

How content stays correct without code review: schema validation at load, a fail-loud
policy, and the designer workflow for adding or tuning cards and events end-to-end
(golden rules 9 and 15). The validator is one script (`tools/validate_data.gd`), run
three ways: at every game boot, headless in CI, and by hand before a commit.

## Validation rules (collected, not first-failure)

The validator gathers **all** violations before reporting — a designer fixes a batch in
one pass, not one error per run attempt.

### `cards.json`
| # | Rule | Severity |
|---|---|---|
| C1 | `schema_version` known; `cards` non-empty array | Error |
| C2 | Unique `id` matching `^[A-Z]{3}[0-9]+$`; `name` ≤ 24 chars, non-empty | Error |
| C3 | `category` ∈ ind/tra/agr/sink/society/diplomacy | Error |
| C4 | Costs ≥ 0; `requires` keys known (`allies_min` only, for now) | Error |
| C5 | Every effect `op` in the `../Phase_4/02` enumeration, with exactly its params | Error |
| C6 | `sufficiency` tag ⇔ some effect has `lifts_cap: true` (both directions) | Error |
| C7 | `sector_progress.sector` ∈ ind/tra/agr; amounts > 0; `reforest.years` ≥ 1 | Error |
| C8 | `restoration` tag present on any card with a `reforest` effect | Warning |
| C9 | Progress-per-100-money outside 6–14 on a sector card | Warning (balance guardrail) |

### `events.json`
| # | Rule | Severity |
|---|---|---|
| E1 | Unique snake_case ids; unique `order`; extremes < 50 ≤ feedbacks | Error |
| E2 | Exactly one of `probabilities` / `probability_formula` / `trigger` per kind | Error |
| E3 | `probabilities` length 3, each in [0,1], non-decreasing (Overshoot escalates) | Error |
| E4 | `target.tags_any` ⊆ {coastal, arid, forested}; `weight_boost` keys ⊆ tags ∪ {ally} | Error |
| E5 | `damages` keys ⊆ {money, happiness, absorption, influence, ally_lost}, values > 0 | Error |
| E6 | `opportunity.set_flag` ∈ CONSUMABLE_FLAGs; feedback `effect` keys ⊆ {e_extra, absorption} | Error |
| E7 | Extreme event with `opportunity: null` | Warning (pillar 2 check; heat_wave is the accepted case) |
| E8 | Reordering/renumbering `order` vs previous file version | Warning (determinism-breaking; needs fixture rebuild) |

### `knowledge.json`
Unique ids; `kp_cost` in 1–20; `patch.card(s)` reference existing card ids;
patch fields limited to the documented set; `insight` non-empty (Errors).

### Cross-file
Every card/event/knowledge id referenced by `log_templates.json` exists, and every
catalog entry has its required templates (hit + opportunity where applicable) — the
template-coverage check that makes "event triggers visible in logs" structural.

## Error handling policy

- **Debug/editor builds**: boot halts on Errors with a full-screen report listing every
  violation (file, entry id, rule id); Warnings print to console and the F3 overlay
  badge. No silent fallbacks — a half-loaded catalog produces unexplainable balance.
- **Release builds**: identical checks; on Error the game refuses to start a run and
  shows the report (data ships with the build, so this should be unreachable — but a
  corrupt install must never limp into a wrong simulation).
- **Headless**: `godot --headless --script tools/validate_data.gd` exits non-zero on any
  Error — the CI gate in front of every content commit.

## Designer workflow: add or tune, no code

1. **Edit** the JSON (authoring template in `01_Card_Catalog_Data.md`; conventions:
   card ids `CAT#`, events snake_case, template ids `evt_<id>_hit` / `evt_<id>_opp` /
   `card_<id>_line`).
2. **Validate**: run the validator (or just boot the editor — same checks).
3. **Fixture check**: run the three autoplay strategies (F3 buttons or headless batch,
   `../Phase_3/05`). A *new* card must leave the seed-2030 fixtures byte-identical
   (strategies reference existing ids only — additive content is regression-free by
   construction). A *tuned* value will diff T13-P4 — that is the point: the diff **is**
   the design review artifact.
4. **Corridor check** for tuning changes: 20-seed × 3-strategy batch; outcomes and
   decade metrics against `../Phase_1/05_Balance_Bands.md`. Structural outcomes must
   hold (Safe/Mixed win, Risky never wins).
5. **Commit**: one balance concern per commit; message carries the tuning rationale
   (Plan.md Phase 8's "tuning patch notes" start now, not at Phase 8); update the
   affected Phase 1 doc **in the same commit** — docs first is the standing rule from
   `../Phase_4/03`.

Steps 2–4 are one wrapper script (`tools/content_check.sh`) so the whole pipeline is a
single command; total runtime target < 60 s (golden rule 17 — a slow pipeline is an
unused pipeline).

## What lives where (single-authority map)

| Question | Authority |
|---|---|
| What a card costs/does | `data/cards.json` |
| When/how hard events hit | `data/events.json` |
| What any of it says on screen | `data/log_templates.json` |
| What ops exist and their semantics | `../Phase_4/02` (code mirrors it) |
| Whether the numbers are *good* | `../Phase_1/05` corridors + fixtures |

A change that cannot be expressed in the data files (new op, new trigger type, new flag)
is a code+design change: it goes through a Phase 4 spec amendment first, then
implementation, then content may use it. The validator enforces the boundary by
rejecting unknown vocabulary.
