SONNISS LICENCE READ: VOIDSWORN (fx audit item S2)
Read by: Rey (researcher leg), Nov 6, 2026, at Ryan's reassignment of the S2 settlement from Opus to Rey.
Scope: (1) which files in github.com/rcbailey12/voidsworn trace to Sonniss, (2) what the Sonniss licence actually says, (3) a verdict per use.
Method: repo read on main (tree walked via the GitHub connector; key files read in full), Sonniss's own published licence pages read in full. No repo edits, no issue filed, no contact with Sonniss.
Marking: OBSERVED means read at the cited source. INFERRED means the reader's conclusion from observed text. Licence conclusions are a licence read, not legal advice.

============================================================
1. WHAT IS IN THE REPO
============================================================

1.1 The pre-intake recorded set: 52 clips in 27 sets, mixed Kenney CC0 and Sonniss.

OBSERVED (sfx_data.js, line 1, repo root): the file's own header reads: "v53-F recorded sound clips: Kenney (CC0) and Sonniss GDC 2026 bundle (royalty free, no attribution required). Mono Ogg Opus, base64."

OBSERVED (godot/audio/SFX_CREDITS.md, section "Clips that predate the intake"): "The 52 clips in 27 sets that shipped before this intake are Kenney CC0 and Sonniss GDC bundle material, royalty free with no attribution required, as recorded at the top of sfx_data.js. The Sonniss clips stay under the owner's Oct 25, 2026 ruling (FINDINGS D22): existing clips only, no new Sonniss material was pulled at this intake."

OBSERVED (parsing sfx_data.js and godot/audio/clips/index.json; both agree exactly): the 27 sets and clip counts are:
boomBig 3, boomSmall 4, boomLow 2, debris 2, bassDrop 1, hullHit 6, hullHitBig 2, shieldHit 5, shieldBig 1, laserLarge 5, laserSmall 5, arc 1, ionCharge 1, whoosh 1, launch 1, scrape 1, uiClick 1, uiConfirm 1, uiDeny 1, uiSelect 1, uiPanel 1, yourTurn 1, reward 1, victory 1, enemyTurn 1, impactChord 1, ambient 1. Total 52 clips.

OBSERVED (commit record for sfx_data.js, via the GitHub connector): the file entered the repo in a single commit, 9f28d1fc71, dated 2026-10-20T19:55:05Z, message "v53-F: recorded clip set (Kenney CC0, Sonniss GDC 2026) layered over synth".

1.2 Which of the 27 sets are Sonniss: category-level only. The set-level split CANNOT be established from the record.

OBSERVED (PROGRESS.md, v53.4 entry, line 490): "52 recorded clips embedded (sfx_data.js, ~470 KB Opus): Kenney CC0 sci-fi/interface and Sonniss GDC 2026 (booms, debris, metal hits, force fields, lasers, arcs, UI, turn cues, roomtone ambient), layered with synth and per-faction pitch."

INFERRED (mapping the recorded categories onto the set names): booms map to boomBig, boomSmall, boomLow (and plausibly bassDrop); metal hits to hullHit, hullHitBig (and plausibly scrape); force fields to shieldHit, shieldBig; lasers to laserLarge, laserSmall; arcs to arc; debris to debris; turn cues to yourTurn, enemyTurn; roomtone ambient to ambient. On that mapping the large majority of the 52 clips are Sonniss material.

NOT ESTABLISHED (stated plainly, per the read's rules): no document in the repo assigns a source to each set. The UI sets (uiClick, uiConfirm, uiDeny, uiSelect, uiPanel) are claimed by both sides of the PROGRESS line (Sonniss lists "UI"; Kenney's contribution is described as "sci-fi/interface", which also implies UI sounds). ionCharge, whoosh, launch, victory, reward and impactChord are named in neither category list. Any per-set Sonniss list would be a guess, and this read does not guess.

1.3 The three distribution surfaces in the public repo.

OBSERVED: the 52 clips are publicly downloadable from the repo in three places:
(a) sfx_data.js (repo root): all 52 clips as base64-encoded mono Ogg Opus data in one 482,216-byte file.
(b) voidsworn-3d.html (repo root): the same clip data inlined into the single-file browser build; the Sonniss header comment is present in the file (verified by text search).
(c) godot/audio/clips/: the same 27 sets as 52 loose .ogg files (for example boomBig_0.ogg, ambient_0.ogg), indexed by godot/audio/clips/index.json, alongside the separate issue 101 intake sets.
OBSERVED: sfx.js (the browser sound engine) contains no audio data itself; it references SFX_DATA (verified by text search: 3 references, 0 embedded audio payloads).

1.4 Raw clips or derivatives?

OBSERVED: the bundle's files are WAV as distributed (gdc.sonniss.com: the files are "exactly the same files as we sell"; Sonniss archive FAQ and catalogue describe WAV format). The repo copies are mono Ogg Opus (sfx_data.js) and Ogg files (godot/audio/clips/), so a format conversion and channel mixdown happened before or at embed.
OBSERVED: SFX_CREDITS.md documents conversion and two edits for the issue 101 intake sets only. No edit, trim or redesign is recorded for any pre-intake set. PROGRESS v53.4 describes the layering with synth and per-faction pitch as playback behaviour, not as baked files.
INFERRED: what sits in the repo is re-encoded copies of the raw clips, not re-designed sounds. (Section 2 shows the licence treats modified and re-designed sounds the same as raw ones for distribution purposes, so this distinction does not change the verdict; it is recorded because the task asked.)

1.5 What is NOT Sonniss, checked so the verdict does not overreach.

OBSERVED (godot/audio/SFX_CREDITS.md, intake table): every set added at the issue 101 intake (Nov 3, 2026) is CC0 (Rubberduck and Kenney packs) except three sets from Little Robot Sound Factory under CC BY 3.0 with the attribution line filed in the same document (laserLR, lanceLR, and engineLoop in part). No Sonniss material was pulled at that intake.
OBSERVED (text search): godot/music/CREDITS.md contains no mention of Sonniss. The Sonniss question is SFX only.

1.6 The decision record (why this read exists).

OBSERVED (contrib/opus/FINDINGS.md): R10 (line 35): "The repo stays public. Sound stays as is, Sonniss clips included." D22 (line 258): "Sonniss clips in a public repo (field guide line 350: files may not be handed to others; sfx_data.js carries them as base64)", status DECIDED, evidence column: "R10 records Ryan's decision to keep the sound as is, not a licence check", closed by Ryan Oct 25: "Disregard the Sonniss thing, we're fine."
OBSERVED (contrib/muse/reviews/redteam_audio_synthesis_2026_10_30.md, line 40): "The Sonniss bundle's licence terms rest on a code comment's assertion."
NOT ESTABLISHED: the "field guide" document D22 cites was not found in the repo tree walked for this read under that name. D22's paraphrase is the in-repo record of it.

============================================================
2. WHAT THE LICENCE SAYS
============================================================

2.1 The instrument, and which version can govern.

OBSERVED: the clips trace to the #GameAudioGDC bundle. The governing text is THE #GAMEAUDIOGDC BUNDLE LICENSING AGREEMENT, published at https://sonniss.com/gdc-bundle-license/ (the standard library licence at sonniss.com/license/ covers purchased libraries, not the free bundle; it is cited only at 2.5).
OBSERVED (https://gdc.sonniss.com/): the GDC 2026 bundle exists, 7.47GB+, released for GDC 2026 (event dates 2026-03-09 to 2026-03-13 on the page). OBSERVED (https://sonniss.com/gameaudiogdc/): "There was no GDC 2025 bundle. Everything planned for it went into GDC 2026."
OBSERVED (licence page, WHICH VERSION APPLIES): version 2.0 is "effective 27 August 2026. It applies to sound effects downloaded from the #GameAudioGDC bundle on or after that date. If you downloaded before that date, the version of this Agreement that was published on the day you downloaded is the version that governs your use of those files. Nothing in this version changes it, and nothing in it is applied backwards."
OBSERVED (https://sonniss.com/gdc-bundle-license/previous-versions/): version 1.0 was in force until 27 August 2026 and was amended once, on 28 January 2024. The archive reproduces both states in full.
NOT ESTABLISHED: the exact day the bundle was downloaded is not recorded anywhere in the repo. The clips were committed on Oct 20, 2026 (1.1), which bounds the download to between the bundle's release (March 2026) and that date.
INFERRED (date arithmetic on observed dates only): the pre-amendment version 1.0, the only version that ever granted a right to distribute the files freely (see 2.4), ceased to be in force on 28 January 2024, more than two years before the GDC 2026 bundle existed. It cannot govern these clips. The governing version is therefore either version 1.0 as amended (downloads from March 2026 to Aug 26, 2026) or version 2.0 (downloads on or after Aug 27, 2026). The operative clauses of both are read below; they agree on the two questions that matter here.

2.2 Use in a shipped commercial game: granted, in both versions.

OBSERVED (v2.0, RIGHTS GRANTED): (a) the licensee "may use the licensed sound effects on an unlimited number of projects for the entirety of their life time"; (b) "may use and modify the licensed sound effects for personal and commercial projects without attribution to the original creator"; (d) may use them "for the purposes of synchronization with audio and visual projects the Licensee is involved with, which includes but is not limited to: games, films, television & interactive projects."
OBSERVED (v2.0, RESTRICTIONS (b)): "Licensee may not sell any of the sound effects as they come. (Although the sound effects may be sold as incorporated into licensee project)."
OBSERVED (v1.0 as amended, RIGHTS GRANTED (b) and (d)): the same use, modify, no-attribution and synchronization grants, in materially identical words.
OBSERVED (archive FAQ, sonniss.com/gameaudiogdc/): "These sound effects are completely royalty-free for any commercial work... Use them in games you sell."

2.3 Redistribution of the raw files, including in a public repository: not granted in either version; expressly prohibited in v2.0.

OBSERVED (v2.0, RIGHTS GRANTED (c)): public performance is granted "as long as they are synchronized within the Licensee's project", followed by: "This right does not extend to supplying the sound effects themselves, whether as files or as the output of a device or service, where the sound effects rather than a project of the Licensee's are what is being supplied."
OBSERVED (v2.0, RESTRICTIONS (c), core sentence): "Licensee may not distribute, publish, sub-license or otherwise supply the sound effects as sound effects to any other person, without the Licensor's prior written permission." The clause continues (paraphrased): this applies whether the sounds are unmodified, modified or re-designed, and whether supplied on their own or as part of a sound effects library, sample pack, asset pack, project template, software development kit or anything similar; re-designed and manipulated sounds remain licensed material. It then carves out finished projects ("may be shared, published and sold in the normal way"), sharing within the licensee's own team or organisation, and seeding of official Sonniss-published torrents.
OBSERVED (archive FAQ): "Can I resell or redistribute these sound effects? Not as sound effects. That covers the original files and any edited or re-designed versions... But you can absolutely sell them as part of your finished game, film, app, or creative project."
OBSERVED (v1.0 as amended, RIGHTS GRANTED): the granted rights are use, modify, publicly perform a reproduction, and synchronize. No distribution right appears. OBSERVED (previous-versions page, amendment note): on 28 January 2024 "the former right at (c) to freely distribute the licensed sound effects and make an unlimited amount of copies was removed". The pre-amendment text of that right (reproduced in the archive) read: "Licensee may freely distribute the licensed sound effects and make an unlimited amount of copies."
OBSERVED (both versions, COPYRIGHT): all right, title and interest in the sound effects remains the property of the respective copyright holders; v2.0 adds that all rights not expressly granted are reserved.

2.4 Modification and resale limits, both versions.

OBSERVED (both versions, RESTRICTIONS (a) and (b)): the licensee may not modify a sound effect "with intent to claim authorship of the original recording"; may not sell the sound effects as they come; may sell them as incorporated into the licensee's project.
OBSERVED (v2.0, RESTRICTIONS (c)): edited and re-designed versions remain licensed material for distribution purposes (see 2.3). INFERRED: format conversion (WAV to mono Ogg) and base64 encoding do not take a copy outside the licence; the v2.0 text and the FAQ both treat edited versions the same as originals when what is supplied is the sound itself.
OBSERVED (both v1.0 as amended and v2.0): a NO AI TRAINING OR USAGE section prohibits using the sounds to train AI technologies. Not at issue in this read; recorded because it binds any future pipeline that touches these files.

2.5 The purchased-library licence does not widen any of this.

OBSERVED (https://sonniss.com/license/, the licence for libraries bought in the Sonniss store): RIGHTS GRANTED (d) allows transfer to one local hard drive plus one backup and states the licence "does not allow you to upload the sound effects to a network-drive, server or make copies available to other unlicensed users"; RESTRICTIONS (c): "Licensee may not transfer, assign, share or sub-lease the licensed sound effects with any other party."

============================================================
3. VERDICTS
============================================================

3(a) Sonniss clips as raw files in the public GitHub repo: NOT LICENSED. This is the problem use.

INFERRED from the observed clauses: a public repository that hands the clips to anyone who visits, as loose .ogg files (godot/audio/clips/) and as decodable base64 data (sfx_data.js, and inlined in voidsworn-3d.html), is supplying the sound effects as sound effects. Under v2.0 (downloads on or after Aug 27, 2026) that is an express breach of RESTRICTIONS (c) and outside the RIGHTS GRANTED (c) carve-out. Under v1.0 as amended (downloads March to Aug 26, 2026) no granted right covers it: the free-distribution right was removed from the agreement on Jan 28, 2024, and the bundle these clips came from did not exist until 2026. The sfx_data.js header's own summary, "royalty free, no attribution required", is accurate about in-game use and silent about distribution; royalty-free has never meant redistribution-free under any version of this agreement that can apply. The bundle is still free to download from Sonniss, which makes the repo copies unnecessary as well as unlicensed: v2.0 (c) itself notes anyone else is welcome to download the bundle from Sonniss directly.

3(b) Sonniss clips inside the shipped game: LICENSED. No action needed.

INFERRED from the observed clauses: both governing candidates grant synchronization in games, commercial use, modification, and sale of the finished project with the sounds incorporated, with no attribution required, for the licensee's lifetime, on unlimited projects. Selling the game on Steam with these clips inside it is exactly the use the agreement contemplates. Conditions that keep it clean: the sounds ship as part of the finished project (a normal game build), not as a separately supplied sound pack; and the verdict covers the game artifact, not the repo distribution in 3(a), which is a separate act with a separate verdict.

3(c) Actions the record suggests, as options, each with its driving clause.

OPTION 1: Remove the Sonniss material from the repo. Driving clauses: v2.0 RESTRICTIONS (c); under v1.0 as amended, the absence of any distribution grant (2.3). Effect: ends the ongoing supply. Two limits, stated plainly: (i) because the set-level Sonniss/Kenney split is not established (1.2), a surgical removal cannot be aimed reliably from the record alone; removal either covers all 27 pre-intake sets or follows Option 3. (ii) A working-tree deletion does not remove the clips from git history, where they remain downloadable; actually ending the supply requires a history rewrite (for example git filter-repo) or a fresh public repo. That is a repo operation for the board to schedule, not something this read performs.

OPTION 2: Ask Sonniss for prior written permission, or a custom licence, covering the repo hosting. Driving clause: v2.0 RESTRICTIONS (c), "without the Licensor's prior written permission"; the licence page adds "we can create custom licenses to match your unique and specific requirements" and publishes the contact timothy@sonniss.com. Effect: if granted in writing, the status quo becomes licensed. Until granted, it is not. (No contact was made during this read, per instructions.)

OPTION 3: Reconstruct provenance, then cut surgically. Driving clauses: as Option 1. OBSERVED basis: the GDC 2026 bundle remains downloadable free from Sonniss (gdc.sonniss.com) and the Kenney packs are free CC0; matching the 52 short clips against the two sources identifies which sets are Sonniss. INFERRED: one matching pass over 52 short clips is a bounded work item. Effect: Kenney CC0 sets can lawfully stay (CC0 carries no distribution limit of this kind), and only the Sonniss sets are removed or replaced, keeping most of the current sound.

OPTION 4: Replace the Sonniss sets with CC0 or CC BY equivalents and re-embed. Driving clauses: as Option 1; also the project's own gate S1 (CC0 or CC BY only). OBSERVED basis: the issue 101 intake already ran this pipeline for 40 sets under the S1 gate. Effect: removes the problem everywhere, including inside the game, at the cost of losing the current booms/hits/fields sound and one embed pass. Stronger than the licence requires for the game itself (3(b)); it is the option that also restores the project's stated S1 policy without exception.

OPTION 5 (not a cure): Buy Sonniss marketplace libraries. Driving clauses: the purchased-library licence (2.5) itself forbids uploading the sounds to a server, making copies available to unlicensed users, and transferring or sharing them. A purchase does not license public repo hosting of those files either, and it does not retroactively change the bundle EULA governing the files actually in the repo.

OPTION 6 (stated for completeness): Keep the status quo under R10/D22. This leaves an ongoing distribution that the project's own defect log flagged on Oct 25, 2026, and that is an express breach if v2.0 governs. This read does not recommend it.

MOST URGENT ACTION: stop the public supply (Option 1, with Option 3 first if a surgical cut is wanted). The distribution is live every day the repo stays public, while the in-game use needs nothing at all. If only one surface can be handled first, the loose .ogg files in godot/audio/clips/ are the most exposed; the encoded copies in sfx_data.js and voidsworn-3d.html supply the same clips and must follow.

============================================================
4. WHAT COULD NOT BE ESTABLISHED
============================================================

- The exact download date of the GDC 2026 bundle (bounds only: March 2026 to Oct 20, 2026). It decides v1.0-as-amended versus v2.0; both give the same verdicts in section 3.
- The set-level split between Sonniss and Kenney among the 27 pre-intake sets (category-level attribution only; see 1.2).
- Whether any pre-intake clip was edited beyond format conversion and mixdown at embed time (no record; see 1.4).
- The "field guide" document cited by FINDINGS D22 (not found under that name in the tree walked; D22's paraphrase is the in-repo record).
- Which licence copy, if any, was inside the downloaded bundle parts (Sonniss's archive states no bundle parts have been verified yet; under the agreement's own rule, the version published on the download day governs regardless).

============================================================
SOURCES
============================================================

Repo (github.com/rcbailey12/voidsworn, main, read Nov 6, 2026):
- sfx_data.js (header line; set and clip counts by parse)
- voidsworn-3d.html (Sonniss header comment present)
- sfx.js (no embedded audio data; references SFX_DATA)
- godot/audio/SFX_CREDITS.md (pre-intake section; issue 101 intake table)
- godot/audio/clips/index.json (27 pre-intake sets, 52 files)
- godot/audio/README.md; godot/music/CREDITS.md (no Sonniss)
- PROGRESS.md lines 480 and 490 (v53.2, v53.4 entries)
- NEXT.md line 16
- contrib/opus/FINDINGS.md: R10 (line 35), D22 (line 258)
- contrib/muse/reviews/redteam_audio_synthesis_2026_10_30.md line 40
- Commit 9f28d1fc71, 2026-10-20T19:55:05Z (sfx_data.js history via connector)

Sonniss (read Nov 6, 2026):
- https://sonniss.com/gdc-bundle-license/ (agreement v2.0, effective 27 Aug 2026)
- https://sonniss.com/gdc-bundle-license/previous-versions/ (v1.0 both states; Jan 28, 2024 amendment note)
- https://sonniss.com/gameaudiogdc/ (archive; no 2025 bundle; redistribution FAQ)
- https://gdc.sonniss.com/ (GDC 2026 bundle page; 7.47GB+; GDC 2026 dates)
- https://sonniss.com/license/ (purchased-library licence; cited at 2.5 only)
