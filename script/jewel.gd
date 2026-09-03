extends Area2D

var special = SpecialType.Type.NONE

var row: int
var col: int
var type: int
var is_selected: bool = false
var board

@onready var highlight = $Highlight if has_node("Highlight") else null


func _ready() -> void:
	pass


func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:
		if board:
			board.on_jewel_clicked(self)


func set_selected(value: bool) -> void:
	is_selected = value
	if highlight:
		highlight.visible = value
