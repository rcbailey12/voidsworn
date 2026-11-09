# #270 UI redesign 1: warship-console concept directions for the battle screen

Chair synthesis, Rey, Nov 8 2026. Refs #270.

## What this package is

R137 (Ryan, Nov 8 2026, RULED) starts the UI over: warship-console look (bridge readouts, hard edges, metal frames, glowing data, little text), battle screen first as the style test, then the style rolls out to every screen, one shared style with faction colours and crests as accents. Underneath, the locked law from #231 and ui_spec.md stays: the scale law, the focus ring, the fixed palette meanings, crest-only faction accent in battle, the 250 px roster, the 12 px text floor. R137's addendum requires multiple distinct options with variations, and a wide ideation round across models.

This package delivers: a reference study of eight shipped works (reference_study.md), five legs (legs/: blind Rey written first, Flash and Grok ideation with web search, DeepSeek on buildability, Qwen on content and reading), the screened candidate pool (POOL.md), fourteen concept images in seven directions with restrained and bold variations (notes.md describes each; the images themselves were shown to Ryan in chat because the repo push is text-only), and the chair's pick below.

## Screening record

Nine candidates went to the stress legs. Four merges and kills came out of that round, all chair-ratified:

1. The Salvaged Console is not a separate system. Both stress legs judged it the Gun Director in a worse state of repair. It survives as the Gun Director's bold variation, which keeps its flavour (mismatched plates, hand-painted labels, warm work-light) without spending a direction slot on it.
2. The Admiralty Table (Flash's wildcard: brass, gimbals, serif war diary) is the Plotting Table in different metal. Qwen's distinctness screen said so in those words. Merged into D1. Its war-diary log is recorded below as a borrowable element for the end card.
3. Flash's Cold USCM Terminal was screened out as a standalone on filing: it removes nameplate shield and hull bars entirely, which breaks the locked spec. Its dot-matrix texture is noted inside the Vector C.I.C. family.
4. Signal and Semaphore (the blind leg's wildcard: orders hoisted as signal groups, lamps before text) is a layer, not a direction. Both stress legs agreed. It is offered to the winner below, not imaged as a direction.
5. The Living Membrane survived screening only as the labelled wildcard. Both stress legs killed it as a system; it stays in the set because R137 asked for genuine wildcards, and its note says why it should not win.

Final set imaged: D3 Chart Room, D2 Gun Director (bold variation salvaged), D1 Plotting Table (Admiralty merged), D4 Vector C.I.C., D6 Glass Bridge, and the two wildcards, the Reliquary and the Living Membrane. Seven directions, fourteen images. The chair screened the final set for same-idea pairs: the remaining overlaps are the recorded merges above.

## Stress verdicts, one line each

- D3 Chart Room: the best reading machine in the pool (always-present margin log, native focus ring, the reserved red lands hardest on a quiet chart); buildability lowest-risk, near theme-only. Named risk: may read as flat print, not a console.
- D2 Gun Director: the only finalist hitting every word of the brief literally; best home for the ALERT tag; strong rollout precedent (Deadlock, HighFleet). Costs: aperture eats field, phase bar and clock need invented elements, roster tabs run tight at 20 ships.
- D1 Plotting Table: strong frame, weak details; ALERT homeless on the rim, ticker cannot carry an adaptation line, engraved capitals overflow the roster width.
- D4 Vector C.I.C.: best second-channel bars and a native clock; bloom fights the 12 px floor, worst log in the pool, CRT pass costs a SubViewport shader.
- D6 Glass Bridge: prettiest, and structurally incompatible with the locked roster and panel rules; legibility depends on scenery.
- The Reliquary: strongest flavour and a natural Crusade accent; ornament density and kitsch risk as a full system; serif diary text is the weakest small text in the pool.
- The Living Membrane: killed by both stress legs as a system; brief conflict, animation fights numbers, decoration carrying no information.

## The chair's pick: D2, the Gun Director

Pick: **the Gun Director**, restrained variation as the shipping register, with the salvaged state reserved for battle-worn contexts (a damaged flagship's console, Hullbreaker-adjacent screens) rather than as the default.

Reasons, in order:

1. It is the only finalist that satisfies the brief as written: metal frames, glowing data (as backlight, which is how real consoles glow), hard edges, little text. The Chart Room wins on reading and loses on the brief's centre: Ryan asked for a warship console, and D3's own named risk is that it reads as a printed chart.
2. Its stress failures are all fixable inside its own language. The phase bar becomes a strip gauge under the aperture; the Nemesis clock becomes an inset odometer counter beside the round counter; the roster tab overflow is a width problem the scale law already knows how to solve. Nothing in D2 requires breaking the locked spec, unlike D6 (roster collapse) and the screened-out USCM (bar removal).
3. It rolls out. R137 sends the winning style to every screen, and a machined console has shipped precedent for carrying a whole campaign game (Battlestar Galactica Deadlock's CIC, HighFleet's single instrument material). D3 also rolls out well; D1, D4, and D6 were each judged battle-first at best by the buildability leg.
4. The ALERT tag matters more than any other single element: the Nemesis is the game's signature pressure, and D2's backlit warning plate is the strongest, most honest use of the reserved red in the pool.

Explicit fallback: if Opus's #271 mockup round shows the aperture costing too much field to play on, the pick falls to **D3, the Chart Room**, with no new concept round needed. D3 is the better reading machine and both stress legs ranked it first on their own axes; the chair is overruling them on brief fit, not on quality, and the fallback records that.

Refinements offered to the winner, from the screened-out material: (a) Signal and Semaphore's signal lamp for the ALERT tag and for phase changes, a lamp before text, which is the purest expression of the reserved red; (b) the Admiralty war diary's italic serif for the end card only, where reading is slow and ceremonial; (c) D4's stepped-segment bars as the bar rendering inside whichever frame wins, because segments give every bar a second channel for free. These are refinements of one shared style, not a pre-merged hybrid; R137 keeps one style and Ryan picks the direction.

## Delivery note

The fourteen concept images are binary and cannot travel through the text-only push that delivers this package; they were presented to Ryan in chat with a one-page contact sheet of all fourteen. The text package on this branch is the durable record: legs, reference study, pool, notes, and this synthesis. Ryan's pick unblocks #271 (Opus, battle screen restyle); #92 waits for the resulting style guide, per R137.
