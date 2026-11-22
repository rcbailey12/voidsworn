

---
I'm working through the review now and starting with the credit math: SFX runs at 40 credits per second, so each battery take of 1.0 second comes to 40 credits, and the two takes total 80. I'm about to check the salvo clip of 1.5 seconds next.

Running through the per-item credit totals for the remaining weapons, each take is multiplied by 40 for SFX at this duration.

Still tallying the credits for the eclipse and craft weapons, each take at its per-second rate.

Now I'm going through the remaining items' credit totals, taking each duration at 40 credits per second for the sound effects.

Now I'm checking the remaining weapon and sound totals, with the SFX rate at 40 credits per second. I'm also weighing whether 0.7 seconds times 40 comes out to exactly 28 in floating point, since the rounding could push Math.ceil up by one.

I'm checking whether 1.1 × 40 in floating point lands just above 44, which would make Math.ceil return 45 instead of 44.

Checking the floating-point product: 1.1 times 40 lands exactly halfway between two doubles, so rounding to even decides whether Math.ceil gets 44 or 45.

Checking 1.4 times 40 next, and whether the floating-point product rounds onto a whole number or just past it.

Checking the float rounding on 1.4 times 40: the product lands on a tie between 56 and the next double below it, and round-to-even keeps it at 56. Next I'm checking 1.3 times 40, which comes out just above 52 and rounds down to 52.

Checking the float rounding on 2.2 times 40, which sits right on a tie point near 88, so I'm working out which way round-to-even goes.

Checking 0.7 times 40 in floating point, which appears to come out to exactly 28, so Math.ceil stays at 28.

Still checking the float rounding on the 0.7-second takes: 0.7 × 40 lands just under 28 and rounds to exactly 28. Now I'm summing the SFX per-take costs across the list.

Still adding up the SFX per-take costs, and the running total has reached 1,652 so far. I'm continuing through the remaining items in the same sum.

Now I'm adding the per-take costs for the damage, death, and UI items, which brings the total to 2,288. Doubling that for the two takes and adding the ambience and music gives 7,401, matching the earlier figure. I'm also noting that the take-1 sweep comes to 5,113 rather than the roughly 4,500 I'd planned.

I'm checking the per-take totals against the estimate column, and the charged amounts work out to roughly 11 credits per second, about 0.275 of the estimate. I'm now adding up the estimate column to see whether the "1,587 credits" figure in Gate 1 holds.

Still adding up the estimate column, which reaches 2,837, and now I'm pulling out the charged amounts for the SFX rows to compare them against it.

Now I'm adding up the charged amounts for the remaining sound effects, from the ladder and shield items through to the ion crawl.

Now I'm adding up the charged SFX amounts, which come to 473, and comparing that against the music charges, which appear to be missing.

I'm converting the SFX estimates into actual billing, and the charged rate looks closer to 11 credits per second than 40, which would bring the real total down to around 3,500 credits. I'm testing whether rounding the per-take charges up or to the nearest whole credit fits the observed amounts.

I'm working out the charge rate from the billed amounts, which looks like about 11 credits per second rather than 40. At that rate the two SFX takes plus ambience and music would come to roughly 3,500 credits, so the second take is a small real cost.

I'm working out the remaining math now: the 121,000-credit pool minus the combined 8,988 leaves about 112,000, so the two gates stay under 8%. I'm also checking the generator's default max-credits setting.

Now I'm weighing the risk of locking the weapon sounds to a model with a published removal date, since matching takes couldn't be regenerated later. The evidence for v2's tighter onset comes from only one A/B pair on a gun, and I'm noting that the same flawed prompt was used in both cases.

I'm checking the timing claim in the breakdown: the breech clack seems to come from the prompt listing "heavy breech block slamming" before the cannon thump, not from the soft-top suffix as the notes suggest. That matters because several Gate 2 prompts also put pre-shot events first, like the torpedo clamp release.

I'm checking the remaining audit claims against the manifest, starting with how the v2 model is selected per item and whether the generator's config handles the other fields I can't see past line 100.

I'm weighing a test design for the v2 claim: the same prompt run on both models, with one take each, so the tighter-onset finding gets checked on its own before the gates commit to it.

I'm weighing a small A/B design instead: a few items with a v3 twin at one take each, so the v2 onset claim gets tested on its own. I'm also noting that the numeric timing cues in the prompts, like "0.08 seconds apart," probably won't be honored reliably by a text-to-sound model.

Checking the prompt length limit now, since the longest prompts may run past the 450-character cap I half-remember for sound effects text.

Now I'm counting the characters in the battery prompt to check it against the length limit.

Counting the characters in the sunward battery prompt, I'm tallying each phrase's length as I go to see how close it is to the limit.

Still counting the characters in the sunward battery prompt, I'm adding each descriptive phrase to see how the total builds toward the limit.

I'm counting the characters in the death_chorus_rupture prompt, which comes to about 380, so it's also under the limit. I'm checking the music prompts next, which I expect are much longer but may have a different cap.

I'm checking whether any of the longer prompts run past the roughly 450-character limit I half-remember for sound effects text, starting with the gauss charge prompt.

I'm checking the prompt lengths now, and the death_eclipse_shear prompt comes to roughly 355 characters, so it's also under the limit I'm trying to confirm.

I'm checking whether the prompt lengths stay under the limit, and the arrival cue comes to about 365 characters, so it fits. The gauss fire prompt is around 375, which also looks safe, so the longer prompts probably all clear the cap I'm unsure about.

I'm checking the weapon pool next, since the trait and name tables for the Sunward weapons seem to line up with the autocannon, battery, heavy battery, and turret entries.

Checking the Sunward battery against the trait table: its listed trait is "las", which would point to a laser cue rather than the kinetic shell cue the plan assigns.

Checking whether the Sunward battery's "las" trait actually means it's a laser weapon, since its name is "Sear battery" and the plan assumes a kinetic cue.

I'm noting that the Sunward battery prompt talks about kinetic rail-artillery and a magnetic muzzle crack, while the gauss prompt for Eclipse also uses electromagnetic rail language, so the two factions could sound alike. The catch is that the Sunward guns are named "Sear" and carry the "las" trait, which points toward a laser-style cue rather than a kinetic one.

Checking the Directorate's weapon names next: the laser becomes "Plasma cannon," the turbo "Plasma battery," and the flak "Picket lasers," so their sound cues will need to match plasma and laser rather than kinetic shells.

I'm checking the Directorate's laser entry against the naming table, since the player sees it as a "Plasma cannon" with plasma trait and plasma hit feedback, which conflicts with the laser-pulse cue the plan gives it. The "Picket lasers" flak is the one that actually matches a laser sound.

I'm checking the Hullbreaker flak entry next, since its row in the table lists a flak weapon that I want to compare against the shared shrapnel airburst cue I've been tracing across several factions.

Checking the flak entries against the sound code: sfx.gd treats every "flak" kind as gun_flak, which would also catch the spore and sentry weapons, so the per-faction flak cues may never get reached.

I'm now checking how the flak branch in the sound code handles the spore and sentry weapons, since they share the "flak" kind and may never reach their own cues. I'm also reviewing whether squadron weapons all route to the squadron gun sound regardless of faction.

I'm checking the spore weapon's shape against the squadron entries: it has the same stats as the bombs, with two shots and one range, so it looks like a squadron weapon rather than a torpedo. The plan's bio-torpedo description doesn't match that, and the faction's name for it is "Acid sacs".

I'm checking whether the Chorus's sporeb weapon is really a torpedo, since the tables show it as a squadron-style bomb payload with the same shape as the bombs, and its faction name is "Acid sacs." The torpedo cue the plan assigns to it may not match what the game actually fires.

I'm now weighing whether the Chorus sporeb is really a torpedo, since its listed kind is squadron-style and its name is "Acid sacs", which would make it a bomber payload instead of a capital launch.

I'm checking the Chorus weapon names and traits next, noting that the bioplasma is called "Spine volley" with a spines trait that strips armor, the tendrils are "Boarding tendrils" with acid, and the spores are a "Spore cloud" point-defense flak with no trait.

I'm matching the Chorus weapon names against the prompt descriptions: the spine volley belongs to bioplasma, not to the point-defense spore cloud, and the bile spray label in the weapon table doesn't agree with the faction name.

I'm checking how the Chorus spine weapon is tied to its prompt, since the "Spine volley" name and spines trait belong to bioplasma, not to the spore cloud point-defense weapon. Mapping the spines cue to bioplasma would line up with what players see, and the spore cloud would need its own prompt.

I'm going to compare the Chorus weapons against their faction names, since "Acid sacs" (sporeb) seems to carry the acid trait and could be the right home for a glob-style cue, while the bioplasma entry may need a second look.

I'm weighing which Chorus weapon each of the remaining prompts should belong to, since the plan's spine and bile assignments don't line up with the faction names. I can't tell from the data alone which glob style players actually see, so I'll leave that choice open.

I'm weighing how the plan's weapon table lines up with the faction names, since the spine prompt seems tied to the wrong Chorus weapon. I'm considering a new spore cloud point-defense prompt and a smaller squadron-scale acid sac burst in place of the torpedo, keeping both the spine and glob prompts with clearer labels.

I'm now checking the Chorus tendril weapon, "Boarding tendrils," whose plan entry describes a sixty-meter alien lash that also carries a muscular wind-up and a chitinous impact. The plan's cue "board_grapple" seems tied to the boarding order rather than to this weapon, so I'll need to keep the lash and the impact as separate beats.

I'm now checking whether the Chorus tendril's "board_grapple" cue is really the weapon's fire sound, since that label seems to belong to the boarding order instead. I'm also noting that the tendril prompt bakes a hull impact into the firing cue, which would misfire on shield-absorbed hits.

I'm noticing that the bomb and flak cues bundle their impact sounds into the firing or release cue, so shield-absorbed or missed shots would still play a hit sound, and I'm checking the Glasswrights' weapon names next.

I'm comparing the Glasswrights' pulsar lance and the shard and turret needle weapons against the plan, since the plan seems to merge the shard and turret into one cue that fires a fixed three-pulse volley even though the two weapons have different shot counts.

I'm checking whether the tonal weapon cues clash with the game's music: the pulsar chord, the star torpedo chime, and the reward and boss stingers are all pitched, and the random pitch jitter could push them more than a semitone off the D minor key. I'm considering asking for inharmonic or unpitched textures on those weapons instead.

Next I'm checking the Eclipse weapons against their faction names: the gauss cannon is "Null cannon," the doom weapon is "Corona arc," and the spire and shredder names don't obviously match the plan's sentry and flak entries.

I'm now checking the Eclipse gauss weapon, "Null cannon," whose plan entry describes an electromagnetic railgun with a tungsten slug and a supersonic crack, while the existing cue is the rail sound already in use.

I'm checking the Eclipse gauss cue against the playbook's faction voice, which calls for a low held note, and the gsentry and gauss prompts don't include one. The railgun wording, with its tungsten slug and supersonic crack, also reads as terrestrial rather than fitting the Eclipse's null identity.

I'm checking the Eclipse doom weapon's prompt, where the "Corona arc" cue has a half-second suck-in pre-delay and a reverb-heavy echo, which goes against the rule that weapon transients fire right at t=0.

I'm checking the Eclipse doom cue now, and the baked half-second suck-in would push the detonation later than the beam visual, breaking my own rule that firing transients land at t=0. I'm also noticing that the nlance and doom entries both map to the same "lance_dark" cue, so the two weapons would share a sound.

I'm checking the Eclipse null lance next, which the plan describes as three shearing pulses about 0.25 seconds apart. The code already fires one shot cue per fire time for it, so if the prompt's pulse spacing is baked into a single 1.6-second clip, the game would hear the pulses arrive in the wrong places.

I'm checking the null lance clip, where the baked three-pulse spacing would stack with the engine's per-fire-time shot cues and double the pulses. A single-pulse clip around 0.8 seconds looks like the fix. I'm also considering whether the volley logic in the salvo path produces the same kind of overlap for the other multi-shot weapons.

I'm checking how the baked multi-shot clips, like the five-gun battery, the twin turret, and the triple-pulse null lance, would stack against the engine's own per-shot scheduling, since each of those could end up playing its pulses twice.

I'm checking whether the baked multi-shot clips, like the five-gun battery and the triple-pulse null lance, would double up against the engine's own per-shot scheduling, since each could end up playing its pulses again for every shot.

I'm checking whether the multi-shot clips, like the five-gun battery, would clash with the playbook's one-sound-per-shot rule, since the engine likely calls the gun sound once for each shot. A baked volley would then repeat its pulses for every shot, so I'm weighing whether the plan should pick volley-per-fire-event as a deliberate design choice.

Now I'm weighing whether the baked multi-shot clips should become single-shot atoms that the engine staggers, with a possible A/B comparison for the heavy battery.

I'm checking the Layer B and Layer C items in the plan against the JSON: no Layer B atom exists at all, and only one Layer C tail does, while the Layer A prompts already bake in body weight and vent decay.

I'm noticing the plan describes a three-layer architecture, but the manifest items are composite one-shots that already bake in body thump and vent decay, with no Layer B atoms at all. For this listening page that's reasonable for judging by ear, but the plan should say so explicitly and leave atom generation for Gate 3.

Next I'm checking the mechanical recoil tail cue, and I'm weighing whether adding two isolated atoms, one body-only Layer B clip, would test the three-layer idea before Gate 3 commits to it.

I'm checking the salvo_tail cue again: it's a volley-level boom that fires once on the fourth shot, so reusing that name for a per-shot breech or vent would change what it means. I also see that a delayed Layer C tail inside a gun cue would break the sound-weight check, which requires weapon shots to stay dry.

I'm noting that the steam vent hiss in the Layer C description is a risk, since "steam" could pull in kettle or iron sounds, and that the sound-weight check would flag any delayed tail inside a gun cue.

I'm checking how the voice cap applies here: it counts active voices rather than individual players, so a three-layer cue takes up one slot. If Layer C had to be split into its own cue to keep the gun cues dry, it would compete for the 34 voices, and per-shot tails could saturate the cap sooner than the overload check expects.

I'm looking at how the voice cap would handle the per-shot tails: stolen voices get cut after about 0.35 seconds, so a tail on a 1.0-second clip would get clipped mid-ring.

I'm thinking about how the gun atoms should be sized: front-loaded clips of roughly 0.5 to 0.7 seconds would be cheaper and fit the short voice lifetimes in heavy salvos, since the generator's minimum is 0.5 seconds. I'm also checking how per-play node creation and the end-time padding in the voice code affect the cue load.

I'm noticing that the mp3 files from the generator carry encoder and decoder delay, plus the model's own leading silence, so the clips won't start at exactly t=0 as the plan requires. A trim step before the ogg conversion looks necessary.

I'm checking whether the mp3 output can be trimmed to a tight onset without a pre-delay click, since the plan's "right at 0.0 seconds" wording doesn't account for the encoder's leading silence. I'm also noting that "click" is a concrete unwanted noun inside a negative phrase, which the playbook rules against, and I'm still unsure whether the API can return wav or pcm instead of mp3.

I'm checking the bridge ambience loop against the existing ambient bed, since a 20-second steady hum could clash with the 120-second room tone already in place.

I'm weighing whether the ambience prompt's "no distinct repeating bangs or creaks" is a problem, since naming those concrete sounds just plants them, and I'd rewrite it as "perfectly steady, unbroken, featureless." I'm also checking "life-support airflow," which could pull in an office air conditioner or a cabin reference, and "subtle distant electrical stillness" doesn't say anything concrete enough to keep.

Now I'm checking the playbook's sound rules against the Gate 2 plan, since the plan drops the "soft top" and the wording around weight may conflict with what Ryan asked for.

Now I'm checking the prompts for harsh wording, since several of them lean on words like "razor-sharp," "shattering," and "loud," which runs against Ryan's dislike of anything harsh or annoying. I'm also noting that the laser fire rate is next.

I'm checking the sound playbook against the new plan, and the "soft top" Ryan asked for conflicts with dropping it from the weapon prompts, so the plan would need its own playbook edit to land the change.

Now I'm checking the ladder requirement against the plan: the laser, battery, and lance descriptions don't yet show each weapon sounding plainly heavier than the last, and the durations I'm seeing don't establish that order.

I'm checking the ladder requirement now: "Colossal" and "Massive" appear across nearly every prompt, including the lance, the ion beam, and the gauss shot, so the size cues would all hit the same maximum. If everything is described at that scale, the weapons won't sound plainly heavier than one another, so the difference has to come from the descriptors instead.

I'm noting that the autocannon is described as "point-defense artillery" even though it's really a battery weapon, and its "Heavy" label and "hammering" thuds don't fit that role. I'm also flagging the "rotary autocannon" wording, since it could pull in a Gatling or helicopter gunship sound, and I want to check whether the Hullbreakers reuse the same autocannon and turret entries.

I'm checking the corsair torpedo mapping next, since "Rattle-rocket pod" is a rocket weapon and shouldn't be paired with the Sunward torpedo entry. The Sunward torpedo is a hellfire-trait "Cinder torpedo," and sfx.gd already maps the corsair torp to torp_rocket, so the plan's use of wep_hullbreaker_rockets for the heavy rocket pod needs a closer look.

I'm checking the Hullbreaker rows next: the corsair torp is mapped to the Sunward torpedo, which doesn't fit its rocket-pod identity, so the Hullbreakers should use the rocket atom for both torp and htorp. I'm also noting that the Sunward forged-iron guns don't match the Hullbreakers' junk-rattle character from the playbook.

I'm now counting which factions use each shared weapon, since the flak, turret, autocannon, and torpedo entries overlap across several factions and the totals matter for the Gate 2 plan.

Checking the Directorate row next: the turbo and hturbo entries both sit under the same prompt, so I'm confirming that the plasma battery and the heavier salvo are each covered.

Now I'm checking the hturbo clip, since it bakes in two blasts where the heavier battery fires three, so per-shot playback would double up. I'm also flagging "turbolaser" and "laser pulse" as terms that pull toward a classic pew-pew sound, so I'd swap in a capacitor-bank plasma discharge instead.

Now I'm settling how the Directorate's weapons should sound: the plasma cannon gets a light shot, the heavier plasma battery becomes a single heavy bolt, and the picket flak gets its own light pulse.

I'm checking the shot counts in the table against the weapon entries, and so far the battery and heavy battery figures line up.

I'm now checking the battery entries: the Sunward battery is a single discharge per clip, which works per-shot, but the Hullbreaker heavy battery bakes five guns into one clip, so the two are treated inconsistently.

Now I'm checking the Gauss entries: three shots, but the charge cue is the shared lance one and would be cut short at its 0.32-second length, even though the Eclipse charge runs 0.9 seconds.

I'm working out the gauss weapon's charge next: there's no charge hook for guns, so a 0.9-second charge before each of three shots would need a new hook, and the prompt's "relay click at peak, then total dead silence" has to fit rise, click, and silence into that same 0.9 seconds.

Now I'm looking at the gauss fire prompt, which wants an instant shockwave whip-crack and sub-bass recoil punch right at the start, followed by a razor-sharp Doppler streak, and I'm weighing whether "razor-sharp" clashes with Ryan's dislike of harsh wording.

I'm weighing whether the gauss wake should stay bundled with the shot or be split out, since the pass-by whoosh already exists as a separate cue and three overlapping volleys could wash together. I'm also noting that "whip-crack" pulls toward a western bullwhip and "Doppler streak" toward a jet flyby, both of which I'd want to avoid.

I'm now checking the gauss snap-crack cues: the Gate 2 version still uses "dry" and "snap-crack" wording, which is close to the recipe that came out sounding like a dry wooden stick snap in Gate 1.

I'm settling on a split for the gauss shot: the crack stays at the start, while the wake gets pulled out, since three overlapping volleys would smear the tails together and the wake depends on whether the shot hits or misses.

I'm weighing whether the heavy pass-by needs its own kinetic and energy cues instead of the generic whoosh, and I'm leaning toward adding both to keep the count manageable. Next I'm looking at the impact cues in the plan.

I'm checking the impact mapping, and the Chorus acid cue is the problem: hit_wet is already the sound for hits landing on a Chorus target, but the prompt describes Chorus acid striking armored plating, so the Chorus weapon is being given the wrong role.

I'm checking the bio-acid impact cue against the plan and finding that it's the wrong way round: the prompt describes Chorus acid eating into metal plating, which is a weapon hitting metal, not a shell hitting Chorus flesh. That leaves the bio target substance without any Gate 2 prompt, so I need to add one that doesn't use metal or alloy language for a Chorus hull.

I'm now going through the bio-acid impact cue and its naming: the plan labels it as a hit on a Chorus hull, but the prompt is really about acid on metal plating, so it would be better renamed to cover the weapon-side effect. That leaves the bio target substance without a cue, so I'm thinking of adding a separate impact for a projectile striking living armored hide. I also want to steer clear of "boiling," "bubbling," and "sizzling," since those words drift toward kettles, aquariums, and bacon.

I'm now weighing the wording for the organic impact sounds: a "wet cartilaginous valve pop" tends to come out comical, so I'm considering how to keep it from landing as a cork popping.

I'm reviewing the wording that could make the Chorus organic sounds come out comical, like "pop," "heave," "bile," and "organ" or "horn" that might be heard as musical instruments or car horns, and I'm planning to swap these for pressure-vessel and muscular drum-skin terms instead.

I'm checking the words that could make the audio come out wrong: "organ" and "horn" could be heard as musical instruments, and "bark" could be heard as a dog. I'm also weighing "rattling iron scrap," which might sound like a toolbox or chains, and "spitting" and "sputtering," which could turn into a mouth noise or a motorbike engine.

I'm checking the remaining cue wording for words that could come out as something else entirely: "locking clamps" and "latch release" might sound like a door or a closet, and "hammering" could land as a workshop hammer on metal. I'm also noting that "pneumatic clunk" on the torpedo prompt is heading the same way.

I'm checking the ui_reward cue next, since its "warm two-note harmonic chime" could read as a doorbell or an electronic notification, which Ryan tends to dislike.

I'm checking the ui_reward cue's wording next: the "two-note harmonic chime" reads like a doorbell, and "sci-fi UI" could push the result toward synthetic beeps, which Ryan would dislike.

I'm checking the ui_boss_arrival sting next: its "war-drone" and "harmonic pulse" wording could push the result toward a synth drone, and "signal" could come out as an alarm or beep.

I'm weighing whether the low brass and contrabass with a deep bass-drum boom underneath would keep the sting acoustic and away from synth territory. I'm also checking the UI coverage for the "ui" audio_check family, which lists ui_click, ui_confirm, ui_cancel, ui_round, and ui_your.

I'm now looking at the remaining UI cues, checking which ones the Gate 2 set doesn't cover yet: ui_enemy, ui_select, ui_panel, ui_alert, and the rest of the stings. The most frequently heard are the clicks, the confirm and cancel sounds, and the turn cues, so I'm leaning toward adding acoustic, mechanical versions of click, confirm, and your-turn, keeping them away from electronic territory.

I'm settling on three additions for the listening set: a click, a confirm, and a your-turn cue, all built from acoustic or mechanical sources rather than electronic ones, since those are the most-heard sounds in the game. I'm also looking at the impact sound for armored glass, which is a 1.2-second cue describing deep, resonant glacier-sheet fracture with a heavy, bell-like ring.

I'm checking the glass armor impact, and it's too heavy for a routine hit: the prompt describes thick crystal slabs shearing apart, and since that cue plays on every hit against an Ithar ship, it would sound like the ship is breaking each time and collide with the death sound.

I'm noticing that the next stretch covers the gap in impact coverage: the common metal hit, energy impacts and shield hits are missing, while rare events like shield breaks and deaths already have cues. I'm planning to add a light metal impact and an energy sear impact to fill that.

I'm now checking the glacier-sheet wording for the glass armor cue, since "glacier" could pull in water or calving recordings that carry splashing, which would be wrong for a frozen-lake-style crack.

I'm checking the "plate" wording in the obsidian eclipse cue, since "glassy stone-plate fracture" and "dry" could bring to mind a ceramic dish breaking in a kitchen.

I'm checking whether adding a metal hit to the per-target cue table would shut off the weapon-family impacts for metal targets, since the target lookup returns before the weapon lookup is reached, and the audio check's assertions for those weapon cues would then fail.

I'm checking whether the new metal-target entry in the per-target cue table would cut off the weapon-family impacts for metal targets, since that lookup returns before the weapon lookup is reached. The audio check's assertions for those weapon cues, like the laser and the plain hit, would then start failing. I'm also noticing that any new cue ID has to be listed in the cue families or the check fails outright.

I'm checking whether the new metal-target entry would cut off the weapon-family impacts, and whether any new cue ID has to be listed in the cue families or the check fails.

Next I'm checking the death sequence in death_audio.gd, where each cue lands at a set point: the powerdown opens it, the vent comes at 0.25 seconds, the crack at the crack point, and the bass drop at the core, with the tail and wreck following the split.

Now I'm checking the death_directorate_blackout cue for the Hegemony, which is a 1.3-second powerdown variant of death_powerdown: a heavy breaker slam into a steep, descending turbine and power-bus hum that drops into dead silence. I'm weighing whether "breaker slam" and "turbine" could pull in a fuse-box click or a vacuum winding down.

I'm checking the hegemony death cue's "descending turbine" wording, since it could bring a domestic appliance winding down to mind, and I'd rather point it at a power station generator hall. Then I'm looking at the corsair hull-snap cue, where "exploding" and "whip-crack" may push it toward an explosion or a literal whip, and the baked-in echo may be a problem too.

I'm checking the death cues against Gate 1 and Gate 2, starting with the tether snap: a steel cable under tension, with a sharp metallic twang and a whip-crack. Next I'm looking at the chorus rupture cue, where "organ rupture" and "horn-chitin" could pull in the wrong sounds, and where the "rush of breath" phrasing from Gate 1 would risk a balloon-like result.

I'm checking the chorus death cue's "pressure" and "rupture" wording against the balloon-pop risk, then turning to the Glasswright strain case, where reusing the Ithar death cue as a lower-gain damage layer could blur the difference between damage and death.

I'm checking the death sequence for the Sunward fleet, which has no faction-specific death cue, so it keeps the base steel clips, and I'm weighing whether to swap only one stage per faction and leave the vent, tail, wreck and bed stages as they are.

I'm adding a death sequence for Sunward that covers the generic explosion and break, since the base boom clips have no candidate yet and a full death run needs judging in one audition, and I'm noting a shield-break cue that's partway through its description.

I'm checking the shield-break cue next, where "pitch drop" and "cascading" sound like an arcade power-down tone, which Ryan has ruled out. I'm also noting that "tearing" and "ripping" show up in several cue prompts, and the notes ban that kind of literal tearing wording.

I'm checking the "vacuum" wording across the shield, doom, prismatic, torpedo, breach and tendril cues, since "vacuum suck-in" and "vacuum drop" could bring a household vacuum cleaner to mind. I'll look at replacing those with plainer space-and-pressure terms.

I'm looking at the breach cue next, where the decompression hiss could sound like a tire or balloon leaking air, so I'd anchor it with a roaring gale or jet-like blast instead, and I'm considering splitting the shear and decompression into two layers so the decompression can be dropped on the Chorus.

I'm checking the breach cue's material split: the shear layer is metal, which fits the alloy hulls but not Chorus flesh or Glasswright crystal, so I'd separate a metal-shear layer from a shared decompression vent. I'm also looking at the turret knockout cue, where "servo motor" could bring a small appliance to mind rather than a turret mechanism.

I'm checking the turret knockout cue next: "servo motor" could bring a small domestic device to mind, and its hydraulic grind and electrical arcs don't fit the Chorus mounts, which should get only the spore wisp with no metal sparks. Since the plan's knockout rule has no faction guard, I need to add one.

I'm checking the turret-knockout trigger now: it fires on the edge when a slot first goes off, but on a sync or reload with slots already down, every one would fire at once, so I'd need to guard against that.

I'm checking the generator crackle timing next: the audio could fire on each crackle, which comes every 1.4 to 3 seconds per ship, but the visual only lasts about 0.2 seconds, so an 1.8-second clip would run well past it and end up nearly continuous.

I'm checking the burnout crackle timing: firing a full clip on every crackle would run nearly continuous on each ship with a down generator, so I'd keep the first crackle at full level and make the later ones a much quieter, shorter patter.

I'm checking whether engine loss needs its own cue, since nothing covers a drive sputter yet. Metal ships could get a dedicated engine-failure sound, while Chorus keeps its spore cough, and I'm also looking at how the warp-in cue's duration has grown from 0.45 to 1.5 seconds.

I'm checking the Sunward lance beam cue, where "reactor-furnace" and "hiss" could pull the sound toward a blowtorch or a gas burner, so I'd anchor it to a directed energy discharge instead.

I'm checking the lance cue's wording against the fire-in-space rule, since "furnace" and "hiss" might pull it toward a blowtorch or flamethrower, so I'd anchor it to an industrial arc at dockyard scale instead.

I'm looking at the torpedo launch cue next: it bundles a clamp release and an ignition about 0.3 seconds apart, and the engine already has a separate charge sound for torpedoes, so the mechanical stage may belong there instead.

I'm checking the torpedo ignition cue against the Sunward launch, where the clamp release and ignition bundle together, and I'm noting that the wording for the Ithar start-torpedo sounds like a wind chime, so I'd swap in a struck crystal bowl tone.

I'm checking the Ithar shard cue next, where "cut-crystal" could bring to mind clinking wine glasses, so I'd swap in dense quartz or a laser-cut sapphire lens with a deeper low body.

I'm checking the Ithar pulsar cue next, where "quartz-bell" and "glass-organ" could bring a glass harmonica or wine-glass rim to mind, and its pitched chord sits awkwardly against the music key. I'd add a low sub thump under the shimmer so it doesn't sound thin.

I'm checking the Directorate ion beam cue now: "bug zapper" and "static" could pull it toward small domestic electrics, so I'd anchor it at power-station scale instead, and I need to make sure its high-voltage discharge doesn't overlap with the Eclipse gauss charge.

I'm noticing electricity wording keeps recurring across several factions and damage cues, with "high-voltage" and "capacitor" showing up in the ion beam, the gauss charge, the shield-break and turret-knockout cues, and "magnetic" appearing in most of the weapon prompts. That overlap could make the electrical weapons blur together, so I'll need to separate them by scale and texture.

I'm noticing that several of the weapon cues are starting to sound alike, especially the crisp crack sounds for the Sunward battery, turret twin, Eclipse gauss fire, and the autocannon and gsentry. That overlap makes me want to separate them more clearly.

I'm checking the remaining weapon pairs for sound overlap: the autocannon, craft guns and flak all rely on tight kinetic pops, and the gsentry and directorate laser both lean on a razor-sharp crack with a dry cutoff.

I'm now sorting the weapon cues into distinct sound families, with Sunward as chemical propellant and iron ring, Directorate as regulated capacitor thump, and Glasswright as tonal crystal with clear pitch.

I'm weighing whether the Eclipse guns should drop the railgun crack entirely and become a deep, hollow null cannon thump with a low held tone, since that would fit their faction and avoid overlapping with the kinetic cluster. The existing gauss cue and its "ignores half of armor" key point the other way, though, and the art direction is Ryan's call to make.

I'm checking the ocean-era wording left in the Gate 2 prompts, since the torpedo cue asks for an orbital bay tube, which reads like a submarine launch tube.

I'm checking the remaining terms for sea-related wording, since "tube" and "pneumatic shove" would suggest a submarine torpedo launch. I'd swap that for a heavy anti-ship missile cold-launched from a spacecraft cell, and I'm noting that "torpedo" and "warship" also show up in several other prompts that may need the same fix.

I'm checking the remaining wording for naval leftovers: "warship" and "hull" could suggest a wooden ship, "flak battery" reads like WWII anti-aircraft, and "leviathan" brings a sea monster or whale to mind.

I'm now checking the remaining wording for sea-related leftovers: "leviathan" could suggest a whale or underwater creature, "abyssal" could call up deep-sea rumble, and "wake" could bring a boat's trail to mind. I'm also noting that the boss arrival's low-brass swell might sound like a foghorn.

I'm checking the boss arrival cue: its long low-brass drone could sound like a ship's foghorn, so I'd make it a rhythmic two-note figure with bowed low strings and a bass drum hit instead. I also want to make sure the "sub-" prefixes in the sound descriptions don't read as submarine-related.

I'm checking the "dark" descriptors across the battery, thermal lance, vault and boss prompts, since in audio terms that word suggests a muffled, low-passed sound rather than a dark mood, so I'd swap it for something that describes the timbre directly.

I'm now looking at whether the "dark" descriptor on the weapon prompts is pulling the timbre toward something muffled, and I'm considering dropping it from the weapon cues while keeping it for ambience.

I'm noticing the remaining prompts have explosive wording on cues that shouldn't be explosions, like the "explosive breech bark" and the whip-crack on the hullbreaker death, plus "detonation" appearing in the doom and flak cues.

I'm now checking the remaining weapon cues for small-scale sounds that could read as toys: "dart" in the spine prompts could suggest a blowgun or nerf gun, and "crisp dry staccato kinetic pops" in the flak and craft guns could come across as a toy cap gun or popcorn.

I'm going through the remaining weapon and death cues for words that could pull the sound toward the wrong scale, like "clunk", "snap", and "hiss", which could read as kitchen or household noises. I'm also noticing "ricochet ping" and "skittering" have cartoonish or insect-like connotations that don't fit a crisp sci-fi sound.

I'm checking the "no" phrases in the prompts for anything that might backfire, like "no big bass boom" in the flak cue, which could plant the very boom I'm trying to avoid. I'm also weighing "no shot" on the gauss charge, since that concrete noun might call up a gunshot, and I'd rather describe the silence positively.

I'm going through the remaining prompts for words that could push the sound off target, like "no gunshot" and "no explosion" in cues that already describe firing, since naming the thing I want absent may bring it in.

I'm checking the remaining prompts for "no" phrases that name the very sound I want absent, like "no gunshot", "no shot", and "no big bass boom", since naming them may bring them in. I'm also noticing that "distinct from capital artillery" and the meta-instructions about stacking and looping don't give the model anything usable to work with.

I'm reviewing the remaining prompts for design-intent phrases like "for a space strategy game" and "fleet", which could push the model toward generic game sound effects, and I'm weighing whether to cut them. I also notice the tail phrases repeat, so I'll trim those too. Finally I'm considering the prompt influence values, since higher settings would make the model follow the literal prompt more closely.

I'm now moving on to the music cues, starting with the battle prototype, which runs 90 seconds on the music model with one take, and I'm weighing whether raising the prompt influence from 0.6 to 0.65 would make the prompts follow too literally. I can't confirm how the influence field is actually passed, so I'd treat that change as untested, and I'm considering an A/B on two prompts at 0.4 versus 0.65 as a cleaner check than varying the takes.

I'm checking the music prompt for the battle cue next, and the "Homeworld and Battlestar Galactica" reference stands out as a problem, since music generators often reject prompts that name copyrighted works. I'd swap those names for a plain description of the tactical dread I want.

I'm weighing whether naming Homeworld and Battlestar Galactica in the music prompt is wise, since those references tend to pull in choir and vocal elements and may get the prompt flagged. I'm also checking whether the 90-second arc actually loops, since a piece that ends on a resolution will likely get a tacked-on finish rather than flowing back into its opening.

I'm checking the loop length: at 94 BPM a 90-second track doesn't land on a whole number of bars, so I'd move to 96 BPM, where a 36-bar loop comes out to exactly 90 seconds.

I'm checking the loop length for the reward track too: at 80 BPM a bar is 3 seconds, so 45 seconds works out to 15 bars. Since players can linger on the reward screen longer than that, I'm weighing whether it needs to loop or should end cleanly into silence.

I'm checking whether the music.json tracks include a reward-screen slot, and it seems they don't, so I'm trying to pin down what the reward screen actually plays right now.

I'm now weighing whether to keep the current reward-screen music, which is probably the Gate 1 clip with its warm brass and strings. The proposed replacement uses a solitary cello and French horns in a darker, longer form, so it would change something Ryan may already like, and I'm weighing that risk against the plan's clean-slate approach.

I'm checking whether the "glass harmonics" in the Sunward battle cue clash with the palette, since glass belongs to the Glasswrights and Sunward is meant to sound like weathered brass, cellos, and forge-metal percussion.

I'm checking the faction flavour for the Sunward battle track: the music player picks the enemy's colour first, so the plan needs to say whose faction the track should follow.

I'm now going through the stem plan, where the four stems are drums and percussion, low strings with bass, brass with the motif, and pads in the faction colour. I'm not sure the stem separation will produce those custom labels, since typical separators return vocals, drums, bass and other, which would leave the vocal stem empty for an orchestral instrumental.

I'm now weighing whether the stem separator will even return the custom orchestral stems I planned, since standard splitters usually give vocals, drums, bass, and other, which would dump the brass and pads into one bucket. I can test that on the existing Gate 1 battle preview before designing any four-stem mix.

I'm weighing whether the stem separator's fixed output categories can support a layered build inside one 90-second song, since a single stem split would not necessarily give me the custom brass and pad layers I planned for.

I'm working out whether the four stems can mix cleanly at all, since the stems share one playhead while the game's intensity moves on its own clock. The song's built-in arc and the stem gains would then stack on top of each other, so a raised percussion stem early on could go silent against the composition, and a calm state could end up sitting under the climax's strings.

I'm settling on the stem question: the 90-second tracks should stay at full density in every bar, with the evolution carried by chord and motif changes rather than by thinning out stems, since the mixer alone handles intensity. Since battle can run for minutes, a fixed 90-second arc would repeat predictably against the player's pace, so I'm weighing that too.

I'm weighing two prototypes for Gate 2: a linear three-part showcase arc to judge palette and motif, and a constant-density 96 BPM, 36-bar loop meant for stems. I'd run the adaptive mix offline from the loop once stems exist, with the full pair coming to about 1,350 credits, or 900 if both are cut to 60 seconds.

I'm settling on the Gate 2 prototypes: the showcase track can go to 96 BPM with sections at 12 and 24 bars, and I'm weighing whether a separate 60-second stem-ready loop is worth its own credits, since Gate 3 depends on it even though it would sound sparse on its own.

I'm weighing a second prototype: a 60-second, 24-bar full-density loop at 96 BPM, about 900 credits, to test stem separation before any broader Gate 3 work. I'm also looking at whether the current player can run stems at all, since it uses three separate players for calm, hot and bed, and those tracks are different lengths, so they never line up.

I'm checking whether the three-layer plan fits the current player: calm, hot and bed map onto existing music.json slots, so it could work with data-only changes if the stems are equal length and start together. Sample-accurate sync would need AudioStreamSynchronized, and four stems would need four gain curves, since feed() only gives one intensity value.

I'm checking how the music player handles looping: it only sets loop points for Ogg files, and ElevenLabs outputs mp3, so the track could play once and stop unless the import settings handle it.

I'm checking the looping and mixing hazards next: mp3 encoder padding could leave a gap or click at each loop point, so the stems would likely need transcoding to ogg and cutting at matching sample points. I also need to confirm that the ducking reroute in sfx.gd still works if the new player keeps the music bus.

I'm checking the faction preview next: it only picks up track ids starting with "fac_", so new "mus_battle_*" tracks would silently fall back to title music, and with stems the preview would play just one layer, so it needs a full-mix file. I'm also looking at how a boss battle swaps the hot track.

I'm checking the music player's boss-battle swap, where the hot layer gets replaced by an unrelated track, which would break coherence if stems are synchronized. I also need to confirm that the audio check's `feed` threshold still holds and whether the tests rely on the `state()` dB keys. Last, the victory and defeat fanfares are still old tracks, so a new solemn reward theme would clash tonally, and stings aren't covered in Gate 2 yet.

I'm checking the remaining music risks: whether the reward theme can double as the victory sting, since the fanfares are still the old tracks and the title and map screens aren't covered yet. I also see that a text prompt can't lock in a specific 4-note motif, so each generated track would likely invent its own, and I'm flagging that as unverified.

I'm checking whether the motif can be guaranteed at all, since independent text prompts will likely invent different four-note tunes. A cheap test is to write the pitches and rhythm into both prompts and see whether the battle and reward tracks share a tune on the listening page.

I'm checking the generator's SFX figure next: 57.2 seconds per take at 40 credits each gives 2,288 per take, and with the fixed ambience and music costs of 2,825, two takes come to about 7,401 credits.

I'm checking the per-take cost against the billed amounts: the estimate gives 5,113 credits for one take, which is about 613 more than the 4,500 the plan states. Gate 1's SFX actually billed at roughly 11 credits per second rather than 40, so the two takes would land near 3,500 credits, and the second take costs only about 0.5% of the pool, so credits aren't the limit here.

I'm weighing two takes against one: the extra take would let me tell a bad prompt from an unlucky roll, but at the real billed rate it adds only about 629 credits, so credits aren't the constraint. The real cost is listening time, since two takes means roughly 88 SFX files to audition instead of 44, and with about half the prompts needing structural edits anyway, I'd rather spend that ear time on fixing prompts first.

I'm settling on two takes for the short core combat sounds and UI, since those are where a single bad roll is most likely, and one take for the longer items like beams, torpedoes, deaths and events to keep the spend down.

I'm settling on running the SFX in two waves with `--only`: a small smoke test first to check onsets and scale, then the rest once the prompt fixes are in. Credits aren't the constraint, since at the real billed rate an extra take costs well under one percent of the pool, so the limit is listening time.

Checking whether a 12-second ambience bed would cover the same loop need for about 480 credits instead of 800, since Gate 1 already produced a similar 12-second map bed.

Now I'm working out the edits for each item and recalculating the credit totals, including whether to give the longer ambience bed a shorter duration.

I'm working out how to present the full replacement JSON for the changed items, weighing whether to paste complete objects for each one so nothing gets lost when it's applied.

I'm settling the prompt edits and how to roll the SFX out, with the credit and listening budget in view.

I'm settling the Sunward gun prompts next: I'll keep them as iron-and-fire kinetic weapons and drop the rail and magnetic wording, and I'll flag for Ryan whether the shell visuals match that style.

I'm still working through the Gate 2 prompt list and thinking about how to compress the Sunward battery cannon entry, since its shot length and wording need to be tightened.

I'm weighing whether to keep the baked salvo as a single-take A/B item next to the engine-staggered single shot, since Ryan would need to compare them and the stitching can be handled when the listening page is built.

I'm weighing whether to keep the baked salvo as a reference take for Ryan, even though the engine staggers shots per the ruling. It's cheap, so I'll keep it as an A/B item that isn't wired in.

I'm reviewing the Sunward heavy battery entry: a single ship-scale main gun shot, close and dry, with a forged-iron barrel ring and a low hull shudder, kept at two takes for a fair comparison.

I'm settling the turret entry as a single shot, and I'm weighing whether a medium turret can sound distinct enough from the main battery if I keep its tail short and its ring brighter.

I'm drafting the autocannon entry as a single round at 0.5 seconds, with a hard mechanical report and a quick metallic action, and I'm planning two takes for it.

I'm settling the torpedo launch entry next: the ignition burn happens at the start, with a deep thruster surge that pulls away cleanly.

I'm drafting the torpedo eject entry as a separate short, heavy launch-cell sound, then moving on to the flak airburst as a single fire-only shot.

I'm reworking the flak entry as a single fire-only shot at 0.5 seconds, then swapping the directorate laser for a plasma cannon with a tight capacitor-bank discharge and a clean, controlled low-mid punch.

I'm settling the directorate picket entry as a single pulse from a military plasma cannon, close and dry with a fast clean attack, and I'm keeping it at one take since it's a light, quick shot.

I'm settling the directorate picket entry as a single short pulse from a point-defense energy emitter, close and dry with a firm, clean attack and no reverb. Next I'm moving on to the ion disruptor cannon, a larger sustained arc beam with a deep magnetic hum.

I'm now turning to the hullbreaker scatter gun, where each pellet is a single scrap-cannon blast of about 0.8 seconds with a ragged propellant burst and a spray of tumbling steel fragments, and I'm dropping the "shotgun" wording so it doesn't read like a hunting weapon.

I'm on the Hullbreaker rocket entry now, planning a single rocket shot for the torpedo and heavy torpedo cues, though I'm still checking how many shots the engine fires for the heavy version.

Now I'm describing the Chorus spine volley: a single bone spine fired from a living alien creature, with a deep muscular release and a dense chitin crack.

I'm tightening the Chorus spine entry to a single bone spine fired from a giant living alien creature, with a deep muscular release and a hard chitin crack, and I'm dropping the "rush" and "whip" wording.

I'm settling the Chorus tendril entry as a lash-only fire cue, with the impact left to the separate impact sounds, and describing it as a giant armored alien tendril with a deep heavy muscular lunge and a taut fibrous strain at full stretch.

I'm drafting the spore-cloud entry next, working from the acid-sac wording and keeping the bio-craft to a single compact release.

I'm drafting the spore-cloud entry as a large creature venting a dense defensive spore cloud, with a short heavy pressurized gas burst carrying a grainy spray of particles that spreads and thins fast, at about 0.8 seconds. Next I'm starting the Ithar shard entry.

I'm drafting the Ithar pulsar entry next, a focused crystalline light lance with a bright sustained quartz-bell tone over a deep steady hum, cut off with a short fading ring.

I'm finishing the Ithar set now: the pulsar keeps its clean sustained beam and I'm settling on a duration of about 1.5 seconds. The startorp entry is a single deep struck-crystal tone with a strong radiant hum that recedes into the distance, with nothing metallic or vocal in it.

Empty.

I'm checking the Eclipse gauss charge entry now: a deep, heavy charging hum that ends in a hard relay clack, kept as a single take since there's no charge hook for guns yet.

I'm settling the Eclipse gauss fire entry as a single heavy magnetic slam at 0.7 seconds, and I'm adding a separate fly-by sound for the projectile wake.

I'm moving on to the Eclipse corona arc entry, a single superweapon discharge at the start with a massive low-end surge.

I'm checking the Eclipse corona arc entry, a single superweapon discharge at the start with a massive low-end surge, and I'm drafting a separate deep inward-pulling charge sound to lead into it.

I'm working out the remaining weapon entries, keeping the Eclipse doom charge at about 0.6 seconds since the existing charge lead is shorter than its clip. Next I'm checking whether a craft gun burst should be baked into one cue or kept as a single shot, since squadron fire is abstract and the shot count is uncertain.

I'm writing the bomber entry now, a single heavy bomb release at close range with a solid magnetic rack thunk, a short dense mechanical drop, and a brief thruster kick as it leaves.

I'm settling the mechanical recoil tail as a heavy machine cycling once, with a damped hydraulic return, a steel block seating, and a short coolant vent, kept free of gun wording so it doesn't layer onto a salvo.

I'm adding a soft low-body impact cue for the heavy weapon layer, a deep sub-bass thump with a short dense hull shudder and a rounded top, kept at two takes. Then I'm moving on to the heavy armor-piercing shell entry, removing the ricochet ping and describing a crushing metallic crunch with a deep hull boom and scattering steel fragments.

I'm drafting the light metal impact cue next, a medium shell on thick armor with a quick dense thud and a small scatter of fragments, kept clearly smaller than the heavy breach. Then I'm starting the energy sear entry for the hot bolt hits.

I'm writing the glass-armor entry now, keeping the impact at about 1.0 seconds, with a heavy hit on a thick crystalline hull that booms out with a low bell tone and a short run of cracks.

I'm now on the acid entry for the weapon side, renaming it to an acid-on-metal cue: a dense heavy liquid impact followed by a deep corrosive roar and a fading seething hiss, about 1.2 seconds. Next I'm starting the flesh-target variant.

I'm checking the acid-on-flesh variant for the Chorus creature now, a heavy blunt impact into thick chitin with a short low fluid burst, and I'm keeping it clear of any metal. Next I'm moving on to the Eclipse obsidian armor entry, describing a cold brittle basalt crack.

I'm settling the Eclipse obsidian armor entry as a heavy impact with a cold brittle crack, then moving on to the shield break entries, where the energy shield collapse gets a hard snap and a deep low-end collapse over 1.5 seconds. I'm starting the prismatic shield break next, with a bright crystal fracture cascading into heavy splintering tones.

I'm now on the hull breach entries: the first is a thick armored plating shear-open at about 0.8 seconds, with a violent steel rupture and snapping girders. Next I'm moving to the vent variant.

I'm writing up the fighter breach entries next, the vent variant with its broad, violent jet of pressurized air that thins out quickly. Then I'm starting the turret knockout with a heavy grind into a mechanical jam and two short arc snaps.

Next I'm drafting the dmg_engine_fail entry, a large starship engine losing power with a deep thruster roar that stumbles into two uneven low surges before dropping away, with the Chorus excluded.

I'm tightening the death entries now: the Directorate blackout stays at two takes with a heavy power-relay slam and a slow power-down into silence, and the hullbreaker snap gets a strain groan followed by a hard cable-parting crack. I'm starting the Chorus rupture entry next.

I'm finishing the Chorus death entry, a colossal armored creature splitting apart with a heavy chitin crack and a deep low rupture into silence, then moving to the last one, the Ithar shatter, where I'm swapping the glacier-tone groan for a deep low resonant strain.

I'm on the last weapon-side death entry now: a large armored starship breaking apart, with an immediate enormous deep structural break, a heavy low-end blast as the steel plating ruptures, and a long low rumble as the wreckage tumbles away.

I'm now on the ui_boss_arrival entry, a slow deep orchestral bass hit with low brass and bowed double basses under a heavy metallic hull shudder, played in a large hall with no synthesizer or vocals.

I'm now working out the reverb-free placement of the ui_reward_vault cue and deciding its level sits just below the boss arrival sting. Next I'm starting the ui_click_switch entry, a single short solid low-mid mechanical click.

I'm drafting the UI click and confirm cues now, a short solid low-mid switch click and a firmer two-stage lever clunk, both dry with no synthesizer. Next I'm weighing the turn-start strike on bronze, keeping it calm and acoustic at roughly two takes.

I'm now on the fleet warp-in cue, a short tight inward pressure snap followed by a deep low displacement boom and a quick clean engine rumble, kept at about 1.2 seconds. Then I'm moving to the bridge room tone, a low steady reactor hum with faint ventilation air under it.

I'm drafting the battle music prompt now: a dark orchestral space fleet score in D minor at 96 BPM, built on a grave four-note motif in low brass and cello, in three 12-bar sections that move from tense to building.

I'm finishing the battle score prompt, describing the bar-by-bar tension and climax, and then starting a looping stem variant that holds four parts steady across 24 bars.

I'm on the reward-screen theme now, a quietly triumphant instrumental piece for the dark space strategy game at 80 BPM in D Dorian, and I'm keeping its tone restrained and close to the earlier reward preview.

I'm finishing the reward-screen music brief now: a warm, restrained acoustic orchestral theme of about 48 seconds, with a solo cello stating the four-note motif and the strings swelling before settling on an open fifth. I'm also setting the Gate 1 reward preview aside as a no-cost listening control.

Now I'm totaling the credits for the weapon takes, with the 1.0-second heavy battery at 40 credits a take.

Now I'm listing the remaining weapon takes at their per-take credit costs, starting with the torpedo eject and the flak airburst.

Now I'm going through the weapon list from the Chorus spines down, with the credit cost per take for each one.

Still tallying the credits for the eclipse weapons, with the gauss fire and pass-by slug each at 56 across two takes.

Checking the remaining weapon entries: the craft bombs and mech recoil tail each come to 48 and 56 credits over two takes at their durations, and I'm adding the new layer body heavy at 48 as well.

Now I'm running the weapon credit subtotal, adding each take's total as I go.

Now I'm adding the impact entries, which total 512 credits across seven items at two takes each.

Now I'm totaling the shield and damage entries, with the shield breaks and hit absorb coming to 280 credits and the breach, turret, burnout and engine entries to 344, and I'm starting on the death entries.

Now I'm adding up the subtotals for the death, UI and event entries, which come to 712 and 548 credits, and I'm folding the short SFX totals in after them.

I'm adding the subtotals up to 4,880 for the SFX entries, then the 800 for ambience and 2,970 for music, which brings the total to 8,650. That's higher than the 7,401 I had before, mainly because of the new stem-loop prototype, so I'm checking whether that increase is acceptable.

I'm weighing whether to keep the total close to the original 7,401 by trimming the ambience bed, since the Gate 1 map bed already covers a similar prompt.

I'm weighing the stem-loop variant at 40 seconds across 16 bars, which costs 600 credits instead of 900 and brings the total down by 300. I'm also considering whether the ambience bed could drop to 12 seconds, since the Gate 1 map bed already covers a similar prompt, saving another 320.

I'm settling the music budget now: trimming the stem-loop variant to 40 seconds brings it to 600 credits, so the music total drops to 2,670. That puts the whole plan at about 8,350, and I'm weighing whether to present that honestly as a rise over the earlier 7,401.

Checking the stem-loop length: at 96 BPM a bar is 2.5 seconds, so 16 bars comes to 40 seconds. Sizing the SFX and music estimates against the original plan, I'm getting about 4,232 credits at the likely real rate, compared with roughly 3,503 before.

I'm tallying the item counts now: 47 originally, with the weapon and impact entries swapped out for the new versions, and I'm checking whether the 124 SFX clips are too many to audition comfortably.

I'm listing the new and renamed item IDs now: the added weapons, impacts, damage and UI entries, plus the renames and replaced entries that make up the remaining changes.

I'm checking the final item count now: 66 entries in total, against the original 47. The new ones are eight weapons and three impacts, with the turret entry renamed in place.

I'm checking the item count against the original 47 and tallying the new entries: eight added weapons, three impacts, and a few damage, death, and UI items, with the turret entry renamed in place. That brings it to 66 in total, which is a sizable jump, so I'm considering whether all of these additions belong in the paste list.

I'm trimming the optional items to see how far the total can come down: the six optional entries add up to 464 credits, bringing the total to 7,886. Dropping the 12-second ambience trim as well would take it to about 7,566, still just above the original 7,401.

I'm weighing a trim to hold the total under the original 7,401: setting aside the stem-loop prototype and the six optional items would bring it to about 7,286. I'm also wondering whether rewriting all 47 prompts is necessary, or whether the ones that already work can stay as they are, which would keep the list shorter.

Now I'm deciding which sound items to leave as they are: the ion beam, the Ithar shatter, the Eclipse shear and the Directorate blackout, since their prompts are only minor issues. Everything else gets a replacement entry.

I'm deciding whether the full JSON is worth the length, since I can cut it down by sending only the id plus the fields that actually change for each existing item, while new items still need complete objects.

I'm checking the review's blocking issues now. The first is that several weapon clips are baked as multi-shot salvos, which the per-shot sound engine can't trigger cleanly, and the second is that a few t=0 clips have pre-delays or bundled beats that break the timing rule.

Now I'm going through the blocking issues: several weapon clips are baked as multi-shot salvos, which the per-shot engine can't trigger cleanly, and some t=0 clips carry pre-delays or bundled beats and baked impacts that break the timing rule. I'm also checking the roster mapping, where a few items point to the wrong table rows, and a recurring trap word that keeps turning up in the prompts.

Now I'm checking the remaining problems: several terms from the earlier Gate 1 prompts are still in use, including "tearing", "sizzling", "boiling", "two-note chime", "whip-crack", "shotgun", and "leviathan". I'm also noting a few negatives that still slip in, like the pink-elephant line.

I'm sorting the review findings into tiers now: the blocking problems, then the high-priority ones, starting with the trap-word list and the harshness overcorrection.

I'm going through the remaining review findings: the similar-sounding clusters, the coverage gaps across hit, UI, and death events, and the music and stem questions, starting with the 94 BPM bar math and how the stems would behave under adaptive mixing.

I'm moving on to the wiring hazards, like the expansion of the hit-by-target event breaking the audio assertions, the cue families, and the shield burnout cadence. I'm also flagging the credit estimate in the plan, which lists about 4,500 where the real figure is 5,113, and noting that the estimator overstates costs compared with the Gate 1 billing.

Now I'm going through the smaller items: tonal SFX against the music key and pitch jitter, the "bed" versus "intermittent" wording for the shield burnout, reusing the Ithar shatter as a strain layer, the UI prompts that read like a synthetic sci-fi brief rather than Ryan's taste, and the "dark", "in space" and "echoing" words that should become muffle or reverb notes. I'm also checking the breech-clack diagnosis, where the prompt order rather than a suffix seems to be the cause, and the v2 claim that lacks evidence, then the low-priority table gaps where flak is missing from some prompt ID columns.

I'm tracing the JSON tails now, checking the wep_sunward_battery prompt for "kinetic rail-artillery cannon" and the "Heavy dark sci-fi" wording alongside the pre-delay clause, then the hbattery entry.

I'm checking the JSON prompts for the turret, autocannon, lance, and torpedo entries, looking at how each one describes its discharge timing and character.

I'm checking the remaining JSON prompt lines for the flak, laser, turbolaser, ion, scatter, and rocket entries, looking at how each describes its discharge and whether it carries sound-design language that should be trimmed.

I'm going through the bioplasma, tendril and spore-bomb prompt entries next, checking how each one describes its discharge and whether the sound-design wording, like "leviathan" and "boiling", needs trimming.

I'm checking the remaining weapon prompts against the JSON, going through the shard, pulsar, starport, and sentry entries for their timing and sound-design wording, then the Eclipse gauss charge and fire lines.

I'm checking the Eclipse gauss fire and dark-lance entries now, looking at how each describes its shot and whether the sound-design wording, like "abyssal hum" and "echoing across cold space", needs trimming.

Checking the craft and imp-sound prompt lines now: the strike craft guns are meant to stay distinct from the capital artillery, and the bomb drop is a magnetic clunk followed by two armor-piercing thumps. I'm also looking at the recoil tail, which should be a pure mechanical vent with no gunshot, and the metal and glass impact prompts.

Next I'm going through the remaining impact and breach prompts in the JSON, checking the bio-acid hull impact, the obsidian stone fracture, the energy-shield break cascade, and the prismatic shield sound that should have no metal boom.

Now I'm checking the remaining JSON prompt lines for the breach, knockout, burnout, blackout, hullbreaker, chorus rupture, and the Ithar and Eclipse shear entries, looking at how each describes its sound and whether the wording needs trimming.

I'm checking the UI and ambience entries now: the boss sting is a low-brass war-drone that fades into dark reverb, the reward chime is a warm two-note sci-fi UI tone, and the warp tail needs to stay crisp so staggered arrivals stack cleanly. I'm also confirming that the ambience has no repeating bangs or creaks, and I'm noting the remaining music cues and the line references in the markdown and sfx.gd files.

I'm now checking the line references for the sfx.gd code, covering the gun, twin, and flak early returns, the salvo thinning, the voice caps, and the reverb settings, along with the cues.json limits for gun_shell, lance_charge, lance_dark, and salvo_tail.

I'm checking the audio test files next, covering the cue family list, the impact assertions, and the sound-weight and salvo checks. I'm also looking at the music player and music.json references for looping, faction previews, and mixing.

I'm going through the line references for the Godot files and the generation script, checking the powerdown, crack, and boom sound points, the slot-off edge, and the chorus return in the generated crackle. I'm also checking the ElevenLabs script for the published estimate, the v2 removal, the rates, the mp3 output, the duration limits, and the credit formula.

I'm cross-checking the references in the docs and the tables excerpt, covering the sound playbook rules, the death and hit rules, and the specific table rows for the spore bomb, spores, strike gun, gauss lance, and Doom cannon entries.

I'm cross-checking the table line references for the weapon entries by faction, covering the Voidsworn, Hegemony, Corsair, Chorus, Ithar and Deathless rows and the trait lookups for the battery and laser weapons.

I'm checking the table line numbers for the bioplasma, spores, gsentry, nlance and doom entries, confirming each key and name, and now moving on to the FAC_WNAMES weapon names by faction.

I'm checking the faction weapon name tables now, going through the Voidsworn, Hegemony, Corsair, Chorus, and Ithar entries, and I'm on the Deathless ones next.

I'm cross-checking the remaining table line numbers, confirming the Deathless entries for the gauss, doom, gsentry and flak weapons, and the Chorus bioplasma, tendril and spore-bomb traits. I'm also checking how the Sunward las trait maps to its hit handler.

I'm settling on a verdict: the edits should be spent, and I'll give Ryan a short 5-8 line summary. For item 2, the gauss fire should be split, while the battery shots are staggered by sfx.gd, which plays one cue per gun() call and thins salvos, bringing in salvo_tail on the fourth shot within 0.45 seconds.

Now I'm weighing whether the engine already staggers per-shot starts for a battery, since it thins gain on successive plays and adds the salvo tail on the fourth shot, so a baked clip would double up the tails. Voice caps could also cut most of a multi-ship battery's 1.5-second clips.

I'm now laying out the line-level edits for the markdown file, taking the key spots in turn: the diagnosis at line 11, the ban list, the trim step, the soft-top wording, the model choice, the takes, the layers, the table rows, the hit and breach rules, the capability note, the music stems, the motif, and the budget and credit figures.

I'm laying out the table rows for the Sunward Crusade, Hegemony, and the other factions, with each weapon's traits and sound files, and I'm keeping the "one propellant shot per gun" note for the battery entries.

Now I'm settling the JSON patch format: entries get merged by id, with cue, seconds, takes, model, and prompt included only when they change. I'm also adding a v3 twin of the battery clip, with the same prompt and no model field, so the v2 choice can be tested against it.

I'm adding a v3 twin for the impact clip as well, at 40 credits, and recomputing the totals: SFX comes to 4,952 credits, ambience 800, and music 2,670, for 8,422 overall. That brings the plan to 68 items and 130 files.

Now I'm working out the audio budget: 4,952 credits of SFX comes to about 123.8 seconds billed, which I estimate at roughly 4,252 credits in actual use once the ambience and music are counted. If I drop the stemloop and the six optional clips, the total falls to about 7,358, just under the 7,401 limit.

Tallying the per-take credit costs for the rest of the weapons, each take is multiplied by its listed credit rate, with the pulsar, startorp, and gauss entries carrying the larger totals.

Now I'm summing the per-take credits for the remaining items, which comes to 2,484. I'm also adding the two A/B twins, the battery and the impact clip, each at 40 and 32 credits.

Now I'm verifying the per-category sums: impacts 512, shields 280, damage 344, deaths 712, and UI 548, which brings the SFX total to 4,952 once the two A/B twins are included.

I'm settling on a wave A of 13 items: the battery and its v3 twin, the laser, spines, shard, gauss fire, lance beam, and the heavy metal impact with its twin, plus the flesh impact, energy shield break, Chorus rupture death, and switch click. Keeping takes at 2 is worth the small extra cost, since the second take separates a weak prompt from a bad roll.

I'm summing the wave A credit costs, which comes to 1,060 for the 14 items, about 26.5 seconds of audio and roughly 290 billed at 11 per second. Music is the expensive part, so I'm leaning toward running it in a later wave after checking onset and scale on wave A, and I'm setting the wave A credit cap at 1,200.

I'm checking the remaining constraints: every id uses only lowercase letters, digits and underscores, and every seconds value is at least 0.5. I'm also confirming that the takes setting on the UI click works with the generator's default of one take, and I'll note the mp3 file naming at line 82 as observed, with the leading-padding point left as a general codec assumption.

I'm checking the original count of v2-pinned SFX items, listing the battery, turret, laser, flak and other entries one by one, and I'm on the ninth when the list cuts off.

Now I'm checking how the music player runs its three loops, the calm, hot and bed tracks, and how each one gets started.

I'm checking how the three music layers start and whether they stay in step, and they don't: each is its own play() call, crossfaded by one intensity value, over tracks of different lengths, so nothing keeps them aligned. Adding a third part would break that alignment further, so for Gate 3 I'd rather write one steady-density loop where all four parts sit in every bar and the progression lives in the harmony, with any extra variety handled later as full-density sections that switch on bar boundaries.

I'm checking the reward-screen music next: the plan never mentions it, and the music file has no reward track, so the one Ryan likes is probably the Gate 1 preview. I'll keep that file as a control and aim the new prompt for the same warm, restrained tone.

Now I'm checking the reward-screen music, since the plan doesn't mention it and the music file has no reward track.

Now I'm checking the top-line recommendations: one shot per clip, no pre-roll inside shot clips, fixing the weapons mapped to the wrong sounds, and running the music in two waves.

Next I'm writing up the findings, starting with B1: twelve fire clips have a multi-shot volley baked into one file, even though the engine already plays a separate cue for each shot.

Now I'm checking the engine side of the fire clips: the playbook asks for one gun sound per shot at its own fire time, and the SFX code already counts salvos from per-shot starts and puts the tail on the fourth shot.

Now I'm checking the steal timing: with a gap of 0.045 to 0.072 seconds between starts, the seventh shot takes the first voice at roughly 0.35 seconds, so a 1.5-second clip gets cut short in a volley.

Checking the fire clips for pre-roll and bundled beats next: several of them open with a build-up or charge before the shot, and the engine already has charge slots for some of those.

Now I'm checking the remaining fire clips for pre-roll: tendril, sporebloom, the craft bombs, flak, and gauss_fire each open or close with a hit or airburst that belongs after the shot, not inside the clip.

Now I'm drafting the trap-word table for H1, listing each flagged phrase with its line number, the risk it carries, and a replacement.

Now I'm writing up the trap-word table, pairing each flagged phrase with its line, the risk it carries, and a safer replacement, such as swapping "tearing apart" for "collapsing into" or "parting".

I'm writing the last few trap words into the table: "short cold magnetic snap" gets a hollow low tone added, and "deep muscular thud" gets a dense chitin crack. Next I'm replacing the tableware and wind-chime phrasing with a quartz block struck once, then swapping the doorbell line for a single low bronze bell tone, the whip-crack lines for heavy slams or cable snaps, and "explosive breech bark" as the last entry.

Now I'm working through the trap-word list, pairing the last few entries with safer replacements: "dog" gets a ragged overdriven propellant blast, "shrapnel-shotgun" becomes a scrap cannon blast, and the submarine torpedo tube turns into an anti-ship missile launch cell. I'm also swapping the creature names for a giant living alien starship creature, and I'm dropping the naval "warship" and "plasma-wake" wording.

Now I'm listing the remaining trap words with their replacements, covering "starship" in place of the naval terms, a held low drum hit instead of the foghorn-style brass, "rupture of dense tissue" and "rigid chitin armor plates" for the organ and horn wording, short hard reports for the cap-gun pops, a spray of heavy steel fragments for the ricochet ping, and I'm working through the steam vent hiss next.

Now I'm going through the trap-word list for the last entries, pairing each with a safer replacement: "ant gas vent" becomes a pressurized coolant gas vent, "hydraulic servo motor" a heavy drive-gear grind, and "decompression hiss" a roaring jet of escaping pressurized air. I'm also swapping the vacuum wording for an inward-pulling pressure swell and a low-end collapse, and I'm replacing the wet valve pop and corrosive bile lines with a compact dense organic pressure thump. That leaves "dart discharges" as the final entry still to handle.

Now I'm going through the last trap-word entries, pairing each with a safer replacement: "dry glassy stone-plate fracture" becomes a brittle crack of a massive basalt slab, and the arcade power-down cascade turns into a deep low-end collapse. I'm also swapping the laser and turbolaser pew sounds for a plasma cannon and capacitor-bank discharge, and the skittering insects for a short burst of arc crackle. The last line, the spitting and raspy exhaust tails, gets a rough roaring solid-fuel burn.

Now I'm compiling the full trap-word table, listing each flagged phrase with its line number, the risk it carries, and a safer replacement.

Now I'm drafting the JSON entries for the changed items, starting with the Sunward battery cue set to a single shot.

Now I'm drafting the remaining JSON entries, working through the changed items one at a time and then the new ones.

Now I'm drafting the JSON entries for the changed items, covering the Sunward battery and its salvo reference, the twin turret swapped for a single turret, and the autocannon cue rewritten as one round.

Now I'm drafting the lance entry and the torpedo launch cue, then the flak and laser cues, each marked as a single shot.

Now I'm drafting the JSON entries for the remaining weapons, giving each one a single-shot cue and a short prompt.

Still writing the JSON entries for the weapon cues, each marked as a single shot.

Still writing out the JSON entries for the weapon cues, covering the remaining items with their single-shot cues and short prompts.

Still writing out the JSON entries, now the impact, shield, and death cues, each with a short prompt.

Checking the totals for the remaining items, I'm counting the changed weapon entries against the unchanged ones to make sure the 40 changed entries add up.

Now I'm checking the totals: the changed entries add up to 40, with the three removed and four unchanged accounted for, and the new entries are being listed by group.

Now I'm checking the item totals: 25 changed weapon entries plus the ion beam and 10 new ones make 36, and the full count lands at 68 with the remaining entries still to be written out against their prompts, keeping each one under about 400 characters and avoiding the flagged wording.

Now I'm finishing the lance prompt, describing it as a huge heat beam that ignites into a steady white-hot roar with a deep reactor drone beneath, then cuts off cleanly. I'm also starting the torpedo launch entry, an anti-ship missile igniting as it leaves the tube.

Checking the remaining audio prompts now, making sure the lance and torpedo descriptions avoid the flagged wording and that the damage and impact entries don't describe anything as a hiss.

Now I'm going through the last few notes on the music prompts and the UI entries, making sure the wording avoids anything that could pull in a synth sound and sticking to real recorded mechanical objects instead.

I'm now turning to the wording for the remaining prompts, and I plan to flag a few choices for Ryan to decide on, such as whether the Sunward guns should be shell guns or sear bolts, and whether the Eclipse should sound like a railgun crack or a null low note. I'm also setting up the wave commands for a dry run and then a limited batch.

I'm listing what I couldn't check: the call sites in battle.gd and fx_weapons.gd, the rest of elevenlabs_gen.js past line 100, and how the service itself handles timing, filtering and cost. Nothing here has been heard, so the prompt risks are inferred from the wording and the Gate 1 results in the notes.

Now I'm checking the remaining estimate in the notes, confirming the dry-run total of 7,401 by working through the per-take cost of 2,288 doubled, plus the 800 and 2,025 figures.

Now I'm checking the voice-cap side of the tail cue: the sfx voice limit is 34, and a separate tail cue would compete for those slots. Since the steal logic picks the lowest-priority voice, a tail at priority 1 could cut off a gun at the same level, so I'm thinking of setting it to priority 0 the way the pass-by cue already does.

Now I'm checking the reverb and distance settings in the audio code, since the plan assumes the engine will handle depth through bus reverb and distance attenuation.

Now I'm checking the death cues: the powerdown variant for big deaths needs its own duration, since the base cue is only 0.6 seconds and would otherwise cut off the 1.3-second blackout.

I'm reviewing the death-cue durations next: the powerdown and crack cues have base lengths well under their intended playback, so any variant without its own duration would be cut short. I'm also noting that the arrival jump cue is short at 0.45 seconds, and checking the audio test that expects certain variants to replace the base cues.

Now I'm checking the death-cue hit on Chorus bio-acid impacts, which the JSON entry labels as a corrosive hull hit, against the hit-by-target mapping that sends Chorus to the wet impact cue.

Now I'm writing out the final prompts for the changed weapon block, starting with the Sunward battery as a single heavy shot.

Still writing out the weapon entries, now the Sunward heavy battery salvo as a reference line and the autocannon entry.

Still writing the weapon JSON entries, now the flak airburst cue and the Directorate laser.

Still writing the Directorate hturbo entry, describing the capacitor-bank discharge as a deep, dense ion blast.

I'm now writing out the remaining weapon entries, describing the Hullbreaker scatter as a single ragged scrap-cannon blast with a spray of steel fragments and a rattling bolted housing.

Writing the Hullbreaker rocket entries...

Still writing the Chorus spine entry, describing it as a heavy bone launch with a muscular release.

Still writing the Chorus sporeb entry, a sac of spores bursting from the creature.

Still writing the Ithar shard entry, describing a crystalline prism strike that rings out clearly.

Still writing the Ithar pulsar and startorp entries, describing a quartz-bell beam lance held steady before a clean cutoff.

Still writing the Ithar startorp entry, a single deep crystal tone that recedes into a shimmering tail, then moving on to the Eclipse gsentry cue as a cold magnetic snap with a hollow low tone.

Still writing the Eclipse gauss entries, describing the null cannon charge as a low dread-filled transformer hum that stops on a hard relay clack.

Still writing the Eclipse null cannon entry, a hard magnetic slam with a crushing low end that falls silent fast.

Now I'm writing the Eclipse doom entry, describing the flagship superweapon as a monumental low-end slam that leads into a long hollow roaring arc, and then starting the craft guns cue.

Still writing the craft bomb entry, describing a heavy magnetic rack release with a short mechanical drop.

Still writing the weapon JSON entries, now the heavy armor-piercing shell impact cue for thick starship plating.

Still writing the armor impact entries, now the metallic hull-frame boom with a spray of heavy steel fragments.

Still writing the shield and impact JSON entries, describing the obsidian armor crack and the energy shield collapse.

Still writing the damage cues, now a turret knockout sound: a heavy drive-gear grind seizing into a hard mechanical jam, followed by two short high-voltage arc snaps.

Still writing the death cues, now a huge welded scrap-metal hull straining and snapping apart.

Still writing the death cues, now the Chorus rupture as a heavy armored creature splitting apart with a deep low-end tissue tear, and then starting the boss arrival sting.

Still writing the audio prompts, now the heavy starship warp-in arrival cue, a tight inward pressure snap.

Now I'm writing the ambient bridge bed, a calm low reactor hum with soft ventilation air that stays even from start to finish, and then the battle music prototype cue as a dark orchestral fleet score at 96 BPM.

Still writing the battle music prototype, now its tempo, key, and bar structure in three 12-bar sections with a repeating motif.

Still writing the Sunward turret entry, starting with the gun shell cue.

Still writing the Sunward turret entry, now the heavier Sunward battery as a single very heavy main-gun shot.

Still writing the weapon JSON entries, now the Sunward battery variant with the same prompt kept identical for the A/B test, and then starting the torpedo eject cue.

Still writing the torpedo eject cue, a heavy launch cell with a deep compressed-gas thump and a dense steel rail slide ending in a solid stop, then the Directorate picket laser as a single fast energy snap with a small capacitor thump.

Still writing the Chorus spore cloud entry as a flak variant.

Still writing the Chorus spore cloud entry, and now the pass-by cue for a heavy shot flying past close.

Still writing the Layer B test entry, a low-body-only variant to check the three-layer idea before the next gate.

Still writing the impact entries, now a light metal hit cue and the heavier A/B impact variant, then the energy sear cue for laser and plasma bolts.

Now I'm writing the Chorus acid entry, a dense liquid impact on thick armor plating that settles into a deep corrosive roar, like an acid vat eating steel.

Still writing the engine-failure and death cues, now a breach decompression sound shared across every hull type.

Still writing the UI cues, now a soft click for switching and a confirm latch, then the turn-start bronze plate strike.

Still writing the battle music prototype, now its instrumentation and the four-note motif that varies every four bars, with a steady pad holding it together.

Now I'm drafting the write-up, keeping the summary to a few plain lines and the findings brief.

Wrapping up the write-up now, checking the findings against the credit and timing figures before I lock it in.

