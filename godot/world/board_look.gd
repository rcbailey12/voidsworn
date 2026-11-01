extends RefCounted
# Board presentation trial (Ryan, Nov 1 16:12: "it almost ends up just looking like a board game on top of a cool
# background"). Four ways to draw the board, switchable while playing so Ryan can pick one; nothing here touches the
# rules or which hexes a ship can reach.
#   today     the board as it was (grey plate, every hex outlined, tinted terrain hexes)
#   holo      A "holo war-table": no plate and no fills; faint holographic grid lines that fade away from the ship that is
#             up and from the cursor; terrain shown by its 3D objects and a thin holo edge; the move area a glowing footprint
#   living    B "living terrain": grid all but gone (hover and planned moves only); nebula, ion storm, debris and the
#             gravity well become real things in space, with only a faint edge for the hex footprint
#   cine      C "tactical toggle": A's grid and footprint with B's terrain, plus one key (Z) or the Grid button that
#             brings up a full tactical grid (tactical = true)
# F8 in battle cycles the four; the choice is kept between runs (user://board_look.cfg). Default: cine (look C, Ryan picked it Nov 1 17:54; "today" stays for comparisons via F8 or VS_BOARD_LOOK=today).

const LOOKS := ["today", "holo", "living", "cine"]
const NAMES := {"today": "Today", "holo": "A  Holo war-table", "living": "B  Living terrain", "cine": "C  Cinematic + tactical toggle"}
const CFG := "user://board_look.cfg"

static var look := ""
static var tactical := false


static func current() -> String:
	if look == "":
		look = "cine"
		var env := OS.get_environment("VS_BOARD_LOOK")
		if env != "" and LOOKS.has(env):
			look = env
		else:
			var cf := ConfigFile.new()
			if cf.load(CFG) == OK:
				var v := str(cf.get_value("board", "look", "cine"))
				if LOOKS.has(v):
					look = v
	return look


static func set_look(l: String, save := true) -> void:
	if not LOOKS.has(l):
		return
	look = l
	if l != "cine":
		tactical = false
	if save:
		var cf := ConfigFile.new()
		cf.set_value("board", "look", l)
		cf.save(CFG)


static func next() -> String:
	var i := LOOKS.find(current())
	set_look(LOOKS[(i + 1) % LOOKS.size()])
	return look


# what each part of the board does in the current look (one place, so board.gd and world.gd agree)
static func spec() -> Dictionary:
	var l := current()
	if l == "cine" and tactical:
		return {"plate": false, "underlay": 0.45, "fills": true, "grid": "tactical", "terrain_edge": 0.9, "reach": "holo", "living": true, "gas_k": 0.35, "old_clouds": false, "funnel": true}
	match l:
		"holo":
			return {"plate": false, "underlay": 0.0, "fills": false, "grid": "holo", "terrain_edge": 0.75, "reach": "holo", "living": false, "gas_k": 1.0, "old_clouds": true, "funnel": true}
		"living":
			return {"plate": false, "underlay": 0.0, "fills": false, "grid": "ghost", "terrain_edge": 0.3, "reach": "today", "living": true, "gas_k": 1.0, "old_clouds": false, "funnel": false}
		"cine":
			return {"plate": false, "underlay": 0.0, "fills": false, "grid": "holo", "terrain_edge": 0.3, "reach": "holo", "living": true, "gas_k": 1.0, "old_clouds": false, "funnel": true}
	return {"plate": true, "underlay": 1.0, "fills": true, "grid": "today", "terrain_edge": 0.0, "reach": "today", "living": false, "gas_k": 1.0, "old_clouds": true, "funnel": false}
