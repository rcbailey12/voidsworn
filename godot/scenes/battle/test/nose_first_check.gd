extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 521 (R195): the main engine does the travelling. Headless. Builds real rules routes (the rules' step dictionaries:
# ahead, slip, rev, rot), turns them into glide steps through battle.gd's own _glide_steps (and so _nose_first), flies
# them through ShipView.play_glide at the battle's pace and 60 frames a second, and checks:
#   - LOOK only: every move ends exactly on the rules' last hex and the rules' final facing;
#   - the flown hull passes inside every hex of the ruled route (within 0.45 of a hex spacing of each hex centre);
#   - a run of two hexes or more is flown nose first: while the hull moves at more than half its peak speed, its nose is
#     within 35 degrees of its course (no skating on thrusters), except a straight back-off (retro jets, slow) and the
#     one-hex sidestep that ends a dogleg (the allowed one-hex slide);
#   - no heading jump (no frame turns more than 3.5 degrees), no roll;
#   - a one-hex slide is flown on thrusters, slower than a one-hex burn by the slide pace (battle.gd SLIDE_PACE).
# Prints, per class and route, the move time and the time to reach speed.
#   godot --headless --path godot --script res://scenes/battle/test/nose_first_check.gd
const MOVE_HEX := [560.0, 860.0]
const CLASSES := [["Frigate", 0.46, 6.5], ["Cruiser", 0.78, 14.5], ["Dreadnought", 1.18, 27.0]]
const DIRS := [[1, 0], [0, 1], [-1, 1], [-1, 0], [0, -1], [1, -1]]
# A route from facing 0 at hex (0, 0): "A" ahead, "S" slip to starboard (facing + 1), "P" slip to port (facing - 1),
# "R" back off, "T" turn to starboard, "U" turn to port.
const ROUTES := {
	"diagonal5": ["S", "A", "S", "A", "S"],
	"slips3": ["S", "S", "S"],
	"dogleg": ["A", "A", "S"],
	"straight4": ["A", "A", "A", "A"],
	"turn_run": ["T", "A", "A", "A"],
	"run_final": ["A", "A", "A", "T"],
	"back2": ["R", "R"],
	"side1": ["S"],
	"ahead1": ["A"],
}

var fails: Array = []
var B
var SV


func _init() -> void:
	GUARD.arm(self, "nose_first_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
	SV = load("res://render/ship_view.gd")
	B = load("res://scenes/battle/battle.gd").new()
	B.board = load("res://render/board.gd").new()
	for c in CLASSES:
		var sk := (float(c[1]) - 0.5) / 0.45
		sk = clampf(sk if sk <= 1.0 else 1.0 + (sk - 1.0) * 0.5, 0.0, 1.4)
		var line := "%-11s" % c[0]
		var rows := {}
		for name in ROUTES:
			var r := _fly(c, sk, name)
			rows[name] = r
			_check(str(c[0]), name, r)
			line += " | %s %.2f s (speed %.2f)" % [name, r["dur"], r["to_speed"]]
		print(line)
		if float(rows["side1"]["dur"]) < float(rows["ahead1"]["dur"]) * 1.3:
			fails.append("%s: a one-hex slide (%.2f s) is not plainly slower than a one-hex burn (%.2f s)" % [c[0], rows["side1"]["dur"], rows["ahead1"]["dur"]])
	B.board.free()
	B.free()
	if fails.is_empty():
		print("nose first: PASS")
		quit(0)
	else:
		for m in fails:
			printerr("nose first: FAIL: " + str(m))
		quit(1)


# the rules' path for a route, as rules.gd computeReach writes it
func _path(name: String) -> Array:
	var q := 0
	var r := 0
	var f := 0
	var out: Array = []
	for s in ROUTES[name]:
		if s == "T" or s == "U":
			f = (f + (1 if s == "T" else 5)) % 6
			out.append({"q": q, "r": r, "f": f, "rot": true})
			continue
		var df: int = {"A": f, "S": (f + 1) % 6, "P": (f + 5) % 6, "R": (f + 3) % 6}[s]
		q += int(DIRS[df][0])
		r += int(DIRS[df][1])
		var st := {"q": q, "r": r, "f": f}
		if s == "S" or s == "P":
			st["slip"] = 1
		if s == "R":
			st["rev"] = 1
		out.append(st)
	return out


func _fly(c: Array, sk: float, name: String) -> Dictionary:
	var sv = SV.new()
	sv.set_process(false)
	root.add_child(sv)
	sv.L = float(c[2]) * 1.6
	sv.half_w = sv.L * 0.12
	sv.half_h = sv.L * 0.06
	sv.hull = Node3D.new()
	sv.add_child(sv.hull)
	sv._ring()
	sv.position = B.board.hex_world(0, 0)
	sv.cur_yaw = 0.0
	sv.rotation.y = 0.0
	var path := _path(name)
	var hexes: Array = []
	for st in path:
		if not st.has("rot"):
			hexes.append(B.board.hex_world(st["q"], st["r"]))
	var steps: Array = B._glide_steps(sv, path, sk)
	var jets_only: bool = not steps.is_empty() and bool((steps[-1] as Dictionary).get("thrusters", false))
	var per := lerpf(MOVE_HEX[0], MOVE_HEX[1], sk)
	var gopts := {"mass": sk, "cap": 7.0}
	if not steps.is_empty() and bool((steps[-1] as Dictionary).get("nose_first", false)):
		gopts["point"] = B.NF_POINT
		gopts["trail"] = B.NF_TRAIL
	sv.play_glide(steps, per * B.MOVE_CRUISE * (B.SLIDE_PACE if jets_only else 1.0) / 1000.0, gopts)
	var dt := 1.0 / 60.0
	var t := 0.0
	var tel: Array = []
	var prev_yaw := 0.0
	var prev_pos: Vector3 = sv.position
	var near: Array = []
	for h in hexes:
		near.append(INF)
	while sv.burning() and t < 12.0:
		sv._process(dt)
		t += dt
		var pos: Vector3 = sv.position
		var mv := Vector2(pos.x - prev_pos.x, pos.z - prev_pos.z)
		var to_end: float = Vector2(pos.x - (hexes[-1] as Vector3).x, pos.z - (hexes[-1] as Vector3).z).length() if not hexes.is_empty() else 0.0
		tel.append({"t": t, "to_end": to_end, "v": mv.length() / dt, "dir": mv, "yaw": float(sv.cur_yaw), "yr": rad_to_deg(absf(float(sv.cur_yaw) - prev_yaw)) / dt, "roll": sv.rotation.x})
		for k in hexes.size():
			near[k] = minf(float(near[k]), Vector2(pos.x - (hexes[k] as Vector3).x, pos.z - (hexes[k] as Vector3).z).length())
		prev_yaw = float(sv.cur_yaw)
		prev_pos = pos
	var last: Vector3 = hexes[-1] if not hexes.is_empty() else B.board.hex_world(0, 0)
	var end_err := Vector2(sv.position.x - last.x, sv.position.z - last.z).length()
	var yaw_err := absf(angle_difference(float(sv.cur_yaw), SV.yaw_of(path[-1]["f"])))
	sv.queue_free()
	var vpk := 0.0
	for x in tel:
		vpk = maxf(vpk, float(x.v))
	var to_speed := 0.0
	for x in tel:
		if float(x.v) >= vpk * 0.95:
			to_speed = float(x.t)
			break
	return {"dur": t, "to_speed": to_speed, "vpk": vpk, "end_err": end_err, "yaw_err": yaw_err, "near": near, "tel": tel, "n_hex": hexes.size(), "jets_only": jets_only}


func _check(cls: String, name: String, r: Dictionary) -> void:
	var tag := "%s %s" % [cls, name]
	if float(r["end_err"]) > 1e-3 or float(r["yaw_err"]) > 1e-4:
		fails.append("%s: ends off its hex or facing (%.4f units, %.5f rad)" % [tag, r["end_err"], r["yaw_err"]])
	var hexd: float = B.board.HW
	for k in (r["near"] as Array).size():
		if float(r["near"][k]) > 0.45 * hexd:
			fails.append("%s: the hull passes %.2f hexes from route hex %d (outside it)" % [tag, float(r["near"][k]) / hexd, k + 1])
	var worst := 0.0
	for x in r["tel"]:
		if absf(float(x.roll)) > 1e-6:
			fails.append("%s: the hull rolls" % tag)
			break
		if float(x.yr) / 60.0 > 3.5:
			fails.append("%s: the heading jumps %.1f degrees in one frame" % [tag, float(x.yr) / 60.0])
			break
		# a one-hex sidestep at the end of a run (the dogleg) is the allowed one-hex slide: its last hex is not checked
		var tail_ok: bool = name == "dogleg" and float(x.to_end) < hexd
		if int(r["n_hex"]) >= 2 and name != "back2" and not tail_ok and float(x.v) > 0.5 * float(r["vpk"]):
			var d: Vector2 = x.dir
			var nose := Vector2(cos(float(x.yaw)), -sin(float(x.yaw)))
			worst = maxf(worst, rad_to_deg(nose.angle_to(d.normalized())) if d.length() > 1e-6 else 0.0)
	worst = absf(worst)
	if worst > 35.0:
		fails.append("%s: under way the nose is %.0f degrees off the course (skating on thrusters)" % [tag, worst])
	if name in ["side1", "back2"] and not bool(r["jets_only"]):
		fails.append("%s: not flown on thrusters" % tag)
	if name in ["diagonal5", "slips3", "dogleg", "straight4", "turn_run", "run_final", "ahead1"] and bool(r["jets_only"]):
		fails.append("%s: flown on thrusters, not the main engine" % tag)
