# FX combine notes (Refs #2148)

The owner table in `godot/fx/API.md` is the only list of assigned IDs.
The earlier branch offsets no longer apply. No shipped effect was renumbered.

- Main already has the ordnance, status ticks, vent jet, fire, thrusters,
  wreck breaks and beam changes. The ordnance aliases now read the table's
  constants from `fx_shaders.gd`. The null beam reuses `S_NLANCE` for the
  sealed cut, so the old `S_NULL_BURN` reservation is obsolete.
- PR #2069 (`e5d79449`) already moved `SPR_NOVA_LEGACY` off `VENT_JET`.
  The registry adopts its new slot. When taking Build D, keep one declaration
  of `SPR_NOVA_LEGACY` and the symbolic selector in `fx_shaders.gd`. Keep
  the emitter in `fx_special.gd`. The Build D look and its ring IDs are
  outside this ID change.
- PR #2049 (`c15b30ac`) adds no new sprite or wound owner. Its cooling fleck
  already uses `SPR_EMBER`'s kind. In `fx.gd`, make `HOT_FLECK_SPRITE` an
  alias to `SH.SPR_EMBER` when combining. Its shared sparks use the streak
  namespace.
- PR #2215 (`29b288d9`) does not introduce or renumber a sprite or wound id.
- The palette ember (PR #2007) and wet contact glob (PR #2021) reservations
  still fit. For the wet contact puff, if PR #2049 is also present, use the
  `_vent` tail `Tg, true, false` to retain hull contact without metal sparks.
