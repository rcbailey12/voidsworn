# Evidence pack: issue 202, playtest checklist for the next build

This pack is the complete evidence base for the job. Work only from this pack. Where this pack and your prior knowledge disagree, this pack wins.

## 1. The job

Board issue 202 (owner: muse). The owner plays the game himself from a double-click build and judges by what he sees. The last build he played is g2_pt_d03ac22. Since that build, work has merged to main, and the next playtest build will be made from current main. This job writes the checklist he follows in that next build.

Deliverable, two parts:
1. A one-page checklist in plain words that the owner can follow while playing: what changed since g2_pt_d03ac22; where to find each change in the game (which screen, which battle, which camera view); what good looks like and what bad looks like for each change; and a short list of what to screenshot.
2. A list of everything that has merged or been decided that will NOT show up in the next build yet, with the reason for each.

## 2. Hard constraints

- The checklist is for the owner, who is not a coder. Plain words, no jargon, no issue numbers or PR numbers in the checklist itself (the not-showing list may carry them, in a separate clearly-marked section for the record). If a technical term is unavoidable, explain it in the same sentence.
- One page for the checklist part: short lines, grouped by where he goes in the game, in the order he would meet them. Do not pad it. The not-showing list is separate and may run longer.
- Every item must trace to section 3 or 4 of this pack. Do not invent changes, screens or behaviours. If you cannot say where a change is found in the game from this pack, say so rather than guessing.
- Pure ASCII. No em dashes anywhere.
- No human-hour estimates. Times, where needed, in the build's own terms (the build takes about 20 minutes to make, section 5).
- Fiction is space ships, never naval.

## 3. What changed since the last build (verified: commit delta d03ac22 to current main, 36 commits)

The last playtest build, g2_pt_d03ac22, was built from commit d03ac22. LOOP.md records its state in the owner's own terms: it has "no deaths 2, no station detail yet". The commits that landed on main after it, grouped by whether the player can see them:

Visible in the next build:

V1. Deaths 2 (issue 167, PR 185): broken ship pieces now have solid insides, and ship deaths are louder and more space-real. Before this, a broken piece could read as an empty shell. Where it shows: in any battle where a ship breaks apart or dies, close up on the wreckage. Good: broken pieces look solid inside, deaths feel big. Bad: any broken piece that still looks hollow or empty inside.

V2. Wreckage fields from real ship pieces (issue 60, PR 143; owner ruling R107 merged it after a look): battlefield debris and wreckage now use pieces derived from actual ships instead of generic chunks. Where it shows: battle backdrops and wreckage fields during fights. Good: debris reads as recognisable ship wreckage. Bad: debris that still looks like plain rocks or generic blocks.

V3. Station shapes (issue 183, PR 190; rulings R94 and R100): the two stations (fleet station and refinery) gained their detail additions: the shapes the station brief specified, additions only, nothing moved or removed. Where it shows: station screens and any view with a station in it. Good: stations have visibly more structure than the plain shapes of the last build. Bad: stations that still read as a few plain blocks stuck together.

V4. Station repaint (issue 195, PR 197; rulings R104, R105): the stations were repainted to the readable-paint standard because the earlier white and tan panels read as plastic toy blocks. Where it shows: the same station views as V3. Good: plates read as metal, value steps separate the parts, no plastic look. Bad: bright toy-like panels, or paint so dark and flat that the new shapes disappear.

Not visible, although merged:

N1. Pyre-Barge round 6 (issue 187, PR 196) merged as tools only (R108). The hand-built V3 and the AI-built V1 exist as workshop builds and comparison sheets; neither is in the game's ship set. The Barge in the next build is the same one as the last build.
N2. Pyre-Barge round 5 (issue 163, PR 186) also merged as tools only; its paint was rejected by the owner (R103, "cluttered messy mix"). Nothing of it is in the game.
N3. Documents and research merged in the same window (the readable-paint standard, PR 191; the backlog check, PR 192; FINDINGS updates, PR 182; board bookkeeping in LOOP.md). No game change.

Already in the last build, so NOT new (do not list these as changes): automatic squadrons (carriers launch at battle start, wings fight on their own), space-real deaths round 1, weapon hits on the flipbook system, the campaign map fixes for engine trails and for solid asteroid and wreck hexes, admiral balance (Thale's fleet composition, Ashgrove's extra Warden). These were in g2_pt_d03ac22 or earlier.

## 4. Decided or in flight, but not in the next build

- Station surface detail pass (issue 199, ruling R109): the owner ruled the repainted stations still look "super plain and just like regular shapes" and ordered way more surface detail. That job has not run yet (it runs after the round 7 job). So in the next build the stations have new shapes and new paint, but NOT the extra surface detail. The owner should not judge the stations as finished.
- Pyre-Barge round 7 (issue 198, ruling R108): the V3 hull gets its detail and outline features back (dishes, scoops, gun barrels, folded claws, chains, rocket clusters) with the red-brown plate paint, compared against V1 with the same paint. Not run yet; its result is a comparison sheet for the owner's pick, and only after that pick does a new Barge enter the game (the breakable Barge job, issue 169, waits on it too).
- Surface detail standard (issue 200): a written standard for how much detail ships and stations must carry. It is a document that future build jobs follow; nothing in the game changes directly. (Its five open picks were ruled by the owner on Nov 5, 2026: all chair picks adopted.)
- Nemesis redesign (issues 120 to 122, rulings R85 and R101): the hunter is drawn per story point, commanders are per faction, and the adopted commander voice lines (NEM_VOICE) get wired in. None of it is built yet. In the next build the Nemesis behaves exactly as in the last build: one hunter for the whole run.
- Test checks for the Nemesis redesign (issue 201): a review document, no game change.
- Progression steps, debrief screen, nebulas and ion storms, rocky and terran planets (issues 24, 26, 27, 29, 30, 92, 139, 140): queued behind the jobs above; none built.
- Tripo per-part test (issue 193) and the five ship-pipeline options (issue 194): parked proposals, nothing built, and 193 additionally waits on the owner's call because Tripo is a paid service and the house rule is free and local tools only.

## 5. How the next build reaches the owner (from LOOP.md, playtest exe recipe)

The build is made from current main on the board side (about 20 minutes), lands on the owner's PC in Downloads\voidsworn_test, and starts by double-clicking play_godot.bat (HANDOFF.md; play_godot_safe.bat is the fallback if it will not start). The checklist may tell him to start the game that way, but must not invent menu paths beyond what this pack states: a run is title screen, pick an admiral and faction, campaign map, battles from map nodes, station and shipyard screens at their map nodes, the Nemesis shown on the campaign map and met in battle.

## 6. What your report must contain

1. The one-page checklist (part 1 of the deliverable), structured: a start line (how to launch, what build this is), then the checks grouped by where he goes (battles first, then stations), each check as: what to look at, what good looks like, what bad looks like. Then the screenshot list: the few shots that carry the decisions (a broken ship close up, a wreckage field, each station, anything that looks wrong).
2. The not-showing list (part 2), one line per item with its reason, from pack sections 3 (N1 to N3) and 4.
3. A fidelity note: anything in sections 3 to 5 you could not turn into a check or a plain-words line, and why. No owner questions are required for this job; if you believe one is unavoidable, at most one, with your pick.

## Leg prompts

### Blind Rey leg (writer, runs first, pack only)

You are a blind writer leg for Voidsworn board issue 202. Work only from the attached PACK.md. Write the complete deliverable described in pack sections 1 and 6, as your reply: the one-page plain-words playtest checklist, the not-showing list, and the fidelity note. Follow the pack's hard constraints exactly. Do not reply with a preamble or a plan.

### DeepSeek leg (writer)

You are a writer leg for Voidsworn board issue 202. Work only from the attached PACK.md; it is your complete evidence base, and where it disagrees with your prior knowledge, the pack wins. Write the complete deliverable described in pack sections 1 and 6: the one-page plain-words playtest checklist, the not-showing list, and the fidelity note. Follow the pack's hard constraints exactly: plain words, no jargon in the checklist, no issue or PR numbers in the checklist itself, pure ASCII, no em dashes. Do not reply with a preamble or a plan.

### Qwen leg (writer)

You are a writer leg for Voidsworn board issue 202. Work only from the attached PACK.md; it is your complete evidence base, and where it disagrees with your prior knowledge, the pack wins. Write the complete deliverable described in pack sections 1 and 6: the one-page plain-words playtest checklist, the not-showing list, and the fidelity note. Follow the pack's hard constraints exactly: plain words, no jargon in the checklist, no issue or PR numbers in the checklist itself, pure ASCII, no em dashes. End your report with the line END OF CHECKLIST. Do not reply with a preamble or a plan.

### Argon leg (review only, runs after the writer legs)

You are a review leg for Voidsworn board issue 202. Attached: PACK.md (the evidence pack) and the writer legs (rey_blind.md, deepseek.md, qwen.md). Your job is fidelity review only. For each writer leg: (1) check every checklist item and not-showing item against PACK.md sections 3 to 5, quoting the exact conflicting text from both the leg and the pack; (2) flag any game change the pack records that the leg omitted, and any change the leg lists that the pack does not record; (3) flag any jargon, issue numbers or PR numbers inside the checklist part, and any em dashes; (4) flag any place where the leg states where a change is found in the game more specifically than the pack supports. End with an exact cut list: the specific items the chair should not adopt, each with the reason. Do not write a replacement checklist of your own. Do not reply with a preamble or a plan.
