# Weapon kit, issue 367

Refs #367. Run 2 continues the original call trace in TRACE.md. The branch
contains the proposed kit. Ryan's faction picks and final visual approval are
pending; outside review is still required on issue 256. No commit or push was
made by this job.

## Changes

- `godot/fx/fx_shaders.gd`: textured compact heads and capped curved tails;
  filled lit prism/shield chips; separate ribbon core and sheath flow, forks,
  per-kind motion and fades; resolved curved engine history.
- `godot/fx/fx_weapons.gd`: smaller shell head/trail; a two-frame travelling
  gauss tracer and short distortion wake in both gauss paths; beam endpoint
  flares and cooling glow; readable rocket/torpedo motors with a rise and fade.
- `godot/fx/fx.gd`: bind the shared imported mask textures for every material,
  including attached batches.
- `godot/fx/textures/`: three original masks, their complete Python/Pillow
  source and provenance. No downloaded sprites or licence packs.
- `godot/fx/API.md`: the kit contract, pixel convention, callers and capture
  method. The rules oracle, saves, UI and faction ids are unchanged.
- This folder: reproducible capture, pixel measurement, gate and sheet tools.

## Evidence

All linked pictures and raw strips are delivered under
`C:/Users/rcbai/Downloads/voidsworn_test/board/issue-367/shots`.
Camera 170 leads each comparison at source pixel size. Ribbon sheets also
retain a native camera-60 detail crop. Camera 26 is a separate build check.
The task GPU go file said `GPU cleared` at this run's start.

The PC hulls were copied without deletion from `build/godot`; all 252 files
match the tracked ship manifest. No placeholder hull was allowed. The before
FX snapshot is the resumed branch's unchanged FX, before this run's edits;
other source and PC assets are shared. The snapshot and scratch logs are in
TEMP. The accepted look-bench baseline was not changed.

The capture adapter uses the standing bench's real ships, attach service,
volley/launch/break/lane calls and clocks. It adds nozzle samples for ribbon
kinds 0, 1 and 3, isolated breaks without a prior volley, point defence and a
real `play_moves` path for the curved engine history. Gauss and gauss flak are
sampled at 60 Hz; the other rows retain 30 Hz. It releases the world's static
rock caches before shutdown and puts its own profile/cache under TEMP.

Measurements and final comparison links are recorded below after the kept
capture runs finish.

## Faction shapes for Ryan's pick

These are candidates shown by the kit, not recorded owner approvals. Existing
faction colours remain in faction_looks.json, including Eclipse violet-white.

| Faction id | Display name | Proposed shape language | Sheet | Pick |
|---|---|---|---|---|
| voidsworn | Sunward Crusade | Compact hot shells, broad sustained lance, clean hot throat | macro, lance | Pending |
| corsair | Ashfall Hullbreakers | Uneven pellet spray, rocket clusters, broken sputtering exhaust | scatter, rockets, ribbon_3 | Pending |
| ithar | the Glasswrights | Filled faceted chips, narrow needles and spectral travelling packets | prism, needle, pulsar | Pending |
| deathless | Eclipse | Angular forked arcs, compact two-frame gauss tracer and cooling violet sheath | doom, gauss | Pending |
| chorus | the Chorus | Wet luminous globs, curved drips, wriggling tissue and spores | bioplasma, tendril, spores | Pending |
| hegemony | Hegemony Navy | Blue churning plasma heads, crawling ion filaments, short precise picket darts | plasma, ion, pflak | Pending |

## Checks and limits

The standing checks, headless effects checks, raster proof, kept scene-gate
costs and review status are recorded here when all required runs complete.
The one scale table remains docs/playbooks/scale.md. This change does not
introduce another world scale. Mask quads and their pixel caps are documented
in API.md section 17.

R129 sweep: every `stk`, `rib` and kind-16 sprite caller shares the new drawing
code. Both gauss emitters are covered; beam endpoint additions cover lance,
ion, pulsar, Doom, needle and tendril. All eight original shared-helper rows
are included. No saves, UI path or rules twin changed, so there are no oracle
copies or tables to refresh. GitHub still runs standing checks, changed-text
checks, rules parity and Godot game checks. No remote check was dispatched.
