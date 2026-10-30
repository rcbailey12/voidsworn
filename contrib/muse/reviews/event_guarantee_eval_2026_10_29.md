# Event free-exit guarantee eval (wave 5, phase 1)

Question: Ryan ruled on Oct 28, 2026 that every fight-start event guarantees a free exit: a leave option costing nothing and risking nothing (the haven principle). This eval checks that ruling mechanically against the shipped event pool at the current checkout of voidsworn-fresh. Every claim below is traced to code read for this eval; inferences are marked INFERRED. The browser version is frozen to break-fixes only, so every failure is framed as an input to the Godot port, not as a browser patch request.

## Scope: how the code scopes "fight-start events"

The code has no choice event at a battle node. Clicking a battle, elite or boss node goes straight into the battle (campaign_run.js:93-97); clicking an event node opens the event screen (campaign_run.js:99). The event pool is the EVENTS table (data.js:275), extended by option splices (data.js:322-333) and a second pushed block (data.js:334-421). nextEvent draws from that pool at event nodes, excluding events barred for the player's faction and events already seen this run (campaign_run.js:230-231).

Two adjacent systems were checked and excluded, with reasons:

1. The events that can start a fight are EVENTS entries carrying an option whose result has a fight field. Choosing that option hands off to an elite battle (campaign_run.js:382). Exactly three events qualify: moon, tomb and haven. These three are the fight-start events in the strict sense, and they are flagged in the table.
2. Mid-battle events (BEVENTS, battle.js:22-26) are scripted occurrences rolled at battle start and announced a round ahead. They present no options at all, so there is no exit to guarantee; out of scope.

Because the ruling states a principle for events generally ("haven gains a leave option" was its example fix), the eval checks the whole drawable pool, not only the three fight-start events. The pool is 33 events (counted from the evaluated EVENTS table after all splices and pushes, via the harness loader). One of the 33, quiet, is the EVENT_FALLBACK (data.js:422): it is excluded from the normal draw and appears only when every other event has been seen (campaign_run.js:230-231).

## The test

An option counts as a guaranteed free exit only if both hold:

1. It is always enabled. The event screen disables any option whose need is unmet or whose credit cost is unaffordable (campaign_run.js:232, rendered disabled at campaign_run.js:236-237). So the exit must have no need and no cost field. The event modal offers no way out except choosing an option (campaign_run.js:236-237 renders only the option buttons), so a gated exit is not a guarantee.
2. Choosing it takes nothing and risks nothing. Its result (applied by applyOutcome, campaign_run.js:347) must contain none of: cost, dmgOne, dmgAll, dmgBig, payMod, payXp, payRelic, loseMod, gamble, ambush, a positive nemClock, a fight field, or the derelictBoard string resolver (which damages a random ship 40 percent of the time, campaign_run.js:349-350). Positive-only results (credits, experience, healing, intel, a negative nemClock) pass: the exit may pay the player; it may not charge or endanger them.

nemClock is counted as a cost because it is one in code: nemClockAdd advances the Nemesis clock, and a full clock makes the next fight the Nemesis fight or fires a raid or tithe strike that takes credits, a crippled ship, or 6 percent hull from every ship (campaign_run.js:282-291).

## Results

Events checked: 33. PASS: 26. FAIL: 7.

Fight-start subset (the three events with a fight option): moon PASS, tomb PASS, haven FAIL. Haven is the event the ruling named, and at this checkout it still has no leave option: its three options are the elite fight, a 40 credit payment, and a corsair-only recruit. A non-corsair player with under 40 credits has exactly one enabled option, the fight.

No FAIL here is a softlock: every failing event keeps at least one always-enabled option (the damaging or paying one). The failure is a forced cost, forced risk, or forced fight, which is what the ruling prohibits. INFERRED: this matches the Oct 27 program's events FAIL verdict on dead and unsafe options.

### Per-event table

Free exit column quotes the passing option's label (under 20 words) or states why none exists.

| Event | Fight option | Free exit | Verdict |
|---|---|---|---|
| derelict | no | "Leave it to the dark" (no effect) | PASS |
| beacon | no | "Ignore it" (no effect) | PASS |
| astropath | no | "Move on" (no effect) | PASS |
| merc | no | "Decline" (no effect) | PASS |
| storm | no | none: punch through damages every ship 10 percent, shield option is need-gated, way around costs 40 | FAIL |
| seer | no | "Refuse politely" (no effect) | PASS |
| wright | no | "Move on" (no effect) | PASS |
| moon | yes (chorus elite) | "Bombard from orbit and leave" (+20 captain experience) | PASS |
| shrine | no | "Leave" (no effect) | PASS |
| deserters | no | "Take them in" (+60 experience to least experienced captain); no null option, but both ungated options are costless and positive | PASS |
| cache | no | "Take the fuel and credits" (+45 credits) | PASS |
| tithe | no | "Leave it sealed" (no effect) | PASS |
| pilot | no | "Leave her to the rescue buoys" (no effect) | PASS |
| reactor | no | none: vent damages the largest ship 20 percent, rebuild is need-gated and spends a refit, drone option is deathless-only, parts cost 45 | FAIL |
| squall | no | none: ride it out damages every ship 8 percent, shield option is need-gated, go around costs 35 | FAIL |
| broker | no | "Send her away" (no effect) | PASS |
| bait | no | "Ignore it" (no effect) | PASS |
| spawn | no | "Burn them" (+20 experience for every captain) | PASS |
| lament | no | "Listen" (+15 experience for every captain) | PASS |
| tomb | yes (deathless elite) | "Chart it and leave" (+30 credits) | PASS |
| tombhome | no | "Strip it for parts instead" (+60 credits) | PASS |
| mutiny | no | none: bonus costs 50, discipline costs the flagship captain 20 experience, talk option needs a veteran captain | FAIL |
| convoy | no | "Escort them" (+45 credits) | PASS |
| battlefield | no | "Leave it to the dead" (no effect) | PASS |
| scout | no | none: hunting costs every ship 5 percent hull, torpedo option is need-gated, letting it watch advances the Nemesis clock | FAIL |
| defector | no | "Interrogate him" (reveals a Nemesis weakness) | PASS |
| dock | no | "Leave it running" (no effect) | PASS |
| well | no | "Go the long way" (no effect) | PASS |
| auction | no | "Watch and leave" (no effect) | PASS |
| saboteur | no | none: search damages a ship 10 percent, face option needs an earlier defector choice, ignoring advances the Nemesis clock twice | FAIL |
| veterans | no | "Thank her and leave" (no effect) | PASS |
| haven | yes (corsair elite) | none: raid is the fight, tribute costs 40, recruit is corsair-only | FAIL |
| quiet (fallback) | no | "Rest" (every ship repairs 10 percent) | PASS |

## Dead and unsafe options (separate flag list)

1. DEAD, unreachable: seer, "Answer her tone in glass" (data.js:327). The option requires the player's faction to be ithar (need fac ithar), but the seer event itself is barred for ithar (not list, data.js:293), and nextEvent never draws a barred event (campaign_run.js:230). No player of any faction can ever enable it: ithar never sees the event, and every other faction fails the need check (needMet, campaign_run.js:218-223). The option renders permanently disabled.
2. UNSAFE BY CONSTRUCTION: scout, "Let it watch" (data.js:386 block). Its only effect is nemClock +1 (applied at campaign_run.js:376). Pure downside, zero upside: it exists to be the leave option and it charges the Nemesis clock for leaving.
3. UNSAFE BY CONSTRUCTION: saboteur, "Ignore it" (data.js:406 block). Its only effect is nemClock +2, the same forced loss at double size.

Risk options noted but not flagged as dead, because each carries an upside: derelict "Send boarding parties" (40 percent chance a random ship takes 25 percent hull damage, campaign_run.js:349-350), beacon "Seize the cargo" (+100 credits against an ambush flag and nemClock +1, data.js:325, ambush applied at campaign_run.js:364), bait "Go in loud and take the cargo" (+80 credits against an ambush flag), shrine "Chalk your names and hope" (coin flip, campaign_run.js:362).

Content references were checked for the options that name content: the ships harrow (merc), c_raider (haven) and d_scythe (tombhome) all exist in HULLS, and the module damcon (spawn) exists in MODULES, all verified through the harness loader. applyOutcome also guards the modId and shipRaw lookups before applying them (campaign_run.js:371-372). No option in the pool references missing content.

## What the Godot port should take from this

1. Add a leave option to haven (the ruling's own example) and to the other six FAIL events: storm, reactor, squall, mutiny, scout, saboteur. The pattern already exists in the pool: a no-effect "leave" option is the house style in 16 of the passing events.
2. Delete or re-gate the seer glass option: as shipped it can never fire. Moving it to an event ithar can actually draw, or changing its need, both fix it; leaving it is a dead button in the port too.
3. Reprice the two pure-cost ignore options (scout, saboteur) or give them a compensating effect. INFERRED: a leave that advances the Nemesis clock reads as a bug to a player who was promised a free exit, even where the fiction intends pressure.

## Limitations

- Static eval: the pool, options and outcome branches were read from data.js and campaign_run.js and enumerated through the harness loader (game_loader.js against voidsworn-fresh). No event was played through the UI, so presentation issues (for example, whether a disabled exit is visibly explained) are out of scope.
- Availability analysis assumes a worst-case fleet and purse (no carrier, no shields, no refits, under 35 credits, no veteran captain, wrong faction) because a guarantee has to hold for the weakest legal state. With a stronger fleet, several FAIL events gain a free gated option; the guarantee, not the typical case, is what the ruling sets.
- The faction variant texts (the v field) change titles and body text only; options are shared, so variants do not affect the verdicts. Verified on the eventScreen merge at campaign_run.js:234.
- Whether nemClock pressure counts as a "cost" under the ruling is a reading of the ruling's "costing nothing and risking nothing": the eval counts it, and says so in the test definition above, so the chair can re-run the count under a different reading. Under a reading that excludes nemClock, scout and saboteur would pass and the count would be 28 PASS, 5 FAIL; haven would still fail.
