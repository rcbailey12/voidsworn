'use strict';
// Standing checks for the consolidated UI specification (contrib/opus/briefs/ui_spec.md, issue #231, FINDINGS R136).
// Node 18+, no dependencies. Run by run_all_checks.js (every *_tests.js in this folder).
// These are code-structure checks, not numeric gates: they keep the one scale law one law, keep the battle focus ring
// visible, and keep text at or above the stated floor. The values themselves are provisional until the U-A captures.
const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '../../..');
const diff = require('./ui_constants_diff.js');
const read = f => fs.readFileSync(path.join(ROOT, f), 'utf8');
let pass = 0, fail = 0;
function check(ok, what) { if (ok) pass++; else { fail++; console.log('FAIL ' + what); } }

const LAW = 'godot/ui/ui_scale.gd';
const law = read(LAW);
const K_MAX = +(/const K_MAX := ([\d.]+)/.exec(law) || [])[1];
const K_MIN = +(/const K_MIN := ([\d.]+)/.exec(law) || [])[1];
const MIN_TEXT = +(/const MIN_TEXT := (\d+)/.exec(law) || [])[1];
check(/const DESIGN_HEIGHT := 1080\.0/.test(law), 'ui_scale.gd keeps the 1080 design height');
check(K_MIN === 0.6 && K_MAX === 2.2, `ui_scale.gd floor and ceiling are the spec's provisional 0.6 and 2.2 (got ${K_MIN}, ${K_MAX}); change ui_spec.md 4.1 with them`);
check(MIN_TEXT === 12, `ui_scale.gd text floor is the spec's 12 (got ${MIN_TEXT}); change ui_spec.md 4.3 with it`);

// 1. one law: no screen keeps its own height / 1080 clamp
const files = diff.godotFiles();
for (const f of files) {
  if (f === LAW) continue;
  const t = read(f);
  const own = /(?:size\.y|vs\.y|\.y)\s*\/\s*1080(?:\.0)?/.test(t) && /clamp/.test(t);
  check(!own, `${f} has its own window-height scale law; use ui_scale.gd k_for() (ui_spec.md 4.1)`);
}
// 2. every screen that sizes text reads the shared law
const USERS = ['godot/ui/battle/hud.gd', 'godot/main/title.gd', 'godot/ui/campaign/campaign_ui.gd', 'godot/main/campaign_fallback_ui.gd',
  'godot/ui/career/career_screen.gd', 'godot/ui/career/rename_dialog.gd', 'godot/main/load_screen.gd'];
for (const f of USERS) check(/ui\/ui_scale\.gd/.test(read(f)) && /k_for\(/.test(read(f)), `${f} reads the shared scale law (ui_scale.gd k_for)`);
check(!/clamp\(ui\.k/.test(read('godot/ui/campaign/map3d.gd')), 'map3d.gd labels follow ui.k without a second clamp');
check(/set_player\(settings\.get\("ui_scale", 1\.0\)\)/.test(read('godot/main/main.gd')), 'main.gd hands the player UI scale to ui_scale.gd, a missing key reading 1.0 (ui_spec.md 4.4)');

// 3. AC5: the battle theme draws a visible focus ring, and the menu and end card take keyboard focus
const hud = read('godot/ui/battle/hud.gd');
check(!/set_stylebox\("focus", "Button", StyleBoxEmpty/.test(hud), 'battle theme focus stylebox is not empty (AC5, ui_spec.md 6.2)');
// #314 check condition 4: the ring has one source, glass_shell.gd focus_ring, installed by make_theme; hud.gd takes the
// theme and does not set a focus stylebox of its own
const gsh = read('godot/ui/theme/glass_shell.gd');
const ringFn = (/static func focus_ring\([^)]*\)[^\n]*\n([\s\S]*?)\n\n/.exec(gsh) || [])[1] || '';
check(/f\.draw_center = false/.test(ringFn) && /f\.border_color = BONE/.test(ringFn) && /set_border_width_all\(maxi\(2,/.test(ringFn), 'battle theme focus ring is the title screen ring: no fill, bone border, at least 2 px (glass_shell.gd focus_ring)');
check(/th\.set_stylebox\("focus", "Button", focus_ring\(k\)\)/.test(gsh) && /GS\.make_theme\(/.test(hud), 'the battle theme takes its focus ring from glass_shell.gd make_theme');
check(!/set_stylebox\("focus"/.test(hud), 'hud.gd sets no focus stylebox of its own (one source for the ring)');
check(/func _button\([^)]*keys := false\)/.test(hud) && /Control\.FOCUS_ALL if keys else Control\.FOCUS_NONE/.test(hud), 'battle buttons take focus only when asked (keys)');
check(/_button\(str\(it\[0\]\), str\(it\[1\]\), it\[2\] if it\.size\(\) > 2 else null, it == items\[0\], true\)/.test(hud), 'battle menu buttons take keyboard focus');
check(/_button\("Continue", "continue", null, true, true\)/.test(hud) && /_button\("Fight again", "restart", null, true, true\)/.test(hud), 'end card buttons take keyboard focus');
const t = read('godot/main/title.gd');
check(/sf\.draw_center = false/.test(t) && /sf\.border_color = HUD\.BONE/.test(t), 'title screen focus ring unchanged (the source of the battle ring)');

// 4. TY6: no port text under the floor (a one-glyph ornament, like the side panel's gilt diamond, is not text)
const gs = diff.godotSizes(files);
const low = gs.filter(r => r.v < MIN_TEXT && !(r.text && /^"[^\w\s]"$/.test(r.text)));
for (const r of low) check(false, `text size ${r.v} under the ${MIN_TEXT} floor at ${r.at} (ui_spec.md 4.3)`);
// #282 (N1): a real assertion that the scan read rows, so a regex that stops matching fails instead of passing silently
check(gs.length >= 300, `text floor scan read ${gs.length} font size literals (expected at least 300; check godotSizes in ui_constants_diff.js)`);
check(gs.some(r => r.at.startsWith('godot/ui/')) && gs.some(r => r.at.startsWith('godot/main/')), 'text floor scan covers font sizes in both godot/ui and godot/main');
check(gs.some(r => r.how === 'theme default'), 'text floor scan reads the theme default font size form (default_font_size = s(15), N1)');

// 5. HD9: one hull-low line in the port
const lows = [...hud.matchAll(/HULL_LOW if \w+ < ([\d.]+)/g), ...read('godot/ui/campaign/campaign_ui.gd').matchAll(/(?:BLOOD|HULL_LOW) if f < ([\d.]+)/g)].map(m => +m[1]);
check(lows.length >= 4 && lows.every(v => v === 0.35), `every hull-low line is 0.35: battle roster, nameplate and the campaign bars (HD9; found ${lows.join(', ')})`);

// 7. issue #344 (UI rollout 1): the campaign map, its side panel and the between-battle pages are in Lime Tactical
{
  const cui = read('godot/ui/campaign/campaign_ui.gd'), m3 = read('godot/ui/campaign/map3d.gd'), mi = read('godot/ui/campaign/map_intel.gd');
  const cb = read('godot/ui/campaign/choice_button.gd'), gsh2 = read('godot/ui/theme/glass_shell.gd'), view = read('godot/campaign/campaign_view.gd');
  check(/const GS = preload\("res:\/\/ui\/theme\/glass_shell\.gd"\)/.test(cui) && /const GILT := GS\.GILT/.test(cui), 'campaign_ui.gd takes its palette from glass_shell.gd (ui_style.md 8)');
  check(!/Color\("#[0-9a-fA-F]{6}"\)/.test(cui), 'campaign_ui.gd writes no colour hex of its own (new colours go into glass_shell.gd first)');
  check(!/Color\("#[0-9a-fA-F]{6}"\)/.test(mi), 'map_intel.gd band and route colours come from glass_shell.gd');
  check(/GS\.make_theme\(k, font, font_semi, 17\)/.test(cui) && !/set_stylebox\("focus"/.test(cui), 'campaign theme is GS.make_theme at base 17 and sets no focus stylebox of its own (one ring, ui_spec.md 6)');
  check(!/Barlow|Michroma|Oxanium/.test(cui), 'campaign screens use the glass_shell.gd faces, not the old Barlow, Michroma and Oxanium');
  check(/font = GS\.body\(\)/.test(cui) && /font_goth = GS\.display\(k\)/.test(cui) && /font_caps = GS\.caps\(k\)/.test(cui), 'campaign fonts come from glass_shell.gd and the tracked faces follow k');
  check(!/modulate\.a = 0\.5/.test(cb) && /tagl\("Locked", BONE3\)/.test(cui), 'a disabled choice dims its words and says LOCKED, not a 50% fade (MN12, ui_style.md 3)');
  check(/draw_style_box\(ring/.test(cb) && /b\.ring = GS\.focus_ring\(k\)/.test(cui), 'campaign choices draw the shared focus ring when focused');
  const mapSizes = [...m3.matchAll(/int\((\d+(?:\.\d+)?) \* s\)/g)].map(m => +m[1]);
  check(mapSizes.length >= 8 && mapSizes.every(v => v >= MIN_TEXT), `map labels are at or above the text floor (found ${mapSizes.join(', ')})`);
  check(/const DANGER_EASY := FRIEND/.test(gsh2) && /GS\.DANGER_EASY/.test(mi) && !/7ddc6a/.test(mi), 'the Easy danger band left the lime-like green (ui_spec.md 5.1 collision note)');
  check(/_chip\(dg\["band"\]\.to_upper\(\)/.test(m3) && /tagl\(str\(dg\["band"\]\)/.test(cui), 'every danger band prints its word beside its colour (ui_spec.md 5.2)');
  check(/Color\(ui\.GILT, 1\.0\) if nxt/.test(m3) && /rc = Color\(ui\.GILT, 0\.95\)/.test(m3), 'the lanes and rings of your next jumps are the lime line (ui_style.md 8)');
  check(/func _strip_text\(/.test(m3) && /GS\.strip\(ui\.k, accent/.test(m3), 'map stop names sit on strips with the slanted end');
  check(/func _side\(\)[\s\S]*?shell_panel\(12\)/.test(cui) && /func shell_panel[\s\S]*?GS\.frame_marks/.test(cui), 'the side panel is one glass_shell panel with its marks');
  check(/func _fight_card\(/.test(cui) && /View\.fight_cards\(C\)/.test(cui) && /"Sector flagship"/.test(view), 'fight cards come from the view and include the sector flagship');
  check((cui.match(/\bfin\(/g) || []).length >= 14 && !/abtn\([^\n]*, true, false, acts\)/.test(cui), 'every dialog finishes on the one lime slab (fin), none on a second filled button (R148)');
  check(/func _page_finish\(/.test(cui) && /"fleet": b = fin\("Done"/.test(cui) && /"shipyard": b = fin\("Leave shipyard"/.test(cui), 'fleet and shipyard keep their finishing action fixed bottom right (ui_style.md 7)');
  check(/func _well_text\(/.test(cui) && /_well_text\(v\)/.test(cui), 'dialog words are gathered onto wells (every line on a backing, ui_style.md 3)');
  for (const fn of ['header', 'purse', 'admiral', 'fleet_rows', 'hold_count', 'aspect', 'fight_cards']) check(new RegExp('static func ' + fn + '\\(C').test(view), `campaign_view.gd offers ${fn}() (audit pass 1, finding 12)`);
  check(!/\bRUN\[[^\]]*\]\s*=|\.RUN\[[^\]]*\]\s*=/.test(view) && !/C\.act\(/.test(view), 'campaign_view.gd only reads: no writes to the run, no actions');
  const side = (cui.match(/func _side\(\)[\s\S]*?\n(?=func )/) || [''])[0];
  check(/View\.purse\(C\)/.test(side) && /View\.fleet_rows\(C\)/.test(side) && !/R\["credits"\]|R\["cpCap"\]|C\.derive\(/.test(side), 'the side panel reads purse and fleet through the view, not the save by name');
  // report first (Board verdict on finding 12): direct save reads left in the campaign UI, counted, not failed
  const direct = ['godot/ui/campaign/campaign_ui.gd', 'godot/ui/campaign/map3d.gd'].map(f => (read(f).match(/\bR\[|\bC\.RUN\[|C\.RUN\.get\(|\bR\.get\(/g) || []).length);
  console.log(`NOTE direct save reads left in campaign_ui.gd ${direct[0]}, map3d.gd ${direct[1]} (finding 12 report; they move with their screen groups)`);
}

// 6. the diff script still reads every named pair (a pattern that stopped matching is reported, not failed)
const r = diff.build();
const stale = r.pairs.filter(p => /NOT FOUND/.test(p.a.v + p.b.v));
if (stale.length) console.log('NOTE ui_constants_diff pairs no longer found: ' + stale.map(p => p.id + ' ' + p.what).join('; ') + ' (update PAIRS in ui_constants_diff.js)');
check(typeof r.text === 'string' && r.text.length > 1000, 'ui_constants_diff builds its table');

console.log(`ui_spec_tests: ${pass + fail} checks, ${pass} pass, ${fail} fail`);
process.exitCode = fail ? 1 : 0;
