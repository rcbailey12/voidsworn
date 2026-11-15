# Shield design: reference pictures and sources

For issue 697 (design.md in this folder). Links only; no images are copied into the repo. Each entry says what the picture shows and what the design takes from it. Found by image search, Nov 14, 2026.

1. Hull-hugging crackle shield under fire (the hit look). Forge3D "Force Field" protective shield shader promo render: a starship wrapped in a shield skin that follows the hull, with electric crackle across the surface and bright sparks where beams strike.
   Picture: https://pic.cgais.com/images/2024/12/09/CGalpha_gQ3ylY.jpg
   Source page: https://www.cgalpha.com/archives/tag/unity%e6%8f%92%e4%bb%b6/page/3?order=rand (asset by Forge3D, forge3d.com)
   What we take: the shield reads as a skin on the ship, not a bubble around it; the crackle lives where the hit lands. Our Voidsworn mask (ridged fbm veins) and the local hit reveal follow this, at our stated caps.

2. Hex lattice energy (the Hegemony mask). ArtStation cover by Bethany Smallman: a hexagonal energy shield, crisp cell edges, glowing nodes.
   Picture: https://cdnb.artstation.com/p/assets/covers/images/037/960/835/large/bethany-smallman-bethany-smallman-shield-001-final.jpg?1621795356
   What we take: cell edges carry the pattern, interiors stay near-clear; on a hit the near cells brighten and thicken. That is the Hegemony style 1 treatment in design.md section 6.

3. Fresnel rim and chromatic edge (the rim, and Ithar's edge). Mirza Beig, "Chromatic Bubble Shield: what it looks like from the inside": a shield whose presence is mostly a fresnel rim with a spectral fringe at grazing angles.
   Picture: https://pbs.twimg.com/media/GWUfrGdWQAAo8tU.jpg
   Source post: https://xstalk.com/profile/TheMirzaBeig/status/1846695302645899738
   What we take: the rim-first read (design.md section 2) and Ithar's rainbow edge mode; our rim is a single edge colour per faction, with the spectral shift only for Ithar.

4. The bubble we are leaving (contrast reference). Homeworld 3 review screenshot, GamingTrend: a mothership inside a large bright energy sphere.
   Picture: https://gamingtrend.com/content/images/2025/02/20240502065121_1.jpg
   Source page: https://gamingtrend.com/homeworld-3-review-the-mothership-has-cleared-the-scaffold-we-are-away/
   What we take: nothing but the lesson. A sphere that big and that bright hides the ship and cannot show which side is open; it is the current defect at larger scale.

The in-repo reference is the current SHIELD shader itself (godot/fx/fx_shaders.gd): its four faction styles (0 gold veil crackle, 1 hex lattice, 2 patchy flicker, 3 smooth prismatic) are the pattern masks this design reuses, and godot/fx/faction_looks.json is the colour and edge source. The mock frames in summary.md are schematic drawings made for this pack, not renders.
