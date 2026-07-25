# Card Catalog Data — The Drawdown Protocol (Phase 5)

The complete content of `data/cards.json` and `data/knowledge.json`: every card from
`../Phase_1/04_Policy_Effect_Matrix.md` expressed in the `../Phase_4/02` resolver schema.
This file is the content-pipeline deliverable (golden rule 15): the JSON below is the
authoritative first version, followed by the authoring template and conventions for
adding cards without touching code (golden rule 9).

**Card text is generated, never authored.** Cost chips and effect lines on cards render
from these fields through the `../Phase_4/06` template system — a card can never display
a number the sim will not apply (pillar 1). Only `name` and optional `flavor` are prose.

## `data/cards.json` (complete, 15 cards — Plan.md's 10–15 range, top end)

```json
{
  "schema_version": 1,
  "cards": [
    { "id": "IND1", "name": "Industrial Efficiency", "category": "ind",
      "cost_money": 80, "cost_influence": 0, "tags": [],
      "effects": [ { "op": "sector_progress", "sector": "ind", "amount": 8, "lifts_cap": false } ] },

    { "id": "IND2", "name": "Clean Energy Grid", "category": "ind",
      "cost_money": 150, "cost_influence": 0, "tags": [],
      "effects": [ { "op": "sector_progress", "sector": "ind", "amount": 15, "lifts_cap": false } ] },

    { "id": "IND3", "name": "Circular Economy", "category": "ind",
      "cost_money": 120, "cost_influence": 0, "tags": ["sufficiency"],
      "effects": [ { "op": "sector_progress", "sector": "ind", "amount": 10, "lifts_cap": true },
                   { "op": "happiness", "amount": 1, "waivable": false } ] },

    { "id": "TRA1", "name": "Rail & Bike Networks", "category": "tra",
      "cost_money": 80, "cost_influence": 0, "tags": ["sufficiency"],
      "effects": [ { "op": "sector_progress", "sector": "tra", "amount": 10, "lifts_cap": true },
                   { "op": "happiness", "amount": 2, "waivable": false } ] },

    { "id": "TRA2", "name": "Affordable EVs", "category": "tra",
      "cost_money": 140, "cost_influence": 0, "tags": [],
      "effects": [ { "op": "sector_progress", "sector": "tra", "amount": 15, "lifts_cap": false } ] },

    { "id": "TRA3", "name": "Walkable Cities", "category": "tra",
      "cost_money": 60, "cost_influence": 0, "tags": ["sufficiency"],
      "effects": [ { "op": "sector_progress", "sector": "tra", "amount": 8, "lifts_cap": true },
                   { "op": "happiness", "amount": -3, "waivable": true } ] },

    { "id": "AGR1", "name": "Plant-Rich Diet Campaign", "category": "agr",
      "cost_money": 60, "cost_influence": 0, "tags": ["sufficiency"],
      "effects": [ { "op": "sector_progress", "sector": "agr", "amount": 10, "lifts_cap": true },
                   { "op": "happiness", "amount": -3, "waivable": true } ] },

    { "id": "AGR2", "name": "Agroecology Transition", "category": "agr",
      "cost_money": 100, "cost_influence": 0, "tags": [],
      "effects": [ { "op": "sector_progress", "sector": "agr", "amount": 12, "lifts_cap": false },
                   { "op": "sink_now", "amount": 0.2 } ] },

    { "id": "SNK1", "name": "Reforestation Program", "category": "sink",
      "cost_money": 70, "cost_influence": 0, "tags": ["restoration"],
      "effects": [ { "op": "reforest", "per_year": 0.3, "years": 5 } ] },

    { "id": "SNK2", "name": "Peatland & Ocean Restoration", "category": "sink",
      "cost_money": 90, "cost_influence": 0, "tags": ["restoration"],
      "effects": [ { "op": "reforest", "per_year": 0.2, "years": 5 },
                   { "op": "adapt", "amount": 5 } ] },

    { "id": "ADP1", "name": "Adaptation Infrastructure", "category": "society",
      "cost_money": 90, "cost_influence": 0, "tags": [],
      "effects": [ { "op": "adapt", "amount": 15 } ] },

    { "id": "SOC1", "name": "Independent Media Fund", "category": "society",
      "cost_money": 50, "cost_influence": 0, "tags": [],
      "effects": [ { "op": "media" } ] },

    { "id": "SOC2", "name": "Global Wellbeing Fund", "category": "society",
      "cost_money": 100, "cost_influence": 0, "tags": [],
      "effects": [ { "op": "wellbeing", "amount": 3 } ] },

    { "id": "DIP1", "name": "Form Alliance", "category": "diplomacy",
      "cost_money": 50, "cost_influence": 25, "tags": [],
      "effects": [ { "op": "ally" } ] },

    { "id": "DIP2", "name": "Joint Transition Project", "category": "diplomacy",
      "cost_money": 120, "cost_influence": 15, "requires": { "allies_min": 2 }, "tags": [],
      "effects": [ { "op": "joint_progress", "amount": 6 } ] }
  ]
}
```

The `restoration` tag is new (amendment **A4**, additive): the `fire_discount` flag needs
a data-visible way to know which cards it discounts; `../Phase_4/02` hard-coded "category
is sink" — the tag replaces that special case so future discountable cards need no code.

## `data/knowledge.json` (complete, 6 nodes)

```json
{
  "schema_version": 1,
  "nodes": [
    { "id": "affordable_evs", "name": "Affordable EVs", "kp_cost": 6,
      "insight": "We know how to make electric cars people can buy.",
      "patch": { "card": "TRA2", "cost_money": 84 } },

    { "id": "healthy_sobriety", "name": "Healthy Sobriety", "kp_cost": 8,
      "insight": "Bikes and plant-rich food are good for climate and health.",
      "patch": { "cards": ["AGR1", "TRA3"], "effect_happiness": 2 } },

    { "id": "informed_public", "name": "Informed Public", "kp_cost": 8,
      "insight": "People who understand accept - even demand - sufficiency.",
      "grant": { "media": true } },

    { "id": "restoration_playbook", "name": "Restoration Playbook", "kp_cost": 5,
      "insight": "We have learned to regrow ecosystems fast.",
      "patch": { "cards": ["SNK1", "SNK2"], "reforest_years": 3 } },

    { "id": "coalition_diplomacy", "name": "Coalition Diplomacy", "kp_cost": 10,
      "insight": "Trust, once earned, is easier the next time.",
      "patch": { "card": "DIP1", "cost_influence": 15 } },

    { "id": "crisis_ready", "name": "Crisis-Ready Design", "kp_cost": 12,
      "insight": "We build for the disasters we know are coming.",
      "grant": { "adapt": 10 } }
  ]
}
```

`insight` is player-facing: the Knowledge Hub shows it as the node's one-sentence
explanation (pillar 4: every unlock must be explainable as a real insight).

## Authoring template and conventions (golden rule 15)

New card checklist — no code edits at any step:

1. Copy the template below into `cards.json`; fill fields.
2. `id`: 3-letter category prefix + ordinal (`IND4`, `SOC3`); never reuse a retired id
   (analytics history keys on it). `name`: Title Case, ≤ 24 characters (card header width).
3. `category` ∈ `ind|tra|agr|sink|society|diplomacy` (drives board grouping and icon slot).
4. `effects` use only ops from the `../Phase_4/02` enumeration — the validator rejects
   unknown ops (`05_Data_Validation_And_Content_Pipeline.md`).
5. Sufficiency cards: tag `sufficiency` AND `lifts_cap: true` on their sector op
   (validator cross-checks the pair).
6. Run the validation + fixture + corridor workflow from doc 05 before committing.

```json
{ "id": "", "name": "", "category": "",
  "cost_money": 0, "cost_influence": 0,
  "requires": {}, "tags": [],
  "flavor": "",
  "effects": [] }
```

Balance guardrails for authors (from `../Phase_1/04` watch list): progress-per-100-money
should stay in the 8–12 range for non-sufficiency sector cards; anything touching all
three sectors must cost Influence; new happiness sources must be weaker than SOC2 per
money spent before 2070.
