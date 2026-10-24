# DeepSeek Council, Pack B Lens 1: Designer

Extracted by Rey from the raw DeepSeek transcript (contrib/deepseek/council_audit.txt). Claims are DeepSeek's, unverified, reproduced for Opus to judge. Quotes are verbatim from the transcript.

Source: Pack B chat, Lens 1 (Designer). 8 findings, in the model's order. In this answer the model wove its citations and quoted fragments into prose rather than using a separate quote field; the fragments below are reproduced exactly as the model gave them.

## 1. The shield/IFF colour law contradicts itself
- Citations: fx3d.js:2, fx3d.js:3, ships3d.js:5
- Mark: OBSERVED
- Model's reasoning: fx3d.js:2 says cyan is always shields, amber is always hull; green and red only mark friend or foe, but fx3d.js:3 says shields wear their faction's colour, and ships3d.js:5 gives corsair "shield:new C3(.85,.16,.1)", a red shield that collides with enemy-red IFF. The model says this breaks at-a-glance combat readability.

## 2. Voidsworn and Corsair are too close in palette to read apart at a glance
- Citations: data.js:111, data.js:115
- Mark: INFERRED
- Model's reasoning: data.js:111 has Voidsworn "trim:'#c8501f',glow:'#ff7a2a'"; data.js:115 has Corsair "trim:'#b8402a',glow:'#e0402c'". Both are warm orange-red fleets, especially in dark scenes and small phone screenshots.

## 3. Faction palettes have contradictory sources of truth
- Citations: data.js:111, ships3d.js:3, data.js:115, ships3d.js:5
- Mark: OBSERVED
- Model's reasoning: data.js:111 says Voidsworn "trim:'#c8501f'", but ships3d.js:3 says "trim:'#9c3a1c'"; data.js:115 says Corsair "trim:'#b8402a'", but ships3d.js:5 says "trim:'#a3542c'". The model says the art direction cannot be judged consistently because the text disagrees with itself.

## 4. "Rare" UI rarity reuses the exact shield cyan
- Citations: data.js:386, fx3d.js:4
- Mark: OBSERVED
- Model's reasoning: data.js:386 gives Rare "col:'#62ccff'"; fx3d.js:4 defines "SHIELD_HEX='#62ccff'". A rarity label can therefore look like shield status, undermining the stated one-language colour system.

## 5. Phone dark-scene screenshots will suffer from dark translucent HUD over dark space
- Citations: head.html:41, head.html:13, head.html:23
- Mark: INFERRED
- Model's reasoning: head.html:41 uses "background:var(--glass);backdrop-filter:blur(8px)", while head.html:13 sets "--bone3:#7d7768" and head.html:23 uses "background:#04060c". Low-contrast secondary text on blurred dark panels is a screenshot legibility risk.

## 6. All six factions sit under one Gothic/imperial UI skin
- Citations: head.html:9, head.html:17
- Mark: INFERRED
- Model's reasoning: head.html:9 loads UnifrakturMaguntia, and head.html:17 sets a gothic font variable from it. That suits Voidsworn, but the same UI frames the bio-swarm, sail, and tomb factions, so menus do not reinforce faction read-apart.

## 7. Patron/boon colours reuse combat semantics
- Citations: data.js:388, data.js:389, fx3d.js:4
- Mark: INFERRED
- Model's reasoning: data.js:388 gives Kharon "col:'#e0b04a'", close to hull amber; data.js:389 gives Vyre "col:'#5fd4ff'", close to shield cyan. In boon UI this competes with the hull and shield colour language defined at fx3d.js:4.

## 8. Phone screenshots lose fleet-level labelling by design
- Citation: fx3d.js:45
- Mark: INFERRED
- Model's reasoning: fx3d.js:45 says the DOM label shows only for the ship in hand; with tiny hull arcs and faction-coloured shields, a phone screenshot can show many ships with little readable identity or damage state.

## Not checked
"Not checked: I did not inspect actual rendered screenshots, shader compile output, device performance, audio, or source files absent from this pack such as sfx.js and wfx3d.js. I also did not audit every CSS breakpoint or every procedural ship-builder branch."
