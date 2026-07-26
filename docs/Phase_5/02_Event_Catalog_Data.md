# Event Catalog Data — The Drawdown Protocol (Phase 5)

The content of `data/events.json` (schema_version 2): the **crisis deck** — 7 crises +
3 opportunities — plus 3 feedback loops = 13 catalog entries. Numbers are exactly
`../Phase_1/03_Event_Probability_Table.md`; draw and resolution semantics are exactly
`../Phase_4/01` and `../Phase_4/04` — this doc adds no new rules, it expresses the
established ones as data. The shipped JSON in `src/data/events.json` is authoritative.

## Schema by kind

```json
{ "id": "mega_fire", "name": "Mega Fire", "kind": "crisis", "order": 20,
  "weights": [0.6, 1.2, 1.8],
  "target": { "tags_any": ["forested", "arid"], "weight_boost": {} },
  "scaled_by_resilience": true,
  "damages": { "absorption": 0.8, "money": 10, "happiness": 1 },
  "counters": { "fires": 1 },
  "scar": "burned",
  "response": { "tags_any": ["forest", "relief"], "rewards": { "money": 8 } },
  "opportunity": { "set_flag": "fire_discount", "teaser": "restoration half price" } }

{ "id": "climate_summit", "name": "Climate Summit", "kind": "opportunity", "order": 50,
  "weights": [1.2, 1.0, 0.8],
  "target": { "tags_any": [], "weight_boost": {} },
  "response": { "tags_any": ["treaty"], "rewards": { "influence": 8, "money": 15 } } }

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
  and step-6/7 resolution order. Renumbering is a determinism-breaking change (E8,
  unimplemented — needs version history).
- **`weights`** — per-band draw weight [stable, Overshoot I, Overshoot II]. Three values
  ≥ 0; **crisis weights must be non-decreasing** (Overshoot escalates, E3); opportunity
  weights may fall. Every year draws exactly `CRISES_PER_TURN` (3) entries without
  replacement; weights are relative shares of the remaining pool.
- **`weight_mods`** — optional social modifiers (used by `social_crisis`):
  `low_happiness_mult` below `happiness_threshold`, `media_mult` while media is active.
- **`response`** — the answer contract (required on every drawable entry, E9):
  `tags_any` (⊆ the card tag vocabulary; must intersect at least one STARTING card's
  tags — E10, no unanswerable crises) and `rewards` (granted immediately on the answer).
- **`target`** — flavor targeting per `../Phase_3/02`, drawn at draw time so the crisis
  panel can name the region all year: `tags_any` filters eligible regions (empty = all);
  `weight_boost` multiplies draw weight (`"ally"` is a pseudo-tag). Targeting never
  changes magnitudes.
- **`scaled_by_resilience`** — `true`: unanswered damages ×`damage_mult` (frozen at
  step-6 entry); `false`: flat. Social crises and energy crunches are deliberately
  flat — seawalls do not stop politics or markets (making that visible in data prevents
  a well-meaning "fix").
- **`damages`** — positive numbers; applied as subtractions with the established floors
  **only when the crisis goes unanswered**. `ally_lost` uses the targeting rule: the
  targeted ally if any, else highest-affinity ally, no-op at 0 allies.
- **`counters` / `scar` / `opportunity`** — applied **only on a real strike**: a
  contained fire neither burns nor discounts; an answered flood rebuilds nothing.
  `opportunity.set_flag` is one of the CONSUMABLE_FLAGs (E6); `teaser` is the short
  player-facing promise rendered in the opportunity beat.
- **Feedbacks**: unchanged one-shot threshold events; `trigger` conditions checked in
  `order` at step 7 with post-strike state; the fires counter counts **unanswered**
  fires only.

## Content notes for future events

The deck dilutes: adding an entry lowers every other entry's draw share — author weights
relative to the totals in `../Phase_1/03` (band-0 total ≈ 7.8, band-2 ≈ 13.5). Any new
crisis must ship with response tags answerable from the starting pool (E10) and SHOULD
carry a rider or a written justification for its absence (pillar 2). Candidates parked
in the backlog: glacier loss (water-stress pressure), climate migration compact
(opportunity-first entry), coral collapse (coast/absorption pressure).
