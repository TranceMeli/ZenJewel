# special_handler.gd
extends Node
class_name SpecialHandler

var board  # Referenz auf den Board-Node (wird per setup() gesetzt)


func setup(p_board) -> void:
	board = p_board


func handle_special_swap(a: Node, b: Node) -> void:
	var special_jewel = a if a.special != SpecialType.Type.NONE else b
	var other_jewel   = b if a.special != SpecialType.Type.NONE else a

	damage_cell(special_jewel.row, special_jewel.col)

	if other_jewel.special != SpecialType.Type.NONE:
		damage_cell(other_jewel.row, other_jewel.col)
	elif special_jewel.special == SpecialType.Type.COLOR:
		activate_color(other_jewel.type)


func damage_cell(row: int, col: int) -> void:
	if row < 0 or row >= board.ROWS or col < 0 or col >= board.COLS:
		return

	var jewel = board.grid[row][col]
	if jewel == null:
		return

	board.grid[row][col] = null

	if jewel.special != SpecialType.Type.NONE:
		board._play(board.sound_special)
		match jewel.special:
			SpecialType.Type.LINE_H:
				activate_line_h(row)
			SpecialType.Type.LINE_V:
				activate_line_v(col)
			SpecialType.Type.BOMB:
				activate_bomb(row, col)
			SpecialType.Type.COLOR:
				activate_color(jewel.type)
		calculate_rewards_special()

	jewel.queue_free()


func activate_line_h(row: int) -> void:
	board.effects.show_line_effect(row, 0, true)
	for c in range(board.COLS):
		damage_cell(row, c)


func activate_line_v(col: int) -> void:
	board.effects.show_line_effect(0, col, false)
	for r in range(board.ROWS):
		damage_cell(r, col)


func activate_bomb(row: int, col: int) -> void:
	board.effects.show_bomb_effect(row, col)
	for r in range(row - 1, row + 2):
		for c in range(col - 1, col + 2):
			damage_cell(r, c)


func activate_color(type: int) -> void:
	for r in range(board.ROWS):
		for c in range(board.COLS):
			if board.grid[r][c] and board.grid[r][c].type == type:
				board.effects.flash_jewel(board.grid[r][c])
				damage_cell(r, c)


func calculate_rewards_special() -> void:
	LevelManager.add_score(150)
	LevelManager.add_currency(5)
