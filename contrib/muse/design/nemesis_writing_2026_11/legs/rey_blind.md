# Blind Rey leg: issue 173, Nemesis commander writing (R85)

Written blind, from the issue 173 evidence pack alone, before reading any other leg. All lines are plain, short, in-game English. No em dashes. No naval vocabulary. Chorus lines carry no gendered pronouns and no song or choir words.

Table notes for the chair and for Codex (issues 120 to 122):

- The table follows the pack shape exactly: NEM_VOICE keyed by faction, then persona, with meet / win / flee / fall arrays, again and remember strings, then a faction-level adapt object and lessons object.
- One addition: each persona object opens with a read field, the one-line character read the issue asks for. Codex can drop it or surface it in the Nemesis panel; it costs nothing to keep.
- deathless (Eclipse) never retreats, so flee is an empty array for all four personas. The fall array carries four variants in a fixed order: the first two are destroyed early, the last two are destroyed in the last sector (the rise-once-more fight). See owner question 2.
- Lessons are written pronoun-free on purpose, so one lesson set serves every commander of a faction, male or female. See owner question 3.
- Spoken lines use he/him lightly or stay pronoun-free, so the runtime pronoun swap (nemSay) can carry them.

```js
NEM_VOICE = {
hegemony: {
  methodical: {
    read: 'A Line Admiral who has already run this battle as a projection; speaks in filings and outcomes, never in threats.',
    meet: ['The Registry has your fleet on file. The projection is not in your favour.', 'Every approach you can make has been projected. Proceed anyway.'],
    win: ['Outcome as projected. The file is updated.', 'Your losses have been recorded. Withdraw and save what remains.'],
    flee: ['Withdrawal logged. The drills will be tighter when we meet again.', 'You leave on schedule. Ours. The next filing will not favour you.'],
    fall: ['Record the result. The formation holds to the last entry.', 'Projection failed. File the correction under my name.'],
    again: 'Last time you won with {beat}. The counter-drill is filed. It will not work twice.',
    remember: 'Last time you won with {beat}. That result is in the Registry. It has not been forgotten.'
  },
  proud: {
    read: 'A Fleet Marshal who treats the artillery line as a ceremony of rank; the flagship goes first and is always announced.',
    meet: ['You face the flagship first. That is the order of things.', 'Announce yourself to the line. It will answer in full.'],
    win: ['The line holds, and the flagship leads it still. Remember both.', 'Victory, recorded with the flagship at the front, as it should be.'],
    flee: ['Running is also a formation. Yours is poor.', 'You withdraw before the flagship. The record will say so.'],
    fall: ['The flagship falls first among equals. Enter it so.', 'If the line breaks, it breaks around me. That is the post.'],
    again: 'Last time you won with {beat}. Rank does not excuse a repeat. The line has drilled against it.',
    remember: 'Last time you won with {beat}. A flagship remembers an insult longer than a wound.'
  },
  patient: {
    read: 'A First Admiral content to let the clock and the Registry do the work; reinforcements are a schedule, not a surprise.',
    meet: ['There is time. Come closer, and the line will do the rest.', 'The clock is patient, and so is this fleet. Approach when ready.'],
    win: ['Patience, confirmed again. Your file grows; your fleet does not.', 'You came to us, as expected. The outcome was filed before you arrived.'],
    flee: ['Withdrawals are expected at this stage. Round three was not.', 'Go. The schedule brings us together again, fuller than before.'],
    fall: ['Even this was allowed for. It changes nothing that follows.', 'The wait ends here. The Registry keeps the rest.'],
    again: 'Last time you won with {beat}. Waiting has its uses. We used it to drill the counter.',
    remember: 'Last time you won with {beat}. Nothing filed is ever lost. Neither is that.'
  },
  cunning: {
    read: 'A High Commodore who files false projections and strikes the flank the report said was safe.',
    meet: ['Your weak points are clear. The projection says which one we use first.', 'The report on your flank was favourable. For us.'],
    win: ['The flank folded as filed. Projections improve with practice.', 'You guarded the wrong side. The Registry notes your habits.'],
    flee: ['You withdraw toward the side we left open. Noted, for next time.', 'Run the route we measured. It will be closed when you return.'],
    fall: ['A projection can be wrong. File this one under rare errors.', 'The flank was mine to hold. Enter the failure plainly.'],
    again: 'Last time you won with {beat}. The flank you used has been refiled as a trap.',
    remember: 'Last time you won with {beat}. The Registry remembers the route you took.'
  },
  adapt: {
    shields: 'Deflector drills, entered into the standing orders. Your lances will find less.',
    pd: 'Picket screens are posted. Your torpedoes will be counted before they arrive.',
    armor: 'Bow plating, fitted and filed. Ram us and read the result.',
    evasion: 'Attitude drills, effective immediately. The line will not sit still for your guns.',
    aim: 'Fire-control drills are complete. Being hard to hit is no longer a defence.',
    special: 'Tight formation. The line fires as one, and reaches one hex further.'
  },
  lessons: {
    flank: 'The stern plating was thin. Flank shots ended fights the line could not answer.',
    ion: 'The shield emitters were brittle. Ion fire stripped the line faster than guns could.',
    torp: 'The point defense was poor. Torpedoes got through where shells did not.',
    board: 'The boarding crews were green. A taken ship stayed taken.',
    brawl: 'The doctrine was long guns. Closing in broke the plan before the line.',
    anchor: 'The flagship led every fight. Killing it broke the formation around it.',
    slow: 'The engines were worn. The fleet could not choose the range, so you did.',
    strike: 'Reinforcements always came in round 3. Fights won before then stayed won.'
  }
},
corsair: {
  cunning: {
    read: 'A Den-alpha who counts your weakest ship before counting your guns, and starts the hunt there.',
    meet: ['Counted your weak ship already. The pack eats that one first.', 'Your flank smells soft. We start there.'],
    win: ['Took what I came for. Come back with more and I will take that too.', 'Your weak ship is scrap now. The rest is just slower.'],
    flee: ['I leave rich and I come back bigger. Chase me and lose twice.', 'Not running scared. Running loaded. There is a difference.'],
    fall: ['Take my wreck, then. The pack remembers who fed on it.', 'You got me this once. Guts out, still grinning.'],
    again: 'Last time you won with {beat}. The pack patched that hole. Try it and bleed.',
    remember: 'Last time you won with {beat}. The den remembers a thief.'
  },
  greedy: {
    read: 'A Warlord who prices your flagship in the middle of the battle and says the price out loud.',
    meet: ['Your flagship. I have priced it. I am here to collect.', 'Rich ship, soft escort. Bad way to travel.'],
    win: ['Told you the price. Paid in full, in hull.', 'Your best ship is mine now, or it is scrap. Either way I ate.'],
    flee: ['I take what I can carry and go. Your flagship keeps. For now.', 'A full hold beats a dead hero. I will be back for the rest.'],
    fall: ['Wanted your flagship. Got your guns instead. Fair trade, near enough.', 'Bury me in scrap. It was always the plan.'],
    again: 'Last time you won with {beat}. You guarded the prize. I counted the cost and changed the hunt.',
    remember: 'Last time you won with {beat}. I still want your flagship. Wanting keeps.'
  },
  proud: {
    read: 'An Apex who leads with his own hull, expects the pack to watch, and treats retreat as a story problem.',
    meet: ['I come first. My hull, my guns, then the pack. Watch the order.', 'Apex does not hide behind the den. You get me first.'],
    win: ['First in, last standing. That is what Apex means.', 'You broke on my hull and the pack fed on the pieces.'],
    flee: ['I do not flee. I take my winnings and walk. There is a difference and you know it.', 'Leaving with kills is not losing. Count yours, then count mine.'],
    fall: ['First in. Last out. Write it on the wreck.', 'The pack saw me fall at the front. That buys them the next fight.'],
    again: 'Last time you won with {beat}. I stood in front of it. This time the front moves.',
    remember: 'Last time you won with {beat}. An Apex does not forget being beaten in the open.'
  },
  cruel: {
    read: 'A First Claw who finishes crippled ships first, in order, and keeps the pieces as proof.',
    meet: ['Your crippled ships die first. I like the order tidy.', 'Weak hulls first. It saves time and it scares the rest.'],
    win: ['Finished your wounded one by one. Watched the rest learn.', 'Your cripples fed the pack. The healthy ones ran out of friends.'],
    flee: ['I leave your wounded alive. That is not mercy. That is bait.', 'Gone to sharpen up. Your cripples will keep until I return.'],
    fall: ['Killed my share before you got me. The count still favours me.', 'You finished me the way I finish yours. No complaint.'],
    again: 'Last time you won with {beat}. I finish wounded ships. This time I start with yours earlier.',
    remember: 'Last time you won with {beat}. I remember every hull you left limping away.'
  },
  adapt: {
    shields: 'Stolen shield cells, wired in. Your lances hit property now.',
    pd: 'Chaff launchers on every hull. Your torpedoes chase scrap, not ships.',
    armor: 'Scrap ram plating, bolted thick. Ram again and keep the change.',
    evasion: 'Overbored burners. The pack moves like it stole the engines too.',
    aim: 'Stolen gun sights, fitted. Hiding got harder for you.',
    special: 'Bigger fleet. One more ship joins the pack, and it is hungry too.'
  },
  lessons: {
    flank: 'The stern plating was thin. Hit from behind, the pack folded before it could turn.',
    ion: 'The shield emitters were brittle. Ion fire stripped ships the den could not replace.',
    torp: 'The point defense was poor. Torpedoes bit deep before the guns answered.',
    board: 'The boarding crews were green. Taken ships turned their guns on the pack.',
    brawl: 'The doctrine was long guns. Getting close broke the hunt.',
    anchor: 'The flagship led the pack. When it died, the raid died with it.',
    slow: 'The engines were worn. The fleet could raid or run, never both.',
    strike: 'When the clock filled, the take was credits, or a weak ship from a fleet of three or more. Everything taken came back when the commander died.'
  }
},
chorus: {
  ravenous: {
    read: 'A Maw-mother that swarms whatever is closest; every line is appetite, with no interest in anything past the next hull.',
    meet: ['More meat on the move. Come closer. The mouths are open.', 'Closest first. Whatever is closest gets eaten. Stay close and find out.'],
    win: ['Fed. Still hungry. There is always a next course.', 'Your ships went down warm. The taste stays. Come back with more.'],
    flee: ['Full mouths drift off. Empty ones return. Both come back.', 'Not gone. Only digesting. Hunger remembers the way back.'],
    fall: ['Eaten at last. The teeth close slow.', 'This mouth shuts. Others open. That is the whole of it.'],
    again: 'Last time the meal was {beat}. The taste is known now. The mouths have grown around it.',
    remember: 'Last time the meal was {beat}. The taste is kept. Nothing swallowed is forgotten.'
  },
  cruel: {
    read: 'An Elder Throat that finishes the wounded first, because wounded flesh is easier to eat and fear seasons the rest.',
    meet: ['Wounded first. Wounded flesh gives easiest.', 'The limping ones. Always the limping ones. Softest meat, soonest meal.'],
    win: ['The crippled went down one at a time. The healthy watched. Watching seasons the meat.', 'Finished the weak first. The strong tasted of fear after.'],
    flee: ['The wounded are left alive. Left meat ripens. Return is certain.', 'Drifts off with a full throat. The cripples keep. Meat keeps.'],
    fall: ['Bitten down at last. The teeth were old and the work was good.', 'This throat closes. The wounded it took are still gone. Count them.'],
    again: 'Last time the meal was {beat}. The weak are watched now. Feed differently or starve.',
    remember: 'Last time the meal was {beat}. The taste of it sits in the flesh still.'
  },
  cunning: {
    read: 'A Gorge-mind that plans the meal: strikes flanks and the weakest ship, hunger with patience behind it.',
    meet: ['The weakest hull has a smell. The mouths already know it.', 'Flanks are soft. Soft is where the teeth go first.'],
    win: ['The weak one folded and the rest followed the smell of it.', 'Struck where the plating thinned. The meal arranged itself after.'],
    flee: ['Slides off sideways, fed and patient. The weak hull keeps its smell.', 'Gone around the flank. The return comes from the same side.'],
    fall: ['Out-thought and eaten by turns. The teeth close on nothing now.', 'The plan was sound. The hull was not. Both are meat now.'],
    again: 'Last time the meal was {beat}. The flank that fed it is watched by more eyes now.',
    remember: 'Last time the meal was {beat}. The weak spot in the winning is tasted and kept.'
  },
  patient: {
    read: 'A Spawn-mother that waits for you to drift close enough to taste, and grows while it waits.',
    meet: ['No hurry. Hunger waits better than fear does. Come close.', 'Drift nearer. The mouths open slow and shut fast.'],
    win: ['Waited. Fed. The order never changes.', 'You came close, as hunger knew you would. The rest was chewing.'],
    flee: ['Patience withdraws to ripen. Nothing is abandoned, only aged.', 'Slow to come, slow to go. The return is the slow part you should fear.'],
    fall: ['Waited too long, perhaps. The teeth are still proud of the work.', 'This patience ends in pieces. Hunger does not end. It moves.'],
    again: 'Last time the meal was {beat}. Waiting since then. The counter grew in the quiet.',
    remember: 'Last time the meal was {beat}. Patience keeps every taste. Yours is kept.'
  },
  adapt: {
    shields: 'Membrane bloom. Fresh skin over the wounds. Lance it and watch it close.',
    pd: 'Spore curtains hang thick. Torpedoes choke on the way in.',
    armor: 'Chitin layers, grown over. Ramming cracks teeth here.',
    evasion: 'Fin clusters wake. The mass moves like small things now.',
    aim: 'Tasting pores open along the hulls. Hiding has a smell, and the smell is found.',
    special: 'Hunger. The flesh knits faster now. What is torn comes back hungrier.'
  },
  lessons: {
    flank: 'The stern plating was thin. Flank hits folded the swarm before it could turn.',
    ion: 'The shield emitters were brittle. Ion fire stripped the mass faster than flesh could close.',
    torp: 'The point defense was poor. Torpedoes reached the flesh where guns only grazed.',
    board: 'The boarding crews were green. Taken hulls stopped feeding the swarm.',
    brawl: 'The doctrine was long guns. Closing in broke the feeding pattern.',
    anchor: 'A proud flagship led the mass. Killing it scattered the swarm.',
    slow: 'The engines were worn. The swarm could not choose where the feeding happened.',
    strike: 'Every ship lost anywhere made this fleet 4% tougher, up to 32%. Losses fed it even in fights it never joined.'
  }
},
ithar: {
  cunning: {
    read: 'A Lens-keeper who has measured your flank in light and strikes where the reflection thins.',
    meet: ['Your flank catches the light badly. I have already measured where it thins.', 'A reflection shows two fleets. Only one of them is lying about its flank.'],
    win: ['The light found your weak ship first. It usually does.', 'You watched the wrong reflection. The strike was in the other one.'],
    flee: ['I withdraw with the glass unbroken where it matters. The duel keeps its appointment.', 'Range is a courtesy I extend to myself. We will resume it.'],
    fall: ['The prism cracks along a line I did not see. Grief, then dark.', 'Note the angle of my fall. Even this teaches the next lens.'],
    again: 'Last time you won with {beat}. I have reground that lens. It will not focus the same way twice.',
    remember: 'Last time you won with {beat}. Glass keeps the image. So do I.'
  },
  proud: {
    read: 'A Duelist who opens with his own flagship and treats range and order as matters of honour.',
    meet: ['My flagship opens the duel. Yours is welcome to answer first.', 'I lead from the front, in full light. There is no other honest range.'],
    win: ['The flagship holds the light, and the duel ends as it began. In the open.', 'Victory, taken from the front. Anything less would not be kept.'],
    flee: ['I withdraw as the terms allow, flagship first, in plain sight.', 'The duel is postponed at the proper range. My flagship leaves as it arrived, ahead.'],
    fall: ['The flagship breaks in full light. Grief is at least witnessed.', 'If I fall, I fall forward. The lens faces the light to the end.'],
    again: 'Last time you won with {beat}. A duelist studies the stroke that beat him. It is studied.',
    remember: 'Last time you won with {beat}. The image is kept in the glass, unblurred.'
  },
  patient: {
    read: 'A First Mirror who waits at range for you to close, grief held flat and quiet behind precise aim.',
    meet: ['There is light enough to wait in. Come closer when you are ready.', 'I keep my range. Grief is patient, and so is aim.'],
    win: ['You closed the distance for me. The rest was focus.', 'Patience, resolved into light. Your fleet dims; the duel is recorded.'],
    flee: ['I withdraw when the shields fail, as agreed with myself long ago. The duel is postponed, not lost.', 'Distance again. I will be at the far end of it, waiting.'],
    fall: ['The wait ends in breaking glass. Even this was seen from far off.', 'I fall at range, quietly. The light goes out one facet at a time.'],
    again: 'Last time you won with {beat}. I have spent the interval at range, adjusting for it.',
    remember: 'Last time you won with {beat}. Mirrors do not hurry, and they do not forget.'
  },
  cruel: {
    read: 'A Keeper of Astra who picks off your most damaged ships one by one, each loss recorded like a dimming.',
    meet: ['Your most damaged ship will go first. I keep the losses in order.', 'I pick off the dim ones. Watch the light leave your fleet in sequence.'],
    win: ['One by one, as promised. The dim ships first; the bright ones learned.', 'Your wounded are dark now. The rest of the fleet shines less for it.'],
    flee: ['I leave your wounded lit for later. A postponed loss is still a loss.', 'Withdrawal, with the tally unfinished. I keep tallies.'],
    fall: ['The picker of dim ships dims. There is a symmetry I refuse to enjoy.', 'My glass breaks. The losses I dealt remain dealt. Count them in the dark.'],
    again: 'Last time you won with {beat}. I have reviewed each of my losses since. The counter is in the aiming.',
    remember: 'Last time you won with {beat}. Cruelty has a good memory for faces and for methods. Yours is kept.'
  },
  adapt: {
    shields: 'Prism matrix, raised. Your lances will scatter before they bite.',
    pd: 'Mirror veil, spread wide. Torpedoes will strike reflections and die in them.',
    armor: 'Waveguide spine, reinforced. Ram the hull and the light carries the blow away.',
    evasion: 'Starwind vanes, trimmed for drift. Broadsides will find only the afterimage.',
    aim: 'Interferometer lenses, aligned. Hiding in glare is no longer possible.',
    special: 'Deeper veil. The fleet dims by six points of certainty. Aim well, if you can find us.'
  },
  lessons: {
    flank: 'The stern plating was thin. From the flank, the careful range did not matter.',
    ion: 'The shield emitters were brittle. Ion fire stripped the protection the duel depended on.',
    torp: 'The point defense was poor. Torpedoes arrived where the lenses were not looking.',
    board: 'The boarding crews were green. A boarded ship left the duel entirely.',
    brawl: 'The doctrine was long guns. Closing in ended the duel on your terms.',
    anchor: 'The flagship led the duel. When it fell, the fleet lost its focus with it.',
    slow: 'The engines were worn. The range the doctrine needed could not be held.',
    strike: 'The duel was fought at range, and the withdrawal came once the flagship lost its shields and dropped under 60% hull. Chasing rarely paid; the fleet returned honed, never bigger.'
  }
},
deathless: {
  patient: {
    read: 'An Archivist whose clock runs at half speed because it has read this ending before; waits without urgency and never retreats.',
    meet: ['The archive has a copy of this meeting. It does not end well for you.', 'My clock runs at half speed. I have time you do not. Approach.'],
    win: ['As stored. Your fleet is smaller in the new copy.', 'The hunt took its tithe and the archive grew. Your fleet did not.'],
    flee: [],
    fall: ['Destroyed early. Irrelevant. The copy reassembles and the hunt resumes.', 'A hull is a draft. The restored copy is already waking.', 'Destroyed in the last sector. Then I rise once more. One final fight, as archived.', 'Even the last sector is not an ending. Once more, and then the archive closes.'],
    again: 'Last time you won with {beat}. The restored copy has read the record. It will not work twice.',
    remember: 'Last time you won with {beat}. Copies forget nothing. That result is kept in full.'
  },
  proud: {
    read: 'A High Nadir who leads from the front in every copy; the flagship is the first entry in the archive.',
    meet: ['The flagship leads, as it led before the sun was lost. You face the first entry first.', 'I do not send others ahead of my own hull. That was true in the first copy too.'],
    win: ['The front held. It has held in every copy so far.', 'Victory, filed under the flagship. The flagship is still here to file it.'],
    flee: [],
    fall: ['The flagship falls early. The archive notes it and sends the next copy forward.', 'A draft destroyed. The author remains.', 'In the last sector, even this. I rise once more, flagship first, for the final fight.', 'The first entry is struck out at the end of all things. Once more, then.'],
    again: 'Last time you won with {beat}. The flagship that returns has studied the copy that fell.',
    remember: 'Last time you won with {beat}. Pride survives restoration. So does the record.'
  },
  cruel: {
    read: 'An Eclipse-prime that finishes crippled ships first and files each wreck; tidiness as a threat.',
    meet: ['Crippled ships are finished first. The archive prefers tidy losses.', 'Your wounded will be filed as destroyed before the healthy are addressed.'],
    win: ['The cripples were closed out one by one. The healthy watched their entries prepared.', 'Finished ships stay finished. That is the whole mercy on offer.'],
    flee: [],
    fall: ['Destroyed early. The restored copy resumes the filing where this one stopped.', 'Tidiness, interrupted. The next copy completes it.', 'Destroyed in the last sector. I rise once more to close your file instead.', 'The last sector, and still I return. One final fight. Make the entry count.'],
    again: 'Last time you won with {beat}. The method is filed under your name, with a counter attached.',
    remember: 'Last time you won with {beat}. What is filed under cruelty is never misfiled.'
  },
  methodical: {
    read: 'An Archivist who advances cautiously under fire, every move copied from a stored pattern older than the sector.',
    meet: ['Every move you can make has been copied from an older battle. Proceed through them.', 'The advance is cautious and the pattern is stored. You are inside it already.'],
    win: ['The pattern held. It usually does, given enough copies.', 'Advanced, fired, recorded. Your losses are now part of the pattern.'],
    flee: [],
    fall: ['Destroyed early. The pattern reruns with a restored hull and the same orders.', 'A cautious advance, ended. The archive keeps the caution and replaces the hull.', 'Destroyed in the last sector. The pattern allows one more run. This is it.', 'The final copy advances once more. After that, the archive is silent.'],
    again: 'Last time you won with {beat}. The pattern has been revised at exactly that point.',
    remember: 'Last time you won with {beat}. Patterns remember what hulls cannot.'
  },
  adapt: {
    shields: 'Corona ward, restored pattern. Your lances strike light and are spent.',
    pd: 'Null spires, raised from the archive. Torpedoes end in silence here.',
    armor: 'Sunshade shell, refitted. Ram it and learn what the old hulls knew.',
    evasion: 'Fold skips, recalibrated. Your broadsides arrive where the fleet was.',
    aim: 'Long-memory sight, aligned. Nothing that has been seen once can hide again.',
    special: 'Deeper backups. One more ship is eligible to reassemble. The archive provides.'
  },
  lessons: {
    flank: 'The stern plating was thin. Even restored copies carried the same flaw.',
    ion: 'The shield emitters were brittle. Ion fire stripped hulls older than the sector.',
    torp: 'The point defense was poor. Torpedoes reached ships the archive valued.',
    board: 'The boarding crews were green. A taken ship was a copy turned against its maker.',
    brawl: 'The doctrine was long guns. Closing in shortened fights meant to stretch.',
    anchor: 'The flagship led every copy. Killing it broke the pattern around it.',
    slow: 'The engines were worn. Even patience needs the range it chooses.',
    strike: 'The clock ran at half speed, but when it filled the hunt drained 6% hull from every ship, never below 1. There was no retreat: destroyed early meant reassembly, and in the last sector, one more rising.'
  }
}
}
```

## Tone check

Checked against the shipped samples in the pack (NEM_LINES placeholders, the NEM_ADAPT why strings, and the NEM_FAC behaviour text).

- Length and register: the shipped placeholders run one or two short sentences ("Your weak points are clear.", "There is time to wait. Come closer."). Every meet, win, flee and fall line here is one or two sentences of the same weight. The debrief lessons run slightly longer where they carry a mechanic (the strike lessons), matching the behaviour text register rather than the spoken register. No line uses modern slang or purple prose.
- Carried-forward anchors: four shipped meets are deliberately echoed, not replaced, so the pools feel continuous with what players have seen: hegemony cunning still opens on "Your weak points are clear", hegemony patient keeps "There is time. Come closer", deathless methodical keeps "Every move you can make has been planned for" in archive wording, and every again line keeps the shipped "Last time you won with {beat}" frame (see owner question 1 for the Chorus exception).
- Faction voices: hegemony lines stay procedural (Registry, filings, drills) and never shout. Corsair lines are short, concrete and take things out loud. Ithar lines are image-led and restrained (light, glass, reflection, grief) and speak normally, with no colour-as-speech. Deathless lines are flat and old (archive, copies, the lost sun).
- Chorus rules: no Chorus line, adaptation line or lesson uses he, she, him or her, and none uses song, choir, sing, chant or hymn vocabulary. The Chorus voice runs on taste, heat, smell, teeth and flesh only. The second throat called Memory is not named in any line; it is story text only, so the remember lines say the taste is kept instead (INFERRED: this is the conservative reading of the pack rule, flagged for the chair).
- Chorus again and remember lines break the shipped frame on purpose: they read "Last time the meal was {beat}" because "you won with" is a human frame the Chorus would not use. The {beat} token is untouched. Flagged as owner question 1.
- Naval check: no keels, masts, sails or sailing words anywhere. "Bow plating" appears only because it is the shipped NEM_ADAPT_FAC name for the hegemony armor counter, which the adaptation line is required to use. "Broadsides" appears in two evasion adaptation lines; it is the shipped weapon term in the NEM_ADAPT why strings ("you leaned on broadsides and batteries"), not a posture or sailing usage.
- Lines I flag myself (INFERRED, chair may cut): ithar cunning meet variant 2 ("A reflection shows two fleets...") is the most image-heavy line in the set and sits at the edge of the plain register. Corsair proud flee lines argue with the slot itself ("I do not flee"); that is the persona talking, and the behaviour rule still fires, but if the UI labels the moment as flight the chair may prefer the greedy or cunning variants to carry proud commanders too. Deathless win variant for patient ("The hunt took its tithe...") borrows the strike mechanic into a win line; it is accurate to the pack but mixes contexts.
- Mechanics check: no line invents a persona, adaptation, weakness or mechanic. Every adaptation line names its shipped NEM_ADAPT_FAC name. Every lesson teaches only the weakness it is keyed to or the faction strike behaviour from the pack (round 3 reinforcements, the raid take and its return on death, feeding at 4% up to 32%, the duel withdrawal terms, the tithe at 6% hull with a floor of 1).

## Owner questions (chair picks first)

1. Return-line frame: the Chorus again and remember lines use "Last time the meal was {beat}" instead of the shipped "Last time you won with {beat}". Pick: keep the Chorus variant. The {beat} token is identical, the pool is per faction now, and a Chorus that says "you won" breaks voice in every return meeting.
2. Deathless fall split: this leg delivers one fall array per persona with an order convention (early, early, late sector, late sector). Pick: split it into separate falle and falll keys for deathless in the final table. Issue 121 has to select by sector, and selecting by array position is a bug waiting to happen.
3. Lesson pronouns: this leg writes all lessons pronoun-free so one set serves male and female commanders of a faction. Pick: keep pronoun-free lessons. The alternative, per-commander gendered lessons, doubles the table for no player-visible gain.
4. Persona and title binding: the persona reads tie each type to a title flavour (the cunning Hegemony commander reads as a High Commodore, the proud one as a Fleet Marshal), but the generator draws titles independently. Pick: no binding. The reads describe the centre of each type; titles stay free, and a cunning Fleet Marshal still reads fine.
5. Adaptation line delivery: the lines are written in first person so nemSay can speak them at the meeting where the adaptation lands, and they also read cleanly as panel text. Pick: speak them when a meeting context exists, panel text otherwise; do not rewrite separate panel versions.
