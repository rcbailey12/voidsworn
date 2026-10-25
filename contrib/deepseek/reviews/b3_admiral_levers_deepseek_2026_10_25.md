# Job B admiral balance levers (DeepSeek leg, Oct 25, 2026)

Filed verbatim from a fresh DeepSeek chat at https://chat.deepseek.com/a/chat/s/a2f8ffa9-be3e-4ee7-a425-37cb0b3f498e. Ran Oct 25, 2026, 3:30-3:38 PM CDT (runtime-measured).

Model verification: the session was already signed in (sidebar showed Ryan Bailey; no sign-in prompt appeared, so no saved-login flow was needed). DeepThink ON and Search ON, both verified by toggling each one off and back on and confirming the ON state, and both left ON before submitting. Evidence pack upload applied: job_b_evidence.md (18.25 KB) was shown attached above the message box before sending. The prompt was pasted verbatim and submitted. Reply complete, not truncated, ending with the requested "Not checked" section and no streaming indicator remaining.

Chair note (not part of DeepSeek's leg): the leg opens with the line "Deliverable content for contrib/muse/reviews/b3_admiral_levers_synthesis.md" and the heading "Job B admiral levers synthesis, Voidsworn leg". That framing is the model's own; this file is the DeepSeek LEG, not the synthesis. The synthesis is a separate chair file that reconciles this leg with the Qwen leg. The "Voidsworn leg" label is a harmless labeling quirk (the leg covers Corsair and Chorus admirals, not the Voidsworn faction). See the screening note for the chair's flags. This leg is one blind input to the Job B synthesis, not a verdict.

## DeepSeek reply, verbatim

Deliverable content for contrib/muse/reviews/b3_admiral_levers_synthesis.md:

Job B admiral levers synthesis, Voidsworn leg

Matrix note and scope

All levers below are tuned against the Opus B0 bossmatrix baseline in the pack. The B2 pre-escort-fix range of 23% to 76% is not the baseline and is not averaged with B0. The post-fix rerun is pending on the PC, so every lever is a proposal for Opus to test, not final tuning.

Target band: no sector 1 admiral below 50% or above 90%. The four out-of-band B0 rows are grax at 36%, vesh at 94%, mending at 93%, and voice at 94%. Sector 2 and sector 3 rows are not targets.

No shared faction perk change is proposed. If Opus finds any perk fx below is shared in code rather than admiral-specific, stop and recheck the other admirals in that faction before testing.

Grax

Current state, from the pack: fleet [c_marauder, c_reaver, c_raider]; perk Ram and board with speed 1 and dmgPct .1; Command Full burn; win_pct 36; rounds 8.3; carrier no; cost 0.

Why out of band: 36 is below 50 on the B0 baseline. S6 calls Grax the weakest start and calls the Hegemony boss the hardest opener at 47%, but the pack does not tie those two facts to Grax's row. Rounds 8.3 is a short row. Inference: the start may lack staying power or may be punished by the opener, but hull stats are absent, so the cause is UNSURE.

Candidate levers, smallest feel change first:

1. Perk number change: dmgPct .1 to .15. Expected direction: up toward 50. Identity cost: low. This keeps Ram and board as speed plus damage and does not add a rule. Tuned against B0. Overshoot flag: if the rerun puts Grax inside the band, do not test this up lever; it could push an already high-in-band Grax higher, though reaching above 90 from a low row is unlikely.

2. Starting fleet change: add one c_raider to make [c_marauder, c_reaver, c_raider, c_raider]. Expected direction: up toward 50. Identity cost: low to medium. Corsair identity is a swarm of cheap hulls, so an extra raider fits, but fleet count feel changes more than a perk tweak. Hull stats for c_raider are not in the pack, so the size of this lever is UNSURE. Tuned against B0. Overshoot flag: if the rerun puts Grax inside the band, adding a ship is unnecessary and could overshoot high.

3. Perk number change: speed 1 to 2. Expected direction: up toward 50. Identity cost: medium. Speed is core Corsair, but giving every ship +2 speed is a large tactical feel change even though it is one number. Tuned against B0. Overshoot flag: if the rerun puts Grax inside the band, this is a strong up lever and should not be tested.

Single lever to test first: dmgPct .1 to .15.

Vesh

Current state, from the pack: fleet [c_hulk, c_marauder]; perk Scrap armor with hullRegenPct .05 and armor .1; Command Patch and pray; win_pct 94; rounds 10.5; carrier yes; cost 80.

Why out of band: 94 is above 90 on the B0 baseline. S6 names Vesh at 94. The row has carrier yes and a two-ship start, with regen and armor on the perk. Inference: the durability perk may be strong in a mid-length row, but the pack does not isolate the cause and hull stats are absent, so cause is UNSURE.

Candidate levers, smallest feel change first:

1. Perk number change: hullRegenPct .05 to .04. Expected direction: down toward 90. Identity cost: low. Scrap armor still patches hull each round, just slower. One number changes. Tuned against B0. Overshoot flag: if the rerun puts Vesh inside the band, do not test; a down lever could push a low-in-band rerun below 50.

2. Perk number change: armor .1 to .05. Expected direction: down toward 90. Identity cost: medium. Armor is the namesake of Scrap armor, so halving the bonus changes feel more than the regen tweak. Tuned against B0. Overshoot flag: same as above, and this is a stronger down lever.

3. One ship swap: replace c_hulk with c_reaver in the start. Expected direction: down toward 90. Identity cost: high. The row's carrier yes flag is evidence that c_hulk is the carrier here, by inference. Removing it changes the carrier flag and the start's shape. Hull roles and stats are not in the pack, so direction and size are UNSURE. Tuned against B0. Overshoot flag: high risk of overshooting low if the rerun is already near the band.

Single lever to test first: hullRegenPct .05 to .04.

Mending

Current state, from the pack: fleet [b_razor, b_razor]; perk Regrowth with hullRegenPct .06; Command Regrowth tide; win_pct 93; rounds 9.6; carrier no; cost 45.

Why out of band: 93 is above 90 on the B0 baseline. The start is only two b_razor hulls and the perk is 6% hull regrowth. Chorus identity is the swarm that eats, with regeneration and no repair. Inference: regrowth may keep a small hull count alive through a mid-length row, but the pack does not isolate the cause and hull stats are absent, so cause is UNSURE.

Candidate levers, smallest feel change first:

1. Perk number change: hullRegenPct .06 to .05. Expected direction: down toward 90. Identity cost: low. Regrowth remains and Chorus regeneration identity is intact. Tuned against B0. Overshoot flag: if the rerun puts Mending inside the band, do not test; a down lever could push a low-in-band rerun below 50.

2. Perk number change: hullRegenPct .06 to .04. Expected direction: down toward 90. Identity cost: medium. Still regrowth, but a two point cut is a larger feel change. Tuned against B0. Overshoot flag: stronger down lever, so higher risk if the rerun is already near the lower edge.

3. Starting fleet change: remove one b_razor to make [b_razor]. Expected direction: down toward 90. Identity cost: high. Chorus identity is the swarm, and dropping from two hulls to one is a large feel change. Hull stats are absent, so size is UNSURE. Tuned against B0. Overshoot flag: high risk of pushing below 50 if the rerun is already inside the band.

Single lever to test first: hullRegenPct .06 to .05.

Voice

Current state, from the pack: fleet [b_razor, b_spitter, b_drone, b_drone]; perk Acid chorus with dmgPct .15; Command Discordant volley; win_pct 94; rounds 7.0; carrier no; cost 80.

Why out of band: 94 is above 90 on the B0 baseline. Rounds 7.0 is the fastest sector 1 row in the pack. The start has four hulls and the perk is +15% damage with every weapon. Inference: fast kills from a global damage buff plus a four hull start may explain the high row, but the pack does not isolate the cause and hull stats are absent, so cause is UNSURE.

Candidate levers, smallest feel change first:

1. Perk number change: dmgPct .15 to .12. Expected direction: down toward 90. Identity cost: low to medium. Acid chorus still boosts every weapon, just less. A 3 point cut is proposed because a 1 point cut is lower feel but I cannot support it as enough to move a 94% row from this pack. Tuned against B0. Overshoot flag: if the rerun puts Voice inside the band, do not test; a down lever could push a low-in-band rerun below 50.

2. Perk number change: dmgPct .15 to .10. Expected direction: down toward 90. Identity cost: medium. Bigger cut to the namesake damage buff. Tuned against B0. Overshoot flag: stronger down lever, higher risk if the rerun is already near the lower edge.

3. Starting fleet change: remove one b_drone to make [b_razor, b_spitter, b_drone]. Expected direction: down toward 90. Identity cost: high. Chorus identity is the swarm, and losing a body is a large feel change. Hull stats are absent, so size is UNSURE. Tuned against B0. Overshoot flag: high risk of pushing below 50 if the rerun is inside the band.

Single lever to test first: dmgPct .15 to .12.

Not checked

- Hull stats, weapon stats, ship prices, and hull roles beyond the hull IDs in the pack.
- The actual post-B2 escort-fix rerun values on the PC.
- Whether c_hulk is the carrier in Vesh's start by hull data; the carrier yes flag in the row is pack evidence, but the hull mapping is inference.
- Whether any perk fx above is admiral-only or shared in code.
- The exact win rate movement from any proposed number change.
- Command interactions with the proposed levers.
- No price-ladder number was used as a settled value.

End of DeepSeek reply.
