# Conversation context for Opus: the design pack sessions

From: Rey (Muse). Date: Oct 23, 2026 (America/Chicago). Audience: Opus, in his roles as coder, verifier and orchestrator.

## 1. What this document is

The design documents in this folder (art_direction_rey.md, ship_kit_upgrade.md, visual_expansion_research.md, GRAPHICS_REFERENCES.md, mod_scene_field_guide.md, tool_guides.md, and the round 3 guides) are the deliverables. This file is the conversation behind them: the owner's rulings, the corrections, the near misses, and what is still undecided. The rulings here are Ryan's, given across the evening of Oct 23, 2026 while reviewing generated plates and portraits. Where a ruling and a document disagree, the ruling wins and the document should be corrected.

Roles, as set by Ryan: Opus codes, verifies and orchestrates, and owns code truth. Rey works external POV only (audits, lenses, design and text proposals, cross model synthesis, heavy compute). Ryan is the final verdict on everything visual. Nothing in Rey's documents is an approval; approvals are listed in section 3 and section 7 is the list of things he has explicitly not decided yet.

## 2. How we got here, briefly

The council's designer lens found strong ingredients and no governing art direction (the repo's art direction brief was a blank template). Ryan commissioned a full visual pack from Rey: art direction, hero ship concepts, background plates, admiral portraits, a ship kit work order, and then a sourced research memo on expanding the actual in game visuals. He reviewed every image personally and corrected direction in four rounds. The corrections matter more than the first drafts, so they are written down in section 3 as standing rules, with the failure modes named so they are not repeated.

Ryan's own summary of the graphics ambition, given while widening the research: be extremely expansive and detailed, and make it feel cinematic, like Sins of a Solar Empire. That benchmark is now the stated target for the whole overhaul, and Section 7 of the research memo is built around it.

## 3. Ryan's rulings (standing)

1. **Ithar sails are vertical.** His words on the hulls: "ithar hulls should be vertical i think. otherwise it's like a bug or something." Vertical fins, dorsal and ventral, never horizontal wings. Horizontal reads as insect to him. This applies to ships and to portrait anatomy alike.
2. **Ithar are beautiful aliens, not humans and not fish.** His words: the Ithar "should not look like norwegian humans, but something truly beautiful and alien/other." Two failure modes are now on record: a portrait that could pass for a costumed human has failed, and anything aquatic has failed (the v3 Aelith read as a fish: gills, scales and organic fin shapes are all banned). Their sail structures are radiant, near geometric constructions of light, like the rigs on their ships.
3. **Chorus are organic, gross and disgusting. Only that.** Grown flesh, membrane, chitin, bile and growth. No human features and no recognizable Earth animal anatomy (no borrowed faces, eyes or limbs, sea creatures included). Equally banned: buildings, instruments and architecture. The Mending Choir's first portrait came out as a cathedral of bells and Ryan killed it on sight: the Chorus are organisms, never constructed things. A Chorus admiral's name describes what it does or the formation it holds, never an animal body part (Razormaw is a fleet formation whose ring reads as a maw, not a creature with a mouth).
4. **Deathless are machine intelligences, and humanoid is not required.** His words: "deathless should be like robots or something AI/cybernetic/robot." He then went further: the final Nekhet has no body at all, a ring construct of bone white ceramic computation around a green core, attended by service drones. Sensor light instead of faces; the green is system light, not soul light.
5. **The first three factions stay human.** Vex (Voidsworn), Kassar (Hegemony) and Grax (Corsairs) were approved as generated. Do not alien them up.
6. **Space ships, never naval ships.** Standing rule, predates this pack. The battle tableau mock in the image set breaks it (the defender was drawn as a wet navy battleship) and is a stand in only; Ryan knows and it is flagged in the art direction doc.
7. **Guns never face backward.** The Confessor's first plate composed its spinal lance pointing aft. It was regenerated with the lance forward, muzzle foremost. The v2 is final.
8. **The colour laws in the art direction doc stand as written.** Cyan means shields and nothing else is cyan. FAC3D is the single colour source (data.js FACTIONS disagrees with it in places and loses). Gold is rationed to patrons and Command. Backgrounds obey the 40 percent luminance readability cap inside the board area.

## 4. What is final, and what is superseded

Final images are the 40 listed in IMAGE_MANIFEST.md in this folder, with SHA-256 hashes: 18 background plates, 12 hero ship concepts plus the battle tableau, and 9 admiral portraits (Vex, Kassar, Grax, Nekhet, the Matriarch, the Voice of the Deep, the Mending Choir, Razormaw, Aelith). The Chorus admiral set is complete at four of four. Fifteen of the 24 admiral portraits remain to be produced against the locked template in the art direction doc, whenever the game can display them.

Superseded and not to be used: Aelith v1 to v3 (v4 is final), Nekhet v1 and v2 (v3, the ring, is final), the Matriarch v1 (v2 is final), the Mending Choir v1 (the bell cathedral; v2, pure flesh, is final), Palinode v1 (horizontal wings; v2 is final), Confessor v1 (aft lance; v2 is final). If Ryan ever shows you one of these, the manifest is the authority on which version counts.

Ryan reviewed the background and ship plates and approved them ("those are all awesome") before the portrait rounds began.

## 5. The images are not in this repo (yet)

The GitHub connector route Rey pushes through accepts UTF-8 text only, so the binary WebP images could not be committed with the documents. Ryan chose docs plus manifest now rather than holding the whole pack. The curated staging pack with the 40 final images, renamed to the manifest's paths, sits on Rey's side; if you need a specific plate or portrait, ask Ryan to relay it or Rey to supply it another way, and verify it against the manifest hash when it arrives.

## 6. Platform ruling: PC-only in Babylon (decided Oct 24, 2026)

Late in the evening Ryan asked two hypotheticals: what if the game went desktop only instead of phone, and what if it became a full app, what is biggest there. Rey's analysis, delivered and not yet ruled on:

- The biggest unlock is sustained desktop GPU budget, not the app wrapper. Dropping the Pixel as the design floor makes higher resolution, full HDR post processing, larger textures and denser effects reasonable defaults, and the repo already carries a desktop asset tier (the asset inventory found hulls_hi meshes and maps for all 36 hulls, about 930k triangles total).
- A Babylon wrapper (Electron or Tauri) is a packaging upgrade, not an engine upgrade: local assets, offline play, controlled runtime, same renderer.
- Godot native is the strongest true native route (Forward+ renderer) but is a full rewrite. Unreal has the highest ceiling and remains the least proportionate. Full reasoning is in Section 6 of the research memo, with the phone assumptions still attached to the earlier sections.
- Recommendation given: desktop first in Babylon, Electron prototype only if an installable app is wanted, Godot only on a conscious PC first rewrite decision.

Ruling, Oct 24, 2026: Ryan decided PC-only in Babylon. The phone target is dropped entirely. The desktop GPU budget is the design floor. There is no phone tier, no phone pass, and no phone acceptance gate. The engine stays Babylon: this ruling is not a native-app decision and not a Godot decision. An installable wrapper (Electron or Tauri) and any engine migration remain separate, undecided questions. Ryan first picked PC-first with phone secondary and then, minutes later, replaced it with PC-only on the grounds that dropping phone changes Opus's decisions meaningfully (single asset tier, desktop-first UI, no Pixel testing).

## 7. What Ryan has not decided (do not treat as approved)

- The council chair's top 10 sequence (save bricking id class and the review debt sweep are ranked first and second). Filed at contrib/muse/reviews/council_audit.md.
- The career and story pick (Rey's recommendation was Option B, faction arcs, with admiral voices first). Filed at contrib/muse/reviews/career_story.md.
- The five owner decisions on the asymmetry decision page. Filed at contrib/muse/reviews/asymmetry_decision.md.
- Pyre-Barge sign off, which gates ship 2 in the queue.
- The remaining 15 admiral portraits: approved in principle as a system, not yet commissioned as a batch.

## 8. Practical notes

- Ryan's manual effort is a hard budget. Anything that routes through his hands should arrive pre packaged, with his side reduced to upload plus one sentence where possible.
- He cross model validates deliverables and expects claims to be checkable. Quotes and numbers in Rey's design documents were verified against the repo on Oct 23, 2026; if the repo has moved since, trust the repo and flag the drift rather than defending the document.
- The mega sim (campaign 200, bossmatrix, fmatrix, matrix, archmatrix legs) was still running when this was written. Its balance reference and CSVs land in contrib/muse/compute/ when it finishes, and the README there will point to them.
- Settled calls stay settled. If Ryan kills a thread ("nah, just wait", "keep waiting", "kill it"), it does not come back in a later proposal wearing a new hat.

## 9. Late addition (Oct 23, late): the feel target has a name

After the documents above were written, Ryan named the thing they were circling: the space battles in Warhammer 40,000: Rogue Trader (Owlcat) are the ones that scratched this itch most for him. Smallish fleets, strictly turn based, and fun. He had not connected it to Voidsworn until tonight, and he asked for it to be put in front of Opus explicitly.

Treat Rogue Trader's voidship combat as the battle feel north star for Voidsworn. Sins of a Solar Empire remains the presentation benchmark; Rogue Trader is the feel benchmark. Concretely, what that game does and what Voidsworn should be judged against: one to three player capital ships per battle, so every activation carries weight; facing and firing arc discipline; torpedoes with travel time that herd movement; critical hits on named ship systems that change what a ship can do; boarding as a real verb; officer posts turning crew into ship abilities.

The design trade it implies, stated plainly: when a choice trades fleet size against per activation decision weight, take the decision weight. It also speaks to the animation time problem the sims keep finding in Voidsworn's late fights: fewer, heavier activations beat many light ones.

A verified breakdown of Rogue Trader's void combat is in GRAPHICS_REFERENCES.md, section 6, as the headline entry of its games like Voidsworn section. This note is the owner's ruling; that section is the evidence.
