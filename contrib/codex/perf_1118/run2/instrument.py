"""Add isolated CPU counters to a temporary Run 1 benchmark project."""

import argparse
from pathlib import Path


def replace_once(source, anchor, replacement):
    if source.count(anchor) != 1:
        raise ValueError(f"Expected one instrumentation anchor: {anchor!r}")
    return source.replace(anchor, replacement)


def trail_and_shield(source):
    # The candidate calls _trail_mesh only when history changes. Measure its
    # full visible update separately from the count of geometry submissions.
    if "trail_elapsed" in source:
        anchor = '\t\tif changed:\n\t\t\tt["mesh_time"] = fx.now'
        source = replace_once(source, anchor, '\t\tvar trail_started := Time.get_ticks_usec()\n' + anchor)
        source = replace_once(source, '\t\t\tmat.set_shader_parameter("trail_style", float(style))',
                              '\t\t\tmat.set_shader_parameter("trail_style", float(style))\n'
                              '\t\tfx.pend("trail_update", trail_started)')
        anchor = '\t\tentry = [template, template.duplicate()]'
        source = replace_once(source, anchor, anchor + '\n'
                              '\t\tfx.prof["live_damage_materials"] = int(fx.prof.get("live_damage_materials", 0)) + 1')
    else:
        anchor = "\t\t_trail_mesh(fx, t, eng)"
        source = replace_once(source, anchor, '\t\tvar trail_started := Time.get_ticks_usec()\n' + anchor +
                              '\n\t\tfx.pend("trail_update", trail_started)')
    source = replace_once(source, "\tam.clear_surfaces()",
                          '\tfx.prof["trail_uploads"] = int(fx.prof.get("trail_uploads", 0)) + 1\n'
                          "\tam.clear_surfaces()")
    # The old code calculates hull motion before the visibility test. Count
    # that calculation even when no shield was submitted that frame.
    if "var hm := hull_motion()" in source:
        source = replace_once(source, "\tvar hm := hull_motion()",
                              '\tvar shield_started := Time.get_ticks_usec()\n'
                              '\tfx.prof["shield_pose_calls"] = int(fx.prof.get("shield_pose_calls", 0)) + 1\n'
                              '\tvar hm := hull_motion()')
    else:
        check = "\tif _shield_mi != null and _shield_mi.visible:"
        source = replace_once(source, check,
                              '\tvar shield_started := Time.get_ticks_usec()\n' + check +
                              '\n\t\tfx.prof["shield_pose_calls"] = int(fx.prof.get("shield_pose_calls", 0)) + 1')
    source = replace_once(source, "\tvar pos = root.global_position",
                          '\tfx.pend("shield_pose", shield_started)\n\tvar pos = root.global_position')
    skin = next(line for line in source.splitlines() if line.startswith("\tvar skin: Mesh = _shield_skin("))
    return replace_once(source, skin,
        '\tvar cache_before: int = fx.shield_skins.size() if "shield_skins" in fx else -1\n'
        '\tvar profile_key := "shield_seen:" + str([hull.code, hull.box, hull.core, hull.tri_count])\n'
        '\tvar skin_started := Time.get_ticks_usec()\n' + skin +
        '\n\tif _shield_tm != null:\n'
        '\t\tfx.pend("shield_skin_repeat" if fx.prof.has(profile_key) else "shield_skin_first", skin_started)\n'
        '\t\tfx.prof[profile_key] = 1\n'
        '\t\tif cache_before < 0 or fx.shield_skins.size() > cache_before:\n'
        '\t\t\tfx.prof["shield_allocations"] = int(fx.prof.get("shield_allocations", 0)) + 1')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("work", type=Path)
    args = parser.parse_args()
    project = args.work / "godot"
    path = project / "fx/fx_ship.gd"
    source = trail_and_shield(path.read_text(encoding="utf-8"))
    path.write_text(source, encoding="utf-8", newline="\n")
    if "trail_elapsed" not in source:
        path = project / "fx/fx_breach.gd"
        source = path.read_text(encoding="utf-8")
        anchor = '\t\t\tmi.set_surface_override_material(si, HULL.damage_material(src,'
        source = replace_once(source, anchor,
            '\t\t\tif fx != null:\n'
            '\t\t\t\tfx.prof["live_damage_materials"] = int(fx.prof.get("live_damage_materials", 0)) + 1\n' + anchor)
        path.write_text(source, encoding="utf-8", newline="\n")
    path = project / "fx/fx.gd"
    source = path.read_text(encoding="utf-8")
    anchor = "\tHULL.start_late_watch()"
    source = replace_once(source, anchor, anchor + '\n\tprint("PERF1070 LOAD COUNTERS ", JSON.stringify(prof))')
    path.write_text(source, encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
