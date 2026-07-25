# Policy Effect Resolver — The Drawdown Protocol (Phase 4)

Resolves one card per year against RunState. Fully data-driven: the catalog in
`data/cards.json` is the single authority for costs and effects (golden rule 9;
Plan.md engineering rules); the resolver knows *operations*, never card names.
Numbers come from `../Phase_1/04_Policy_Effect_Matrix.md`.

## Card catalog schema (`data/cards.json`)

```json
{
  "id": "TRA1",
  "name": "Rail & Bike Networks",
  "category": "transport",                  // ind|tra|agr|sink|society|diplomacy
  "cost_money": 80,
  "cost_influence": 0,
  "requires": { "allies_min": 0 },          // omitted keys default to no requirement
  "tags": ["sufficiency"],
  "effects": [
    { "op": "sector_progress", "sector": "tra", "amount": 10, "lifts_cap": true },
    { "op": "happiness", "amount": 2, "waivable": false }
  ]
}
```

## Effect operations (complete enumeration)

| `op` | Params | Semantics | Duration class |
|---|---|---|---|
| `sector_progress` | sector, amount, lifts_cap | `progress = min(cap, progress + amount)`; if `lifts_cap`, set `suff_played` first (cap 70→100), then add | INSTANT |
| `joint_progress` | amount | `sector_progress` on all three sectors in fixed order; never lifts caps | INSTANT |
| `happiness` | amount, waivable | `H = clamp(H + amount, 0, 100)`; negative+waivable amounts subject to the waiver rule | INSTANT |
| `sink_now` | amount | `absorption += amount` | INSTANT |
| `reforest` | per_year, years | append `ReforestEntry`; matures during step 3 | MATURING |
| `adapt` | amount | `adapt = min(60, adapt + amount)` (clarification C2 below) | INSTANT |
| `media` | — | `media = true` for rest of run | PERSISTENT_FLAG |
| `wellbeing` | amount | alias of `happiness` (kept separate for analytics of SOC2) | INSTANT |
| `ally` | — | `allies += 1`; requires target region (UI prompt, flavor-only per `../Phase_3/04_Interaction_Spec.md`); sets region `ally_state` | PERSISTENT until crisis loss |

Duration taxonomy: **INSTANT** (applies once, permanent consequence),
**MATURING** (queue entry drained over N years), **PERSISTENT_FLAG** (until run end),
**CONSUMABLE_FLAG** (`window`, `fire_discount`, `flood_rebuild` — set by events/plays,
consumed by the first thing they modify). There are no timed buffs that expire silently —
every duration is visible state (readable balance, pillar 1).

## Validation order (all checks before any mutation)

```gdscript
func can_play(id: StringName, rs: RunState) -> Error:
    # 1. phase == AWAIT_ACTION and not rs.action_taken     -> ERR_UNAVAILABLE
    # 2. effective_cost_money(id, rs) <= rs.money           -> ERR_INSUFFICIENT_FUNDS
    # 3. cost_influence <= rs.influence                     -> ERR_INSUFFICIENT_FUNDS
    # 4. requires.allies_min <= rs.allies                   -> ERR_UNCONFIGURED
    # 5. op "ally": rs.allies < 6 and a NEUTRAL region exists
    # 6. op "media": not rs.media (unplayable twice)
    # 7. sector card: progress < cap OR (lifts_cap and not suff_played)
```

`effective_cost_money(id, rs)`: catalog cost, ×0.5 if `fire_discount` and category is
`sink` (discount consumed on play, not on preview). Cost previews shown by the UI must
call this same function — one source of truth for what the player reads.

## Application order (single code path)

1. Pay: `money -= cost`, `influence -= cost_influence`; consume `fire_discount` if used.
2. Apply effects **in catalog order** (authors control sequencing; the only
   order-sensitive pair is `lifts_cap` before a same-card progress add, handled inside
   the op).
3. Waiver rule for negative waivable happiness (clarification **C1**): if `media` is
   active, waive and **do not consume** `window`; else if `window` is open, waive and
   consume it; else apply the penalty. *(The Phase 1 throwaway script consumed the window
   even when media made it redundant; this spec keeps the window banked. Verified
   fixture-neutral: in the seed-2030 runs no waivable card was ever played with both
   flags set — Safe/Mixed had media from year 1, Risky played no waivable cards.)*
4. Set `action_taken = true`; emit `card_played`; write the action section of the
   TurnRecord (card id, costs paid, effects applied with final clamped values).

**C2 (clarification):** `adapt` is clamped at 60 per the metric dictionary range; the
Phase 1 script had no clamp. Fixture-neutral (max observed adapt in the three runs: 15).

## Stacking rules

- `sector_progress` is additive across years, clamped to the live cap every application.
- Multiple `reforest` entries coexist (Safe run banks two programs at once by design).
- `media` cannot stack (validation 6). `ally` stacks to 6. `adapt` stacks to 60.
- A joint project on a capped sector silently clamps at that sector's cap — the resolver
  reports actual applied amounts in the TurnRecord so the log can say
  "industry +6 → +2 (at cap: sufficiency needed)". Never fail the whole card for one
  capped sector.

## Knowledge-tree modifiers (applied at init, never mid-run)

Knowledge nodes are **catalog and state patches** in `data/knowledge.json`, applied by
`RunState.new_from_worldgen()` before turn 1 — mid-run they would break the "cards mean
what they say" contract:

```json
{ "id": "affordable_evs",   "patch": { "card": "TRA2", "cost_money": 84 } }
{ "id": "healthy_sobriety", "patch": { "cards": ["AGR1","TRA3"], "effect_happiness": 2 } }
{ "id": "informed_public",  "grant": { "media": true } }
{ "id": "restoration_playbook", "patch": { "cards": ["SNK1","SNK2"], "reforest_years": 3 } }
{ "id": "coalition_diplomacy",  "patch": { "card": "DIP1", "cost_influence": 15 } }
{ "id": "crisis_ready",     "grant": { "adapt": 10 } }
```

`restoration_playbook` preserves each program's **total** (per_year = total / 3) per
`../Phase_1/04_Policy_Effect_Matrix.md`. Patches apply to the run's in-memory catalog
copy; `cards.json` on disk is never mutated.

## Diplomacy interactions

- `ally` effect requires the UI-supplied `target_region`; the resolver validates the
  target is NEUTRAL and not the player home, flips `ally_state`, emits `ally_changed`.
  Timeline-equivalence of any valid target is test T9 (Phase 3), re-asserted here.
- Ally loss is **not** a resolver concern — it belongs to the event step
  (`04_Society_And_Resilience_Spec.md`); the resolver only ever adds allies.
