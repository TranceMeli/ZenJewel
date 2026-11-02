extends Node


const BASE_GOAL = 1000
const GROWTH = 1.4

const SAVE_FILE = "user://save.json"


const DEFAULT_NAME = "Player"

var player_name : String = DEFAULT_NAME

var current_level : int = 1
var total_score : int = 0
var level_score : int = 0
var currency : int = 0
var sound_enabled : bool = true

# Cosmetics: owned = {id: count}, placed = [{id, x, y}] (x/y in 96 px cells,
# y = row of the bottom edge). New saves start without decorations.
var owned : Dictionary = {}
var placed : Array = []


signal level_up(new_level: int, goal: int)
signal score_changed(total: int, level: int, goal: int)
signal currency_changed(amount: int)
signal cosmetics_changed


const SAVE_DELAY = 1.0

var _save_pending : bool = false


func _ready() -> void:
	load_game()
	_apply_sound()


func _unhandled_input(event: InputEvent) -> void:
	# F11 toggles fullscreen in every scene (this autoload lives across scenes)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		var fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen
			else DisplayServer.WINDOW_MODE_FULLSCREEN)


func _notification(what: int) -> void:
	# Ausstehenden Spielstand sichern, bevor die App schließt oder pausiert.
	if what == NOTIFICATION_WM_CLOSE_REQUEST \
			or what == NOTIFICATION_APPLICATION_PAUSED:
		if _save_pending:
			save_game()


## Bündelt viele Score-/Münz-Events zu einem Schreibvorgang.
func request_save() -> void:
	if _save_pending:
		return
	_save_pending = true
	await get_tree().create_timer(SAVE_DELAY).timeout
	if _save_pending:
		save_game()


func set_sound_enabled(enabled: bool) -> void:
	sound_enabled = enabled
	_apply_sound()
	save_game()


func _apply_sound() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), not sound_enabled)


func owned_count(id: String) -> int:
	return int(owned.get(id, 0))


func placed_count(id: String) -> int:
	var n = 0
	for p in placed:
		if p.id == id:
			n += 1
	return n


func free_count(id: String) -> int:
	return owned_count(id) - placed_count(id)


func buy_cosmetic(id: String) -> bool:
	if not Cosmetics.exists(id):
		return false
	var price = int(Cosmetics.get_def(id).price)
	if currency < price:
		return false
	currency -= price
	owned[id] = owned_count(id) + 1
	currency_changed.emit(currency)
	cosmetics_changed.emit()
	cosmetics_changed.emit()
	save_game()
	return true


func add_placement(id: String, x: int, y: int) -> bool:
	if not Cosmetics.exists(id) or free_count(id) <= 0:
		return false
	placed.append({"id": id, "x": x, "y": y})
	cosmetics_changed.emit()
	request_save()
	return true


func remove_placement(index: int) -> void:
	if index < 0 or index >= placed.size():
		return
	placed.remove_at(index)
	cosmetics_changed.emit()
	request_save()


func get_goal(level: int = current_level) -> int:
	return int(BASE_GOAL * pow(GROWTH, level - 1))

func add_score(pts: int) -> void:
	total_score += pts
	level_score += pts

	score_changed.emit(
		total_score,
		level_score,
		get_goal()
	)

	if level_score >= get_goal():
		_advance_level()
	else:
		request_save()

func add_currency(coins: int) -> void:
	currency += coins

	currency_changed.emit(currency)
	cosmetics_changed.emit()

	request_save()

func _advance_level() -> void:
	# Überschüssige Punkte nehmen wir ins nächste Level mit.
	while level_score >= get_goal():
		level_score -= get_goal()
		current_level += 1

	save_game()

	level_up.emit(
		current_level,
		get_goal()
	)


func set_player_name(new_name: String) -> void:
	player_name = new_name.strip_edges()

	if player_name.is_empty():
		player_name = DEFAULT_NAME

	save_game()


func save_game() -> void:
	var data = {
		"player_name": player_name,
		"current_level": current_level,
		"total_score": total_score,
		"level_score": level_score,
		"currency": currency,
		"sound_enabled": sound_enabled,
		"owned": owned,
		"placed": placed
	}

	# Erst in eine Temp-Datei schreiben, dann umbenennen (kein halber Spielstand bei Absturz).
	var tmp_path = SAVE_FILE + ".tmp"
	var file = FileAccess.open(tmp_path, FileAccess.WRITE)

	if file == null:
		push_error("Konnte Save-Datei nicht schreiben.")
		return

	file.store_string(JSON.stringify(data))
	file.close()

	var err = DirAccess.rename_absolute(tmp_path, SAVE_FILE)
	if err != OK:
		push_error("Konnte Save-Datei nicht ersetzen (Fehler %d)." % err)
		return

	_save_pending = false

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		return

	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)

	if file == null:
		return

	var text = file.get_as_text()
	file.close()

	var data = JSON.parse_string(text)

	if typeof(data) != TYPE_DICTIONARY:
		return

	player_name = str(data.get("player_name", DEFAULT_NAME))
	current_level = maxi(_to_int(data.get("current_level", 1), 1), 1)
	total_score = maxi(_to_int(data.get("total_score", 0), 0), 0)
	level_score = maxi(_to_int(data.get("level_score", 0), 0), 0)
	currency = maxi(_to_int(data.get("currency", 0), 0), 0)
	sound_enabled = bool(data.get("sound_enabled", true))
	_load_cosmetics(data)


func _load_cosmetics(data: Dictionary) -> void:
	# Alte Spielstände ohne diese Schlüssel behalten die Standardwerte.
	if data.get("owned") is Dictionary:
		owned = {}
		for id in data.owned:
			if Cosmetics.exists(str(id)):
				owned[str(id)] = maxi(_to_int(data.owned[id], 0), 0)
	if data.get("placed") is Array:
		placed = []
		for p in data.placed:
			if not (p is Dictionary) or not Cosmetics.exists(str(p.get("id", ""))):
				continue
			var id = str(p.id)
			if placed_count(id) >= owned_count(id):
				continue
			placed.append({
				"id": id,
				"x": _to_int(p.get("x", 0), 0),
				"y": _to_int(p.get("y", Cosmetics.GROUND_ROW), Cosmetics.GROUND_ROW),
			})


func _to_int(value, fallback: int) -> int:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return int(value)
	return fallback


func reset() -> void:
	player_name = DEFAULT_NAME

	current_level = 1
	total_score = 0
	level_score = 0
	currency = 0
	owned = {}
	placed = []

	save_game()

	score_changed.emit(
		total_score,
		level_score,
		get_goal()
	)

	currency_changed.emit(currency)
	cosmetics_changed.emit()
