extends Node2D

func _ready() -> void:
	var vp = get_viewport_rect().size

	$BoardBackground.position = vp * 0.5
	$BoardBackground.scale    = Vector2(2.75, 2.75)

	_setup_decorations()
	_add_ambient_particles()


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
