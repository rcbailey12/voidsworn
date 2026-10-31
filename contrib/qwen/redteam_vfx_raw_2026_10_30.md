# Red Team Audit: Visual Effects and Graphic Design Seat

Voidsworn, "Embers of the Hollow Sun"
Auditor seat: VFX and Graphic Design
Date: October 31, 2026
Evidence pin: main head b3a3b802, game code pin 264f441d

## Findings (ranked by severity for this seat)

### Finding 1: The counted-flash budget certifies a gated subset while the brightest emitters bypass it

OBSERVED. The fx implementation review states the budget "certifies a gated subset while several of the brightest emitters bypass it." The chair verdict is explicit: "a budget the brightest emitters bypass does not meet the spec it claims to implement." The accessibility spine in the effects sheets synthesis sets a "hard cap 3 flashes per second, plus a reduce-flashing option." The spec the effects pass claims to implement is WCAG, which "counts flashes on screen, not calls into a budget function."

What it costs: The single hardest accessibility commitment in the effects language is structurally unmet. A worst-case salvo from capital-class weapons can exceed the 3-flash ceiling because the emitters most likely to exceed it are outside the accounting. The reduce-flashing mode (Qwen's 0-flash variant) cannot reduce what it does not track. This is not a tuning gap; it is an architectural gap. Every downstream test of the flash rule is testing the wrong system.

### Finding 2: Per-weapon persistent marks are mostly absent; the damage language is generic

OBSERVED. The fx implementation review audits ten weapon families against the damage marks reference (the R43 merged spec). Results: battery PARTIAL, lance PARTIAL, ion MISSES, torpedo PARTIAL, flak NOT IMPLEMENTED, bio PARTIAL, gauss PARTIAL, squadron MEETS, ram MISSES, boarding MISSES. The review's overall verdict: "PARTIAL, leaning MISS on the specs as written." The two things the specs actually specify are "per-weapon persistent marks" and a valid flash budget; neither is built.

What it costs: The entire readability premise of the damage marks reference, that "a mark reads by shape family" at fleet distance, collapses into a single generic scorch decal. Ion "runs the identical _beam_burn as lance and leaves the identical scorch" (fx_weapons_gd.txt:697-730). Ram "leaves the same glowing scorch as a torpedo" (fx_weapons_gd.txt:605-606, 793-821). The player cannot read what hit them. The four-way convergence in the reference document on architecture and individual marks becomes wasted design labour if the implementation ships a single orange decal.

### Finding 3: The Compatibility renderer path draws zero persistent damage marks

OBSERVED. The fx implementation review states: "under the Compatibility renderer, scorch and hole decals draw nothing at all (fx_death_gd.txt:132-135, 155-158)." The Godot desktop 3D brief confirms from the engine side: "Compatibility has NO decals in 4.7; they appear only in 4.8 dev snapshots (GH-118070)." The brief also notes: "Since 4.4 it auto-falls back to Compatibility when the RenderingDevice is unsupported; that degraded path must be tested or gated."

What it costs: Any player whose GPU cannot initialise Vulkan, D3D12, or Metal gets the automatic fallback and sees no damage marks whatsoever. Every per-weapon mark verdict in Finding 2 becomes literally invisible on that path. The brief names the pattern to gate this ("check RenderingServer.get_current_rendering_method()") but the fx code has no such gate. If the Godot build ships without gating, the effects pass silently degrades to no-damage-state visuals for the entire affected audience, with no warning.

### Finding 4: Chorus and Hegemony weapon colours are indistinguishable from their own damage glow

OBSERVED. The palette safety check computes Chorus weapon #DDF176 against damage_glow #D4F66F at 1.02:1 contrast. Hegemony weapon #C4EAFF against damage_glow #FFDDA6 sits at 1.03:1. The check states: "Every faction sits between 1.02:1 and 1.40:1, so a faction's weapon colour and its own glow colour are never separable by brightness, only by hue." The two white-gold glow colours (Hegemony damage_glow #FFDDA6, Eclipse accent #FFECBC) are "only 26.8 apart in normal vision, the closest cross-faction pair computed anywhere in this pack."

What it costs: In a 20-ship battle at fleet distance, the damage marks reference says marks read by "shape family, brightness and silhouette, never by texture detail." If a Chorus ship firing its own weapons produces the same colour as its own damage glow, the player cannot tell incoming fire from outgoing fire by colour channel alone. The effects sheets synthesis assigns faction colours to shields and weapons as a core readability layer. Two of six factions fail that layer at their own signature colour. Under deuteranopia, Sunward Crusade versus Chorus closes to a distance of 29.7 out of about 441, making the problem worse for colour-vision-deficient players.

### Finding 5: Flak chip damage drives structural breaches, contradicting the flak spec's core rule

OBSERVED. The fx implementation review states: "flak chip damage still drives stage 3 and 4 structural breaches, the opposite of the spec's never-exposes-structure rule." The damage marks reference entry 5 is explicit: "The patch grows in area and density, never in depth; flak never exposes structure in the mark language (Rey)." In the implementation, flak "sits in the light set and leaves no decal" (fx_weapons_gd.txt:590) while simultaneously triggering the same stage-transition geometry as a torpedo.

What it costs: The staged damage ladder's stage 3 ("hull plating gone in patches revealing interior structure") and stage 4 ("actual holes, not decals") are the most expensive visual states in the system, carrying fire plumes, streaming debris, atmosphere jets, and spark showers. Flak, designed as the weakest and most frequent weapon, triggers these states without leaving any flak-specific mark. The player sees heavy structural damage from what should read as light chip fire. The damage language lies about the cause. Every flak burst in a 20-ship battle can trigger geometry swaps, particle systems, and streaming parts that the spec reserves for heavy weapons, inflating the effects budget for the least narratively important hits.

### Finding 6: Repair reverses stage geometry but never removes hit decals, so hull language and game state disagree

OBSERVED. The fx implementation review states: "Stage geometry reverses on repair; hit decals are never removed, so a repaired section still wears its scorch and holes, against spec A's rule that hull language and game state must not disagree." The damage marks reference agreement 4 establishes the fresh/cooling/scarred lifecycle, and the cross-cutting behaviour audit confirms the DECAL shader's "own header comment claims cooling its fragment code does not implement" (fx_shaders_gd.txt:737, 765-833).

What it costs: In a roguelite where repair is a core survival verb and "repair always beats scrap-and-replace per ship by design," the player repairs a ship and it still looks wrecked. The staged damage ladder exists so the player can read fleet health at a glance. If repaired sections carry permanent scorch and holes, the readability contract is broken at the exact moment the player most needs to trust it: deciding which ships to commit to the next battle. Over a multi-node campaign run, every repaired ship accumulates visual noise that no longer encodes information.

### Finding 7: Gauss entry holes are the smallest persistent mark and the spec'd companion cue does not exist

OBSERVED. The fx implementation review states: "the entry hole is the smallest persistent mark in the game, so gauss history is invisible at fleet distance." The damage marks reference entry 3 calls gauss "the honest problem mark: the hole cannot read at fleet distance (all four legs agree)" and prescribes "a pale stress ring with short radial cracks (Rey) or a silver-white petaled collar (Argon)" as the distance read. The review confirms: "Spec A's distance-tier companion cue (pale stress ring or petaled collar) is absent."

What it costs: Gauss is a signature weapon in the seven-kind effects grammar. Its distance read is the one mark all four reference legs solved with a companion cue, and that cue is not built. At the 20-ship fleet distance where the damage marks reference says marks read "by shape family, brightness and silhouette," gauss simply vanishes. The player cannot track gauss damage history, cannot read which sections have been punctured, and the weapon's tactical identity (the row of two or three holes along the shot path) is lost.

### Finding 8: Engine trail colours collapse under colour-vision deficiency, undermining faction identification in motion

OBSERVED. The palette safety check reports: "Hegemony against Eclipse engine colours fall to 14.6 under deuteranopia, the smallest distance computed anywhere in this pack." In normal vision the smallest engine pair is Sunward Crusade against Ashfall Hullbreakers at 30.6. The check notes: "Engine colours are worse than weapon colours."

What it costs: Engine trails are the primary motion signature in a space fleet battle. The effects sheets synthesis mandates engine trails as part of the cinematic bar ("Weapons and engine trails must feel more realistic and cinematic, up to BattleTech, Sins of a Solar Empire, and Rogue Trader"). The Corsair engine cough effect in fx3d.js is a per-ship plume animation, meaning engine trails are constantly visible during battle. At 14.6 RGB distance under deuteranopia, Hegemony and Eclipse engine trails are functionally identical. A player with the most common form of colour-vision deficiency cannot tell which faction's engines they are watching during a retreat, a pursuit, or a multi-faction engagement. The IFF system (green for friendly, violet for enemy) partially covers this, but faction identity within the friendly or enemy group is lost.

### Finding 9: The V1b prow fix created a top-view/side-view silhouette disagreement unique among the three hulls fixed

OBSERVED. The hull surface diagnosis records: "the fix changed the side profile and left the top profile pointed, so the two outlines now tell different stories: pointed from above, blunt and drooping from the side." H8 and H7 on the same sheet show matched pairs after their fix: "the bow is a flat vertical face in both the top and the side views. V1b is the only one of the three whose top and side disagree." The diagnosis further observes: "the bow no longer slopes to a point. The profile runs out and then hooks downward, ending in a blunt, drooping snout."

What it costs: Faction silhouette readability depends on consistent outline reads from the player's primary camera angles. The tactics orbit rig means the player regularly sees ships from above and from the side. A bow that reads pointed from one angle and blunt-and-drooping from the other creates a visual identity flicker as the camera orbits. The hull surface diagnosis also identifies the broader wavy-hull geometry problem ("plates that bulge like cushions across every deck"), which the diagnosis leans toward calling a mesh loft issue rather than a material issue. If the mesh carries the wave, no material pass will fix the silhouette.

### Finding 10: The staged damage ladder's thresholds and durations are all marked UNSURE; the readability system is built on screen-tuned guesses

OBSERVED. The effects sheets synthesis states: "Thresholds are balance values, UNSURE; sizes and durations below are screen-tuned guesses." Every stage from scorched through wreck carries specific numbers for decal sizes, fire plume counts, debris intervals, atmosphere jet durations, and secondary explosion timings, all flagged as guesses. Stage 3's exposed-structure method is itself "UNSURE." The death sequence timings (cook-off 0.8 to 2.5 s, break-up into 4 to 10 sections, wreck field 10 to 30 s) are proposals, not tested values.

What it costs: The staged damage ladder is the backbone of the entire effects language. The R16 bar says "damage reads as holes with streaming parts, fire, and other damage states, not orange lines." If the stage thresholds are wrong, a ship at 60 percent hull might look identical to one at 80 percent, or a ship at 20 percent might not look dramatically worse than one at 40 percent. The cinematic benchmark depends on the wreck stage being "mournful and cinematic, the payoff of the whole ladder." With every number unvalidated, the effects pass cannot be budgeted against PERFCAP because nobody knows how many simultaneous fire plumes, debris streams, and atmosphere jets a 20-ship battle actually produces at each stage boundary. The performance budget item in the Godot brief depends on these numbers being locked.

## Verdict

MISS, leaning structural. The effects language has a strong spec spine (the staged ladder, the per-weapon marks reference, the flash budget, the faction palette) but the implementation in godot/fx/ delivers a generic scorch decal where the spec demands ten distinct mark families, a flash budget that the brightest emitters bypass, and a renderer fallback that erases all persistent marks. The single most important attack: the counted-flash budget does not cover what is on screen, which means the accessibility ceiling the effects sheets synthesis commits to is unenforceable in the current build, and every downstream flash test is measuring the wrong system.

## Not checked

This seat could not judge from this pack:

- How any of the transient effects or the staged ladder actually reads in motion at fleet distance. No video, no screenshots from the running game, no Ryan playtest transcript are in the pack. Every readability claim here is from code and spec documents, not from observed frames.
- The Babylon.js browser build's effects fidelity relative to the Godot tree. The pack contains fx3d.js and wfx3d.js line counts and the ring-merge optimisation, but no per-weapon effect implementation excerpts from the browser build equivalent to the godot/fx/ code. Whether the browser build has the same generic-scorch problem or a different one is not judgeable from this pack.
- The Pyre-Barge deferred standard. The pack references it as a seat concern but provides no spec, no asset state, and no timeline. Its absence from the evidence base means the deferred benchmark cannot be attacked or confirmed.
- The actual PERFCAP measurements on Ryan's PC. The profiler code is in the pack (perf3d.js) but no collected data, no CSV output, no summary. The performance cost of the staged ladder, the death sequences, and 20-ship streaming parts is unmeasured in this pack.
- Sound. The effects sheets synthesis states "Sound cues in both legs are design descriptions (words only), not claims about existing game audio." This seat defers all audio findings to the audio seat. The pack's sfx.js and sfx_data.js are inventoried but not excerpted.
- Whether the third silent weapon deletion (b_razor_s dropping bioplasma, found Oct 30) leaves orphaned effect code or removes a visual that players had learned to read. No code excerpt for b_razor_s is in the pack.
