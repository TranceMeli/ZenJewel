extends CanvasLayer

@onready var menu_overlay = %MenuOverlay
@onready var menu_button  = %MenuButton
@onready var btn_resume   = %BtnResume
@onready var btn_shop     = %BtnShop
@onready var btn_sound    = %BtnSound
@onready var btn_exit     = %BtnExit
@onready var player_name  = %PlayerName
@onready var board        = $"../Board"


var menu_open: bool = false
var shop: Shop = null


func _ready() -> void:
	refresh_player_name()
	menu_overlay.visible = false

	UIStyle.style_button(menu_button, false, 28)
	UIStyle.style_button(btn_resume, true, 32)
	UIStyle.style_button(btn_shop, false, 32)
	UIStyle.style_button(btn_sound, false, 32)
	UIStyle.style_button(btn_exit, false, 32)

	menu_button.pressed.connect(_on_menu_button_pressed)
	btn_resume.pressed.connect(_close_menu)
	btn_shop.pressed.connect(_on_shop_pressed)
	btn_sound.pressed.connect(_on_sound_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)
	_refresh_sound_button()


func refresh_player_name() -> void:
	player_name.text = "Hello %s!" % LevelManager.player_name


func _on_menu_button_pressed() -> void:
	if menu_open:
		_close_menu()
	else:
		_open_menu()


func _open_menu() -> void:
	menu_open = true
	if board:
		board.lock_input()   # Brett blockieren, solange das Menü offen ist

	menu_overlay.modulate.a = 0.0
	menu_overlay.visible = true
	btn_resume.grab_focus()   # Tastatur und Gamepad starten bei "Resume"

	var tween = create_tween()
	tween.tween_property(menu_overlay, "modulate:a", 1.0, 0.2) \
		.set_trans(Tween.TRANS_SINE)


func _close_menu() -> void:
	if not menu_open:
		return
	menu_open = false

	var tween = create_tween()
	tween.tween_property(menu_overlay, "modulate:a", 0.0, 0.2) \
		.set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func():
		if not menu_open:
			menu_overlay.visible = false
		if board:
			board.unlock_input()   # Brett wieder freigeben
	)


func _on_shop_pressed() -> void:
	if shop != null and is_instance_valid(shop):
		return
	shop = Shop.new()
	shop.place_requested.connect(_on_place_requested)
	add_child(shop)


func _on_place_requested(id: String) -> void:
	_close_menu()
	var decorations = get_tree().get_first_node_in_group("decorations")
	if decorations:
		decorations.start_placing(id)


func _on_sound_pressed() -> void:
	LevelManager.set_sound_enabled(not LevelManager.sound_enabled)
	_refresh_sound_button()


func _refresh_sound_button() -> void:
	btn_sound.text = "Sound on" if LevelManager.sound_enabled else "Sound off"


func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_menu_button_pressed()   # Esc öffnet und schließt das Menü
