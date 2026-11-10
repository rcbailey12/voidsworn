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

// 7. issue #344 (UI rollout 1): the campaign pages are in Lime Tactical, and the campaign map is the Briefing layout
// (Ryan's pick, FINDINGS R165; contrib/opus/briefs/campaign_map_briefing.md). These are code-structure checks: they read
// the source. What the map does when it runs (it only reads; Muse's check of PR 349, condition 1) is tested by behaviour in
// godot/campaign/test/map_readonly_test.gd, which CI runs with the Nemesis scenarios (run_nem_scenarios.sh).
{
  const cui = read('godot/ui/campaign/campaign_ui.gd'), m3 = read('godot/ui/campaign/map3d.gd'), mi = read('godot/ui/campaign/map_intel.gd');
  const cb = read('godot/ui/campaign/choice_button.gd'), gsh2 = read('godot/ui/theme/glass_shell.gd'), view = read('godot/campaign/campaign_view.gd');
  const msh = read('godot/ui/campaign/map3d_shaders.gd');
  check(/const GS = preload\("res:\/\/ui\/theme\/glass_shell\.gd"\)/.test(cui) && /const GILT := GS\.GILT/.test(cui), 'campaign_ui.gd takes its palette from glass_shell.gd (ui_style.md 8)');
  check(!/Color\("#[0-9a-fA-F]{6}"\)/.test(cui), 'campaign_ui.gd writes no colour hex of its own (new colours go into glass_shell.gd first)');
  check(!/Color\("#[0-9a-fA-F]{6}"\)/.test(mi), 'map_intel.gd writes no colour hex of its own');
  check(/GS\.make_theme\(k, font, font_semi, 17\)/.test(cui) && !/set_stylebox\("focus"/.test(cui), 'campaign theme is GS.make_theme at base 17 and sets no focus stylebox of its own (one ring, ui_spec.md 6)');
  check(!/Barlow|Michroma|Oxanium/.test(cui), 'campaign screens use the glass_shell.gd faces, not the old Barlow, Michroma and Oxanium');
  check(/font = GS\.body\(\)/.test(cui) && /font_goth = GS\.display\(k\)/.test(cui) && /font_caps = GS\.caps\(k\)/.test(cui), 'campaign fonts come from glass_shell.gd and the tracked faces follow k');
  check(!/modulate\.a = 0\.5/.test(cb) && /tagl\("Locked", BONE3\)/.test(cui), 'a disabled choice dims its words and says LOCKED, not a 50% fade (MN12, ui_style.md 3)');
  check(/draw_style_box\(ring/.test(cb) && /b\.ring = GS\.focus_ring\(k\)/.test(cui), 'campaign choices draw the shared focus ring when focused');
  check((cui.match(/\bfin\(/g) || []).length >= 14 && !/abtn\([^\n]*, true, false, acts\)/.test(cui), 'every dialog finishes on the one lime slab (fin), none on a second filled button (R148)');
  check(/func _page_finish\(/.test(cui) && /"fleet": b = fin\("Done"/.test(cui) && /"shipyard": b = fin\("Leave shipyard"/.test(cui), 'fleet and shipyard keep their finishing action fixed bottom right (ui_style.md 7)');
  check(/func _well_text\(/.test(cui) && /_well_text\(v\)/.test(cui), 'dialog words are gathered onto wells (every line on a backing, ui_style.md 3)');

  // the Briefing layout: the map screen's own section of campaign_ui.gd
  const sec = (cui.match(/# -+ the sector map: the Briefing layout[\s\S]*?\n(?=# -+ ship cards, fleet, shipyard)/) || [''])[0];
  check(sec.length > 4000, 'campaign_ui.gd has the Briefing layout section (the map screen)');
  check(/const COL_W := 480\.0/.test(sec) && /const COL_PAD := 40\.0/.test(sec) && /GS\.column\(k\)/.test(sec), 'the briefing column is 480 wide with 40 padding on the flat column of glass_shell.gd');
  check(!/shell_panel\(|GS\.frame_marks|GS\.well\(k, GILT|GS\.strip\(|GS\.finish_boxes|GS\.lit_boxes/.test(sec.replace(/func blk\([\s\S]*?\n(?=func )/, '')), 'no chamfers, brackets, scanline, lit wells or strips on the map screen (brief: one flat column)');
  check((sec.match(/GS\.jump_boxes\(k\)/g) || []).length === 1 && /func _jump_button\(/.test(sec), 'the map screen has one filled lime button, the jump button (R148)');
  // lime on the map screen: the picked number, the jump button, the key's samples. Nothing else may take GILT.
  const giltUses = sec.split('\n').filter(l => /\bGILT\b/.test(l) && !/^\s*#/.test(l));
  check(giltUses.length <= 3 && giltUses.every(l => /GILT if on else BONE3|"lime": m\.draw_line|kind == "lime"/.test(l)), `lime in the map screen's code is only the picked number and the key's sample line (found ${giltUses.length} lines)`);
  const redUses = sec.split('\n').filter(l => /\bALERT\b/.test(l) && !/^\s*#/.test(l));
  check(redUses.length >= 3 && redUses.every(l => /Nemesis|_nem_mark|GS\.diamond|GS\.pips\(k, float\(N\["clock"\]\)|_over_head\("Nemesis"/.test(l)), `red in the map screen's code is only the Nemesis (found ${redUses.length} lines)`);
  check(!/\b(BLOOD|VERD|EMBER|FRIEND|BLUE)\b/.test(sec.replace(/#.*$/gm, '')) && !/fac_col\(|PATRONS\[[^\]]*\]\["col"\]/.test(sec), 'no third accent on the map screen: no faction or core colours in body text, no BLOOD, VERD, EMBER, FRIEND or BLUE');
  // one type ladder: every size literal in the section is on it
  const ladder = new Set([12, 13, 14, 15, 16, 17, 18, 20, 22, 26, 28, 30, 40]);
  const sizes = [...sec.matchAll(/\b(?:tl|para|tbtn|_over_text)\((?:[^()]|\([^()]*\))*?, (\d+(?:\.\d+)?), (?:\d+|lh|16|20)/g)].map(m => +m[1]);
  check(sizes.length >= 40 && sizes.every(v => ladder.has(v)), `every text size on the map screen is on the one ladder (${[...new Set(sizes)].sort((a, b) => a - b).join(', ')})`);
  check(/View\.routes\(C\)/.test(sec) && /View\.nemesis\(C\)/.test(sec) && /View\.nem_dossier\(C\)/.test(sec) && /View\.sector_notes\(C\)/.test(sec) && /View\.fleet_rows\(C\)/.test(sec) && /View\.purse\(C\)/.test(sec), 'the map screen reads routes, the Nemesis, the sector, the fleet and the purse through the view');
  check(!/\bR\[|C\.RUN\[|C\.RUN\.get\(|\bR\.get\(/.test(sec), 'the map screen reads no save field by name (everything comes through campaign_view.gd)');
  check(/func _dossier\(/.test(sec) && /func _map_key\(/.test(sec) && /func _slide_over\(/.test(sec), 'the Dossier and the Map key are the two slide-overs');
  check(/"Map detail: "/.test(sec) && /"Tips: "/.test(sec) && /Rival raiders/.test(sec) && /in range\[\/b\]/.test(sec), 'Map detail, Tips, rival raiders and cores in range live in the Map key');
  check(/func pick_route\(/.test(sec) && /KEY_KP_1/.test(cui) && /pick_route\(str\(_routes\[rn\]\["id"\]\)\)/.test(cui), 'a route is picked by its row, its number key or its stop on the map');

  // the map itself
  check(/const BACKDROP_K := 0\.5/.test(m3) && /env\.background_energy_multiplier = BACKDROP_K/.test(m3) && /sys\.backdrop_k = BACKDROP_K/.test(m3), 'the map backdrop (sky, near stars, embers) is at half strength');
  check(/const TIER_LIGHT := \[1\.0, 0\.45, 0\.18\]/.test(m3) && /const TIER_SCALE := \[1\.0, 0\.7, 0\.6\]/.test(m3) && /func _set_tier\(/.test(m3), 'stops further on are 70% size and under half brightness; stops behind or cut off dimmer still');
  check(!/sys\.halo\(|sys\.threat\(|"RING"|_strip_text|func _chip\(|GS\.strip\(|GS\.tag\(/.test(m3), 'no rings, halos, threat holograms, strips or tags on the map');
  check(/"LANE_FLAT"/.test(m3) && !/sys\.mat\("LANE",/.test(m3) && /const LANE_FLAT := /.test(msh) && !/hazard|flow|halo/.test((msh.match(/const LANE_FLAT := """[\s\S]*?"""/) || [''])[0]), 'routes are flat lines: no flow, hazard chevrons or halo');
  check(/Color\(GS\.GILT, 1\.0\); w = 1\.25/.test(m3) && /Color\(GS\.BONE, GS\.PALE\)/.test(m3) && /Color\(GS\.BONE, GS\.PALE_CUT\)/.test(m3) && !/0\.53, 0\.74, 1\.0/.test(m3), 'routes to the next jumps are lime and wider; every other route is one thin pale line, cut-off ones fainter; no blue routes');
  check(/GS\.halo_text\(overlay/.test(m3) && /GS\.marker\(overlay/.test(m3) && /GS\.diamond\(overlay/.test(m3), 'map words are plain text with a dark halo, next jumps carry the square number marker, Nemesis stops the red diamond');
  const mapSizes = [...m3.matchAll(/int\((\d+(?:\.\d+)?) \* s\)/g)].map(m => +m[1]);
  check(mapSizes.length >= 5 && mapSizes.every(v => v >= MIN_TEXT), `map words are at or above the text floor (found ${mapSizes.join(', ')})`);
  check(/GS\.tip\(ui\.k\)/.test(m3) && /func _fill_card\(/.test(m3), 'the hover tip is the one box on the map (glass_shell.gd tip)');
  // Muse's check of PR 349, condition 2: the three unbacked detail lines. Two are gone from the map; IN FLIGHT carries the halo.
  check(!/func _text\(/.test(m3) && /GS\.halo_text\(overlay, f14, Vector2\(fr\.get_center\(\)\.x - w3 \* 0\.5/.test(m3), 'the board shape and reward detail lines are gone from the map; the in-flight line carries the halo');
  // Muse's check of PR 349, condition 3: the names this build retires are gone from the theme; the kept ones are in ui_style.md 5
  const style = read('contrib/opus/briefs/ui_style.md');
  check(!/\bDANGER_|const DANGER\b|const STOP\b|ROUTE_SAFE|ROUTE_RICH/.test(gsh2) && !/GS\.(DANGER|STOP|ROUTE)/.test(cui + m3 + mi), 'the danger band, stop glyph and route planner colours are retired from glass_shell.gd');
  for (const name of ['BLUE', 'SHADE', 'COLUMN', 'HAIR', 'ROW_LIT', 'ROW_HOVER', 'HALO', 'PALE']) check(new RegExp('const ' + name + ' := ').test(gsh2) && new RegExp('\\| [^|\\n]*\\b' + name + '\\b[^|\\n]* \\|').test(style), `${name} is in glass_shell.gd and has its row in ui_style.md section 5`);
  check(/campaign map exception/i.test(style), 'ui_style.md records the campaign map exception to section 3 (plain words with a dark halo)');

  // the view: the functions the screens read through, and the spelling half of the read-only rule (the behaviour half is
  // godot/campaign/test/map_readonly_test.gd)
  for (const fn of ['header', 'purse', 'admiral', 'fleet_rows', 'hold_count', 'aspect', 'routes', 'stop', 'nemesis', 'nem_dossier', 'sector_notes', 'faction_action', 'run_notes']) check(new RegExp('static func ' + fn + '\\(C').test(view), `campaign_view.gd offers ${fn}() (audit pass 1, finding 12)`);
  const code = t => t.replace(/#.*$/gm, '');
  check(!/\bRUN\[[^\]]*\]\s*=|\.RUN\[[^\]]*\]\s*=/.test(view) && !/C\.act\(/.test(view), 'spelling check: campaign_view.gd assigns to no run field and calls no action');
  // a call that resolves the commander: nemActive, ensureNemesis, and the rules that fall back to nemActive when they are
  // given no commander (nemNodeIs(n), nemBeh(), nemPanelData(), nemFull(), nemMeetingLine())
  const resolvers = /C\.(nemActive|ensureNemesis|nemNodeTag|nemBattleCfg|nemReveal|nemClockAdd|nemStrike)\(|C\.(nemBeh|nemPanelData|nemFull|nemMeetingLine)\(\)|C\.nemNodeIs\([^,()]*\)/;
  check(!resolvers.test(code(view)) && /C\.nemNodeIs\(n, N\)/.test(view) && /C\.nemPanelData\(N\)/.test(view) && /C\.nemWarnLine\(N\)/.test(view), 'spelling check: campaign_view.gd hands the commander it read (C.nemRead) to the campaign rules and calls none that resolves or creates one');
  check(!resolvers.test(code(m3)) && !resolvers.test(code(mi)) && !resolvers.test(code(sec)) && /View\.nem\(C\)/.test(cui), 'spelling check: the map, its estimate and the map screen call none of them either');
  const cgd = read('godot/campaign/campaign.gd');
  check(/func nemBeh\(N0 = null\)/.test(cgd) && /func nemNodeIs\(n, N0 = null\)/.test(cgd) && /func nemPanelData\(N0 = null\)/.test(cgd) && /var st = nemBeh\(N\)\.get\("strike"\)/.test(cgd), 'campaign.gd lets a reader pass the commander it already read (nemBeh, nemNodeIs, nemPanelData, nemWarnLine)');
  check(/map_readonly_test\.gd/.test(read('godot/campaign/test/run_nem_scenarios.sh')) && fs.existsSync(path.join(ROOT, 'godot/campaign/test/map_readonly_test.gd')), 'the behaviour check of the read-only rule (map_readonly_test.gd) runs with the Nemesis scenarios in CI');
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
