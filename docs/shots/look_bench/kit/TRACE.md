# Issue 367: trace before changing the effects

Refs #367. This is the original run-1 call trace. Run-2 implementation,
captures, measurements and approval status are in [REPORT.md](REPORT.md).
Line numbers and prerequisite notes below describe the dated run-1 checkout.
The sh_06 attribution was completed on Nov 15 in the section below. Older
prerequisite and check notes are history, not the current job status.

Read against checkout `6096c4368c1baa8ccebca8170043be4dbfe2f2be` on
`codex/issue-367`, Nov 14 2026. Runtime files have not been changed. This is
the first step required by the brief: identify the callers before replacing
their shared drawing code.

The nine evidence images named in the task were opened and inspected. Their
source is `docs/shots/audit_2026_11/`. They were captured at
`70e87f2345adf171f4dd7a1a5aa52ac1d43e8338`, not at this checkout. The old
weapon and shield callers were also read with `git show` at that pin.
Current line numbers below are for the unmodified checkout above.

## The drawing path

`fx_weapons.volley` chooses a look using `look_of`, gets real muzzle and hit
points, then calls `_shot`. The calls to `fx.stk`, `fx.rib` and `fx.spr`
pack particles into the corresponding pools in `fx.gd` (lines 455, 469 and
441). `fx.gd` creates those pools at lines 239 to 243. Their shaders are
`STREAK`, `RIBBON` and `SPRITE` in `fx_shaders.gd`.

`STREAK` draws one camera-facing quad per particle, not a physical shell.
`fx_pool.gd:217` defines that quad. `RIBBON` uses a segmented strip
(`fx_pool.gd:224`); `fx.gd:243` requests 32 segments. A bright narrow
centre in either shader can still read as a hairline even if the outer
quad is several pixels wide.

## Evidence to callers

| Evidence code | Visible feature | Caller at the current checkout | Shader path and cause |
|---|---|---|---|
| fx_02 | Identical pale, pointed shells with large round heads | `_shot`, macro arm, `fx.stk` at `fx_weapons.gd:274` | `STREAK` kind 0. Fixed world length `9 * ka`, world width `0.75 * ka`, length floor 26 px. Its narrow Gaussian centre and amplified head make one continuous cone. It has no separate shell body. |
| fx_03 | Full-width incoming line in successive cells | `fx_weapons.gd:410`, gauss arm | `STREAK` kind 5. `dist` is passed as its length, velocity is only the unit direction, and life is 0.4 s. The kind-5 vertex branch explicitly puts the tail at the muzzle and the head at the target for its entire life. |
| fx_03 | Straight starburst at entry and exit | `_gauss_punch`, `fx_weapons.gd:1349`, through `_throw_sparks:1012`; also the exit `_vent` through `_impact_sparks:596` | `STREAK` kind 1. At the audit pin `_gauss_punch` directly used `_impact_sparks` for entry and exit. The current hit recipe now uses `_throw_sparks`, but both still request kind 1 and use the same uncapped tail calculation. |
| fx_04 | Short, blunt luminous bar approaching the target | `_shot`, las arm, `fx_weapons.gd:295` | `STREAK` kind 4, length floor 30 px. A smooth transverse core and smooth longitudinal ends provide no interior texture. The later orange point is the hit, not the projectile. |
| fx_06 | Uniform cream beam | `_shot`, shared lance/ion/pulsar/doom arm, `fx_weapons.gd:336`; `fx.rib` at 349, kind chosen at 347 | `RIBBON` kind 2. The shared beam branch uses a very narrow white Gaussian with strength 5 and a weaker coloured sheath. Widening the strip alone does not guarantee a resolved core. |
| fx_10 | Several long crossing white lines, with a fan at Hegemony | `gallery/gallery.gd:292` fires Deathless gauss at Hegemony, three shots; `_shot` gauss arm plus `_gauss_punch` | Same kind-5 path streaks and kind-1 entry/exit sparks as fx_03. The firing ship is Deathless; Hegemony is the target. The audit's phrase "from the Hegemony flagship" does not identify the shooter. |
| fx_11 | Long yellow-green spokes at the bio splash | `gallery/gallery.gd:293` fires Chorus bioplasma at Corsair; `_bio_splat:1332` calls `_vent`, which calls `_impact_sparks:596` | The spokes are kind-1 sparks introduced by the shared vent helper, not the kind-15 bile droplets. The same call chain exists at the audit pin. Bile's flight also emits kind-6 drips, but those are not the radial fan shown here. |
| fx_12 | Three bright bars travelling toward the shield | `_shot`, prism arm, `fx_weapons.gd:326` | Three `fx.stk` calls use `STREAK` kind 4 with a 24 px length floor, plus moving kind-16 glints. The bars come from the streaks; the glints do not replace them. |
| fx_13 | Even bright beam with diagonal white bands | `_shot`, ion arm, `fx_weapons.gd:336` | `RIBBON` kind 5. The generic hot centre is overlaid with a high-power periodic sine in `s * length - time + side`, making the regular diagonal bands. |
| sh_06 | Yellow lines across a breaking Hegemony shield | **Not fully attributed from this still.** `fx_ship.gd:475`, `shield_break`, Hegemony arm at 505 emits two rings and 36 kind-16 sprites, no streaks | Hegemony break glints use `SPRITE` kind 16, whose `star` term has thin cross arms. Long yellow straight streaks are not emitted by that Hegemony break arm, at either pin. The gallery has other effects in flight. Do not replace a shield-break streak call that does not exist. Isolate the break and surrounding volleys on the bench before assigning those crossing lines. |

Attribution above follows the emitting call and the selected shader kind.
The mixed gallery still sh_06 is explicitly unresolved; a screenshot's file
name cannot establish which simultaneous effect drew a particular line.
There is no claim here of a new rendered reproduction.

The audit image index maps sh_06 to gallery g17, captured 0.12 s after
`break_H` (10.6 s). The prior Sunward break at 10.0 s emits kind-1 gold
sparks from `fx_ship.gd:498`, with delays up to 0.4 s and lives up to
0.7 s. Those can still be present at 10.72 s and are a concrete candidate
for the crossing yellow lines. This is an inference from the event
schedule, not a claim that an isolated capture has proved their identity.

## Completed sh_06 attribution, Nov 15

Observed in a replay of gallery g17 from the preserved PC audit checkout.
`trace_audit.py` first checked the gallery, fx.gd, fx_shaders.gd,
fx_weapons.gd and fx_ship.gd against the audit commit above. Its wrappers
record calls and delegate to the original emitters. They do not suppress,
recolour or replace particles. The original scene, hulls and event schedule
then rendered g17 at effect time 10.7387 s.

The long green-yellow strokes are Chorus **spore flak**, fired at 9.8 s:
`gallery._vol("spores") -> fx.volley -> _shot -> _flak:803 ->
_impact_sparks:530 -> fx.stk(kind 1)`. All 48 live green streaks whose
projected axes exceeded 50 px came from that call chain. Their colour is
RGB (0.72, 0.88, 0.18); their projected axes span 55 to 1519 px in the
2560-wide replay. Those are projected geometry lengths, not measured lit
extents. The old blur length and speed both scale with the large target.

The same captured frame also contains 18 live gold kind-1 streaks from the
Sunward shield break and four from the torpedo volley. Hegemony's break
contributes its rings and kind-16 cross glints. This separates the mixed
shot's sources; all its kind-1 paths now use the capped textured tail, and
kind 16 uses the filled flake. The isolated break, spores and torpedo rows
are in the new three-camera bench.

Evidence is under the task's shots folder:
`review_20261115/forensic/sh_06_attribution.png`,
`active_streaks.json` (every live streak and its real call stack) and
`attribution_summary.json`. This old free-camera replay establishes
attribution only. The kit's visual comparison uses the real bench cameras.

## Shared causes that need separate captures

- In `STREAK`, kind 1 uses `length = blur_seconds * speed * exp(-drag * age)`.
  Several emitters scale both blur and speed with hull size, so the tail
  grows roughly with the square of that scale. There is a minimum screen
  length, but no maximum. Kinds 6 and 7 share that vertex branch.
- The streak width floor describes the quad, not the hot centre. For a
  2 px quad, `exp(-x*x*22)` has a full width at half maximum of about
  0.36 px. Kind 5 uses an even narrower `exp(-x*x*80)` centre.
- Ribbon widths likewise describe the quad. The generic
  `exp(-x*x*60)` core has a full width at half maximum of about 0.38 px
  inside the 3.5 px floor. Doom's `exp(-x*x*40)` is about 0.46 px at that
  floor. These are analytic widths before tone mapping and bloom, not
  measured lit extents from a capture.
- Doom currently has a jagged path and re-strikes every 70 ms, but no
  branch geometry. Its shared strip width is subject to floor dimming.
  R248 requires branching, a resolved core and coloured glow, and end
  afterglow, not merely a larger intensity multiplier.
- The Hegemony and Glasswright shield fragments are kind-16 cross glints.
  Changing kind 16 globally would also change prism projectiles and muzzle
  glints. Give shield flakes a separately selected kind, or prove all
  affected uses on their own rows. `fx_ship.gd` is not in this job's scope;
  any caller change there needs the Board to expand the Deliver to list.
- The moving-engine `TRAIL` shader is separate from `RIBBON` idle kind 1.
  A ribbon-only change does not cover the ship's curved moving exhaust.
- `_flak`'s gflak arm (`fx_weapons.gd:867`) independently emits a whole-path
  kind-5 streak for 0.15 s. Updating gauss alone leaves that path in play.
- Guns, bombs and spore bombs enter `_strafe:886`; launch/bay flashes enter
  `launch:1474`; campaign torpedo lanes enter `torp_lane:1539` and
  `torp_launch:1597`. They must be included beside `_shot` and `_launch`.

The requested spark-tail cap is not implemented yet. It needs a stated
pixel measurement convention, including camera 26 and 4K. Existing
`px_world` uses pixels at a reference height of 1080 and scales them with
resolution; that is different from an absolute framebuffer-pixel cap.

## Required capture order

1. Obtain the issue's Board GPU go file or an explicit GPU release from Ryan.
   Keep one GPU job at a time. The launched Codex chain identifies this job,
   but no issue-367 go file was found. The separate GPU chain's old completed
   paint log is not a release for this job.
2. Use the PC-built hulls already present in this checkout. The bench still
   checks every hull and must stop if one is missing or a placeholder.
3. Before changing a look, capture it at 170, 60 and 26. The unmodified
   checkout above is the before version. Run it twice and retain the second.
4. Start with Doom, as Ryan specifically requested. Show its whole path,
   muzzle and landing, then fading ends. Keep one 170/60 before/after sheet
   for this ribbon and a separate 26 build strip.
5. Repeat one look at a time for all other ribbon kinds: plume 0, idle
   trail 1, lance 2, sputter plume 3, ion 5, pulsar 7, needle 8, tendril 9.
   Kind 4 is unused in the ribbon shader's kind list.
6. Cover every weapon family, its muzzle, flight and landing: macro, auto,
   las, plasma, scatter, prism, needle, lance, ion, pulsar, doom, torpedo,
   rockets, star torpedo, flak, picket flak, mirror flak, gauss flak, spores,
   bioplasma, tendril, gauss, craft guns, bombs and spore bombs. Include
   launch/bay flashes, interceptions and torpedo lanes. Use the real public
   effect calls and attach-point service, not guessed origins.
7. Capture the eight shared-helper regression rows already in
   `godot/bench/look_moments.json`: `p_las_muzzle`, `p_prism_muzzle`,
   `p_missile_launch`, `p_torp_shield`, `p_lance_burn`, `p_bile_hit`,
   `p_gauss_exit`, `p_crit`. Hits remain issue 538's recipe; inspect shared
   particles here without restaging those hits.
8. Run isolated shield breaks for all four shield styles to distinguish
   flakes, glint arms and unrelated weapon streaks, especially sh_06.
9. Prove gauss's two-frame tracer at 60 fps with consecutive frames.
   The stock look bench stores every second frame at 30 fps; that strip
   alone cannot prove a two-frame lifetime at 60 fps.
10. Report R116 cost before and after on the scene gate: frame median at
    1080p and GPU ms with 3D at 4K, compared with 12.5 ms. A headless run
    gives no GPU timing or visual proof. Retain the second run after warm-up.

All new screenshots, sheets and recordings must go to
`C:\Users\rcbai\Downloads\voidsworn_test\board\issue-367\shots`, as the
task requires. Keep temporary logs in `%TEMP%`. Sheets need their code name,
camera 170 first at true source-pixel size, and height at most 720 px.
Do not overwrite the accepted baseline.

## Open prerequisites, Nov 14

The chat has a pending GPU availability question and three scope choices.
No new visual direction or faction table has been called Ryan-approved.
`docs/playbooks/scale.md` and `godot/render/test/scale_check.gd` from issue
710 do not exist at this checkout. Read that table when it lands before
claiming the projectiles follow it. Do not create a competing scale table
in the effects files.

No new textures or downloaded sprite packs have been added, so there is
no new licence claim or bake to record. No effects have been replaced,
and no before/after captures, measured widths or gate costs exist for this
job yet. It does not meet the done test and is not ready for approval.

## Checks and review status

- Ran `contrib/opus/tools/run_all_checks.js` with the bundled Node 22.11.0.
  Exit 1: 47 PASS rows, 2 KNOWN baseline rows, 1 FAIL row. The failure is
  `doc_check_tests`, which reports both missing issue-710 files above.
  This ran against the unchanged game code. Log:
  `%TEMP%\voidsworn-367-standing.txt`.
- Godot 4.7.2, `--headless --path godot --script
  res://tools/ci/load_all.gd`: exit 0, 181 scripts, 11 scenes, 0 failed.
  Godot also logged a root-certificate-store warning. Log:
  `%TEMP%\voidsworn-367-headless\load-all-console.txt`.
- The new trace is ASCII. `git diff --check` found no tracked-file
  whitespace errors. `git status --short` shows the pre-existing
  untracked `CODEX_TASK.md` and this new kit folder only.
- R129 sweep: no runtime caller, save, rules twin or UI changed. There
  are no oracle copies or tables to refresh for this documentation-only
  preparation. GitHub's configured jobs remain standing checks, changed
  text/em-dash checking, rules parity and Godot game checks. None was
  dispatched remotely; this job must not commit or push.
- GPU checks, the GPU portion of `check_destruction.bat`, new captures,
  R116 before/after costs, authored textures and the visual rebuild were
  not run while the required GPU release is pending. Runtime changes
  also wait for the brief's before captures. The shots folder was created
  at the exact task path and contains no new evidence from this run.

Do not merge this preparation as a finished issue 367. The next build
starts with the before captures, one look at a time, and still needs
Ryan's faction picks and final visual approval.
