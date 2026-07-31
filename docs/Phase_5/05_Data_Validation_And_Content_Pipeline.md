# Data Validation and Content Pipeline — The Drawdown Protocol (Phase 5)

How content stays correct without code review: schema validation at load, a fail-loud
policy, and the designer workflow for adding or tuning cards, crises, combos, projects,
world actors, archetypes and summits end-to-end (golden rules 9 and 15). The validator
is one class (`DataValidator`, driven by `tools/validate_data.gd`), run three ways: at
every game boot, headless in CI, and by hand before a commit. Known
`schema_version`s: 1, 2, 3.

## Validation rules (collected, not first-failure)

The validator gathers **all** violations before reporting — a designer fixes a batch in
one pass, not one error per run attempt.

### `cards.json`
| # | Rule | Severity |
|---|---|---|
| C1 | `schema_version` known; `cards` non-empty array | Error |
| C2 | Unique `id` matching `^[A-Z]{3}[0-9]+$`; `name` ≤ 24 chars, non-empty | Error |
| C3 | `category` ∈ ind/tra/agr/sink/society/diplomacy/response/research | Error |
| C4 | Costs (money, influence, happiness) ≥ 0; `requires` keys known | Error |
| C5 | Every effect `op` in the `../Phase_4/02` enumeration (incl. `actor_fund`, `actor_treaty`), with exactly its params | Error |
| C6 | `sufficiency` tag ⇔ some effect has `lifts_cap: true` (both directions) | Error |
| C7 | `sector_progress.sector` ∈ ind/tra/agr; amounts > 0; `reforest.turns` ≥ 1 | Error |
| C8 | `restoration` tag present on any card with a `reforest` effect | Warning |
| C9 | Progress-per-100-money outside 6–14 on a non-sufficiency sector card | Warning (balance guardrail) |
| C10 | `rewards` keys ⊆ {money, influence, happiness, knowledge}, values ≥ 0; money reward ≥ money cost — **skipped for happiness-cost cards** (resource-vs-resource dilemmas like the carbon levy are meant to return money) | Error / Warning (self-financing) |
| C11 | `unlock.kind` known; `count` ≥ 1, or `sector` + `gte` > 0 for sector_progress | Error |
| C12 | Every tag in the fixed vocabulary (10 combo tags + sufficiency + restoration) | Error |
| C13 | `risk.chance` in (0,1) exclusive; `on_success` branch required; only chance/on_success/on_failure keys; branch effect ops ⊆ SIMPLE_OPS; branch reward keys valid | Error |
| C14 | `codex` present (warning if absent); title non-empty and body ≥ 40 chars when present | Warning / Error |
| C15 | `meta_unlock.on` is a run ending code; cannot combine with `unlock` | Error |
| C16 | `market_weight` > 0; `bonus_only` cards carry no unlock conditions | Error |

### `events.json`
| # | Rule | Severity |
|---|---|---|
| E1 | Unique snake_case ids; unique `order`; crises < 50 ≤ opportunities < 90 ≤ feedbacks; known kinds | Error |
| E2 | Drawable entries carry `weights` and no `trigger`; feedbacks the reverse | Error |
| E3 | `weights` length 3, each ≥ 0; crisis weights non-decreasing (Overshoot escalates); `weight_mods` keys known | Error |
| E4 | `target.tags_any` ⊆ {coastal, arid, forested}; `weight_boost` keys ⊆ tags ∪ {ally} | Error |
| E5 | `damages` keys/values valid; opportunities carry no damages/scar/counters | Error |
| E6 | `opportunity.set_flag` ∈ CONSUMABLE_FLAGs; feedback `effect` keys ⊆ {e_extra, absorption} | Error |
| E7 | `on_draw` on crises only; keys ⊆ {e_extra} (answering must be able to clear the spike) | Error |
| E8 | `bonus_card.card` references an existing card; `requires` keys ⊆ {happiness_gte, money_gte, influence_gte}; ungated injection (always injects) | Error / Warning |
| E9 | Every drawable entry has `response.tags_any` (non-empty, vocabulary) and valid `rewards`; feedbacks have no response | Error |
| E10 | Every drawable entry answerable by at least one STARTING card (no unlock, no meta_unlock, not bonus_only) | Error |

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
| PR1 | Unique snake_case ids; names ≤ 24 chars; upkeep ≥ 0 and non-zero total; `turns` 2–6 | Error |
| PR2 | `completion` non-empty; effect ops ⊆ SIMPLE_OPS ∪ {ally}; passive keys ⊆ {income_money, income_influence, happiness_per_turn, absorption_per_turn} | Error |
| PR3 | `abandon_penalty` present, keys ⊆ {happiness, influence}, values ≥ 0 | Error |

### `world_actors.json`
| # | Rule | Severity |
|---|---|---|
| A1 | ≥ 2 actors (the world must out-emit the city); unique snake_case ids; non-empty names | Error |
| A2 | `emissions` > 0; `trend` ≥ 0 (treaties cut it — data never starts negative); `floor` in (0, emissions] | Error |

### `city_archetypes.json`
| # | Rule | Severity |
|---|---|---|
| Y1 | ≥ 3 selectable archetypes; unique snake_case ids; non-empty name and tagline | Error |
| Y2 | `money_mult` / `income_mult` > 0; `sector_mult` keys ∈ sectors, values > 0; `market_weights` keys in the tag vocabulary; `start_allies` ≥ 0 | Error |
| Y3 | `unlock.knowledge` references a real knowledge node; **at least one archetype must start locked** (meta-progression must have somewhere to go) | Error |

### `summits.json`
| # | Rule | Severity |
|---|---|---|
| S1 | Non-empty; unique snake_case ids; non-empty names | Error |
| S2 | `turn` unique and in 2–15 (announced in advance, resolvable in-run); `goal.metric` ∈ {net, clock_pct} with an `lte` target | Error |
| S3 | `reward` present and valid (success must matter); `penalty` present, keys ⊆ {influence, happiness, money} (failure must matter) | Error |

### `knowledge.json`
Unique ids; `kp_cost` in 1–20; `insight` non-empty; a `patch` or a `grant` required;
`patch` keys ⊆ {card, cards, cost_money, cost_influence, effect_happiness,
**reforest_turns**} with targets referencing existing card ids; `grant` keys ⊆
{media, adapt, **archetype**} (Errors).

### `tutorial.json`
Rules TU1–TU4: snake_case ids, non-empty title/text (≤ 280 chars warning), `target` in
the anchor vocabulary (incl. `crisis_bar`, `project_column`), advance `signal` in
the wired set (incl. `project_started`).

### Cross-file (T1)
Every crisis has `_hit` + `_answered` templates; every opportunity `_seized` +
`_missed`; every feedback `_hit`; every rider `_opp`; every op (incl. the actor ops),
every ending (incl. `LOSS_REVOLT`), and every system key — the established set plus
`world_drift`, `on_draw_hit`, `on_draw_cleared`, `bonus_card`, `risk_success`,
`risk_failure`, `summit_met`, `summit_missed`, `curve_bent` — present in
`log_templates.json`; `cards.enact` present. The template-coverage check makes "every
trigger visible in logs" structural.

## Error handling policy

- **Debug/editor builds**: boot halts on Errors with a full-screen report listing every
  violation (file, entry id, rule id); Warnings print to console. No silent fallbacks.
- **Release builds**: identical checks; on Error the game refuses to start a run.
- **Headless**: `godot --headless --script tools/validate_data.gd` exits non-zero on any
  Error — the CI gate in front of every content commit.

## Designer workflow: add or tune, no code

1. **Edit** the JSON (authoring templates in `01_Card_Catalog_Data.md`; conventions:
   card ids `CAT#`, everything else snake_case).
2. **Validate**: run the validator (or just boot the editor — same checks).
3. **Fixture check**: run the three autoplay strategies (F3 buttons or headless batch).
   **The additive-content invariant is reframed for the market era**: because the deal
   draws from the whole available pool, adding a NORMAL card legitimately shifts every
   timeline — new content in the pool is a tuning change *by definition*, exactly like
   a new drawable event always was. Only `bonus_only` cards (which never enter the
   pool) are timeline-neutral additions and must leave the seed-2030 fixtures
   byte-identical. A *tuned* value will diff the fixture — that is the point: the diff
   **is** the design review artifact.
4. **Corridor check**: 20-seed × 3-strategy batch against
   `../Phase_1/05_Balance_Bands.md`. The corridor is a **rate corridor** — market
   variance is deliberate, so rates, not certainties: **Risky must never win; Safe
   must win ≥ 50% of seeds; Mixed ≥ 40%** (currently measured 12/20 and 11/20).
   `--enforce` makes violations exit non-zero.
5. **Commit**: one balance concern per commit; message carries the tuning rationale;
   update the affected Phase 1 doc **in the same commit** — docs first is the standing
   rule from `../Phase_4/03`.

Steps 2–4 are one wrapper script (`tools/content_check.sh`: validate → test suite with
fixture regression → enforced 20-seed batch) so the whole pipeline is a single command;
total runtime target < 60 s (golden rule 17).

## What lives where (single-authority map)

| Question | Authority |
|---|---|
| What a card costs/does/pays/risks/unlocks | `data/cards.json` |
| What lands each turn, its spikes/windows, and how to answer it | `data/events.json` |
| What combos exist and pay | `data/combos.json` |
| What projects cost and grant | `data/projects.json` |
| What the rest of the world emits and how fast | `data/world_actors.json` |
| What each starting city changes | `data/city_archetypes.json` |
| When the COPs meet and what they demand | `data/summits.json` |
| What any of it says on screen | `data/log_templates.json` |
| What ops/kinds/tags exist and their semantics | `../Phase_4/02` (code mirrors it) |
| Whether the numbers are *good* | `../Phase_1/05` corridors + fixtures |

A change that cannot be expressed in the data files (new op, new unlock kind, new
passive, new flag, new summit metric) is a code+design change: it goes through a
Phase 4 spec amendment first, then implementation, then content may use it. The
validator enforces the boundary by rejecting unknown vocabulary.
