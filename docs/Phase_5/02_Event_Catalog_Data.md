# Event Catalog Data — The Drawdown Protocol (Phase 5)

The complete content of `data/events.json`: 4 extreme events + 3 feedback loops = **7
catalog entries** (within Plan.md's 6–10 range). Numbers are exactly
`../Phase_1/03_Event_Probability_Table.md`; resolution order and damage semantics are
exactly `../Phase_4/04_Society_And_Resilience_Spec.md` — this doc adds no new rules, it
expresses the established ones as data.

## `data/events.json` (complete)

```json
{
  "schema_version": 1,
  "events": [
    { "id": "heat_wave", "name": "Heat Wave", "kind": "extreme", "order": 10,
      "probabilities": [0.10, 0.25, 0.40],
      "target": { "tags_any": [], "weight_boost": { "arid": 2.0 } },
      "scaled_by_resilience": true,
      "damages": { "happiness": 3, "money": 20 },
      "opportunity": null },

    { "id": "mega_fire", "name": "Mega Fire", "kind": "extreme", "order": 20,
      "probabilities": [0.05, 0.15, 0.25],
      "target": { "tags_any": ["forested", "arid"], "weight_boost": {} },
      "scaled_by_resilience": true,
      "damages": { "absorption": 1.0, "money": 10, "happiness": 1 },
      "counters": { "fires": 1 },
      "scar": "burned",
      "opportunity": { "set_flag": "fire_discount",
                       "teaser": "restoration half price" } },

    { "id": "flood_tsunami", "name": "Flood & Tsunami", "kind": "extreme", "order": 30,
      "probabilities": [0.05, 0.10, 0.15],
      "target": { "tags_any": ["coastal"], "weight_boost": {} },
      "scaled_by_resilience": true,
      "damages": { "money": 40, "happiness": 3 },
      "scar": "flooded",
      "opportunity": { "set_flag": "flood_rebuild",
                       "teaser": "transport rebuilt better next year" } },

    { "id": "social_crisis", "name": "Social Crisis", "kind": "extreme", "order": 40,
      "probability_formula": { "base": 0.05, "base_low_happiness": 0.25,
                               "happiness_threshold": 40,
                               "band_scale": [1.0, 1.25, 1.5],
                               "media_multiplier": 0.5 },
      "target": { "tags_any": [], "weight_boost": { "ally": 2.0 } },
      "scaled_by_resilience": false,
      "damages": { "influence": 10, "money": 20, "ally_lost": 1 },
      "opportunity": { "set_flag": "window",
                       "teaser": "a window for change is open" } },

    { "id": "permafrost_methane", "name": "Permafrost Methane Release",
      "kind": "feedback", "order": 50, "one_shot": true,
      "trigger": { "temp_gte": 1.75 },
      "effect": { "e_extra": 2.0 } },

    { "id": "ocean_sink_weakening", "name": "Ocean Sink Weakening",
      "kind": "feedback", "order": 60, "one_shot": true,
      "trigger": { "temp_gte": 1.90 },
      "effect": { "absorption": -2.0 } },

    { "id": "amazon_dieback", "name": "Amazon Dieback",
      "kind": "feedback", "order": 70, "one_shot": true,
      "trigger": { "fires_gte": 3 },
      "effect": { "absorption": -3.0 } }
  ]
}
```

## Schema semantics (binding on the implementation)

- **`order`** is the resolution order within step 6 (extremes 10–40) and step 7
  (feedbacks 50–70). The resolver iterates by ascending `order`; the RNG consumption
  contract of `../Phase_4/01` (trigger roll, then target draw, per event) follows this
  sequence. Renumbering `order` is a determinism-breaking change — validator warns.
- **`probabilities`** — per-year chance by warming band [stable, Overshoot I,
  Overshoot II], rolled against `band(T_new)`. Exactly three ascending values
  (escalation past +1.5 °C is a validator rule, not a convention).
- **`probability_formula`** — used only by `social_crisis`; fields map 1:1 to
  `social_crisis_p()` in `../Phase_4/04`. An event has `probabilities` or
  `probability_formula`, never both.
- **`target`** — flavor targeting per `../Phase_3/02`: `tags_any` filters eligible
  regions (empty = all); `weight_boost` multiplies draw weight for regions matching the
  key (`"ally"` is a pseudo-tag matching `ally_state == ALLY`). Targeting never changes
  magnitudes.
- **`scaled_by_resilience`** — `true`: damages ×`damage_mult` (frozen at step-6 entry);
  `false`: flat. Social crisis is deliberately flat — seawalls do not stop politics
  (`../Phase_1/03`; making that visible in data prevents a well-meaning "fix").
- **`damages`** — positive numbers; the resolver applies them as subtractions with the
  established floors (money/happiness/influence ≥ 0, absorption ≥ `A_FLOOR`).
  `ally_lost` uses the targeting rule: the targeted ally if any, else highest-affinity
  ally, no-op at 0 allies.
- **`opportunity.set_flag`** — one of the CONSUMABLE_FLAGs from `../Phase_4/02`.
  `teaser` is the short player-facing promise, rendered in the opportunity beat
  (`04_Event_Presentation_Spec.md`); full copy lives in the log templates.
- **`scar`** — region scar id appended as `&"<scar>_<year>"` (Phase 3 schema).
- **Feedbacks**: `trigger` conditions are checked in `order` at step 7 with post-event
  state; `one_shot` entries record their trigger year for the debug overlay's
  "armed / triggered" display (`../Phase_3/05`).

## Content notes for future events

Plan.md allows up to 10 entries; three slots are intentionally left open. Candidates
parked in the backlog (not designed here): crop failure (agro-targeted, agr-progress
rider), climate migration compact (social-positive event — an opportunity-first entry),
glacier loss (water-stress pressure). Any new extreme event must ship with an
opportunity rider or a written justification for its absence (pillar 2 is a validator
*warning*, human-overridable, since heat_wave legitimately has none as pure drumbeat).
