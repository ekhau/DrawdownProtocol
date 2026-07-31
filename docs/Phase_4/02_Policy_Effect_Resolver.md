# Policy Effect Resolver — The Drawdown Protocol (Phase 4)

Resolves card plays (several per turn, dealt through the project market), combo
firings, risk rolls, world-actor diplomacy and project lifecycles against RunState.
Fully data-driven: the catalogs in `data/cards.json`, `data/combos.json`,
`data/projects.json` and `data/world_actors.json` are the single authority for costs,
rewards and effects (golden rule 9); the resolver knows *operations*, never card names.
Numbers come from `../Phase_1/04_Policy_Effect_Matrix.md`.

## Card catalog schema (`data/cards.json`, schema_version 3)

```json
{
  "id": "RSP5",
  "name": "Grid Repair Crews",
  "category": "response",                   // ind|tra|agr|sink|society|diplomacy|response|research
  "cost_money": 35,
  "cost_influence": 0,
  "cost_happiness": 0,                      // any mix of the three; omitted = 0
  "rewards": { "money": 15 },               // money|influence|happiness|knowledge, all >= 0
  "requires": { "allies_min": 0 },          // omitted keys default to no requirement
  "tags": ["energy", "relief"],             // crisis answers + combo algebra; validator C12
  "market_weight": 1.0,                     // optional deal weight (> 0; default 1.0) — C16
  "unlock": { "kind": "crises_answered", "count": 4 },   // optional: deck growth (C11)
  "meta_unlock": { "on": "LOSS_REVOLT" },   // optional: earned by a past defeat (C15)
  "bonus_only": true,                       // optional: exists only via event injection (C16)
  "risk": { "chance": 0.35,                 // optional push-your-luck block (C13)
            "on_success": { "effects": [], "rewards": {} },
            "on_failure": { "effects": [], "rewards": {} } },
  "codex": { "title": "...", "body": "..." },  // real-world solution blurb (C14)
  "effects": [ { "op": "adapt", "amount": 2 } ]
}
```

Tag vocabulary (validator C12): the ten combo/response tags — water, food, energy,
mobility, forest, coast, health, civic, treaty, relief — plus the two rule tags
`sufficiency` (cap lift contract, C6) and `restoration` (fire-discount target, A4).

Unlock kinds (C11): `crises_answered`, `combos`, `allies`, `projects_completed`
(each with `count`), and `sector_progress` (with `sector`, `gte`). Cards with an
`unlock` field are outside the playable pool until the run meets the condition; the
check runs after every card play and project completion. `meta_unlock` cards are
lessons of specific defeats: permanently unlocked the first time the meta records that
ending, then passed to `new_run` as `meta_cards` and available from turn 1
(`is_card_available`). `bonus_only` cards are excluded from the market pool and from
`available_cards()`; they exist only while an event's `bonus_card` injection holds them
in the market.

## Effect operations (complete enumeration)

| `op` | Params | Semantics | Duration class |
|---|---|---|---|
| `sector_progress` | sector, amount, lifts_cap | `progress = min(cap, progress + amount)`; if `lifts_cap`, set `suff_played` first (cap 70→100), then add | INSTANT |
| `joint_progress` | amount | `sector_progress` on all three sectors in fixed order; never lifts caps | INSTANT |
| `happiness` | amount, waivable | `H = clamp(H + amount, 0, 100)`; negative+waivable amounts subject to the waiver rule | INSTANT |
| `sink_now` | amount | `absorption += amount` | INSTANT |
| `reforest` | per_turn, turns | append `ReforestEntry`; matures during step 3, `per_turn` per turn for `turns` turns | MATURING |
| `adapt` | amount | `adapt = min(60, adapt + amount)` (clarification C2) | INSTANT |
| `media` | — | `media = true` for rest of run | PERSISTENT_FLAG |
| `wellbeing` | amount | alias of `happiness` (kept separate for analytics) | INSTANT |
| `ally` | — | `allies += 1`; card plays take a UI-supplied target region; combo/project contexts auto-target the first neutral region (skipped when fully allied) | PERSISTENT until crisis loss |
| `actor_fund` | cut, trend_cut | auto-targets the **biggest emitter above its floor**: `emissions = max(floor, emissions − cut)`, `trend = max(0, trend − trend_cut)` (DIP4 Fund a Transition) | INSTANT (on the world curve) |
| `actor_treaty` | trend_cut | auto-targets the **steepest still-positive trend**: `trend = max(0, trend − trend_cut)` (DIP5 Emissions Treaty) | INSTANT (on the world curve) |

Combo effects, project completions and risk branches are restricted to the SIMPLE_OPS
subset — `sector_progress`, `joint_progress`, `happiness`, `wellbeing`, `sink_now`,
`reforest`, `adapt`, `actor_fund`, `actor_treaty`; no `ally`, no `media` (validators
CB4 / PR2 / C13); project completions may additionally use `ally` (auto-target).
Duration taxonomy unchanged: INSTANT, MATURING, PERSISTENT_FLAG, CONSUMABLE_FLAG
(`window`, `fire_discount`, `flood_rebuild`).

## Validation order (all checks before any mutation)

```gdscript
func can_play_reason(id) -> StringName:
    # ended / resolving                                    -> "ended" / "resolving"
    # unknown card                                         -> "unknown_card"
    # not available (unlock unmet, meta lesson not earned,
    #   bonus-only card not currently injected)            -> "card_locked"
    # market_enforced and id not in this turn's market     -> "not_in_market"
    # plays this turn >= MAX_CARDS_PER_TURN                -> "turn_limit"
    # effective_cost_money(id) > money                     -> "no_money"
    # cost_influence > influence                           -> "no_influence"
    # cost_happiness > happiness                           -> "no_happiness"
    # requires.allies_min > allies                         -> "locked_allies"
    # op "ally": allies >= 6 or no NEUTRAL region          -> "no_target"
    # op "actor_fund": no actor above its floor            -> "no_target"
    # op "actor_treaty": no actor with positive trend      -> "no_target"
    # op "media": media already active                     -> "media_active"
    # sector card: progress >= cap and not a fresh lift    -> "capped"
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
3. **Risk roll** (2b), if the card carries a `risk` block: exactly one
   `rng_risk.randf()` against `chance`; the matching branch's effects (SIMPLE_OPS)
   apply and its rewards are granted; the outcome (`chance`, `success`, applied
   effects, gains) is recorded on the action and `risk_resolved` fires.
4. Grant the card's printed `rewards` (money/influence/happiness added, clamped;
   knowledge accrues to `kp_earned`).
5. **Crisis answer**: scan `pending_crises` in draw order; the first open entry whose
   `response.tags_any` intersects the card's tags is flagged answered, its response
   rewards are granted immediately, `crises_answered_total` increments, and
   `crisis_answered` fires. One card answers at most one crisis; a second matching
   crisis needs a second card. (An answered crisis's on-draw spike dissipates at
   step 3 — see `03_Climate_Calc_Spec.md`.)
6. **Tag accounting + combo check**: the card's tags join the turn's multiset; every
   combo not yet fired this turn whose `tags_required` multiset is covered fires
   immediately: `mult = 1 + COMBO_CHAIN_STEP × min(chain, COMBO_CHAIN_CAP)` (chain
   BEFORE this combo), chain += 1, combo effects apply, rewards × mult are granted
   (knowledge rewards only on the combo's first fire of the run), `combo_triggered`
   fires. Combos check in catalog order; a combo can re-fire on later turns.
7. **Market consumption**: a market offer is a single funding decision — playing
   erases the card from this turn's market.
8. Record the action (card id, target, costs, rewards, applied effects, waiver, risk
   outcome, crisis answered, combos fired) in the turn's action list; emit
   `card_played`; then the **deck-growth check** unlocks any card whose condition the
   run now meets (`card_unlocked`).

## Project lifecycle

`data/projects.json` schema: `id`, `name`, `upkeep_money`, `upkeep_influence`, `turns`
(2–6; all four shipped projects run **3 turns** = 15 years),
`completion { effects[], passive{} }`, `abandon_penalty { happiness, influence }`.
Passive keys: `income_money`, `income_influence`, `happiness_per_turn`,
`absorption_per_turn` (validator PR2).

- `start_project(id)`: legal in AWAIT_ACTION when the project was never attempted this
  run, fewer than `PROJECT_MAX_ACTIVE` are running, and this turn's upkeep is
  affordable — which is **paid immediately** (`turns_left = turns − 1`). Emits
  `project_changed(id, "launched")`.
- Turn-start upkeep pass (`_begin_year`, launch order): pay `upkeep`; at
  `turns_left == 0` the project **completes** — completion effects apply (ally ops
  auto-target), passives merge additively into `passives`, `projects_completed`
  increments, deck growth re-checks. If the upkeep is unaffordable the project
  **fails**: the abandon penalty applies and the project is closed for the run.
- `abandon_project(id)`: player-initiated; same penalty, status "abandoned".
- One attempt per project per run — completed, failed, or abandoned, it never returns.
- Project events record `turns_left` (not years) — the log and analytics speak in
  turns.

## Stacking rules

- `sector_progress` is additive across plays and turns, clamped to the live cap every
  application; two plays of the same card in one turn are legal only if the market
  offered it twice — which the without-replacement deal never does; in practice an
  offer is played at most once per turn.
- Multiple `reforest` entries coexist. `media` cannot stack. `ally` stacks to 6.
  `adapt` stacks to 60. Project passives stack additively across completed projects.
  `actor_fund` / `actor_treaty` re-target on every application (the biggest/steepest
  actor *at that moment*), floored at each actor's `floor` and at trend 0.
- A joint project on a capped sector silently clamps at that sector's cap — the resolver
  reports requested vs applied in the TurnRecord ("industry +5 → +2, at cap"). Never
  fail the whole card for one capped sector.
- A combo fires at most once per turn; the chain multiplier applies to its resource
  rewards only, never to its effects (effects stay verbatim — readable balance).

## Knowledge-tree modifiers (applied at init, never mid-run)

Nodes in `data/knowledge.json` patch the run's in-memory catalog copy (`cost_money`,
`cost_influence`, `effect_happiness`, `reforest_turns` — program totals preserved: the
patched card delivers the same total absorption over fewer turns) or grant state
(`media`, `adapt`) before turn 1. The `archetype` grant key is meta-scope: it unlocks a
locked city archetype (Capital Charter → `political_capital`) on the archetype-select
screen rather than patching the run. `cards.json` on disk is never mutated.

## Diplomacy interactions

- The `ally` effect on a card play requires the UI-supplied `target_region`; the
  resolver validates the target is NEUTRAL and not the player home, flips `ally_state`,
  emits `ally_changed`. Timeline-equivalence of any valid target is test T9 (Phase 3).
- The **actor ops** never take a target: `actor_fund` picks the biggest emitter still
  above its floor, `actor_treaty` the steepest positive trend — fixed iteration order
  keeps ties deterministic; `{}` (no qualifying actor) reports `no_target` and, inside
  combo/project/risk contexts, records a skipped entry instead of failing the play.
- Allies also damp the world's between-turn drift (`ACTOR_TREND_PER_ALLY` per ally) —
  that lives in the actor-advance step (`01_RunState_Spec.md`), not in the resolver.
- Ally loss is **not** a resolver concern — it belongs to the crisis-strike step
  (`04_Society_And_Resilience_Spec.md`); the resolver only ever adds allies.
