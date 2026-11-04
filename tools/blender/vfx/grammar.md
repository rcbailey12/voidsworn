# Death grammar, issue 137

Owner rulings: FINDINGS R88 and R90. Scope: synthesis D1 to D5 only.

| Beat | Capital | Small hull | What reads |
| --- | --- | --- | --- |
| Power loss | 0.00 to 0.30 s | 0.00 to 0.12 s | Lights die by section, one quiet blue-white tear flicker. |
| Vent | 0.30 to 0.80 s | 0.12 to 0.55 s | Gas and sparse hot sparks leave the tear normal. No upward smoke drift. |
| Structural break | 0.80 to 1.60 s | 0.55 to 0.85 s | Two cruiser cuts, three battleship cuts, one reactor flash under 0.5 s. At most two secondary flashes. |
| Drift and cool | 1.60 to 2.05 s, then 14 s cooling | 0.85 to 1.15 s, then cooling | Sealed sections tumble and keep their vectors. Hot rims cool, the gas disperses. |

Metal: warm ivory -> amber -> deep red -> charcoal violet. Reactor and drive plasma: pale blue-white, never a sustained orange fireball. Vapour: muted violet-grey. Broad soft masses must stay below the hull's detail frequency. Exposure stays fixed.

Max has lit, motion-blended flipbooks, vent cones, sparks and fracture glow. High drops fracture glow. Low keeps the flash and sealed drifting sections, dropping vents and sparks. Reduced flashing uses a quiet cooling puff and no counted flashes. The existing rolling three-flash budget and R80 damage surfaces stay in force.

Reference frames on the accompanying sheet are study references, not shipped game assets:

- [Homeworld 3, developer damage breakdown](https://store.steampowered.com/news/app/1840080/view/3669906156890227103): readable broken silhouettes and local damage.
- [EVE, Andre Bragason's explosion breakdown](https://realtimevfx.com/t/eve-online-ascension-new-explosions/1269): staged local events and optical-flow animation.
- [The Expanse, production breakdown](https://vfxvoice.com/new-visual-vistas-propel-the-expanse-into-higher-orbit/): ships and detached material moving coherently in space. The sheet uses a published space frame, not a claimed destruction frame.

Mantaflow is an offline artistic gas model, not a vacuum physics solver. Buoyancy and gravity are disabled; the emission is brief and directional. Mantaflow runs on the CPU; Cycles channel renders run on the RTX GPU. No simulation runs in the game.
