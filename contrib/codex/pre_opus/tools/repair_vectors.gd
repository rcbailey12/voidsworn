extends SceneTree
const Campaign = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/jsm.gd")
func clean(v: Variant) -> Variant:
	if v is Array:
		var out = []
		for x in v: out.append(clean(x))
		return out
	if v is Dictionary:
		var out = {}
		for k in v:
			if v[k] != null and typeof(v[k]) != TYPE_CALLABLE: out[k] = clean(v[k])
		return out
	return v
func _init() -> void:
	var args = OS.get_cmdline_user_args()
	if args.size() != 1: printerr("output required"); quit(2); return
	var tests = JSON.parse_string(FileAccess.get_file_as_string("res://campaign/test/pre_opus_input.json"))
	if not tests is Array or tests.is_empty(): printerr("missing test inputs"); quit(2); return
	var c = Campaign.new(); var err = c.load_tables()
	if err != "": printerr(err); quit(1); return
	c.persist_on = false; c.fixed_clock = true
	var out = FileAccess.open(args[0], FileAccess.WRITE); var count = 0
	for test in tests:
		c.META = test["meta"].duplicate(true); c.RUN = test["run"].duplicate(true); c.B = null; JSM.rnd_seed(int(test["seed"]))
		var result = c.callv(test["op"], test["args"])
		out.store_line(JSON.stringify({"kind":"repair", "case":test["id"], "result":result, "nem":clean(c.RUN["nem"]), "rng":JSM.rng_s & 0xFFFFFFFF})); count += 1
	out.close(); print(count, " native Godot repair records"); quit()
