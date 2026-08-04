# Claude's Ideas — Tension, Difficulty, Addictiveness

Proposals from a design review (2026-08-04) responding to: *"the game is too easy and lacks the tension, fun, and addictiveness a rogue-like should have."* Grounded in [01_Design_Brief.md](01_Design_Brief.md), [02_MVP_Spec.md](02_MVP_Spec.md), [04_Rebalance_Plan.md](04_Rebalance_Plan.md), and [Design_History.md](Design_History.md).

## Why it feels easy and flat (diagnosis)

The rebalance pass fixed the *money* faucet, but three structural things still drain tension:

1. **The game is fully predictable.** Effects are deterministic, the clock moves linearly, and the ◆ diamond tells you at all times exactly whether you're winning. There is never *doubt*, and doubt is where tension lives. Slay the Spire is tense because you don't know what the boss will do to your draw luck; here, a mid-run player can see the ending 10 turns out.
2. **There are no spikes.** The thermometer is a slow ramp with no moments where everything is on the line — no elites, no bosses, no deadlines inside the run. Band scaling is a slope, not a wall.
3. **Rich turns have no opportunity cost.** You can buy *any number* of cards per turn. So a good turn is a shopping spree, not a painful pick-one decision. Money is the only constraint, and constraints that are only economic get solved.
4. **Runs resemble each other.** No breakthroughs, no city archetypes, no meta-progression yet (all designed, all out of MVP scope) — so the "what will this run give me?" slot-machine pull that drives Hades/StS addictiveness isn't in the build.

## Tension

### 1. Tipping points — make the boss hit back

The thermometer is "the boss" but it never attacks. Add 2–3 temperature thresholds that fire permanent world-scars when crossed:

- **+1.70° Permafrost thaw** — gross +2 perm
- **+1.85° Amazon dieback** — absorption −2 perm
- **+1.95° Ice-sheet instability** — crisis band C locked in

Draw them as skull markers on the climate bar so the player sees them coming for years. This converts the late game from a grind into a race with compounding punishment, produces "lost by one turn" stories, and is nearly free in the current architecture — a climate-phase trigger applying existing effect atoms, all in `config.json`. It's the "tipping-point bosses" idea already parked in [Design_History.md](Design_History.md).

### 2. Agenda slots — cap purchases per turn

Parliament passes at most 2 bills a year (temptations and gambles could be slot-free or not — playtest it). Suddenly every turn is "which two of these four?", rerolls matter, and stockpiling money doesn't trivially convert into progress. Probably the single cheapest tension fix in the list: one turn rule plus a UI counter. Also fixes the residue of the 2038-shopping-spree problem at the decision level instead of the price level.

### 3. The forecast — telegraph next year's crisis

Show a one-line weather-service hint at end of turn ("El Niño building — next year's crisis will be climate, one band worse"). Into the Breach proved telegraphing *creates* tension rather than relieving it: the dread is in seeing it coming and deciding whether to brace or push. Cheap: peek the top of the crisis deck.

### 4. Crisis chains — consequences with a fuse

Some responses spawn a follow-up crisis n years later (Ration water → Farmers' revolt in 2 years; Let it burn → Ash floods next spring). Mortgage choices become genuinely scary rather than just arithmetically worse, and runs get narrative arcs. Data-driven: a `spawns: {crisis_id, delay}` field on a response.

## Difficulty

### 5. Era exams — a boss checkpoint at each act gate

At 2038 and 2044, a scripted "COP Review" scores your structural net against a printed target; miss it and you take a real penalty (sanctions: −2$/turn for 3 years, or a band bump). Right now era transitions are *gifts* (new cards, free refresh). Making them exams gives the run internal deadlines, so you can be losing at 2037 in a way you feel — currently the only deadline is the far end of the run.

### 6. Victory tiers — make Drawdown the true ending

Today you win the instant structural net ≤ 0, which is anticlimactic and stops the game right when Act III's toys unlock. Split it:

- **Net Zero** — survival ending, run graded B
- **Drawdown** — true ending: go net-*negative* and pull the thermometer back below ~+1.8° before 2060

The game is literally named after the act nobody currently plays. Adds difficulty for good players without making run one harder, and gives Act III a climax.

### 7. Protocol levels — the ascension ladder

After a first win, unlock stacking modifiers (start at +1.55°, drift-down 4%/yr, an extra temptation always in the market, double-crisis years…). Already mapped in [01_Design_Brief.md](01_Design_Brief.md); this is the standard rogue-lite answer to "too easy for me specifically" and it's config-only. The note in [random_ideas.md](random_ideas.md) — "winnable in one run by a hardcore gamer, but very difficult" — is exactly what an ascension ladder preserves: run one stays learnable, mastery always has a wall to climb.

## Fun & addictiveness

### 8. Breakthroughs — build the boon system

The highest fun-per-effort item on the designed-but-unbuilt list. Every ~4 years, pick 1 of 3 run-shaping gifts rolled per run ("Battery collapse: Transport/Industry cards −2$", "Green hydrogen: 3 new cards join the pool"). This is the mechanism that makes run #12 feel different from run #11, which is the core of "one more run". Medium effort: a new choice modal on a year trigger plus a JSON pool.

### 9. Insights — even a thin meta-progression loop

The post-mortem currently ends in… nothing. Award 1–3 insights keyed to *how* the run ended, spendable on unlocks: new cards into the pool, then the second starting city, then a starting breakthrough. Even three unlockables transform the restart moment from "again?" to "I want to see the next thing." Ship it thin; grow it later.

### 10. Score the timeline, keep the ledger

Win/lose is binary, so once players win, the game is "done." Score every run (year, temp margin, final popularity, combos found, zero-mortgage bonus) and keep a persistent **timeline ledger** — "Timeline #14: best yet." Chasing a better timeline is what keeps rogue-lites alive after the first win, and it's diegetically perfect for the Drawdown Institute fantasy. Cheap: the post-mortem already has all the data.

### 11. (Bigger swing, flagged not pushed) A real hand

[random_ideas.md](random_ideas.md) mentions "hand of 4 cards with a shop, or Hades boons, or both." Moving from market-only to draw-a-hand deckbuilding would add the adaptation-under-variance that rogue-likes run on — but it's a genre pivot touching everything; per golden rule #11 (one major system per milestone), exhaust ideas 1–3 (which add tension *within* the current market model) before considering it.

## Where to start

One system per milestone, riskiest question first:

1. **Agenda slots + tipping points** — both ~a day, both JSON-heavy, and together they attack tension from both ends (scarcity per turn, dread per run).
2. **Run the harness with new targets** — clean bot should drop toward ~45–50%, and slow runs should now *lose late* rather than win late.
3. **Breakthroughs** — run identity.
4. **Insights + timeline ledger** — the restart pull.

Victory tiers and era exams slot in whenever a milestone needs a difficulty beat rather than a content beat.
