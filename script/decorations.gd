# decorations.gd
# Zeichnet die platzierten Cosmetics auf dem Feld und stellt den
# Platzierungsmodus bereit (Klick = setzen, Rechtsklick = entfernen).
extends Node2D
class_name Decorations

const FONT      = preload("res://font/PressStart2P-Regular.ttf")
const MIN_Y_PX  = 110.0   # unterhalb der TopBar

var board: Node = null
var placing_id: String = ""

var _sprites: Array = []
var _ghost: Sprite2D
var _hint_layer: CanvasLayer
var _hint_panel: PanelContainer
var _hint_label: Label


func _ready() -> void:
	add_to_group("decorations")
	board = get_node_or_null("../Board")

	_ghost = Sprite2D.new()
	_ghost.centered = false
	_ghost.scale    = Vector2.ONE * Cosmetics.PIXEL_SCALE
	_ghost.visible  = false
	_ghost.z_index  = 10
	add_child(_ghost)

	_build_hint_ui()
	LevelManager.cosmetics_changed.connect(_on_cosmetics_changed)
	set_process_input(false)
	_rebuild()


func _exit_tree() -> void:
	if placing_id != "":
		stop_placing()


# --- Anzeige -----------------------------------------------------------------

func _rebuild() -> void:
	for s in _sprites:
		s.queue_free()
	_sprites.clear()
	for p in LevelManager.placed:
		var sprite = Sprite2D.new()
		sprite.texture  = Cosmetics.make_texture(p.id)
		sprite.centered = false
		sprite.scale    = Vector2.ONE * Cosmetics.PIXEL_SCALE
		var rect = _item_rect(p.id, Vector2i(p.x, p.y))
		sprite.position = rect.position
		add_child(sprite)
		_sprites.append(sprite)


func _on_cosmetics_changed() -> void:
	_rebuild()
	if placing_id != "":
		_update_hint()
		_update_ghost()


func _item_rect(id: String, cell: Vector2i) -> Rect2:
	var size = Cosmetics.size_px(id)
	return Rect2(
		Vector2(cell.x * Cosmetics.CELL, (cell.y + 1) * Cosmetics.CELL - size.y),
		size
	)


# --- Platzierungsmodus ---------------------------------------------------------

func start_placing(id: String) -> void:
	if not Cosmetics.exists(id):
		return
	if placing_id != "":
		stop_placing()
	placing_id = id
	_ghost.texture = Cosmetics.make_texture(id)
	if board:
		board.lock_input()
	_hint_layer.visible = true
	set_process_input(true)
	_update_hint()
	_update_ghost()


func stop_placing() -> void:
	if placing_id == "":
		return
	placing_id = ""
	_ghost.visible      = false
	_hint_layer.visible = false
	set_process_input(false)
	if board and is_instance_valid(board):
		board.unlock_input()


func _input(event: InputEvent) -> void:
	if placing_id == "":
		return

	if event is InputEventMouseMotion:
		_update_ghost()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		stop_placing()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if _hint_panel.get_global_rect().has_point(event.position):
			return   # Klick auf den „Fertig“-Button, nicht auf das Feld
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Tapping a placed item removes it (touch has no right click), otherwise place
			if not _try_remove():
				_try_place()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_try_remove()
			get_viewport().set_input_as_handled()


func _cell_under_mouse() -> Vector2i:
	var m    = get_global_mouse_position()
	var size = Cosmetics.size_px(placing_id)
	var cx   = roundi((m.x - size.x * 0.5) / Cosmetics.CELL)
	var cy   = Cosmetics.GROUND_ROW
	if not Cosmetics.get_def(placing_id).ground:
		cy = clampi(roundi((m.y + size.y * 0.5) / Cosmetics.CELL) - 1, 1, Cosmetics.GROUND_ROW)
	return Vector2i(cx, cy)


func _is_valid(id: String, cell: Vector2i) -> bool:
	var rect = _item_rect(id, cell)
	if rect.position.x < 0 or rect.end.x > get_viewport_rect().size.x:
		return false
	if rect.position.y < MIN_Y_PX:
		return false
	if board:
		var board_rect = Rect2(board.global_position - Vector2.ONE * Board.CELL_SIZE * 0.5,
			Vector2(Board.COLS, Board.ROWS) * Board.CELL_SIZE)
		if rect.intersects(board_rect):
			return false
	for p in LevelManager.placed:
		if rect.intersects(_item_rect(p.id, Vector2i(p.x, p.y))):
			return false
	return true


func _update_ghost() -> void:
	if LevelManager.free_count(placing_id) <= 0:
		_ghost.visible = false
		return
	var cell = _cell_under_mouse()
	_ghost.visible  = true
	_ghost.position = _item_rect(placing_id, cell).position
	_ghost.modulate = Color(1, 1, 1, 0.75) if _is_valid(placing_id, cell) \
		else Color(1, 0.35, 0.35, 0.6)


func _try_place() -> void:
	var cell = _cell_under_mouse()
	if not _is_valid(placing_id, cell):
		return
	if LevelManager.add_placement(placing_id, cell.x, cell.y):
		_puff(_item_rect(placing_id, cell))
		if LevelManager.free_count(placing_id) <= 0:
			stop_placing()


func _try_remove() -> bool:
	var m = get_global_mouse_position()
	for i in range(LevelManager.placed.size() - 1, -1, -1):
		var p = LevelManager.placed[i]
		if _item_rect(p.id, Vector2i(p.x, p.y)).has_point(m):
			_puff(_item_rect(p.id, Vector2i(p.x, p.y)))
			LevelManager.remove_placement(i)
			return true
	return false


# --- Hinweis-Leiste ----------------------------------------------------------

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

	var done = Button.new()
	done.text = "Done"
	done.custom_minimum_size = Vector2(240, 52)
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIStyle.style_button(done, true, 16)
	done.pressed.connect(stop_placing)
	box.add_child(done)


func _update_hint() -> void:
	var def = Cosmetics.get_def(placing_id)
	_hint_label.text = "%s - free: %d\nTap to place, tap an item to remove it" % [
		def.name, LevelManager.free_count(placing_id)
	]


## Small dust cloud at the foot of an item.
func _puff(rect: Rect2) -> void:
	var foot = Vector2(rect.get_center().x, rect.end.y - 6)
	FX.burst(self, foot, [Color(0.95, 0.9, 0.7), Color(0.7, 0.85, 0.4)], 14, 120.0, 8.0, 0.45, 160.0)
