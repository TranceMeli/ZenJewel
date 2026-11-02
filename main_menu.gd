extends Control

@onready var start_button      = $VBoxContainer/StartButton
@onready var highlights_button = $VBoxContainer/HighlightsButton
@onready var exit_button       = $VBoxContainer/ExitButton
@onready var name_edit         = $VBoxContainer/NameEdit
@onready var progress_label    = $VBoxContainer/ProgressLabel
@onready var title_label       = $VBoxContainer/TitleLabel


const CORNER_MARGIN = 24.0


func _ready() -> void:
	_place_corner_jewels()
	UIStyle.style_button(start_button, true, 40)
	UIStyle.style_button(highlights_button, false, 32)
	UIStyle.style_button(exit_button, false, 32)
	name_edit.add_theme_stylebox_override("normal", UIStyle.box(UIStyle.PANEL, UIStyle.PANEL_EDGE))
	name_edit.add_theme_stylebox_override("focus", UIStyle.box(UIStyle.PANEL, UIStyle.GOLD))
	name_edit.add_theme_color_override("font_color", UIStyle.TEXT)
	name_edit.add_theme_color_override("font_placeholder_color", UIStyle.TEXT_DIM.darkened(0.3))

	# The meadow-free menu still gets a few drifting motes behind the buttons
	var motes = FX.ambient(self, get_viewport_rect(), Color(1.0, 0.9, 0.5, 0.7))
	move_child(motes, $Background.get_index() + 1)

	# Highlights is not built yet: show it, but make that obvious
	highlights_button.disabled     = true
	highlights_button.tooltip_text = "Personal bests are coming in a later version"

	_refresh_progress()
	if LevelManager.player_name != LevelManager.DEFAULT_NAME:
		name_edit.text = LevelManager.player_name

	start_button.pressed.connect(_on_start)
	exit_button.pressed.connect(_on_exit)
	name_edit.text_submitted.connect(func(_t): _on_start())
	start_button.grab_focus()

	_animate_in()


## Pin the four decorative jewels flush into the corners with the same margin.
## Order in the scene: top left, bottom left, top right, bottom right.
func _place_corner_jewels() -> void:
	var vp = get_viewport_rect().size
	var jewels = get_children().filter(func(n): return n is Sprite2D)
	for i in range(jewels.size()):
		var jewel: Sprite2D = jewels[i]
		var half = jewel.region_rect.size * jewel.scale * 0.5
		var left   = i == 0 or i == 1
		var top    = i == 0 or i == 2
		jewel.position = Vector2(
			CORNER_MARGIN + half.x if left else vp.x - CORNER_MARGIN - half.x,
			CORNER_MARGIN + half.y if top  else vp.y - CORNER_MARGIN - half.y
		)


func _refresh_progress() -> void:
	var has_progress = LevelManager.total_score > 0 or LevelManager.current_level > 1
	start_button.text = "Continue" if has_progress else "Play"
	progress_label.text = "Level %d    %d gems" % [LevelManager.current_level, LevelManager.currency] \
		if has_progress else "Match jewels at your own pace"


## Fade the menu in and let the title and the corner jewels breathe gently.
func _animate_in() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.4)

	await get_tree().process_frame   # wait for the layout so the pivot is the title's center
	var pulse = create_tween().set_loops()
	title_label.pivot_offset = title_label.size / 2.0
	pulse.tween_property(title_label, "scale", Vector2(1.03, 1.03), 1.6).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(title_label, "scale", Vector2.ONE, 1.6).set_trans(Tween.TRANS_SINE)

	var i = 0
	for node in get_children():
		if node is Sprite2D:
			var bob = create_tween().set_loops()
			var base_y = node.position.y
			bob.tween_interval(0.35 * i)   # offset each jewel so they do not move in sync
			bob.tween_property(node, "position:y", base_y - 14.0, 1.4).set_trans(Tween.TRANS_SINE)
			bob.tween_property(node, "position:y", base_y, 1.4).set_trans(Tween.TRANS_SINE)
			i += 1


func _on_start() -> void:
	if name_edit.text.strip_edges() != "":
		LevelManager.set_player_name(name_edit.text)
	get_tree().change_scene_to_file("res://scene/main.tscn")


func _on_exit() -> void:
	get_tree().quit()
