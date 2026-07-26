# Policy Effect Resolver — The Drawdown Protocol (Phase 4)

Resolves card plays (several per year), combo firings, and project lifecycles against
RunState. Fully data-driven: the catalogs in `data/cards.json`, `data/combos.json` and
`data/projects.json` are the single authority for costs, rewards and effects (golden
rule 9); the resolver knows *operations*, never card names. Numbers come from
`../Phase_1/04_Policy_Effect_Matrix.md`.

## Card catalog schema (`data/cards.json`, schema_version 2)

```json
{
  "id": "RSP5",
  "name": "Grid Repair Crews",
  "category": "response",                   // ind|tra|agr|sink|society|diplomacy|response
  "cost_money": 35,
  "cost_influence": 0,
  "cost_happiness": 0,                      // any mix of the three; omitted = 0
  "rewards": { "money": 15 },               // money|influence|happiness|knowledge, all >= 0
  "requires": { "allies_min": 0 },          // omitted keys default to no requirement
  "tags": ["energy", "relief"],             // crisis answers + combo algebra; validator C12
  "unlock": { "kind": "crises_answered", "count": 4 },   // optional: deck growth (C11)
  "effects": [ { "op": "adapt", "amount": 2 } ]
}
```

Tag vocabulary (validator C12): the ten combo/response tags — water, food, energy,
mobility, forest, coast, health, civic, treaty, relief — plus the two rule tags
`sufficiency` (cap lift contract, C6) and `restoration` (fire-discount target, A4).

Unlock kinds (C11): `crises_answered`, `combos`, `allies`, `projects_completed`
(each with `count`), and `sector_progress` (with `sector`, `gte`). Cards with an
`unlock` field are outside the playable pool until the run meets the condition; the
check runs after every card play and project completion.

## Effect operations (complete enumeration — unchanged vocabulary)

| `op` | Params | Semantics | Duration class |
|---|---|---|---|
| `sector_progress` | sector, amount, lifts_cap | `progress = min(cap, progress + amount)`; if `lifts_cap`, set `suff_played` first (cap 70→100), then add | INSTANT |
| `joint_progress` | amount | `sector_progress` on all three sectors in fixed order; never lifts caps | INSTANT |
| `happiness` | amount, waivable | `H = clamp(H + amount, 0, 100)`; negative+waivable amounts subject to the waiver rule | INSTANT |
| `sink_now` | amount | `absorption += amount` | INSTANT |
| `reforest` | per_year, years | append `ReforestEntry`; matures during step 3 | MATURING |
| `adapt` | amount | `adapt = min(60, adapt + amount)` (clarification C2) | INSTANT |
| `media` | — | `media = true` for rest of run | PERSISTENT_FLAG |
| `wellbeing` | amount | alias of `happiness` (kept separate for analytics) | INSTANT |
| `ally` | — | `allies += 1`; card plays take a UI-supplied target region; combo/project contexts auto-target the first neutral region (skipped when fully allied) | PERSISTENT until crisis loss |

Combo effects are restricted to the SIMPLE_OPS subset (no `ally`, no `media` — validator
CB4); project completions may additionally use `ally` (auto-target). Duration taxonomy
unchanged: INSTANT, MATURING, PERSISTENT_FLAG, CONSUMABLE_FLAG (`window`,
`fire_discount`, `flood_rebuild`).

## Validation order (all checks before any mutation)

```gdscript
func can_play_reason(id) -> StringName:
    # ended / resolving                                    -> "ended" / "resolving"
    # unknown card                                         -> "unknown_card"
    # unlock condition not met this run                    -> "card_locked"
    # plays this turn >= MAX_CARDS_PER_TURN                -> "turn_limit"
    # effective_cost_money(id) > money                     -> "no_money"
    # cost_influence > influence                           -> "no_influence"
    # cost_happiness > happiness                           -> "no_happiness"
    # requires.allies_min > allies                         -> "locked_allies"
    # op "ally": allies < 6 and a NEUTRAL region exists    -> "no_target"
    # op "media": not media (unplayable twice)             -> "media_active"
    # sector card: progress < cap OR (lifts_cap and !suff) -> "capped"
```

`effective_cost_money(id)`: catalog cost, ×0.5 if `fire_discount` and the card carries
the `restoration` tag (discount consumed on play, not on preview). Cost previews shown
by the UI must call this same function — one source of truth for what the player reads.

## Application order per play (single code path)

1. Pay: `money -= cost`, `influence -= cost_influence`, `happiness -= cost_happiness`
   (clamped ≥ 0); consume `fire_discount` if used.
2. Apply effects **in catalog order** (waiver rule for negative waivable happiness,
   clarification **C1**: media waives without consuming the window; else the window
   waives and is consumed; else the penalty applies).
3. Grant the card's printed `rewards` (money/influence/happiness added, clamped;
   knowledge accrues to `kp_earned`).
4. **Crisis answer**: scan `pending_crises` in draw order; the first open entry whose
   `response.tags_any` intersects the card's tags is flagged answered, its response
   rewards are granted immediately, `crises_answered_total` increments, and
   `crisis_answered` fires. One card answers at most one crisis; a second matching
   crisis needs a second card.
5. **Tag accounting + combo check**: the card's tags join the year's multiset; every
   combo not yet fired this year whose `tags_required` multiset is covered fires
   immediately: `mult = 1 + COMBO_CHAIN_STEP × min(chain, COMBO_CHAIN_CAP)` (chain
   BEFORE this combo), chain += 1, combo effects apply, rewards × mult are granted
   (knowledge rewards only on the combo's first fire of the run), `combo_triggered`
   fires. Combos check in catalog order; a combo can re-fire on later years.
6. **Deck-growth check**: any locked card whose unlock condition the run now meets joins
   the pool (`card_unlocked`).
7. Record the action (card id, target, costs, rewards, applied effects, waiver, crisis
   answered, combos fired) in the turn's action list; emit `card_played`.

## Project lifecycle

`data/projects.json` schema: `id`, `name`, `upkeep_money`, `upkeep_influence`, `years`
(2–10), `completion { effects[], passive{} }`, `abandon_penalty { happiness, influence }`.
Passive keys: `income_money`, `income_influence`, `happiness_per_year`,
`absorption_per_year` (validator PR2).

- `start_project(id)`: legal in AWAIT_ACTION when the project was never attempted this
  run, fewer than `PROJECT_MAX_ACTIVE` are running, and this year's upkeep is
  affordable — which is **paid immediately** (`years_left = years − 1`). Emits
  `project_changed(id, "launched")`.
- Year-start upkeep pass (`_begin_year`, launch order): pay `upkeep`; at
  `years_left == 0` the project **completes** — completion effects apply (ally ops
  auto-target), passives merge additively into `passives`, `projects_completed`
  increments, deck growth re-checks. If the upkeep is unaffordable the project
  **fails**: the abandon penalty applies and the project is closed for the run.
- `abandon_project(id)`: player-initiated; same penalty, status "abandoned".
- One attempt per project per run — completed, failed, or abandoned, it never returns.

## Stacking rules

- `sector_progress` is additive across plays and years, clamped to the live cap every
  application; two plays of the same card in one year are legal and pay twice.
- Multiple `reforest` entries coexist. `media` cannot stack. `ally` stacks to 6.
  `adapt` stacks to 60. Project passives stack additively across completed projects.
- A joint project on a capped sector silently clamps at that sector's cap — the resolver
  reports requested vs applied in the TurnRecord ("industry +5 → +2, at cap"). Never
  fail the whole card for one capped sector.
- A combo fires at most once per year; the chain multiplier applies to its resource
  rewards only, never to its effects (effects stay verbatim — readable balance).

## Knowledge-tree modifiers (applied at init, never mid-run)

Unchanged from the previous revision: nodes in `data/knowledge.json` patch the run's
in-memory catalog copy (`cost_money`, `cost_influence`, `effect_happiness`,
`reforest_years` — totals preserved) or grant state (`media`, `adapt`) before turn 1.
`cards.json` on disk is never mutated.

## Diplomacy interactions

- The `ally` effect on a card play requires the UI-supplied `target_region`; the
  resolver validates the target is NEUTRAL and not the player home, flips `ally_state`,
  emits `ally_changed`. Timeline-equivalence of any valid target is test T9 (Phase 3).
- Ally loss is **not** a resolver concern — it belongs to the crisis-strike step
  (`04_Society_And_Resilience_Spec.md`); the resolver only ever adds allies.
