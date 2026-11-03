extends Node2D

func _ready() -> void:
	var vp = get_viewport_rect().size

	$BoardBackground.visible = false
	_build_pit(vp)

	_setup_decorations()
	_add_ambient_particles()


# The lowest jewel pixel sits 3 px above the cell edge; the floor bar starts right under it
const REST_GAP = 3.0


## Open-topped basin around the grid: jewels fall in from above, so there is no
## frame at the top. Side walls only run along the grid and a floor bar closes
## the bottom, touching the lowest row.
func _build_pit(vp: Vector2) -> void:
	var cell  = Board.CELL_SIZE * Board.DISPLAY_SCALE
	var side  = cell * Board.COLS
	var left  = (vp.x - side) * 0.5
	var top   = Board.FLOOR_Y - cell * Board.ROWS
	var edge  = Color(0.42, 0.31, 0.06)
	var parts = [
		# Covers the old pillars above the grid so the top stays open sky
		[Color(0.361, 0.282, 0.004), Vector2(left - 80.0, 0), Vector2(side + 160.0, top)],
		[Color(0.133, 0.09, 0.0), Vector2(left, top), Vector2(side, Board.FLOOR_Y - top)],
		[edge, Vector2(left - 10.0, top), Vector2(10.0, Board.FLOOR_Y - top - REST_GAP)],
		[edge, Vector2(left + side, top), Vector2(10.0, Board.FLOOR_Y - top - REST_GAP)],
		[edge, Vector2(left - 10.0, Board.FLOOR_Y - REST_GAP), Vector2(side + 20.0, 24.0)],
	]
	var anchor = $EnvironmentFrame.get_index()
	for part in parts:
		var rect = ColorRect.new()
		rect.color        = part[0]
		rect.position     = part[1]
		rect.size         = part[2]
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)
		move_child(rect, anchor)
		anchor += 1


## Die Pilze auf der Wiese sind jetzt Cosmetics: die fest eingebauten Tiles
## werden entfernt und durch die gespeicherten Platzierungen ersetzt.
func _setup_decorations() -> void:
	var env: TileMapLayer = $EnvironmentFrame
	for cell in env.get_used_cells_by_id(2, Vector2i(1, 0)):
		env.erase_cell(cell)

	var decorations = Decorations.new()
	decorations.name = "Decorations"
	add_child(decorations)
	move_child(decorations, $Board.get_index())   # über der Wiese, unter dem Brett


## Slow golden motes drifting over the meadow, behind the board.
func _add_ambient_particles() -> void:
	var motes = FX.ambient(self, Rect2(0, 300, 1920, 560), Color(1.0, 0.9, 0.5, 0.8))
	move_child(motes, $Board.get_index())
