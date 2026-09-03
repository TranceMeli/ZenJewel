extends Node


const BASE_GOAL = 1000
const GROWTH = 1.4

const SAVE_FILE = "user://save.json"


var player_name : String = "Mel"

var current_level : int = 1
var total_score : int = 0
var level_score : int = 0
var currency : int = 0


signal level_up(new_level: int, goal: int)
signal score_changed(total: int, level: int, goal: int)
signal currency_changed(amount: int)


func _ready() -> void:
	load_game()


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

	save_game()

	if level_score >= get_goal():
		_advance_level()

func add_currency(coins: int) -> void:
	currency += coins

	currency_changed.emit(currency)

	save_game()

func _advance_level() -> void:
	level_score = 0
	current_level += 1

	save_game()

	level_up.emit(
		current_level,
		get_goal()
	)


func set_player_name(name: String) -> void:
	player_name = name.strip_edges()

	if player_name.is_empty():
		player_name = "Bot"

	save_game()


func save_game() -> void:
	var data = {
		"player_name": player_name,
		"current_level": current_level,
		"total_score": total_score,
		"level_score": level_score,
		"currency": currency
	}

	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)

	if file == null:
		push_error("Konnte Save-Datei nicht schreiben.")
		return

	file.store_string(JSON.stringify(data))
	file.close()

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

	player_name = data.get("player_name", "Spieler")
	current_level = data.get("current_level", 1)
	total_score = data.get("total_score", 0)
	level_score = data.get("level_score", 0)
	currency = data.get("currency", 0)


func reset() -> void:
	player_name = "Mel"

	current_level = 1
	total_score = 0
	level_score = 0
	currency = 0

	save_game()

	score_changed.emit(
		total_score,
		level_score,
		get_goal()
	)

	currency_changed.emit(currency)
