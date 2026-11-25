# FX combine notes (Refs #2148)

Apply the registry first, then apply these edits on the named PRs before
combining. Paths and line numbers below refer to each PR head listed here.
No FX PR is merged on this branch.

## PR #2136 (57b7943d) | Wound style 16 to 19

- `godot/fx/fx_breach.gd:55`: drop the local `S_NULL_BURN := 16` in favor of
  the registry's `S_NULL_BURN := 19`. Keep the uses at lines 66 and 1805 and
  the `BREACH.S_NULL_BURN` check at `godot/fx/test/layered_beam_check.gd:154`.
- `godot/fx/fx_shaders.gd:2195,2234`: change only this PR's `style != 16` and
  `style == 16` to 19. Preserve all of PR #1755's `S_PRISM` paths at 16 and its
  star and null-lance marks at 17 and 18.

## PR #2133 (48deac49) | Sprite kinds 30 to 37 become 38 to 45

- `godot/fx/fx_weapons.gd:66-72`: replace the seven local values with aliases
  to `SH.SPR_BOLT_PLASMA`, `SH.SPR_BOLT_BIO`, `SH.SPR_BOLT_BOMB`,
  `SH.SPR_MUZZLE_BALLISTIC`, `SH.SPR_MUZZLE_ENERGY`, `SH.SPR_MUZZLE_CRYSTAL`
  and `SH.SPR_MUZZLE_BIO`, in that order. At line 1438 use
  `SH.SPR_ROCKET_SMOKE` (45), dropping the old declaration in
  `godot/fx/fx_shaders.gd:254`. The existing tests using the weapon aliases
  can stay. Leave the streak kinds at `fx_weapons.gd:62-65` alone.
- `godot/fx/fx_shaders.gd:286-287,338,340,349-351,463,465,467,471,474`:
  add eight to the old sprite selector values, including rocket smoke at 37.
  Bound the line 349 test to 38 through 45. Leave legacy kinds and all
  floor, timing and stretch values unchanged.
- `godot/render/weapon_layer_masks.gd:29,31,39,48,55,59`: update the
  `profile` checks to 40, 38, 40, 41, 42 and 43 respectively. Do not shift
  the separate streak profiles or the mask parameters.

## PR #2132 (4cb23fa7) | Sprite kinds 30 and 31 become 46 and 47

- `godot/fx/fx_shaders.gd:245-246,315,436,443,460,462`: drop the local
  `TICK_EMBER` and `TICK_DROPLET` declarations and update the shader
  selectors to 46 and 47, respectively.
- Switch to `SH.SPR_TICK_EMBER` and `SH.SPR_TICK_DROPLET` at
  `godot/fx/fx_status_tick.gd:47,61,93`,
  `godot/fx/fx.gd:760` (smoky pool), and
  `godot/fx/test/event_layers_2046_check.gd:71,79,91`.

## PR #2084 (f9d14db1) | Sprite kind 30 to 48

- `godot/fx/fx_shaders.gd:245,285,338,348,374,410,500`: drop the old kind
  comment and update all vent-jet selector literals from 30 to 48.
- `godot/fx/fx_death.gd:2823-2824`: update the comment and use
  `SH.SPR_RUPTURE_JET` for the emitter. Do not touch the 0.30 s lifetime
  or the trailing smoke's kind 27.
- `godot/fx/test/small_death_vent_2048_check.gd:50-53`: update the comment
  and test strings for kind 48, using `SH.SPR_RUPTURE_JET` for the expected
  selector values. Leave the asserted stretch unchanged.

## PR #2069 (ae57de8c) | Sprite kind 34 to 49

- `godot/fx/fx_shaders.gd:372`: change the legacy Nova selector to 49.
- `godot/fx/fx_special.gd:40` and `godot/fx/test/build_d_check.gd:71`: use
  `SH.SPR_NOVA_LEGACY` in the emitter and its test. Both files need the
  `res://fx/fx_shaders.gd` preload.

## PR #2049 (838263ae) | Keep the spark API

- No sprite or wound id change. `SPARK_KIND := 8` at `godot/fx/fx.gd:813`
  is a streak kind, not a sprite. Keep the `_vent` argument tail and
  role-aware spark body at `godot/fx/fx_weapons.gd:832-849`.
- When integrating with #2021, keep the shared `_crit` helper at lines
  2727-2738 for non-bio hits. The merged `_impact` body should use #2021's
  split at line 2247's call site, so bio criticals do not enter that helper.

## PR #2021 (207f5d71) | Keep sprite kind 29, adapt the vent call

- `godot/fx/fx_shaders.gd:245-246`: drop the old comment and local
  `BIO_CONTACT_GLOB` declaration. Keep sprite selectors 29 at lines 280,
  439 and 445. Use `SH.SPR_BIO_CONTACT_GLOB` in `godot/fx/fx.gd:760`,
  `godot/fx/fx_weapons.gd:2539` and
  `godot/fx/test/status_fx_check.gd:213,250`. Keep both this smoky pool
  entry and #2132's tick droplet entry.
- `godot/fx/fx_weapons.gd:832-848,2534`: take #2049's `_vent` declaration
  and spark gate. Change the bio-contact tail from `Tg, false` to
  `Tg, true, false` (`src, hull_contact, with_sparks`). A single trailing
  `false` would leave sparks on.
- Keep #2021's feel-only bio-critical branch at
  `godot/fx/fx_weapons.gd:2239-2246`. Non-bio criticals still call the
  shared `_crit` with its default spark behavior. When resolving the
  shader conflict, keep merged PR #1904's 2.5 s Acid Thorn etch.
