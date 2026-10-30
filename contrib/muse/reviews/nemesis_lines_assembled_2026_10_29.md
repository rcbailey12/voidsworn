# Nemesis line pools: assembled additions (savings pass wave 4, item 4, Oct 29, 2026)

Chair assembly from the three filed prongs: the blind Rey draft (primary text), the DeepSeek draft, and the Qwen draft, all filed under contrib/muse/reviews/, contrib/deepseek/reviews/, and contrib/qwen/reviews/. Sources are marked per group. The Argon prong is still outstanding; if it lands stronger lines they arrive as an addendum for Opus, not a rewrite.

These are ADDITIONS to the shipped NEM_LINES pools (data.js), in the shipped shapes: meet keyed by persona, again and remember with the {beat} slot, gloat keyed by trigger, plus the two new debrief pools the pack specified (loss-reveal under Ryan's Oct 29 Q5 ruling, win-reveal as its counterpart), each debrief line carrying exactly one [WEAKNESS] slot.

## meet (2 per persona)

- cunning [Rey]: I did not come for your strongest ship. I never do.
- cunning [Qwen]: I have counted your ships. I know which one you will sacrifice first.
- zealous [Rey]: I have burned my retreat into the hull behind me. Forward is all that is left.
- zealous [Qwen]: Kneel or burn. There is no third road.
- cruel [Rey]: Scream all you like on open channels. I count it as ranging data.
- cruel [DeepSeek]: Your crippled will be finished first. I want you to watch.
- patient [Rey]: Empires have mustered against me and gone home to dust. Your turn now.
- patient [DeepSeek]: Time is my ally. I will spend yours.
- proud [Rey]: Watch the flagship. Everything I am is written on her prow, and she is coming first.
- proud [Qwen]: My flagship is the first thing you will see and the last thing you will forget.
- greedy [Rey]: I have already paced out where your flagship will hang in my yard. There is a hook with her name on it.
- greedy [DeepSeek]: I have already priced your fleet. The flagship is mine.
- methodical [Rey]: We ran this battle eleven times in drill. You lose in all of them, but the variations are instructive.
- methodical [DeepSeek]: Every lane is drilled. Every answer is prepared.
- ravenous [Rey]: We can smell your reactor wash from three systems out. We have been following it like a trail of blood.
- ravenous [Qwen]: I do not pick targets. I eat whatever is nearest.

## again (keeps the {beat} slot)

- [Rey]: You beat me with {beat} once. I took the counter for it, and I have been drilling it ever since.
- [Qwen]: {beat} was your trick last time. I have drilled the counter into every crew I command.

## remember (keeps the {beat} slot)

- [Rey]: You beat me with {beat}. No counter yet, I admit it freely. It changes nothing about today.
- [Qwen]: You beat me with {beat}. I carry that scar.

## gloat (1 per trigger)

- flagship [Rey]: Your flagship died under my guns once. Ships remember, even when crews cannot.
- retreat [Qwen]: You turned your engines away from me. I let you. I always let you run.
- loss [Rey]: Once was not luck, whatever your crews tell each other. Shall we make it twice?

## loss-reveal debrief (2 per faction; the less-certain register)

- Sunward Crusade [Rey]: The dawn watch combed the wreckage twice before anyone would say it aloud. The signs point, not prove, to a fault in the enemy: [WEAKNESS].
- Sunward Crusade [Qwen]: Scorch-markings on the wreckage are consistent with [WEAKNESS], though the oath-plate may have obscured the full picture.
- Hegemony [Rey]: The after-action review is three signatures short of certain, but the pattern keeps surfacing in the gunnery plots: [WEAKNESS].
- Hegemony [Qwen]: Signals intercepts recovered from the battlefield suggest the line is vulnerable to [WEAKNESS], though the cipher was only partially broken.
- Ashfall Hullbreakers [Rey]: The pack sniffed over what was left of the field and came back with a scent, faint and maybe imagined: [WEAKNESS].
- Ashfall Hullbreakers [Qwen]: Salvage pulled from the raider's wake suggests a vulnerability to [WEAKNESS], though the evidence is fragmentary.
- The Chorus [Rey]: The throats that fed on the wreckage sing uncertain of everything but one soft place in the enemy fleet: [WEAKNESS].
- The Chorus [Qwen]: Tissue samples recovered from the retreating mass suggest a vulnerability to [WEAKNESS], though the organism was already adapting.
- Glasswrights [Rey]: No lens-keeper will swear to a reading taken from a lost fight. The least doubtful of them speaks of [WEAKNESS].
- Glasswrights [Qwen]: Prism-shard analysis from the duel site suggests the fleet may be susceptible to [WEAKNESS], though the mirrors were already re-aligning.
- Eclipse [Rey]: The Archive restored the battle from partial copies, and the gaps are honest gaps. In what survives, one flaw recurs: [WEAKNESS].
- Eclipse [Rey]: A fragment of a Nemesis backup, recovered and only partly legible, suggests what no interrogation could: [WEAKNESS].

## win-reveal debrief (1 per faction; the certain register; all Rey)

- Sunward Crusade: The roll is amended in open session, and no voice dissents: the weakness is [WEAKNESS], witnessed and sworn.
- Hegemony: Confirmed by three independent plots and entered into the line's standing orders: [WEAKNESS]. There will be no appeal.
- Ashfall Hullbreakers: The pack took the knowledge the way it takes everything, by main force, and there is no doubt left in the den: [WEAKNESS].
- The Chorus: Every throat sings it now, and the song does not waver: [WEAKNESS], tasted and known.
- Glasswrights: The glass kept the whole of it, light unbroken, and the reading is exact: [WEAKNESS].
- Eclipse: The enemy Archive, taken intact, states it without hedging: [WEAKNESS]. The copy agrees with the original.

## Assembly notes

Mix: 41 lines total. Meet 16 (Rey 8, Qwen 5, DeepSeek 3); again 2 (Rey 1, Qwen 1); remember 2 (Rey 1, Qwen 1); gloat 3 (Rey 2, Qwen 1); loss-reveal 12 (Rey 7, Qwen 5); win-reveal 6 (all Rey).

Choices Opus should know were deliberate:
- Win-reveal is all Rey because each line is faction-shaped end to end. Qwen's filed set is the coherent alternative if he prefers a uniform shape: every Qwen line ends "Confirmed weakness: [WEAKNESS]" behind a faction first sentence. That uniformity is a UI decision, not a quality gap; the two sets are both complete.
- DeepSeek's win-reveal lines are not assembled anywhere: six near-identical "confirms [WEAKNESS]" shapes with no faction first sentence. They stand in the filed draft as reserves only.
- Qwen's second Hullbreakers loss-reveal line is excluded on a correctness point, not taste: it calls the Nemesis "his", and the Nemesis's gender varies by roll (NEM_FAC carries masc and fem name lists). Every assembled debrief line is pronoun-clean, and every assembled meet line is first-person, so no assembled line depends on the roll.
- Qwen's gloat loss line ("The scoreboard does not lie") is excluded on register; DeepSeek's loss line is the reserve if a third gloat register is ever wanted.
- Convergence worth noting: all three legs independently produced a patient meet line on "come when you are ready" and a zealous line on "be weighed." The assembled set keeps neither duplicate shape; the ideas survive in the Rey zealous and patient picks' neighbours rather than as repeats.
- Both external legs flagged the NEM_FAC key-to-display-name mapping as their own inference. Chair-closed: the mapping is exactly rename_map_final, so all faction labels in all three filed drafts stand.
