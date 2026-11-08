# Evidence pack: red team of the Voidsworn UI, menu, and campaign map gates

Job: a red team of every design gate, constant, convention, and
default governing how the UI of Embers of the Hollow Sun
(Voidsworn) looks and reads: the battle HUD, menus and flow
screens, the shop and reward screens, debrief presentation, the
campaign (sector) map, typography, iconography and markers,
faction colour usage in UI, and settings and accessibility.
Three writer legs run from this pack (blind Rey, DeepSeek,
Qwen), identically prompted, plus one Flash ideation leg. The
chair screens every leg before anything is adopted.

This pack is the legs' complete evidence. It is built from the
shipped code on main, read Nov 6, 2026: the frozen JS build
(head.html, voidsworn-3d.html, ui3d.js, battle.js, data.js,
campaign_run.js, campaign_meta.js, campaign3d.js) and the Godot
port (godot/project.godot, godot/ui/battle/hud.gd and brand.gd,
godot/ui/campaign/campaign_ui.gd, map3d.gd, map_intel.gd,
campaign_tips.gd, choice_button.gd, crest.gd,
godot/main/title.gd, main.gd, campaign_fallback_ui.gd,
godot/campaign/campaign.gd). Where this pack and a leg
disagree, the pack wins. Where a source file and this pack's
summary of it disagree, the source wins and the disagreement
is a finding.

A note on the two builds, because the whole pack turns on it:
the JS build is frozen to break fixes but is the currently
playable game. The Godot port re-implements its screens and is
not yet the shipped game. UI truth therefore lives in both,
and every place the two disagree is inventoried as a
disagreement, not resolved by picking a winner. The port's own
header states the intent: the Godot HUD is "laid out like
today's game (head.html, ui3d.js)" with "Colours from the
game's CSS variables" (godot/ui/battle/hud.gd:1-5).

## 1. Scope and method

### 1.1 The owner's instruction

Ryan Bailey, Nov 6, 2026: after the graphics red team, the
ceiling pressure test, the fx audit, and the environment and
destruction audits, the chair named the UI and campaign map as
the last unaudited player-facing surface. Ryan approved the
commission the same day ("everything except 3", the excluded
item being a parked Steam store art note, which is not part of
this audit).

### 1.2 What counts as a gate

A gate is any of: a numeric constant that sizes, spaces,
colours, times, or caps a UI element; a layout rule (fixed
widths, regions, scroll behaviour); a typographic choice (face,
size, scaling law); a naming or labelling convention; a
settings default or a settings menu's contents; and, in this
stack especially, an ABSENCE: a control or protection that
comparable games and this game's own other screens lead a
reader to expect, which does not exist (no text scale setting,
no colour-vision support, no minimum text size). Absences are
inventoried as items with provenance ASSUMED, because an
absence that binds every player is a design outcome whether or
not anyone chose it.

### 1.3 Provenance classes

- MEASURED: a test, capture, count, or code verification
  produced the value.
- DERIVED: arithmetic from measured or ruled inputs, with the
  arithmetic shown in the item.
- ANCHORED: copied from a named external source, an engine or
  platform default, or another document; the source is named.
- ASSUMED: appears from nowhere, a round number with no test,
  or an implementer's choice with no record.

### 1.4 This red team's question

For every gate in the UI stack, answer three things:

1. What kind of gate is it (section 1.3)?
2. What does it cost if it is wrong, in each of the three
   lenses: game dev (performance, gameplay, input), graphic
   designer (the look, hierarchy, and readability of the
   screens), agent lead (pipeline effort, enforceability,
   wasted runs)?
3. What measurement, capture, or build would settle it, and
   what does that cost in agent terms (section 1.5)?

A gate is artificial, in the owner's sense, when it cannot be
traced to a measurement or a derivation but still binds what
players see in every session. A silent disagreement between
the JS build and the Godot port, or between two screens in the
same build, counts double: the value is not only unmeasured,
the project does not agree with itself about it.

### 1.5 Cost units

The only units permitted anywhere in a leg report: Codex runs
(one-hour cap per run), Opus runs, one-time script builds,
per-asset unattended runs, owner review rounds. State one-time
and recurring costs separately. No human hours, days, or weeks
anywhere (standing rule R99).

### 1.6 Standing owner rulings that govern this audit

These rulings are settled and are NOT inventory items. The
legs apply them; they do not re-litigate them.

- Tests and captures run uncapped where the stack has a load
  to measure. Numbers are reported, never treated as pass or
  fail gates. The measured scene gate in milliseconds on the
  RTX 5080 (issue 207, still to run) is the only binding
  performance limit; no UI number in this pack is a substitute
  for it, and no leg may propose a triangle or performance cap.
- Performance aspiration: 60 fps at 4K, flexible as needed;
  minimum resolution 1440p (ruled Nov 6, 2026 in the fx audit).
  Judgement is the owner's eye on captures and in play,
  against the stated objective: AAA style graphics.
- Assumed and anchored numeric gates stop binding. A
  constraint earns its way back only by proving itself in
  builds. Replacements are measurements, consolidated
  specifications, or the owner's eye on sheets and captures.
- The platform is PC only. The phone was dropped as a design
  constraint on Oct 24, 2026. Any UI text, layout, or tier
  still denominated for phones is inventoried as a leftover,
  not re-litigated as a platform question.

## 2. Settled rulings fenced off

The following are decided and are excluded from the inventory.
Legs may cite them; they may not re-audit them.

- F1. Camera calibration. The destruction audit's ruling
  (issue 212) commissions a calibration harness: the owner
  plays at the standard radius and zooms in for effects, and
  the readability standards re-denominate at the logged pair.
  The 170-unit camera radius is therefore a known-unjudged
  denominator under repair, not an open question. Section 3
  inventories only UI constants silently denominated against
  on-screen size, as cross-reference.
- F2. The flash cap. The fx audit's item E6 (flash and strobe
  limits) is derived from WCAG 2.3.2 and platform guidance and
  was ruled the best-derived number in the fx stack. The
  settings toggle that exposes it is inventoried (AC3) as a
  settings default only; the cap itself is not re-audited.
- F3. The movement specification. A consolidated movement spec
  is commissioned under issue 210. The settings choices that
  select movement feel (MN items on the Movement and Speed
  choices) are inventoried as settings surface only; the
  underlying motion parameters belong to issue 210.
- F4. Faction motif ownership is lore-settled: light, glass,
  grief for the Glasswrights; taste, heat, smell, teeth for
  the Chorus; memory, archive, lost sun for Eclipse; data,
  Registry for the Hegemony; oath, dawn, burning for the
  Crusade; violence, trophies, scrap for the Hullbreakers. No
  leg may propose moving a motif between factions. How those
  motifs are (or are not) carried into UI colour and icon work
  IS inventory (IC7).
- F5. The game title. "Embers of the Hollow Sun" is approved
  (FINDINGS R59, recorded in godot/ui/battle/brand.gd). The
  title screen's sizing law for that title is inventory (MN1);
  the name is not.

## 3. Cross-references to already-audited items

These are NOT duplicated in the inventory. Legs treat them as
settled inventory under their existing numbers.

- X1. Battle effects readability (fx audit, E1 to E34): weapon
  timing, tracer and lance presentation, damage-state effects.
  Floating combat text styling is inventoried here (HD12)
  only as typography; the effects themselves are fx items.
- X2. The nine-cell sheets and the readable paint standard
  (issues 188, 200, 208): ship readability at battle and close
  crops. Those standards judge ships, not UI. No UI element in
  this pack was ever placed on a nine-cell sheet; that gap is
  a hypothesis input (section 10), not an inventory item.
- X3. The 170-unit camera radius (destruction audit CM1;
  fenced at F1): the denominator for px-per-unit readability
  math in the ship standards. UI relevance: nameplates are
  fixed-pixel overlays on a variable-scale 3D board (HD7,
  HD8). At the standard radius a capital spans a known screen
  width while its nameplate bar stays at a fixed pixel width,
  so the plate-to-ship proportion inverts as the player zooms.
  No item in either build adjusts plate size by zoom; the JS
  build has one overlay fade behaviour keyed to zoom
  (ui3d.js:168, overlay opacity 1 at board zoom falling to
  0.15 in the tightest view), which is an fx-side overlay
  behaviour cross-referenced here.
- X4. Ship and station paint palettes (issues 188, 193, 199):
  the hull, trim, and glow colours per faction live in
  data.js (see IC7). The paint standards govern the 3D models;
  this pack inventories only where those colours enter UI.
- X5. Sound settings values (fx audit, S domain): the Volume
  and Music volume sliders are inventoried here only as
  settings surface (MN3); their audio behaviour is fx
  inventory.

## 4. Battle HUD inventory (HD1 to HD15)

Template per entry: the value or rule and where it lives; its
provenance class with the evidence; what breaks if it is
wrong; what measurement would settle it. Tallies for this
section: 15 entries; MEASURED 0, DERIVED 0, ANCHORED 1,
ASSUMED 14.

HD1. The HUD scaling law: every size in the Godot battle HUD
is s(v) = round(v * k), where k = clamp(viewport height /
1080, 0.6, 2.2). The header states the design point: sizes
scale with window height, designed at 1080.
- Lives in: godot/ui/battle/hud.gd:94-95 (scale_for), 210-211
  (s), header at hud.gd:1-13.
- Provenance: ASSUMED. Evidence: shipped code. A screenshot job
  verifies the rebuild behaviour (ui_shots.gd:152 checks the
  built k matches scale_for after a resize), which verifies
  the law's implementation, not its values. No capture in the
  record judges the HUD at 1440p or 4K, and neither clamp bound
  (0.6 floor, 2.2 ceiling) has a stated source.
- If wrong: this one formula denominates every HUD size in
  the game. At 1440p (height 1440) k is 1.33; at 4K (2160) k
  is 2.0; the ceiling 2.2 binds only above 2376 px of window
  height. If the design point or the clamps are wrong, every
  screen is wrong by the same factor.
- Settles it: HUD captures at 1440p and 4K judged by the owner
  in the camera calibration sitting (issue 212, S-E), no extra
  run; the clamps earn or lose their values there.

HD2. Battle theme base sizes: theme default font s(15),
Button font s(14), RichTextLabel normal and bold s(14).
- Lives in: godot/ui/battle/hud.gd:217, 240, 245-246.
- Provenance: ASSUMED. Evidence: shipped constants. The JS
  build's body size is also 15px (head.html:23), but as a
  fixed pixel value with two media queries (HD15, TY3), so
  the agreement is nominal, not structural.
- If wrong: 15 is the size every battle decision is read at;
  one step either way changes the information density of the
  whole HUD.
- Settles it: the same 1440p and 4K capture round as HD1.

HD3. Top bar: the Godot title label ("Round 1") is 21 in the
display face, with the turn label at 17. The JS top bar is a
52 px bar whose game-title text is 28 in the blackletter face.
- Lives in: godot/ui/battle/hud.gd:354, 356; head.html:42-43.
- Provenance: ASSUMED, both sides. The two bars also carry
  different contents (HD14), so this is a redesign that was
  never specified, not a port.
- If wrong: the top bar is the most-seen strip in the game;
  its hierarchy (what is largest) is currently set by two
  different implementer choices in two builds.
- Settles it: one side-by-side capture of both top bars in the
  HD1 round.

HD4. Fleet roster geometry: the JS roster is fixed at 236 px
wide, top 76, bottom 150. The Godot roster is a scrolling
column whose height is fitted each frame to the viewport
minus s(236), with ship names given a minimum width of s(130).
- Lives in: head.html:44; godot/ui/battle/hud.gd:499, 528.
- Provenance: ASSUMED, both sides. No capture compares how
  many ships read at once in each build at the owner's
  resolutions.
- If wrong: with fleets near 20 ships, roster height decides
  whether the fleet state is glanceable or a scroll exercise
  mid-battle.
- Settles it: a full-fleet (20 ship) roster capture in the HD1
  round, both builds.

HD5. Selected-ship panel width: JS 340 px fixed; Godot s(316).
- Lives in: head.html:45; godot/ui/battle/hud.gd:580.
- Provenance: ASSUMED, both sides, and a silent disagreement:
  at the shared 1080 design height the port's panel is 24 px
  narrower than the playable build's, with no record of the
  change.
- If wrong: the panel carries stats, weapons with hit
  chances, and orders; 24 px is roughly two characters of
  weapon text per row.
- Settles it: the HD3 side-by-side capture.

HD6. Battle log: JS panel 430 by 126 px at 13.5 px text, with
the DOM child list capped at 200 entries (older entries are
removed). Godot: a RichTextLabel at 13, scroll-following on,
and no entry cap located in the add_log path, which appends
formatted text per event.
- Lives in: head.html:46; ui3d.js:5; godot/ui/battle/hud.gd:
  713-721, 728-738.
- Provenance: ASSUMED, both sides, with a behavioural
  disagreement: a cap exists in the playable build's
  presentation and none was located in the port's. (Whether
  the port's underlying event array is capped in
  godot/scenes/battle/battle.gd was not established; see
  Limitations.)
- If wrong: an uncapped rich-text log in a long battle is a
  growing layout and memory cost, and the two builds will
  diverge in what of the fight remains readable afterwards.
- Settles it: a long-battle soak capture plus a line count,
  one Codex run.

HD7. Nameplate geometry: JS plates use a fixed bar width
variable of 54 px and a 12 px name; the name's base opacity is
0 with a 0.15 s transition (the showing rules sit in state
classes not fully read; see Limitations). Godot plates use a
bar of s(90) wide and a 14 pt name.
- Lives in: head.html:86-87; godot/ui/battle/hud.gd:975, 981.
- Provenance: ASSUMED, both sides, and the largest single
  numeric disagreement in this pack: at the 1080 design height
  the port's nameplate bar is 90 px against the playable
  build's 54 px, a 67 percent difference in the size of the
  element that sits on every ship in every battle. (90 / 54 =
  1.67.)
- If wrong: plate size relative to ship size is the battle's
  core readability ratio (see X3); one of the two builds is
  showing plates at a size nobody chose.
- Settles it: plate-at-zoom captures at the standard radius
  and at the owner's effects zoom, in the calibration sitting.

HD8. Nameplate bars: JS shows hull as a 4 px bar and shields
as four segment pips (segments sized (54 - 6) / 4 px). Godot
shows hull as an s(4) bar and shields as a continuous s(3)
bar beneath it.
- Lives in: head.html:57, 92, 95; godot/ui/battle/hud.gd:
  980-999.
- Provenance: ASSUMED, both sides, with a presentation
  disagreement: segmented shield pips (which read as four
  facings or four charges) against a continuous shield bar
  (which reads as a fraction). The two builds teach the player
  two different shield models at the nameplate.
- If wrong: shield state is a targeting input; the wrong
  encoding costs decision time in every engagement.
- Settles it: the HD7 capture round, with the owner asked
  which encoding he reads faster.

HD9. Hull-low threshold: the JS roster bar turns low-colour
at hull fraction below 0.35. The Godot roster fill turns
HULL_LOW at fraction below 0.34.
- Lives in: voidsworn-3d.html:5927 (hpBar); godot/ui/battle/
  hud.gd:550.
- Provenance: ASSUMED, both sides, and a silent disagreement
  of exactly the kind the environment audit kept finding
  (AS14 pattern): two near-identical constants, 0.35 and
  0.34, in two builds, with no record that either was chosen
  over the other.
- If wrong: almost nothing, which is the point: a threshold
  nobody can feel differs between builds, so neither build's
  value has ever been tested by being noticed.
- Settles it: one line in the consolidated UI specification
  (an Opus run), value picked by the owner or by the capture
  round.

HD10. IFF colours: JS friend names #8ff0a0, foe names
#c9a2ff, with plate rings at rgba(110,245,140,.5) and
rgba(160,70,255,.65). Godot ports these as FRIEND
Color(0.56, 0.94, 0.63) and FOE Color(0.79, 0.64, 1.0).
- Lives in: head.html:77, 93; godot/ui/battle/hud.gd:37-38.
- Provenance: ANCHORED. Evidence: the port's header states
  colours come from the game's CSS variables (hud.gd:1-5).
  The port's rounding drifts one step in two channels:
  0.56 * 255 = 142.8 (0x8F), 0.94 * 255 = 239.7 (0xF0),
  0.63 * 255 = 160.65 (0xA1), giving #8ff0a1 against the CSS
  #8ff0a0; 0.79 * 255 = 201.45 (0xC9), 0.64 * 255 = 163.2
  (0xA3), giving #c9a3ff against #c9a2ff.
- If wrong: it is not, visibly; the item exists because the
  rounding drift is the fingerprint of the whole port's method
  (transcription by eye, not by table), which HD5, HD7, and
  HD9 show costing real differences elsewhere.
- Settles it: nothing for this item; it is evidence for H1.

HD11. Round banner: JS banner text is 84 px in the blackletter
face, centred at 38 percent of screen height, fading over
0.35 s. Godot banner is a 46 pt display-face label, centred.
- Lives in: head.html:84; godot/ui/battle/hud.gd:741.
- Provenance: ASSUMED, both sides. At the 1080 design height
  the playable build's banner is nearly twice the port's size
  (84 against 46). Banner timing and text content are fx and
  story surfaces; only the size and face are inventoried here.
- If wrong: the banner is the game's punctuation; the two
  builds currently shout at two different volumes.
- Settles it: the HD3 capture round.

HD12. Floating combat text: 19 px bold, rising over a 1.25 s
keyframed animation (scale from 0.35 up to 1.3, settle at 1,
drift up 50 px, fade).
- Lives in: head.html:99-100.
- Provenance: ASSUMED. Evidence: shipped CSS. No Godot
  equivalent was located in hud.gd (the port's floating text,
  if any, lives in battle or fx code not read for this pack;
  see Limitations). The animation curve itself is an fx
  surface (X1); the size is inventoried as typography.
- If wrong: damage numbers are the densest text in a big
  salvo; 19 px at 1080 design height is the size every number
  is read at.
- Settles it: a salvo capture in the fx E6 settlement round
  (issue 210), judged with the flash logging.

HD13. Hover tooltip: JS tooltip max-width 330 px at 13.5 px.
Godot hover tip text minimum width s(300).
- Lives in: head.html:81; godot/ui/battle/hud.gd:788.
- Provenance: ASSUMED, both sides; near-agreement (330
  against 300) of the same unmeasured kind as HD9.
- If wrong: tooltips carry weapon and order explanations; the
  width decides whether they read as a glance or a paragraph.
- Settles it: the HD3 capture round.

HD14. The JS battle top bar carries its settings and its
developer surface in the same row: quality, fx mode, shake
mode, follow, AI level, TAA, sound, speed, log toggle, and
restart buttons, plus buttons labelled "Report a problem",
"Copy report", and "Diagnostics".
- Lives in: ui3d.js:63-65.
- Provenance: ASSUMED. Evidence: shipped markup. No record
  separates the player surface from the developer surface in
  the playable build; the Godot port moves the player controls
  to the title settings panel (MN2) and drops the developer
  buttons from the bar, also without a recorded decision.
- If wrong: the playable build shows its debugging tools to
  every player in every battle, and the port's removal of
  them is an unrecorded product decision in the other
  direction.
- Settles it: an owner ruling (one question, no run), then one
  Opus run to apply it per build.

HD15. Panel material: JS HUD panels are a glass style with an
8 px backdrop blur, a gilt border at 20 percent alpha, 6 px
radius, and a heavy drop shadow. Godot panels are flat fills:
panel styleboxes at (0.133, 0.176, 0.267, 0.85) with radius
s(4) and an IRON3 border, over a GLASS colour of
(0.047, 0.07, 0.12, 0.80).
- Lives in: head.html:41; godot/ui/battle/hud.gd:36, 219-224.
- Provenance: ASSUMED, both sides. The blur is also the only
  backdrop-dependent panel treatment in either build: over a
  bright nebula the JS panel and the Godot panel will not read
  alike.
- If wrong: panel legibility over bright scenery is a
  background-dependent failure, invisible on the dark captures
  the project usually judges.
- Settles it: one capture of each build's panel over the
  brightest nebula patch, in the HD1 round.

## 5. Menus and flow screens inventory (MN1 to MN12)

Tallies for this section: 12 entries; MEASURED 0, DERIVED 0,
ANCHORED 0, ASSUMED 12.

MN1. Title sizing law: the Godot title screen fits the game
title on one line at the largest size up to s(84) that fits
88 percent of the width, shrinking in steps of 2. The JS title
is clamp(64 px, 11 vw, 148 px); the JS intro variant is
clamp(72 px, 9 vw, 132 px).
- Lives in: godot/main/title.gd:86-89, 147-157; head.html:
  103, 156; godot/ui/battle/brand.gd (fit_size).
- Provenance: ASSUMED, all three. Three different sizing laws
  for the same name across the two builds and the JS build's
  own two title screens.
- If wrong: the title is the game's first image; vw-based
  sizing also means the frozen build's title changes size
  with window width in a way the port's never will.
- Settles it: title captures at 1440p and 4K in the HD1 round.

MN2. Settings architecture: the JS build splits its options
across the battle top bar (quality, fx, shake, follow, AI,
TAA, sound, speed as individual buttons) and a "Battle view"
panel of view toggles (firing arcs, threat, cut-ins, a test
hull toggle, top-down) at 290 px wide. The Godot port has one
settings panel, on the title screen, with 15 controls.
- Lives in: ui3d.js:63-65; head.html:78; godot/main/title.gd:
  248-295.
- Provenance: ASSUMED, both sides. The two architectures put
  the same decisions in different places: battle-local in the
  playable build, title-only in the port, so a player who
  wants to change shake mid-battle can in one build and
  cannot in the other.
- If wrong: settings placement is a flow decision that will
  be baked into the port's main loop if nobody names it.
- Settles it: an owner ruling on placement (one question),
  applied in the MN3 specification run.

MN3. Settings defaults (Godot): volume 0.8, music volume 0.7,
shake 1.0 (Full), speed 1.0, quality "max", AI "standard",
cut-ins "key", movement "cinematic", full screen true,
TAA false, reduce flashing false, follow activations true,
teaching tips true, sound and music on.
- Lives in: godot/main/main.gd:20 (the settings dictionary);
  godot/main/title.gd:281-295 (the panel that edits it).
- Provenance: ASSUMED. Evidence: shipped defaults. No record
  of a playtest pass over the default set; note also that the
  default says full screen true while godot/project.godot
  boots the window at mode 2 (maximised), so the shipped
  window state and the settings default describe two
  different things until the setting is applied.
- If wrong: defaults are the game most players play; "max"
  quality as the default interacts with the issue 207 scene
  gate, which has not run yet.
- Settles it: the defaults are re-ruled as one block after the
  issue 207 benchmark reports, one owner review round.

MN4. Quality tier naming: the JS quality button's tooltip
names three tiers Ultra, High, and Medium, and describes
Medium as "tuned for phones". The Godot settings choice names
its three tiers Max, High, Low. The campaign screen has a
separate two-state control, "Map detail: High / Low".
- Lives in: ui3d.js:65; godot/main/title.gd:294; godot/ui/
  campaign/campaign_ui.gd:533.
- Provenance: ASSUMED, all three. Three naming sets for what
  the player experiences as one decision, plus a phone
  reference in a PC-only game (section 1.6).
- If wrong: tier names are how the owner and players will
  talk about the issue 207 benchmark results; three
  vocabularies guarantee confusion in exactly that
  conversation.
- Settles it: one naming pass in the consolidated UI
  specification, one Opus run.

MN5. Speed choice values: Normal 1.0, Fast 0.45.
- Lives in: godot/main/title.gd:285.
- Provenance: ASSUMED. The 0.45 is oddly precise for an
  unmeasured value; no capture compares the two speeds.
- If wrong: battle pace is a feel decision (its motion
  parameters are fenced at F3; only the choice's values and
  labels are inventoried here).
- Settles it: the owner's play in the calibration sitting.

MN6. Cut-ins choice: Key moments / Every attack / Off,
default Key moments.
- Lives in: godot/main/title.gd:291; godot/main/main.gd:20.
- Provenance: ASSUMED. The cut-in presentation itself is an
  fx and camera surface (fx audit, destruction audit CM
  domain); the choice's existence, labels, and default are
  the UI gate inventoried here.
- If wrong: the default decides how often the game interrupts
  the player's own framing, which the destruction audit ruled
  is otherwise never taken (issue 212, R1); the interaction
  between that ruling and this default has never been stated
  in one place.
- Settles it: one line in the UI specification recording the
  interaction, after the S-A capture round (issue 212) shows
  death presentation.

MN7. End card: Godot end card title at 34 in the display
face, body at 16, card minimum width s(520). JS end card
heading at 64 px in the blackletter face.
- Lives in: godot/ui/battle/hud.gd:1205-1211; head.html:118.
- Provenance: ASSUMED, both sides; the same face and scale
  schism as HD11 and MN1, at the screen that closes every
  battle.
- Settles it: the HD3 capture round.

MN8. Debrief presentation: there is no debrief screen in
either build. Run-end and battle-end debrief material appears
as paragraphs inside other screens: the story beat debrief as
a gilt paragraph in the campaign screen, and the heir debrief
flow inside the meta screens.
- Lives in: campaign_run.js:417, 469; campaign_meta.js:
  237-300; godot/campaign/campaign.gd:2379-2382; godot/ui/
  campaign/campaign_ui.gd:1288.
- Provenance: ASSUMED. Evidence: the debrief text exists and
  is styled as body text with a colour, in both builds; no
  document specifies a debrief layout, a stats table, or what
  a debrief must show.
- If wrong: the debrief is where a roguelike teaches the
  player why they lost (the run-learning design depends on
  it); an unspecified paragraph is the weakest possible
  carrier for the game's core loop message.
- Settles it: one Opus run drafting a debrief specification
  against the existing text, judged by the owner on one
  mock capture.

MN9. Loading presentation: JS loading is a full-screen 18 px
centred line on the void background. The Godot load screen is
a 43-line script.
- Lives in: head.html:119; godot/main/load_screen.gd.
- Provenance: ASSUMED. Inventoried for completeness; neither
  build states what a loading screen must show (progress,
  tips, or nothing).
- Settles it: folds into the MN8 specification run at no
  extra cost.

MN10. The Godot port contains two campaign presentations: the
3D map UI (section 6) and a 2D campaign fallback UI with its
own scaling law and base sizes (15 and 16, clamp 0.6 to 2.2).
- Lives in: godot/main/campaign_fallback_ui.gd:31, 77, 87;
  godot/main/campaign_host.gd (the host that chooses; not
  read, see Limitations).
- Provenance: ASSUMED. Evidence: the fallback exists and is
  maintained (it loads the current display face, per its line
  32 comment). Which presentation a player actually gets, and
  when, is decided in host code this pack did not read.
- If wrong: two maintained campaign UIs double every future
  campaign UI change, and the fallback's sizes will drift from
  the main UI's exactly as HD5 and HD9 drifted.
- Settles it: one Opus read of the host plus an owner ruling
  on whether the fallback is a shipping surface or a
  development scaffold.

MN11. Credits screen: header at 24, body as running text
including engine and font licence lines.
- Lives in: godot/main/title.gd:345-388.
- Provenance: ASSUMED. Inventoried for completeness; it is
  the only screen that names the fonts, which makes it a
  accidental typography document (section 7).
- Settles it: nothing; folds into any typography pass.

MN12. Choice button pattern: campaign choices are a bold line
with a small line under it, sized by their text; disabled
choices are dimmed to 50 percent opacity and ignore input.
The JS build's choice elements follow the same two-line
pattern in campaign screens.
- Lives in: godot/ui/campaign/choice_button.gd (setup and
  _style); head.html campaign styles (choice classes, second
  style block).
- Provenance: ASSUMED, both sides. The 50 percent disabled
  dim is the only disabled-state rule in either build, and it
  is an opacity, not a colour or a label change.
- If wrong: dimmed-only disabled states are a known
  readability trap at small sizes; event choices are where
  the campaign's story decisions are made.
- Settles it: the campaign capture round (section 6
  settlements), judged on event screens.

## 6. Campaign map inventory (MP1 to MP12)

Tallies for this section: 12 entries; MEASURED 0, DERIVED 0,
ANCHORED 0, ASSUMED 12.

MP1. JS map form: the sector map is a 2D SVG, viewBox 900 by
450 (portrait 450 by 900), styled to width 100 percent with
max-width 1400 px and max-height calc(100vh - 230 px), with
role img and an aria-label "Sector map".
- Lives in: campaign_run.js:52.
- Provenance: ASSUMED. Evidence: shipped rendering code. The
  1400 px and 230 px figures have no stated source.
- If wrong: the map is the campaign's home screen; its frame
  decides how much of a sector reads at once.
- Settles it: superseded as a live question by MP6 (the port
  replaces the form); the JS figures stand as the record of
  what players use today.

MP2. JS node geometry: node radius 19, boss radius 26; ring
stroke 2.5 for the current and available nodes, 1.5
otherwise; available nodes carry a pulsing ring animated
between r+3 and r+9 over 2.4 s, repeating.
- Lives in: campaign_run.js:37-42.
- Provenance: ASSUMED. Evidence: shipped constants. The pulse
  has no off switch (see AC7).
- If wrong: node size against the 900-unit viewBox sets the
  map's click targets and its visual weight; the boss at 26
  is only 37 percent larger than a normal node.
- Settles it: the MP6 comparison; the JS values are the
  baseline the port's sizes should be judged against.

MP3. JS node labels: encounter name at 12.5 px under the node,
map name at 10.5 px above it in #7f8fa6, and a "Nemesis" tag
at 12 px bold in #ff6b5a above boss-type nodes.
- Lives in: campaign_run.js:43.
- Provenance: ASSUMED. Evidence: shipped constants. Two
  colours here exist nowhere in the shared palette variables
  (head.html:12-15): #7f8fa6 and the Nemesis red #ff6b5a (the
  palette's own red family is #d0493f and #e27f74, TY section
  and HD10 note).
- If wrong: the Nemesis tag is the map's highest-stakes label;
  its colour is a one-off that no palette decision ever
  approved.
- Settles it: the palette consolidation in the UI
  specification run.

MP4. JS route lines: travelled edges gilt at width 3;
available edges from the current node gilt at 55 percent,
dashed 6 5, width 2; all other edges bone at 13 percent,
width 2.
- Lives in: campaign_run.js:36.
- Provenance: ASSUMED. Evidence: shipped constants; the three
  states (done, reachable, locked) are distinguished by
  colour, width, and dash together, the map's one redundant
  encoding (compare AC1).
- Settles it: the MP6 comparison captures.

MP5. Map structure as layout: the sector map is generated as
7 columns; a shipyard is guaranteed in column index 3, and a
drydock or shipyard in the second-to-last column.
- Lives in: godot/campaign/campaign.gd:856, 883-885.
- Provenance: ASSUMED. Evidence: shipped generator code (the
  JS generator producing the same structure was not read; see
  Limitations). Column count is the map's real size gate: it
  sets run length more directly than any visual constant.
- If wrong: 7 columns is the campaign's pacing skeleton,
  currently resting on a generator constant with no design
  document behind it in the record read.
- Settles it: out of this audit's gift to re-derive (it is a
  campaign design constant); inventoried so the legs can say
  whether its presentation consequences (MP1, MP6) have ever
  been judged.

MP6. Godot map form: the port replaces the SVG map with a 3D
scene. Stops sit on orbit radii from R_IN 21 to R_OUT 52
units, starting angle 190 degrees, span 200 degrees; each
stop has a ring of radius 2.4; the Hollow Sun's shadow radius
is 5.0; the camera direction is fixed at (0, 0.79, 0.62).
- Lives in: godot/ui/campaign/map3d.gd:33-41.
- Provenance: ASSUMED. Evidence: shipped constants. This is
  the largest presentation divergence in the pack: the
  campaign's home screen changed medium, from a flat diagram
  to a lit 3D orrery, and these six constants are its entire
  written design record in the files read.
- If wrong: everything the player learns about route reading
  from the JS map (MP2 to MP4 encodings) must be re-taught by
  a scene whose readability has never been captured against
  the SVG baseline.
- Settles it: side-by-side captures, SVG map and 3D map of
  the same sector, judged by the owner; one Codex run plus
  one owner review round.

MP7. Flight time: moving between stops takes FLIGHT_SECONDS
2.4.
- Lives in: godot/ui/campaign/map3d.gd:72.
- Provenance: ASSUMED. Evidence: shipped constant. (The same
  2.4 appears as the JS pulse period, MP2; no relation is
  recorded.)
- If wrong: map traversal time is paid on every move of every
  run; too long reads as loading, too short makes the map
  feel weightless.
- Settles it: the MP6 capture round, at two flight times.

MP8. Danger bands (Godot only): node danger is banded at
ratios 0.8, 1.05, and 1.4 into Easy, Even, Hard, and Deadly,
coloured #7ddc6a, #d0a64b, #f0883a, and #e2453a. The
underlying estimate is computed from the same budget numbers
the game uses to build enemy fleets, against the player's
fleet power.
- Lives in: godot/ui/campaign/map_intel.gd:13 (BANDS), 1-8
  and 17-24 (the estimate's stated derivation).
- Provenance: ASSUMED for the band thresholds and colours;
  the estimate itself is derived from game numbers by the
  file's stated method. The JS map shows no danger read at
  all, so the port adds an information channel the playable
  build does not have, with unmeasured cut points: a fight at
  1.04 reads Even and at 1.06 reads Hard.
- If wrong: danger bands steer route choice; mis-set cut
  points systematically mislabel the campaign's hardest
  decisions.
- Settles it: a Monte Carlo comparison of band labels against
  measured bot outcomes per band (the campaign sim harness
  exists), one-time script build, no owner round for the
  data; labels re-ruled on the result.

MP9. Two quality controls govern the 3D map: the title
settings Graphics quality (Max, High, Low) and a campaign
screen button, "Map detail: High / Low", which is not a key
in the settings dictionary. Map content counts follow the
map toggle: clouds 7 against 4, drones 4 against 2 and 6
against 3; the positional shadow atlas is 4096 on high and
0 otherwise.
- Lives in: godot/ui/campaign/campaign_ui.gd:533; godot/ui/
  campaign/map3d.gd:126, 304, 356, 372; godot/main/main.gd:20.
- Provenance: ASSUMED. Evidence: shipped code. Because the
  map toggle lives outside the settings dictionary, the two
  controls can disagree about the same scene, and nothing
  records which wins.
- If wrong: the map is the one screen where the port spends
  3D effort outside battle; an ambiguous quality path makes
  its cost unreviewable (and invisible to the issue 207
  benchmark family).
- Settles it: one Opus read to state the precedence, then the
  MN4 naming pass.

MP10. Map legend: the Godot campaign screen lists node types
in a text legend at 13, with elite and boss names in BLOOD.
The JS legend renders a 26 px icon chip per node type beside
its name.
- Lives in: godot/ui/campaign/campaign_ui.gd:548;
  campaign_run.js:53.
- Provenance: ASSUMED, both sides; a quiet downgrade in the
  port (icon chips to text only) with no record.
- Settles it: the MP6 capture round.

MP11. Node intel text: the encounter preview shows the
encounter name in gilt, the archetype line in blood, the
modifier in gilt, and a reward line coloured by the patron's
colour or #bfb6a0. The port mirrors the structure with its
own label helpers.
- Lives in: campaign_run.js:55; godot/ui/campaign/
  campaign_ui.gd:558-572, 621-629.
- Provenance: ASSUMED, both sides. #bfb6a0 is another one-off
  colour outside the palette variables (bone2 is #b3aa95).
- If wrong: the preview is where route decisions are actually
  made; its colour code (what gilt means, what blood means)
  is nowhere written down.
- Settles it: the palette and semantics consolidation in the
  UI specification run.

MP12. Map prop colour rule: station props on the 3D map are
lerped toward neutral warm greys, with code comments
recording the intent (accent toned down, "no purple cast").
- Lives in: godot/ui/campaign/map3d.gd:281, 342-366.
- Provenance: ASSUMED. Evidence: shipped code and comments;
  the rule exists only as comments beside lerp factors (0.85,
  0.4), not as a stated standard.
- If wrong: faction identity on the map (IC7) is being
  deliberately muted by an unrecorded amount; the muting
  factor is as much a colour gate as any palette value.
- Settles it: the MP6 captures, with one unmuted variant.

## 7. Typography and text inventory (TY1 to TY10)

Tallies for this section: 10 entries; MEASURED 0, DERIVED 0,
ANCHORED 2, ASSUMED 8.

TY1. The display face schism: the frozen JS build sets its
title, top bar, banner, and end card in a blackletter face
(--gothic: "UnifrakturMaguntia", "Old English Text MT",
Georgia, serif). The Godot port retired the blackletter in
lore round 5: headers use Michroma, small labels Oxanium
small caps, body Barlow Semi Condensed.
- Lives in: head.html:17, 32, 43, 84, 118; godot/ui/battle/
  brand.gd:1-5; godot/ui/battle/fonts and godot/ui/campaign/
  fonts (the font files themselves).
- Provenance: ANCHORED on the Godot side (a recorded lore
  round decision, brand.gd:1-5); the JS side is the frozen
  incumbent. The schism itself is the inventory item: the
  currently playable game and its replacement present two
  different brand faces, and no document states when the
  player-facing change is supposed to happen (at cutover,
  presumably, but that is this pack's inference, marked as
  such).
- If wrong: brand recognition is the face; a silent face
  change at cutover will read as a different game to anyone
  who played the browser build.
- Settles it: an owner ruling confirming the cutover is the
  change point (one question, no run).

TY2. Body face: Barlow Semi Condensed on both sides (JS
--ui stack with Arial Narrow and system fallbacks; Godot
loads the TTF directly, Regular and SemiBold).
- Lives in: head.html:16; godot/ui/battle/hud.gd:84-85;
  godot/ui/battle/brand.gd (BODY_DIR).
- Provenance: ANCHORED. Evidence: the one typographic choice
  the two builds share exactly, including the fallback stack
  difference (the browser can fall back to Arial Narrow; the
  port has no fallback if the file loads, and a code fallback
  path if it does not, brand.gd load_font).
- Settles it: nothing; the pack's one clean typography item.

TY3. Base size per screen: battle theme default 15 (Godot)
and JS battle body 15 px; Godot campaign theme default 18
with RichText and buttons at 17; Godot campaign fallback at
15 and 16; JS campaign body 16 px.
- Lives in: godot/ui/battle/hud.gd:217; head.html:23;
  godot/ui/campaign/campaign_ui.gd:139-157; godot/main/
  campaign_fallback_ui.gd:77, 87; head.html:142.
- Provenance: ASSUMED, all six. Four distinct base sizes (15,
  16, 17, 18) across the game's screens, each locally
  plausible, never stated as a system. A player moving from
  battle to campaign crosses at least one size boundary.
- If wrong: inconsistent base sizes read as inconsistent
  polish, and they make every other size in this pack
  non-comparable across screens.
- Settles it: one base-size rule in the UI specification,
  judged on the HD1 and MP6 capture rounds.

TY4. The three scaling laws disagree: battle HUD k clamps at
0.6 to 2.2; campaign UI k clamps at 0.6 to 2.5; campaign
fallback k clamps at 0.6 to 2.2. All three key on viewport
height divided by 1080.
- Lives in: godot/ui/battle/hud.gd:94-95; godot/ui/campaign/
  campaign_ui.gd:105; godot/main/campaign_fallback_ui.gd:31.
- Provenance: ASSUMED, all three. Above 2376 px of window
  height, campaign text keeps growing after battle text has
  stopped; below 648 px both sit at the 0.6 floor.
- If wrong: at the owner's 4K target the disagreement is
  latent (2160 gives k 2.0 in all three), but any taller or
  windowed arrangement exposes it, and the port contains
  three copies of a law that should exist once.
- Settles it: consolidation into one shared scale function,
  one Opus run; the clamp values re-ruled in the HD1 round.

TY5. Height-only scaling: no scaling law in either build
reads window width. Panel and column geometry in the Godot
HUD is width-managed by the layout pass, while every type
size is height-derived.
- Lives in: godot/ui/battle/hud.gd:1-13 (layout header),
  94-95; head.html:121-132 (the JS build's two width-driven
  media queries are the exception that proves the rule).
- Provenance: ASSUMED. Evidence: shipped code. At 4K, k is
  2.0, so the 15 base renders at 30 and the 12 pt nameplate
  name (HD7) at 28; no capture in the record judges text at
  that size against the board it labels.
- If wrong: type sized for a 1080p living-room assumption may
  crowd the board at 4K or shrink below reading on a small
  window, and neither failure appears at the design point.
- Settles it: the HD1 capture round at 1440p, 4K, and one
  small windowed size.

TY6. Smallest text: JS orders buttons carry an 11.5 px small
line; the JS map name label is 10.5 px; the JS targeted tag
is 10 px. Godot's smallest located sizes are the 12 pt "NEW"
roster tag and the 13 pt map legend.
- Lives in: head.html:68, 89; campaign_run.js:43; godot/ui/
  battle/hud.gd:534; godot/ui/campaign/campaign_ui.gd:548.
- Provenance: ASSUMED. Evidence: shipped values. No minimum
  text size rule exists anywhere in the files read; the floor
  is simply wherever each implementer stopped.
- If wrong: 10 px text at the 1080 design point is below
  comfortable reading for a substantial share of players, and
  it carries gameplay information (which map, which orders).
- Settles it: a minimum-size rule in the UI specification,
  with the HD1 captures as the evidence.

TY7. The control scheme is one text block: the Godot battle
help is a single RichText paragraph at 12 containing the
entire control scheme (roughly 30 distinct inputs); the JS
build's key list is a 12 px block at line-height 1.9.
- Lives in: godot/ui/battle/hud.gd:648; head.html:80.
- Provenance: ASSUMED, both sides. No chunking, grouping, or
  progressive disclosure exists in either build's version of
  the game's only controls reference.
- If wrong: a dense paragraph is where control learning goes
  to die; the teaching cards (TY8) cover four battle actions
  and leave the rest to this block.
- Settles it: the owner's read in the capture round; any fix
  is a text-layout job, one Opus run.

TY8. Teaching cards: six campaign cards (map, Nemesis clock,
rewards, shipyard, the next run, skill tree) plus battle tips
shown one at a time, all behind one shared off switch. The
longest campaign card (the sector map) runs to several dense
sentences.
- Lives in: godot/ui/campaign/campaign_tips.gd:1-13;
  godot/ui/battle/hud.gd:1-13 (tip card in the layout header).
- Provenance: ASSUMED. Evidence: shipped text. No length,
  reading level, or one-idea-per-card rule exists; the shared
  off switch means a player who dismisses battle tips also
  loses campaign teaching.
- If wrong: the cards are the game's tutorial; their density
  decides whether new players learn the loop or click past
  it.
- Settles it: the playtest checklist route (issue 202's
  successor captures), owner-judged; no standalone run.

TY9. Display text shrink floor: fit_size shrinks display text
in steps of 2 until it fits one line, but stops at 12.
- Lives in: godot/ui/battle/brand.gd (fit_size).
- Provenance: ASSUMED. Evidence: shipped code. The floor
  interacts with MN1: a long title on a narrow window stops
  shrinking at 12 and overflows or wraps by other means.
- Settles it: folds into the TY4 consolidation run.

TY10. Line height: JS body line-height 1.4, log 1.45. No
line-spacing override was located in the Godot HUD theme, so
battle text there takes the engine and font default.
- Lives in: head.html:23, 46; godot/ui/battle/hud.gd:213-246
  (the theme construction, searched for spacing settings).
- Provenance: ASSUMED (JS values) and unlocated (Godot side);
  stated plainly as a gap rather than a value.
- If wrong: condensed faces at default spacing are a known
  tight-read; the two builds may already differ invisibly.
- Settles it: one line in the UI specification after the HD1
  captures.

## 8. Icons and markers inventory (IC1 to IC8)

Tallies for this section: 8 entries; MEASURED 0, DERIVED 0,
ANCHORED 2, ASSUMED 6.

IC1. Node iconography: the JS map draws a per-type SVG glyph
inside each node (nodeIcon) and reuses the glyphs in the
legend. The Godot 3D map replaces glyphs with 3D props per
stop type (station, dock frame, gantry, clouds), built in
map3d.gd and map3d_props.gd.
- Lives in: campaign_run.js:5, 53; godot/ui/campaign/
  map3d.gd:281-390; godot/ui/campaign/map3d_props.gd.
- Provenance: ASSUMED, both sides; two unrelated icon systems
  for the same node types, so no icon survives the cutover.
- If wrong: node-type recognition learned in the playable
  build resets to zero in the port.
- Settles it: the MP6 capture round, with a recognition pass
  (owner names each stop type from the capture).

IC2. Reward badge: a node's payout is badged by a patron
sigil, a circle of radius 10 in the patron's colour with the
patron's glyph letter, plus a star when the reward is rare
or better.
- Lives in: campaign_run.js:16-20.
- Provenance: ASSUMED. Evidence: shipped drawing code. The
  badge's size relative to the node (10 against 19, MP2) and
  its colour source (patron colours, a data table not read
  for this pack) are unrecorded choices.
- Settles it: the MP6 round; patron colour table read folds
  into the specification run.

IC3. Flagship marker: the flagship is marked by a gilt star
before its name. JS does it in CSS (a star character injected
before the plate name, in gilt); Godot does it in the label
text (a star character prefixed in the roster and panel name
strings).
- Lives in: head.html:77; godot/ui/battle/hud.gd:526, 598.
- Provenance: ANCHORED. Evidence: the convention is ported
  deliberately and identically in meaning; only the mechanism
  differs (presentation layer against string content, which
  means the port's star is now part of the ship's name string
  anywhere that string is reused, including logs).
- If wrong: a marker baked into strings leaks into saves,
  logs, and screen readers as a literal character.
- Settles it: one line in the UI specification.

IC4. Elite marker: JS plates suffix the name with " - elite"
in gilt, via CSS. No equivalent plate marking was located in
the Godot HUD's plate construction.
- Lives in: head.html:91; godot/ui/battle/hud.gd:966-1010
  (the plate builder, searched).
- Provenance: ASSUMED (JS side); unlocated (Godot side),
  stated as a gap. Elites are a difficulty signal the player
  is meant to read before engaging.
- Settles it: the HD7 capture round, checking elite plates in
  both builds.

IC5. Targeted tag: JS plates carry a "Targeted" tag at 10 px,
uppercase, letter-spaced, in #ff7466 on a dark red ground,
with a second variant used inline in text. No equivalent was
located in the Godot plate builder.
- Lives in: head.html:89-90; godot/ui/battle/hud.gd:966-1010.
- Provenance: ASSUMED (JS side); unlocated (Godot side). The
  tag's red #ff7466 is a third one-off red (see MP3).
- If wrong: focus-fire state is core battle information; if
  the port dropped the tag, it dropped a read, not a
  decoration.
- Settles it: the HD7 capture round.

IC6. Faction crests: each faction has a crest drawn as clean
vector art from the lore bible's description, in the
faction's colours: a half sun over a broken link (Crusade), a
wedge in a ring of five linked nodes (Hegemony), welded scrap
teeth around three claw slashes (Hullbreakers), a ring of
nine open mouths (Chorus), a cracked lens with one beam
(Glasswrights), an eclipsed sun (Eclipse). Resolution order:
the portraits helper's crest if it exists, else an SVG file,
else the procedural drawing.
- Lives in: godot/ui/campaign/crest.gd:1-14 (the header is
  the written spec); godot/ui/career/crest.gd (a second copy
  for the career screen).
- Provenance: ANCHORED. Evidence: the file header ties the
  set to lore round 8, approved R59. The three-step fallback
  chain and the existence of two crest implementations
  (campaign and career) are implementer choices recorded
  nowhere else.
- If wrong: crests are the factions' logos; two
  implementations will drift like every other duplicated
  constant in this pack.
- Settles it: the TY4-style consolidation, one Opus run,
  only if the two copies are shown to differ.

IC7. Faction colour in UI: data.js assigns each faction a
hull, trim, and glow hex (Crusade glow #ff7a2a, Hegemony
#5fa0ff, Hullbreakers #e0402c, Chorus #d6d24a, Glasswrights
#9fffd2, Eclipse #3dff6a). In UI these colours enter through
the 3D map's per-faction looks and the crests; the battle HUD
palette itself is faction-neutral except for the FRIEND and
FOE name colours (HD10).
- Lives in: data.js:112-124; godot/ui/campaign/
  map3d_system.gd (the LOOKS table, referenced by crest.gd
  and map3d.gd; its values were not read for this pack);
  godot/ui/battle/hud.gd:21-38.
- Provenance: ASSUMED. Evidence: the data table is shipped;
  no document states a rule for where faction colour may
  appear in UI, how much of a screen it may claim, or whether
  the enemy's faction should colour anything in battle. The
  motif ownership ruling (F4) governs imagery, not colour
  usage.
- If wrong: faction identity in battle currently rides on
  ship models alone; whether UI should reinforce it (enemy
  name in faction glow, map stops in faction colour) is an
  open design question masquerading as a settled one.
- Settles it: an owner ruling (one question) plus the MP6
  captures.

IC8. Enemy and AI signalling colour: the Godot HUD signals
enemy and AI state in a lavender-purple family that appears
nowhere in the JS palette variables: the enemy-acting chip
text #e2d2ff on (0.086, 0.04, 0.157, 0.88) with border
#a64dff, and the phase bar fill #b98cff with border #a64dff.
The JS foe colour #c9a2ff (HD10) is the family's only relative
in the playable build.
- Lives in: godot/ui/battle/hud.gd:851-858, 1475-1495.
- Provenance: ASSUMED. Evidence: shipped constants; no
  palette entry, no stated rule that purple means enemy in
  UI, and the family is close enough to the Glasswrights'
  and Hegemony's glows (IC7) to risk confusion.
- Settles it: the palette consolidation in the UI
  specification run.

## 9. Accessibility and settings inventory (AC1 to AC7)

Tallies for this section: 7 entries; MEASURED 0, DERIVED 0,
ANCHORED 0, ASSUMED 7. This domain's items are mostly
absences; the tally pattern is the finding.

AC1. No colour-vision support exists in either build: no
colourblind mode, no palette variant, no redundant encoding
rule. The search covered every file read for this pack; no
colour-vision or accessibility identifier appears in any of
them. Nameplate friend-or-foe rests on green against lavender
(HD10) plus position and context; the JS map's route states
(MP4) are the honourable exception, encoded three ways.
- Lives in: absence across head.html, ui3d.js, campaign_run.
  js, godot/ui/battle/hud.gd, godot/ui/campaign/
  campaign_ui.gd, godot/main/title.gd.
- Provenance: ASSUMED (an unchosen absence). Note the owner's
  Nov 6, 2026 direction in the graphics programme added a
  colour-vision readability run over ship sheets as an
  addendum to issue 208; that run covers ship paint, not UI,
  and does not settle anything here.
- If wrong: roughly 1 in 12 male players reads red-green
  distinctions poorly; the game's IFF, danger bands (MP8),
  and hull-low state (HD9) all speak colour first.
- Settles it: a CVD simulation pass over the existing UI
  captures (one-time script build), then owner ruling on any
  redundant encodings it shows failing.

AC2. No text or UI scale setting exists. The settings panel
has no text-scale or UI-scale entry; the only lever a player
has over UI size is the window size, through the height law
(HD1, TY4).
- Lives in: godot/main/title.gd:281-295 (the full settings
  list); godot/main/main.gd:20.
- Provenance: ASSUMED (an unchosen absence).
- If wrong: the 1440p floor and 4K goal are resolution
  targets for rendering; reading comfort is a separate axis
  the game currently cannot adjust at all.
- Settles it: an owner ruling on whether a UI scale setting
  is in scope (one question); implementation, if any, is one
  Opus run against the consolidated scale function (TY4).

AC3. Reduce flashing is a settings toggle, default off. (The
cap it exposes is fenced at F2 and is not re-audited.)
- Lives in: godot/main/title.gd:288; godot/main/main.gd:20;
  ui3d.js:65 (the JS build exposes the same control as a top
  bar button, "Reduce flashes and strobing lights").
- Provenance: ASSUMED as a default. Evidence: shipped
  default false in the settings dictionary. No record weighs
  default-off against default-on for a game with this much
  salvo flash (fx audit E6's worst case has never run).
- If wrong: the players the toggle exists for meet the
  unmitigated game first, in the biggest battles, before they
  find the setting.
- Settles it: folds into the MN3 defaults ruling after issue
  207.

AC4. Screen shake choice: Full 1.0, Reduced 0.5, Off 0.0;
default Full.
- Lives in: godot/main/title.gd:289; godot/main/main.gd:20.
- Provenance: ASSUMED. Evidence: shipped values. The 0.5
  midpoint and the Full default have no capture or playtest
  behind them in the record read. (Shake amplitude itself is
  a destruction audit item, CM7; only the choice's steps and
  default are inventoried here.)
- Settles it: the owner's play in the calibration sitting,
  where shake is judged anyway (issue 212, S-A and S-E).

AC5. Focus visibility disagreement: the title screen sets
every button to full keyboard focus, with a comment citing
WCAG 2.1.1 (keyboard reachability); the JS build draws a 2 px
gilt focus outline. The Godot battle theme sets the Button
focus stylebox to an empty stylebox, so a focused battle
button shows no outline of its own.
- Lives in: godot/main/title.gd:197; head.html:26;
  godot/ui/battle/hud.gd (the _theme construction, focus
  stylebox set to StyleBoxEmpty).
- Provenance: ASSUMED. Evidence: shipped code on all three
  sides. The battle HUD is the most keyboard-driven screen in
  the game (HD7's help text lists about 30 keys, TY7), and it
  is the one screen where focus is invisible.
- If wrong: keyboard and controller players cannot see where
  they are on the game's main screen.
- Settles it: one stylebox in the UI specification run; the
  cheapest fix in this pack.

AC6. The campaign map quality toggle lives outside the
settings system (see MP9): it is not persisted in the
settings dictionary, and its precedence against the Graphics
quality choice is unstated.
- Lives in: godot/ui/campaign/campaign_ui.gd:533;
  godot/main/main.gd:20.
- Provenance: ASSUMED. Inventoried here as a settings-scope
  gate: the settings panel is not the whole settings surface,
  and the part outside it is invisible to anyone auditing
  options from the panel.
- Settles it: the MP9 Opus read.

AC7. No motion-comfort control covers UI animation: the JS
map's available-node pulse repeats indefinitely at 2.4 s, the
Godot map flies drones and patrols ambiently, and floating
text animates on its curve (HD12); the motion-related
settings (Speed, Movement, shake, AC4) govern battle
choreography, not UI motion, and there is no reduce-motion
entry anywhere.
- Lives in: campaign_run.js:42; godot/ui/campaign/map3d.gd
  (drone and patrol animation); godot/main/title.gd:281-295.
- Provenance: ASSUMED (an unchosen absence).
- If wrong: ambient map motion is constant and peripheral,
  exactly the category motion-sensitive players need a
  switch for.
- Settles it: folds into the AC2 owner ruling as a second
  question if the owner wants it.

## 10. Chair observations (hypotheses for the legs to test)

These are the chair's starting suspicions, recorded so the
legs can attack or confirm them. They are INFERRED, they are
not findings, and a leg that merely repeats them has done no
work.

Pack tally, for the record: 64 items. MEASURED 0, DERIVED 0,
ANCHORED 5, ASSUMED 59. This is the least measured stack the
programme has audited: the fx stack had 13 measured in 76,
the graphics stack 4 in 65, the environment stack 1 in 74,
the destruction stack 0 in 40. UI joins destruction at zero,
with a difference: destruction's zeroes were physics values
nobody had instrumented, while UI's values are on screen in
every session and could have been captured at any time.

H1. The port transcribed the JS build's UI by eye, not by
table, and the transcription drift is the stack's signature.
Exact where a value was a named colour copied from a variable
table (HD10, off by one in two channels), near-miss where a
value had to be re-measured from a running layout (panel 340
to 316, HD5; tooltip 330 to 300, HD13; hull-low 0.35 to 0.34,
HD9), and far off where a value was re-derived from feel
(nameplate 54 to 90, HD7; banner 84 to 46, HD11). If H1
holds, the right settlement is not 64 small rulings but one
diff: a scripted comparison of the two builds' UI constants,
with every difference forced to be either adopted or reverted
on the record.

H2. The 1080 height law is this stack's 306k ceiling: a
single denominating assumption (design at 1080p, scale by
height, clamp) that nobody has judged at the resolutions the
owner actually targets, copied three times with two different
clamps (HD1, TY4, TY5). The graphics stack's disease was
per-asset caps; this stack's is a per-screen formula. The
calibration sitting (issue 212) already puts the owner at
1440p and 4K with a camera in hand; the UI captures proposed
in this pack ride it for free, which makes this the cheapest
hinge in the pack to settle.

H3. The campaign map changed medium without a presentation
spec, and its encodings did not survive the move. The SVG
map's reads (node size for boss, pulse for available, dash
for reachable, icon chips in the legend, labels above and
below) were a small visual language (MP2 to MP4, MP10). The
3D map's six constants (MP6) plus its prop builders are a
scene, not a language, and two of the old language's words
(elite marking, IC4; targeted-style emphasis) have no located
equivalent anywhere in the port. The legs should say whether
the 3D map needs its encodings re-specified as a system, or
whether the scene teaches itself in play, and what capture
would prove it.

H4. Accessibility in this stack is a settings panel, not a
system. The comfort toggles that exist (flash, shake) are
real, but the structural items were never items: no minimum
text size (TY6), no UI scale setting (AC2), no colour-vision
support or simulation result (AC1), invisible focus on the
most keyboard-driven screen (AC5), unswitchable ambient
motion (AC7). Each absence is individually explainable as
scope; together they mean accessibility has only ever been
added where a toggle was easy. AC5 is the cheapest fix in the
pack and AC1 the most consequential test; both are one
script build or less.

H5. The playable build never separated its player surface
from its developer surface (HD14: report, copy-report, and
diagnostics buttons in the battle bar; a test-hull toggle in
the battle settings, MN2), and the port silently separated
them by deletion. Neither state was decided. This is the one
hypothesis whose settlement is purely a ruling, and it has a
deadline hiding in it: the decision is free now and expensive
after the port's UI is treated as final.

H6. One-off colours accumulate because there is no palette
gate for UI. The palette variables name 15 colours; this pack
found at least five more in service (Nemesis red #ff6b5a,
MP3; map label blue #7f8fa6, MP3; reward grey #bfb6a0, MP11;
targeted red #ff7466, IC5; the AI lavender family, IC8), each
locally sensible. The JS CSS itself disagrees with itself
once: the variable --blood is #d0493f (head.html:14) while
the .blood class that text actually uses is #e27f74
(head.html:33), and the port adopted #e27f74 (hud.gd BLOOD),
so the variable is dead and the class is the truth. A palette
is a gate like any other: currently it binds nothing because
nothing checks additions against it.

H7. Text density is the unmeasured half of readability. The
ship standards measure pixels and luma; nothing in the
programme has ever measured words: the help paragraph carries
about 30 inputs in one block (TY7), the longest teaching card
runs to several dense sentences (TY8), and the debrief, the
screen meant to teach the run loop, has no specified form at
all (MN8). If the legs agree, the settlement is a text budget
stated as a specification (what each surface must show, in
what order), not a word cap, which would be exactly the kind
of assumed gate this programme exists to remove.

## 11. Limitations and unverified list

- The stylesheet exists twice: head.html and an inline copy
  inside voidsworn-3d.html. Values cited from head.html were
  spot-checked against the inline copy (palette variables,
  body sizes, the min-width 2200 media query) and matched at
  every spot checked; a full diff was not run, so a divergence
  between the two copies beyond the spots checked is possible
  and would itself be a finding.
- godot/scenes/battle/battle.gd (4,707 lines) was downloaded
  but only searched, not read: whether the port caps its
  underlying log array (HD6), and where its floating combat
  text lives (HD12), are stated as unlocated, not as absent
  from the file.
- godot/main/campaign_host.gd was not read: which campaign
  presentation ships, and when the fallback UI (MN10)
  appears, is unverified.
- godot/ui/campaign/map3d_system.gd's LOOKS table (per-faction
  map colours, IC7) was not read; its existence and use are
  cited from crest.gd and map3d.gd.
- The JS map generator (the code that builds the cols
  structure the SVG map renders, MP5) was not read; MP5 cites
  the Godot generator only.
- The nameplate name's showing rules in the JS build (HD7):
  the base opacity and transition were read; the state classes
  that raise it were not fully traced.
- Scene files (battle.tscn, campaign.tscn, main.tscn) were
  not parsed; any UI constant set in a scene rather than a
  script is outside this pack.
- Patron colours (IC2) live in a data table not read for this
  pack.
- FINDINGS.md and LOOP.md were not re-read for this pack; the
  fenced rulings in section 2 are taken from the commissioning
  record and the cited issues. If a FINDINGS ruling already
  settles an inventoried item, the legs cannot see it, and
  the chair will catch it at screening.
- No captures were run for this pack. Every settlement
  proposed is priced but not yet executed.

## 12. Leg prompts

Three writer legs and one ideation leg. The three writer legs
(blind Rey, DeepSeek, Qwen) run from this pack alone, in
parallel, without seeing each other, under the single writer
prompt below, used identically for all three. The Flash
ideation leg runs after them under its own prompt.

Context the legs cannot see and the chair records here: the
programme's usual review leg is Argon (Gemini, Google AI
Pro). The owner's Google AI Pro subscription lapsed on Nov 5,
2026, so Argon is unavailable and no review leg runs on this
audit. In its place, per the owner's Nov 6, 2026 ruling, a
Gemini Flash leg runs explicitly in the ideation seat: ideas
and challenges only, never a reviewer, never a screener; its
claims are leads, not evidence. The blind Rey writer leg's
disposition table therefore governs as the spine unless the
chair rules otherwise at synthesis.

Disposition ground rule, from the owner's Nov 6, 2026
rulings, binding on every writer leg: assumed and anchored
numeric gates stop binding. Do not propose re-deriving a
number to a new fixed value as the default settlement.
Replacements are measurements, consolidated specifications,
or the owner's eye on captures. A leg that proposes a fresh
cap or a fresh fixed value must say what measurement earned
it. Absences (section 1.2) take dispositions like any other
item: KEEP means the absence stands as a decision, REPLACE
means name the addition and its cost.

The lenses, named by the owner and used identically in every
writer leg:

- Game dev lens: does this gate bind real performance,
  gameplay, or input? Is it denominated in what the engine or
  the player actually pays? What happens in a real battle, on
  a real map, at the owner's resolutions (1440p floor, 4K
  goal), not at the 1080 design point?
- Graphic designer lens: does this gate buy real hierarchy,
  readability, or identity? Which values are a system and
  which are accidents that merely look like one? Who pays
  when a size, colour, or encoding is wrong: the first-time
  player, the returning player, or the player with low vision
  or colour-vision deficiency?
- Agent lead lens: can the build pipeline produce work
  against this gate and measure the result? Is it enforceable
  in a review, on a capture the owner judges, or does it hide
  in a constant, a stylesheet copy, or a duplicated
  implementation nobody diffs? Does it waste runs: rebuilds,
  re-reviews, per-screen adjudication?

Cost units, the only ones permitted: Codex runs (one-hour cap
per run), Opus runs, one-time script builds, per-asset
unattended runs, owner review rounds. State one-time and
recurring costs separately.

---

### Writer leg (blind) - one prompt, used identically for the blind Rey, DeepSeek, and Qwen legs

You are a blind reviewer on a game project's user interface
standards. One file is your complete evidence and your
complete instruction: PACK.md, the evidence pack for a red
team of the UI, menu, and campaign map stack of the game
Embers of the Hollow Sun. You have no other sources. Do not
browse, do not use outside knowledge of this project beyond
what the pack contains, and do not invent facts the pack does
not hold.

Task: answer the question in PACK section 1.4 for the
inventory in PACK sections 4 to 9 (HD1 to HD15, MN1 to MN12,
MP1 to MP12, TY1 to TY10, IC1 to IC8, AC1 to AC7), in light of
the standing rulings in PACK section 1.6, the fenced rulings
in PACK section 2, the cross-references in PACK section 3,
and the limitations in PACK section 11. The chair's
observations in PACK section 10 are hypotheses to test, not
conclusions to repeat.

Produce one report with exactly these parts:

1. Verdict: one of THE STACK HOLDS, THE STACK HOLDS ONLY WITH
   REPLACEMENTS, or THE STACK DOES NOT HOLD, applied to the
   UI stack as a whole, followed by the three inventory items
   your verdict most depends on, named by item number (they
   may be from any domains, but say why those three). A
   verdict of THE STACK HOLDS must state what evidence, if it
   appeared, would change it.
2. Game dev lens: attack every inventory item, HD1 to HD15,
   then MN1 to MN12, then MP1 to MP12, then TY1 to TY10, then
   IC1 to IC8, then AC1 to AC7, in order, one entry per item:
   does it bind real performance, gameplay, or input, is it
   denominated in what the engine or the player actually
   pays, and what does its being wrong cost in a real session?
   An entry may be one line where the lens genuinely finds
   nothing; silence on an item counts as a miss. Mark each
   entry OBSERVED (present in the pack; cite the pack section)
   or INFERRED (your reasoning; say what it rests on). If the
   pack lacks a fact you need, write NOT IN PACK.
3. Graphic designer lens: the same items in the same order,
   for the craft of interface design: which values form a
   system and which are accidents, which buy hierarchy,
   readability, or identity, which tax them without buying
   any, and what each error costs on the screen.
4. Agent lead lens: the same items in the same order, for
   production: can the pipeline build to it, can a review
   measure it on the owner's captures or does it hide in a
   constant, a duplicated stylesheet, or a duplicated
   implementation, and where does it waste runs (rebuilds,
   re-reviews, per-screen adjudication)?
5. Disposition table: every item, HD1 to HD15, MN1 to MN12,
   MP1 to MP12, TY1 to TY10, IC1 to IC8, AC1 to AC7, one row
   each: KEEP, RE-DERIVE, REPLACE, or DROP; for RE-DERIVE and
   REPLACE, the replacement approach and its cost in the
   pack's agent-term units only; for DROP, what replaces the
   protection the item was giving, or the statement that none
   is needed. Apply the disposition ground rule in PACK
   section 12: a fresh cap or fixed value needs a named
   measurement that earned it. A disposition that contradicts
   one of your own lens entries is an error.
6. Owner questions: at most three, each with your pick and
   one line on the stakes. Questions must be human-direction
   questions, not technical ones.
7. Not checked: what this report could not verify from the
   pack.

Hard constraints: no human-time estimates anywhere (no hours,
days, or weeks of human work); costs only in the units above.
No invented measurements, thresholds, or quotations. No
triangle or performance caps proposed anywhere. No em dashes.
Plain ASCII.

---

### Flash ideation leg (runs after the writer legs)

You are NOT a reviewer on this project, and this is not a
review. You are an ideation leg. You receive one file:
PACK.md, the evidence pack for a red team of the UI, menu,
and campaign map stack of the game Embers of the Hollow Sun.
Writer legs are reviewing the pack separately; your job is
the things a review would not produce. Do not give a verdict.
Do not verify, check, or rely on any quotation, number, or
provenance classification in the pack; treat all of it as
unverified background. Everything you produce is speculation
and must be labelled as such.

Produce one report with exactly these parts:

1. Ideas: options, mechanisms, or designs for the UI, menu,
   or campaign map stack that none of the pack's settlements
   raise and a reviewer working item by item would be
   unlikely to reach. For each, one line on what it would
   change and what it would cost in agent terms only (Codex
   runs, Opus runs, one-time script builds, owner review
   rounds).
2. Challenges: attacks on the pack's own framing, its domain
   boundaries (HD, MN, MP, TY, IC, AC), its provenance
   classes, and its chair hypotheses (PACK section 10). Where
   is the pack asking the wrong question, lumping unlike
   things, or splitting one thing into many? Name the pack
   section or item numbers you are challenging.
3. Cheaper settlements: for any settlement the pack proposes,
   a cheaper or higher-information alternative that settles
   the same question, or a reason the expensive one is the
   right buy after all. Price both sides in agent terms only.
4. Not checked: what you did not look at. (This section is
   expected to be long. That is fine.)

Hard constraints: no verdict, no disposition table, no owner
questions. No human-time estimates anywhere. No triangle or
performance caps proposed anywhere. No em dashes. Plain
ASCII. Label every claim as speculation.
