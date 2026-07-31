# Card Presentation and Selection Spec — The Drawdown Protocol (Phase 5)

How the turn's hand of choices is presented. Functional/structural spec only: layout,
hierarchy, states, readability. Visual styling (colors, illustration, typography, card
frames) is explicitly handed off to the solarpunk-ui-artist — see handoff notes at the end.

## Reconciliation: the Project Market replaces the full Policy Board

The earlier phases presented the player's whole available pool every turn ("the Policy
Board"). **Decision, reversed for the clock race: each turn deals a MARKET of 4 offers**
(plus event injections) from the available pool — weighted by card `market_weight` ×
the city archetype's tag lean, without replacement, on its own RNG stream. A turn is a
*funding round*, not a menu: you fund what is on the table or you bank.

Randomness on the response side is made safe by three structural rules, so it stays
"decisions, not gambling" (golden rule 5):

1. **The guarantee rule** (RNG-free): if no dealt offer answers any of this turn's open
   events, the last slot is swapped for the cheapest answering card — every turn is
   interactive.
2. **Crisis windows**: an event can inject its own answer into the market
   (`bonus_card`, gated on resources at draw time), marked distinctly.
3. **Playing consumes the offer** — one funding decision per chip; the market rebuilds
   next turn.

The deck-growth rule stands (amendment A7): cards with an `unlock` condition never
appear — in the market or anywhere — until the run earns them; arriving with a banner
is the reward beat. Meta-lesson cards (`meta_unlock`) join the pool from turn 1 once
their defeat has been lived. `bonus_only` cards exist exclusively while injected.

## The Project Market (layout and hierarchy)

Bottom third of the screen, always visible during `AWAIT_ACTION`: the **market row**
(this turn's 4–6 offer chips, in deal order, bonus injections last), the **Projects
column** (the 3-turn commitments), and the explicit **"End the turn (bank funds)"**
chip. Header: "PROJECT MARKET — this turn's offers (funding one consumes it)". Cards
render as compact chips.

### Offer chip anatomy (information hierarchy, top to bottom)

1. **Name + marks**: `[CRISIS WINDOW]` when the offer was injected by an event;
   `[NN% ODDS]` when the card carries a risk block — the odds are printed on the chip,
   always (an honest bet or no bet).
2. **Cost chips**: `[80M 25I 6H]` — money always; influence/happiness only when > 0;
   `(half price!)` appended live when the fire discount applies. Rendered from
   `effective_cost_money()` — the discount price, live.
3. **Effect + reward line**: one clause per effect op (sector deltas, "lifts cap",
   reforest per-turn×turns, actor-op summaries like "Biggest bloc: −6 Gt, drift −0.3"),
   then `-> +15M +3I` style reward chips, then the card's combo/response **tags**
   (`[energy/relief]`) — tags are gameplay-critical (they answer crises and build
   combos) and always visible.
4. **State line** replaces line 3 when not freely playable (see state matrix).

### Expanded card (hover/tooltip)

Adds: id, the crisis-window note when injected, the sufficiency cap explainer, full
cost line, effect breakdown with projected post-play values ("Industry 57% → 67%"),
the risk branches ("PUSH YOUR LUCK — 35% success: …on success / on failure"), the tag
list with its role spelled out ("answer crises, build combos"), the **codex line** —
the entry's title plus, while undiscovered, the hint "(fund it once to unlock the
entry — C opens the codex)" — and `flavor` text.

## Offer state matrix (every offer visible, every reason stated)

| State | Trigger | Treatment | State line |
|---|---|---|---|
| Playable | `can_play_reason() == ok` | Full strength, interactive | — |
| Unaffordable (money) | `no_money` | Dimmed | "Need 150 money (have 112)" |
| Unaffordable (influence) | `no_influence` | Dimmed | "Need 25 influence (have 18)" |
| Unaffordable (happiness) | `no_happiness` | Dimmed | "Costs 6 happiness (have 3) — the public cannot bear it" |
| Locked (allies) | `locked_allies` | Dimmed + lock glyph slot | "Needs 2 allies (have 1)" |
| Turn limit | `turn_limit` | Whole tray dimmed | "Five cards a turn is the limit — Space to resolve" |
| Capped sector | `capped` | Dimmed + cap glyph | "Industry at 70% cap — play a sufficiency policy" |
| Already active | `media_active` | Checkmark treatment | "Active since it was funded" |
| No valid target | `no_target` | Dimmed | "No bloc left to move" (diplomacy) / "No target available" |
| Not dealt this turn | `not_in_market` | (not rendered as a chip) | "Not offered this turn" — used by any non-market surface referencing the card |
| Resolving / ended | `resolving` / `ended` | Tray inert | "Resolving…" / "The run is over" |
| Unlockable, not yet earned | `card_locked` | **Hidden** (A7) | — (arrives with its unlock banner) |

State reasons reuse `can_play_reason()` codes; the UI never re-derives eligibility.

## Multi-play flow (UI side)

The model enforces resources, the market and the 5-card cap; the UI's job is making
the turn's budget legible:

1. Click chip → `play_card()` immediately (single-click play; DIP1 opens the partner
   prompt per `../Phase_3/04`). On accept: HUD deltas, **the chip leaves the market
   row** (the offer is consumed), crisis panel refresh (an answer may have landed),
   risk verdict banner if the card rolled, combo banners, prompt updates to "N/5 cards
   played, M crises open".
2. A rejected `play_card()` shows the reason on the prompt — the UI trusts the model's
   verdict over its own cached state, always.
3. **Projects column**: each project chip shows upkeep ×turns ("[90M/turn x3]") and its
   payoff tooltip (completion effects, permanent passives, the abandon penalty); click
   launches (paying now). An ACTIVE project chip shows turns left; abandoning takes a
   second confirming click ("costs trust" on the prompt) — commitment must never break
   by accident. Concluded chips state their outcome (COMPLETED / FAILED / ABANDONED).
4. **End of turn is explicit**: Space resolves once any card was played; with zero plays
   Space asks for a confirming second press ("Resolve without acting?"), and the "End
   the turn (bank funds)" chip resolves directly. Banking is legal strategy but must
   never happen by accident.

## Companion screens (new this phase)

- **The Codex** (C toggles it): the collection of real climate solutions. Funding a
  card for the first time — in any run — unlocks its entry (`Meta.codex_seen`);
  discovered entries show the codex title + body, undiscovered show ??? so the codex
  is also a collection meter.
- **Archetype Select**: shown on first boot and reachable from the end screen ("Change
  city"); one row per archetype with tagline, strategy hint and starting-modifier
  summary. Locked archetypes state their Knowledge gate ("Capital Charter, 6 KP") —
  unlocking happens in the Knowledge tree, never here. The choice persists in Meta and
  applies to every new timeline.

## First-run onboarding hook

The tutorial (data-driven, `data/tutorial.json`) spotlights the market tray, the crisis
panel and the Projects column; the tray exposes rect anchors for the spotlight
(`project_column_rect()`); no other onboarding logic lives in this layer.

## Handoff notes — solarpunk-ui-artist

- Category icon set (8 incl. Response and Research), `sufficiency` badge, lock/cap/
  checkmark glyphs, tag chips (10 tags — small, color-coded, consistent with the crisis
  panel's answer tags), reward chips, the odds mark, the crisis-window mark, and the
  project state ribbon (available / active-N-turns / completed / failed / abandoned):
  slots and sizes are this spec's contract; imagery, palette and frame style are yours.
- Cost chips need money vs influence vs happiness instantly distinguishable by shape,
  not only color — the happiness cost is the game's sharpest dilemma and must never be
  misread as money.
- `[CRISIS WINDOW]` offers deserve a distinct chip treatment: they are the turn's
  event knocking on the door, not ordinary stock.
- Risk chips carry their odds as a first-class visual element (dice-adjacent, honest,
  not casino-glamorous).
- The **combo moment** is the game's biggest juice beat: banner + chain multiplier
  deserve a family treatment that scales with the chain (modest → jubilant), plus the
  CASCADE variant when several fire in one turn.
- The **unlock moment** (a new card materializing in the pool) is the deck-growth
  payoff — it should feel like a gift, not a patch note. The **codex discovery** beat
  is its quieter sibling.
- The waiver state ("−3 happiness (waived)") still deserves its visual moment.
- No card illustrations required for MVP; the chip must work text-first.
