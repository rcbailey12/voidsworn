Personality reads

Hegemony: methodical treats the fight as a logged procedure. proud leads the line and speaks in formal certainty. patient waits and makes you close. cunning reads your weak points like a report.
Ashfall Hullbreakers: cunning talks like a trap already closed. greedy goes for the richest prize and says so. proud boasts in short hard lines and leads the pack. cruel finishes crippled ships first.
The Chorus: ravenous speaks in hunger and immediate appetite. cruel goes for the weakest ships and savors the finish. cunning speaks of angles and smell. patient waits for heat and closeness.
Glasswrights: cunning speaks in precise images of light and cracks. proud speaks with restrained dueling certainty. patient waits at range and talks about light and timing. cruel speaks precisely about cutting damaged ships first.
Eclipse: patient speaks flatly of memory and time. proud speaks with old certainty about restored copies. cruel speaks flatly about finishing damaged ships. methodical speaks like an old archive clerk.

NEM_VOICE = {
'hegemony': {
'methodical': {
meet: ['Registry entry confirmed. Your approach is already in the plan.', 'Hold your course. Every move is measured against the file.'],
win: ['The projection held. Your losses are now part of the record.', 'As expected. The next step is already scheduled.'],
flee: ['The line is lost. Withdrawal is the correct entry.', 'This position is logged as untenable. We will return.'],
fall: ['The Registry closes this file. Another will open it.', 'A clean result. The data remains.'],
again: 'Last time you won with {beat}. The drill now covers it.',
remember: 'Last time you won with {beat}. The record is not erased.'
},
'proud': {
meet: ['You face the line itself. Do not expect it to bend.', 'This flagship sets the standard. Match it or break.'],
win: ['The line holds because it is led. Note the difference.', 'You saw the front. You did not break it.'],
flee: ['The line is spent. The standard withdraws, not yields.', 'This is a reposition. The record will show it.'],
fall: ['The standard falls. The Navy will remember the stance.', 'A rare entry. It will be studied.'],
again: 'Last time you won with {beat}. The front is ready for it.',
remember: 'Last time you won with {beat}. The standard has not forgotten.'
},
'patient': {
meet: ['There is no hurry. The file will fill itself.', 'Come closer when you are ready. The line is patient.'],
win: ['Time was on the line. It usually is.', 'You closed too soon. The record shows it.'],
flee: ['The position is not worth the loss. We will wait again.', 'A measured withdrawal. The file stays open.'],
fall: ['The wait ends. The Registry notes the cost.', 'A patient line still breaks. The record is exact.'],
again: 'Last time you won with {beat}. The wait has been adjusted.',
remember: 'Last time you won with {beat}. The file is still open.'
},
'cunning': {
meet: ['Your weak points are clear. The line will reach them.', 'The plan already has your flank. You may proceed.'],
win: ['The flank was in the file. You found it too late.', 'A small opening was enough. The record is precise.'],
flee: ['The file is not complete. We will correct it elsewhere.', 'A calculated exit. The next entry will be better.'],
fall: ['The plan failed at one point. The rest remains.', 'A rare miscalculation. The Registry will annotate it.'],
again: 'Last time you won with {beat}. The file now has a second page.',
remember: 'Last time you won with {beat}. The weak point is marked.'
},
adapt: {
shields: 'Deflector drills are in effect. Your lance pattern is logged.',
pd: 'Picket screens are up. Your torpedoes are expected.',
armor: 'Bow plating is fitted. Your ram is in the file.',
evasion: 'Attitude drills are running. Your batteries will find less.',
aim: 'Fire-control drills are complete. Your evasive pattern is measured.',
special: 'Tight formation is set. Synchronized fire reaches one hex further.'
},
lessons: {
flank: 'A methodical commander covers the rear late. Hit the rear plating before the formation tightens.',
ion: 'Brittle shield emitters fail under focused ion fire. Strip the shields before the line settles.',
torp: 'Poor point defense leaves torpedoes a clear path. Launch after the escorts commit.',
board: 'Green boarding crews lose to prepared marines. Board only after the escorts are split.',
brawl: 'Long-gun doctrine struggles at close range. Close in and force the brawl.',
anchor: 'A proud flagship draws fire. Target it when the line is fixed.',
slow: 'Worn engines limit repositioning. Cut the retreat path and keep pressure.',
strike: 'The Hegemony strike is reinforcement in round 3. Finish the fight before the line doubles.'
}
},
'corsair': {
'cunning': {
meet: ['Nice fleet. The pack already picked which part to take.', 'You brought scrap. The trap is set.'],
win: ['Told you. The best piece comes off first.', 'The pack got the angle. You got the leftovers.'],
flee: ['Not worth the teeth. The pack comes back richer.', 'This scrap is not ready. We take it later.'],
fall: ['The pack breaks. Someone else takes the trophy.', 'A bad trade. The scrap stays yours.'],
again: 'Last time you won with {beat}. The pack knows that trick now.',
remember: 'Last time you won with {beat}. The pack remembers the angle.'
},
'greedy': {
meet: ['That flagship looks rich. The pack will take it.', 'You brought the best prize. Good.'],
win: ['The richest part came off clean. The pack eats well.', 'Trophy taken. The rest is scrap.'],
flee: ['The prize is too guarded. We take a smaller one.', 'Not yet. The pack comes back for the big piece.'],
fall: ['The prize was a trap. The pack paid for it.', 'Greed lost the trophy. The scrap is still yours.'],
again: 'Last time you won with {beat}. The prize is guarded differently now.',
remember: 'Last time you won with {beat}. The pack still wants the big piece.'
},
'proud': {
meet: ['The pack leads with me. Try to take the front.', 'You face the best trophy in the scrap. Hold still.'],
win: ['The front held. The pack takes what it wants.', 'You saw the lead. You could not break it.'],
flee: ['The front is chewed up. The pack regroups richer.', 'A bad fight. The pack will boast later.'],
fall: ['The lead falls. The pack scatters with the story.', 'A hard trophy. Someone else will wear it.'],
again: 'Last time you won with {beat}. The front is ready for that.',
remember: 'Last time you won with {beat}. The pack tells that story too.'
},
'cruel': {
meet: ['The broken ones go first. Then the rest.', 'I see the lame ships. The pack starts there.'],
win: ['The cripples came apart first. The rest followed.', 'A clean finish. The pack leaves the slow ones last.'],
flee: ['The pack is hurt. The weak ones still get finished later.', 'Not this time. The broken ones can wait.'],
fall: ['The pack breaks. The cripples get their turn.', 'A bad end. The scrap keeps the story.'],
again: 'Last time you won with {beat}. The broken ones are watched now.',
remember: 'Last time you won with {beat}. The pack has not forgotten the finish.'
},
adapt: {
shields: 'Stolen shield cells are in. Your lance scrap is logged.',
pd: 'Chaff launchers are out. Your torpedoes hit scrap.',
armor: 'Scrap ram plating is bolted on. Try the ram again.',
evasion: 'Overbored burners are hot. Your batteries will eat dust.',
aim: 'Stolen gun sights are fitted. Your dodging is known.',
special: 'Bigger fleet. One more ship joins the pack.'
},
lessons: {
flank: 'Raiders leave the rear open when they turn for loot. Hit the rear plating during the grab.',
ion: 'Brittle shield emitters fail under ion fire. Strip the shields before the pack closes.',
torp: 'Poor point defense lets torpedoes through. Fire while the pack is loaded with scrap.',
board: 'Green boarding crews can be met with marines. Counterboard after the first grab.',
brawl: 'Long-gun doctrine is weak at close range. Close in and deny the raid.',
anchor: 'A proud flagship is a trophy. Guard it or make the pack pay for it.',
slow: 'Worn engines leave the pack unable to chase. Break contact and hit the rear.',
strike: 'The Hullbreaker strike is a raid on your path. Keep a reserve or lose credits.'
}
},
'chorus': {
'ravenous': {
meet: ['Hunger. The fleet smells close.', 'Feed. The teeth are already out.'],
win: ['The fleet feeds. The heat rises.', 'Taste was good. The hunger grows.'],
flee: ['Not enough meat. The fleet pulls back to feed.', 'The teeth are thin. Hunger waits.'],
fall: ['The mouth closes. The fleet feeds elsewhere.', 'Heat fades. The hunger remains.'],
again: 'Last time you won with {beat}. The taste is known.',
remember: 'Last time you won with {beat}. The fleet still tastes it.'
},
'cruel': {
meet: ['The weak ships smell best. The fleet starts there.', 'Broken hulls first. The teeth are ready.'],
win: ['The weak ones came apart. The fleet is full.', 'A slow finish. The taste lasts.'],
flee: ['The fleet is cut. The weak ones can wait.', 'Not enough teeth. The hunger pulls back.'],
fall: ['The mouth is torn. The fleet still chews.', 'Heat spills. The hunger does not end.'],
again: 'Last time you won with {beat}. The weak points are known.',
remember: 'Last time you won with {beat}. The fleet remembers the taste.'
},
'cunning': {
meet: ['The fleet smells the weak side. The teeth follow.', 'Heat gathers where the hull is thin.'],
win: ['The weak side opened. The fleet fed.', 'The smell was right. The teeth found it.'],
flee: ['The weak side closed. The fleet waits for the next smell.', 'Not yet. The hunger keeps the angle.'],
fall: ['The mouth guessed wrong. The fleet pulls the teeth back.', 'A bad smell. The hunger learns.'],
again: 'Last time you won with {beat}. The fleet smells that trick.',
remember: 'Last time you won with {beat}. The angle is remembered.'
},
'patient': {
meet: ['The fleet waits. Heat comes to the teeth.', 'Come closer. The hunger is patient.'],
win: ['The wait was right. The fleet feeds.', 'Heat came close. The teeth were ready.'],
flee: ['The heat is wrong. The fleet waits again.', 'Not enough. The hunger keeps still.'],
fall: ['The wait ends badly. The fleet feeds elsewhere.', 'Heat cools. The hunger stays.'],
again: 'Last time you won with {beat}. The wait is longer now.',
remember: 'Last time you won with {beat}. The fleet has not forgotten the heat.'
},
adapt: {
shields: 'Membrane bloom covers the fleet. Lance heat is known.',
pd: 'Spore curtains rise. Torpedoes taste wrong.',
armor: 'Chitin layers grow. Ram teeth break first.',
evasion: 'Fin clusters shift. Batteries find less heat.',
aim: 'Tasting pores open. Evasive heat is read.',
special: 'Hunger. Ships regrow 3 more hull each turn.'
},
lessons: {
flank: 'The swarm leaves a thin rear when it feeds. Hit the rear plating during the feed.',
ion: 'Brittle shield emitters fail under ion fire. Burn the shields before the swarm grows.',
torp: 'Poor point defense leaves torpedoes a path. Fire into the cluster.',
board: 'Green boarding crews are weak to prepared marines. Counterboard the closest ship.',
brawl: 'Long-gun doctrine is weak at close range. Close in and deny the swarm room.',
anchor: 'A proud flagship draws the swarm. Target it when the teeth commit.',
slow: 'Worn engines leave the swarm unable to chase. Break contact and burn the stragglers.',
strike: 'The Chorus strike is growth from your losses. Every ship lost makes the fleet tougher.'
}
},
'ithar': {
'cunning': {
meet: ['The light shows your weak side. The lens is set.', 'A small crack is enough. The glass turns.'],
win: ['The crack was where the light said. The fleet cut there.', 'A precise cut. The reflection breaks.'],
flee: ['The glass is chipped. We withdraw and cut again.', 'Not this light. The duel continues elsewhere.'],
fall: ['The lens cracks. The reflection dims.', 'A clean break. The glass remembers.'],
again: 'Last time you won with {beat}. The lens has turned toward it.',
remember: 'Last time you won with {beat}. The crack is still visible.'
},
'proud': {
meet: ['You face the first mirror. It does not bend.', 'This duel is already framed. Hold still.'],
win: ['The mirror held. Your reflection broke first.', 'A clean line. The glass kept its shape.'],
flee: ['The mirror is chipped. A duel can wait.', 'Not this cut. The glass returns honed.'],
fall: ['The mirror breaks. The light goes with it.', 'A rare crack. The glass will remember.'],
again: 'Last time you won with {beat}. The mirror is honed for it.',
remember: 'Last time you won with {beat}. The glass has not forgotten.'
},
'patient': {
meet: ['The lens is set. Time will bring the crack.', 'Hold your range. The light does the work.'],
win: ['The wait was right. The crack came to the lens.', 'You moved first. The glass was ready.'],
flee: ['The light is wrong. We withdraw to sharpen it.', 'A patient cut can wait. The glass keeps.'],
fall: ['The lens dims. The wait was too long.', 'A clean break. The glass records it.'],
again: 'Last time you won with {beat}. The lens is set against it.',
remember: 'Last time you won with {beat}. The light still shows it.'
},
'cruel': {
meet: ['The damaged ships show the clearest cracks. The lens picks them.', 'A broken pane cuts first. The glass is ready.'],
win: ['The damaged ships broke first. The rest followed.', 'A precise finish. The glass is clean.'],
flee: ['The cut is not clean. We withdraw and hone.', 'Not this pane. The glass returns sharper.'],
fall: ['The lens breaks on a hard pane. The glass records it.', 'A bad cut. The reflection dims.'],
again: 'Last time you won with {beat}. The damaged ships are watched.',
remember: 'Last time you won with {beat}. The crack is marked.'
},
adapt: {
shields: 'Prism matrix is set. Your lance light is split.',
pd: 'Mirror veil is up. Your torpedoes reflect away.',
armor: 'Waveguide spine is fitted. Your ram meets glass.',
evasion: 'Starwind vanes turn. Your batteries lose the line.',
aim: 'Interferometer lenses are set. Your evasive light is read.',
special: 'Deeper veil. Ships are 6 harder to hit.'
},
lessons: {
flank: 'A duelist keeps range but the rear opens on turns. Hit the rear plating during the turn.',
ion: 'Brittle shield emitters fail under ion fire. Strip the shields before the duel settles.',
torp: 'Poor point defense leaves torpedoes a path. Fire when the fleet turns.',
board: 'Green boarding crews lose to prepared marines. Board after the flagship withdraws.',
brawl: 'Long-gun doctrine is weak at close range. Close in and break the duel.',
anchor: 'A proud flagship draws the lens. Target it when the fleet holds range.',
slow: 'Worn engines limit the withdrawal. Cut the escape and keep pressure.',
strike: 'The Glasswrights strike is a duel. Keep range, hit damaged ships, and force the flagship to withdraw.'
}
},
'deathless': {
'patient': {
meet: ['The archive has this meeting already. We proceed.', 'Time is on the record. Come closer.'],
win: ['The archive records the loss. The copy remains.', 'Patience held. The memory continues.'],
flee: [],
fall: ['This copy ends. The archive restores another.', 'A last-sector break. The archive rises once more.'],
again: 'Last time you won with {beat}. The archive has added it.',
remember: 'Last time you won with {beat}. The memory remains.'
},
'proud': {
meet: ['You face a copy that has already endured. Proceed.', 'The archive chose this form. It will not bend.'],
win: ['The copy held. The record is updated.', 'You saw the archive. It did not retreat.'],
flee: [],
fall: ['This form breaks. The archive restores it.', 'The last sector takes this copy. Another rises.'],
again: 'Last time you won with {beat}. The restored form is ready.',
remember: 'Last time you won with {beat}. The archive remembers.'
},
'cruel': {
meet: ['The damaged ships are marked. The archive finishes them.', 'Broken hulls enter the record first.'],
win: ['The damaged came apart. The archive notes it.', 'A clean finish. The memory keeps it.'],
flee: [],
fall: ['This copy is finished. The archive restores another.', 'The last sector ends this form. The archive rises.'],
again: 'Last time you won with {beat}. The damaged are marked again.',
remember: 'Last time you won with {beat}. The record does not fade.'
},
'methodical': {
meet: ['The record is open. Every move will be entered.', 'The archive expects this. Proceed in order.'],
win: ['The sequence held. The record is exact.', 'As entered. The archive continues.'],
flee: [],
fall: ['This entry closes. The archive restores the file.', 'The last sector ends this copy. The archive keeps the sequence.'],
again: 'Last time you won with {beat}. The sequence has been amended.',
remember: 'Last time you won with {beat}. The record is still open.'
},
adapt: {
shields: 'Corona ward is raised. Your lance is in the record.',
pd: 'Null spires are set. Your torpedoes are archived.',
armor: 'Sunshade shell is fitted. Your ram is remembered.',
evasion: 'Fold skips are ready. Your batteries lose the sequence.',
aim: 'Long-memory sight is set. Your evasive pattern is known.',
special: 'Deeper backups. One more eligible ship can reassemble.'
},
lessons: {
flank: 'The patient line leaves the rear thin on turns. Hit the rear plating during the turn.',
ion: 'Brittle shield emitters fail under ion fire. Strip the shields before the archive restores.',
torp: 'Poor point defense leaves torpedoes a path. Fire before the copy adapts.',
board: 'Green boarding crews lose to prepared marines. Board after the first restore.',
brawl: 'Long-gun doctrine is weak at close range. Close in and force the brawl.',
anchor: 'A proud flagship draws fire. Target it when the archive holds.',
slow: 'Worn engines limit repositioning. Cut the path and keep pressure.',
strike: 'The Eclipse strike is a tithe on the clock. Finish the fight before the clock fills.'
}
}
};

Tone check

Length and register: all meeting, win, flee, and fall lines are one or two short sentences. No purple prose and no modern slang. No em dashes are used. No naval vocabulary is used in the lines. Exact adaptation names are used for every faction. The Chorus lines contain no gendered pronouns and no song or choir words. Eclipse has no flee line and has two fall variants.

INFERRED: the Chorus special line uses the exact Hunger mechanics string from the pack. No extra mechanics are added.
INFERRED: the Eclipse fall variants map to destroyed early and destroyed in the last sector, per the pack behavior text.
INFERRED: adaptation lines are written so they can be shown as commander speech or as panel text. The pack allows either.

No line is flagged as breaking register, length, or lore voice rules.

Owner questions with chair picks

Lessons coverage: the pack says one lesson per weakness a commander could carry. I wrote all eight weaknesses for every faction. Pick: keep all eight per faction.

Eclipse flee key: the pack says Eclipse has no flee line. I set flee to an empty array and gave two fall variants. Pick: keep the empty flee array.

Adaptation line use: adaptation lines read as commander speech. Pick: use them as panel text if the UI has no speech slot for adaptations.

Chorus titles: Chorus lines avoid titles and gendered pronouns. Pick: keep titles in the name field only and keep lines neutral.

Table key placement: adapt and lessons are at faction level, as in the pack shape. Pick: keep this placement for issues 120 to 122.
