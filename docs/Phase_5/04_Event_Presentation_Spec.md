# Event Presentation Spec — The Drawdown Protocol (Phase 5)

How the crisis year hits the player: the crisis panel, banners, log, and HUD as
synchronized renderings of the same state and TurnRecord (`../Phase_4/06` — no view
computes anything). Functional/structural only; visual styling is handed off to the
solarpunk-ui-artist.

## The crisis panel (new — the turn's question, always visible)

Top of the right dock, one chip per drawn event, live all year:

1. **Header**: event name + targeted region ("Drought — Varkuna Basin") + state word:
   OPEN (crisis, rust) / OPEN (opportunity, gold) / ANSWERED · SEIZED (green).
2. **Threat line** (open crises): final catalog damages — "if ignored: −15 funds,
   −2 happiness, −0.3 absorption". Opportunities show "if seized: +30 funds".
3. **Answer line**: the response tags ("answers: water/food") — the same tag chips the
   cards wear; this pairing IS the turn's puzzle, so it must be scannable in one glance.
4. On an answer: the chip flips to ANSWERED with the answering card's name; a short
   containment banner plays ("Drought in Varkuna answered: reserves hold. Returns: …").

## The play beats (during the action phase)

Immediate feedback per play (golden rule 8), in this order when several fire at once:

1. **HUD deltas** (costs paid, rewards granted) and the plays counter ("3/5").
2. **Answer beat**: green banner + crisis chip flip, when the card answered something.
3. **Combo beat**: gold banner — "COMBO x7 — Green Corridor! +33 funds" — with the
   chain-scaled numbers from the record; the HUD chain label updates in the same frame.
4. **Unlock beat**: hope banner — "New policy available: Mutual Aid Network" — and the
   card materializes in the tray.
5. **Project beats**: launch (log line), completion (hope banner: "PROJECT COMPLETE"),
   failure/abandon (damage banner: "Partners remember").

## The resolution beat (after Space)

Steps 3–8 resolve instantly in the model; the presentation replays the TurnRecord as a
banner queue, skippable by pressing Space again:

1. **Ledger tick**: HUD emissions/absorption/net and warming gauge update; if
   `sink_matured > 0`, absorption pulses green first — growth before stress, deliberately.
2. **Strike beats** (unanswered crises, draw order): banner anatomy below; the targeted
   region panel flashes in sync.
3. **Missed-opportunity lines** go to the log only ("The summit convenes without you") —
   regret, not punishment; no banner.
4. **Feedback interstitials** (rare): full-width, at most three per run.
5. **Band/terminal changes**: Overshoot transitions or run end.

## Strike banner anatomy (damage first, opportunity second — always)

1. **Header**: event name + targeted region ("Mega Fire — Varkuna Basin").
2. **Damage line(s)**: final applied numbers from the TurnRecord (post-multiplier):
   "Absorption −0.7 · Funds −8 · Happiness −1". When `scaled_by_resilience` and
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

- **Crossing +1.5 °C** (band 0→1): amber vignette, one interstitial ("OVERSHOOT — events
  intensify; sinks strain"), gauge badge; the crisis panel's draw is visibly heavier
  from next year (that, not a tooltip, is how the escalation teaches).
- **Crossing +1.75 °C** (band 1→2): red vignette; interstitial names what is now armed.
- **Descending transitions**: equally loud, hopeful interstitials — the vignette lifting
  is the emotional payoff of the whole run; it must never happen silently.
- The `warming_band_changed` signal drives all of this; the +2.0 °C line itself belongs
  to the run-end screen.

## Log and HUD integration

- Every banner line **is** a log line (same template, same record fields); the log shows
  the year's full step order — income, project events, the crisis draw ("Crises this
  year: …"), each play with its effects/returns/answer/combos, ledger, drift, strikes,
  unlocks, feedbacks, check — so a player can reconstruct any number by reading downward
  (pillar 1).
- HUD warning states: happiness < 40 marks the income line with its penalty; the chain
  label shows the current combo multiplier; open crises count sits in the prompt.

## Handoff notes — solarpunk-ui-artist

- The crisis panel needs three instantly-readable states (open-threat, open-gift,
  answered) sharing one chip family; answered must read as relief, not merely "done".
- Banner registers: damage / opportunity / combo / hope now form a four-voice family;
  combo banners scale emotionally with the chain.
- Interstitials: three feedback loops + Overshoot transitions + nothing else.
- Vignette: amber/red must keep the board readable underneath; it is weather, not an
  alarm screen.
- Reserve a subtle audio hook per beat type (ledger, damage, answer, combo, unlock,
  interstitial); audio content itself is Phase 7 scope.
