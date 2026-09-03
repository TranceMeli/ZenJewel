extends Node2D

const BOARD_SIZE = 576  # 8 × 64
const PADDING    = 10    # je 8px rundherum
const BG_SIZE    = BOARD_SIZE + (PADDING * 2)  # = 528

func _ready() -> void:
	var vp = get_viewport_rect().size
	
	$BoardBackground.position = vp * 0.5
	$BoardBackground.scale    = Vector2(2.75, 2.75)
