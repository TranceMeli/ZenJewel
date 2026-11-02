# shop.gd
# Shop overlay: buy cosmetics with gems. The UI is built in code and uses the
# dark area of zenjewel_UI.png as its field.
extends CanvasLayer
class_name Shop

signal closed
signal place_requested(id: String)

const FONT  = preload("res://font/ARCADECLASSIC.TTF")
const FRAME = preload("res://assets/zenjewel_UI.png")
const COIN  = preload("res://assets/coin.png")

# Dark field in zenjewel_UI.png (1920x1080)
const FIELD = Rect2(101, 101, 1718, 898)

var _gems_label: Label
var _root: Control
var _toast: Label
var _toast_tween: Tween
var _grid: GridContainer
var _filter_row: HBoxContainer
var _filter: String = ""   # empty = all categories
var _cards: Dictionary = {}


func _ready() -> void:
	layer = 10
	_build()
	LevelManager.currency_changed.connect(_on_currency_changed)
	LevelManager.cosmetics_changed.connect(_refresh)
	_refresh()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	closed.emit()
	queue_free()


func _on_currency_changed(_amount: int) -> void:
	_refresh()


# --- Build -------------------------------------------------------------------

func _label(text: String, size: int, color: Color = UIStyle.TEXT) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, primary: bool = false, size: int = 28) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 56)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIStyle.style_button(b, primary, size)
	return b


func _coin(size: int) -> TextureRect:
	var coin = TextureRect.new()
	coin.texture             = COIN
	coin.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.custom_minimum_size = Vector2(size, size)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return coin


func _build() -> void:
	var root = Control.new()
	_root = root
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP   # nothing underneath is clickable
	add_child(root)

	var frame = TextureRect.new()
	frame.texture      = FRAME
	frame.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(frame)

	var field = MarginContainer.new()
	field.anchor_left   = FIELD.position.x / 1920.0
	field.anchor_top    = FIELD.position.y / 1080.0
	field.anchor_right  = FIELD.end.x / 1920.0
	field.anchor_bottom = FIELD.end.y / 1080.0
	for side in ["left", "top", "right", "bottom"]:
		field.add_theme_constant_override("margin_" + side, 32)
	root.add_child(field)

	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	field.add_child(column)

	# Header: title, category filter, gems, close
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	column.add_child(header)
	header.add_child(_label("Shop", 64))

	_filter_row = HBoxContainer.new()
	_filter_row.add_theme_constant_override("separation", 10)
	_filter_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filter_row.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	header.add_child(_filter_row)
	_build_filters()

	var chip = PanelContainer.new()
	chip.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL, UIStyle.PANEL_EDGE, 24, 2))
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(chip)
	var chip_row = HBoxContainer.new()
	chip_row.add_theme_constant_override("separation", 10)
	chip.add_child(chip_row)
	chip_row.add_child(_coin(40))
	_gems_label = _label("0", 44)
	chip_row.add_child(_gems_label)

	var close = _button("X", false, 32)
	close.custom_minimum_size   = Vector2(64, 56)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_close)
	header.add_child(close)

	column.add_child(HSeparator.new())

	# Catalog
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical    = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 24)
	_grid.add_theme_constant_override("v_separation", 24)
	scroll.add_child(_grid)

	for id in Cosmetics.ids():
		var card = _build_card(id)
		_grid.add_child(card)
		_cards[id]["root"] = card

	_toast = _label("", 32, UIStyle.GOLD)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	column.add_child(_toast)

	# Hint bar
	var hint = PanelContainer.new()
	hint.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL, Color(0, 0, 0, 0), 8, 0))
	column.add_child(hint)
	var hint_label = _label("Buy an item then press Place   Click to place   Click a placed item to remove it", 24, UIStyle.TEXT_DIM)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_child(hint_label)


func _build_filters() -> void:
	var cats = Cosmetics.categories()
	if cats.size() < 2:
		return   # a filter is pointless with a single category
	var options = [""] + cats
	for option in options:
		var b = _button("All" if option == "" else option, option == _filter, 26)
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		b.custom_minimum_size   = Vector2(120, 48)
		b.pressed.connect(_on_filter_pressed.bind(option))
		_filter_row.add_child(b)


func _on_filter_pressed(option: String) -> void:
	_filter = option
	for child in _filter_row.get_children():
		child.queue_free()
	_build_filters()
	_refresh()


func _build_card(id: String) -> Control:
	var def = Cosmetics.get_def(id)

	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIStyle.box(UIStyle.PANEL, UIStyle.PANEL_EDGE, 12, 2))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)

	var icon = TextureRect.new()
	icon.texture             = Cosmetics.make_texture(id)
	icon.texture_filter      = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(0, 180)
	box.add_child(icon)

	var name_label = _label(def.name, 36)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)

	var price_row = HBoxContainer.new()
	price_row.alignment = BoxContainer.ALIGNMENT_CENTER
	price_row.add_theme_constant_override("separation", 8)
	box.add_child(price_row)
	price_row.add_child(_coin(32))
	var price_label = _label(str(def.price), 32)
	price_row.add_child(price_label)

	var info_label = _label("", 24, UIStyle.TEXT_DIM)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info_label)

	var buttons = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	var buy   = _button("Buy", true)
	var place = _button("Place")
	buy.pressed.connect(_on_buy_pressed.bind(id))
	place.pressed.connect(_on_place_pressed.bind(id))
	buttons.add_child(buy)
	buttons.add_child(place)

	_cards[id] = {"info": info_label, "buy": buy, "place": place, "price": price_label}
	return card


# --- Logic -------------------------------------------------------------------

func _refresh() -> void:
	_gems_label.text = str(LevelManager.currency)
	for id in _cards:
		var card  = _cards[id]
		var def   = Cosmetics.get_def(id)
		card["root"].visible = _filter == "" or def.category == _filter

		var owned    = LevelManager.owned_count(id)
		var price    = int(def.price)
		var missing  = price - LevelManager.currency
		var can_buy  = missing <= 0

		if can_buy:
			card["info"].text = "Owned %d   Placed %d" % [owned, LevelManager.placed_count(id)] if owned > 0 else "New"
			card["info"].add_theme_color_override("font_color", UIStyle.TEXT_DIM)
		else:
			card["info"].text = "Need %d more gems" % missing
			card["info"].add_theme_color_override("font_color", UIStyle.BAD)
		card["price"].add_theme_color_override("font_color", UIStyle.TEXT if can_buy else UIStyle.BAD)

		card["buy"].disabled = not can_buy
		# Place only makes sense once the player owns the item
		card["place"].visible = owned > 0


func _on_buy_pressed(id: String) -> void:
	if LevelManager.buy_cosmetic(id):
		_show_toast("%s bought" % Cosmetics.get_def(id).name)
		var button: Button = _cards[id]["buy"]
		var at = button.get_global_rect().get_center()
		FX.burst(_root, at, [UIStyle.GOLD, UIStyle.GOLD_HOVER, Color(1, 1, 1)], 22, 240.0, 8.0, 0.7)


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.2)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)


func _on_place_pressed(id: String) -> void:
	place_requested.emit(id)
	_close()
