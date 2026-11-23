extends Node
# Issue 1559 (menus audit, common cause A): one shared way to make an overlay modal for the keyboard, so the battle menu,
# Career, the title's Settings and Credits drawers, the rename dialog and the debrief detail all behave the same:
#   - on open, the overlay takes keyboard focus (its first focusable control, or the one named), unless focus is already
#     inside it;
#   - while it is the topmost open overlay, focus cannot leave it: Tab, Shift+Tab, the arrows, a window resize or a
#     screen behind that grabs focus for itself all land back inside (on the control that last had focus there, else the
#     first one);
#   - on close, focus goes back to what had it before the overlay opened, when that is still on screen.
# Overlays stack: only the newest open one traps, so a menu over the end card hands focus back to the card when it closes.
# blocker() adds a clear full-screen sheet under an overlay so mouse clicks cannot reach the screen or the board behind.
# Use: ModalFocus.attach(panel) once the panel is in the tree or about to be added (it waits for the panel's tree).

static var _stack: Array[int] = []   # instance ids of the open traps, newest last


# the static stack goes at exit with the other statics (tools/ci gpu_statics: every script static gets a clear)
static func clear_static() -> void:
	_stack.clear()

var panel: Control
var first: Control = null
var _prev: WeakRef = null
var _last: WeakRef = null
var _fixing := false


static func attach(p: Control, first_focus: Control = null) -> Node:
	var m = load("res://ui/theme/modal_focus.gd").new()
	m.name = "modal_focus"
	m.panel = p
	m.first = first_focus
	p.add_child(m, false, Node.INTERNAL_MODE_BACK)
	return m


# A clear sheet over the whole viewport that eats mouse input, for the parent's children drawn before the overlay.
static func blocker(parent: Control) -> Control:
	var b := Control.new()
	b.name = "modal_blocker"
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.focus_mode = Control.FOCUS_NONE
	parent.add_child(b)
	return b


# True when an open trap other than the one given (or any, with none given) is on top.
static func any_open() -> bool:
	_prune()
	return not _stack.is_empty()


# The newest open overlay's panel, or null. A screen's own key handler gives way to an overlay that is not part of it:
# if top_panel() is not null and not inside the screen, the key is the overlay's (issue 1559 item 5).
static func top_panel() -> Control:
	_prune()
	if _stack.is_empty():
		return null
	var o = instance_from_id(_stack.back())
	return o.panel if o != null and is_instance_valid(o.panel) else null


# True when the screen under `screen` should leave keys alone because an overlay outside it is open.
static func covered(screen: Node) -> bool:
	var t := top_panel()
	return t != null and screen != null and t != screen and not screen.is_ancestor_of(t)


static func _prune() -> void:
	var keep: Array[int] = []
	for id in _stack:
		var o = instance_from_id(id)
		if o != null and is_instance_valid(o) and (o as Node).is_inside_tree() and not o._gone():
			keep.append(id)
	_stack = keep


# the overlay is closing: it, or a screen it sits in, is queued for deletion (a re-render frees the old page whole)
func _gone() -> bool:
	if not is_instance_valid(panel):
		return true
	var n: Node = panel
	while n != null:
		if n.is_queued_for_deletion():
			return true
		n = n.get_parent()
	return false


func _ready() -> void:
	var vp := get_viewport()
	var fo := vp.gui_get_focus_owner()
	if fo != null and not _inside(fo) and not fo.is_queued_for_deletion():
		_prev = weakref(fo)
	_prune()
	_stack.append(get_instance_id())
	vp.gui_focus_changed.connect(_on_focus)
	if fo == null or not _inside(fo):
		_take.call_deferred()


func _exit_tree() -> void:
	_stack.erase(get_instance_id())
	var vp := get_viewport()
	if vp != null and vp.gui_focus_changed.is_connected(_on_focus):
		vp.gui_focus_changed.disconnect(_on_focus)
	if _prev != null:
		_restore.call_deferred(_prev)


# ref: a WeakRef to the control that had focus before the overlay opened (it may be gone by the time this runs)
static func _restore(ref: WeakRef) -> void:
	var p = ref.get_ref()
	if p == null or not is_instance_valid(p) or not (p is Control) or p.is_queued_for_deletion() or not p.is_visible_in_tree():
		return
	var vp: Viewport = (p as Control).get_viewport()
	if vp == null:
		return
	# an overlay still open (a newer one, or the one this closed overlay sat on) keeps the keyboard: back to p when it is
	# inside that overlay, else to the overlay's own last control
	_prune()
	if not _stack.is_empty():
		var top = instance_from_id(_stack.back())
		if top != null and top._inside(p):
			p.grab_focus()
		elif top != null:
			top._take()
		return
	var fo: Control = vp.gui_get_focus_owner()
	if fo == null or fo.is_queued_for_deletion() or not fo.is_visible_in_tree():
		p.grab_focus()


func _inside(c: Control) -> bool:
	return c != null and is_instance_valid(panel) and (c == panel or panel.is_ancestor_of(c))


func _is_top() -> bool:
	_prune()
	return not _stack.is_empty() and _stack.back() == get_instance_id()


func _on_focus(c: Control) -> void:
	if _fixing or _gone() or not panel.is_visible_in_tree():
		return
	if _inside(c):
		_last = weakref(c)
		return
	if _is_top():
		_take.call_deferred()


# focus back inside: the control that last had it there, else the named first one, else the first focusable control
func _take() -> void:
	if not is_inside_tree() or _gone() or not panel.is_visible_in_tree():
		return
	if not _is_top():
		return
	var fo := get_viewport().gui_get_focus_owner()
	if _inside(fo):
		return
	var want: Control = null
	if _last != null:
		var l = _last.get_ref()
		if l != null and is_instance_valid(l) and _focusable(l):
			want = l
	if want == null and first != null and is_instance_valid(first) and _focusable(first):
		want = first
	if want == null:
		want = first_focusable(panel)
	if want != null:
		_fixing = true
		want.grab_focus()
		_fixing = false
		_last = weakref(want)


static func _focusable(c: Control) -> bool:
	return c.focus_mode != Control.FOCUS_NONE and c.is_visible_in_tree() and not c.is_queued_for_deletion() \
		and not ("disabled" in c and c.disabled)


static func focus_key(c: Control) -> String:
	if not is_instance_valid(c): return ""
	if c.has_meta("press_act"):
		return "action:" + str(c.get_meta("press_act")) + "|" + str(c.get_meta("press_arg", ""))
	return "" if str(c.name).begins_with("@") else "name:" + str(c.name)


static func find_focus_key(n: Node, key: String) -> Control:
	if n.is_queued_for_deletion() or key.is_empty(): return null
	if n is Control and _focusable(n) and focus_key(n) == key: return n
	for ch in n.get_children():
		var found := find_focus_key(ch, key)
		if found != null: return found
	return null


static func nearest_button(scroll: ScrollContainer, point: Vector2) -> Control:
	var nearest: Control = null
	var distance := INF
	var bounds := scroll.get_global_rect()
	for node in scroll.find_children("*", "Control", true, false):
		if not node.has_signal("pressed") or not _focusable(node): continue
		var rect: Rect2 = node.get_global_rect()
		if not bounds.intersects(rect): continue
		var next: float = rect.get_center().distance_squared_to(point)
		if next < distance:
			distance = next
			nearest = node
	return nearest


static func first_focusable(n: Node) -> Control:
	for ch in n.get_children():
		if ch is Control and _focusable(ch as Control) and (ch as Control).focus_mode == Control.FOCUS_ALL:
			return ch
		var f := first_focusable(ch)
		if f != null:
			return f
	return null
