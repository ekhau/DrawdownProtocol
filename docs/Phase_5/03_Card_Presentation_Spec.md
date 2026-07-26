# Card Presentation and Selection Spec — The Drawdown Protocol (Phase 5)

How the yearly hand of choices is presented. Functional/structural spec only: layout,
hierarchy, states, readability. Visual styling (colors, illustration, typography, card
frames) is explicitly handed off to the solarpunk-ui-artist — see handoff notes at the end.

## Reconciliation: full pool on the board, no drawn hand

Plan.md's original loop said "draw policy options (example: 3 cards)". **Decision,
reaffirmed for the crisis loop: the player's whole AVAILABLE pool is presented every
year ("the Policy Board"); there is no hand draw.** The randomness lives entirely on the
*pressure* side (the 3-crisis draw); the *response* side stays reliable so the player
can plan answers, combos, and projects deliberately (golden rule 5: decisions, not
gambling). Variance in what is playable comes from resources, caps, and deck growth.

**Deck-growth exception to the old "never hidden" rule (deliberate, amendment A7):**
cards with an `unlock` condition are HIDDEN until the run earns them — appearing with a
banner is the reward beat. Every *available* card still always shows its blocked state
and reason; only the not-yet-earned pool is invisible.

## The Policy Board (layout and hierarchy)

Bottom third of the screen, always visible during `AWAIT_ACTION`; seven category groups
in fixed order — Industry, Transport, Agro-economy, Sinks, Society, Diplomacy,
**Response** — plus the **Projects** column and the explicit "End the year" chip.
Cards render as compact chips.

### Card chip anatomy (information hierarchy, top to bottom)

1. **Name** + cost chips: money always; influence/happiness only when > 0. Rendered from
   `effective_cost_money()` — the fire-discount price, live.
2. **Effect + reward line**: one clause per effect op, then `-> +15M +3I` style reward
   chips, then the card's combo/response **tags** (`[energy/relief]`) — tags are
   gameplay-critical (they answer crises and build combos) and always visible.
3. **State line** replaces line 2 when not freely playable (see state matrix).

### Expanded card (hover/tooltip)

Adds: full effect breakdown with projected post-play values ("Industry 57% → 67%"),
reward details, the tag list with its role spelled out ("answer crises, build combos"),
`flavor` text, and for sufficiency cards the cap explainer.

## Card state matrix (every available card visible, every reason stated)

| State | Trigger | Treatment | State line |
|---|---|---|---|
| Playable | `can_play() == OK` | Full strength, interactive | — |
| Unaffordable (money) | `no_money` | Dimmed | "Need 150 money (have 112)" |
| Unaffordable (influence) | `no_influence` | Dimmed | "Need 25 influence (have 18)" |
| Unaffordable (happiness) | `no_happiness` | Dimmed | "Need 5 happiness (have 3)" |
| Locked (allies) | `locked_allies` | Dimmed + lock glyph slot | "Needs 2 allies (have 1)" |
| Turn limit | `turn_limit` | Whole board dimmed | "Five cards a year is the limit — Space to resolve" |
| Capped sector | `capped` | Dimmed + cap glyph | "Industry at 70% cap — play a sufficiency policy" |
| Already active | `media_active` | Checkmark treatment | "Active since it was funded" |
| No valid target | `no_target` | Dimmed | "Every nation is with you" |
| Resolving / ended | `resolving` / `ended` | Board inert | "Resolving…" / "The run is over" |
| Unlockable, not yet earned | `card_locked` | **Hidden** (A7) | — (arrives with its unlock banner) |

State reasons reuse `can_play()` codes; the UI never re-derives eligibility.

## Multi-play flow (UI side)

The model enforces resources and the 5-card cap; the UI's job is making the year's
budget legible:

1. Click chip → `play_card()` immediately (single-click play; DIP1 opens the partner
   prompt per `../Phase_3/04`). On accept: HUD deltas, crisis panel refresh (an answer
   may have landed), combo banners, prompt updates to "N/5 cards played, M crises open".
2. A rejected `play_card()` shows the reason on the prompt — the UI trusts the model's
   verdict over its own cached state, always.
3. **Projects column**: each project chip shows upkeep ×years and its payoff tooltip;
   click launches (paying now). An ACTIVE project chip shows years left; abandoning
   takes a second confirming click ("costs trust" on the prompt) — commitment must
   never break by accident.
4. **End of year is explicit**: Space resolves once any card was played; with zero plays
   Space asks for a confirming second press ("Resolve without acting?"), and the "End
   the year (bank funds)" chip resolves directly. Banking is legal strategy but must
   never happen by accident.

## First-run onboarding hook

The tutorial (data-driven, `data/tutorial.json`) spotlights the tray, the crisis panel
and the Projects column; the board exposes rect anchors for the spotlight
(`project_column_rect()`); no other onboarding logic lives in this layer.

## Handoff notes — solarpunk-ui-artist

- Category icon set (7 incl. Response), `sufficiency` badge, lock/cap/checkmark glyphs,
  tag chips (10 tags — small, color-coded, consistent with the crisis panel's answer
  tags), reward chips, and the project state ribbon (available / active-N-years /
  completed / failed): slots and sizes are this spec's contract; imagery, palette and
  frame style are yours.
- Cost chips need money vs influence vs happiness instantly distinguishable by shape,
  not only color.
- The **combo moment** is the game's biggest juice beat: banner + chain multiplier
  deserve a family treatment that scales with the chain (x1.0 modest → x2.0 jubilant).
- The **unlock moment** (a new card materializing in the tray) is the deck-growth
  payoff — it should feel like a gift, not a patch note.
- The waiver state ("−3 happiness (waived)") still deserves its visual moment.
- No card illustrations required for MVP; the chip must work text-first.
