# Sunward Crusade text table: NEM_VOICE (issue 296)

Chair-merged from the writer legs (blind Rey, DeepSeek, Qwen) with Flash and Grok in the ideation seat only; Argon blocked since Nov 5. This is the voidsworn block that text_table.md is missing: paste it into data.js beside the other five faction blocks, in the same shape (data.js style: single quotes, unquoted keys, ASCII only). {beat} is substituted by nemSay with a NEM_BEAT_WORD value (lances, torpedoes, your wings, rams, boarding parties, massed batteries, speed and evasion). Pronouns in spoken lines are swapped by nemSay at runtime. The Crusade never flees (data.js beh.noFlee), so flee is an empty pool, the same shape as Eclipse. The Crusade has no revive, so there is no fall_final. Lessons are pronoun-free as a set.

```js
voidsworn: {
  "zealous": {
    "meet": [
      "Forty worlds are freezing behind us, and you're standing in our jump lane! Open fire!",
      "We swore back in Vesper orbit we'd burn straight through anyone blocking the sun! Come on!"
    ],
    "win": [
      "Lane's clear! Chalk the victory on the bulkhead and check our fuel!",
      "Tried to stop a Crusade line and paid for it! Keep moving sunward!"
    ],
    "flee": [],
    "fall": [
      "Flagship's going up... don't stop for us, keep pushing toward the siphon!",
      "Bulkheads are gone! Chalk my name under the others and finish the job!"
    ],
    "again": "You beat us with {beat} last time, alright, so we're hitting twice as hard today!",
    "remember": "My gunners still have your {beat} chalked beside the loading rails. Nobody forgot."
  },
  "proud": {
    "meet": [
      "This flagship has led the dawn watch through three sectors! Answer our challenge or break!",
      "I fly right up front where every captain can see my radiators. Come test our iron!"
    ],
    "win": [
      "Our front line held every shot you had and broke your fleet clean in half!",
      "Looked straight down our flank guns and blinked first! Keep pushing!"
    ],
    "flee": [],
    "fall": [
      "Front hull's buckling... close the gap over us and don't let them pass!",
      "Damn fine shooting... the Crusade doesn't stop for one broken flagship!"
    ],
    "again": "Thought {beat} would fold my front line twice? We braced every bulkhead for it!",
    "remember": "I still carry the dents your {beat} put on my bow, and I mean to return them."
  },
  "cruel": {
    "meet": [
      "Look at those leaking escorts on your flank. We're burning the weak ones down first!",
      "Tag their most damaged hull and pour every flank gun into it until it cracks!"
    ],
    "win": [
      "Took your crippled hulls off the plot first and watched the rest fold!",
      "Every scorched hull goes on the roll. Keep the burners hot!"
    ],
    "flee": [],
    "fall": [
      "Reactor's failing... guess your wounded ones had more fight left than I figured...",
      "Bad way to go out... tell Vesper the cold won't be kinder to them either..."
    ],
    "again": "You kept your damaged hulls alive with {beat} before. We're cutting straight through that trick now!",
    "remember": "Still remember how you used {beat} to save those crippled escorts."
  },
  "methodical": {
    "meet": [
      "Screens at full, guns laid by hand, intervals locked. Advance on my mark.",
      "Every firing lane is measured and every crew knows their station. Engage."
    ],
    "win": [
      "Clean volleys, steady screens, minimal hull losses. That's how you cross three sectors.",
      "Formation held from start to finish. Patch the burns and plot the next jump."
    ],
    "flee": [],
    "fall": [
      "Command hull's failing. Transfer the flag to the senior cruiser and keep the line closed.",
      "One gap in the line, not the whole Crusade. Hold steady and finish the fight."
    ],
    "again": "We drilled against your {beat} tactics every watch since our last fight.",
    "remember": "My tactical plot still carries the firing angles from your {beat}."
  },
  "adapt": {
    "shields": "Reinforced screen drills active. Your focused beams won't crack us easily now.",
    "pd": "Spark flak crews doubled across the line. Expect your torpedoes to detonate early.",
    "armor": "Riveted extra black-iron plate onto our bows. Try ramming that.",
    "evasion": "Running lighter thruster trims across the line so your flank volleys miss wide.",
    "aim": "Hand-laid optical sights zeroed in on your burn profile. Quit dodging, we've got you.",
    "special": "Crews running hot on battle rations and grit: +8% damage across all guns."
  },
  "lessons": {
    "flank": "Crusade cruisers commit hard to forward charges and leave thin rear armor exposed. Swing behind them.",
    "ion": "Their front screens are strong, yet brittle emitters collapse fast under sustained ion fire.",
    "torp": "Sparse point defense leaves clear torpedo lanes once their escorts commit to the flank.",
    "board": "Green breach defense crews struggle if you isolate a cruiser away from its escorts.",
    "brawl": "Their hand-laid guns lose tracking speed inside two hexes. Close in and force a knife-fight.",
    "anchor": "Their escorts fight around the flagship's example. Drive it below 60% hull to break their nerve.",
    "slow": "Heavy iron hulls burn sluggishly on worn drives. Cut off their pivots and pound their sterns.",
    "strike": "This commander never flees and challenges your flagship to single combat (+20% damage both ways). Screen your flagship or turn the duel back on them."
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
