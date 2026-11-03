# decorations.gd
# Draws the placed cosmetics on the meadow and provides two modes:
#  - placing: put a bought item on the field (click = place, R = rotate)
#  - editing: drag any placed item to a new spot (R rotates the picked item)
# Positions are stored in cell units (96 px) as floats, snapped to the pixel grid.
# Items snap onto the meadow or onto the top of other items.
extends Node2D
class_name Decorations

const FONT      = preload("res://font/PressStart2P-Regular.ttf")
const MIN_Y_PX  = 110.0   # below the TopBar
const SNAP      = 16.0    # steps per cell = one source pixel at scale 6
const SNAP_DIST = 30.0    # pull onto the meadow or another item within this distance (px)

var board: Node = null
var placing_id: String = ""
var placing_rot: int = 0
var editing: bool = false

var _sprites: Array = []
var _ghost: Sprite2D
var _hint_layer: CanvasLayer
var _hint_panel: PanelContainer
var _hint_label: Label
var _put_back: Button

var _selected: int = -1          # index in LevelManager.placed
var _dragging: bool = false
var _grab_offset: Vector2 = Vector2.ZERO
var _drag_pos: Vector2 = Vector2.ZERO
var _mouse: Vector2 = Vector2.ZERO   # pointer in world coordinates, taken from the events


func _ready() -> void:
	add_to_group("decorations")
	board = get_node_or_null("../Board")

	_ghost = Sprite2D.new()
	_ghost.visible = false
	_ghost.z_index = 10
	add_child(_ghost)

	_build_hint_ui()
	LevelManager.cosmetics_changed.connect(_on_cosmetics_changed)
	set_process_input(false)
	_rebuild()


func _exit_tree() -> void:
	_end_mode()


# --- Display -----------------------------------------------------------------

func _rebuild() -> void:
	for s in _sprites:
		s.queue_free()
	_sprites.clear()
	for p in LevelManager.placed:
		var sprite = Sprite2D.new()
		sprite.texture  = Cosmetics.make_texture(p.id)
		sprite.scale    = Vector2.ONE * Cosmetics.scale_of(p.id)
		var rot = int(p.get("rot", 0))
		sprite.position = _item_rect(p.id, Vector2(p.x, p.y), rot).get_center()
		sprite.rotation = rot * PI / 2.0
		add_child(sprite)
		_sprites.append(sprite)


func _on_cosmetics_changed() -> void:
	_rebuild()
	if _selected >= LevelManager.placed.size():
		_selected = -1
	if placing_id != "":
		_update_hint()
		_update_ghost()


## Screen rectangle of an item; the cell is a position in cell units.
func _item_rect(id: String, cell: Vector2, rot: int = 0) -> Rect2:
	var size = Cosmetics.size_px(id, rot)
	return Rect2(
		Vector2(cell.x * Cosmetics.CELL, (cell.y + 1.0) * Cosmetics.CELL - size.y),
		size
	)


func _placed_rect(i: int) -> Rect2:
	var p = LevelManager.placed[i]
	return _item_rect(p.id, Vector2(p.x, p.y), int(p.get("rot", 0)))


# --- Modes -------------------------------------------------------------------

func _begin_mode() -> void:
	_end_mode()
	if board:
		board.lock_input()
	_hint_layer.visible = true
	_mouse = get_global_mouse_position()
	set_process_input(true)


func _end_mode() -> void:
	if placing_id == "" and not editing:
		return
	placing_id = ""
	editing    = false
	_dragging  = false
	_selected  = -1
	_ghost.visible      = false
	_hint_layer.visible = false
	set_process_input(false)
	_rebuild()
	if board and is_instance_valid(board):
		board.unlock_input()


func start_placing(id: String) -> void:
	if not Cosmetics.exists(id):
		return
	_begin_mode()
	placing_id  = id
	placing_rot = 0
	_ghost.texture = Cosmetics.make_texture(id)
	_ghost.scale   = Vector2.ONE * Cosmetics.scale_of(id)
	_update_hint()
	_update_ghost()


func stop_placing() -> void:
	_end_mode()


func start_editing() -> void:
	_begin_mode()
	editing = true
	_update_hint()


func stop_editing() -> void:
	_end_mode()


func _input(event: InputEvent) -> void:
	if placing_id == "" and not editing:
		return
	if event is InputEventMouse:
		_mouse = get_canvas_transform().affine_inverse() * event.position

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_end_mode()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_rotate()
		get_viewport().set_input_as_handled()
		return

	# Clicks on the hint bar belong to its buttons. Let press and release through
	# (a button fires on release), unless a drag is in progress.
	if event is InputEventMouseButton and not _dragging \
			and _hint_panel.get_global_rect().has_point(event.position):
		return

	if editing:
		_edit_input(event)
	else:
		_place_input(event)


func _place_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_ghost()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_place()   # clicking onto an item stacks on it; removing is done in edit mode
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_try_remove()
			get_viewport().set_input_as_handled()


func _edit_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_begin_drag()
			else:
				_end_drag()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_try_remove()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging:
		_drag_to_mouse()


func _top_item_at(point: Vector2) -> int:
	for i in range(LevelManager.placed.size() - 1, -1, -1):
		if _placed_rect(i).has_point(point):
			return i
	return -1


func _begin_drag() -> void:
	var m = _mouse
	_selected = _top_item_at(m)
	_dragging = _selected >= 0
	if _dragging:
		_grab_offset = m - _placed_rect(_selected).position
		_drag_pos = Vector2(LevelManager.placed[_selected].x, LevelManager.placed[_selected].y)
		_sprites[_selected].z_index = 10


func _drag_to_mouse() -> void:
	var p   = LevelManager.placed[_selected]
	var rot = int(p.get("rot", 0))
	var pos = _snap_cell(_mouse - _grab_offset, p.id, rot, _selected)
	_drag_pos = pos
	var sprite: Sprite2D = _sprites[_selected]
	sprite.position = _item_rect(p.id, pos, rot).get_center()
	sprite.modulate = Color.WHITE if _is_valid(p.id, pos, rot) else Color(1, 0.45, 0.45, 0.8)


func _end_drag() -> void:
	if not _dragging:
		return
	_dragging = false
	var p   = LevelManager.placed[_selected]
	var rot = int(p.get("rot", 0))
	if _is_valid(p.id, _drag_pos, rot):
		_puff(_item_rect(p.id, _drag_pos, rot))
		LevelManager.move_placement(_selected, _drag_pos.x, _drag_pos.y, rot)
	else:
		_rebuild()   # invalid spot: snap back


func _rotate() -> void:
	if editing:
		if _selected < 0 or _selected >= LevelManager.placed.size():
			_selected = _top_item_at(_mouse)
		if _selected < 0:
			return
		var p   = LevelManager.placed[_selected]
		var rot = (int(p.get("rot", 0)) + 1) % 4
		# Turn around the item's center
		var pos = _snap_cell(_placed_rect(_selected).get_center() - Cosmetics.size_px(p.id, rot) * 0.5, p.id, rot, _selected)
		if _is_valid(p.id, pos, rot):
			LevelManager.move_placement(_selected, pos.x, pos.y, rot)
	elif placing_id != "":
		placing_rot = (placing_rot + 1) % 4
		_update_ghost()


# --- Position helpers --------------------------------------------------------

## Converts a top-left pixel position into a snapped cell position. Items can
## sit anywhere; near the meadow or the top of another item they snap onto it,
## so a potion can stand on a mushroom.
func _snap_cell(top_left: Vector2, id: String, rot: int, ignore: int = -1) -> Vector2:
	var size = Cosmetics.size_px(id, rot)
	var cx = snappedf(top_left.x / Cosmetics.CELL, 1.0 / SNAP)
	var left = cx * Cosmetics.CELL
	var bottom = top_left.y + size.y

	var ground = float(Cosmetics.GROUND_ROW + 1) * Cosmetics.CELL
	var surface = ground
	var best = INF
	for i in LevelManager.placed.size():
		if i == ignore:
			continue
		var r = _placed_rect(i)
		if left < r.end.x and left + size.x > r.position.x:
			var d = abs(bottom - r.position.y)
			if d < best:
				best = d
				surface = r.position.y
	var snapped_to_item = best <= SNAP_DIST and abs(bottom - surface) < abs(bottom - ground)
	if snapped_to_item or abs(bottom - ground) <= SNAP_DIST:
		bottom = surface if snapped_to_item else ground
	elif bottom > ground:
		bottom = ground
	else:
		bottom = snappedf(bottom, Cosmetics.CELL / SNAP)
	return Vector2(cx, bottom / Cosmetics.CELL - 1.0)


func _cell_under_mouse() -> Vector2:
	var size = Cosmetics.size_px(placing_id, placing_rot)
	return _snap_cell(_mouse - size * 0.5, placing_id, placing_rot)


func _is_valid(id: String, cell: Vector2, rot: int = 0) -> bool:
	var rect = _item_rect(id, cell, rot)
	if rect.position.x < 0 or rect.end.x > get_viewport_rect().size.x:
		return false
	if rect.position.y < MIN_Y_PX:
		return false
	if board:
		if rect.intersects(board.grid_rect()):
			return false
	return true   # items may overlap, so lamps can stand in front of backgrounds


func _update_ghost() -> void:
	if LevelManager.free_count(placing_id) <= 0:
		_ghost.visible = false
		return
	var cell = _cell_under_mouse()
	_ghost.visible  = true
	_ghost.position = _item_rect(placing_id, cell, placing_rot).get_center()
	_ghost.rotation = placing_rot * PI / 2.0
	_ghost.modulate = Color(1, 1, 1, 0.75) if _is_valid(placing_id, cell, placing_rot) \
		else Color(1, 0.35, 0.35, 0.6)


func _try_place() -> void:
	var cell = _cell_under_mouse()
	if not _is_valid(placing_id, cell, placing_rot):
		return
	if LevelManager.add_placement(placing_id, cell.x, cell.y, placing_rot):
		_puff(_item_rect(placing_id, cell, placing_rot))
		if LevelManager.free_count(placing_id) <= 0:
			_end_mode()


func _try_remove() -> bool:
	var i = _top_item_at(_mouse)
	if i < 0:
		return false
	_puff(_placed_rect(i))
	_dragging = false
	_selected = -1
	LevelManager.remove_placement(i)
	return true


# --- Hint bar ----------------------------------------------------------------

func _build_hint_ui() -> void:
	_hint_layer = CanvasLayer.new()
	_hint_layer.layer   = 5
	_hint_layer.visible = false
	add_child(_hint_layer)

	_hint_panel = PanelContainer.new()
	_hint_panel.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL, UIStyle.PANEL_EDGE, 12, 3))
	_hint_panel.anchor_left   = 0.5
	_hint_panel.anchor_right  = 0.5
	_hint_panel.offset_left   = -520
	_hint_panel.offset_right  = 520
	_hint_panel.offset_top    = 120
	_hint_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint_layer.add_child(_hint_panel)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_hint_panel.add_child(box)

	_hint_label = Label.new()
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_override("font", FONT)
	_hint_label.add_theme_font_size_override("font_size", 16)
	box.add_child(_hint_label)

	var buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	box.add_child(buttons)

	var rotate = Button.new()
	rotate.text = "Rotate (R)"
	rotate.custom_minimum_size = Vector2(240, 52)
	UIStyle.style_button(rotate, false, 16)
	rotate.pressed.connect(_rotate)
	buttons.add_child(rotate)

	_put_back = Button.new()
	_put_back.text = "Put back"
	_put_back.custom_minimum_size = Vector2(240, 52)
	UIStyle.style_button(_put_back, false, 16)
	_put_back.pressed.connect(_put_back_selected)
	buttons.add_child(_put_back)

	var done = Button.new()
	done.text = "Done"
	done.custom_minimum_size = Vector2(240, 52)
	UIStyle.style_button(done, true, 16)
	done.pressed.connect(_end_mode)
	buttons.add_child(done)


func _put_back_selected() -> void:
	if _selected < 0 or _selected >= LevelManager.placed.size():
		return
	_puff(_placed_rect(_selected))
	var i = _selected
	_selected = -1
	_dragging = false
	LevelManager.remove_placement(i)


func _update_hint() -> void:
	_put_back.visible = editing
	if editing:
		_hint_label.text = "Edit mode\nDrag to move, R rotates, Put back stores the picked item"
		return
	var def = Cosmetics.get_def(placing_id)
	_hint_label.text = "%s - free: %d\nTap to place, R rotates. Edit meadow moves or removes items" % [
		def.name, LevelManager.free_count(placing_id)
	]


## Small dust cloud at the foot of an item.
func _puff(rect: Rect2) -> void:
	var foot = Vector2(rect.get_center().x, rect.end.y - 6)
	FX.burst(self, foot, [Color(0.95, 0.9, 0.7), Color(0.7, 0.85, 0.4)], 14, 120.0, 8.0, 0.45, 160.0)
