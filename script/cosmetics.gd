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
	"stump": {
		"name":   "Tree trunk",
		"price":  60,
		"region": Rect2(48, 48, 16, 16),
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


static func make_texture(id: String) -> AtlasTexture:
	var tex := AtlasTexture.new()
	tex.atlas  = ATLAS
	tex.region = CATALOG[id]["region"]
	return tex


## Größe des Dekors auf dem Bildschirm in Pixeln.
static func size_px(id: String) -> Vector2:
	var region: Rect2 = CATALOG[id]["region"]
	return region.size * PIXEL_SCALE
