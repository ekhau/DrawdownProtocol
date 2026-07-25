# Event Presentation Spec — The Drawdown Protocol (Phase 5)

How the resolved year hits the player: banners, log, and HUD as three synchronized
renderings of the same TurnRecord (`../Phase_4/06` — no view computes anything).
Functional/structural only; visual styling is handed off to the solarpunk-ui-artist.

## The resolution beat (after Space)

Steps 3–8 resolve instantly in the model; the presentation replays the TurnRecord as a
timed sequence, total ≤ 0.8 s, skippable by pressing Space again (`../Phase_3/04` budget):

1. **Ledger tick** (~0.2 s): HUD emissions/absorption bars move; net and warming gauge
   update; if `sink_matured > 0`, absorption bar pulses green first — growth before
   stress, deliberately.
2. **Society tick** (~0.1 s): happiness drifts with a ± cue tied to
   `co_benefit − overshoot_stress` sign.
3. **Event beats** (~0.3 s each when present): banner queue in `order` sequence
   (heat → fire → flood → social) — see anatomy below; the targeted region panel flashes
   in sync (`../Phase_3/03` FXLayer).
4. **Feedback interstitials** (rare, not skippable — see below).
5. **Band/terminal changes**: Overshoot transitions or run end (below).

Skipping jumps all values to final state and collapses beats into log lines; banners for
*this* year stay one click away in the log. Nothing exists only as animation.

## Event banner anatomy (damage first, opportunity second — always)

Non-modal banner, upper board area, one at a time from the queue:

1. **Header**: event name + targeted region name ("Mega Fire — Varkuna Basin").
2. **Damage line(s)**: final applied numbers from the TurnRecord (post-multiplier):
   "Absorption −0.9 · Money −7 · Happiness −1". When `scaled_by_resilience` and
   `mult < 1.0`, append the earned mitigation: "(resilience softened this)". Social
   crisis ally loss is its own line with the region name and breaking-ring animation
   hook (`ally_changed`).
3. **Opportunity line**, styled as the counter-beat, appearing ~0.15 s after the damage
   lines: the `teaser` from `events.json` expanded via template — "Rebuild better:
   restoration is half price while the ashes are warm." Rendered only when the event has
   a rider; heat waves end on the damage line (pillar 2 needs contrast, not boilerplate).

The damage-then-opportunity order is a hard rule (consistent with `../Phase_3/03`):
crisis, then door — never simultaneous, never reversed.

## Feedback loop interstitials (the run's dramatic beats)

`permafrost_methane`, `ocean_sink_weakening`, `amazon_dieback` fire at most once per run
and get a full-width interstitial (still ≤ 1.5 s, auto-dismissing to a pinned log line):
name, one-sentence consequence from the template ("The thaw releases what was frozen:
+2.0 emissions, permanently"), and the affected HUD element (E or A bar) marked with a
persistent scar tick for the rest of the run. These are the game teaching its thresholds;
they justify interrupting the flow exactly three times per run, maximum.

## Overshoot escalation communication

- **Crossing +1.5 °C** (band 0→1): amber vignette engages (`../Phase_3/03`), one
  interstitial ("OVERSHOOT — the world is past 1.5 °C; events intensify, sinks strain"),
  HUD warming gauge label switches to the Overshoot badge, and the event probability
  tooltip on the gauge shows the new band column from `events.json`.
- **Crossing +1.75 °C** (band 1→2): red vignette; interstitial names what is now armed
  ("permafrost threshold reached" fires this same year — the two messages chain).
- **Descending transitions** (Overshoot exit, e.g. Run A in 2091): equally loud, hopeful
  interstitial — "The world dips back below +1.5 °C." The vignette lifting is the
  emotional payoff of the whole run; it must never happen silently.
- The `warming_band_changed` signal drives all of this; the +2.0 °C line itself belongs
  to the run-end screen (`../Phase_4/05` copy mapping), not a banner.

## Log and HUD integration

- Every banner line **is** a log line (same template, same record fields); the log shows
  the year's full step order — income, action, ledger, drift, events, feedbacks, check —
  so a player can reconstruct any number by reading downward (pillar 1).
- Log entries carrying an unconsumed opportunity flag show a pin glyph until consumed or
  superseded ("window open", "restoration discount available") — the HUD's reminder that
  a door is standing open. The pin is driven by RunState flags, not by log history.
- HUD warning states: happiness < 40 marks the income line with its penalty
  ("income ×0.75 — unrest"); influence < 10 dims diplomacy affordability previews.
  Both read from the same formulas the model uses.

## Handoff notes — solarpunk-ui-artist

- Banner: damage register vs opportunity register need distinct visual voices (the
  design's threat/hope duality); opportunity must read as invitation, not reward candy.
- Interstitials: three feedback loops + Overshoot transitions (2 up, 2 down) + nothing
  else — a total vocabulary of ~7 full-width moments; they should share one family look
  with a hopeful variant for descending transitions.
- Vignette: amber/red intensities must keep the board readable underneath (it persists
  for decades of play time); it is weather, not an alarm screen.
- Scar ticks on HUD bars and the log pin glyph: small persistent marks, in-family with
  the region scar pips from `../Phase_3/03`.
- Reserve a subtle audio hook per beat type (ledger, damage, opportunity, interstitial);
  audio content itself is Phase 7 scope.
