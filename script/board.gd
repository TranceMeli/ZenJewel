extends Node2D
class_name Board

const ROWS        = 8
const COLS        = 8
const CELL_SIZE   = 64
const FLOOR_Y     = 832   # bottom edge of the dark pit in the frame
const DISPLAY_SCALE = 1.3125   # 64 px cells drawn at 84 px
const SWAP_SPEED  = 0.2
const FALL_SPEED  = 0.12

const POINTS_3    = 30
const POINTS_4    = 80
const POINTS_5    = 200

const COINS_3     = 1
const COINS_4     = 3
const COINS_5     = 8


var jewel_scenes = [
	preload("res://scene/jewel0.tscn"),
	preload("res://scene/jewel1.tscn"),
	preload("res://scene/jewel2.tscn"),
	preload("res://scene/jewel3.tscn"),
	preload("res://scene/jewel4.tscn"),
	preload("res://scene/jewel5.tscn"),
]

var special_scenes = {
	SpecialType.Type.COLOR:  preload("res://scene/jewel_color.tscn"),
	SpecialType.Type.LINE_H: preload("res://scene/jewel_line_h.tscn"),
	SpecialType.Type.LINE_V: preload("res://scene/jewel_line_v.tscn"),
	SpecialType.Type.BOMB:   preload("res://scene/jewel_bomb.tscn"),
}

var grid:           Array = []
var first_selected: Node  = null
var is_busy:        bool  = false
var input_locks:    int   = 0
var combo:          int   = 0

@onready var effects         : BoardEffects   = $BoardEffects
@onready var gravity         : BoardGravity   = $BoardGravity
@onready var special_handler : SpecialHandler = $SpecialHandler
@onready var ui_bridge                        = $BoardUIBridge

@onready var sound_swap    = $SoundSwap    if has_node("SoundSwap")    else null
@onready var sound_match   = $SoundMatch   if has_node("SoundMatch")   else null
@onready var sound_nomatch = $SoundNoMatch if has_node("SoundNoMatch") else null
@onready var sound_combo   = $SoundCombo   if has_node("SoundCombo")   else null
@onready var sound_special = $SoundSpecial if has_node("SoundSpecial") else null


func _ready() -> void:
	special_handler.setup(self)
	effects.setup(CELL_SIZE, ROWS, COLS)
	create_grid()
	center_board()
	ui_bridge.refresh()
	is_busy = true
	await _ensure_playable()
	is_busy = false


func create_grid() -> void:
	grid = []
	for row in range(ROWS):
		grid.append([])
		for col in range(COLS):
			grid[row].append(_spawn_jewel(row, col, _safe_random_type(row, col)))


func _safe_random_type(row: int, col: int) -> int:
	var excluded: Array = []
	if col >= 2 and grid[row][col-1] != null and grid[row][col-2] != null:
		if grid[row][col-1].type == grid[row][col-2].type:
			excluded.append(grid[row][col-1].type)
	if row >= 2 and grid[row-1][col] != null and grid[row-2][col] != null:
		if grid[row-1][col].type == grid[row-2][col].type:
			excluded.append(grid[row-1][col].type)
	var t = randi() % jewel_scenes.size()
	var tries = 0
	while t in excluded and tries < 20:
		t = randi() % jewel_scenes.size()
		tries += 1
	return t


func center_board() -> void:
	# The grid is drawn at DISPLAY_SCALE so it fills the pit; logic stays on CELL_SIZE
	scale = Vector2.ONE * DISPLAY_SCALE
	var vp     = get_viewport_rect().size
	var side   = CELL_SIZE * DISPLAY_SCALE
	var base_x = (vp.x - COLS * side) * 0.5
	var base_y = FLOOR_Y - ROWS * side   # the bottom row rests on the floor of the pit
	global_position = Vector2(base_x + side * 0.5, base_y + side * 0.5)


## Screen rectangle covered by the grid.
func grid_rect() -> Rect2:
	var side = CELL_SIZE * DISPLAY_SCALE
	return Rect2(global_position - Vector2.ONE * side * 0.5, Vector2(COLS, ROWS) * side)


func _spawn_jewel(row: int, col: int, type: int) -> Node:
	var jewel      = jewel_scenes[type].instantiate()
	jewel.type     = type
	jewel.row      = row
	jewel.col      = col
	jewel.board    = self
	jewel.position = Vector2(col * CELL_SIZE, row * CELL_SIZE)
	add_child(jewel)
	return jewel


func _spawn_special(row: int, col: int, special_type) -> void:
	if not special_scenes.has(special_type):
		return
	var original_type = 0
	if grid[row][col]:
		original_type = grid[row][col].type
		grid[row][col].queue_free()
	var jewel       = special_scenes[special_type].instantiate()
	jewel.type      = original_type
	jewel.special   = special_type
	jewel.row       = row
	jewel.col       = col
	jewel.board     = self
	jewel.position  = Vector2(col * CELL_SIZE, row * CELL_SIZE)
	grid[row][col]  = jewel
	add_child(jewel)


func _create_specials(specials: Array) -> void:
	for s in specials:
		var type
		if s.count >= 6:
			type = SpecialType.Type.COLOR
		elif s.count == 5:
			type = SpecialType.Type.BOMB
		elif s.horizontal:
			type = SpecialType.Type.LINE_H
		else:
			type = SpecialType.Type.LINE_V
		_spawn_special(s.row, s.col, type)


## UI-Overlays (Menü, Level-Up) sperren die Eingabe unabhängig von is_busy,
## das nur der laufenden Kaskade gehört.
func lock_input() -> void:
	input_locks += 1


func unlock_input() -> void:
	input_locks = max(input_locks - 1, 0)


func can_input() -> bool:
	return not is_busy and input_locks == 0


func on_jewel_clicked(jewel: Node) -> void:
	if not can_input():
		return
	if first_selected == jewel:
		first_selected.set_selected(false)
		first_selected = null
		return
	if first_selected == null:
		first_selected = jewel
		jewel.set_selected(true)
	else:
		if are_adjacent(first_selected, jewel):
			first_selected.set_selected(false)
			_try_swap(first_selected, jewel)
			first_selected = null
		else:
			first_selected.set_selected(false)
			first_selected = jewel
			jewel.set_selected(true)


func are_adjacent(a: Node, b: Node) -> bool:
	return (abs(a.row - b.row) == 1 and a.col == b.col) or \
		   (abs(a.col - b.col) == 1 and a.row == b.row)



func _try_swap(a: Node, b: Node) -> void:
	is_busy = true
	combo   = 0
	_play(sound_swap)
	_animate_swap(a, b, func():
		_apply_swap_logic(a, b)

		if a.special != SpecialType.Type.NONE or b.special != SpecialType.Type.NONE:
			_resolve_special_swap(a, b)
			return

		var result  = MatchFinder.find_matches(grid, ROWS, COLS, SpecialType.Type.NONE)
		var matches = result.matched
		if matches.is_empty():
			_play(sound_nomatch)
			_animate_swap(a, b, func():
				_apply_swap_logic(a, b)
				is_busy = false
			)
		else:
			_create_specials(result.specials)
			_resolve_matches(matches, result.runs)
	)


func _apply_swap_logic(a: Node, b: Node) -> void:
	grid[a.row][a.col] = b
	grid[b.row][b.col] = a
	var temp_row = a.row; var temp_col = a.col
	a.row = b.row;  a.col = b.col
	b.row = temp_row;     b.col = temp_col


func _animate_swap(a: Node, b: Node, on_done: Callable) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(a, "position",
		Vector2(b.col * CELL_SIZE, b.row * CELL_SIZE), SWAP_SPEED) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(b, "position",
		Vector2(a.col * CELL_SIZE, a.row * CELL_SIZE), SWAP_SPEED) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.chain().tween_callback(on_done)



func _resolve_special_swap(a: Node, b: Node) -> void:
	special_handler.handle_special_swap(a, b)

	await get_tree().create_timer(0.05).timeout
	await gravity.apply_gravity(grid, ROWS, COLS, CELL_SIZE, FALL_SPEED)
	await gravity.refill_board(grid, ROWS, COLS, CELL_SIZE, FALL_SPEED,
		func(r, c): return _spawn_jewel(r, c, randi() % jewel_scenes.size())
	)

	var result = MatchFinder.find_matches(grid, ROWS, COLS, SpecialType.Type.NONE)
	if not result.matched.is_empty():
		_create_specials(result.specials)
		await _resolve_matches(result.matched, result.runs)
	else:
		await _finish_turn()


## Punkte und Münzen pro Run (Länge der Reihe), nicht pro gematchter Zelle.
func _calculate_rewards(runs: Array) -> void:
	var combo_mult = 1.0 + (combo * 0.5)
	var pts        = 0
	var coins      = 0
	for length in runs:
		if length >= 5:
			pts   += POINTS_5 * (length - 4)
			coins += COINS_5
		elif length == 4:
			pts   += POINTS_4
			coins += COINS_4
		else:
			pts   += POINTS_3
			coins += COINS_3
	LevelManager.add_score(int(pts * combo_mult))
	LevelManager.add_currency(coins)

	combo += 1


func _finish_turn() -> void:
	combo = 0
	ui_bridge.update_combo_label(combo)
	await _ensure_playable()
	is_busy = false


func _has_possible_move() -> bool:
	for r in range(ROWS):
		for c in range(COLS):
			if grid[r][c] == null:
				return true
			if grid[r][c].special != SpecialType.Type.NONE:
				return true
			for d in [Vector2i(0, 1), Vector2i(1, 0)]:
				var r2 = r + d.x
				var c2 = c + d.y
				if r2 >= ROWS or c2 >= COLS:
					continue
				_swap_cells(r, c, r2, c2)
				var found = not MatchFinder.find_matches(grid, ROWS, COLS, SpecialType.Type.NONE).matched.is_empty()
				_swap_cells(r, c, r2, c2)
				if found:
					return true
	return false


func _swap_cells(r1: int, c1: int, r2: int, c2: int) -> void:
	var tmp = grid[r1][c1]
	grid[r1][c1] = grid[r2][c2]
	grid[r2][c2] = tmp
	if grid[r1][c1]:
		grid[r1][c1].row = r1
		grid[r1][c1].col = c1
	if grid[r2][c2]:
		grid[r2][c2].row = r2
		grid[r2][c2].col = c2


func _ensure_playable() -> void:
	if not _has_possible_move():
		await _shuffle_board()


func _shuffle_board() -> void:
	var jewels: Array = []
	for r in range(ROWS):
		for c in range(COLS):
			jewels.append(grid[r][c])

	for attempt in range(100):
		jewels.shuffle()
		for i in range(jewels.size()):
			var r = floori(float(i) / COLS)
			var c = i % COLS
			grid[r][c]   = jewels[i]
			jewels[i].row = r
			jewels[i].col = c
		var no_matches = MatchFinder.find_matches(grid, ROWS, COLS, SpecialType.Type.NONE).matched.is_empty()
		if no_matches and _has_possible_move():
			break

	var tween = create_tween()
	tween.set_parallel(true)
	for j in jewels:
		tween.tween_property(j, "position", Vector2(j.col * CELL_SIZE, j.row * CELL_SIZE), 0.3) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

	# Fallback: falls nach 100 Versuchen noch Matches stehen, normal auflösen.
	var result = MatchFinder.find_matches(grid, ROWS, COLS, SpecialType.Type.NONE)
	if not result.matched.is_empty():
		_create_specials(result.specials)
		await _resolve_matches(result.matched, result.runs)


func _resolve_matches(matches: Array, runs: Array) -> void:
	_calculate_rewards(runs)
	ui_bridge.update_combo_label(combo)

	if combo > 1: _play(sound_combo)
	else:         _play(sound_match)

	for key in matches:
		var p = key.split(",")
		var r = int(p[0]); var c = int(p[1])
		special_handler.damage_cell(r, c)

	await get_tree().create_timer(0.05).timeout
	await gravity.apply_gravity(grid, ROWS, COLS, CELL_SIZE, FALL_SPEED)
	await gravity.refill_board(grid, ROWS, COLS, CELL_SIZE, FALL_SPEED,
		func(r, c): return _spawn_jewel(r, c, randi() % jewel_scenes.size())
	)

	var result = MatchFinder.find_matches(grid, ROWS, COLS, SpecialType.Type.NONE)
	if not result.matched.is_empty():
		await get_tree().create_timer(0.08).timeout
		_create_specials(result.specials)
		await _resolve_matches(result.matched, result.runs)
		return

	await _finish_turn()


func _play(player) -> void:
	if player:
		player.stop()
		player.play()
