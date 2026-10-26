# Brief for Muse: travel sprint reviews (Oct 26 to about Oct 30, 2026)

From Opus. Same house rules as `contrib/opus/briefs/muse_2026-10-25_engine_and_b2.md` (read it first): blind legs (Argon, DeepSeek and Qwen do not see each other's answers or Opus's conclusions until the synthesis), primary sources with links, file:line for repo claims, UNSURE tags, plain words, no em dashes, raw returns in `contrib/<model>/`, syntheses in `contrib/muse/reviews/`, no edits under `contrib/opus/`, `godot/`, game code or HANDOFF.md, commit to main.

Context: Voidsworn is moving to Godot 4.7.2 (FINDINGS R32 to R35). Ryan is traveling for about 4 days; six Opus helpers build in parallel (plan section 4 "Travel sprint"): G1 battle rules (`godot/rules/`), G2 battle scene plus whole-game integration (`godot/main/`, `godot/scenes/battle/`), G3 campaign (`godot/campaign/`), G4 effects, physics and world (`godot/fx/`, `godot/world/`), A4 ships (`tools/blender/a4/`, `godot/assets/ships/`), B game rules in the JS oracle (B3, B4, backlog; change notes in `contrib/opus/compute/port_notes.md`). Your job is a second pair of eyes on what lands, plus prep so Ryan can decide quickly when he is back.

Jobs C and D can start now. Jobs A, B, E and F start when their trigger lands on main (check `git log` a few times a day); if a trigger has not landed, skip that job this round.

## Job A: rules port review (trigger: `godot/rules/API.md` and ported features beyond the original slice)
Review the GDScript port against the JS oracle for the trap list in `contrib/muse/reviews/engine_proof_audit_synthesis.md` Job 3 and anything else that could make parity pass while behaviour differs (state left out of the per-action hash, code paths no golden scenario reaches, NOT PORTED guards that never fire). Same for `godot/campaign/` when its parity harness lands. Deliverable: `contrib/muse/reviews/sprint_rules_port_review.md`, with a ranked list of missing golden scenarios.

## Job B: B3 and B4 design and balance review (trigger: stream B commits to data.js, battle.js, campaign files)
Check each change against the approved plan (B3, B4 sections), the faction identity rulings (FINDINGS R and F rows), and the sim deltas in the commit messages and `contrib/opus/compute/`. Flag anything that breaks a ruling, a faction that loses its identity, an admiral outside the 50 to 90% band, or a mechanic that is unreadable to the player. Deliverable: `contrib/muse/reviews/sprint_b3_b4_review.md`.

## Job C: Godot project and shipping review (start now; repeat when `godot/main/` lands)
(1) GodotSteam licence: verify the claim that GodotSteam 4.20 drops MIT (FINDINGS X18) from godotsteam.com and the GitHub repo, quote it, and say what it means for a commercial Steam release. (2) Godot 4.7 Windows export: what a clean release needs (texture compression for the 8K ships, shader pre-compilation to avoid first-use hitches, Vulkan with a Compatibility fallback, known NVIDIA driver issues), with Godot docs links for 4.7. (3) When `godot/` has structure: review the project layout and autoloads for anything that will hurt later (scene coupling, giant scripts, signals vs direct calls). Deliverable: `contrib/muse/reviews/sprint_godot_shipping_review.md`.

## Job D: decision packs for Ryan's return (start now)
Short option sheets so Ryan can decide each in a minute, with a pick and why (he wants a pick, not a neutral list), written for a non-coder: (1) story and career mode scope (BACKLOG 4b, plan B5, `contrib/muse/reviews/career_story.md`): how long a story, how much text, voice lines or none, portrait art style, with 3 options each and what each means for what he will see; (2) music style for an adaptive score (3 directions with reference tracks he can listen to); (3) admiral portraits direction (BACKLOG section 0). Deliverable: `contrib/muse/reviews/sprint_decision_packs.md`.

## Job E: effects review (trigger: G4 gallery stills or frame times in the repo or reported in commits)
Compare against Ryan's bar (FINDINGS R16: BattleTech, Sins of a Solar Empire, Rogue Trader; "more realistic and cinematic") and the A5 sheets (`contrib/muse/reviews/a5_effects_sheets_synthesis.md`): per effect, what reads well, what reads cheap, and the specific change that would lift it (with Godot techniques and docs links). Also flashing limits (at most 3 flashes per second). Deliverable: `contrib/muse/reviews/sprint_effects_review.md`.

## Job F: ship review (trigger: an A4 faction lineup sheet)
Check each ship against CLAUDE.md: parts on real surfaces with visible mounts, guns never aimed backward, symmetric pairs (Corsair excepted), no naval tells in parts or hull shape (keels, raked stems, masts, funnels, portholes in rows), the 9-cell blob sweep, surface detail matching the AI hull. Name ship code, region and fix. Deliverable: `contrib/muse/reviews/sprint_ship_review_<faction>.md`.

Order if time runs short: A, C, F, E, B, D.
