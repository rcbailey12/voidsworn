# Issue 1077: flagship death prototype, PC evidence

## Pass 4B at 8216f983, Nov 20 2026 (PASSED)

PC run OPUS1077_PASS4B.bat attempt 1: pinned commit, safe checkout, throwaway profile (real options unchanged), every
Godot start through the canonical watchdog tools_live\dc630028a957\pc\tmo.bat, import, both headless checks (28 sooted
inside surfaces with strain, 0 without; travel unchanged from pass 3), clips and both side-by-sides. For Ryan:
/mnt/project-files/pc/1077/review/pass4/ (FLAGSHIP1077_A16_strain_death.mp4, 23 s, battle camera then close camera;
FLAGSHIP1077_A16_stills.jpg, the camera named on each pair).

- The torn insides now read as dark burnt metal up close, not flat grey slabs.
- The strain band now shows at the battle camera as a wider warm glow along the break.
- The wreck numbers match pass 3: main pieces 0.57 L, fragments 0.55 L (today 1.35 L and 2.44 L).
- compose.gd's page now overshoots the movie slightly (scale about 1.05, about 45 px clipped at each outer edge); the
  review clip is re-cut from the two panels with its own labels.

## Pass 3C at 66e55036, Nov 19 2026 (PASSED)

PC run OPUS1077_PASS3C.bat attempt 1: pinned commit checked out safely, throwaway profile (real options unchanged), import,
both headless checks, clips, both side-by-sides and 12 of 12 timing results valid. Godot 4.7.2, forward_plus, RTX 5080,
installed A16 (C19_51.glb sha256 6611595b...). Pictures and clips: /mnt/project-files/pc/1077/review/pass3/.

- Wreck grouped at the end of the clip (from the pieces' middle): main pieces 0.57 L with strain against 1.35 L today;
  fragments 0.55 L against 2.44 L (4 pieces, 12 fragments both). Headless on the installed hull: physics pieces 0.22 L
  with strain against 0.99 L today, fragments 0.52 L against 2.58 L.
- The tell now shows as a brighter glowing band and hairlines along the break at the close camera; at the battle camera
  it is still a small difference.
- Up close the grouped wreck keeps a piece's torn face in view, and some of those cut faces read as flat grey slabs
  (c26 wreck picture). Today's wreck shows the same faces, but its pieces fly out of frame first. Fix before installing.
- The side-by-side AVIs still render at about three quarters scale on the PC (left edge clipped by about 50 px); the
  review mp4s are cropped to the drawn area.

Frame times, solo GPU, three sessions (median of the session medians; worst is the worst of all three), ms:

| deaths | path | frame p50 | p95 | worst | GPU p50 | p95 | worst |
|---|---|---|---|---|---|---|---|
| 1 (first in process) | off | 2.2 | 2.4 | 6.9 | 1.79 | 1.84 | 2.09 |
| 1 (first in process) | strain | 2.2 | 2.5 | 10.5 | 1.81 | 1.85 | 2.12 |
| 1 | off | 2.2 | 2.6 | 8.5 | 1.75 | 1.82 | 1.84 |
| 1 | strain | 2.2 | 2.9 | 8.7 | 1.79 | 1.83 | 2.10 |
| 2 | off | 2.4 | 3.6 | 11.2 | 1.67 | 1.76 | 1.78 |
| 2 | strain | 2.4 | 3.4 | 12.0 | 1.73 | 1.83 | 1.85 |
| 3 | off | 4.0 | 6.0 | 18.4 | 2.08 | 2.12 | 2.36 |
| 3 | strain | 3.3 | 5.6 | 15.2 | 2.24 | 2.31 | 2.41 |

The strain now costs about nothing: the rerun's extra 1 to 2.5 ms CPU went with the undamped, colliding physics pieces.
The first-use fracture preparation (prepared path, before the first kill): worst frame 19 to 33 ms off, 15 to 26 ms strain,
p95 2.2 ms both. Cold case: same as the finding below (5 of 6 fell back to no pieces, worst frame 2.3 to 4.3 s).

## Rerun at 1236bbc3 (main after PR 1171), Nov 19 2026

PC run OPUS1077_RERUN.bat, RTX 5080, Godot 4.7.2, forward_plus, installed A16 (C19_51.glb sha256 6611595b...),
all steps exit 0. Pictures: /mnt/project-files/pc/1077/review/ (code names FLAGSHIP1077_A16_c26_* and _c170_*).

What it showed:
- Fragments stay grouped: 0.53 L from the break's middle with strain against 2.44 L today (12 fragments both).
- The main pieces did not: 1.93 L apart with strain against 1.35 L today. The physics pieces (quality above low) kept
  their speed because Jolt ignored their damping, and touching neighbours shoved them apart. The headless check only
  covered quality low (kinematic pieces), so it passed. Fixed in pass 3: update() slows a strained physics piece itself,
  strained pieces no longer collide with each other, and the check now also kills A16 at quality high in a
  --fixed-fps 60 child process (off 1.00 L, strain 0.22 L; before the fix 1.46 L).
- The strain tell did not read at either camera. Pass 3 doubles the bulge (0.0045 to 0.010 of the length), doubles the
  hairline width, raises its brightness (1.6 to 3.0) and the band glow (0.05 to 0.12). Needs the pass 3 clip to judge.
- The side-by-side AVIs came out at half size, cropped (the project's stretch settings on a 1920x1080 window). compose.gd
  now draws one to one.
- The prepared timing JSONs were overwritten by the cold run (a misplaced write); the numbers below come from the logs.
  Fixed in pass 3, which reruns the timing.

Frame times, solo GPU, three sessions (median of the session medians; worst is the worst of all three), ms:

| deaths | path | frame p50 | p95 | worst | GPU p50 | p95 | worst |
|---|---|---|---|---|---|---|---|
| 1 (first in process) | off | 2.5 | 3.1 | 10.6 | 1.82 | 2.12 | 2.41 |
| 1 (first in process) | strain | 3.7 | 5.7 | 13.4 | 1.83 | 2.24 | 2.55 |
| 1 | off | 2.5 | 3.2 | 9.1 | 1.79 | 2.09 | 2.48 |
| 1 | strain | 4.4 | 6.5 | 17.4 | 1.80 | 2.13 | 2.47 |
| 2 | off | 3.1 | 5.0 | 14.8 | 1.74 | 2.03 | 2.41 |
| 2 | strain | 5.5 | 8.1 | 17.5 | 1.77 | 2.14 | 2.61 |
| 3 | off | 5.2 | 8.2 | 23.6 | 2.10 | 2.53 | 3.02 |
| 3 | strain | 7.6 | 11.6 | 26.9 | 2.09 | 2.56 | 2.94 |

GPU cost is flat. The strain costs CPU: about 1 to 2.5 ms more per frame at the median and 2.5 to 3.5 ms at p95 while a
capital dies. Not yet traced; it would need a profile before the prototype could be installed.

Cold case (fresh process, no warm-up, no prepared cut), both paths alike, so these are today's problems, not the
prototype's: the worst frame is 3.1 to 6.9 s (a freeze at the kill), and 2 of 3 sessions per path ended in the
no-pieces fallback (hull hidden at 2.68 s with 0 pieces); session 1 fractured (4 pieces, 11 fragments, hidden at 2.02 s).
The game warms and cuts every ship under the loading cover, so a real battle should not hit this; it is the worst case.

## Finding for its own issue: the cold kill freezes and loses its pieces (today's code, not the prototype)

Rerun at 1236bbc3, RTX 5080, solo GPU, three sessions per path. A16 killed 6 frames after it appears, in a fresh process
with no warm-up and no prepared cut (capture.gd `cold`):

| session | path | outcome | hull hidden after | pieces | fragments | worst frame | frame p50 |
|---|---|---|---|---|---|---|---|
| s1 | off | fractured | 2.02 s | 4 | 11 | 4309 ms | 3.77 ms |
| s1 | strain | fractured | 2.02 s | 4 | 11 | 6879 ms | 3.73 ms |
| s2 | off | fallback (no pieces) | 2.68 s | 0 | 0 | 3164 ms | 1.54 ms |
| s2 | strain | fallback (no pieces) | 2.68 s | 0 | 0 | 3237 ms | 1.65 ms |
| s3 | off | fallback (no pieces) | 2.68 s | 0 | 0 | 3147 ms | 1.58 ms |
| s3 | strain | fallback (no pieces) | 2.68 s | 0 | 0 | 3680 ms | 1.71 ms |

GPU worst stays under 2.0 ms in every row, so the freeze is CPU side (likely the first use of the death shaders and the
cut, unproven). The fallback is the #1138 deadline path: the worker missed it and the hull popped with no pieces. Off and
strain match, so this is today's code. A real battle warms and cuts under the loading cover, so players should not see it
unless a ship dies before its cut is ready (a ship added mid-battle, or a kill in the first second).
