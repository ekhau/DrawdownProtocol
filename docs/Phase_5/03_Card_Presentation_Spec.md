# Card Presentation and Selection Spec — The Drawdown Protocol (Phase 5)

How the yearly choice is presented. Functional/structural spec only: layout, hierarchy,
states, readability. Visual styling (colors, illustration, typography, card frames) is
explicitly handed off to the solarpunk-ui-artist — see handoff notes at the end.

## Reconciliation: full catalog, not a drawn hand

Plan.md's core loop says "draw policy options (example: 3 cards)". The Phase 1 balance
model, its three seed-2030 fixtures, and the scripted strategies all assume **free choice
from the full catalog** — an assumption Phase 1 left implicit. **Decision: the MVP
presents the full 15-card catalog every year ("the Policy Board"); there is no draw.**

Rationale:
- **The fantasy is planning, not gambling.** The concept's promise is "spend money
  wisely"; a draw would make the wise plan unavailable by luck. Meaningful-decision
  density comes from trade-offs, not variance (golden rule 5).
- **Variance is already covered.** Replayability comes from the procgen world and the
  event system (Phase 0 pillar 4); draw luck would stack randomness on the *response*
  side, where the player needs reliability to counter the random *pressure* side.
- **15 cards in 6 categories is scannable.** Below the complexity threshold where a hand
  becomes a readability tool (golden rule 6).
- **The fixtures stay valid.** A drawn hand would invalidate every Phase 1 table and the
  T13-P4 regression anchor.

**Amendment A5 (flagged, not silent):** this records the free-choice assumption as
balance assumption #22, to be folded into `../Phase_1/06_Assumptions.md` at its next
revision (that file is out of scope to edit in this phase).
**Deviation from Plan.md**, accepted: "draw policy options" is replaced by "present the
Policy Board". A drawn-hand variant ("Advisor's Shortlist", 3 cards via a new
`STREAM_HAND = 5`) is parked as a post-MVP experiment; adopting it requires balance
re-validation and new fixtures — a design event, not a toggle.

## The Policy Board (layout and hierarchy)

Bottom third of the screen, always visible during `AWAIT_ACTION`; six category groups in
fixed order — Industry, Transport, Agro-economy, Sinks, Society, Diplomacy — matching the
board/HUD vocabulary. Cards render as compact chips; one chip expands on hover/focus.

### Card chip anatomy (information hierarchy, top to bottom)

1. **Name** (≤ 24 chars) + category icon slot + `sufficiency` badge slot when tagged.
2. **Cost chips**: money always; influence only when > 0 (DIP1/DIP2). Rendered from
   `effective_cost_money()` — the fire-discount price, live (`../Phase_4/02` single
   source of truth for what the player reads).
3. **Effect lines**: one line per effect op, generated from data via the template system
   (`../Phase_4/06`) — e.g. `sector_progress` → "Transport +10%", `reforest` →
   "+0.3 absorption/yr for 5 yrs", `ally` → "+1 ally: +20 money & +1 influence yearly".
   Negative waivable happiness renders with its waiver status live:
   "−3 happiness (waived: media)" when applicable.
4. **State line** (only when not freely playable — see state matrix).

### Expanded card (hover 0.3 s or focus)

Adds: full effect breakdown with projected post-play values ("Industry 57% → 67%",
computed via the resolver's requested-vs-applied preview — a joint project on a capped
sector shows "+6 → +2, at cap"), `flavor` text, and for sufficiency cards the cap
explainer: "Lifts this sector's ceiling from 70% to 100%."

## Card state matrix (every state visible, every reason stated)

| State | Trigger | Treatment | State line |
|---|---|---|---|
| Playable | `can_play() == OK` | Full strength, interactive | — |
| Unaffordable (money) | check 2 fails | Dimmed, cost chip emphasized | "Need 150 money (have 112)" |
| Unaffordable (influence) | check 3 | Dimmed, influence chip emphasized | "Need 25 influence (have 18)" |
| Locked (allies) | check 4 | Dimmed + lock glyph slot | "Needs 2 allies (have 1)" |
| Capped sector | check 7 | Dimmed + cap glyph | "Industry at 70% cap — play a sufficiency policy" |
| Already active | media dup (check 6) | Checkmark treatment, non-interactive | "Active since 2031" |
| No valid target | DIP1, no neutrals / 6 allies | Dimmed | "Every nation is with you" |
| Year resolved | `action_taken` | Whole board dimmed | Played card gets "Enacted 2047" ribbon |

Cards are **never hidden** (Plan.md: "prerequisite visibility"): a locked card is a goal
the player can see — DIP2 visible from turn 1 teaches that alliances unlock scale.
State reasons reuse `can_play()` error codes; the UI never re-derives eligibility.

## Selection and the one-card-per-year lock (UI side)

Model-side lock already exists (`../Phase_4/01`); the UI's job is making it legible:

1. Click chip → expanded card with **Enact** button (and **Choose partner…** flow for
   DIP1, per `../Phase_3/04`'s modal prompt). Esc/right-click collapses.
2. Enact → `play_card()`; on accept: ribbon on the chip, rest of board dims to the
   "Year resolved" state, HUD pillar deltas animate, prompt switches to
   "Space — resolve the year".
3. **Pass is explicit**: a "Bank funds" chip sits at the board's end, always playable;
   pressing Space with no action first shows a one-time inline confirm on the prompt
   ("Resolve without acting? Space again to confirm") — passing is legal strategy
   (Phase 1 runs bank 15–19 years) but must never happen by accident.
4. A rejected `play_card()` (race with state, bug) flashes the state line — the UI
   trusts the model's verdict over its own cached state, always.

## First-run onboarding hook (Plan.md Phase 7 delivers it; the seam is here)

The board supports a `highlight_filter` (set of card ids) the tutorial can set — no
other onboarding logic lives in this layer.

## Handoff notes — solarpunk-ui-artist

- Category icon set (6), `sufficiency` badge, lock/cap/checkmark glyphs, "Enacted"
  ribbon: slots and sizes fixed by this spec (chip ≈ 180×92 @1080p, expanded ≈ 320×420);
  imagery, palette, and frame style are yours — including how "dimmed" reads without
  losing legibility (contrast floor: state lines readable at all states).
- Cost chips need money vs influence instantly distinguishable by shape, not only color.
- The waiver state ("−3 happiness (waived)") deserves a visual moment — it is the
  media/window payoff loop made visible.
- Reserve a treatment for `sufficiency` cards as a family — they are the game's thesis.
- No card illustrations required for MVP; the chip must work text-first.
