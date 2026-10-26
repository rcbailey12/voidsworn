# Decision Pack for Ryan: Three Sheets

Prepared Oct 26, 2026. Written blind from the evidence pack provided. No repo files were opened beyond what is summarised here. Effort estimates come from the pack; I have not invented new ones.

## Sheet 1: Story and Career Mode Scope

The question. BACKLOG 4b asks for progression, characters, personalisation, story arcs, and a career layer. Plan B5 says: build Option A (voices and records) first, then Option B (faction arcs). Neither starts until you answer four scope questions. Here they are, three choices each.

### Story length

Option | What you will see
Short: 3 beats per faction (the pack's default) | One arc takes about 15 minutes of reading across a full run. Each sector gets one story event. You feel a beginning, a twist, a showdown, then the run ends.
Medium: 5 beats per faction | About 25 minutes of reading. Two extra beats let a choice in sector 1 ripple twice before the final battle. The rival admiral gets more screen time. No new code needed; the beat structure just gets two more slots. Cost is purely more writing.
Long: 7+ beats or branching paths | 40 minutes or more. Choices fork. You would need a real branching state machine, which is new machinery the pack does not plan for. Effort: UNSURE, but clearly multi-week and risky.

Pick: Short (3 beats). It matches the pack's assumption, keeps each run tight, and lets you judge whether players want more before commissioning extra writing. The structure extends to 5 beats later with zero rework if players ask.

### Text volume

Option | What you will see
Lean: 100 to 150 words per beat (the pack's default) | Each story event is a short paragraph plus a choice. Reads fast, like a mission briefing with personality. Total arc text per faction is roughly 300 to 450 words.
Moderate: 250 to 350 words per beat | Each event is a full page of dialogue and description. More flavour, more rival banter. Doubles the writing load.
Heavy: 500+ words per beat, full dialogue trees | Closer to a visual novel. Each beat has multiple exchanges. Writing load triples or more and risks slowing the turn-based pace players came for.

Pick: Lean (100 to 150 words). The game's rhythm is tactical, not narrative. Short, punchy text respects that. Option B's six factions times three beats means 18 beats of writing; lean keeps that to about a week of effort (the pack's estimate) instead of two or three.

### Voice lines or none

Option | What you will hear
None: text only (the pack's default) | Silence during story events. You read the admiral's words on screen. No audio budget, no casting, no recording sessions.
Short barks: 3 to 5 second recorded clips per admiral | You hear a gruff "Fleet forming" when you select your admiral, a taunt when the rival appears, a victory line. Adds huge personality for modest cost. The backlog says recorded sound packs are OK.
Full voiced scenes | Every story beat is spoken. Cinematic, but expensive, hard to re-record if you rewrite a line, and multiplies the audio asset count by 24 admirals times dozens of lines.

Pick: None for now, with the door open to short barks later. Option A gives each admiral written voice lines (selection, victory, defeat, flagship-sighted). Get those on screen first. If the text lands well, a small recorded-bark pack is a natural add-on that does not touch the story system. Starting with full voice would lock you into text you cannot cheaply revise.

### Portrait art style

Option | What you will see
Glyph crests (the pack's default, patron-style) | Each admiral is represented by a stylised faction symbol: a sigil, a crest, a glyph in faction colours. Clean, fast to produce, consistent. No faces. You see the symbol on the admiral select screen and the career tab.
Painterly busts (the existing template) | Three-quarter bust, lit from the left, faction glow, dark background, painterly finish. This is the template already used for Voice of the Deep v4 and Matriarch v3. You see a character's face and posture. Slower to produce; 15 unmade portraits remain.
Hybrid: glyph crests now, busts later | Ship the game with crests so every admiral has a visual identity on day one. Commission bust portraits in batches afterward, starting with the admirals players meet most.

Pick: Glyph crests now, busts later (hybrid). The pack assumes portraits are deferred until you choose a style. Crests unblock Option A and B immediately. You can green-light bust portraits in small batches once you have settled on the look you want, without holding up the story work.

### Overall pick

Follow Plan B5 exactly: Option A first (a few days), then Option B (about a week). This matches the career_story.md review and the plan. I see no reason to deviate. Option A makes the 24 admirals audible and gives you medals, records, and rename hooks you will see on the Progression screen immediately. Option B then layers three-beat faction arcs on top, using the event system that already exists. You will see a story event pop up once per sector, make a choice, meet a named rival, and fight a flagship showdown framed as that rival's reckoning. Win, and you earn a permanent reward you can see in the shipyard or your Command list.

Option C (the Long Career) is the wrong next step. It rewrites the save layer (the riskiest piece, per the pack) and makes your flagship immortal, which undercuts the permadeath tension that makes the Hall of the Fallen matter. If players ask for more after B ships, C's career screen can be built later as a read-only view over the data A and B already collect.

Stays open for you. The four scope answers above. Also: you must read and approve each faction's arc text before it ships (B5's exit condition). And if you want 5-beat arcs instead of 3, say so before writing starts; the cost is writing time only, but it is real time.

## Sheet 2: Music Style for the Adaptive Score

The question. BACKLOG section 4 calls for an adaptive layered score. Style is your call. The game sits at the crossroads of three feels: deliberate turn-based tactical weight (BattleTech), cinematic capital-ship grandeur (Sins of a Solar Empire 2), and small-fleet tension (Rogue Trader voidship battles). Six factions span crusade zeal, naval discipline, raider chaos, grown flesh, porcelain sails, and faceless machine intelligences.

Three directions, kept genuinely distinct.

### Direction 1: Brass, war drums, and low strings (the military-weight route)

What it sounds like. Thick brass chords, timpani hits, snare patterns, deep cello and bass lines. It sounds like a fleet forming up for war. Exploration is sparse: a low drone, a distant horn. Battle adds layers: percussion kicks in at the start of combat, brass swells when capital ships exchange fire, strings tighten when your hull is cracking. Victory is a full brass fanfare over rolling drums. Defeat is the same theme slowed down, strings only, hollow.

Adaptive layers. Exploration: drone plus one horn. Battle start: add percussion. Mid-battle: add brass and strings. Victory/defeat: full arrangement, major or minor. Faction flavour rides on top: Corsairs get faster, rougher percussion; Hegemony gets stricter, march-like snare.

Reference tracks.

- "Main Theme" from BattleTech (2018), composed by Jon Everist. Heavy brass and percussion, very much the "fleet going to war" feel.
- The Sins of a Solar Empire original soundtrack, composed by Paul Ruskay. Orchestral sci-fi with weight.
- I could not verify links from this environment, so I am not printing URLs. Search those two titles plus composer names on Spotify or YouTube. UNSURE: I cannot confirm any specific URL is live.

Licensing note. These are references only. The game cannot ship those recordings. A composer would write original music in the same spirit. The backlog says recorded sound packs are OK, which covers hiring musicians or buying a royalty-free orchestral pack.

### Direction 2: Cold synths, sparse piano, and swelling strings (the lonely-vacuum route)

What it sounds like. Analog synth pads, a few piano notes with long reverb, strings that creep in slowly. It sounds like staring out a viewport at a distant enemy fleet. Exploration is almost silence: a low hum, one piano note every few seconds. Battle adds a pulsing synth bass and tighter string ostinatos. The longer the fight goes, the more layers stack. Victory is the synth pulse resolving into a warm string chord. Defeat is the pulse stopping, leaving just the hum.

Adaptive layers. Exploration: pad and sparse piano. Battle start: add bass pulse. Mid-battle: add string ostinato and a second synth layer. Victory: resolve to major. Defeat: strip back to the hum. Faction flavour: Deathless get colder, more mechanical synth textures; Chorus get wetter, more organic-sounding pads.

Reference tracks.

- "Milky Way" (the exploration track) from FTL: Faster Than Light, composed by Ben Prunty. Sparse, lonely, synth-and-piano. Very close to the exploration feel this game needs.
- The Homeworld (1999) soundtrack, composed by Paul Ruskay. Strings and choir over a void. The battle tracks build in layers.
- I could not verify links from this environment, so I am not printing URLs. Search those titles plus composer names on Spotify or YouTube. UNSURE: I cannot confirm any specific URL is live.

Licensing note. Same as above. References only. The game would need an original score or a licensed royalty-free pack in this style.

### Direction 3: Ritual chant, drone, and industrial hymn (the crusade-and-flesh route)

What it sounds like. Low human or synthetic chanting, frame drums, bowed metal, deep drones that vibrate. It sounds like a war-cathedral or a living ship breathing. Exploration is a slow chant over a drone. Battle adds pounding drums and harsher textures: grinding metal for the Deathless, wet percussive hits for the Chorus, ragged shouted chants for the Voidsworn. Victory is the chant rising to a full hymn. Defeat is the chant collapsing into a single sustained drone.

Adaptive layers. Exploration: drone plus one voice. Battle start: add drums. Mid-battle: add second voice layer and metallic texture. Victory/defeat: full chant arrangement. This direction gives each faction the most distinct sonic identity because the "instruments" are voices and found sounds, not a fixed orchestra.

Reference tracks.

- The Darkest Dungeon soundtrack, composed by Stuart Chatwood. Chanting, strings, and dread. The track "Town in Chaos" or the main theme capture the ritual-weight feel.
- The Hellblade: Senua's Sacrifice soundtrack. Whispered and shouted voices over dark drones. UNSURE: I recall this score exists but I am not fully certain of the lead composer credit, so I am flagging that.
- I could not verify links from this environment, so I am not printing URLs. Search those titles on Spotify or YouTube. UNSURE: I cannot confirm any specific URL is live.

Licensing note. Same as above. References only. Chant and drone music is well served by royalty-free packs or a small vocal recording session, which the backlog's "recorded sound packs are OK" line covers.

### Pick and why

Direction 1 (brass and war drums), with elements of Direction 3 for faction identity.

Reason: the game's core feel is tactical weight. You are moving fleets on a hex grid, watching capital ships trade broadsides. Brass and percussion sell that weight better than synths. Direction 2 is beautiful but it suits a lonely exploration game more than a fleet-battle game. Direction 3 is the most distinctive but it risks making every faction sound like a horror game.

The blend: use Direction 1's brass-and-drums spine for the shared battle system, then let Direction 3's texture vocabulary colour each faction. Voidsworn get chanted overlays. Deathless get metallic drones instead of brass. Chorus get wet, organic percussion. Hegemony get the strictest march snare. This way the adaptive layer system stays one system, but each faction feels different.

Stays open for you. Pick a direction (or a blend). Decide whether to commission an original score or license a royalty-free pack. Either way, the adaptive layer structure (exploration, battle start, mid-battle, victory, defeat) is the same regardless of style.

## Sheet 3: Admiral Portraits Direction

The question. The game has no portrait screen yet. Voice of the Deep v4 is approved and final. Matriarch v3 awaits your verdict. Mending Choir v3 could not be generated and is not being retried in any reworded form; it needs a genuinely fresh direction from you. Fifteen portraits remain unmade across all factions. The standing rule is that an admiral's portrait should reflect their Command and doctrine in some way.

### Option A: Finish what exists, then batch the rest

What you will see. You rule on Matriarch v3 (approve or send back with notes). You give a fresh creative direction for Mending Choir (see below). The 15 unmade portraits are produced in batches of three to four, using the existing template: three-quarter bust, left-lit, faction glow, dark background, painterly finish, thin faction-trim frame. Chorus admirals follow the established modifiers (grown flesh, membrane, chitin, bile, growth, gross; no human features; no Earth-animal anatomy; no buildings or instruments). Each portrait is checked against the admiral's Command before it is approved. You see them appear on the admiral select screen and, later, on the career tab from Option A.

Timeline. Matriarch verdict: your call, one look. Mending fresh direction: your words, one paragraph. Then roughly three to four portraits per batch. UNSURE: I do not have generation-time estimates from the pack, so I cannot say how many days per batch.

### Option B: Glyph crests for all 24, portraits later

What you will see. Every admiral gets a stylised faction crest (a sigil in faction colours, patron-style) as their visual identity right now. This unblocks Option A and B from Sheet 1 immediately. You see 24 distinct symbols on the select screen. Portrait busts are commissioned later in small batches, starting with the admirals players meet most often (the ones whose arcs feature in Option B). Matriarch and Mending are handled when their bust portraits are commissioned, not before.

Trade-off. You get full visual coverage fast, but the painterly bust style that Voice of the Deep v4 already proves is delayed. Players see symbols instead of faces for a while.

### Option C: Lock the Chorus look first, then do the rest

What you will see. Before touching the other 15 portraits, you and the team nail down the Chorus admirals (Matriarch verdict, Mending fresh direction, and the remaining Chorus slots). Chorus is the hardest faction visually because of the no-human-features, no-Earth-anatomy, grown-flesh constraints. Getting three Chorus admirals right sets a clear visual rule that makes the remaining 12 portraits (across the other five factions) faster and more consistent. You see three Chorus portraits first, then the other factions in batches.

Trade-off. Non-Chorus factions wait longer for their portraits. But the riskiest visual problem (Chorus) is solved up front instead of being discovered mid-batch.

### Pick and why

Option C: lock Chorus first, then batch the rest using the existing template.

Reason: Chorus is where the visual rules are strictest and where two of the three open items live (Matriarch verdict, Mending fresh direction). The other five factions work within a more straightforward painterly-bust template. If you solve Chorus now, every portrait after that is a template execution, not a design problem. Matriarch v3 is already in front of you. Mending needs one fresh paragraph from you (see below). Once those two are resolved, the remaining Chorus admirals and then the other 12 follow a known path.

Option A is close but it treats all 15 as one queue, which risks hitting the Chorus constraints again mid-batch. Option B is the fastest unblock but it sidelines the painterly style that the game has already proven works.

### What I need from you before this direction can be built

1. Matriarch v3 verdict. Look at it. Say approve or say what is wrong. Her Command is Spawning Surge (broods release extra swarms, all swarms strike again +50%). The portrait should reflect that in some way: something about multiplicity, release, overwhelming numbers. That is the standing rule.

2. Mending Choir fresh direction. I am not proposing a retry of v3 or a reword of the old prompt. I need you to say, in your own words, what Mending should look like. Her Command is Regrowth Tide (every ship regrows 25% hull, heals damaged sections even destroyed ones). Some seeds you might react to: what does "healing" look like when the subject is grown flesh, membrane, and chitin, with no human features? Is it a figure knitted together from new growth? Is it a mass of tissue reaching outward? Is it something still and patient, or something active and urgent? Give me three or four sentences of feeling and imagery. I will turn that into a brief. Do not reference the v3 attempt. Start clean.

3. Portrait style confirmation for non-Chorus factions. The existing template (three-quarter bust, left-lit, faction glow, painterly) is established. Confirm it holds, or say what changes.

### What stays open for you

- Matriarch v3 verdict.
- Mending Choir fresh direction (your words, not a retry).
- Whether to start the 15 unmade portraits immediately after Chorus is locked, or to wait until Option A from Sheet 1 ships and you have a career tab to display them on.

## Not Checked

- Music reference links. I could not browse the internet from this environment. I named tracks and composers I believe are real based on training data, but I could not verify that any specific URL is live. Per instructions, I did not print links. Ryan should search by track title and composer name on Spotify, YouTube, or Bandcamp.
- Hellblade composer credit. I recall the Hellblade: Senua's Sacrifice soundtrack exists but I am not fully certain of the lead composer. UNSURE.
- Sins of a Solar Empire composer. I believe Paul Ruskay composed for the Sins series, but I am not 100% certain of the exact credit for the original game versus its expansions. UNSURE.
- Portrait generation time. The pack does not give per-portrait generation times. I could not estimate how many days a batch of three to four portraits takes. UNSURE.
- Option C (Long Career) full effort. The pack says "several weeks" and flags the save layer as highest risk. I have no independent estimate. UNSURE beyond the pack's words.
- All repo files. I did not open BACKLOG.md, plan B5, career_story.md, data.js, or any code file. Everything above is drawn from the summaries provided in this evidence pack, dated to commit f4b4607 (Oct 22) for the career review. I have not checked whether the repo has changed since.
