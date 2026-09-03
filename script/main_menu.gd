extends Control

func _ready() -> void:
    $VBoxContainer/StartButton.pressed.connect(_on_start)
    $VBoxContainer/HighlightsButton.pressed.connect(_on_highlights)
    $VBoxContainer/ExitButton.pressed.connect(_on_exit)


func _on_start() -> void:
    get_tree().change_scene_to_file("res://scene/main.tscn")


func _on_highlights() -> void:
    # Später: get_tree().change_scene_to_file("res://scene/highlights.tscn")
    pass


func _on_exit() -> void:
    get_tree().quit()