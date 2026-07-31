# Event Presentation Spec — The Drawdown Protocol (Phase 5)

How the crisis turn hits the player: the crisis panel, the world's blocs panel,
banners, log, and HUD as synchronized renderings of the same state and TurnRecord
(`../Phase_4/06` — no view computes anything). Functional/structural only; visual
styling is handed off to the solarpunk-ui-artist.

## The crisis panel (the turn's question, always visible)

Top of the right dock, one chip per drawn event, live all turn:

1. **Header**: event name + targeted region ("Drought — Varkuna Basin") + state word:
   OPEN (crisis, rust) / OPEN (opportunity, gold) / ANSWERED · SEIZED (green).
2. **Threat line** (open crises): final catalog damages — "if ignored: −30 funds,
   −4 happiness, −0.6 absorption". Opportunities show "if seized: +50 funds". A crisis
   with an on-draw spike states it: "+1.0 Gt/yr baked in unless answered".
3. **Answer line**: the response tags ("answers: water/food") — the same tag chips the
   market offers wear; this pairing IS the turn's puzzle, so it must be scannable in
   one glance.
4. On an answer: the chip flips to ANSWERED with the answering card's name; a short
   containment banner plays ("Drought in Varkuna answered: reserves hold. Returns: …").

## The world's blocs panel (the other half of the ledger)

Below the crisis panel in the right dock: one line per world actor — name, current
emissions, drift arrow (up in rust while trend > 0, flat "at floor" note otherwise) —
closed by the summary line "World N Gt, drift +X/turn (allies damp Y)". Tooltip states
the lever plainly: Fund a Transition cuts the biggest bloc, an Emissions Treaty bends
the steepest, every ally damps the combined drift by 0.2/turn. Funding DIP4/DIP5 must
visibly move the named bloc's number and arrow in the same frame — the world curve is
a first-class opponent, not a background constant.

## The turn-start beats (after the draw, before the player acts)

1. **On-draw spike** and **bonus-card** banners: "Record Heat Wave bakes in: +1.0
   Gt/yr unless answered this turn" / "Crisis window: Heatwave Response Plan joins
   this turn's market" — the spike and the injected offer are announced together; the
   pairing is the mechanic.
2. **Summit-turn interstitial**, on scheduled turns only: "SUMMIT THIS TURN — Global
   Stocktake 2045: end the turn with net ≤ 45 or the world loses faith." The HUD's
   next-summit line has carried the target since the previous COP resolved — the
   interstitial is the deadline, not the first notice.

## The play beats (during the action phase)

Immediate feedback per play (golden rule 8), in this order when several fire at once:

1. **HUD deltas** (costs paid, rewards granted) and the plays counter ("3/5").
2. **Answer beat**: green banner + crisis chip flip, when the card answered something
   (this also visibly clears the crisis's on-draw spike from the forecast).
3. **Risk beat**: the roll's verdict, loudly and honestly — hope banner "BREAKTHROUGH —
   Fusion Moonshot pays off (35% odds). +60 funds…" or damage banner "Fusion Moonshot
   fails (35% odds). The bet is lost."
4. **Combo beat**: gold banner — "COMBO x7 — Green Corridor! +44 funds" — with the
   chain-scaled numbers from the record; the HUD chain label updates in the same frame.
   When 2+ combos fire in one turn, the **CASCADE banner** follows and the climate
   clock gauge plays its flash-plunge — the engine moment.
5. **Unlock beat**: hope banner — "New policy available: Mutual Aid Network". The
   **codex discovery** beat ("CODEX — Heat action plans, press C") plays on a card's
   first-ever funding.
6. **Project beats**: launch (log line), completion (hope banner: "PROJECT COMPLETE"),
   failure/abandon (damage banner: "Partners remember").

## The resolution beat (after Space)

Steps 3–8 resolve instantly in the model; the presentation replays the TurnRecord as a
banner queue, skippable by pressing Space again:

1. **Ledger tick**: HUD ledger ("City E + World E | A | net") and the **climate clock**
   update; if `sink_matured > 0`, absorption pulses green first — growth before
   stress, deliberately. On the first net ≤ 0 turn the **curve-bent banner** plays
   ("THE CURVE BENDS — the world absorbs more than it emits") with the clock's
   flash-plunge — and that turn is also the win.
2. **Strike beats** (unanswered crises, draw order): banner anatomy below; the targeted
   region panel flashes in sync. An ignored on-draw spike logs its permanence
   ("bakes in").
3. **Missed-opportunity lines** go to the log only ("The Treaty Conference convenes
   without you") — regret, not punishment; no banner.
4. **Summit verdict banner**, on scheduled turns: hope register when met ("SUMMIT
   Global Stocktake 2045: target met (net 41 vs 45). Returns: +80 funds…", plus the
   clock flash-plunge), damage register when missed (the penalty note spelled out).
5. **Feedback interstitials** (rare): full-width, at most three per run.
6. **World-drift line** (log): "The world's blocs emit N Gt and drift +X/turn" — the
   blocs panel updates to the post-advance curves the next turn opens on.
7. **Band/terminal changes**: Overshoot transitions or run end (the end screen renders
   the ending template plus the post-mortem's pivotal-turn analysis).

## Strike banner anatomy (damage first, opportunity second — always)

1. **Header**: event name + targeted region ("Mega Fire — Varkuna Basin").
2. **Damage line(s)**: final applied numbers from the TurnRecord (post-multiplier):
   "Absorption −1.3 · Funds −16 · Happiness −1.6". When `scaled_by_resilience` and
   `mult < 1.0`, append the earned mitigation: "(resilience softened this)". Social
   crisis ally loss is its own line with the region name.
3. **Opportunity line**, styled as the counter-beat: the rider's `teaser` expanded via
   template — "Rebuild better: restoration is half price while the ashes are warm."
   Only a crisis that actually struck opens its door; answered crises already had their
   green beat at play time.

The damage-then-opportunity order is a hard rule: crisis, then door — never
simultaneous, never reversed.

## Feedback loop interstitials (the run's dramatic beats)

Unchanged: `permafrost_methane`, `ocean_sink_weakening`, `amazon_dieback` fire at most
once per run and get a full-width interstitial (auto-dismissing to a pinned log line);
they justify interrupting the flow exactly three times per run, maximum.

## Overshoot escalation communication

- **Crossing +1.5 °C** (band 0→1): amber vignette, one interstitial ("OVERSHOOT — the
  world passes +1.5 C. Events intensify; sinks strain"), gauge badge; the crisis
  panel's draw is visibly heavier from next turn (that, not a tooltip, is how the
  escalation teaches).
- **Crossing +1.75 °C** (band 1→2): red vignette; interstitial names what is now armed.
- **Descending transitions**: equally loud, hopeful interstitials ("The world dips back
  below +1.5 C. The air clears.") — the vignette lifting is the emotional payoff of the
  whole run; it must never happen silently.
- The `warming_band_changed` signal drives all of this; the +2.0 °C line itself belongs
  to the run-end screen — but the **climate clock gauge** carries it continuously:
  percent-to-tipping, the next-turn forecast tick (the do-nothing projection), and the
  sparkline history of the curve the player is bending.

## Log and HUD integration

- Every banner line **is** a log line (same template, same record fields); the log shows
  the turn's full step order — income, project events, the draw ("Events this turn:
  …"), on-draw spikes, bonus-card windows, each play with its effects/risk/returns/
  answer/combos, ledger (city + world), clock, drift, strikes, summit verdict, unlocks,
  feedbacks, world drift, check — so a player can reconstruct any number by reading
  downward (pillar 1).
- HUD warning states: happiness < 40 marks the income line with its penalty; the chain
  label shows the current combo multiplier; open crises count sits in the prompt; the
  top bar carries the turn counter ("Turn N/15"), the global ledger, the clock gauge
  and the next-summit line ("SUMMIT turn 8 — Accord of 2065: net ≤ 25 (now +38)").

## Handoff notes — solarpunk-ui-artist

- The crisis panel needs three instantly-readable states (open-threat, open-gift,
  answered) sharing one chip family; answered must read as relief, not merely "done".
  Spiked crises need their "baked-in emissions" mark.
- The blocs panel is the world's face: four lines, drift arrows, floor states — it
  must read as an opponent's board, and a funded transition must land as a visible hit.
- Banner registers: damage / opportunity / combo / hope now carry more traffic (risk
  verdicts, summit verdicts, cascade, curve-bent) — one four-voice family, no new
  voices; combo banners scale emotionally with the chain.
- The climate clock gauge is the game's face: percent, forecast tick, sparkline, and
  the flash-plunge celebration (cascade / summit met / curve bent) are its four jobs.
- Interstitials: three feedback loops + Overshoot transitions + summit turns + nothing
  else.
- Vignette: amber/red must keep the board readable underneath; it is weather, not an
  alarm screen.
- Reserve a subtle audio hook per beat type (ledger, damage, answer, risk, combo,
  cascade, summit, unlock, interstitial, curve-bent); audio content itself is Phase 7
  scope.
