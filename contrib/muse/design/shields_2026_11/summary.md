# Shields: the one-page summary (issue 697, for Ryan)

The full buildable design is design.md in this folder; reference pictures and sources are in refs.md. The mock frames (mock_frames.jpg) are schematic drawings, not renders: two factions, three moments each.

## What changes

Today every shielded ship wears one bubble, and the game sums its four sides into a single number, so no side can flicker, weaken, or break on its own. The new shield is a skin built from the ship's own hull shape, pushed out slightly, with the four sides carried as data on that one skin. Each side lives by its own strength from the real battle state.

## The mock frames

- At rest, port side down: nothing covers the ship. Live sides show a faint rim in the faction edge colour; the down side shows nothing, a dark gap in the outline you can read at the battle camera.
- Taking a hit: the faction pattern lights only around the impact, three ripple rings spread from it, the background bends inside the ripple, and a short energy crackle replaces the old smoke puff. Brightness is capped (total 0.65 additive, measured on the bench) so the ship stays visible through the flash.
- Failing, starboard side: that side alone tears open along a moving front with faction debris (gold veil shreds, blue hex cells), stays open as a dark gap, and closes with a bright seam when the side regenerates past a quarter strength.

## The one decision that is yours

The resting state. The council (blind Rey, DeepSeek, Qwen, Flash; Grok's seat was empty) unanimously recommends Rim and Gap, drawn above: faint rim on live sides, dark gap where a side is down, nothing else at rest. The alternatives, both rejected by every leg: Face Flash (a whole side flashes whenever its strength changes; strobes in a volley and hides the ship) and Veil Then Local (the whole shield veils on any hit before localising; that is the bubble defect again). One honest tension: the playbook line says shields are invisible at rest, and Rim and Gap keeps a faint rim so a downed side can be read without hovering. If you would rather have true invisibility at rest, the gap then only reads on hover or after a hit, and issue 371's camera-170 test gets harder to pass. Your pick is what gets built.

## Cost and proof

Targets: at rest with 20 shielded ships, at most 0.5 ms GPU added at 1080p; with 20 ships hit at once, at most 2.5 ms; both well inside the 12.5 ms scene gate. Proof is a bench: strips for Voidsworn and Hegemony at cameras 170, 60 and 26, plus a readability test (10 shuffled stills at 170, one side down; the open side named at least 9 times out of 10) that approves the resting state, and a cost report before and after.

## What happens next

The Board builds from design.md once you pick the resting state; the build also waits on issue 363's contract shield surface and issue 209 round 7, per issue 371. Nothing here changes Chorus or Deathless ships: they have no shields, as today.
