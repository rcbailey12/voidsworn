extends SceneTree
# Issue 505: flown movement, headless. Flies the moves the capture strips show (straight, a turn then a run, a run then
# the final facing, a big turn at a corner, a sidestep, a back-off) for a frigate, a cruiser, a battleship and a
# dreadnought through ShipView.play_glide at the battle's own pace, 60 frames a second, and checks what Ryan asked for:
#   - LOOK only: every move ends exactly on its last hex and its rules facing;
#   - no roll into turns; no heading jump (no frame turns more than 3.5 degrees); a slide or a back-off holds its heading;
#   - a turn inside a move never spins faster than the same ship's turn in place (plus 10 percent);
#   - the drive burns to gain speed (peak above 0.7), is low while coasting (under 0.35), and retro jets fire to stop;
#     a back-off is stopped by the aft jets with the main drive low; nothing on the drive or a jet steps in one frame;
#   - a bigger hull is slower to reach speed, to stop and to turn.
# It prints the measured numbers per class (time to 95% of peak speed, 95% to 5% stop, peak turn rate, move time).
#   godot --headless --path godot --script res://scenes/battle/test/movement_flight_check.gd
#   [-- --sv res://path/to/ship_view.gd --json /tmp/out.json]   (measure another ship_view, e.g. main's, without checks)
const HEX := 18.0
const MOVE_HEX := [560.0, 860.0]
const MOVE_ROT := [0.6, 1.1]
const CLASSES := [["Frigate", 0.46, 6.5], ["Cruiser", 0.78, 14.5], ["Battleship", 0.97, 21.0], ["Dreadnought", 1.18, 27.0]]

var fails: Array = []
var SV


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var sv_path := "res://render/ship_view.gd"
	var i := a.find("--sv")
	if i >= 0:
		sv_path = a[i + 1]
	SV = load(sv_path)
	var j := a.find("--json")
	var strict := i < 0
	var out := {}
	var spin_in_place := {}
	for c in CLASSES:
		var sk := clampf((float(c[1]) - 0.5) / 0.45, 0.0, 1.8 if strict else 1.0)
		var rows := {}
		for mv in ["inplace", "straight", "turn", "final", "corner", "corner2", "side", "back"]:
			if mv == "corner2" and sk > 0.9:
				continue   # battleships and up have one turn a round (data.js tn 1): no 120 degree corner
			var r := _fly(c, sk, mv)
			rows[mv] = r
			if strict:
				_check(str(c[0]), mv, r, spin_in_place.get(c[0], 0.0))
			if mv == "inplace":
				spin_in_place[c[0]] = r["peak_turn"]
		out[c[0]] = rows
		print("%-11s straight: to speed %.2f s, stop %.2f s, %.2f s | turn: peak %.0f deg/s, %.2f s | final: peak %.0f deg/s, %.2f s | in place 60: peak %.0f deg/s, %.2f s | side %.2f s, back %.2f s" % [
			c[0], rows.straight.to_speed, rows.straight.stop, rows.straight.dur, rows.turn.peak_turn, rows.turn.dur,
			rows.final.peak_turn, rows.final.dur, rows.inplace.peak_turn, rows.inplace.dur, rows.side.dur, rows.back.dur])
	if strict:
		var f: Dictionary = out["Frigate"]
		var d: Dictionary = out["Dreadnought"]
		if not (float(d.straight.to_speed) > 2.0 * float(f.straight.to_speed) and float(d.straight.stop) > 2.0 * float(f.straight.stop)):
			fails.append("weight: a dreadnought is not plainly slower to start and stop than a frigate")
		if not (float(d.inplace.peak_turn) < 0.5 * float(f.inplace.peak_turn)):
			fails.append("weight: a dreadnought turns nearly as fast as a frigate")
		if not (float(d.straight.to_speed) > float(out["Battleship"].straight.to_speed)):
			fails.append("weight: a dreadnought starts as fast as a battleship (the size scale stops at battleship)")
	if j >= 0:
		var fo := FileAccess.open(a[j + 1], FileAccess.WRITE)
		fo.store_string(JSON.stringify(out, " "))
		fo.close()
	if fails.is_empty():
		print("movement flight: PASS")
		quit(0)
	else:
		for m in fails:
			printerr("movement flight: FAIL: " + str(m))
		quit(1)


static func _dir(f: int) -> Vector3:
	var y := -deg_to_rad(60.0 * f)
	return Vector3(cos(y), 0, -sin(y))


# the glide steps battle.gd _glide_steps makes for each move, from facing 0 at the origin: "F<f>" a step to the next hex
# along facing f (the heading does not change), "T" a 60 degree turn to starboard
const MOVES := {"inplace": ["T"], "straight": ["F0", "F0", "F0"], "turn": ["T", "F1", "F1"], "final": ["F0", "F0", "T"],
	"corner": ["F0", "T", "F1"], "corner2": ["F0", "T", "T", "F2"], "side": ["F1"], "back": ["F3"]}


func _steps(mv: String, sk: float) -> Array:
	var w := lerpf(MOVE_ROT[0], MOVE_ROT[1], sk)
	var p := Vector3.ZERO
	var out: Array = []
	var yaw := 0.0
	for s in MOVES[mv]:
		if s == "T":
			yaw += -deg_to_rad(60.0)
			out.append({"kind": "turn", "yaw": yaw, "w": w})
		else:
			p += _dir(int(s.substr(1))) * HEX
			out.append({"kind": "move", "p": p, "w": 1.0})
	return [out, p, yaw]


func _fly(c: Array, sk: float, mv: String) -> Dictionary:
	var sv = SV.new()
	sv.set_process(false)
	root.add_child(sv)
	sv.L = float(c[2]) * 1.6
	sv.half_w = sv.L * 0.12
	sv.half_h = sv.L * 0.06
	sv.hull = Node3D.new()
	sv.add_child(sv.hull)
	sv._ring()
	sv.position = Vector3.ZERO
	sv.cur_yaw = 0.0
	sv.rotation.y = 0.0
	var st: Array = _steps(mv, sk)
	var per := lerpf(MOVE_HEX[0], MOVE_HEX[1], sk)
	sv.play_glide(st[0], per * 0.8 / 1000.0, {"mass": sk, "cap": 7.0})
	var dt := 1.0 / 60.0
	var t := 0.0
	var tel: Array = []
	var prev_yaw := 0.0
	var prev_pos := Vector3.ZERO
	var has_jets: bool = sv.get("jet_retro") != null
	while sv.burning() and t < 12.0:
		sv._process(dt)
		t += dt
		var yaw: float = sv.cur_yaw
		var pos: Vector3 = sv.position
		tel.append({"t": t, "v": Vector2(pos.x - prev_pos.x, pos.z - prev_pos.z).length() / dt, "yr": rad_to_deg(absf(yaw - prev_yaw)) / dt,
			"yaw": yaw, "roll": sv.rotation.x, "drive": float(sv.thrust),
			"retro": float(sv.jet_retro) if has_jets else 0.0, "aft": float(sv.jet_aft) if has_jets else 0.0,
			"side": float(sv.jet_side) if has_jets else 0.0, "tj": float(sv.jet_turn) if has_jets else 0.0})
		prev_yaw = yaw
		prev_pos = pos
	var end_err: float = Vector2(sv.position.x - (st[1] as Vector3).x, sv.position.z - (st[1] as Vector3).z).length()
	var yaw_err: float = absf(angle_difference(sv.cur_yaw, float(st[2])))
	sv.queue_free()
	var vpk := 0.0
	var ypk := 0.0
	for r in tel:
		vpk = maxf(vpk, r.v)
		ypk = maxf(ypk, r.yr)
	var to_speed := 0.0
	var last_full := 0.0
	var stop := 0.0
	if vpk > 1e-3:
		for r in tel:
			if r.v >= vpk * 0.95:
				if to_speed == 0.0:
					to_speed = r.t
				last_full = r.t
		for r in tel:
			if r.t > last_full and r.v <= vpk * 0.05:
				stop = r.t - last_full
				break
	return {"dur": t, "to_speed": to_speed, "stop": stop, "peak_speed": vpk, "peak_turn": ypk, "end_err": end_err, "yaw_err": yaw_err, "tel": tel}


func _check(cls: String, mv: String, r: Dictionary, inplace_peak: float) -> void:
	var tag := "%s %s" % [cls, mv]
	var tel: Array = r["tel"]
	if float(r["end_err"]) > 1e-3 or float(r["yaw_err"]) > 1e-4:
		fails.append("%s: ends off its hex or facing (%.4f units, %.5f rad)" % [tag, r["end_err"], r["yaw_err"]])
	var n := tel.size()
	var max_dd := 0.0
	var max_dj := 0.0
	for i in n:
		var x: Dictionary = tel[i]
		if absf(float(x.roll)) > 1e-6:
			fails.append("%s: the hull rolls (%.3f rad)" % [tag, x.roll])
			break
		if float(x.yr) / 60.0 > 3.5:
			fails.append("%s: the heading jumps %.1f degrees in one frame" % [tag, float(x.yr) / 60.0])
			break
		if mv in ["side", "back", "straight"] and absf(float(x.yaw)) > 1e-4:
			fails.append("%s: the heading does not hold (%.4f rad)" % [tag, x.yaw])
			break
		if i > 0:
			var y: Dictionary = tel[i - 1]
			max_dd = maxf(max_dd, absf(float(x.drive) - float(y.drive)))
			for k in ["retro", "aft", "side", "tj"]:
				max_dj = maxf(max_dj, absf(float(x[k]) - float(y[k])))
	if max_dd > 0.15 or max_dj > 0.25:
		fails.append("%s: a drive or jet level steps in one frame (drive %.2f, jet %.2f)" % [tag, max_dd, max_dj])
	if mv != "inplace" and inplace_peak > 0.0 and float(r["peak_turn"]) > inplace_peak * 1.1 + 1.0:
		fails.append("%s: turns at %.0f deg/s, faster than its own turn in place (%.0f)" % [tag, r["peak_turn"], inplace_peak])
	var peak := func(key: String, a: float, b: float, sgn := 1.0) -> float:
		var m := 0.0
		for x in tel:
			if float(x.t) >= a * float(r["dur"]) and float(x.t) <= b * float(r["dur"]):
				m = maxf(m, float(x[key]) * sgn)
		return m
	match mv:
		"straight":
			if peak.call("drive", 0.0, 0.45) < 0.7:
				fails.append("%s: no hard burn to gain speed" % tag)
			if peak.call("retro", 0.5, 1.0) < 0.5:
				fails.append("%s: no retro burn to stop" % tag)
			if peak.call("drive", 0.75, 1.0) > 0.3:
				fails.append("%s: the drive burns while the ship brakes" % tag)
			var mid: Dictionary = tel[n / 2]
			if float(mid.v) > float(r["peak_speed"]) * 0.9 and float(mid.drive) > 0.35:
				fails.append("%s: the drive is high while coasting (%.2f)" % [tag, mid.drive])
		"back":
			if peak.call("aft", 0.4, 1.0) < 0.4 or peak.call("retro", 0.0, 0.6) < 0.4:
				fails.append("%s: a back-off is not pushed by the retro jets and stopped by the aft jets" % tag)
			if peak.call("drive", 0.0, 1.0) > 0.2:
				fails.append("%s: the main drive lights on a back-off" % tag)
		"side":
			if maxf(peak.call("side", 0.0, 1.0), peak.call("side", 0.0, 1.0, -1.0)) < 0.4:
				fails.append("%s: a sidestep has no side jets" % tag)
		"inplace", "turn", "final", "corner", "corner2":
			if peak.call("tj", 0.0, 1.0) < 0.4 or peak.call("tj", 0.0, 1.0, -1.0) < 0.4:
				fails.append("%s: the turn is not started and stopped by opposite turning jets" % tag)
