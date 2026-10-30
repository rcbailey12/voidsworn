<!-- Chair filing note, Oct 30, 2026: Qwen Nemesis line pools drafting leg (wave 4 item 4), run 1:54-2:00 AM CDT, Qwen3.8-Max verified at both gates (fresh chat defaulted to Qwen3.7-Plus and was switched before sending; header re-verified after generation started), no slider challenge appeared, single response. Filed verbatim except em dashes and the two mapping arrows in the Notes, which are normalized to ASCII hyphens per the standing filing rule. -->

MEET - 2 new variants per persona (16 lines)
cunning
"You show your spine to me. You always do."
"I have counted your ships. I know which one you will sacrifice first."
zealous
"Kneel or burn. There is no third road."
"I did not cross the void to watch you. I came to end you."
cruel
"I can hear your wounded ships crying out. I will answer them."
"The crippled one first. Then the next. I am not in a hurry."
patient
"Come to me when you are ready. I will still be here."
"You will cross the distance. They always do. And I will be waiting at the far end."
proud
"My flagship is the first thing you will see and the last thing you will forget."
"You face my banner. That is more honour than you deserve."
greedy
"Everything you carry, I will carry better."
"That flagship of yours. I can already smell the salvage."
methodical
"I do not improvise. I do not need to."
"You will break against my line the way you broke against it in every drill I ran."
AGAIN - 2 new variants (keeps {beat} slot)
"You beat me with {beat} once. I have since rebuilt around that."
"{beat} was your trick last time. I have drilled the counter into every crew I command."
REMEMBER - 2 new variants (keeps {beat} slot)
"You beat me with {beat}. I carry that scar."
"{beat}. Yes. I remember. I have not yet answered it, but I will."
GLOAT - 1 new variant per trigger (3 lines)
flagship
"Your flagship limped away last time. This time it will not limp at all."
retreat
"You turned your engines away from me. I let you. I always let you run."
loss
"The scoreboard does not lie. You lost. You will lose again."
LOSS-REVEAL - 2 per faction (12 lines, game narration, less-certain register)
Ashfall Hullbreakers (corsair)
"Salvage pulled from the raider's wake suggests a vulnerability to [WEAKNESS], though the evidence is fragmentary."
"Wreckage analysis hints his fleet may be exposed to [WEAKNESS], but the data is incomplete."
Eclipse (deathless)
"Fragments recovered from the reassembled hull point toward [WEAKNESS] as a possible fault line, though the structure was already rebuilding."
"The wreckage yielded partial readings consistent with [WEAKNESS], but the evidence degraded before confirmation."
Glasswrights (ithar)
"Prism-shard analysis from the duel site suggests the fleet may be susceptible to [WEAKNESS], though the mirrors were already re-aligning."
"Optical residue recovered after the engagement is consistent with a weakness to [WEAKNESS], though certainty remains out of reach."
the Chorus (chorus)
"Tissue samples recovered from the retreating mass suggest a vulnerability to [WEAKNESS], though the organism was already adapting."
"The spore-trail left behind is consistent with an exposure to [WEAKNESS], but the sample may not survive transit."
Hegemony (hegemony)
"After-action telemetry hints the formation may be stressed by [WEAKNESS], though the data is drawn from a single engagement."
"Signals intercepts recovered from the battlefield suggest the line is vulnerable to [WEAKNESS], though the cipher was only partially broken."
Sunward Crusade (voidsworn)
"Scorch-markings on the wreckage are consistent with [WEAKNESS], though the oath-plate may have obscured the full picture."
"Recovered debris suggests the warden's fleet may falter against [WEAKNESS], though the evidence is circumstantial."
WIN-REVEAL - 1 per faction (6 lines, game narration, certain register)
Ashfall Hullbreakers (corsair)
"The raider's fleet is broken. Confirmed weakness: [WEAKNESS]."
Eclipse (deathless)
"The dead admiral will not reassemble. Confirmed weakness: [WEAKNESS]."
Glasswrights (ithar)
"The duelist's mirrors are dark. Confirmed weakness: [WEAKNESS]."
the Chorus (chorus)
"The mass is silent. Confirmed weakness: [WEAKNESS]."
Hegemony (hegemony)
"The line is shattered. Confirmed weakness: [WEAKNESS]."
Sunward Crusade (voidsworn)
"The warden's oath is broken. Confirmed weakness: [WEAKNESS]."
NOTES
NEM_FAC lists exactly six factions (corsair, deathless, ithar, chorus, hegemony, voidsworn). All six are covered above; no gap.
The display-name mapping (Sunward Crusade - voidsworn, Ashfall Hullbreakers - corsair, Glasswrights - ithar, Eclipse - deathless) is inferred from the titles, traits, and flavour text in the pack. No explicit key-to-display-name table is shipped in data.js; if the mapping differs in the live build, the faction labels above should be swapped but the line text is faction-agnostic in the loss/win pools.
All loss-reveal lines are written to read sensibly with any of the seven weakness names slotted into [WEAKNESS]. No line depends on a fact outside the shipped tables.
No invented facts. All persona AI tags, trait names, adaptation names, and beat words referenced or implied are drawn from the pack.
