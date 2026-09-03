# board_ui_bridge.gd
extends Node
class_name BoardUIBridge

@onready var score_label         = get_node_or_null("../../UI/HUD/TopBar/HBoxContainer/BlockScore/VBoxContainer/ScoreValue")
@onready var level_label         = get_node_or_null("../../UI/HUD/TopBar/HBoxContainer/BlockLevel/VBoxContainer/HBoxContainer/LevelValue")
@onready var currency_label      = get_node_or_null("../../UI/HUD/TopBar/HBoxContainer/BlockGems/VBoxContainer/HBoxContainer/CurrencyValue")
@onready var progress_bar        = get_node_or_null("../../UI/HUD/TopBar/HBoxContainer/BlockLevel/VBoxContainer/HBoxContainer/ProgressBar")
@onready var combo_label         = get_node_or_null("../../UI/HUD/ComboLevel")
@onready var level_overlay       = get_node_or_null("../../UI/LevelOverlay")
@onready var level_overlay_label = get_node_or_null("../../UI/LevelOverlay/Label")


func _ready() -> void:
	LevelManager.score_changed.connect(_on_score_changed)
	LevelManager.currency_changed.connect(_on_currency_changed)
	LevelManager.level_up.connect(_on_level_up)


func refresh() -> void:
	if score_label:
		score_label.text = _format_score(LevelManager.total_score)
	if level_label:
		level_label.text = str(LevelManager.current_level)
	if currency_label:
		currency_label.text = str(LevelManager.currency)
	if progress_bar:
		progress_bar.max_value = float(LevelManager.get_goal())
		progress_bar.value     = float(LevelManager.level_score)


func update_combo_label(combo: int) -> void:
	if combo_label:
		if combo > 1:
			combo_label.text    = "COMBO  x%d" % combo
			combo_label.visible = true
		else:
			combo_label.visible = false


func _on_score_changed(total: int, level_s: int, goal: int) -> void:
	if score_label:
		score_label.text = _format_score(total)
	if progress_bar:
		progress_bar.max_value = goal
		progress_bar.value     = level_s


func _on_currency_changed(amount: int) -> void:
	if currency_label:
		currency_label.text = str(amount)


func _on_level_up(new_level: int, _goal: int) -> void:
	# Board muss während des Übergangs blockiert sein.
	# get_parent() ist hier der Board-Node selbst.
	get_parent().is_busy = true

	if level_overlay and level_overlay_label:
		level_overlay_label.text = "LEVEL  %d" % new_level
		level_overlay.modulate.a = 0.0
		level_overlay.visible    = true
		var t_in = create_tween()
		t_in.tween_property(level_overlay, "modulate:a", 1.0, 0.35) \
			.set_trans(Tween.TRANS_SINE)
		await t_in.finished

	await get_tree().create_timer(1.2).timeout

	if level_overlay:
		var t_out = create_tween()
		t_out.tween_property(level_overlay, "modulate:a", 0.0, 0.35) \
			.set_trans(Tween.TRANS_SINE)
		await t_out.finished
		level_overlay.visible = false

	refresh()
	get_parent().is_busy = false


func _format_score(s: int) -> String:
	var raw = str(s)
	var out = ""
	for i in range(raw.length()):
		if i > 0 and (raw.length() - i) % 3 == 0:
			out += "."
		out += raw[i]
	return out
