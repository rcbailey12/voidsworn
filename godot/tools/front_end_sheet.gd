extends SceneTree
# Contact sheets of the start screens (issue 1217 phase 5): one sheet per phase prefix (F2 title, F3 desk, F4 flagship,
# F5 Progression, Lineage and Help) from the pictures front_end_shots.gd saved, each sheet no taller than 720 px and no
# wider than 1600 px, saved through the shared provenance writer. Run by tools/pc/jobs/frontend_ui_check.bat.
#   godot --headless --path godot --script res://tools/front_end_sheet.gd -- <shots dir> <out dir>
const MAX_W := 1600
const MAX_H := 720
const GAP := 8


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() < 2:
		print("usage: -- <shots dir> <out dir>"); quit(2); return
	var src := str(a[0]); var out := str(a[1])
	DirAccess.make_dir_recursive_absolute(out)
	var groups := {}
	for f in DirAccess.get_files_at(src):
		if not f.ends_with(".png") or f.begins_with("sheet_"): continue
		var pre := f.get_slice("_", 0)
		if not groups.has(pre): groups[pre] = []
		groups[pre].append(src.path_join(f))
	var made := 0
	for pre in groups.keys():
		var files: Array = groups[pre]; files.sort()
		var imgs := []
		for p in files:
			var im := Image.load_from_file(p)
			if im != null and not im.is_empty(): imgs.append(im)
		if imgs.is_empty(): continue
		var n := imgs.size()
		var ar := float(imgs[0].get_width()) / float(imgs[0].get_height())
		# the column count that gives the biggest thumbnails inside MAX_W x MAX_H
		var best_cols := 1; var best_w := 0.0
		for cols in range(1, n + 1):
			var rows := int(ceil(float(n) / cols))
			var w := minf((MAX_W - GAP * (cols + 1)) / float(cols), ((MAX_H - GAP * (rows + 1)) / float(rows)) * ar)
			if w > best_w: best_w = w; best_cols = cols
		var tw := int(floor(best_w)); var th := int(floor(best_w / ar))
		var rows2 := int(ceil(float(n) / best_cols))
		var sheet := Image.create(GAP + best_cols * (tw + GAP), GAP + rows2 * (th + GAP), false, Image.FORMAT_RGB8)
		sheet.fill(Color(0.05, 0.055, 0.065))
		for i in n:
			var t: Image = imgs[i].duplicate()
			t.convert(Image.FORMAT_RGB8)
			t.resize(tw, th, Image.INTERPOLATE_LANCZOS)
			sheet.blit_rect(t, Rect2i(0, 0, tw, th), Vector2i(GAP + (i % best_cols) * (tw + GAP), GAP + (i / best_cols) * (th + GAP)))
		var dest := out.path_join("sheet_" + pre + ".png")
		preload("res://tools/picture_provenance.gd").save_png(sheet, dest, preload("res://tools/picture_provenance.gd").capture_stage())
		print("[front-end-sheet] ", dest, " ", n, " pictures, ", sheet.get_width(), "x", sheet.get_height())
		made += 1
	print("[front-end-sheet] ", made, " sheet(s)")
	quit(0 if made > 0 else 1)
