# board_effects.gd
extends Node2D
class_name BoardEffects

var cell_size: int = 64
var rows: int = 8
var cols: int = 8


func setup(p_cell_size: int, p_rows: int, p_cols: int) -> void:
	cell_size = p_cell_size
	rows      = p_rows
	cols      = p_cols


func show_line_effect(row: int, col: int, horizontal: bool) -> void:
	var flash = ColorRect.new()
	flash.color        = Color(0.6, 0.9, 1.0, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if horizontal:
		flash.size     = Vector2(cols * cell_size, cell_size * 0.3)
		flash.position = Vector2(0, row * cell_size + cell_size * 0.35)
	else:
		flash.size     = Vector2(cell_size * 0.3, rows * cell_size)
		flash.position = Vector2(col * cell_size + cell_size * 0.35, 0)

	add_child(flash)

	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.8, 0.08)
	tween.tween_property(flash, "color:a", 0.0, 0.25)
	tween.tween_callback(flash.queue_free)


func show_bomb_effect(row: int, col: int) -> void:
	var flash = ColorRect.new()
	flash.color        = Color(1.0, 0.7, 0.3, 0.6)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.size         = Vector2(cell_size * 3, cell_size * 3)
	flash.position     = Vector2((col - 1) * cell_size, (row - 1) * cell_size)
	flash.pivot_offset = flash.size / 2
	add_child(flash)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(1.3, 1.3), 0.25)
	tween.tween_property(flash, "color:a", 0.0, 0.25)
	tween.chain().tween_callback(flash.queue_free)


func flash_jewel(jewel: Node) -> void:
	if jewel and is_instance_valid(jewel):
		var tween = create_tween()
		tween.tween_property(jewel, "modulate", Color(2, 2, 2, 1), 0.1)
		tween.tween_property(jewel, "modulate", Color(1, 1, 1, 1), 0.1)


# Average colors of the six jewel types (orange, red, yellow, green, purple, blue)
const JEWEL_COLORS = [
	Color(0.85, 0.5, 0.1), Color(0.8, 0.15, 0.15), Color(0.9, 0.78, 0.15),
	Color(0.3, 0.8, 0.15), Color(0.45, 0.3, 0.85), Color(0.1, 0.35, 0.85),
]


func jewel_pop(pos: Vector2, type: int) -> void:
	var base: Color = JEWEL_COLORS[type % JEWEL_COLORS.size()]
	FX.burst(self, pos, [base, base.lightened(0.4), Color(1, 1, 1)], 10, 150.0, 7.0, 0.5)


func special_burst(pos: Vector2) -> void:
	FX.burst(self, pos, [Color(1, 0.9, 0.4), Color(1, 1, 1), Color(1, 0.6, 0.2)], 28, 260.0, 9.0, 0.7)


func confetti() -> void:
	# Raining from the top edge of the screen, converted to this node's space
	var top = to_local(Vector2(get_viewport_rect().size.x * 0.5, 100))
	FX.confetti(self, top, get_viewport_rect().size.x, JEWEL_COLORS)
