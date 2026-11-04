Chair gate note: Qwen3.8-Max verified in the model selector before sending and in the chat header after generation started; both gates passed (run Nov 4, 2026). Single response returned. The leg follows verbatim; non-ASCII punctuation in its review prose was normalized to ASCII by the chair. The table itself is unchanged.

Qwen Leg (Writer): Nemesis Commander Writing, Issue 173 (R85)
Faction Personality Types
Hegemony (hegemony)
Persona
Character read
methodical
Treats your fleet as a data set to be solved on paper before the guns speak; every engagement is a projection to be confirmed.
proud
Believes the Registry's authority is absolute and your resistance is a clerical error to be corrected with force.
patient
Holds position and lets your own urgency feed you into his guns; time is on the side of the one who does not move.
cunning
Feigns a gap, splits the line, and finds the seam you did not know you had; wins by making you solve the wrong problem.
Ashfall Hullbreakers (corsair)
Persona
Character read
cunning
Sets traps with wreck hulks and hits you from the side you are not watching; takes things by being smarter, not bigger.
greedy
Ignores your escorts and goes straight for your richest ship; wants the prize, not the fight.
proud
Wants you to see the kill happen; stands in the open and dares you to stop it.
cruel
Lets your crippled ships sit, then finishes them one by one while you watch; the slow break is the point.
The Chorus (chorus)
Persona
Character read
ravenous
Eats everything closest first; does not choose, consumes; the fleet is a mouth and everything is food.
cruel
Tastes your crippled ships and finishes them slow, savouring the break; the suffering is flavour.
cunning
Waits in the dark between stations, strikes where your hull is thinnest; hunger makes it patient and precise.
patient
Lets you come close, lets you think you are winning, then swallows the gap; the mouth does not chase.
Glasswrights (ithar)
Persona
Character read
cunning
Finds the angle you did not guard and strikes through it like light through a crack in glass.
proud
Duels you openly, flagship against your fleet, and expects the exchange to be clean; honour is precision.
patient
Holds at the edge of range, watching, waiting for you to overextend into the kill zone.
cruel
Picks your most damaged ships and finishes them while you watch; precise, unhurried, grief-coloured.
Eclipse (deathless)
Persona
Character read
patient
Waits across centuries; the hunt is a record being written and it will not rush the entry.
proud
Remembers every fleet it has archived; yours will be another line in the record, shorter than most.
cruel
Erases your ships one by one and files the memory of each breaking; the archive keeps everything.
methodical
Processes your fleet as data, each engagement a correction pass; the model improves with every loss you take.
Paste-Ready Table (data.js format)
js
var NEM_VOICE = {

  hegemony: {

    methodical: {
      meet: [
        'Your fleet composition is logged. Begin standard engagement protocol.',
        'The Registry projects your defeat in four rounds. I intend to finish in three.'
      ],
      win: [
        'Outcome as projected. Log the engagement.',
        'Your losses were within expected parameters. Mine were not.'
      ],
      flee: [
        'Tactical withdrawal. The data will inform the next engagement.',
        'Disengaging to revise projections.'
      ],
      fall: [
        'Projection... failed. Log it. Log all of it.',
        'The data was wrong. Or you were better. Either way, the Registry will note it.'
      ],
      again: 'Last time you won with {beat}. The counter is now standard doctrine.',
      remember: '{beat} is logged. I have not yet solved it. I will.'
    },

    proud: {
      meet: [
        'You are not registered. Correct that omission by surrendering.',
        'The Hegemony does not negotiate with unlisted tonnage.'
      ],
      win: [
        'The Registry was correct. You were insufficient.',
        'Struck from the record. As expected.'
      ],
      flee: [
        'This engagement is beneath resolution. I will return with adequate force.',
        'The Registry does not accept this outcome. Nor do I.'
      ],
      fall: [
        'Struck... from the record. Unacceptable.',
        'The Hegemony will send another. It will not send me.'
      ],
      again: 'You beat me with {beat}. The Registry has issued the correction.',
      remember: 'You won with {beat}. It is noted. It will not stand.'
    },

    patient: {
      meet: [
        'I will hold this position. You will come to me.',
        'There is no urgency. Your fuel is finite. My patience is not.'
      ],
      win: [
        'You came to me. That was the error.',
        'I waited. You did not. The result follows.'
      ],
      flee: [
        'I will wait elsewhere. You will still come.',
        'The position was wrong. The patience remains.'
      ],
      fall: [
        'I waited too long. That is... the lesson.',
        'Stillness was my error. You moved faster than the wait allowed.'
      ],
      again: '{beat} worked once. I have had time to account for it.',
      remember: '{beat}. I remember. I am still thinking.'
    },

    cunning: {
      meet: [
        'Your formation has a gap at third position. I have noted it.',
        'I have read your approach vector. It is predictable.'
      ],
      win: [
        'You saw the line I showed you, not the one I held.',
        'The gap was bait. You took it.'
      ],
      flee: [
        'I have seen enough. Next time the gap will be real.',
        'Withdraw and refit. The next approach will differ.'
      ],
      fall: [
        'The plan had... a seam. You found it.',
        'Outthought. Logged. Finished.'
      ],
      again: '{beat} was clever. I have built the answer into the next approach.',
      remember: '{beat}. I saw it coming and missed. I will not miss twice.'
    },

    adapt: {
      shields: 'Deflector drills complete. Your lance and ion solutions are now projected to fail.',
      pd: 'Picket screens deployed. Torpedo and wing approaches will be intercepted.',
      armor: 'Bow plating reinforced. Ramming and boarding actions are now inadvisable.',
      evasion: 'Attitude drills complete. Your broadside solutions will find less hull to hit.',
      aim: 'Fire-control drills logged. Your evasive doctrine is now countered.',
      special: 'Tight formation ordered. Synchronized fire extends one hex further.'
    },

    lessons: {
      flank: 'The commander had thin stern plating. Flanking fire dealt extra damage. Next Hegemony commander may not share this weakness.',
      ion: 'Shield emitters were brittle. Ion weapons broke through faster than expected.',
      torp: 'Point defense was poor. Torpedoes and wings got through unchallenged.',
      board: 'Boarding crews were green. Boarding actions succeeded more often than projected.',
      brawl: 'The commander favoured long guns. Getting close negated the range advantage.',
      anchor: 'The flagship anchored the formation. Destroying it broke the line.',
      slow: 'Engines were worn. The fleet could not reposition fast enough to respond.',
      strike: 'The Hegemony commander brought reinforcements in round 3. Ending the fight before then, or preparing for the extra ships, would have reduced losses.'
    }
  },

  corsair: {

    cunning: {
      meet: [
        'Saw your path three jumps ago. Been waiting.',
        'You walk into the wreck field. Good.'
      ],
      win: [
        'Took your side while you watched the front. Easy.',
        'The trap worked. You walked in good.'
      ],
      flee: [
        'Not this time. I will be back with more teeth.',
        'Run now. Come back richer.'
      ],
      fall: [
        'Trap... broke. You saw the wires.',
        'Outfoxed. In the wreck field. Of all places.'
      ],
      again: '{beat} worked last time. Wired the trap different now.',
      remember: '{beat}. Saw it. Did not dodge it. Next time I dodge.'
    },

    greedy: {
      meet: [
        'That flagship. I want that one.',
        'Shiny hull. Mine now.'
      ],
      win: [
        'Took the fat one. Rest is scrap.',
        'The prize is mine. What else you got?'
      ],
      flee: [
        'Not worth the blood yet. I will take it later.',
        'Keep the prize warm. I am coming back for it.'
      ],
      fall: [
        'The prize... got me.',
        'Went for too much. Teeth were bigger.'
      ],
      again: 'You hit me with {beat}. Took the lesson. Kept the hunger.',
      remember: '{beat}. Cost me. I do not forget costs.'
    },

    proud: {
      meet: [
        'Look at me. Watch what I take.',
        'I am the Apex. You are the prize.'
      ],
      win: [
        'You saw. You saw me take it. Good.',
        'Stood in the open. You could not stop it.'
      ],
      flee: [
        'I do not die here. Remember my name.',
        'Walk away this time. Next time I stand.'
      ],
      fall: [
        'You... saw me fall. Good. Remember.',
        'The Apex... falls standing.'
      ],
      again: '{beat}. You used {beat} on me. I remember. I am ready.',
      remember: '{beat}. You tagged me with it. I still feel it.'
    },

    cruel: {
      meet: [
        'Your ships look soft. I will open them slow.',
        'I will crack them one at a time and you will hear each one.'
      ],
      win: [
        'Broke them slow. Heard every one go.',
        'They begged. I finished them anyway.'
      ],
      flee: [
        'They are already broken. I will finish them next time.',
        'The killing can wait. I will not.'
      ],
      fall: [
        'Finally. Someone cruel enough.',
        'Broke me like I broke them. Fair.'
      ],
      again: '{beat} hurt. Good. I like it when it hurts both ways.',
      remember: '{beat}. Left a mark. I keep marks.'
    },

    adapt: {
      shields: 'Stolen shield cells bolted on. Your lances and ion fire hit scrap now.',
      pd: 'Chaff launchers welded up. Your torps and wings eat junk.',
      armor: 'Scrap ram plating. You want to board? You want to ram? Hit the scrap first.',
      evasion: 'Overbored burners. We go faster than your broadsides can track.',
      aim: 'Stolen gun sights. You dodge? We aim better now.',
      special: 'Bigger fleet. One more ship joins. Took it. Keeping it.'
    },

    lessons: {
      flank: 'The Hullbreaker had thin stern plating. Flanking fire scored extra hits.',
      ion: 'Shield emitters were brittle. Ion fire cracked them fast.',
      torp: 'Point defense was poor. Torpedoes and wings got clean runs.',
      board: 'Boarding crews were green. Boarding actions went easier than expected.',
      brawl: 'The Hullbreaker favoured long guns. Closing the range negated the advantage.',
      anchor: 'The flagship held the pack together. Killing it scattered the rest.',
      slow: 'Engines were worn. The fleet could not reposition fast enough.',
      strike: 'The Hullbreaker raided your path. When its clock filled, it took credits or a ship. Everything it held came back when it died.'
    }
  },

  chorus: {

    ravenous: {
      meet: [
        'More hull. More heat. More.',
        'Teeth ready. Feed.'
      ],
      win: [
        'More. Always more. Feed.',
        'Consumed. Still hungry.'
      ],
      flee: [
        'Not enough. Will feed elsewhere. Will return hungrier.',
        'Too much heat here. Will find softer meat.'
      ],
      fall: [
        'The hunger... stops. Teeth... still.',
        'Consumed... at last. The mouth goes cold.'
      ],
      again: '{beat} fed on us last time. The mouth knows the taste now. Will not swallow it again.',
      remember: '{beat}. The taste lingers. We have not forgotten.'
    },

    cruel: {
      meet: [
        'Your ships smell soft. Will crack them slow.',
        'Taste the weak ones first. Always.'
      ],
      win: [
        'Cracked them. Tasted the break. Good.',
        'They broke slow. That is the best part.'
      ],
      flee: [
        'The prey fights back. Will let the wounds soften them first.',
        'Not yet ripe. Will wait for the rot.'
      ],
      fall: [
        'Cracked... finally. Something cracked back.',
        'The taste... fades. Good. It was... good.'
      ],
      again: '{beat} cracked us. We remember the pain. The pain teaches.',
      remember: '{beat}. Left a wound. Wounds teach.'
    },

    cunning: {
      meet: [
        'Warm hulls ahead. Thin spots known.',
        'The gap in your line smells like an opening.'
      ],
      win: [
        'The thin spot held. You did not see the teeth.',
        'Ate from the dark. You felt it late.'
      ],
      flee: [
        'The gap closed. Will find another.',
        'Too many teeth pointed here. Will taste a softer side.'
      ],
      fall: [
        'The dark... found something darker.',
        'Outwaited. In the dark. By warmer things.'
      ],
      again: '{beat} found the gap. The gap is sealed. The teeth are new.',
      remember: '{beat}. Felt it in the dark. Will not feel it blind again.'
    },

    patient: {
      meet: [
        'Come closer. The mouth is patient.',
        'Wait. You will bring your heat to us.'
      ],
      win: [
        'You came close. The mouth closed.',
        'The wait fed well.'
      ],
      flee: [
        'The mouth withdraws. The hunger stays.',
        'Will wait deeper. You will still come.'
      ],
      fall: [
        'Waited... too long. The mouth... closes on itself.',
        'The patience... ran out. The hunger did not.'
      ],
      again: '{beat} hurt. The mouth remembers. The wait will be different.',
      remember: '{beat}. Remembered. The wait sharpens memory.'
    },

    adapt: {
      shields: 'Membrane bloom grown. Your lances and ion fire hit wet skin now.',
      pd: 'Spore curtains thick. Your torps and wings choke in them.',
      armor: 'Chitin layers hardened. You want to ram? Want to board? Bite the shell first.',
      evasion: 'Fin clusters grown. Your broadsides track us but we slip the aim.',
      aim: 'Tasting pores opened. We smell your evasive burns before you make them.',
      special: 'Hunger deepens. Ships regrow 3 hull each turn. The fleet feeds and grows.'
    },

    lessons: {
      flank: 'The Chorus flank was soft. Flanking fire tore through the membrane.',
      ion: 'Shield emitters were brittle. Ion fire burned through the bloom.',
      torp: 'Point defense was thin. Torpedoes and wings punched clean holes.',
      board: 'Boarding crews were green. Boarding actions cut deep.',
      brawl: 'The Chorus relied on long-gun doctrine. Closing the range took away the advantage.',
      anchor: 'The lead ship anchored the swarm. Destroying it broke coordination.',
      slow: 'Engines were worn. The swarm could not reposition fast enough.',
      strike: 'The Chorus grew from your losses. Every ship you lost made the fleet tougher. Ending fights fast and losing fewer ships limited the growth.'
    }
  },

  ithar: {

    cunning: {
      meet: [
        'Your formation has a seam. I have found the angle.',
        'Light bends. So will your line.'
      ],
      win: [
        'The angle held. You did not see the light bend.',
        'Through the seam. Clean. As expected.'
      ],
      flee: [
        'The angle is spent. I will find another.',
        'The light shifts. I withdraw to refract elsewhere.'
      ],
      fall: [
        'The angle... closed. You found the seam first.',
        'Outrefracted. The light... goes dim.'
      ],
      again: '{beat} found the seam last time. The glass is cut differently now.',
      remember: '{beat}. I saw the light of it. I did not dodge. I will.'
    },

    proud: {
      meet: [
        'I face you directly. Ship to fleet. Let us see what holds.',
        'The duel begins. I will not hide behind escorts.'
      ],
      win: [
        'The duel is decided. Your fleet was the lesser glass.',
        'I stood in the open. You broke first.'
      ],
      flee: [
        'The duel is not finished. I withdraw to hone the blade.',
        'I step back. The glass will be sharper next time.'
      ],
      fall: [
        'The duel... is lost. The glass breaks. I do not look away.',
        'I stood. I faced you. The shard is clean.'
      ],
      again: '{beat} broke me in the duel. The blade is re-honed.',
      remember: '{beat}. It struck true. I remember the impact. It will not strike twice.'
    },

    patient: {
      meet: [
        'I will hold this distance. Come to me when you are ready.',
        'The range suits me. Close it if you dare.'
      ],
      win: [
        'You overextended. The range closed on my terms.',
        'I waited at the edge. You walked into it.'
      ],
      flee: [
        'The range is wrong. I will find the distance that suits.',
        'I withdraw to the edge. You will still come to me.'
      ],
      fall: [
        'The wait... was too long. The edge... dulled.',
        'I held the range. You broke the distance. Well done.'
      ],
      again: '{beat} worked at that range. The distance has changed.',
      remember: '{beat}. The memory is clear. The glass holds the image.'
    },

    cruel: {
      meet: [
        'Your weakest hull is third from the left. I will start there.',
        'The damaged ones first. Clean. Precise.'
      ],
      win: [
        'The weak ones shattered first. As they do.',
        'Clean breaks. One at a time. Watch the next.'
      ],
      flee: [
        'The breaking can wait. The cracks will deepen in time.',
        'I leave the shards. I will return to finish the cut.'
      ],
      fall: [
        'Shattered... by the ones I left cracked.',
        'The breaker... breaks. The glass remembers.'
      ],
      again: '{beat} cracked me. I remember the fracture line. It will not repeat.',
      remember: '{beat}. Left a crack. I keep the crack. I learn from it.'
    },

    adapt: {
      shields: 'Prism matrix aligned. Your lance and ion fire refracts and scatters.',
      pd: 'Mirror veil drawn. Your torpedoes and wings chase false images.',
      armor: 'Waveguide spine hardened. Ramming and boarding meet solid glass.',
      evasion: 'Starwind vanes tuned. Your broadsides track us but we slip the focus.',
      aim: 'Interferometer lenses ground. Your evasive burns are read before they finish.',
      special: 'Deeper veil drawn. Ships are 6 harder to hit. The glass hides.'
    },

    lessons: {
      flank: 'The Glasswright had thin stern plating. Flanking fire found the seam.',
      ion: 'Shield emitters were brittle. Ion fire cracked the prism.',
      torp: 'Point defense was poor. Torpedoes and wings passed the veil.',
      board: 'Boarding crews were green. Boarding actions broke through the glass.',
      brawl: 'The Glasswright favoured long guns. Closing the range negated the precision.',
      anchor: 'The flagship anchored the duel. Destroying it ended the engagement.',
      slow: 'Engines were worn. The fleet could not reposition to hold the range.',
      strike: 'The Glasswright kept range, picked off damaged ships, and withdrew when the flagship lost shields. It returned honed, not bigger. Pressing during withdrawal or overwhelming the flagship early would have ended the duel faster.'
    }
  },

  deathless: {

    patient: {
      meet: [
        'You are logged. The hunt begins. It will end when the archive is complete.',
        'I have waited longer than your fleet has existed. I will wait longer still.'
      ],
      win: [
        'The entry is written. Your loss is archived.',
        'As expected. The record holds.'
      ],
      flee: [],
      fall: [
        'The archive... persists. I will be restored.',
        'This body ends. The record does not.'
      ],
      fall_final: [
        'The last entry... is written. The archive... closes.',
        'Restored once more. This time... the record ends.'
      ],
      again: '{beat} is archived. The counter is written. It will not work twice.',
      remember: '{beat}. The entry is logged. I have not yet written the counter. I will.'
    },

    proud: {
      meet: [
        'Another fleet for the record. You will be remembered. Briefly.',
        'The archive holds a thousand fleets. Yours will fill one line.'
      ],
      win: [
        'Another line in the archive. Shorter than most.',
        'Remembered. Filed. Done.'
      ],
      flee: [],
      fall: [
        'The record... does not end with this hull.',
        'Filed under: temporary loss. I will return.'
      ],
      fall_final: [
        'The final line... in the archive. It was... a good record.',
        'One more rise. The last. The archive... is complete.'
      ],
      again: '{beat} is in the record. The record has been updated.',
      remember: '{beat}. It is in the archive. Unresolved. It will not stay unresolved.'
    },

    cruel: {
      meet: [
        'Each of your ships will be erased. Each will be filed. I will keep the memory.',
        'I will take them one by one and remember each one breaking.'
      ],
      win: [
        'Erased. Filed. The memory is kept.',
        'One by one. As promised. The record grows.'
      ],
      flee: [],
      fall: [
        'The memory... is saved. The erasure... continues elsewhere.',
        'I am... archived. Not ended.'
      ],
      fall_final: [
        'The last erasure... is filed. The memory... goes dark.',
        'No more copies. The record... is full.'
      ],
      again: '{beat}. I remember the feeling. The memory has been weaponized.',
      remember: '{beat}. The scar is kept. Kept things teach.'
    },

    methodical: {
      meet: [
        'Your fleet composition is archived. Correction protocol engaged.',
        'The data is logged. The correction begins now.'
      ],
      win: [
        'Correction applied. The data improves.',
        'Your losses refine the model. Continue.'
      ],
      flee: [],
      fall: [
        'Data... preserved. Correction... pending.',
        'The model... persists. Rebuild... begins.'
      ],
      fall_final: [
        'Final correction... failed. The data... is complete.',
        'The model... is finished. No more iterations.'
      ],
      again: '{beat} is logged. The correction is applied.',
      remember: '{beat}. The data is recorded. The correction is pending.'
    },

    adapt: {
      shields: 'Corona ward raised. Your lance and ion fire is absorbed into the record.',
      pd: 'Null spires raised. Your torpedoes and wings find nothing to hit.',
      armor: 'Sunshade shell hardened. Ramming and boarding meet dead metal.',
      evasion: 'Fold skips engaged. Your broadsides track the afterimage.',
      aim: 'Long-memory sight restored. Your evasive burns are archived before they happen.',
      special: 'Deeper backups restored. One more eligible ship can reassemble.'
    },

    lessons: {
      flank: 'The Eclipse commander had thin stern plating. Flanking fire scored clean hits.',
      ion: 'Shield emitters were brittle. Ion fire cracked the corona ward.',
      torp: 'Point defense was poor. Torpedoes and wings passed the null spires.',
      board: 'Boarding crews were green. Boarding actions broke through the shell.',
      brawl: 'The Eclipse commander favoured long guns. Closing the range negated the advantage.',
      anchor: 'The flagship anchored the formation. Destroying it disrupted the archive.',
      slow: 'Engines were worn. The fleet could not reposition to maintain formation.',
      strike: 'The Eclipse commander clock moved at half speed but never stopped. When it filled, the hunt drained 6% hull from every ship. Destroying the commander before the clock filled, or spreading hull repairs, limited the drain.'
    }
  }
};
Tone Check
I compared every line above against the shipped samples in this pack (NEM_LINES placeholders, NEM_FAC behaviour text, NEM_ADAPT why strings) and the lore voice rules. Findings:
All Hegemony lines: PASS. Measured, procedural, no shouting. Matches "data, projections, the Registry" voice.
All Corsair lines: PASS. Short, concrete, physical. Trophy and scrap language. No abstraction.
All Chorus lines: PASS. Taste, heat, smell, teeth vocabulary. No he/she pronouns. No song, choir, sing, hymn, or chorus-as-music words. Neuter voice throughout.
All Ithar lines: PASS. Light, glass, reflection, grief imagery. Precise, image-led, restrained. No singing.
All Eclipse lines: PASS. Memory, archive, the lost sun. Flat, old, unhurried. No flee lines. Fall lines reference restoration.
Corsair adapt, evasion: "We go faster than your broadsides can track." PASS. "broadsides" is a shipped weapon term in NEM_BEAT_WORD and NEM_ADAPT why strings. Not naval-posture usage.
Ithar adapt, evasion: "Your broadsides track us but we slip the focus." PASS. Same as above. Shipped weapon term.
Deathless adapt, evasion: "Your broadsides track the afterimage." PASS. Same.
Chorus adapt, evasion: "Your broadsides track us but we slip the aim." PASS. Same.
Eclipse patient meet: "I have waited longer than your fleet has existed." PASS. Flat, old, unhurried. No naval terms.
All lesson lines: PASS. Written to the player. Short, factual, debrief register. No commander voice.
Corsair cruel meet: "I will crack them one at a time and you will hear each one." PASS. Concrete, physical, violent. Fits "takes things and says so."
Chorus cunning meet: "The gap in your line smells like an opening." PASS. Smell/taste vocabulary. No gendered pronouns.
Hegemony proud meet: "The Hegemony does not negotiate with unlisted tonnage." INFERRED. "Tonnage" is not in the shipped text. It fits the procedural Registry voice but is not directly attested. Flagging for chair.
Ithar proud flee: "I withdraw to hone the blade." INFERRED. "Blade" metaphor is not in the shipped Glasswright text, which uses glass/light imagery. Fits the duelist persona but is slightly off-voice. Flagging for chair.
Eclipse cruel adapt, aim: "Long-memory sight restored. Your evasive burns are archived before they happen." INFERRED. "Archived before they happen" implies precognition, which is not in the pack. The adaptation is aim (counters evasive). The line should say the sight reads your burns, not predicts them. Flagging for chair.
No em dashes appear anywhere in the table. No naval vocabulary (keels, sailing terms, helm, bow-as-ship-front used as posture). "Broadside" appears only as the shipped weapon term. No song or choir words in any Chorus line. No gendered pronouns in any Chorus line. No invented personas, adaptations, weaknesses, or mechanics.
Owner Questions (with chair picks)
Q1. Hegemony proud meet uses "tonnage." The shipped text does not use this word. Should I replace it with "ships" or "fleet" for safety, or does "tonnage" fit the Registry procedural voice well enough to keep?
Pick: Keep "tonnage." It reads as procedural and data-flavoured, which matches the Hegemony voice. It is not naval-posture language.
Q2. Ithar proud flee uses "hone the blade." The Glasswright lore voice is glass, light, reflection, grief. Should the metaphor be "hone the glass" or "sharpen the lens" instead?
Pick: Change to "I withdraw to sharpen the lens." Keeps the duelist intent and stays in glass/light vocabulary.
Q3. Eclipse adapt aim says "archived before they happen," which could imply precognition. The adaptation is Gunnery drills (you won by staying hard to hit). Should the line say "read" instead of "archived before they happen" to avoid implying a mechanic not in the pack?
Pick: Change to "Long-memory sight restored. Your evasive burns are read and answered." Removes the precognition implication.
Q4. The Chorus special adaptation is called "Hunger" in NEM_ADAPT_FAC. The flavour line says "The fleet feeds and grows." Should the line name the adaptation explicitly ("Hunger deepens") or let the panel show the name separately?
Pick: Keep "Hunger deepens" in the line. The pack says the adaptation flavour names the adaptation by its NEM_ADAPT_FAC name. The panel may also show it, but the line should carry the name for audio/text fallback.
Q5. Eclipse fall_final lines reference "the archive closes" and "the record ends." The pack says destroyed in the last sector, the Eclipse commander "rises once more for one final fight." Should the fall_final lines acknowledge this is the final death (no more reassembly), or leave it ambiguous?
Pick: Acknowledge finality. The pack says "one final fight," implying no further restoration. The lines should close the arc. Keep "The archive closes" and "No more iterations" as written.
End of Qwen leg.
