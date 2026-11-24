# Playbook: sound (first cut: the target and the first two jobs)

Issue 405. Written by the Board (Fable 5.2), Nov 11 2026, from Ryan's scope answers. The steps and checks get filled in when
the first sounds are remade.

## 1. Target

- Ryan, Nov 10: "The sounds that I've heard from the game so far are bad".
- What is bad, in his picks: "Thin and weak", "Cheesy or arcade-like", "Harsh or annoying".
- What a battle should sound like: "Clean and tactical": restrained and clear, like Sins of a Solar Empire or EVE Online; a
  sound you can play to for hours.
- In the redo: weapons, hits and deaths; buttons and menus; ambience; music. Everything.

What that means for every sound:
- **Weight without harshness.** Body in the low and low-mid range, a soft top. Nothing shrill. Big events are deep, not loud.
- **Weapons dry, big moments with weight (reworded Nov 11, R187, R193).** Weapon shots stay short and dry, with little echo:
  space is quiet and the fleet is heard as if through your own ship's hull. Deaths, capital hits and shield breaks are not
  dry: they get tails, the sub-bass, a bed for the length of the picture, the mix ducking under the core flash, and a beat of
  near-silence after a capital dies; the lance and the torpedo get a short charge. The old line "Short and dry. Short tails,
  little echo" was built as no tails at all, so a ten second death had a one second sound (cinematic audit item 9,
  contrib/opus/reviews/cinematic_audit_top10.md). Ryan asked for the audit to cover "the sounds" too and said "Go, in my
  order" on its list (R187, R193 (4)).
- **The gun chooses the sound of its hit (audit item 8, built in issue 506, PR 514).** One gun sound per shot at its own fire
  time; the hit cue chosen by the weapon and by what it struck (contrib/opus/reviews/sound_routing_report.md).
- **No arcade.** No zaps, pews, rising whooshes or stock explosions. Mechanical and electrical sources: relays, capacitors,
  breech blocks, hull groans, pressure.
- **A ladder, like the pictures.** Las, macro, lance, torpedo, death: each plainly heavier than the last, matching
  docs/playbooks/deaths_and_hits.md beat for beat (the tell, the break, the wreck).
- **Variation.** Four takes is the starting count for anything heard often, never the same one twice in a row (RULEBOOK 8.4).
- **A quiet bed.** Ambience and music sit low under the fight; menus click softly; nothing competes with a torpedo.
- **Faction voices.** Each faction's guns and engines share a family of sound (iron and fire for the Crusade, clean
  electrical hum for the Hegemony, rattling junk for the Hullbreakers, glass and tone for the Glasswrights, a low held note
  for Eclipse, wet and breathing for the Chorus).
- Free tools and free sources only.
- **Faction deaths (issue 1238).** Every death cue carries the dying ship's faction. A faction variant in
  godot/audio/cues.json marked `"replace": true` is that faction's whole sound, with no steel under it (a variant without
  it adds its layers to the base). Chorus deaths use wet and breath clips (puff, torpSac, gunGlob, grappleWet, hitWet);
  Glasswright deaths use glass and tone (shieldShatter, crackGlass, hitGlass, choirBell, starShimmer); the heavy-hit tail
  under a Chorus or Glasswright hit does the same. Built from clips already in the game; Ryan's ear decides whether they
  stay. Check: godot/audio/test/faction_death_check.gd (prints the cue timing trace) and audio_check.gd.

## 2. Where it stands (Nov 11 evening)

- Done: the sourcing and palette study (contrib/muse/design/sound_sources_2026_11/synthesis.md); sound routing (issue 506);
  sound weight (tails, sub-bass, the death bed, ducking, the lance and torpedo charge; issue 771) with its listening page at
  docs/shots/sound_weight/LISTEN.md.
- Next, in Ryan's order (R193 (4)): the sound redo.
- Wiring rules (issue 1448, Neon player audit Nov 21; no new sounds): a screen gets its ui cues from one hook,
  `OrdersKit.watch_sound(root)` in godot/ui/theme/orders_kit.gd (campaign_ui.gd and career_screen.gd call it), never its own
  per-button code; a confirm that takes a reward, relic, perk or bought hull plays `ui_reward` instead of `ui_confirm`
  (campaign_ui.gd REWARD_ACTS); `ui_boss` plays when a boss or Nemesis fight is entered (campaign_host.gd); a battle ends on
  one sound, the music fanfare, with the synth sting only when music cannot play (battle.gd `_end_sound`); the battle music
  hears hits this round (`shots`) and counts enemies within 3 true hex steps as close. Check: audio_check.gd, the 1448 lines.

- Gate 2 recorded sounds (issue 1752, Nov 24 2026): the 65 mastered keepers (`contrib/opus/sound/keepers_gate2.json`,
  `contrib/opus/tools/sound/master_keepers.py`) are wired by `contrib/opus/tools/sound/wire_gate2.py` from
  `contrib/opus/sound/wiring_gate2.json`. A weapon's own sound is a `"faction.weapon_id"` variant on the cue the battle
  plays for it (bare `weapon_id` for strike craft); `sfx.gd` `weapon_variant` picks it, and a weapon without one keeps the
  base cue. Levels match today's mix: a group's energy mean for guns and hits, the cue's own level for charges, shields,
  deaths and menus. Re-running `godot/audio/build/render_synth.js` rebuilds the base layers of browser cues, so run
  `wire_gate2.py` again after it. Sounds still waiting on a new game hook are listed under `next_hooks` in the wiring file.
  Check: audio_check.gd (every wired variant sits on the cue its weapon really plays).

## 2a. The first two jobs (as first planned)

1. Muse: a sourcing and palette study. Where each family of sound can come from at no cost and with a licence that allows
   use in a game (named libraries and synthesis recipes, each with its licence), and a one-page palette per faction.
2. Board: a listening page for Ryan on his PC: for ten key sounds (the five ladder steps, a cruiser death, a button, the jump,
   a map bed, a battle bed), the present sound beside two candidates. He picks by ear; that pick sets the standard the rest
   is made to.

## 3. Seat

Muse researches and sources. Codex or DeepSeek wires sounds into the game and builds the listening page. The Board writes the
ladder and judges with Ryan's picks. Ryan's ear decides.
