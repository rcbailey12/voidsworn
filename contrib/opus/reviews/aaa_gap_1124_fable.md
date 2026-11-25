I cannot push from this seat, so the full text for `contrib/opus/reviews/aaa_gap_1124_fable.md` is below. Whoever saves it should commit on `work/issue-2016-opus` with "Refs #2016". I have not read the Neon or Astra audits.

---

# AAA gap audit, Fable seat (issue 2016)

Main at 9689628f. Written Nov 24 2026 from 22 still pictures and 5 documents. I could not run the game, watch a clip or hear a sound. Every claim is marked OBSERVED (I can see it in a named picture) or INFERRED (from the documents, or a guess from a still).

Sizes: S = 1 agent run, M = 2 to 4, L = 5 or more.

## 1. Top 10 gaps, ranked

### 1. The big moments do not read at the camera the game is played at
- **Area:** effects, camera, graphics. Partly planned.
- **Today:**
  - Picture 15: one Chorus ship is about 70 pixels wide in a 1266 pixel frame. OBSERVED.
  - Picture 22, left: the Brood-sac is about a tenth of its panel width at camera 170. OBSERVED.
  - Picture 17: a Directorate cruiser dies at camera 170. Over six frames I see a dark bite grow at the stern, with no flash, fireball, ring or drifting pieces. OBSERVED, with a limit: this strip is from WRECK5c, which the Board did not send to Ryan, and the frames may miss the flash.
  - Picture 16 (PC, Max, "dense"): I cannot find a fleet. The only ship-like shapes are a small cluster at the top centre. OBSERVED.
  - Picture 18: the same kind of event at camera 26 has real depth. The good work lives at camera 26, but PROGRAM.md says the game is judged at 170.
- **Benchmark:** BattleTech cuts to a close action camera for each attack and kill, then returns. In Battlefleet Gothic: Armada 2 a dying cruiser throws a blast and ring you can read from the top of the zoom.
- **Fix:** For each big moment, decide whether it reads by camera (a cut-in) or by size (a flash and ring sized to the screen, not to the ship). Add a pass or fail row to the look bench: "in one small camera 170 cell, can you tell which ship died and how". This stays inside R186 (flame capped at 0.70 s) and the R193 flash counter.
- **Planned part:** 1406 and PR 1964 (ships read at the battle camera), 1404 (cut-ins), 1779 (kill-cam), PR 1737 (wrecks). None of those titles covers sizing effects for camera 170.
- **Size:** M. **Confidence:** OBSERVED in the frames; INFERRED for the game in general.

### 2. The menus never show the ships
- **Area:** graphics, UI.
- **Today:**
  - Pictures 2 to 6: each starting fleet is a row of tiny pale blobs on a black page. OBSERVED.
  - Picture 10: the shipyard sells and upgrades ships as text cards with no ship picture. OBSERVED.
  - Picture 8: progression is a text list. OBSERVED.
  - Pictures 12, 18, 21 and 22 show the game owns good ship models. The player only meets them small, in battle.
- **Benchmark:** BattleTech's Mech Bay puts the mech in front of you while you refit it. EVE's fitting window has the ship in the middle. Armada 2's fleet screen shows each hull.
- **Fix:** Put a lit, slowly turning model of the selected ship in the shipyard, and the faction flagship behind each faction header. Replace the blob rows with clean class silhouettes rendered from the real models.
- **Size:** M. **Confidence:** OBSERVED.

### 3. The captains you can lose have no face
- **Area:** progression.
- **Today:** Picture 1 promises "Every hull you lose stays lost, and so does its captain." In Picture 10 a captain is one line of text: "Lieutenant Elsbeth Kade, 0/30 experience to Commander, No perks yet." OBSERVED. I saw no portrait, callsign or history for captains anywhere. INFERRED beyond Picture 10.
- **Benchmark:** BattleTech pilots have a portrait, a callsign, a voice, skills and a memorial wall. That is why losing one hurts.
- **Fix:** Give every captain a small portrait, a callsign and one trait line. Show them on the ship card, in battle when selected, and in the Hall of the fallen.
- **Planned part:** portrait issues 1887 and 1897 cover admirals only.
- **Size:** M. **Confidence:** OBSERVED on the card.

### 4. The 24 admirals share six command abilities
- **Area:** tactical depth, faction identity. Partly planned (1453).
- **Today:** In Pictures 2 to 7 every admiral command I can read (23 of 24) is one of six templates under a new name. OBSERVED.
  - The free extra volley appears on five admirals: Kassar, Voice of the Deep, Umbra Vessane, Saro and Vex.
  - The extra wing plus bonus attack appears on five.
  - The "+30% damage this round" command appears on four.
  - The 25% repair, the "+2 movement" burn and the damage wall appear on three each.
  - Passives are mostly flat percentages that also repeat. The squadron bonus is on four factions. OBSERVED.
- **Benchmark:** BattleTech skills change what a unit can do (Sensor Lock, Bulwark, Multi-Target). Armada 2 factions play by different rules, not different numbers.
- **Fix:** Give each faction commands that only it could have, built on its battle rule. Those rules (Feed, Archive restore, Prism charge) are already distinct.
- **Planned part:** 1453 names "admiral command twists" and own Glasswright and Chorus abilities. It does not name passives. These captures may be older than parts of 1453, so a fresh desk capture should settle it.
- **Size:** M. **Confidence:** OBSERVED in the pictures; INFERRED that main still matches.

### 5. Key screens are walls of small text
- **Area:** UI/UX.
- **Today:**
  - Pictures 2 to 6: four admiral cards of about 70 small words each, with no icons and no emphasis on numbers. OBSERVED.
  - Picture 10: stats run as plain sentences ("Shields 40, +10/turn Armor 20% Speed 3 Turns 2 Evasion 5"). Weapons read "4×6, range 5". The right third of the screen is empty. OBSERVED.
  - "Mastery 0/8 0/6: next alternate fleet" explains nothing. OBSERVED.
- **Benchmark:** BattleTech shows weapons and skills as icons with numbers in fixed columns, and detail on hover. Sins of a Solar Empire II leans on icons and tooltips.
- **Fix:** One headline and one icon per ability, with full text on hover. Put ship stats in a fixed grid with small bars. Show the stat change before the player buys Mk II.
- **Size:** M. **Confidence:** OBSERVED.

### 6. Performance is proven on one high-end PC
- **Area:** loading and performance.
- **Today:** Every number in LOOP.md comes from Ryan's PC, an RTX 5080 per FINDINGS B-17. GPU frame time is good there: about 5.4 ms at 4K against a 12.5 ms budget. I found no frame-time or load proof on a mid-range card. INFERRED.
- **Benchmark:** EVE Online runs from weak laptops to 4K rigs on a wide settings ladder. Sins II holds large fleets on ordinary hardware.
- **Fix:** Run the same frame-time and load benches at lower presets on one mid-range card. Write a minimum spec from the result.
- **Planned part:** 1436 covers a sky-bake fallback and a safe-mode launcher, not a proof.
- **Size:** M. **Confidence:** INFERRED.

### 7. Ships cover each other on the board
- **Area:** motion, readability. Ties to the pending altitude bands (1582, PR 1874 per LOOP).
- **Today:**
  - Picture 12: the selected red frigate and the dark spindle ship overlap. OBSERVED.
  - Picture 11: escorts above the plane read as "far and small", not "high". Only a thin drop line gives the hex. OBSERVED.
  - Picture 14: at the low angle the fleet collapses into one band. OBSERVED.
- **Benchmark:** Armada 2 keeps every ship on one plane with a clear base. EVE's tactical overlay ties each ship to the plane with a stalk and a ring.
- **Fix:** Light the hex under any raised or lowered ship. Fade the nearer hull when two hulls cover each other. Stop the camera before the Picture 14 angle if a player can reach it.
- **Size:** S to M. **Confidence:** OBSERVED on bench captures.

### 8. Nebula hexes look like flat tinted patches
- **Area:** graphics.
- **Today:** Picture 16 (PC, Max, after PR 1301): the purple and teal clouds are blotchy and grainy beside a clean sky. OBSERVED. Pictures 9 and 20 show cloud shapes that follow hex edges, but those are cloud renders. OBSERVED, weak. A still cannot show depth, so "flat" is INFERRED.
- **Benchmark:** EVE's volumetric gas clouds. Armada 2's layered gas clouds with lightning inside.
- **Fix:** Build clouds from several soft layers at different heights with slow drift. Prove it on one PC capture at camera 170 with ships inside.
- **Planned part:** 1766 covers the sky, not the board clouds.
- **Size:** M. **Confidence:** OBSERVED for texture; INFERRED for depth.

### 9. No hull or shield read on the ships themselves
- **Area:** UI/UX.
- **Today:** In Pictures 11 and 12 the only per-ship marks are rings and brackets in teal, purple and orange. I see no hull bar, shield bar, class mark or name. OBSERVED. Picture 11 was labelled as having the HUD, but I see no panels in it. If the bench hides these marks, this item drops. INFERRED for the real game.
- **Benchmark:** BattleTech draws armour and structure bars over every mech. Armada 2 puts hull and shield bars and status icons beside each ship.
- **Fix:** A small plate per ship with hull, shield (Glacier blue per R210) and a class mark, readable at camera 170.
- **Size:** S if missing. **Confidence:** INFERRED.

### 10. Nobody speaks
- **Area:** sound.
- **Today:** Admiral lines exist as text only on the desk (Pictures 2 to 6). OBSERVED. No open issue title names voiced lines. INFERRED.
- **Benchmark:** Armada 2 captains answer every order in their faction's voice. BattleTech pilots call hits and kills.
- **Fix:** A small set of voiced lines per faction (order taken, ship lost, flagship hail), added as one wave of the sound redo.
- **Size:** M. **Confidence:** INFERRED. I heard nothing.

## 2. Further gaps by area

Several areas have fewer than three rows. I had no clips or sound, and I will not invent gaps.

### Graphics

| Gap | Today (picture) | Benchmark | Fix | Size | Confidence |
|---|---|---|---|---|---|
| Progression has no art | Picture 8: six cores shown as one coloured letter each; two thirds of the screen black | BattleTech's Argo screen shows what you upgraded | One emblem per core; show the protocols | S to M | OBSERVED |
| Board markers look like debug lines | Pictures 11, 12: thin flat rings and brackets in three styles, beside detailed hulls | Armada 2 bases and arcs are soft and part of the scene | One marker family with a soft glow, drawn under hulls | S | OBSERVED (bench) |
| Ice planet scribbles | Picture 19, after row: red-brown squiggles on the ice planet | EVE planets hold up at any distance | Check a PC capture of the merged ice planet first | S | OBSERVED on an older software render; INFERRED for main |

### Effects

| Gap | Today (picture) | Benchmark | Fix | Size | Confidence |
|---|---|---|---|---|---|
| Engine jets are soft smears | Pictures 12, 13: blurred bars; factions differ in colour, little in shape | EVE trails have a bright core and a tapering ribbon | Add a hot core and taper; give each faction a shape | S | OBSERVED, low resolution |
| A breach gives off no heat or light | Picture 18: the hole opens dark; plates beside it never light up | Armada 2 hull hits glow and light the hull | Short hot-edge glow that cools; not flame, so R186 holds. Check after PR 1997 | S to M | OBSERVED; partly planned (1741) |
| A hurt ship shows little at camera 170 | Picture 17: frames 2 to 6 show only a dark notch | EVE hulls smoke and spark as structure drops | Venting gas, sparks, flickering lights sized for 170 | M | OBSERVED; partly planned (1693, 1741) |

### Physics and motion

| Gap | Today (picture) | Benchmark | Fix | Size | Confidence |
|---|---|---|---|---|---|
| Breakups do not fire reliably | Picture 17: hull stays one still piece. LOOP: three-piece breakup "engaged on 1 of 10 rows" | Armada 2 hulks break and drift every time | Gate PR 1737 on the breakup firing in every bench row | S | OBSERVED and INFERRED; planned |
| Low camera is unreadable | Picture 14: all ships in one thin band | Sins II stays readable at any zoom | Limit the pitch, or switch to icons at flat angles | S | OBSERVED (bench camera) |

### UI/UX

| Gap | Today (picture) | Benchmark | Fix | Size | Confidence |
|---|---|---|---|---|---|
| Run options drawer is see-through | Picture 7: card text and a ghost button show through the panel | Any shipped menu | Solid panel; dim the page behind | S | OBSERVED |
| A test switch faces the player | Picture 7: "Test new battle maps, faster ships and longer gun ranges" is the only option | BattleTech's start screen lists named difficulty choices | Move it to a dev menu, or name it as a mode | S | OBSERVED |
| Shipyard buttons are tiny and risky | Picture 10: "Repair", "Mk II" and "Decommission" sit together, small, with no preview | BattleTech confirms refits with cost and changes | Larger buttons; Decommission apart, with a confirm | S | OBSERVED |
| One green line breaks the palette | Pictures 2 to 6: the admiral quote is green on every faction | n/a | Use the faction accent or ember | S | OBSERVED |
| Faction name differs | Picture 2 says "Hegemony Navy"; FLEET.md says "Meridian Directorate" | n/a | Pick one; recapture | S | OBSERVED mismatch; INFERRED which is current |

### Loading and performance

| Gap | Today (source) | Benchmark | Fix | Size | Confidence |
|---|---|---|---|---|---|
| No total load budget | LOOP: Planets V2 added about 5 s cold and 2 s warm to battle load; a 20 s cover is held | Sins II; BattleTech is the warning here | Set one battle-load ceiling and gate look PRs on it, as frame time is gated | S | INFERRED |
| Fixes queue behind one PR | PR titles and LOOP: 1975, 1976, 1980, 1852, 1960 and 1950 wait on PR 1445; eight LOAD runs reported failed, none passed | n/a | Land the loading work in smaller parts so stutter fixes are not held | M | INFERRED |

### Sound and music

All INFERRED. I heard nothing, and the redo (1752) is in flight.

| Gap | Today (source) | Benchmark | Fix | Size | Confidence |
|---|---|---|---|---|---|
| No full-battle mix proof | LOOP reviews sounds as single takes on listening pages | EVE limits and ranks voices so big fights stay clear | One clip of a 20-ship round, judged for clutter | S | INFERRED |
| Faction music identity not named | 1752 names multi-stem music; M1 and M2 are calm and hot pairs | Armada 2 scores each faction differently | One motif or stem per faction | M | INFERRED |

### Progression and campaign

| Gap | Today (picture) | Benchmark | Fix | Size | Confidence |
|---|---|---|---|---|---|
| Ship growth is one flat step | Picture 10: "A Mark upgrade adds 20% hull and shields and 15% damage" | Armada 2 ships earn upgrade picks | Offer a choice of two upgrades at each Mark | M | OBSERVED |
| Fitting looks shallow | Picture 10: fixed weapon lists, one "Empty refit slot" per ship | BattleTech MechLab | Check a fresh capture first; quick-fit (1913) merged after this picture | M | INFERRED |
| Core sync rewards are abstract | Picture 8: "Its protocols are rare more often" | BattleTech's Argo upgrades name what you get | Show the actual protocols each tier opens (no grind added) | S | OBSERVED |

### Tactical depth and AI

| Gap | Today (source) | Benchmark | Fix | Size | Confidence |
|---|---|---|---|---|---|
| AI judged by bots, not by eye | LOOP: balance comes from sim runs; the sim bot broke twice (1632, 1992) | BattleTech's AI was tuned against human play | Record three AI turns per faction; a critic checks focus fire, flagship care and use of the faction rule | S | INFERRED |

### Anything else

| Gap | Today (source) | Fix | Size | Confidence |
|---|---|---|---|---|
| No picture shows the whole game at once | Of my 22 pictures none has ships, sky, HUD and weapons together. Picture 11 is ships on black; Picture 16 is sky with no readable fleet | One fixed "state of the game" sheet of ten real screens per day. PROGRAM.md's "one finished battle" capture is the goal | S | OBSERVED for my set |
| Only Ryan plays it | LOOP names a playtest build for Ryan and no outside players | A small outside playtest once 1403 lands | S to M | INFERRED |

## 3. What already holds up

- **Hull modelling up close.** The plating in Picture 18, the Chorus and Eclipse hulls in Picture 12 and the strike craft in Picture 21. OBSERVED.
- **Six factions that look nothing alike**, even small (Pictures 11 and 13). OBSERVED.
- **The space sky.** It is calm and deep, and ships win against it (Pictures 16 and 17). OBSERVED.
- **Planets V2** rocky, terran and barren (Picture 19, after row). OBSERVED.
- **Wounds with real insides**, not a painted mark (Picture 18). OBSERVED.
- **Faction battle rules.** They are distinct and worth playing (Pictures 2 to 6). OBSERVED.
- **One menu look.** The ember style is consistent, and the launch button is worded per faction (Pictures 2 to 8 and 10). OBSERVED.
- **Frame time on the test PC**, and the habit of stamping every picture with its revision. INFERRED from LOOP.

## 4. Already planned

| Gap | Issue or PR | Still missing |
|---|---|---|
| Title and battle load freeze | 1434, PR 1445, 1995 / PR 2010 | Gate not yet passed |
| Battle stutters | 1843 / PR 1852, 1645, 1982 | Held behind 1445 |
| Shader warm-up, first launch, memory | 1542 (parked), 1439 / PR 1442, 1780 / PR 1960 | 1542 has no date |
| Slow window close; battle to title | 1518, 1519 / PR 1950 | |
| Other PCs fallback and safe mode | 1436 | Mid-range proof (item 6) |
| Title, load screens, first launch | 1405 | Picture 1 is flat text; title layout is "phase 2" |
| First battles teach; HUD wording | 1403, 1401 | |
| Cut-ins; ships read at camera | 1404, 1406 / PR 1964 | Effect sizing (item 1) |
| Rebinding, colorblind, rules reference | 1454 (later) | |
| Admiral portraits | 1887, 1897, PRs 1896, 1903 | 12 test admirals; captains (item 3) |
| Commands, relics, capstones, events | 1453, 1652 | Passives (item 4) |
| Difficulty, economy, story, balance | 1940, 1941, 1990, 1992 | |
| Wrecks and breakups | PR 1737 | Reliability |
| Wounds V2 and interiors | 1741, PRs 1755, 1997, 1743 / PR 1763 | |
| Faction deaths, variety, acid and Gauss | 1399, 1875, 1394 / PR 1858 | |
| Debris from ship kits | 1362 (blocked) | |
| Weapon and hit reactions, status | 1689, 1693 | |
| Effect timers, shield hits, colour leaks | 1970, 1974, 1991 and their PRs | |
| Post effects and kill-cam | 1779 | Opt-in; capture owed |
| Sky, banding, gas floor | 1766, 1502, 1328 | |
| Stations, hulks, props | 1767 / PR 1772, 1791 / PR 1998, 2003 | |
| Planet detail | PR 1983 | |
| Storm lightning | 1360 / PR 1986 | |
| New look options | 1463 / PR 2000 | |
| Exteriors rollout | 1778, 1908, 1681, 1684, 2001 | |
| Unfinished fleet (FLEET.md: 5 old hulls, 6 pending looks) | 1412 / PR 1725, 1145, 1146, 1422, 1423, 2011 / PR 2012, 1291 | |
| Strike craft and torpedo bodies | 1943 (shelved by Ryan) | Not re-proposed |
| Chorus tendril weapon | 1877, PRs 1881, 1904 | |
| Sound redo | 1752, 1572 / PR 1718 | M2 waits on Ryan's go |
| Altitude bands; idle motion | 1582 / PR 1874 and 1685 (per LOOP) | Overlap rule (item 7) |
| Release prep | 1508 | |

## 5. Not checked

- **The game itself.** I could not run it. I had no clips and no sound, so motion, timing, camera moves, music and mix are unjudged.
- **Screens with no picture:**
  - the battle HUD panels (E1 Ledger)
  - any weapon firing, shield hit or explosion
  - the campaign map, events, debrief and end cards
  - settings, How to play, and loading screens
  - the title with its 3D backdrop (Picture 1 is a cloud render on flat grey)
  - boarding and wings in flight
- **Weak evidence.** Pictures 9, 19 and 20 are cloud or software renders. Pictures 11 to 15 and 22 are benches on black. Battle sky and lighting rest on Pictures 16 to 18 only.
- **Stale pictures.** Several carry stamps from Nov 19 to 22. Main has since merged Planets V2, Ship Exteriors V2, asteroids, fonts, the UI audit port and end cards.
- **Rulings.** I had only the last 60 FINDINGS rows, all old, and no RULEBOOK. I kept the rulings visible in LOOP and PROGRAM:
  - one boss phase (R440)
  - no Glasswright refraction and 400 stars (R421)
  - blown apart, never sliced, with flame capped (R186)
  - no Eclipse craft
  - no controller
  - torpedo and craft concepts shelved
  - the approved ship looks

  The Board should check items 3, 10 and the outside playtest against the full list.
- **Issues.** I read titles only, not bodies. Some "planned" rows may cover more or less than the title says.
- **AI, balance feel, save and resume, 4K and other resolutions.** Not seen.