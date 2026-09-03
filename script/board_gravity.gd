# board_gravity.gd
extends Node
class_name BoardGravity


func apply_gravity(grid: Array, rows: int, cols: int, cell_size: int, fall_speed: float) -> void:
	var moves = []
	for col in range(cols):
		var empty_row = rows - 1
		for row in range(rows - 1, -1, -1):
			if grid[row][col] != null:
				if row != empty_row:
					moves.append({
						"jewel":    grid[row][col],
						"from_row": row,
						"to_row":   empty_row,
						"col":      col
					})
					grid[empty_row][col]     = grid[row][col]
					grid[row][col]           = null
					grid[empty_row][col].row = empty_row
				empty_row -= 1
	if moves.is_empty():
		return
	var tween = create_tween()
	tween.set_parallel(true)
	for m in moves:
		tween.tween_property(
			m.jewel, "position",
			Vector2(m.col * cell_size, m.to_row * cell_size),
			fall_speed * (m.to_row - m.from_row)
		).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	await tween.finished

	
func refill_board(grid: Array, rows: int, cols: int, cell_size: int, fall_speed: float, spawn_fn: Callable) -> void:
	var spawns = []
	for col in range(cols):
		var offset = 0
		for row in range(rows - 1, -1, -1):
			if grid[row][col] == null:
				offset        += 1
				var jewel      = spawn_fn.call(row, col)
				grid[row][col] = jewel
				jewel.position = Vector2(col * cell_size, -cell_size * offset)
				spawns.append({
					"jewel":    jewel,
					"target":   Vector2(col * cell_size, row * cell_size),
					"duration": fall_speed * (row + offset)
				})
	if spawns.is_empty():
		return
	var tween = create_tween()
	tween.set_parallel(true)
	for s in spawns:
		tween.tween_property(s.jewel, "position", s.target, s.duration) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	await tween.finished
