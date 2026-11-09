# Sunward Crusade text table: NEM_VOICE (issue 296)

Chair-merged from the writer legs (blind Rey, DeepSeek, Qwen) with Flash and Grok in the ideation seat only; Argon blocked since Nov 5. This is the voidsworn block that text_table.md is missing: paste it into data.js beside the other five faction blocks, in the same shape (data.js style: single quotes, unquoted keys, ASCII only). {beat} is substituted by nemSay with a NEM_BEAT_WORD value (lances, torpedoes, your wings, rams, boarding parties, massed batteries, speed and evasion). Pronouns in spoken lines are swapped by nemSay at runtime. The Crusade never flees (data.js beh.noFlee), so flee is an empty pool, the same shape as Eclipse. The Crusade has no revive, so there is no fall_final. Lessons are pronoun-free as a set.

```js
voidsworn: {
  zealous: {
    meet: ['The oath brought us here. Your hull will burn before the dawn watch ends.', 'Who carries the dawn? We do. And you are what we burn to keep it.'],
    win: ['The debt is paid in fire. Your name goes on the hull in chalk.', 'Dawn breaks over the broken line. The debt was collected.'],
    flee: [],
    fall: ['The flagship burns and the oath holds. Chalk the name.', 'The oath does not end with the hull. Chalk my name and keep burning.'],
    again: 'Last time you won with {beat}. The charge comes the same way, only harder.',
    remember: 'Last time you won with {beat}. The name is chalked. The debt is not forgotten.'
  },
  proud: {
    meet: ['This flagship leads the dawn watch. Answer the oath or break against it.', 'You face the front of the line. We come no other way.'],
    win: ['The front held. It always holds. Your fleet broke against the oath.', 'You saw the dawn line. You could not break it.'],
    flee: [],
    fall: ['The front falls. Chalk the name and let the line close over the gap.', 'A proud hull breaks. The brand stays. The Crusade does not stop for one name.'],
    again: 'Last time you won with {beat}. The front is braced for it now.',
    remember: 'Last time you won with {beat}. The front has not forgotten.'
  },
  cruel: {
    meet: ['The crippled ships go first. The cold takes the rest.', 'Your weakest hulls are marked. The brand goes where the frost is thinnest.'],
    win: ['The broken ones went down first. The rest followed into the cold.', 'A slow burn. Each hull chalked, each name spoken. The debt collects.'],
    flee: [],
    fall: ['The brand goes cold. The broken ones get their dawn after all.', 'A bad end. The Roll of Vesper takes the name. The cold keeps the rest.'],
    again: 'Last time you won with {beat}. The crippled ones are watched now.',
    remember: 'Last time you won with {beat}. The chalk still marks the finish.'
  },
  methodical: {
    meet: ['Screens up, names chalked. The dawn watch sets the pace.', 'The line advances under oath. Every gun is laid, every screen is set.'],
    win: ['The line held. The guns were laid by hand and the oath was kept.', 'Steady fire, steady screens. The debt was collected in order.'],
    flee: [],
    fall: ['The hull goes dark. Add my name to the chalk and keep the watch.', 'The line breaks at one point. The rest holds. Chalk the name and close the gap.'],
    again: 'Last time you won with {beat}. The line has drilled against it.',
    remember: 'Last time you won with {beat}. The chalk mark is still on the hull.'
  },
  adapt: {
    shields: 'Screen drills are re-sworn. Your lances will spend themselves.',
    pd: 'Spark flak is up. Your torpedoes burn short.',
    armor: 'Riveted plate is fitted. Your ram meets iron and frost.',
    evasion: 'The Oath of speed is sworn. Your batteries will find cold space.',
    aim: 'Hand-laid sights are set. Your evasive burn is read by eye, not machine.',
    special: 'Fervour is up. Guns deal 8% more damage.'
  },
  lessons: {
    flank: 'Thin stern plating gives way under rear fire. Hit the rear while the charge is committed.',
    ion: 'Brittle shield emitters fail under focused ion fire. Strip the shields before the line settles.',
    torp: 'Poor point defense leaves torpedoes a clear path. Launch after the escorts commit to the line.',
    board: 'Green boarding crews lose to prepared defenders. Board only after the escorts are split.',
    brawl: 'Long-gun doctrine struggles at close range. Close in and force the brawl.',
    anchor: 'A proud flagship holds the line together. Get the flagship under 60% hull and the escorts break and run.',
    slow: 'Worn engines limit repositioning. Cut the retreat path and keep pressure.',
    strike: 'The Crusade strike is a challenge: the enemy flagship singles out yours, and the pair deal 20% more damage to each other. Screen your flagship; if your flagship falls, the challenge moves to your strongest ship.'
  }
}
```

## Corsair flee fix

One line changes in text_table.md (corsair, cunning, flee, first line), applied in place in this delivery:

- Was: 'Not worth the teeth. The pack comes back richer.'
- Now: 'Not worth the scrap. The pack comes back richer.'

Teeth is a Chorus motif word (opus_check_274). Scrap is a Hullbreaker motif word, and the pack is the Corsair's own word, so the replacement keeps the slot, the length, and the sense (they leave and return richer later). Four legs converged on "scrap" (DeepSeek, Grok, and both Flash runs); Qwen's "swing" is not a Hullbreaker motif word and was not adopted. Nothing else in text_table.md changes.

## Persona reads (chair final)

- Crusade, zealous: Charges in headlong under the oath, never backs off, and treats the burn as a debt coming due.
- Crusade, proud: Leads the sworn line from the front, flagship first, because the oath demands the leader be seen.
- Crusade, cruel: Marks crippled ships first and finishes them slow, chalking each name as the cold takes them.
- Crusade, methodical: Advances in a measured line under steady screens and hand-laid guns, lets the dawn watch set the pace, and does not stop.

## Merge and screening notes

- Shape verified against text_table.md: four personas in the shipped pool order (zealous, proud, cruel, methodical), two lines per spoken pool, flee empty, no fall_final, six adapt lines naming the shipped NEM_ADAPT_FAC.voidsworn adaptations (Screen drills, Spark flak, Riveted plate, Oath of speed, Hand-laid sights, Fervour, with the Fervour 8% carried in the line), eight lessons keyed to NEM_WEAK plus the strike.
- Motif screen: no other faction's motif words in the Crusade block (no Registry or file, no archive or copy, no lens, mirror or glass, no taste, heat, smell or teeth, no pack, trophy or scrap; dawn, sun, flame and burning are the Crusade's sky words, not light). The Corsair replacement is the one deliberate exception in the other direction: it is a Hullbreaker line, so Hullbreaker words are correct there.
- Church screen: every word on the lore bible banned list is absent from the block, and the near-church words the ideation legs flagged are absent too. The retired song words are absent everywhere in the delivery.
- Lessons screen: every mechanical claim traces to data.js. Rear-arc damage and the charge (flank), brittle shield emitters (ion), poor point defense (torp), green boarding crews (board), long-gun doctrine at two hexes or closer (brawl), escorts breaking once the flagship is under 60% hull (anchor), 1 less movement, phrased as worn engines (slow), and the challenge at 20% more damage to each other with the transfer to the strongest ship (strike). Lessons say shields, not screens: the debrief is the game's voice, not the commander's.
- Leg use: the blind Rey leg is the spine for the zealous charge register, the anchor threshold lesson, and the strike lesson's screening advice. Qwen contributed the zealous meet pair, the proud win and fall pairs, the cruel win and fall pairs, and the template-form torp, board, brawl and slow lessons. DeepSeek contributed the cruel meet opener, the methodical meet pair's pace line, and the chalk-and-finish remember line. The methodical fall opener is the Flash ideation candidate, adopted by the chair. Grok contributed the zealous meet question form ("Who carries the dawn?") through Qwen's line. Flash's church-bleed trap list was applied as a chair screen.
- Qwen gates: selector showed Qwen3.8-Max before the prompt was submitted and the chat header still showed Qwen3.8-Max after generation; single response, no preference prompt, nothing chosen by the runner.

## Not checked

- No line was tested in the running game; line length in the dialogue UI and nemSay substitution against every {beat} value were checked by reading the substitution table, not by rendering. DeepSeek wires these rows into data.js afterwards, per the board's filing note.
