extends SceneTree
## Builds the placeholder TileSets from the placeholder art. Run gen_placeholder_art.gd and an
## import first, so the textures exist:
## [codeblock]
## godot --headless --path . --import
## godot --headless --path . -s res://tools/gen_placeholder_tilesets.gd
## [/codeblock]
## - overworld_tileset.tres: every hex map's tiles, exploration and battle: terrain, feature, region,
##   height and prop tiles. Each names its content through "terrain_id", "feature_id",
##   "region_id" or "prop_id" custom data; height tiles hold their "height", and terrain tiles hold
##   the "cliff" texture battles draw under raised hexes.
## - fog_tileset.tres: the fog ExploreMode draws over unexplored and remembered hexes.
## Re-running overwrites both files, including any edits made in the editor.

const ART_DIR := "res://assets/tilesets/placeholder/"
const OUT_DIR := "res://assets/tilesets/"

## Atlas source ids in the overworld TileSet.
const TERRAIN_SOURCE := 0
const FEATURE_SOURCE := 1
const REGION_SOURCE := 2
const HEIGHT_SOURCE := 3
const PROP_SOURCE := 4

## Must match the rows gen_placeholder_art.gd draws and the ids in res://content/data/.
const TERRAIN_IDS: Array[StringName] = [&"grass", &"dirt", &"stone", &"sand", &"water", &"snow", &"swamp", &"cave_wall"]
const TERRAIN_VARIANTS := 4
const FEATURE_IDS: Array[StringName] = [&"forest", &"hills", &"mountains"]
const FEATURE_VARIANTS := 2
## Tints without an id are spares: give one a region_id in the TileSet editor to add a region.
const REGION_IDS: Array[StringName] = [&"greenvale", &"thornwood", &"frost_reach", &"", &"", &""]
## Height tiles 0–9, from height_digits.png.
const HEIGHT_COUNT := 10
## Must match the rows gen_placeholder_art.gd draws in props.png.
const PROP_IDS: Array[StringName] = [&"tree", &"rock"]
const PROP_VARIANTS := 2

var _cell := HexLayout.new().cell_size
var _step := HexLayout.new().elevation_step


func _init() -> void:
	var failures := 0
	failures += _save(_overworld_tileset(), OUT_DIR + "overworld_tileset.tres")
	failures += _save(_fog_tileset(), OUT_DIR + "fog_tileset.tres")
	quit(failures)


func _overworld_tileset() -> TileSet:
	var tile_set := _hex_tileset()
	var data_layers: Dictionary[StringName, Variant.Type] = {
		ExploreMapBuilder.TERRAIN_ID: TYPE_STRING_NAME, ExploreMapBuilder.FEATURE_ID: TYPE_STRING_NAME,
		ExploreMapBuilder.REGION_ID: TYPE_STRING_NAME, BattleMapBuilder.HEIGHT: TYPE_INT,
		BattleMapBuilder.PROP_ID: TYPE_STRING_NAME, TileArt.CLIFF: TYPE_OBJECT,
	}
	for key: StringName in data_layers:
		var layer := tile_set.get_custom_data_layers_count()
		tile_set.add_custom_data_layer()
		tile_set.set_custom_data_layer_name(layer, key)
		tile_set.set_custom_data_layer_type(layer, data_layers[key])

	var terrain := _atlas("terrain_tops.png", _cell)
	tile_set.add_source(terrain, TERRAIN_SOURCE)
	var cliffs: Texture2D = load(ART_DIR + "cliff_faces.png")
	for row: int in TERRAIN_IDS.size():
		var cliff := AtlasTexture.new()
		cliff.atlas = cliffs
		cliff.region = Rect2(0, row * (_cell.y + _step), _cell.x, _cell.y + _step)
		for variant: int in TERRAIN_VARIANTS:
			var tile := _add_tile(terrain, Vector2i(variant, row), ExploreMapBuilder.TERRAIN_ID, TERRAIN_IDS[row])
			tile.set_custom_data(TileArt.CLIFF, cliff)

	# Feature art is two hexes tall; lift it so its bottom half covers the hex, and sort it just
	# before anything else on the same hex so the party stands in front of its own forest.
	var features := _atlas("features.png", Vector2i(_cell.x, _cell.y * 2))
	tile_set.add_source(features, FEATURE_SOURCE)
	for row: int in FEATURE_IDS.size():
		for variant: int in FEATURE_VARIANTS:
			var tile := _add_tile(features, Vector2i(variant, row), ExploreMapBuilder.FEATURE_ID, FEATURE_IDS[row])
			tile.texture_origin = Vector2i(0, _cell.y / 2)
			tile.y_sort_origin = -1

	var regions := _atlas("regions.png", _cell)
	tile_set.add_source(regions, REGION_SOURCE)
	for i: int in REGION_IDS.size():
		_add_tile(regions, Vector2i(i, 0), ExploreMapBuilder.REGION_ID, REGION_IDS[i])

	var heights := _atlas("height_digits.png", _cell)
	tile_set.add_source(heights, HEIGHT_SOURCE)
	for height: int in HEIGHT_COUNT:
		heights.create_tile(Vector2i(height, 0))
		heights.get_tile_data(Vector2i(height, 0), 0).set_custom_data(BattleMapBuilder.HEIGHT, height)

	# Props stand on their hex like features do.
	var props := _atlas("props.png", Vector2i(_cell.x, _cell.y * 2))
	tile_set.add_source(props, PROP_SOURCE)
	for row: int in PROP_IDS.size():
		for variant: int in PROP_VARIANTS:
			var tile := _add_tile(props, Vector2i(variant, row), BattleMapBuilder.PROP_ID, PROP_IDS[row])
			tile.texture_origin = Vector2i(0, _cell.y / 2)
			tile.y_sort_origin = -1
	return tile_set


func _fog_tileset() -> TileSet:
	var tile_set := _hex_tileset()
	var fog := _atlas("fog.png", _cell)
	tile_set.add_source(fog, 0)
	fog.create_tile(Vector2i(0, 0))
	fog.create_tile(Vector2i(1, 0))
	return tile_set


## A TileSet whose map coordinates are HexLayout's axial coordinates.
func _hex_tileset() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_shape = TileSet.TILE_SHAPE_HEXAGON
	tile_set.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
	tile_set.tile_layout = TileSet.TILE_LAYOUT_STAIRS_DOWN
	tile_set.tile_size = _cell
	return tile_set


func _atlas(file: String, region_size: Vector2i) -> TileSetAtlasSource:
	var source := TileSetAtlasSource.new()
	source.texture = load(ART_DIR + file)
	source.texture_region_size = region_size
	return source


func _add_tile(source: TileSetAtlasSource, coords: Vector2i, key: StringName, id: StringName) -> TileData:
	source.create_tile(coords)
	var tile := source.get_tile_data(coords, 0)
	tile.set_custom_data(key, id)
	return tile


func _save(tile_set: TileSet, path: String) -> int:
	var error := ResourceSaver.save(tile_set, path)
	print("%s %s" % ["wrote" if error == OK else "FAILED (%s)" % error_string(error), path])
	return 0 if error == OK else 1
