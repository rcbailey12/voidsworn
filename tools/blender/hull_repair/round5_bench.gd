extends "res://probe.gd"
# Paired old/new controls, preserving the round 4 20-ship measurement loop.

func run() -> void:
	cfg=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	out=cfg["shots"];facets=cfg["factions"];root.size=Vector2i(1920,1080)
	setup_world();view("battle",41.6)
	var blank := await bench("empty")
	var rows: Array = []
	for repeat in 3:
		var order := ["R4V1","V1","R4V2","V2"] if repeat%2==0 else ["V2","R4V2","V1","R4V1"]
		for route in order:
			var ship := model("C19_51",route)
			var geometry := fit(ship,41.6)
			view("battle",41.6)
			await bench(route+"_1")
			var spacing := 41.6*1.15
			cam.look_at_from_position(Vector3(0,cos(.98),sin(.98))*41.6*8,Vector3.ZERO,Vector3.UP)
			ship.position+=Vector3(-2*spacing,0,-1.5*spacing)
			for i in range(1,20):
				var copy := ship.duplicate()
				copy.position+=Vector3((i%5)*spacing,0,(i/5)*spacing)
				holder.add_child(copy)
			var fleet := await bench(route+"_20")
			rows.append({"route":route,"repeat":repeat+1,"geometry":geometry,"fleet":fleet})
			for child in holder.get_children():child.free()
			await settle(5)
	var file := FileAccess.open(str(cfg["work"]).path_join("paired_gpu.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"adapter":RenderingServer.get_video_adapter_name(),
		"renderer":RenderingServer.get_current_rendering_method(),"resolution":[1920,1080],
		"blank":blank,"rows":rows,"probe_sha256":FileAccess.get_sha256("res://round5_bench.gd"),
		"models_sha256":cfg["bench_models_sha256"],
		"method":"3 alternating old/new pairs; identical round 4 camera, MSAA, 100 warm-up and 360 measured frames"},"  ")+"\n")
	file.close();print("[round5] PAIRED GPU PASS");quit(0)
