# Chorus: replacing the Boarding tendrils weapon (issue 1877)

Ryan's ruling (FINDINGS R437, Nov 23, 2026): scrap the tendrils, they do not make sense as a space weapon, find an alternative.

The weapon today (W.tendril in godot/rules/data/tables.json): "Boarding tendrils", kind bio, 2 shots, 11 damage, range 1, accuracy 85, pierce 0.5, crit 12, Chorus trait acid (hull hits leave acid: 4 hull a turn for 2 turns, through shields and armour). It is the Chorus close-in brawler weapon on hulls b_spitter_s, b_razor_s and b_razor_e.

All four options below keep those numbers exactly. No leg of the council flagged a number change, and the chair found no reason to invent one. Each option gives its own in-fiction reason range stays 1. Notes only, no code.

## Option 1: Acid sacs (chair pick)

One line: the ship grows a pressurised sac of acid inside a thin calcified shell and fires it point blank; the shell cracks on the hull and the acid pours out.

Fire, at the battle camera: a flank pore swells, the sac visible inside it, translucent and sloshing with bile yellow-green light, then a muscle ring squeezes and the sac kicks out, tumbling slowly end over end, one sac per shot. The ship shudders once with the effort.

Hit: the thin bone shell cracks open against the plating with a pale shard scatter, and the acid load splashes wide, runs into the seams and pools. The pool keeps bubbling and eating in for the two acid turns, so the trait reads as cause and effect the player can watch.

Sound: a tight wet muscular squeeze at launch; on hit, a brittle crack like thin crab shell, then a heavy liquid splash and a low sustained hiss.

Why range 1: the shell is fragile and the sac is spun out by muscle alone, slow and tumbling. Any further and it breaks up or drifts off line in empty space.

Why it is not the spore bomb: sporeb is an opaque dead pod that seeds spores. This is a wet, translucent, visibly liquid sac that bursts acid on contact. The look-bench should hold that line: sloshing liquid and a cracked shell, never a dry pod.

## Option 2: Bone bolts

One line: the ship fires a single heavy bolt of solid bone with an acid core, grown in a flank organ and shot out by a muscle snap.

Fire: the flank organ flexes once and the bolt leaves straight and fast for its size, trailing a thin line of bile droplets, with a recoil shudder through the hull flesh. One bolt per shot.

Hit: the bolt punches in, the head shatters into pale shards, and acid sheets down the hull and keeps dripping and smoking through the acid turns.

Sound: a deep wet thunk and a muscle-snap crack at launch; a bone crack on hit, then the acid hiss.

Why range 1: the bolt is massive and muscle-fired, so it is only dangerous point blank; beyond that it is too slow to matter.

## Option 3: Gut torps

One line: a living torpedo, a finned flesh sac full of acid, slides out of a launch mouth and swims the gap by undulating, then bursts against the hull.

Fire: the lobed flesh door of the launch mouth opens, the torp slides out and starts to swim, membrane fins rippling, bile light pulsing inside it. It is slow enough to watch cross, which sells the short range.

Hit: it slaps onto the hull, splits along its belly seam, and the acid pours out and spreads before the husk flakes away.

Sound: a wet gulp and squeeze at launch; silence in travel; a soft body slap, a tearing split, then hissing on hit.

Why range 1: the torp is a short-lived swimmer. It crosses one hex of vacuum and dies; it does not steer and it does not chase.

## Option 4: Burst mites

One line: the ship ejects a hand-sized chitin mite that crosses the void on flickering membrane wings and bursts into acid the moment it strikes.

Fire: the mite pops out of a flank pore already moving, legs tucked, wings a blur, a faint bile glint at the abdomen sac. One mite per shot.

Hit: it hits, curls, and pops. Acid sprays in a flat fan across the plating and eats in. Nothing latches, nothing stays; the mite is a delivery shell that destroys itself on impact.

Sound: a chitin click and a wet pop at launch; a crunch, a pop, and a short hiss on hit. No buzz; travel stays silent.

Why range 1: the mite lives for seconds outside the body.

Risk, stated plainly: this is the option closest to the thing being scrapped. DeepSeek's version of the creature (a burrowing larva) reads as boarding and infestation, and Ryan's own Chorus note records "cartoon bugs or grubs" as his complaint about the ships. The burst-on-impact form above is the only version the chair would put in front of him, and it is ranked last for this reason.

## Chair pick: Option 1, Acid sacs

The council converged hard. All four legs (blind Rey, DeepSeek, Qwen, Gemini on Hydrogen) independently proposed the acid sac family and the heavy bone mass family; the sac was the single pick of both Qwen and Gemini, and Gemini's version supplied the missing piece, the thin calcified shell, which explains the 0.5 pierce in the picture instead of leaving it a bare stat. The sac gives the acid trait a visible cause (sac breaks, acid pools, hull eats over two turns), reads instantly at battle camera as a glowing tumbling sac, and is plainly different from the spine volley, the Bile spray cone, the Spore drifts cloud and the spore bomb pod. Bone bolts (option 2) are the safe second: the clearest pure weapon read and likely the cheapest to build, if the sac proves hard to make read against sporeb.

## Council record

- Blind Rey leg first: bile globs, bone bolts, gut torps, burst mites. Lean: bone bolts.
- DeepSeek (DeepThink on, Search off, verified both ends): Canker Larva (its pick), Marrow Slug, Gullet Sac, Bone Seed. Chair flags: the larva burrows, which leans boarding, and carries the grub risk Ryan has already ruled on for Chorus ships; Marrow Slug and Gullet Sac converge with the bone and sac families.
- Qwen (Qwen3.8-Max, verified both ends): Acid Blister (its pick), Gullet Cast, Acid Clot, Bone Burr. Chair flag: the Acid Clot's trailing mucus strings detach and snap away, so it passes the no-tether rule, but no stringy connection between the ships should survive into the look-bench.
- Gemini on Hydrogen (picker verified): Calcified Bile Globules (its pick), Acidic Lamprey Darts, Bursting Gall Bladders, Venomous Jaw-Spurs. Its globule is the hybrid the chair adopted for option 1.
- Grok: seat empty. grok.com returned a bot wall ("Your request was blocked") before sign-in on Nov 23, 2026. The seat is recorded empty, not filled.

OBSERVED: the weapon values and neighbouring weapon entries are read from main (tables.json) and the Chorus identity from docs/playbooks/factions.md, both Nov 23, 2026. INFERRED: build cost and camera reads are judgement, to be settled by the Board's 3D look-bench clips (R416).

Next step, Board side: build the look-bench clip of each option for Ryan to choose. Refs #1877.
