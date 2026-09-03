extends CanvasLayer

@onready var menu_overlay = %MenuOverlay
@onready var menu_button = %MenuButton
@onready var btn_weiter = %BtnWeiter
@onready var btn_shop = %BtnShop
@onready var btn_exit = %BtnExit
@onready var player_name = $HUD/TopBar/PlayerName
@onready var board = $"../Board"


var menu_open: bool = false

func refresh_player_name() -> void:
	print("DEBUG: Der Name im LevelManager ist: ", LevelManager.player_name)
	player_name.text = "Hello %s!" % LevelManager.player_name

func _ready() -> void:
	refresh_player_name()
	menu_overlay.visible = false
	menu_button.pressed.connect(_on_menu_button_pressed)
	btn_weiter.pressed.connect(_on_weiter_pressed)
	btn_shop.pressed.connect(_on_shop_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)

func _on_menu_button_pressed() -> void:
	if menu_open:
		_close_menu()
	else:
		_open_menu()


func _open_menu() -> void:
	menu_open = true
	if board:
		board.is_busy = true # Board blockieren während Menü offen

	menu_overlay.modulate.a = 0.0
	menu_overlay.visible = true

	var tween = create_tween()
	tween.tween_property(menu_overlay, "modulate:a", 1.0, 0.2) \
		.set_trans(Tween.TRANS_SINE)


func _close_menu() -> void:
	menu_open = false

	var tween = create_tween()
	tween.tween_property(menu_overlay, "modulate:a", 0.0, 0.2) \
		.set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func():
		menu_overlay.visible = false
		if board:
			board.is_busy = false # Board wieder freigeben
	)


func _on_weiter_pressed() -> void:
	_close_menu()


func _on_shop_pressed() -> void:
	# Später: Shop-Overlay öffnen
	print("Shop kommt noch!")


func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")

	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and menu_open:
		_close_menu()
