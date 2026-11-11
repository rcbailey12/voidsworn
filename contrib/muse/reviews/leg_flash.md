# Leg: Flash (ideation), issue #486 cinematic audit

Landed Nov 11, 2026, 10:35 to 10:41 CST at gemini.google.com (chat https://gemini.google.com/app/939365882f260614). Sign-in required a Google number-match prompt; Ryan approved it (Yes, then 31) and the runner resumed; the account showed as Ryan Bailey (Pro), the standing unverified Pro observation, gates unchanged. PACK.md attached by grant. Chair screening notes: (1) Flash's Finding 1 proposes relaxing the 0.70 s flame cap itself; that cap is an owner ruling (fire is wrong for space, flash and snuff out), so the chair does NOT adopt the relaxation as written: the adopted form is DeepSeek's and Grok's, separating flame from matter inside the cap, with the cap question itself flagged for Ryan in the synthesis. (2) Its "missed tell" (dead stillness between turns, no idle behaviour) is a genuine addition no other leg raised and is adopted. Raw leg text follows, unedited except this header.

---

1. Top Eight Findings (Ideation Short Form)

Finding 1: The 0.70s Flame/Heat Cap Enforces Disappearing Explosions

What the player sees/hears now: Capital ship deaths and heavy torpedo detonations flash white and vanish almost instantly; clouds disperse into clean, empty vacuum within a second.

What a film would do instead: As seen in The Expanse and Battlestar Galactica, massive detonations produce heavy, lingering fire, superheated expanding debris, and persistent smoldering wreckage that glows and casts light across neighboring hulls for 10-20 seconds.

The loosening proposed: Relax effects.md Section 1 ("no flame or hot core lives longer than 0.70 s, and none stays at full heat longer than 0.25 s"). Allow core thermal embers, venting gases, and slag clouds on capital deaths to linger for 6.0-12.0 seconds at decaying intensity, utilizing slow alpha/color ramps instead of repetitive bright strobing to remain safely under the 3-flash WCAG ceiling.

Finding 2: The Perfect Untouchable Shield Bubble

What the player sees/hears now: A rigid, static honeycomb ellipsoid wraps the ship; weapon impacts generate a disconnected generic puff on the perimeter without localized deflection, surface rippling, or visual degradation at low shield HP.

What a film would do instead: Like Star Trek or Sins of a Solar Empire II, shields remain invisible until struck, upon which energy flares violently at the exact point of impact, diffusing across local hexagonal facets before bleeding into the hull as capacity drops.

The loosening proposed: Strip the permanent static ellipsoid overlay. Implement localized impact blooms and directional mesh displacement at the hit vector, with a shader variable driving cell jitter and darkening/flickering as shield integrity depletes below 30%.

Finding 3: Fixed Synthetic Audio Salvos and Symmetrical Layer Pitching

What the player sees/hears now: Every shot within a weapon burst fires with mechanical regularity, identical sound profiles, and zero dynamic distance falloff or acoustic weight differentiation between a frigate battery and a dreadnought battery.

What a film would do instead: In Star Wars or Dune, projectile barrages have natural human/mechanical cadence stagger, barrel-cycle variance, acoustic interior resonance, and distinct bass punch depending on hull displacement.

The loosening proposed: Loosen cues.json fixed salvo gaps (gap: 0.045, pj: 0.03). Introduce pitch jitter up to ±0.15, trigger acoustic ducking on the master weapons bus during heavy hits (duck: 0.5-0.75), and mandate non-linear stagger across individual turret barrels.

Finding 4: Uniform White Bar Beams with Zero Thermal Life

What the player sees/hears now: Energy lances and ion beams draw razor-straight, flat-shaded bars edge-to-edge across the screen with hard on/off cutoffs and no beam decay or optical bloom.

What a film would do instead: In Babylon 5 and Homeworld, heavy beam weapons ramp up with optical focal blooming, shudder slightly along their vector with an unstable incandescent core, and leave a searing ionized path that dissipates over 1-2 seconds.

The loosening proposed: Loosen the instantaneous beam rendering. Introduce a 0.15s beam aperture flare/charge ramp, core noise/wiggle shaders, and a glowing lingering trail along the shot path that cools from white-hot to dull cherry-red.

Finding 5: Decoupled Single-Puff Kinetic Hull Impacts

What the player sees/hears now: Macro-cannons, railguns, and autocannons spawn an identical beige smoke puff and a tiny static glow pip at the ship's center or root node, regardless of caliber or projectile velocity.

What a film would do instead: In The Expanse, kinetic slugs punch jagged entry holes, kick off high-velocity spall and spark cones perpendicular to the armor plate, shatter exterior fixtures, and leave molten gouges.

The loosening proposed: Implement directional velocity to hit VFX. Align cone spall and high-speed directional sparks with the incoming strike angle, leaving persistent decal wounds that cool over 3.0s instead of spawning symmetrical circular puffs.

Finding 6: Symmetrical, Scheduled Chain Blasts on Ship Destruction

What the player sees/hears now: Dying hulls step through perfectly rhythmic, evenly spaced secondary explosions walking down the spine before snapping into halves.

What a film would do instead: Capital ship deaths in Return of the Jedi feature uneven, asymmetric structural failures, internal fuel ruptures venting violent directional fire, followed by irregular pauses, secondary blasts, and catastrophic structural tears.

The loosening proposed: Loosen the rigid timing table in deaths_and_hits.md (e.g., Cruiser beats locked at 0.5s, 0.8s, 1.1s). Inject ±35% randomized interval variance and spatial offset along bulkhead breach zones, mixing sharp structural ruptures with dull internal hull groans.

Finding 7: Single Scale Comet Tracers and Universal Munitions

What the player sees/hears now: Small escort craft fire projectiles nearly as large as their own chassis; dreadnought batteries fire tracers that share identical velocity, width, and illumination profiles.

What a film would do instead: Fleet engagements in Battlestar Galactica contrast needle-thin, high-velocity point-defense flak screens with massive, slow-burning heavy ordnance shells that illuminate the hulls firing them.

The loosening proposed: Implement weapon-class scaling factors. Downscale point-defense and frigate tracer geometry/glow radii by 50% while expanding capital heavy macro shells and torpedoes, allowing heavy ordnance to cast real-time local point-light onto adjacent ship geometry.

Finding 8: Sterile Post-Engagement Battlefield Space

What the player sees/hears now: Once an effect duration elapses, the hex returns to a pristine, sterile board; no atmospheric venting, particulate dust, or drifting structural debris remains.

What a film would do instead: Spaces after engagements in Homeworld or The Expanse are littered with floating particulate clouds, cooling hull fragments, frozen venting gas, and scarred navigation hazards.

The loosening proposed: Permit low-cost persistent particulate fields. Leave low-density GPU drift clouds (cold vapor, small tumbling shards) on hexes where capital kills or torpedo strikes occurred, persisting for several turns without violating performance budgets.

2. The Staged Tell the Writers' Framing Is Likely to Miss

The Synchronized Turn Reset and Static Posture Tell:
The writers focus extensively on the execution of active verbs (the hit, the beam, the break). What they will likely miss is the dead stillness between turns. In real space operations, a vessel is never static; it maintains slight station-keeping thruster firings, RCS puff corrections, and rotational inertial trim. Currently, all ships stop dead on the hex center, extinguish their drives instantly, and sit motionless with uniform running lights. This immediately exposes the board game beneath the simulation. Ships need subtle, continuous idle behaviors, micro-drifts within the hex bounds, faint gyroscopic attitude corrections, and heat-radiator shimmer during weapon cooldown phases.

3. Movement Devices Shortlist (Hex Tactics from Above)

Devices That Suit the Game:

Vector Decoupling / Drift While Turned (LOOK): The ship rotates its nose toward the movement vector or final tactical facing while the hull's momentum continues translating along the original path, showing vacuum mechanics without altering the underlying hex destination.

Thruster-Driven Pitch and Yaw Couplets (LOOK): RCS thruster jets fire on opposing corners of the hull (e.g., bow-left, stern-right) to initiate yaw, firing reverse pairs to arrest rotation, rather than snapping rotational degrees.

Asymmetrical Class Inertia / Staggered Turn Inception (LOOK): Frigates pivot instantly and dart away; capital ships experience an engine spin-up delay, slow rotational ramp-up, and lingering braking burns before coming to a stop.

Retro-Burn Braking Maneuvers (LOOK): Instead of gliding to a dead stop, ships fire bow retro-thrusters or execute an end-of-move braking burn to decelerate into the destination hex.

Devices That Do NOT Suit the Game:

Aerodynamic Banking and Rolling: Tilting hulls along the longitudinal axis into turns like an atmospheric fighter or naval boat. This reads as aircraft in an ocean, violating the vacuum aesthetic.

Full 180° Flip-and-Burn Deceleration: While realistic in The Expanse, executing a complete flip-and-burn over a 1-to-2 hex hop in a 1.5-second turn playback creates disorienting visual spinning and ruins weapon-facing comprehension from an overhead tactical camera.

Continuous Arc Curvature (Car-Like Cornering): Smoothing paths into gentle highway curves causes ships to clip hex edges and visually disconnect from the underlying hex grid rules.

4. One-Line Verdict

Relax the rigid sub-second flame and timing clamps to allow asymmetrical secondary burns, lingering slag, and directional spall to accumulate on hulls.
