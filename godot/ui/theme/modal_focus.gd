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


static func _prune() -> void:
	var keep: Array[int] = []
	for id in _stack:
		var o = instance_from_id(id)
		if o != null and is_instance_valid(o) and (o as Node).is_inside_tree():
			keep.append(id)
	_stack = keep


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
		var p = _prev.get_ref()
		if p != null and is_instance_valid(p):
			_restore.call_deferred(p)


static func _restore(p: Control) -> void:
	if not is_instance_valid(p) or p.is_queued_for_deletion() or not p.is_visible_in_tree():
		return
	var vp := p.get_viewport()
	if vp == null:
		return
	# a newer overlay opened meanwhile keeps the keyboard
	if any_open():
		return
	var fo := vp.gui_get_focus_owner()
	if fo == null or fo.is_queued_for_deletion() or not fo.is_visible_in_tree():
		p.grab_focus()


func _inside(c: Control) -> bool:
	return c != null and is_instance_valid(panel) and (c == panel or panel.is_ancestor_of(c))


func _is_top() -> bool:
	_prune()
	return not _stack.is_empty() and _stack.back() == get_instance_id()


func _on_focus(c: Control) -> void:
	if _fixing or not is_instance_valid(panel) or panel.is_queued_for_deletion() or not panel.is_visible_in_tree():
		return
	if _inside(c):
		_last = weakref(c)
		return
	if _is_top():
		_take.call_deferred()


# focus back inside: the control that last had it there, else the named first one, else the first focusable control
func _take() -> void:
	if not is_inside_tree() or not is_instance_valid(panel) or panel.is_queued_for_deletion() or not panel.is_visible_in_tree():
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
		and not (c is BaseButton and (c as BaseButton).disabled)


static func first_focusable(n: Node) -> Control:
	for ch in n.get_children():
		if ch is Control and _focusable(ch as Control) and (ch as Control).focus_mode == Control.FOCUS_ALL:
			return ch
		var f := first_focusable(ch)
		if f != null:
			return f
	return null
