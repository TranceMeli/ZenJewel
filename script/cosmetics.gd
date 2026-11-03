# cosmetics.gd
# Catalog of all purchasable decorations. A new entry only needs a region in
# the environment atlas, a name, a price and a category.
class_name Cosmetics
extends RefCounted

const ATLAS       = preload("res://assets/zenjewel_environment.png")
const PIXEL_SCALE = 6    # Environment-Layer ist 6x skaliert
const CELL        = 96   # 16 px Tile * PIXEL_SCALE
const GROUND_ROW  = 8    # Reihe, in der Bodendekor steht (Unterkante = Wiese)

# region: crop in the atlas (pixels), ground: true = stands on the meadow,
# false = may be placed freely in the background.
const CATALOG = {
	"mushroom": {
		"name":   "Mushroom",
		"price":  25,
		"region": Rect2(16, 0, 16, 16),
		"ground": true,
		"category": "Ground",
	},
	"rocket": {
		"name":   "Rocket",
		"price":  300,
		"region": Rect2(0, 0, 16, 45),
		"ground": true,
		"category": "Ground",
	},
	# Items below use their own image ("file", optionally cropped by "region") and a per-item "scale"
	"heart": {
		"name":   "Heart",
		"price":  40,
		"file":   "res://assets/cosmetics/heart.png",
		"scale":  3.0,
		"ground": false,
		"category": "Sky",
	},
	"tile_0_0": {
		"name":   "Purple top",
		"price":  20,
		"file":   "res://assets/cosmetics/tileset_purple.png",
		"region": Rect2(0, 0, 16, 16),
		"scale":  6.0,
		"ground": false,
		"category": "Tiles",
	},
	"tile_1_0": {
		"name":   "Purple sky",
		"price":  20,
		"file":   "res://assets/cosmetics/tileset_purple.png",
		"region": Rect2(16, 0, 16, 16),
		"scale":  6.0,
		"ground": false,
		"category": "Tiles",
	},
	"tile_2_0": {
		"name":   "Orange diamond",
		"price":  20,
		"file":   "res://assets/cosmetics/lamps.png",
		"region": Rect2(0, 0, 16, 16),
		"scale":  6.0,
		"ground": false,
		"category": "Tiles",
	},
	"tile_0_1": {
		"name":   "Orange lamp top",
		"price":  20,
		"file":   "res://assets/cosmetics/lamps.png",
		"region": Rect2(16, 0, 16, 16),
		"scale":  6.0,
		"ground": false,
		"category": "Tiles",
	},
	"tile_1_1": {
		"name":   "Purple block",
		"price":  20,
		"file":   "res://assets/cosmetics/tileset_purple.png",
		"region": Rect2(16, 16, 16, 16),
		"scale":  6.0,
		"ground": false,
		"category": "Tiles",
	},
	"tile_2_1": {
		"name":   "Purple wall",
		"price":  20,
		"file":   "res://assets/cosmetics/tileset_purple.png",
		"region": Rect2(32, 16, 16, 16),
		"scale":  6.0,
		"ground": false,
		"category": "Tiles",
	},
	"tile_0_2": {
		"name":   "Lamp post",
		"price":  20,
		"file":   "res://assets/cosmetics/lamps.png",
		"region": Rect2(32, 0, 16, 16),
		"scale":  6.0,
		"ground": true,
		"category": "Tiles",
	},
	"tile_1_2": {
		"name":   "Purple step",
		"price":  20,
		"file":   "res://assets/cosmetics/tileset_purple.png",
		"region": Rect2(16, 32, 16, 16),
		"scale":  6.0,
		"ground": true,
		"category": "Tiles",
	},
	"potion": {
		"name":   "Potion",
		"price":  80,
		"file":   "res://assets/cosmetics/potion.png",
		"scale":  0.96,
		"ground": true,
		"category": "Ground",
	},
	"yellow_post": {
		"name":   "Ony_02",
		"price":  50,
		"file":   "res://assets/cosmetics/yellow_post.png",
		"scale":  3.0,
		"ground": true,
		"category": "Ground",
	},
	"yellow_smiley": {
		"name":   "Ony_01",
		"price":  50,
		"file":   "res://assets/cosmetics/yellow_smiley.png",
		"scale":  3.0,
		"ground": true,
		"category": "Ground",
	},
}


static func ids() -> Array:
	return CATALOG.keys()


static func categories() -> Array:
	var cats: Array = []
	for id in CATALOG:
		if not cats.has(CATALOG[id]["category"]):
			cats.append(CATALOG[id]["category"])
	return cats


static func exists(id: String) -> bool:
	return CATALOG.has(id)


static func get_def(id: String) -> Dictionary:
	return CATALOG.get(id, {})


static func make_texture(id: String) -> Texture2D:
	var def: Dictionary = CATALOG[id]
	if def.has("file") and not def.has("region"):
		return load(def["file"])
	var tex := AtlasTexture.new()
	tex.atlas  = load(def["file"]) if def.has("file") else ATLAS
	tex.region = def["region"]
	return tex


## Scale factor from source pixels to screen pixels.
static func scale_of(id: String) -> float:
	return float(CATALOG[id].get("scale", PIXEL_SCALE))


## Size on screen in pixels; quarter turns (rot 1 and 3) swap width and height.
static func size_px(id: String, rot: int = 0) -> Vector2:
	var def: Dictionary = CATALOG[id]
	var src: Vector2 = def["region"].size if def.has("region") else make_texture(id).get_size()
	var size = src * scale_of(id)
	return Vector2(size.y, size.x) if rot % 2 != 0 else size
