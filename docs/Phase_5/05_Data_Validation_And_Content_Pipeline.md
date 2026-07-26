# Data Validation and Content Pipeline — The Drawdown Protocol (Phase 5)

How content stays correct without code review: schema validation at load, a fail-loud
policy, and the designer workflow for adding or tuning cards, crises, combos and
projects end-to-end (golden rules 9 and 15). The validator is one script
(`tools/validate_data.gd`), run three ways: at every game boot, headless in CI, and by
hand before a commit.

## Validation rules (collected, not first-failure)

The validator gathers **all** violations before reporting — a designer fixes a batch in
one pass, not one error per run attempt.

### `cards.json`
| # | Rule | Severity |
|---|---|---|
| C1 | `schema_version` known; `cards` non-empty array | Error |
| C2 | Unique `id` matching `^[A-Z]{3}[0-9]+$`; `name` ≤ 24 chars, non-empty | Error |
| C3 | `category` ∈ ind/tra/agr/sink/society/diplomacy/response | Error |
| C4 | Costs (money, influence, happiness) ≥ 0; `requires` keys known | Error |
| C5 | Every effect `op` in the `../Phase_4/02` enumeration, with exactly its params | Error |
| C6 | `sufficiency` tag ⇔ some effect has `lifts_cap: true` (both directions) | Error |
| C7 | `sector_progress.sector` ∈ ind/tra/agr; amounts > 0; `reforest.years` ≥ 1 | Error |
| C8 | `restoration` tag present on any card with a `reforest` effect | Warning |
| C9 | Progress-per-100-money outside 6–14 on a non-sufficiency sector card | Warning (balance guardrail) |
| C10 | `rewards` keys ⊆ {money, influence, happiness, knowledge}, values ≥ 0; money reward ≥ money cost | Error / Warning (self-financing) |
| C11 | `unlock.kind` known; `count` ≥ 1, or `sector` + `gte` > 0 for sector_progress | Error |
| C12 | Every tag in the fixed vocabulary (10 combo tags + sufficiency + restoration) | Error |

### `events.json`
| # | Rule | Severity |
|---|---|---|
| E1 | Unique snake_case ids; unique `order`; crises < 50 ≤ opportunities < 90 ≤ feedbacks; known kinds | Error |
| E2 | Drawable entries carry `weights` and no `trigger`; feedbacks the reverse | Error |
| E3 | `weights` length 3, each ≥ 0; crisis weights non-decreasing (Overshoot escalates); `weight_mods` keys known | Error |
| E4 | `target.tags_any` ⊆ {coastal, arid, forested}; `weight_boost` keys ⊆ tags ∪ {ally} | Error |
| E5 | `damages` keys/values valid; opportunities carry no damages/scar/counters | Error |
| E6 | `opportunity.set_flag` ∈ CONSUMABLE_FLAGs; feedback `effect` keys ⊆ {e_extra, absorption} | Error |
| E9 | Every drawable entry has `response.tags_any` (non-empty, vocabulary) and valid `rewards`; feedbacks have no response | Error |
| E10 | Every drawable entry answerable by at least one STARTING (non-unlock) card | Error |
| E8 | Reordering `order` vs previous file version | Not implemented (needs history) |

### `combos.json`
| # | Rule | Severity |
|---|---|---|
| CB1 | Unique snake_case ids; non-empty names | Error |
| CB2 | `tags_required` ≥ 2 entries, all in the vocabulary | Error |
| CB3 | Valid `rewards`; at least one of rewards/effects present | Error |
| CB4 | Effect ops ⊆ SIMPLE_OPS (no ally, no media), with required params | Error |
| CB5 | A single card's tags cover the whole combo | Warning (a combo must need ≥ 2 cards) |

### `projects.json`
| # | Rule | Severity |
|---|---|---|
| PR1 | Unique snake_case ids; names ≤ 24 chars; upkeep ≥ 0 and non-zero total; `years` 2–10 | Error |
| PR2 | `completion` non-empty; effect ops ⊆ SIMPLE_OPS ∪ {ally}; passive keys known | Error |
| PR3 | `abandon_penalty` present, keys ⊆ {happiness, influence}, values ≥ 0 | Error |

### `knowledge.json`
Unique ids; `kp_cost` in 1–20; `patch.card(s)` reference existing card ids;
patch fields limited to the documented set; `insight` non-empty (Errors).

### `tutorial.json`
Rules TU1–TU4: snake_case ids, non-empty title/text (≤ 280 chars warning), `target` in
the anchor vocabulary (now incl. `crisis_bar`, `project_column`), advance `signal` in
the wired set (now incl. `project_started`).

### Cross-file (T1)
Every crisis has `_hit` + `_answered` templates; every opportunity `_seized` + `_missed`;
every feedback `_hit`; every rider `_opp`; every op, ending, and system key (incl.
`crises_faced`, `combo`, `rewards`, `card_unlocked`, `project_*`) present in
`log_templates.json` — the template-coverage check that makes "every trigger visible in
logs" structural.

## Error handling policy

- **Debug/editor builds**: boot halts on Errors with a full-screen report listing every
  violation (file, entry id, rule id); Warnings print to console. No silent fallbacks.
- **Release builds**: identical checks; on Error the game refuses to start a run.
- **Headless**: `godot --headless --script tools/validate_data.gd` exits non-zero on any
  Error — the CI gate in front of every content commit.

## Designer workflow: add or tune, no code

1. **Edit** the JSON (authoring templates in `01_Card_Catalog_Data.md`; conventions:
   card ids `CAT#`, events/combos/projects snake_case).
2. **Validate**: run the validator (or just boot the editor — same checks).
3. **Fixture check**: run the three autoplay strategies (F3 buttons or headless batch).
   A *new* card/combo/project must leave the seed-2030 fixtures byte-identical when the
   strategies never touch it (additive content is regression-free by construction —
   note that a new DRAWABLE event always shifts the crisis draw and therefore the
   fixtures: adding to the deck is a tuning change by definition). A *tuned* value will
   diff T13-P4 — that is the point: the diff **is** the design review artifact.
4. **Corridor check** for tuning changes: 20-seed × 3-strategy batch; outcomes and
   decade metrics against `../Phase_1/05_Balance_Bands.md`. Structural outcomes must
   hold (Safe/Mixed win, Risky never wins).
5. **Commit**: one balance concern per commit; message carries the tuning rationale;
   update the affected Phase 1 doc **in the same commit** — docs first is the standing
   rule from `../Phase_4/03`.

Steps 2–4 are one wrapper script (`tools/content_check.sh`) so the whole pipeline is a
single command; total runtime target < 60 s (golden rule 17).

## What lives where (single-authority map)

| Question | Authority |
|---|---|
| What a card costs/does/pays/unlocks | `data/cards.json` |
| What lands each year and how to answer it | `data/events.json` |
| What combos exist and pay | `data/combos.json` |
| What projects cost and grant | `data/projects.json` |
| What any of it says on screen | `data/log_templates.json` |
| What ops/kinds/tags exist and their semantics | `../Phase_4/02` (code mirrors it) |
| Whether the numbers are *good* | `../Phase_1/05` corridors + fixtures |

A change that cannot be expressed in the data files (new op, new unlock kind, new
passive, new flag) is a code+design change: it goes through a Phase 4 spec amendment
first, then implementation, then content may use it. The validator enforces the
boundary by rejecting unknown vocabulary.
