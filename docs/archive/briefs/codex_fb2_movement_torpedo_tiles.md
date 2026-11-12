ARCHIVED Nov 11 2026: replaced by docs/RULEBOOK.md (the damage read is RULEBOOK 6.8; movement is section 7) and contrib/opus/briefs/movement_spec.md. A finished job. Kept for history; do not follow.

# Task: playtest fixes, batch 2 (movement, torpedoes, move tiles)

Ryan's rulings (Nov 2, FINDINGS R76). Photos from his playtest are in docs/shots/playtest/2026-11-02/ (phone photos of a monitor; ignore moire). House rules: docs/archive/briefs/feel_pass_2026-11-01.md. Presentation only: no rules or number changes, and the rules parity must still PASS.

1. Movement: glide on curves. Ryan: "Movement is too thruster based. It causes the ships to move jerkily side to side. It doesn't feel like space travel... It doesn't feel smooth, cohesive or cinematic. The thrusters are more visible than the engine." Rebuild the cinematic move animation in the battle scene (find it from board_look.gd and the F2 movement work):
   - The ship follows one smooth curve through its path (a spline through the hex centres, eased at both ends), always facing along its direction of travel, and banks gently into turns (a few degrees of roll, eased).
   - No side-to-side translation: sideslips and back-offs (rules moves) are shown as a gentle curved drift with the hull still mostly pointed along the curve, never a sideways shuffle.
   - The final facing is reached smoothly over the last part of the curve, not snapped.
   - The main engine glow and trail do the work and scale with speed; manoeuvring thrusters are small, brief puffs only while turning, dimmer than the main engine.
   - Keep the current total move time per hex (Ryan set the pace in F2, R67) and the enemy at the same pace.
   Reference: Homeworld and Battlefleet Gothic Armada capital ship movement.

2. Torpedoes: clearer, same rules. Ryan: "I constantly couldn't tell if they were going to hit, how or what." The rules stay as they are (resolve on fire).
   - Before firing, the target tooltip and the fire card show the torpedo hit chance and expected damage the same way guns do, plus one plain line on why (for example "torpedoes are hard to dodge for slow ships, easy for fast ones" if that is what evMult does; read battle.js to say it truthfully).
   - When fired, a visible torpedo flies the lane to the target (a bright head and trail, a second or so), then a clear HIT with the damage number or a MISS where it passes the target.
   - The aim lane must read shooter to target (batch 1 fixed the direction; keep it).

3. Move tiles in cinematic look: soft outlines. Replace the bright blue fill in the cinematic board look with thin glowing hex edges and a very faint fill; the hex under the mouse brightens; the planned path shows as a soft line. Other board looks unchanged. Space must stay visible through the tiles (ryan_05, ryan_13).

4. Capture for review (you have the GPU here): with the full build's ships if you can reach them, otherwise skip. Report file names.

Tests: parse-check changed .gd; rules parity PASS; the UI check (--ui-shots) still passes at 1920x1080 and 3840x2160. Final message: per item what changed (file:line), checks, anything left. Plain ASCII, never the em dash; no commit (the board runner commits and pushes).
