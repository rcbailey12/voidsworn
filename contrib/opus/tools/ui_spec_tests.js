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

// 2b. issue 546 (the A2 sweep row): the settings screen offers UI scale and Reduce motion, with the spec's defaults, and
// an old settings.json without either key keeps those defaults (main.gd loads the file key by key over its defaults).
{
  const mg = read('godot/main/main.gd');
  const defs = (/var settings := \{([^}]*)\}/.exec(mg) || [])[1] || '';
  check(/"ui_scale": 1\.0/.test(defs), 'main.gd default ui_scale is Normal 1.0 (ui_spec.md 4.4, 7.5)');
  check(/"reduce_motion": false/.test(defs), 'main.gd default reduce_motion is off (ui_spec.md 7.5, 7.6)');
  check(/for k in o:\n\s*settings\[k\] = o\[k\]/.test(mg), 'main.gd loads an existing settings file key by key over the defaults, so an old file without ui_scale or reduce_motion still reads 1.0 and off');
  check(/b\.reduce_motion = bool\(settings\.get\("reduce_motion", false\)\)/.test(mg), 'main.gd gives the battle the reduce_motion setting (a missing key reads off)');
  const ti = read('godot/main/title.gd');
  check(/_choice\("UI scale", "ui_scale", \[\[0\.9, "Small"\], \[1\.0, "Normal"\], \[1\.15, "Large"\], \[1\.3, "Larger"\]\]\)/.test(ti), 'title Settings offers UI scale as Small 0.9, Normal 1.0, Large 1.15, Larger 1.3 (ui_spec.md 4.4)');
  check(/_toggle\("Reduce motion", "reduce_motion"\)/.test(ti), 'title Settings offers Reduce motion as a switch (ui_spec.md 7.6)');
  check(/_toggle\("Reduce flashing", "reduce_flashing"\)/.test(ti), 'the two new entries sit in the same Settings list as Reduce flashing (issue 546)');
  check(/if key == "ui_scale":\n\s*_rebuild\(\)/.test(ti), 'changing UI scale rebuilds the title screen at once (ui_spec.md 4.4)');
  check(/ScrollContainer\.new\(\)/.test(ti) && /rows\.get_combined_minimum_size\(\)\.y, vs\.y - s\(150\)/.test(ti), 'the Settings list scrolls when the larger UI scales would push the panel past the window, so Done stays reachable');
  const bt = read('godot/scenes/battle/battle.gd');
  check(/items\.append\(\["Reduce motion: %s"/.test(bt) && /"opt", "motion"/.test(bt), 'the battle menu offers Reduce motion in the comfort subset (ui_spec.md 7.6)');
  check(/items\.append\(\["UI scale: %s"/.test(bt) && /"opt", "uiscale"/.test(bt), 'the battle menu offers UI scale in the comfort subset (ui_spec.md 4.4)');
  check(/reduce_motion = not reduce_motion/.test(bt) && /option_changed\.emit\("reduce_motion", reduce_motion\)/.test(bt), 'the battle menu switch writes reduce_motion through option_changed');
  check(/UiScale\.set_player\(v\)/.test(bt) && /option_changed\.emit\("ui_scale", v\)/.test(bt), 'the battle menu switch writes ui_scale and applies the shared law');
  check(/hud\._rebuild\(\)/.test(bt), 'changing UI scale in the battle menu rebuilds the HUD at once (ui_spec.md 4.4)');
}

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
const campaignHull = read('godot/ui/campaign/campaign_ui.gd');
const lows = [...hud.matchAll(/HULL_LOW if \w+ < ([\d.]+)/g), ...campaignHull.matchAll(/(?:BLOOD|HULL_LOW) if f < ([\d.]+)/g), ...campaignHull.matchAll(/HULL_LOW if float\(s\["frac"\]\) < ([\d.]+)/g)].map(m => +m[1]);
check(lows.length >= 4 && lows.every(v => v === 0.35), `every hull-low line is 0.35: battle roster, nameplate, campaign bars and hull figures (HD9; found ${lows.join(', ')})`);

// 7. issue #344 (UI rollout 1): the campaign pages are in Lime Tactical, and the campaign map is the Briefing layout
// (Ryan's pick, FINDINGS R165; docs/archive/briefs/campaign_map_briefing.md). These are code-structure checks: they read
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
  const fn = name => { const at = sec.indexOf('func ' + name + '('); return at < 0 ? '' : sec.slice(at).split(/\n(?=func )/)[0]; };
  const orders = sec.slice(sec.indexOf('func _sheet_words'), sec.indexOf('func _open_overlay'));
  check(/const COL_W := 540\.0/.test(sec) && /const COL_PAD := 40\.0/.test(sec) && /MarginContainer.new/.test(fn('_briefing_column')) && !/PanelContainer|GS\.column/.test(fn('_briefing_column')), 'orders sheet is an unboxed rail with 40 px margins');
  check(/sheet_veil\.anchor_right = 0\.43/.test(m3) && /GS\.sheet_veil/.test(m3) && /0\.96/.test(gsh2), 'a smooth dark veil reaches 43 percent of the map, below its words');
  check(/#ff8a3a/.test(gsh2) && /#f0eade/.test(gsh2) && /#c4beb0/.test(gsh2) && /#969084/.test(gsh2) && /#ff6050/.test(gsh2), 'orders sheet palette matches the approved ember, text and Nemesis colors');
  check(!/\bGILT\b|\bGILT2\b|GS\.row_boxes|GS\.jump_boxes|GS\.keycap_flat|GS\.thin_bar/.test(orders + m3), 'no lime, key badges, row fills or hull bars on the orders sheet or map');
  check(/sheet_jump_boxes/.test(fn('_jump_button')) && /px\(56\)/.test(fn('_jump_button')) && /focus/.test(fn('_jump_button')), 'the jump action is a 56 px square ember outline with a filled hover and focus state');
  const jumpStyle = gsh2.slice(gsh2.indexOf('static func sheet_jump_boxes'), gsh2.indexOf('# ---------------------------------------------------------------- type', gsh2.indexOf('static func sheet_jump_boxes')));
  check(/set_border_width_all\(maxi\(2/.test(jumpStyle) && !/corner_radius|shadow/.test(jumpStyle), 'the action has a 2 px edge, no rounded corners and no shadow');
  for (const [file, family] of [['BigShouldersDisplay-VF.ttf','Big Shoulders'], ['Barlow-Regular.ttf','Barlow'], ['Barlow-Medium.ttf','Barlow'], ['AzeretMono-VF.ttf','Azeret Mono']]) {
    check(fs.existsSync(path.join(ROOT,'godot/ui/theme/fonts',file)) && fs.statSync(path.join(ROOT,'godot/ui/theme/fonts',file)).size > 50000, family + ' font exists: ' + file);
  }
  check(/sheet_body\(\)/.test(fn('_sheet_words')) && /maxf\(17, size\)/.test(fn('_sheet_words')) && /sheet_medium\(\)/.test(fn('_sheet_words')), 'sentences use Barlow at a minimum of 17 px');
  check(/sheet_name\(\)/.test(fn('_sheet_name')) && /fs > 28/.test(fn('_sheet_name')) && /to_upper/.test(fn('_sheet_name')) && !/OVERRUN_TRIM|clip_text/.test(fn('_sheet_name')), 'names use Big Shoulders in capitals, wrap without trimming, and stay at least 28 px');
  check(/_sheet_name\(H\["region"\].*, 70/.test(orders) && /54 if on else 32/.test(orders) && /132 if on else 36/.test(orders), 'the region, selected route and other routes use the approved size hierarchy');
  check(/font_num, 19/.test(fn('_fleet_line')) && /_sheet_name\(s\["name"\], 28/.test(fn('_fleet_line')) && !/thin_bar|flagship.*tl\(/.test(fn('_fleet_line')), 'fleet names and hull figures have separate space, Azeret figures and a diamond flagship mark');
  check(/mini\(7, fleet.size\(\)\)/.test(orders) && /FleetScroll/.test(orders) && /OrdersScroll/.test(orders), 'large fleets and extreme route cases scroll without shrinking text');
  check(/for r in _routes:/.test(fn('_briefing_column')) && /if on:/.test(fn('_route_row')) && /_jump_button\(\)/.test(fn('_route_row')) && !/\["then"\]/.test(fn('_route_row')), 'routes stay in number order, expand in place and keep the action directly below the selection');
  check(/_action_line\(FA\)/.test(cui.slice(cui.indexOf('func _fleet('), cui.indexOf('func _shipyard'))) && !/_action_line|faction_action/.test(fn('_briefing_column')) && /C\.act\("factionVerb"/.test(fn('_action_line')), 'the unchanged faction purchase action lives in Fleet and refits');
  check(/GS\.sheet_pips/.test(fn('_route_row')) && /GS\.sheet_pips/.test(fn('_nemesis_block')) && !/persona_d/.test(fn('_nemesis_block')), 'danger and hunt use square pips; the trait sentence stays in the Dossier');
  check(/View\.routes\(C\)/.test(sec) && /View\.nemesis\(C\)/.test(sec) && /View\.nem_dossier\(C\)/.test(sec) && /View\.sector_notes\(C\)/.test(sec) && /View\.fleet_rows\(C\)/.test(sec) && /View\.purse\(C\)/.test(sec), 'the map screen reads routes, the Nemesis, the sector, the fleet and the purse through the view');
  check(!/\bR\[|C\.RUN\[|C\.RUN\.get\(|\bR\.get\(/.test(sec), 'the map screen reads no save field by name (everything comes through campaign_view.gd)');
  check(/func _dossier\(/.test(sec) && /func _map_key\(/.test(sec) && /func _slide_over\(/.test(sec), 'the Dossier and the Map key are the two slide-overs');
  check(/"Map detail: "/.test(sec) && /"Tips: "/.test(sec) && /Rival raiders/.test(sec) && /in range\[\/b\]/.test(sec), 'Map detail, Tips, rival raiders and cores in range live in the Map key');
  check(/func pick_route\(/.test(sec) && /KEY_KP_1/.test(cui) && /pick_route\(str\(_routes\[rn\]\["id"\]\)\)/.test(cui), 'a route is picked by its row, its number key or its stop on the map');

  // the map itself
  const system = read('godot/ui/campaign/map3d_system.gd');
  for (const key of ['boneyard', 'nebula', 'world', 'frontier', 'deep']) {
    check(system.includes('"' + key + '":') && gsh2.includes('"' + key + '"'), 'R174: ' + key + ' has region scenery and a shared emblem');
  }
  check(/GS\.region_emblem/.test(fn('_briefing_column')) && /GS\.region_emblem/.test(fn('_map_key')) && /2\.0 \* k/.test(gsh2), 'region emblems use the shared line artwork on the rail and Map key');
  check(/Battles take place among/.test(fn('_map_key')) && /C\.REGIONS\[region\]\["route"\]/.test(fn('_map_key')), 'the region battle-setting line comes from the live region routes');
  check(/Flown routes are hidden/.test(fn('_map_key')) && !/Flown routes are fainter/.test(fn('_map_key')), 'the Map key states that flown routes are hidden');
  check(/System\.fight_group\(/.test(m3) && /_map_ship_rim\(ship\)/.test(m3), 'fight models use the seeded group plan and every member gets a faint rim; live sizes and counts are checked by map_readonly and map_travel');
  check(/minimum_lines = mini\(3/.test(orders) && /54 if _routes.size\(\) >= 4/.test(orders) && /gap\(8 if _routes.size\(\) >= 4/.test(orders), 'four-route forks tighten unchosen rows and reserve three fleet lines');
  check(!/_add_orbits|sys\.orbit\(|sys\.orbit_arc\(/.test(m3) && !/STAR_ARCS/.test(system + msh), 'R174: no orbit guides or background star arcs are built around the sun');
  check(/const STOP_ICON_PX := 24\.0/.test(gsh2) && /GS\.stop_icon\(/.test(m3) && /GS\.stop_key\(/.test(sec), 'R174: map and Map key share the 24 px icon and its scaled halo');
  check(/func _enemy_fleet\(/.test(m3) && /if fight:\s+top = _enemy_fleet/.test(m3) && !/_place_scene/.test(m3), 'R174: every fight uses an enemy fleet, without battlefield scenery');
  check(/L\["mi"\]\.visible = not behind/.test(m3), 'R174: routes behind the fleet are hidden');
  check(/const BACKDROP_K := 0\.5/.test(m3) && /env\.background_energy_multiplier = BACKDROP_K/.test(m3) && /sys\.backdrop_k = BACKDROP_K/.test(m3), 'the map backdrop (sky, near stars, embers) is at half strength');
  check(/const TIER_LIGHT := \[1\.0, 0\.75, 0\.375\]/.test(m3) && /const TIER_SCALE := \[1\.0, 0\.85, 0\.425\]/.test(m3) && /func _set_tier\(/.test(m3), 'R170: stops ahead are 85% size and 75% brightness; cut-off stops have half of each');
  check(!/sys\.halo\(|sys\.threat\(|"RING"|_strip_text|func _chip\(|GS\.strip\(|GS\.tag\(/.test(m3), 'no rings, halos, threat holograms, strips or tags on the map');
  check(/"LANE_FLAT"/.test(m3) && !/sys\.mat\("LANE",/.test(m3) && /const LANE_FLAT := /.test(msh) && !/hazard|flow|halo/.test((msh.match(/const LANE_FLAT := """[\s\S]*?"""/) || [''])[0]), 'routes are flat lines: no flow, hazard chevrons or halo');
  check(/for_screen\(Color\(GS\.MAP_EMBER, 1\.0\)\); w = 1\.25/.test(m3) && /pale\(GS\.PALE\)/.test(m3) && /pale\(GS\.PALE_CUT\)/.test(m3) && !/0\.53, 0\.74, 1\.0/.test(m3), 'routes to the next jumps are ember and wider; every other route is one thin pale line, cut-off ones fainter; no blue routes');
  check(/GS\.halo_text\(overlay/.test(m3) && /GS\.marker\(overlay/.test(m3) && /GS\.diamond\(overlay/.test(m3), 'map words are plain text with a dark halo, next jumps carry the square number marker, Nemesis stops the red diamond');
  const mapSizes = [...m3.matchAll(/int\((\d+(?:\.\d+)?) \* s\)/g)].map(m => +m[1]);
  check(mapSizes.length >= 5 && mapSizes.every(v => v >= MIN_TEXT), `map words are at or above the text floor (found ${mapSizes.join(', ')})`);
  check(/GS\.tip\(ui\.k\)/.test(m3) && /func _fill_card\(/.test(m3), 'the hover tip is the one box on the map (glass_shell.gd tip)');
  // Muse's check of PR 349, condition 2: the three unbacked detail lines. Two are gone from the map; IN FLIGHT carries the halo.
  check(!/func _text\(/.test(m3) && /GS\.halo_text\(overlay, f14, Vector2\(fr\.get_center\(\)\.x - w3 \* 0\.5/.test(m3), 'the board shape and reward detail lines are gone from the map; the in-flight line carries the halo');
  // Muse's check of PR 349, condition 3: the names this build retires are gone from the theme; the kept ones are in ui_style.md 5
  const style = read('contrib/opus/briefs/ui_style.md');
  check(!/\bDANGER_|const DANGER\b|const STOP\b|ROUTE_SAFE|ROUTE_RICH/.test(gsh2) && !/GS\.(DANGER|STOP|ROUTE)\b/.test(cui + m3 + mi), 'the danger band, stop glyph and route planner colours are retired from glass_shell.gd');
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

// 8. issue 387 (UI-5): the battle screen clears its armed wing on every cancel path. The behaviour check is
// godot/scenes/battle/test/wing_cancel_test.gd, run by godot/tools/ci/run_checks.sh on GitHub. These are the structure
// guards, so the clearing cannot be dropped silently from the Node-only standing checks.
{
  const bg = read('godot/scenes/battle/battle.gd');
  const body = name => (new RegExp('func ' + name + '\\([^)]*\\)[^\\n]*\\n([\\s\\S]*?)\\n\\n\\n').exec(bg) || [])[1] || '';
  check(/wing_sel = ""/.test(body('select')), 'battle select() clears the armed wing (UI-5, issue 387)');
  check(/wing_sel = ""/.test(body('_cancel')), 'battle _cancel() clears the armed wing (UI-5, issue 387)');
  check(/elif wing_sel != "":[\s\S]*?wing_sel = ""/.test((bg.match(/KEY_ESCAPE:[\s\S]*?KEY_TAB:/) || [''])[0]), 'battle Escape clears the armed wing (UI-5, issue 387)');
  check(fs.existsSync(path.join(ROOT, 'godot/scenes/battle/test/wing_cancel_test.gd')) && /headless\|scenes\/battle\/test\/wing_cancel_test\.gd\|/.test(read('godot/tools/ci/godot_checks.txt')), 'the headless UI-5 behaviour check is listed in godot/tools/ci/godot_checks.txt');
}

// 9. issue 271 step 2: the battle screen is the ember orders sheet, E1 LEDGER (Ryan's pick R210; the rail's look, R176).
// Structure guards for the Node-only standing checks; the readability numbers (17 px, 28 px Big Shoulders, three strengths,
// 4.5 to 1 over the brightest and darkest board, no overlaps, every function reachable) are measured by the headless
// Godot check godot/ui/battle/test/ledger_readability_test.gd on GitHub.
{
  const led = read('godot/ui/battle/ledger.gd'), bg = read('godot/scenes/battle/battle.gd');
  const gsh3 = read('godot/ui/theme/glass_shell.gd'), board = read('godot/render/board.gd'), sv = read('godot/render/ship_view.gd');
  check(/const Ledger := preload\("res:\/\/ui\/battle\/ledger\.gd"\)/.test(hud) && /func _build_ledger\(/.test(hud) && /ledger\.ship = info/.test(hud) && /ledger\.target = info/.test(hud) && /ledger\.card = info/.test(hud), 'the battle HUD hands every setter to the orders sheet (ledger.gd)');
  // issue 578: the hidden Lime shell is gone; no file under godot/ui/battle/ writes the lime hex
  const battleUi = [];
  (function walk(d) {
    for (const e of fs.readdirSync(path.join(ROOT, d), { withFileTypes: true })) {
      const rel = d + '/' + e.name;
      if (e.isDirectory()) { if (e.name !== 'fonts') walk(rel); }
      else if (/\.(gd|tscn|tres|json)$/.test(e.name)) battleUi.push(rel);
    }
  })('godot/ui/battle');
  for (const f of battleUi) check(!/#c8f53a/i.test(read(f)), `${f} writes no lime hex (the hidden shell is gone, issue 578)`);
  check(/const EMBER := GS\.MAP_EMBER/.test(led) && /const GLACIER := GS\.GLACIER/.test(led) && /const GLACIER := Color\("#92b8e8"\)/.test(gsh3), 'the sheet takes ember and Glacier (#92b8e8) from glass_shell.gd');
  check(!/GILT|GS\.SHIELD\b|#c8f53a|#4fc4ff|corner_radius|shadow/.test(led), 'no lime, no old shield cyan, no rounded corners and no shadows on the sheet');
  const plan = (led.match(/func _shield_plan\([\s\S]*?\n(?=func )/) || [''])[0];
  const glacierUses = led.split('\n').filter(l => /GLACIER/.test(l) && !/^\s*#|^const /.test(l));
  check(glacierUses.length >= 2 && glacierUses.every(l => plan.includes(l)), 'Glacier is used by the shield plan only (the shield readout)');
  check(/GS\.sheet_name\(\)/.test(led) && /GS\.sheet_body\(\)/.test(led) && /GS\.sheet_medium\(\)/.test(led) && /GS\.num\(\)/.test(led) && /fs > 28/.test(led), 'the sheet uses the three faces (Big Shoulders names from 28 px, Barlow, Azeret Mono)');
  check(/func _action_box\(/.test(led) && /px\(56\)/.test(led) && /maxf\(2\.0, px\(2\)\)/.test(led), 'the one box is the 56 px square ember action, a 2 px outline');
  check(/static func veil_alpha/.test(led) && /func dark_at\(/.test(led) && /VEIL_A := 0\.94/.test(led), 'the sheet sits on a smooth veil, not a panel, and the check reads its strength');
  check(/HOVER_RING := Color\(1\.0, 0\.541, 0\.227/.test(board) && !/0\.78, 0\.96, 0\.23/.test(board + sv + bg), 'the hovered hex and the ring under the ship that is up are ember on the 3D board (lime retired, R191)');
  check(!/#c8f53a|#4fc4ff/.test(bg), 'battle.gd writes no lime and no old shield cyan');
  check(/"say": say/.test(bg) && /"nem": bool\(tu\.get\("nemesis", false\)\)/.test(bg), 'the activation card carries one short sentence and the target says when it is the Nemesis');
  check(/\["Top-down view \(T\)", "top"\]/.test(bg) && /\["Keys", "keys"\]/.test(bg) && /"grid":/.test(bg), 'the view keys that left the screen are listed in the menu (T, Z, Keys)');
  check(/func show_ask\(/.test(hud) && /ledger\.ask = a/.test(hud) && /func _prompt\(/.test(led), 'the issue 529 tree prompt takes the shot\'s place in the sheet (show_ask drops in)');
  check(/screen_shift/.test(read('godot/render/camera_rig.gd')) && /hud\.clear_shift\(\)/.test(bg), 'the camera looks at the middle of the part the sheet leaves clear');
  check(/headless\|ui\/battle\/test\/ledger_readability_test\.gd\|/.test(read('godot/tools/ci/godot_checks.txt')), 'the readability check is listed in godot/tools/ci/godot_checks.txt');
}

// 6. the diff script still reads every named pair (a pattern that stopped matching is reported, not failed)
const r = diff.build();
const stale = r.pairs.filter(p => /NOT FOUND/.test(p.a.v + p.b.v));
if (stale.length) console.log('NOTE ui_constants_diff pairs no longer found: ' + stale.map(p => p.id + ' ' + p.what).join('; ') + ' (update PAIRS in ui_constants_diff.js)');
check(typeof r.text === 'string' && r.text.length > 1000, 'ui_constants_diff builds its table');

console.log(`ui_spec_tests: ${pass + fail} checks, ${pass} pass, ${fail} fail`);
process.exitCode = fail ? 1 : 0;
