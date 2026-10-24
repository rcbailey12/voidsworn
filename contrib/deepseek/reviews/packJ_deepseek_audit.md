# Pack J adversarial audit: DeepSeek report (raw return, unverified archive)

Source: DeepSeek chat, DeepThink ON, Search OFF. Pack J uploaded as .txt (473.87 KB) on the first attempt (no rename needed, never PDF). Sign-in completed as Ryan Bailey (rcbailey12@gmail.com) via Google OAuth with no phone verification prompt on the fresh attempt; two hCaptcha challenges cleared during sign-in. The response initially truncated mid-Engineer and needed one "Continue" click, then finished in full. Report received Oct 24, 2026 via browser task. Filed below with DeepSeek's em dashes normalized to hyphens per house style; wording otherwise verbatim. Rey's screening and the three-way reconciliation are separate documents; nothing in this file is a verdict.

## Pack J: Adversarial Audit of the Voidsworn Design Document Set

Read order: rulings first, then errata, then the corpus. Findings are ranked by damage within each lens. Quote or it did not happen; every finding cites a document and a quote under 20 words. OBSERVED = stated in the text; INFERRED = my reasoning from the text.

### 1. Engineer

Can a single coder build this in Babylon.js? Are the mechanisms specified enough to implement, or hand-waved? Are budgets, ceilings and performance claims measured or asserted?

Finding E1 - The kit work order's central premise is wrong. The work order is built on "35 of 36 queued hulls are not started" (ship_kit_upgrade.md), but the errata states "All 36 hull meshes already exist and the game loads them" (reading_plan.md). The 69-session figure is a hull-creation rate, not a dressing rate. The document's biggest-lever argument is mis-aimed at a job that is already done. OBSERVED. Damage: critical.

Finding E2 - Loft v2 is not implementable from the text. "The loft interpolates stations with smooth curves and computes true normals" (ship_kit_upgrade.md). No interpolation scheme (Catmull-Rom, B-spline, etc.), no normal algorithm, no station-to-station continuity rule. A coder cannot write this from the spec. OBSERVED. Damage: high.

Finding E3 - "Impossible to express" is asserted, not mechanised. "A new hull that violates its pack should be impossible to express, not merely discouraged" (ship_kit_upgrade.md). A grammar pack is a parameter set, not a constraint system. No validator, schema or build-time check is specified that would make a violation impossible. OBSERVED. Damage: high.

Finding E4 - Per-class ceilings are demanded but never set numerically. "Per-class vertex and triangle ceilings for phone" (ship_kit_upgrade.md). No numbers follow. The beauty corner spec admits "the gate is marked provisional and the corner's job includes turning it into a measured ceiling" (beauty_corner_spec.md). A gate with no numbers cannot fail a hull. OBSERVED. Damage: high.

Finding E5 - The manifest and landmark system has no schema. Modules are "placed by landmarks in the manifest (prow, bridge, hangar, gun deck, engine)" (ship_kit_upgrade.md). No coordinate system, no socket definitions, no placement rules. The kit's data contract is a list of words, not a format. OBSERVED. Damage: high.

Finding E6 - The texture-memory figure is asserted and internally inconsistent. "A 20-ship battle wants about 1.32 GB of texture memory" (ship_kit_upgrade.md). The same document recommends "1K per hull family" (visual_expansion_research.md). Twenty ships at 1K compressed cannot plausibly reach 1.32 GB; the number is a guess dressed as a budget. OBSERVED. Damage: medium-high.

Finding E7 - The three largest documents still assume phone-first. The research memo opens "must perform on a mid-range Android phone (a Pixel is the reference device)" (visual_expansion_research.md). The tool guides say "phone first with a desktop tier" (tool_guides.md). The graphics craft doc says "phone first, desktop tier" (graphics_craft.md). The PC-only ruling drops phone entirely. The errata names only four smaller documents as superseded, not these three. OBSERVED. Damage: medium-high.

Finding E8 - The joint paint solve is unspecified. "One gain across hull and kit texels, the 0.3 emissive fudge in aiKitMat deleted" (ship_kit_upgrade.md). The gain value is not given; the replacement for the 0.3 fudge is not given. The paint solve is named but not specified. OBSERVED. Damage: medium.

Finding E9 - A load-bearing pipeline setting rests on forum answers, not official docs. "Default pipeline details rest on forum threads and a third party walkthrough" (tool_guides.md); "the current DefaultRenderingPipeline doc page itself was still not opened" (verification_sweep.md). The HDR/AA trap is correct per forum evidence, but it is not officially documented. A coder implementing the pipeline is working from community memory. OBSERVED. Damage: medium.

Finding E10 - The kit's proof exemplar does not exist. The rollout is "proven on one manifest: the Basilica hero" (ship_kit_upgrade.md), but "the Basilica manifest the spec points at as its proof exemplar does not exist as a file yet" (reading_plan.md). Step 1 depends on an unwritten artifact. OBSERVED. Damage: medium.

Engineer verdict: GO WITH CONDITIONS. The mechanisms are mostly specified at a high level, but the kit's economic premise is wrong, and several core parameters (ceilings, manifest schema, loft interpolation, paint gain) are hand-waved. Next step: Reconcile the kit work order with the asset inventory - rewrite it as a dressing/paint/VSM-conversion job for the 36 existing meshes, and set numerical desktop ceilings before any hull is gated.

### 2. Designer

Do the systems cohere as a game? Does the BattleTech + Sins 2 + Rogue Trader mix hold together? Is the 20-ship battle size consistent with the spectacle claims?

Finding D1 - The battle-size target is internally contradictory. The ruling states "Target battle size stays near the current scale (around 20 ships)" (conversation_context.md), but the Rogue Trader benchmark is "one to three player capital ships per battle" (conversation_context.md). The design trade says "when a choice trades fleet size against per activation decision weight, take the decision weight" - which would argue for fewer ships, not 20. The ruling keeps 20 without explaining how decision weight survives at that count. OBSERVED. Damage: critical.

Finding D2 - The gold law fails on its own text. The art direction says "Gold is rationed: patrons and Command UI only" (art_direction_rey.md), but the same document assigns "Chorus trim is dull gold" and "Ithar trim is pale gold" (art_direction_rey.md), and the errata admits "epic rarity stays gold-adjacent" (reading_plan.md). Gold means at least three things, not one. The acceptance test will fail two factions' hulls. OBSERVED. Damage: critical.

Finding D3 - The Chorus admiral set violates the Chorus ruling. The ruling bans "buildings, instruments and architecture" (conversation_context.md), but the Matriarch is "a faceless column of membrane organ pipes" (art_direction_rey.md), the Voice of the Deep is "an abyssal comb-jelly bell" (art_direction_rey.md) - a sea creature - and the Mending Choir "stitches a broken hull with fleshy sutures" (art_direction_rey.md), a constructed action. Razormaw is "a blade formation" (art_direction_rey.md), not an organism. All four final portraits break at least one ban. OBSERVED. Damage: high.

Finding D4 - The plate system has six anchors for five terrain kinds and no mapping. The art direction promises "a plate per terrain kind" then lists six plates: Belt, Storm, Graveyard, Planet, Station, Dead Star (art_direction_rey.md). Battle.js has five terrain kinds (belt, station, planet, storm, graveyard). Dead Star has no terrain kind. The reading plan admits "Plate wiring is not mapped" (reading_plan.md). The kit doc calls plate wiring "the fastest visual win in the whole overhaul" (ship_kit_upgrade.md) - but it is blocked on an unmapped system. OBSERVED. Damage: high.

Finding D5 - The kit conflates two different jobs. The rollout proves the kit on "the Basilica hero" (ship_kit_upgrade.md), a new hull, but the errata says the kit job is "dressing, paint unification and VSM format conversion of existing meshes" (reading_plan.md). The visual overhaul's first deliverable does not touch the existing fleet. The 36 existing hulls - the ones the player actually sees - are not in the kit's proof set. OBSERVED. Damage: high.

Finding D6 - A final approved asset breaks a standing rule. The battle tableau is listed as final in the manifest ("12 hero ship concepts plus the battle tableau"), but the art direction says "the defender was drawn as a wet navy battleship" and "is a stand in only" (art_direction_rey.md), violating "Space ships, never naval ships." A final image is a rule-breaker. OBSERVED. Damage: medium-high.

Finding D7 - The specs still say "both tiers" after PC-only, but only one tier exists. The beauty corner spec says "Cut order (both tiers, from the research memo)" (beauty_corner_spec.md) after stating "There is no phone tier" (beauty_corner_spec.md). The QA pack says "Per effect (every effect family, both tiers)" (visual_qa_pack.md) after stating "no phone frame" (visual_qa_pack.md). The specs are internally inconsistent on tiers. OBSERVED. Damage: medium.

Finding D8 - The Rogue Trader feel benchmark is visual-only in the pack. The benchmark promises "torpedoes with travel time that herd movement" and "boarding as a real verb" (conversation_context.md). The art direction includes torpedo flight and boarding flash in the effects language, but the beauty corner spec says "the corner proves the visual... rather than the game rule" (beauty_corner_spec.md). The battle rules that would make the feel are not in the pack. OBSERVED. Damage: medium.

Finding D9 - The 40% luminance cap does not name its reference facet. "No background pixel inside the board area may exceed 40% of the luminance of an unlit hull facet" (art_direction_rey.md). The Voidsworn hull is dark (#4a4440); the Hegemony hull is bright (#c4ccd5). The cap varies by a factor of several depending on which faction's facet is the reference. The measurement procedure says "render one unlit hull facet as a reference swatch" (beauty_corner_spec.md) but does not say which hull. OBSERVED. Damage: medium.

Finding D10 - The acceptance tests use an unspecified "viewer." "Any two hulls a viewer cannot tell apart, or any hull a viewer assigns to the wrong faction, sends the manifest back" (ship_kit_upgrade.md). No sample size, no pass rate, no viewer profile. The test is a judgment call dressed as a gate. OBSERVED. Damage: medium.

Designer verdict: GO WITH CONDITIONS. The systems are mostly coherent, but the battle-size tension, gold law, and Chorus admiral contradictions are load-bearing. Next step: Resolve the battle-size target (20 ships with per-activation density, or fewer heavier ships) and repair the gold law before any hull or portrait is gated.

### 3. Gamer

Would this be fun and readable in play? Is faction identity readable at battle zoom? Do the effects languages, damage states and shield languages survive a real battle, or only in hero shots?

Finding G1 - Shield identity is carried by shape alone, and shape may not read at battle zoom. The art direction says "the faction expressed in the ripple's shape only" (art_direction_rey.md), and the same document admits "glow is the first thing lost at small size" (art_direction_rey.md). At 20-ship battle zoom, a brief ripple on a hull may not convey faction shape. The QA pack flags this as a known tension: "The ripple shape check must therefore be done at battle zoom" (visual_qa_pack.md) - but no evidence is presented that it passes. OBSERVED. Damage: critical.

Finding G2 - The gold signal is corrupted. The player is meant to learn "gold means Command." But Chorus trim is dull gold, Ithar trim is pale gold, and epic rarity is gold-adjacent. The art direction itself says "Gold currently means five things; after this it means one" (art_direction_rey.md), but the document then fails to make it one. The player's learned signal is unreliable. OBSERVED. Damage: critical.

Finding G3 - 20 ships with decision weight is a contradiction in feel. Rogue Trader's feel comes from "one to three player capital ships per battle, so every activation carries weight" (conversation_context.md). Twenty ships means many light activations. The ruling keeps 20 ships; the design trade says take decision weight over fleet size. The player gets neither the Rogue Trader weight nor the Sins fleet spectacle - just a larger version of the current game. OBSERVED. Damage: high.

Finding G4 - Effects are proven in isolation, not in a real battle. The beauty corner spec says "Each effect is proven separately, in isolation, before any combined shot" (beauty_corner_spec.md), and the combined test is "a frame with at least three effect families active at once" (visual_qa_pack.md). One frame is not a 20-ship brawl. Effects that pass in isolation may collapse under real overdraw, targeting chaos and bloom pile-up. OBSERVED. Damage: high.

Finding G5 - The "faction at a glance" test is on a hero shot, not at battle zoom. The QA pack requires "a viewer who has never seen the hull names the faction in under three seconds" on the "lit hero shot" (visual_qa_pack.md). The hero shot is a three-quarter beauty shot. The player fights at fleet view. The test does not match the play distance. OBSERVED. Damage: medium-high.

Finding G6 - Chorus admirals as busts of formations may not read as characters. The portrait template is "three-quarter bust" (art_direction_rey.md), but the Matriarch is "a faceless column of membrane organ pipes" and Razormaw is "a blade formation" (art_direction_rey.md). A bust of a formation is a representational contradiction. The player may not read these as admirals. OBSERVED. Damage: medium.

Finding G7 - Deathless ships have faces despite being machine intelligences. The ruling says "sensor light instead of faces" (conversation_context.md), but the Deathless hull grammar includes "prow plate like a blank face" (art_direction_rey.md). At battle zoom, the player may read the Deathless as organic, muddling the robot identity. OBSERVED. Damage: medium.

Finding G8 - The 40% luminance cap may starve the backgrounds. The owner says "backgrounds carry a huge share of the game's beauty" (art_direction_rey.md), but the cap requires "no background pixel... may exceed 40%" (art_direction_rey.md). A beautiful plate that is dim enough to pass may read as muddy or empty. The readability cap and the beauty goal are in tension. OBSERVED. Damage: medium.

Finding G9 - Torpedo and boarding visuals exist without rules. The art direction includes "Torpedo flight" and "Boarding flash" as effects, but the beauty corner spec says it proves "the visual rather than the game rule" (beauty_corner_spec.md). The player sees a torpedo track and a boarding flash, but the mechanics that make them feel weighty - travel time, interception, boarding consequences - are not specified in the pack. OBSERVED. Damage: medium.

Finding G10 - The silhouette sheet is at desktop size, not battle zoom. The test renders "all six heroes... small, in a grid" at desktop size (beauty_corner_spec.md). The player fights at battle zoom, which may be a different size. A hull that passes the sheet may still fail at the actual play distance. OBSERVED. Damage: medium.

Gamer verdict: GO WITH CONDITIONS. The readability systems are mostly specified, but shield identity, gold signal, and battle size are at risk. Next step: Run a real 20-ship battle readability test at fighting zoom before accepting the shield-shape-only law or the gold law.

### 4. Sci-fi (fiction coherence)

Does the world hold together? Do faction identities, colour laws and naming stay consistent?

Finding S1 - The Chorus admiral set contradicts its own ruling. The ruling bans "instruments" and "sea creatures" for the Chorus (conversation_context.md). The Matriarch is "membrane organ pipes" (art_direction_rey.md) - an instrument. The Voice of the Deep is "an abyssal comb-jelly bell" (art_direction_rey.md) - a sea creature. The Mending Choir "stitches a broken hull" (art_direction_rey.md) - a constructed action. Razormaw is "a blade formation" (art_direction_rey.md) - a formation, not an organism. All four final portraits violate the ruling. OBSERVED. Damage: critical.

Finding S2 - "Razormaw" uses a body-part word despite the name rule. The ruling says "never an animal body part" (conversation_context.md), but "Razormaw" contains "maw." The ruling explains it as "a fleet formation whose ring reads as a maw" (conversation_context.md), but "maw" is still the word for a mouth. The name rule is violated on its own example. OBSERVED. Damage: high.

Finding S3 - The Deathless use organic metaphors despite being machine intelligences. The ruling says "Deathless are machine intelligences" and "sensor light instead of faces" (conversation_context.md). The hull grammar is "the ribcage" with "prow plate like a blank face" and "bone-white structural ribs" (art_direction_rey.md). The Deathless are described as bone machines with faces. That is a coherent aesthetic choice, but it is in tension with the "robot/AI" identity, and the document does not resolve it. OBSERVED. Damage: high.

Finding S4 - The gold law is not consistent on its own text. "Gold is rationed: patrons and Command UI only" (art_direction_rey.md) is contradicted by "Chorus trim is dull gold" and "Ithar trim is pale gold" (art_direction_rey.md). The colour law says gold means one thing; the faction palettes say it means three. The reader cannot tell which text wins. OBSERVED. Damage: high.

Finding S5 - A final approved image breaks a standing rule. The battle tableau is final, but the art direction says "the defender was drawn as a wet navy battleship" and "is a stand in only" (art_direction_rey.md), violating "Space ships, never naval ships." The manifest and the art direction disagree on whether this image is final or a stand-in. OBSERVED. Damage: medium-high.

Finding S6 - The Dead Star plate is tied to an unspecified mechanic. "This plate is the argument for the well mechanic on sight alone" (art_direction_rey.md). No "well mechanic" is defined in the terrain kinds or the battle rules. The plate is for a mechanic that may not exist. OBSERVED. Damage: medium.

Finding S7 - The Mending Choir "stitches a hull," violating "never constructed things." The ruling says "the Chorus are organisms, never constructed things" (conversation_context.md). The Mending Choir is "a mass of pulsing throat sacs and membrane chambers stitching a broken hull with fleshy sutures" (art_direction_rey.md). Stitching a hull is a constructed action. The organic material does not change the verb. OBSERVED. Damage: medium.

Finding S8 - Aelith's "seven-fingered hands" use human anatomy. The Ithar ruling says "should not look like Norwegian humans" (conversation_context.md). Seven fingers is non-human, but the hand itself is human anatomy. The Ithar are supposed to be "truly beautiful and alien/other" (conversation_context.md), and hands are the most human of appendages. OBSERVED. Damage: low-medium.

Finding S9 - Corsair "stolen Hegemony grey" may blur the Hegemony/Corsair distinction. The Corsairs are "rust and bone" with "large patches of stolen Hegemony grey" (art_direction_rey.md). The Hegemony is "the only bright hull in the game" (art_direction_rey.md). A Corsair with a large Hegemony-grey patch may read as Hegemony at distance, especially in a small ship. The document says "if a hull panel matches another faction's base colour, it is visibly bolted on, scarred and misaligned" (art_direction_rey.md) - but that is a detail that may not survive battle zoom. OBSERVED. Damage: low-medium.

Finding S10 - Voidsworn and Deathless are both near-black. Voidsworn is "warm black with fire inside" (#4a4440); Deathless is "cold black with bone on the outside" (#232a28). At silhouette distance, the warm/cold distinction may not read. The art direction says "At silhouette distance Deathless reads by its ribcage geometry" (art_direction_rey.md), but the Voidsworn is also a dark hull with vertical spires. The two dark factions may merge at distance. OBSERVED. Damage: medium.

Sci-fi verdict: NO-GO on Chorus and Deathless identity coherence. The final Chorus admirals contradict the Chorus ruling, and the Deathless organic metaphors muddle the machine identity. Next step: Regenerate the four Chorus admirals against the "organisms, never constructed things" rule, and decide whether Deathless ships may use bone/face metaphors.

### 5. QA (verification)

What can actually be checked, and what cannot? Which claims rest on unverified or secondhand sources? Which acceptance tests are measurable and which are vibes?

Finding Q1 - The reading plan errata says no battle-size target exists, but the ruling states one. "The two benchmarks pull in opposite directions and no target battle size is stated anywhere" (reading_plan.md), but the ruling says "Target battle size stays near the current scale (around 20 ships)" (conversation_context.md). The errata is stale and contradicts the ruling. A reader following the errata will look for a target that already exists. OBSERVED. Damage: critical.

Finding Q2 - The reading plan errata omits the three largest phone-first documents. The errata names only the kit spec's Pixel gate, the beauty corner and QA pack gates, and the UI review's phone findings (reading_plan.md). It does not name the research memo, the tool guides, or the graphics craft doc - the three documents that contain the most phone-first framing. The research memo alone is 11,900 words of phone-budgeted guidance. OBSERVED. Damage: critical.

Finding Q3 - The field guide's "convergence" claim overstates independence. The field guide says "Three independent research passes... converged" (mod_scene_field_guide.md), but the errata admits "Its three research passes were briefed with the same problems, so their agreement is weaker evidence than three independent discoveries would be" (reading_plan.md). The field guide still presents the convergence as independent. OBSERVED. Damage: high.

Finding Q4 - The research memo's verification claim is overstated. "No entry relies on a link that was not opened or returned by search" (visual_expansion_research.md), but the verification sweep found "3 CORRECTED" claims, including a load-bearing TAA claim and a DreamGaussian licence error (verification_sweep.md). The memo's "verified" standard is lower than the sweep's. OBSERVED. Damage: high.

Finding Q5 - The gold acceptance check is unpassable for two factions. "Gold or gold-adjacent trim on a hull fails, subject to the open gold question in section 7" (visual_qa_pack.md). Chorus trim is dull gold and Ithar trim is pale gold (art_direction_rey.md). The check cannot be applied until the design question is resolved. The QA pack flags it, but the gate is blocked. OBSERVED. Damage: high.

Finding Q6 - The acceptance tests are subjective, not measurable. "Any two hulls a viewer cannot tell apart, or any hull a viewer assigns to the wrong faction, sends the manifest back" (ship_kit_upgrade.md). No sample size, no pass rate, no viewer profile, no statistical threshold. The "faction at a glance" test is "a viewer who has never seen the hull names the faction in under three seconds" (visual_qa_pack.md) - three seconds is measurable, but "a viewer" is not. OBSERVED. Damage: high.

Finding Q7 - Reference scoring uses AI-generated concept plates as ground truth. "Run a programmatic comparison against the matching concept plate: palette and histogram match, light and contrast match" (beauty_corner_spec.md). The concept plates are themselves proposals generated by a local image model, not verified renders. Scoring against them is scoring against a target that may be wrong. The spec says "A high score on a wrong-looking ship is still a fail" (beauty_corner_spec.md), but the reference is still an AI-generated plate. OBSERVED. Damage: medium-high.

Finding Q8 - The 40% luminance cap measurement does not name its reference facet. The QA pack says "sample the brightest board-area pixel against an unlit facet in the same shot" (visual_qa_pack.md). "An unlit facet" is ambiguous: the Voidsworn hull is dark, the Hegemony hull is bright, and the cap varies by a factor of several depending on which facet is chosen. The cap is not a fixed number. OBSERVED. Damage: medium.

Finding Q9 - The Blender Lab MCP server's licence and the installed Blender version are both unverified. The Claude skills doc says "the licence line remains single-secondary-sourced" and "the PC's installed Blender version is still the open check" (verification_sweep.md; claude_skills.md). The "single biggest capability jump" depends on an unconfirmed licence and an unverified Blender version. OBSERVED. Damage: medium.

Finding Q10 - The research memo's phone-first framing is not self-corrected. The document opens "must perform on a mid-range Android phone (a Pixel is the reference device)" (visual_expansion_research.md). The PC-only ruling is in the errata, but the document itself does not flag the stale premise. A reader who opens the research memo without the errata will read 11,900 words of phone-first guidance as current. OBSERVED. Damage: medium-high.

QA verdict: GO WITH CONDITIONS. The QA system is strong (verification sweep, screenshot QA, verdict log), but the errata is incomplete, the acceptance tests are partly subjective, and the research memo's verification claim is overstated. Next step: Update the reading plan errata to name all phone-first documents and correct the "no target battle size" claim; then replace subjective acceptance tests with measurable ones (sample size, pass rate, named reference facet).

### Not checked

- I did not open the image files or verify the 40 image hashes; the binaries are not in the repo.
- I did not verify code line numbers (ships3d.js:800-801, etc.) or the repo state at HEAD 51337c2.
- I did not run the game or measure frame rates, draw calls, or texture memory.
- I did not verify external URLs or licences beyond what the verification sweep states.
- I did not check the mega sim results (still running).
- I did not check the council audit, career story, or asymmetry decision page (not in the pack).
- I did not verify the installed Blender version on Ryan's PC.
- I did not verify TripoSG or FTL Hyperspace licences (still open).
- I did not verify ESA audio terms (still open).
- I did not verify the Blender Lab MCP licence from a primary source.
- I did not check whether the Chorus admiral portraits actually exist as files; I audited the textual descriptions.
- I did not check the "well mechanic" beyond the one-line mention in the art direction.

### Top 10 findings across all lenses

1. Chorus admiral set violates the Chorus ruling (organ pipes, comb-jelly, stitching, blade formation). Sci-fi/Designer. Critical. The final four Chorus portraits break the "organisms, never constructed things" and "no instruments, no sea creatures" bans.
2. Kit work order's central premise is wrong - it assumes hull generation, but all 36 meshes exist. Engineer. Critical. The 69-session figure and the "biggest lever" argument are aimed at a job that is already done.
3. Gold law fails on its own text - Chorus trim, Ithar trim, and epic rarity are gold, but gold is patrons/Command only. Designer/Sci-fi/QA. Critical. The colour law is self-contradictory.
4. Battle-size contradiction - ruling says 20 ships, Rogue Trader benchmark says 1-3 capital ships, design trade says take decision weight. Designer/Gamer. Critical. The core feel target is unresolved.
5. Reading plan errata says "no target battle size" but the ruling states 20 ships. QA. Critical. The errata is stale and misleads the reader on a core design decision.
6. Reading plan errata omits the three largest phone-first documents (research memo, tool guides, graphics craft). QA. Critical. 29,400 words of phone-framed guidance are not flagged as superseded.
7. Loft v2 mechanism underspecified - "smooth curves," "true normals," no interpolation scheme. Engineer. High. The core geometry replacement is not implementable from the text.
8. Per-class ceilings demanded but never numerically set; no desktop ceilings. Engineer. High. The budget gate cannot fail a hull without a number.
9. Shield identity carried by ripple shape only, but glow is first lost at small size; at 20-ship battle zoom, shape may not read. Gamer/Designer. High. The shield faction language may not survive contact with a real battle.
10. Field guide's "convergence" claim overstates independence; passes were briefed with the same problems. QA. Medium-high. The field guide's central evidence claim is weaker than stated.

### What evidence would change my verdicts

- Engineer: A working loft v2 prototype with a specified interpolation scheme and a numerical desktop ceiling set from the asset inventory would upgrade the verdict from GO WITH CONDITIONS toward GO. A manifest schema with concrete landmark definitions would close the biggest implementation gap.
- Designer: A resolved battle-size decision (20 ships with specified per-activation density, or fewer heavier ships) and a repaired gold law would upgrade the verdict. A plate-to-terrain mapping would unblock the "fastest visual win."
- Gamer: A 20-ship battle readability test at fighting zoom showing shield shape and gold signals read would upgrade the verdict. A combined-effects stress test (not one frame, but a full 60-second brawl) would close the isolation gap.
- Sci-fi: Regenerated Chorus admirals that obey the ruling would upgrade the verdict from NO-GO. A decision on whether Deathless may use bone/face metaphors would resolve the machine-identity tension.
- QA: A corrected reading plan errata naming all phone-first documents and the 20-ship target would upgrade the verdict. Measurable acceptance tests with sample sizes and pass rates would replace the "a viewer" tests. A confirmed Blender 5.1 install and a primary-source MCP licence would upgrade the Claude skills recommendation.
- Overall: The pack is a strong body of work with a real verification layer, but it carries a large stale-premise debt (phone-first) and several self-contradictions (gold, battle size, Chorus admirals). The single highest-value fix is to reconcile the kit work order with the asset inventory and repair the gold law - those two changes would remove the most damage from the pack.

Settings state observed: DeepThink ON (toggle highlighted; response carried a "Thought for 161 seconds" reasoning block), Search OFF (toggle plain/unhighlighted). The audit was generated under exactly these settings - no re-run was needed. Failed steps: none. Sign-in, upload (.txt accepted directly, 473.87KB), toggles, and message send all succeeded; no phone approval was required this attempt.
