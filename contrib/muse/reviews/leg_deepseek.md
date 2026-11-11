# #495 DeepSeek WRITER leg: FINDINGS.md, all rows

Chair header: run Nov 11, 2026, 11:09 to 11:18 CST, chat.deepseek.com, session already signed in as Ryan Bailey. Gates: DeepThink ON and Search OFF verified before sending (Search was on at open, runner turned it off, re-verified both) and both re-verified after the reply. Both files attached (PACK_DEEPSEEK.md, FINDINGS.md). Reply complete in one response, no continuation. Filed verbatim below.

Chair screening notes (not part of the leg): (1) Item 15 cites an "R233 capture round" for movement tuning. FINDINGS runs to R190; no R233 exists in the record. Treated as an invented reference: the R131 challenge stands on its own text, but nothing in the synthesis rests on R233. (2) All other row citations were spot-checked at chair against the local FINDINGS.md copy; the quotes used are short and match. (3) The leg's Part B largely converges with the blind Rey leg (seat contradictions, the Kimi correction, the nose-gun withdrawal), reached independently from FINDINGS alone.

---

Part A: rules I would challenge first

1. R132, the outside-check gate on Opus code. Rule: Opus never merges its own code without an outside check. Where: R132. Who set it: Ryan's own call. Reason recorded: none. What it stops: it blocks a fast merge of small, well-understood game-facing fixes and forces a second seat even when the change is narrow. Disposition: REWORD TO ITS PURPOSE. New wording: game-facing changes need an independent check before merge; tools-only changes may use the R162 exception.

2. R6, acceptance and viewer panels. Rule: "No viewer panels." Where: R6. Who set it: Ryan's own call. Reason recorded: none. What it stops: agents cannot build read-only capture or inspection tools to support Ryan's eye and the automatic checks. Disposition: REWORD TO ITS PURPOSE. New wording: acceptance is Ryan's eye plus automatic checks; read-only capture or viewer tools are allowed if they do not change the game state and do not replace the checks.

3. R10, sound stays as is. Rule: sound stays as it is. Where: R10. Who set it: Ryan's own call. Reason recorded: none. What it stops: sound changes, despite R163 and R171 later recording that the current cues are bad and a redo is scoped. Disposition: RETIRE the sound part. Replaced by R163 and R171. The public-repo part of R10 stands.

4. R5, pick before ship 2. Rule: Ryan and Opus pick the engine before ship 2. Where: R5. Who set it: Ryan's own call. Reason recorded: none. What it stops: the ship pipeline from advancing independently of an engine choice that was made in R32. Disposition: RETIRE. The engine pick happened in R32, and the ship recipe now carries the build route.

5. R33, browser freeze. Rule: today's browser version is frozen, only fixes for breakage. Where: R33. Who set it: Ryan's own call. Reason recorded: none. What it stops: browser improvements and parity work while the Godot migration was the stated direction. Disposition: RETIRE. R35 moved the sprint to full migration, and G-14 records the travel close-out.

6. R164, no new Opus helpers. Rule: no new Opus helpers; helpers run on Fable 5.2, coding to the DeepSeek workhorse until ChatGPT is back. Where: R164. Who set it: Ryan's own call. Reason recorded: "I topped up DeepSeek with 10 until chatgpt comes on." What it stops: using Opus worker threads for hard implementation. Disposition: RETIRE. R170 records ChatGPT is back, and R180 sets worker threads on Opus.

7. R167, at most two Fable helpers. Rule: Board plus at most two Fable helpers. Where: R167. Who set it: Ryan's own call. Reason recorded: usage pacing, no reason recorded for the exact number two. What it stops: using more than two Fable helpers on design or build work. Disposition: RETIRE. R180 says no Fable helpers at all and worker threads are Opus.

8. R152, Fable board seat. Rule: Fable 5.2 owns the board, merges and reviews; Opus 5.5 stays on worker threads. Where: R152. Who set it: Ryan's own call, with the Board pick named. Reason recorded: none. What it stops: an Opus board while Fable usage is constrained. Disposition: REWORD TO ITS PURPOSE. New wording: one Board owner holds merges and reviews; the model seat follows the usage rule in R180, not a fixed Fable seat.

9. R75, Codex local only. Rule: Codex stays local; no Codex cloud tasks or reviews. Where: R75. Who set it: Ryan's own call. Reason recorded: "I don't want to use an inferior model." What it stops: Codex cloud work even when the cloud model matches or improves on the local one. Disposition: REWORD TO ITS PURPOSE. New wording: use the best available Codex model for the job; the Board reviews and merges; cloud use is allowed when the model quality is not lower.

10. R102, one board owner. Rule: the loop is the only board owner; other Claude chats work one named area or only read. Where: R102. Who set it: Ryan's own call. Reason recorded: none. What it stops: parallel board work, even when two named areas do not overlap. Disposition: REWORD TO ITS PURPOSE. New wording: one owner for the merge queue and board state; named-area chats and read-only chats are allowed when they do not write board state.

11. R89, every Muse job has a blind leg. Rule: every Muse research, design or review job includes a blind Rey leg written before Rey reads other legs. Where: R89. Who set it: Ryan's own call. Reason recorded: "running its own blind leg room not just chairing". What it stops: quick Muse jobs that do not need a blind leg, such as low-code fixes under R81. Disposition: KEEP AND ADD THE REASON. The blind leg reduces chair anchoring on research, design and review; keep it for those jobs, not for R81 low-code fixes.

12. R96, 306k triangle ceiling. Rule: performance ceiling near 306k triangles and 3.9 ms at 20 ships. Where: R96. Who set it: Ryan's own call, adopting chair picks. Reason recorded: none. What it stops: ship detail above a fixed triangle number. Disposition: RETIRE. R111 retires R96 as a ceiling and replaces it with the measured scene gate.

13. R100, station triangle ceiling. Rule: about 20k triangles and 0.35 ms per station, with 40k to 45k and 1.0 ms as the hard ceiling. Where: R100. Who set it: Ryan's own call, adopting chair picks. Reason recorded: none. What it stops: station detail above the fixed triangle range. Disposition: RETIRE the triangle ceiling. R113 drops the triangle figures and prices stations on the R116 scene gate.

14. R105, 7 of 9 paint sign-off. Rule: paint sign-off needs 7 of 9 clean cells, for any ship however built. Where: R105. Who set it: Ryan's own call, adopting chair picks. Reason recorded: "readability judged at 1080p"; no reason recorded for the 7 of 9 bar. What it stops: paint approval on a smaller, targeted check. Disposition: RETIRE the 7 of 9 bar. R121 makes the nine-cell sweep a viewing instrument, not a binding gate.

15. R131, movement numbers. Rule: one build reference with fixed move times, a 4 degree lean, a 7 s cap, squadrons at 0.35 with no glide, and turret slew at 90, 45 and 30 degrees a second marked ASSUMED. Where: R131. Who set it: Board, Opus. Reason recorded: none for most numbers; turret slew is marked "ASSUMED". What it stops: tuning movement feel from captures without rewriting the spec. Disposition: REWORD TO ITS PURPOSE. New wording: set the feel goals and the allowed range, mark assumed values, and tune from the R233 capture round.

16. R64, flip-and-burn stays off. Rule: flip-and-burn stays off. Where: R64. Who set it: Ryan's own call. Reason recorded: none. What it stops: a look-only flip-and-burn test for large ships. The round pace part of R64 is play and is not challenged here. Disposition: REWORD TO ITS PURPOSE. New wording: keep the move time and the rules unchanged; allow a look-only flip-and-burn test when it does not change move timing.

17. R80, open breaks only at stage 4. Rule: open breaks only at stage 4, at 20 percent section ship body or broken; no section tint on small ships. Where: R80. Who set it: Ryan's own call. Reason recorded: none. What it stops: earlier readable damage on small ships and more varied damage progression. Disposition: REWORD TO ITS PURPOSE. New wording: damage must read clearly at the play camera; allow open breaks earlier when they read and do not add noise.

18. R79, strict rock cap. Rule: no single backdrop rock wider than 0.05 rad, planets at least 4.4 times wider. Where: R79; R124 records the purpose. Who set it: Ryan's own call recorded in R79. Reason recorded: none in R79; R124 records "scale coherence". What it stops: large foreground rocks that could improve composition without breaking scale. Disposition: REWORD TO ITS PURPOSE. New wording: keep scale coherence as the test; allow a larger rock when the composition needs it and the scale still reads.

19. R9, portraits and height bands on backlog. Rule: portraits and three height bands go on the near backlog and neither is part of this pass. Where: R9. Who set it: Ryan's own call. Reason recorded: none. What it stops: portrait and 3D band work in that pass. Disposition: RETIRE. Portraits became active work under R37, R40 and R68, and the pass is over.

20. R23, one batched prize screen. Rule: one batched prize screen for all prizes after a battle, with values side by side, a default per prize and one confirm. Where: R23. Who set it: Ryan's own call. Reason recorded: none. What it stops: per-prize detail or an expandable review path inside the batch. The play and upkeep parts of R23 are not challenged. Disposition: REWORD TO ITS PURPOSE. New wording: keep the default batch confirm, and allow one prize to expand for detail before confirm.

Part B: contradictions inside FINDINGS

1. R10 and R163. R10 says sound stays as is. R163 says "The sounds that I've heard from the game so far are bad" and scopes a sound redo; R171 sets the sound scope. A reader at R10 would keep the current cues and block the redo. R163 does not mark R10 superseded.

2. R105 and R121. R105 says paint sign-off needs 7 of 9 clean cells. R121 removes "the 7 of 9 and 9 of 9 nine-cell bars" and makes the nine-cell sweep a viewing instrument. A reader at R105 would enforce a bar that R121 removes.

3. R137, R159 and R174. R137 says the battle screen is first as the style test, then the style rolls out. R159 orders the campaign map and its between-battle pages first. R174 says "Map first, then all". A reader at R137 would build the battle screen first.

4. R152 and R180. R152 says Fable 5.2 owns the board, merges and reviews. R180 says no Fable helpers at all, worker threads are Opus, and the Board stays in this chat until a new Board thread on Opus. A reader at R152 would keep the Fable board as the standing seat.

5. R164 and R180. R164 says no new Opus helpers; helpers run on Fable 5.2 and coding goes to DeepSeek until ChatGPT is back. R180 says worker threads are Opus. A reader at R164 would avoid Opus workers after ChatGPT returned.

6. R167 and R180. R167 allows the Board plus at most two Fable helpers. R180 says no Fable helpers at all. A reader at R167 would start Fable helpers.

7. R176 and R183. R176 required the forward gun to be the largest object on the front and to read as armed from above. R183 says that wording is withdrawn, because it produced the same long nose gun across factions, and each faction must build its forward weapon its own way. A reader at R176 would keep the nose-gun rule.

8. R180 and R183, Glasswrights. R180 says the Glasswright ship is one long prism of real glass with light inside. R183 scraps every crystal and prism route and starts fresh from the lore. R185 then settles the Mirror Deck made prismatic. A reader at R180 would build the full prism.

9. R180 and R185, Sunward. R180 settles Sunward as S1b's four flak turrets with S1a's heavy broadside barrels. R185 settles Sunward S8 with a forked front. A reader at R180 would build S1b.

10. R169 and R180, concept history. R169 says all 36 concepts are history, not targets. R180 says the redo must not sand off what was already liked, and when a faction had a concept Ryan liked, the new brief starts from that picture, naming the earlier Hullbreaker concept. A reader at R169 would ignore the earlier concept.

11. R163 and R164, Kimi factual correction. R163 says Kimi was slower and far dearer per job in the trial. R164 corrects that this was the pay-as-you-go starter tier only and that the subscription tier was never tried. R163 still reads as a general verdict. A reader at R163 would treat the subscription as tested and rejected.

Part C: provisional and temporary material written as settled

1. R175 and R179. R175 accepts the eight protocol values as PROVISIONAL, but lists exact numbers in a merged row. R179 then changes three of them and settles the rest. A reader at R175 can treat the first numbers as ruled.

2. R131. The movement spec gives first numbers, marks turret slew ASSUMED, and says one tonnage bus is not adopted until a capture shows the masses disagree. It is written as one build reference. A reader can treat the assumed slew values as settled.

3. R136 and R161. R136 says values marked provisional wait on U-A (#235), U-C (#237) and U-D (#238). R161 retires #235 and #237. The provisional values remain in the spec while their settling jobs are gone. A reader sees constants without the promised confirmation.

4. R96, R100, R105 and R121. R96, R100 and R105 write triangle ceilings and a 7 of 9 bar as hard rules. R121 says assumed and anchored numeric gates stop binding until a measurement earns them back. The earlier rows still read as settled gates.

5. R164 and R180, seat arrangement. R164 writes the no-Opus-helper rule as a seat arrangement "until ChatGPT is back". R180 sets worker threads on Opus. The temporary arrangement is written in the same owner-ruling form as a permanent seat rule.

6. R152 and R180, board seat. R152 writes the Fable board seat as the standing board. R180 plans the Board's move to Opus after key items close. The temporary model seat hardens in R152 while R180 changes it.

7. R160, PC workaround. R160 says PC-dependent work now runs as helpers inside the Board thread, or the Board queues job files itself, because a scheduled thread has no PC link. This is a workaround from a scheduler limit, written as a standing process.

8. R162 and R173, temporary holds. R162 allows a tools-only PR to merge on the Board's own diff review while Muse is idle, with the outside check still requested. R173 holds the rebake until Ryan says the GPU is free. R180 later says the GPU is free any time today. Both temporary holds are written in standing rule language.

Part D: how the rulings were written

1. Bare prohibition with no object or reason. Example: "No viewer panels." R6. The reader gets the ban but not the harm it prevents.

2. Number first, purpose later or absent. Example: "12.5 ms, 75% of the 16.7 ms frame" R116. The number reads as the rule before the reason is stated.

3. Mixed authority inside one row. Example: "Opus calls (vetoable)" R66. The same row also records Ryan's picks, so who set the binding rule is unclear.

4. Correction placed in a later row instead of editing the earlier row. Example: "That wording is WITHDRAWN." R183. R176 still reads as the rule.

5. Supersede applied to part of a compound row. Example: "Supersedes the 'first playable = one full battle' part of R33." R35. The rest of R33 still reads as standing.

6. Provisional values written with exact numbers. Example: "accepts them as PROVISIONAL" R175, followed by eight exact values. A later reader can lift the numbers without the label.

7. Temporary seats written in the same form as permanent seats. Example: "Seats until ChatGPT is back" R164. The expiry is in the sentence, but the row reads like a standing seat map.

8. Compound cells that bundle unrelated decisions. Example: "Test scope superseded by R20" R5. One cell holds engine neutrality, the engine test, the app option and the ship-2 gate, so later reversal points at only one clause.

Leg filed. DeepSeek, WRITER seat, issue 495.
