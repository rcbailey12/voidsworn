# Issue 768 helper scripts (the hegemony_IM5 build sheet, the Iron Mandate)

The sandbox steps behind the hegemony_IM5 sheet's README rows that the shared sheet tools do not make. Each says its usage in its
first lines. Nothing here is a standing check. Reused as they are: contrib/opus/tools/issue738/ (mask, grid, density_mesh, budget,
run_blend) and contrib/opus/tools/issue759/ (inside_check and bell_check, which take the ship code: `inside_check.py
hegemony_IM5`, `bell_check.py hegemony_IM5`; the IM5 design file offers `inside_ok`, with the canyon outside the skin).

| Script | What it does | Runs with |
|---|---|---|
| `mask_im5.py` | the IM5 beauty's outline mask for the camera fit: its "IM5" label blanked, issue 738's mask.py, the engine plumes above the stern edge cut away | Python, numpy, scipy, Pillow |
| `pictures.py` | the three named 1280 by 720 pictures (overview, the whole concept beside IM5, the battle camera); publish.py makes the weapon review | Python, Pillow |

The cutaway was rendered a second time after the last inside fix with a throwaway copy of build.py whose renders were skipped
for every view but the cutaway (the other views did not change); the copy was deleted.
