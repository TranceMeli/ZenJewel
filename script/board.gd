extends Node2D
class_name Board

const ROWS        = 8
const COLS        = 8
const CELL_SIZE   = 64
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
	var vp     = get_viewport_rect().size
	var base_x = (vp.x - COLS * CELL_SIZE) * 0.5
	var base_y = (vp.y - ROWS * CELL_SIZE) * 0.5
	global_position = Vector2(
		base_x + (CELL_SIZE * 0.5),
		base_y + (CELL_SIZE * 0.5)
	)

	
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


func on_jewel_clicked(jewel: Node) -> void:
	if is_busy:
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
			_resolve_matches(matches)
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
		await _resolve_matches(result.matched)
	else:
		is_busy = false


func _calculate_rewards(matches: Array) -> void:
	var count      = matches.size()
	var combo_mult = 1.0 + (combo * 0.5)
	var pts        = 0
	if   count >= 5: pts = POINTS_5 * (count - 4)
	elif count == 4: pts = POINTS_4
	else:            pts = POINTS_3 * (count / 3)
	LevelManager.add_score(int(pts * combo_mult))

	var coins = 0
	if   count >= 5: coins = COINS_5
	elif count == 4: coins = COINS_4
	else:            coins = (count / 3) * COINS_3
	LevelManager.add_currency(coins)

	combo += 1


func _resolve_matches(matches: Array) -> void:
	_calculate_rewards(matches)

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
		await _resolve_matches(result.matched)
		return

	combo   = 0
	is_busy = false
	ui_bridge.update_combo_label(combo)


func _play(player) -> void:
	if player:
		player.stop()
		player.play()
