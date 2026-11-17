# Landing check: rulings R270 to R274

Refs #256. Board brief: issue 256 comment 6904314062, item 9: verify each of R270 to R274 reached the document a worker reads (RULEBOOK, factions.md, effects.md, issue briefs) and flag any brief still saying the old thing. Checked against main on Nov 15, 2026, about 19:50 CST: docs/RULEBOOK.md, docs/playbooks/factions.md, docs/playbooks/effects.md, docs/playbooks/ships.md, contrib/opus/FINDINGS.md (rows 300 to 304 name each ruling's designated homes), contrib/opus/LOOP.md, HANDOFF.md, and the KB1C-C design notes in contrib/muse/design/squadron_concepts_2026_11/hullbreakers/. The Board's own dot check 3 (19:42 CST, recorded in LOOP) caught two of the same gaps independently; where a fix is already on a Board branch, this note says so.

## Landed

R272, full landing. RULEBOOK 3.11 reads "A pause never loses or deletes work", names tools/pc/pause_all.bat, quotes Ryan's words and is set "Ryan, Nov 15"; pause_all.bat and pause_all.ps1 are both on main under tools/pc/. The E13 pass in the same ruling is executed (PR 825 merged, checked as opus_check_825).

R271, landed by its own routing. DB1 accepted and PR 809 merged. The shield smoke point is in effects.md (the settled list: "A shield hit makes no smoke, only an energy crackle (R271, issue 815)"). The doom arc and gauss notes were routed by the ruling itself to issue 815 round 3, and LOOP records 815's scope as exactly that (cinematic doom arc, a null cannon tracer, no smoke on shield hits), finished as PR 834. One soft spot, not a gap against the ruling: the Board's one-slug-per-gauss-shot call lives in FINDINGS row 301 and in 815, but effects.md has no gauss entry at all, so the playbook a worker opens for the gauss look carries nothing about it.

R270, landed except the librarian line below. The nebula and ion storm route A call is in issue 368's body, rewritten to step 2 route A with the old body kept in a comment (LOOP, 22:45 UTC Nov 15). The merges held for Ryan's look were resolved the same evening. The build scope ("do it all now") is an operating note and sits in LOOP, which RULEBOOK 0.10 makes the right home for it.

## In flight on the Board's side (dot check 3 already has them)

1. The RULEBOOK librarian line (R270's judge pick, R271's "have them both do it"). Still absent on main: RULEBOOK has no librarian text, its 2.7 is the Codex model pin, and 0.10 says only that "Muse audits for stale or conflicting docs now and then". FINDINGS row 300 names the owed home itself ("needs a RULEBOOK 2.7 line"). The Board's fix exists on branch opus/issue-788-dotline; it needs a merge to land.
2. factions.md and R274. The Hullbreakers lines still state the old rule on main: "the trophy patches read big and pale like the A20 concept, not small dark plates" and "patches of trophy colour (pale Hegemony grey, violet Eclipse plate)". R274 superseded the pale half four hours before this check. Per LOOP, the factions.md edit lands with the 726b worker's PR, and issue 726's title already says dark grey metal. Until that PR lands, the faction document a worker reads contradicts the ruling.

## Still open (no fix in flight found)

3. FINDINGS has no row for Ryan's FL5 settle (Nov 15, 10:32 CST, The Manifest, superseding FL4 and FL1) or his CR4 settle (Nov 15, 11:27 CST, The Honours Board). A grep of FINDINGS on main finds no mention of either. Both settles live only in the issue 794 record and its branches (the Career delivery and PR 798).
4. HANDOFF section 0 still lists the fleet screen as an open pick: "Ryan's open picks. The fleet screen (FL1 and FL2 hybrid, in Muse's chat)." FL5 settled that screen the same morning. The dot's earlier checks fixed other stale HANDOFF lines (804, 810), not this one. Items 3 and 4 are the two halves of the hand-over surface note's item 1; both are still open.
5. R252's FINDINGS row (row 282) is not marked SUPERSEDED in its paler half. R274's row states the supersession, so the record is resolvable, but RULEBOOK 0.10's own standard is that the old row is marked, so no two live rules conflict; a cold read of row 282 alone still gives "bigger and paler".
6. The KB1C-C design notes still carry the beam guard unqualified. Round 3 notes, line 16: "the beam stays well under the length, roughly 60 to 65 percent at most"; line 39: "KB1C-C's sheet terms (extreme-corner mouths in dark collars, the armoured lip, the beam guard) stand as written." FINDINGS row 303 names these notes as one of R273's homes. The sheet-notes half lands with the PR 830 rebuild, and dot check 3 put a comment carrying R273 and R274 on issue 793, so a worker on the issue sees the ruling; a cold reader of the design notes does not.

## Bottom line

Of the five rulings, R272 landed whole, R271 and R270 landed by their own routing, and R273 and R274 are recorded in FINDINGS and in flight: their remaining landings (factions.md via 726b, the RULEBOOK librarian line via the dotline branch, the KB1C-C notes) are named above with their carriers. The two items with no carrier are the FL5 and CR4 FINDINGS rows and the HANDOFF open-pick line.
