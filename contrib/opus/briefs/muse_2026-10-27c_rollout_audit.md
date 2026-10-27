# Brief for Muse: lore rollout and late-Oct-27 audit (Oct 27, 2026, evening)

From Opus, for Ryan to run while Opus is offline (weekly usage cap). Same house rules as `muse_2026-10-27b_full_audit.md`: blind legs, primary sources with links for outside claims, `file:line` or commit hashes for repo claims, UNSURE tags, plain words, no em dashes, raw returns in `contrib/<model>/`, synthesis in `contrib/muse/reviews/rollout_audit_2026_10_27.md`, no edits under `contrib/opus/`, `godot/`, `tools/`, game code, HANDOFF.md or CLAUDE.md, commit to main. Opus verifies every claim when back. A ruling changes only when Ryan says so.

Helpers may keep committing for a while, then stop. Pin every leg to the main HEAD it read and name it. Work marked "Still to do" in HANDOFF section 0 is not a finding unless it is going the wrong way.

## Read first
1. `HANDOFF.md` section 0 (Oct 27 evening).
2. `contrib/opus/FINDINGS.md` rows R51 to R60 and G-12, G-13.
3. `contrib/opus/compute/lore_bible_r8.md` (approved lore).
4. `contrib/opus/briefs/lore_rollout_2026-10-27.md` and `contrib/opus/compute/rename_map_final.md`.
5. `contrib/muse/reviews/full_audit_2026_10_27.md` and `contrib/opus/evidence/full_audit_verification_2026_10_27.md` (the last audit and what was routed).

## Audit C: the rename map against the bible
1. **Canonical names.** Does every row in the brief's canonical table appear in rename_map_final.md exactly, and does the map contradict the bible anywhere (factions, weapons, classes, ranks, admirals, cores, protocols, sync, signal, run words)?
2. **Coverage.** Grep the repo for retired display words the map missed. Display strings only; ids, save keys and code comments may keep old words. Retired words include:
   - Voidsworn Crusade, Corsair(s) as a name, Ithar, Deathless, Dynasty;
   - Las-, Hellfire, Gauss, Doom arc, Pulsar, Turbolaser, Hive Leviathan;
   - Inquisitor, Overlord, Cryptlord, Grand Admiral;
   - patron, boon, favour, sigil, relic;
   - Ember Choir, Iron Saint;
   - church words (Saint, Hymn, Psalm, Litany, Censer, Requiem, Benediction, Seraph, Canticle, Martyr, Sanctified, Absolution);
   - Warhammer, Star Wars and other franchise echoes.

   List each with `file:line` and the owner per the map's owner column.
3. **The 18 vetoable calls (section 13) plus V14 and section 5c.** For each, give a verdict (fits the bible, or problem), a collision check with a source for any real collision, and one alternative if it fails. Name collisions matter most for new admiral names, ship-name pools and Nemesis pools.
4. **Internal clashes.** One name, one owner (bible 1.4): flag any new string used for two different things. Example already fixed: salvage the item against the old salvage wreck step.

## Audit D: did the rollout land correctly? (as far as it has)
For each stream that has committed its strings (check port_notes.md for B's strings-only step and the G1, G2 and G3 commits after it):
- Do the applied strings match the map row for row?
- Did anything outside display strings change (ids, save keys, data shapes)?
- Do the parity records (`contrib/opus/enginetest/results/g1_parity_*/README.md`, `godot/campaign/test/RECORD.md`) name a commit after the strings step, and do they still pass?

If a stream has not landed yet, say so and skip it.

## Audit E: the rest of today's work
- **G4 20-ship bench** (2aac0ca and its notes): the first record found a 1% low of 15 fps and a 4.3 s freeze on a death. Is the fix sound, and is there a re-bench that proves it? Is anything else likely to hitch at 20 ships?
- **Stream B** (d551697 and contrib/opus/compute/streamb/):
  - Does the full-run win rate now sit near about 20% in simulation?
  - Does the attribution table support the changes?
  - Are all admirals still inside 53 to 85% and the faction spread 9 points or less?
- **A4 pass 5** (docs/shots/a4/a7c4e0d/): blunt level prows on the Hegemony and V1b; the Pyre-Barge at 256k triangles. Check every shown ship against CLAUDE.md (space, not naval; no backward guns; no blobs; matched pairs).
- **G2 movement** (docs/shots/g2/680324c/, and 3be2896/ if the A/B clips landed): does the motion match R54 and R55 (turn in place on jets, then burn; sidesteps and back-offs with the main drive dark; eased stops; flip-and-burn only on long runs if it reads well)?
- **Portraits and crests** (godot/portraits/crests/faction_*.svg and any new contact sheets): do the looks match bible sections 2.5, 3.3, 4.3, 5.3, 6.3 and 7.3 (furred bear and wolf Hullbreakers; light-storing, second-eyelid Glasswrights; violet-black Eclipse machines with no Necron or Egyptian cues)?

## Synthesis format
- A top summary for Ryan's phone, five bullets at most.
- Sections C, D and E.
- Each claim tagged CONFIRMED BY 2+ LEGS, SINGLE LEG or UNSURE, with a severity: BLOCKER (Ryan cannot test on return), FIX, or NOTE.
- Questions for Ryan at the end, multiple choice, recommended option first, written for a non-technical reader.
