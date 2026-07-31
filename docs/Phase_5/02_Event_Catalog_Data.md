# Event Catalog Data — The Drawdown Protocol (Phase 5)

The content of `data/events.json` (schema_version 3): the **crisis deck** — 7 crises +
3 opportunities — plus 3 feedback loops = 13 catalog entries. Numbers are exactly
`../Phase_1/03_Event_Probability_Table.md`; draw and resolution semantics are exactly
`../Phase_4/01` and `../Phase_4/04` — this doc adds no new rules, it expresses the
established ones as data. Two event powers are new with the clock race: **on-draw
emission spikes** and **bonus-card market injections**. The shipped JSON in
`src/data/events.json` is authoritative.

## Schema by kind

```json
{ "id": "heat_wave", "name": "Record Heat Wave", "kind": "crisis", "order": 15,
  "weights": [0.8, 1.4, 2.0],
  "target": { "tags_any": [], "weight_boost": { "arid": 1.5 } },
  "scaled_by_resilience": true,
  "on_draw": { "e_extra": 1.0 },
  "bonus_card": { "card": "HWP1", "requires": { "happiness_gte": 40 } },
  "damages": { "happiness": 6, "money": 40 },
  "response": { "tags_any": ["health", "relief"],
                "rewards": { "influence": 4, "happiness": 2 } },
  "opportunity": null }

{ "id": "climate_summit", "name": "Treaty Conference", "kind": "opportunity", "order": 50,
  "weights": [1.2, 1.0, 0.8],
  "target": { "tags_any": [], "weight_boost": {} },
  "response": { "tags_any": ["treaty"], "rewards": { "influence": 10, "money": 30 } } }

{ "id": "permafrost_methane", "name": "Permafrost Methane Release",
  "kind": "feedback", "order": 90, "one_shot": true,
  "trigger": { "temp_gte": 1.75 },
  "effect": { "e_extra": 2.0 } }
```

## Schema semantics (binding on the implementation)

- **`kind`** — `crisis` (drawable; damages when unanswered), `opportunity` (drawable;
  pure upside, no damages/scar/counters — validator E5), `feedback` (threshold-triggered,
  never drawn). Order ranges: crises < 50, opportunities 50–89, feedbacks ≥ 90 (E1).
- **`order`** — draw-pool iteration order (weighted pick runs over ascending `order`)
  and step-6/7 resolution order. Renumbering is a determinism-breaking change.
- **`weights`** — per-band draw weight [stable, Overshoot I, Overshoot II]. Three values
  ≥ 0; **crisis weights must be non-decreasing** (Overshoot escalates, E3); opportunity
  weights may fall. Every turn draws exactly `CRISES_PER_TURN` (3) entries without
  replacement; weights are relative shares of the remaining pool.
- **`weight_mods`** — optional social modifiers (used by `social_crisis`):
  `low_happiness_mult` (×3) below `happiness_threshold` (40), `media_mult` (×0.5)
  while media is active.
- **`on_draw`** — the crisis-window mechanic, side 1 (E7, crises only, keys ⊆
  `{e_extra}`): the spike bakes into `e_extra` **at draw time** and is remembered on
  the drawn entry. Answering the crisis this turn dissipates the spike before the
  ledger is read (step 3); ignoring it makes the spike permanent. The record heat wave
  (+1.0 Gt/turn) is the shipped example — the turn's question is no longer only "can
  you afford the damage" but "can you afford the emissions".
- **`bonus_card`** — the crisis-window mechanic, side 2 (E8): a drawn event injects
  its named card into this turn's market when the resource gate holds **at draw time**
  (`requires` keys ⊆ `happiness_gte` / `money_gte` / `influence_gte`; an ungated
  injection draws a warning). The injected card is typically `bonus_only` — it exists
  nowhere else (heat_wave → HWP1 Heatwave Response Plan while happiness ≥ 40). A
  crisis can thus *bring its own answer*, priced and gated.
- **`response`** — the answer contract (required on every drawable entry, E9):
  `tags_any` (⊆ the card tag vocabulary; must intersect at least one STARTING card's
  tags — E10, no unanswerable crises; "starting" excludes unlockable, meta-lesson and
  bonus-only cards) and `rewards` (granted immediately on the answer).
- **`target`** — flavor targeting per `../Phase_3/02`, drawn at draw time so the crisis
  panel can name the region all turn: `tags_any` filters eligible regions (empty = all);
  `weight_boost` multiplies draw weight (`"ally"` is a pseudo-tag). Targeting never
  changes magnitudes.
- **`scaled_by_resilience`** — `true`: unanswered damages ×`damage_mult` (frozen at
  step-6 entry); `false`: flat. Social crises and energy crunches are deliberately
  flat — seawalls do not stop politics or markets (making that visible in data prevents
  a well-meaning "fix").
- **`damages`** — positive numbers, retuned for the 5-year turn (a mega fire now takes
  1.6 absorption, 20 money, 2 happiness); applied as subtractions with the established
  floors **only when the crisis goes unanswered**. `ally_lost` uses the targeting rule:
  the targeted ally if any, else highest-affinity ally, no-op at 0 allies.
- **`counters` / `scar` / `opportunity`** — applied **only on a real strike**: a
  contained fire neither burns nor discounts; an answered flood rebuilds nothing.
  `opportunity.set_flag` is one of the CONSUMABLE_FLAGs (E6); `teaser` is the short
  player-facing promise rendered in the opportunity beat.
- **Feedbacks**: unchanged one-shot threshold events; `trigger` conditions
  (`temp_gte` / `fires_gte`) checked in `order` at step 7 with post-strike state; the
  fires counter counts **unanswered** fires only. Effects: permafrost `e_extra` +2.0,
  ocean sink `absorption` −2.0 (T ≥ 1.90), Amazon dieback `absorption` −3.0 (3 fires).

## Content notes for future events

The deck dilutes: adding an entry lowers every other entry's draw share — author weights
relative to the totals in `../Phase_1/03` (band-0 total ≈ 7.8, band-2 ≈ 13.5). Any new
crisis must ship with response tags answerable from the starting pool (E10) and SHOULD
carry a rider, an on-draw spike, or a written justification for their absence
(pillar 2: threats are feedback loops, and feedback loops compound while ignored). An
event that injects a `bonus_card` should gate it on the resource the crisis strains —
the gate is the fiction ("a demoralized city cannot staff cooling centers"). Candidates
parked in the backlog: glacier loss (water-stress pressure), climate migration compact
(opportunity-first entry), coral collapse (coast/absorption pressure).
