extends RefCounted
# Issue 1204: one node_added watcher for every system that needs to see each new mesh (the hull rim lights in
# render/look_rim.gd and the nebula fog guard in world/nebula_hulls.gd). Before it, each of the three listeners
# connected its own node_added and queued its own deferred call, three per new mesh. Now new meshes are collected and
# looked at once, at the end of the frame (the game sets a mesh's materials right after adding it), and every listener
# sees each one in that single pass.
#
# Late materials: a hull whose hull material is set a frame or more after it entered the scene was missed by that one
# look and lost its rim. Code that sets a hull material on a mesh already in the scene calls MeshWatch.touch(mesh)
# (render/ship_view.gd does); the mesh is then looked at again at the end of that frame. A mesh already queued this
# frame is not queued twice.
#
# The watcher lives as metadata on the SceneTree (not in a script static, so nothing outlives the tree) and holds
# only instance ids of the queued meshes and the listeners' callables.

const META := &"mesh_watch"

var _listeners: Array[Callable] = []
var _pending := {}        # instance id -> true, the meshes to look at this frame
var _flush_queued := false
var flushes := 0          # end-of-frame passes so far (the check reads it)


static func of(tree: SceneTree) -> RefCounted:
	if tree == null:
		return null
	var w = tree.get_meta(META) if tree.has_meta(META) else null
	if w == null:
		w = load("res://render/mesh_watch.gd").new()
		tree.set_meta(META, w)
		tree.node_added.connect(w._added)
	return w


# Call `fn` with every GeometryInstance3D that enters the tree (once, at the end of its frame). A listener whose
# object is freed drops out by itself.
static func listen(tree: SceneTree, fn: Callable) -> void:
	var w = of(tree)
	if w != null and not w._listeners.has(fn):
		w._listeners.append(fn)


# Look at `n` (and the meshes under it) again at the end of this frame: its hull material was set after it entered.
static func touch(n: Node) -> void:
	if n == null or not n.is_inside_tree():
		return   # not in the scene yet: node_added sees it when it enters
	var w = of(n.get_tree())
	if n is GeometryInstance3D:
		w._queue(n)
	for g in n.find_children("*", "GeometryInstance3D", true, false):
		w._queue(g)


func _added(n: Node) -> void:
	if n is GeometryInstance3D:
		_queue(n)


func _queue(n: Node) -> void:
	_pending[n.get_instance_id()] = true
	if not _flush_queued:
		_flush_queued = true
		_flush.call_deferred()


func _flush() -> void:
	_flush_queued = false
	flushes += 1
	var ids := _pending.keys()
	_pending.clear()
	var live: Array[Callable] = []
	for fn in _listeners:
		if fn.is_valid():
			live.append(fn)
	_listeners = live
	if live.is_empty():
		return
	for id in ids:
		var n = instance_from_id(id)
		if n == null or not is_instance_valid(n):
			continue
		for fn in live:
			if fn.is_valid():
				fn.call(n)
