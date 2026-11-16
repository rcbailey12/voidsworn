# Hullbreaker paint, issue 726 run 3

Run 3 stopped at A20 stage 5. The approved normal-only proposal still exhausted Cycles' SVM stack in five hull materials.
The new bake guard caught the error and stopped before stage 6, export or installation.

There are no accepted run 3 painted or installed pictures in this folder. The installed ships remain as before the run.
Earlier pictures must not be presented as the result of this fix.

See the [run report](../../../../contrib/codex/issue726/REPORT.md) for the real-ship failure, diagnostic controls and checks.
PC evidence is in `C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-726/shots/run3/`.

The repeatable launcher is `tools/pc/jobs/HB_PAINT_726.bat`. On a successful run it writes one beauty-camera picture beside
the concept and one camera-170 picture from the playable game per ship, at 1280 pixels wide and no taller than 720 pixels.
Its pictures carry the source revision and actual stage. Run 3 used `225b10ae+normal726-run3`, including PRs 884 and 898.
