extends GutTest

## Atlas tiles of the test TileSet, each naming one id through custom data.
const GRASS_TILE := Vector2i(0, 0)
const WATER_TILE := Vector2i(1, 0)
const FOREST_TILE := Vector2i(2, 0)
const VALE_TILE := Vector2i(3, 0)
const LAVA_TILE := Vector2i(4, 0)

var _registry: ContentRegistry
var _chest: PoiDef
var _scene: ExploreMapScene


func before_each() -> void:
	_chest = FakeContent.poi(&"chest", [FakeContent.message("Loot")])
	_registry = ContentRegistry.new()
	for def: Def in [FakeContent.terrain(&"grass"), FakeContent.terrain(&"water", 1.0, false),
			FakeContent.feature(&"forest", 1.0), FakeContent.region(&"vale"), _chest]:
		_registry.add(def)
	_scene = _make_scene()
	add_child_autofree(_scene)


func test_reads_every_layer_and_marker() -> void:
	_paint(_scene.terrain, Hex.disc(Vector2i.ZERO, 2), GRASS_TILE)
	_paint(_scene.terrain, [Vector2i(2, 0)], WATER_TILE)
	_paint(_scene.features, [Vector2i(0, 1)], FOREST_TILE)
	_paint(_scene.regions, [Vector2i(-1, 0), Vector2i(-1, 1)], VALE_TILE)
	_add_poi(Vector2i(1, -1), _chest)
	_add_entry(Vector2i(0, -1), &"start")
	var builder := ExploreMapBuilder.new(_registry)
	var map := builder.build(_scene, &"test")
	assert_eq(builder.problems, PackedStringArray())
	assert_eq(map.id, &"test")
	assert_eq(map.hexes().size(), 19)
	assert_eq(map.terrain_at(Vector2i(2, 0)).id, &"water")
	assert_eq(map.terrain_at(Vector2i(1, 0)).id, &"grass")
	assert_eq(map.feature_at(Vector2i(0, 1)).id, &"forest")
	assert_eq(map.region_at(Vector2i(-1, 1)).id, &"vale")
	assert_null(map.region_at(Vector2i.ZERO))
	assert_eq(map.poi_at(Vector2i(1, -1)), _chest)
	assert_eq(map.entry(&"start"), Vector2i(0, -1))


func test_unknown_tiles_are_reported_once_per_id() -> void:
	_paint(_scene.terrain, Hex.disc(Vector2i.ZERO, 1), GRASS_TILE)
	_paint(_scene.terrain, [Vector2i(3, 0), Vector2i(4, 0)], LAVA_TILE)
	var builder := ExploreMapBuilder.new(_registry)
	var map := builder.build(_scene, &"test")
	assert_eq(builder.problems.size(), 1)
	assert_string_contains(builder.problems[0], "2 tiles have \"lava\", which isn't a TerrainDef")
	assert_false(map.has_hex(Vector2i(3, 0)))


func test_marker_and_feature_mistakes_are_reported() -> void:
	_paint(_scene.terrain, Hex.disc(Vector2i.ZERO, 1), GRASS_TILE)
	_paint(_scene.features, [Vector2i(5, 0)], FOREST_TILE)
	_add_poi(Vector2i(6, 0), _chest)
	_add_poi(Vector2i(1, 0), null)
	_add_entry(Vector2i.ZERO, &"start")
	_add_entry(Vector2i(0, 1), &"start")
	var builder := ExploreMapBuilder.new(_registry)
	builder.build(_scene, &"test")
	var report := "\n".join(builder.problems)
	assert_string_contains(report, "a forest feature at (5, 0) has no terrain under it")
	assert_string_contains(report, "at (6, 0) has no terrain under it")
	assert_string_contains(report, "has no PoiDef")
	assert_string_contains(report, "two entries are named \"start\"")


func _make_scene() -> ExploreMapScene:
	var tile_set := TileSet.new()
	tile_set.tile_shape = TileSet.TILE_SHAPE_HEXAGON
	tile_set.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
	tile_set.tile_layout = TileSet.TILE_LAYOUT_STAIRS_DOWN
	tile_set.tile_size = Vector2i(32, 16)
	for key: StringName in [ExploreMapBuilder.TERRAIN_ID, ExploreMapBuilder.FEATURE_ID, ExploreMapBuilder.REGION_ID]:
		var layer := tile_set.get_custom_data_layers_count()
		tile_set.add_custom_data_layer()
		tile_set.set_custom_data_layer_name(layer, key)
		tile_set.set_custom_data_layer_type(layer, TYPE_STRING_NAME)
	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(Image.create_empty(32 * 5, 16, false, Image.FORMAT_RGBA8))
	source.texture_region_size = Vector2i(32, 16)
	tile_set.add_source(source, 0)
	_add_tile(source, GRASS_TILE, ExploreMapBuilder.TERRAIN_ID, &"grass")
	_add_tile(source, WATER_TILE, ExploreMapBuilder.TERRAIN_ID, &"water")
	_add_tile(source, FOREST_TILE, ExploreMapBuilder.FEATURE_ID, &"forest")
	_add_tile(source, VALE_TILE, ExploreMapBuilder.REGION_ID, &"vale")
	_add_tile(source, LAVA_TILE, ExploreMapBuilder.TERRAIN_ID, &"lava")

	var scene := ExploreMapScene.new()
	scene.terrain = _add_layer(scene, "Terrain", tile_set)
	scene.features = _add_layer(scene, "Features", tile_set)
	scene.regions = _add_layer(scene, "Regions", tile_set)
	scene.markers = Node2D.new()
	scene.markers.name = "Markers"
	scene.add_child(scene.markers)
	return scene


func _add_tile(source: TileSetAtlasSource, coords: Vector2i, key: StringName, id: StringName) -> void:
	source.create_tile(coords)
	source.get_tile_data(coords, 0).set_custom_data(key, id)


func _add_layer(scene: ExploreMapScene, layer_name: String, tile_set: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tile_set
	scene.add_child(layer)
	return layer


func _paint(layer: TileMapLayer, hexes: Array, tile: Vector2i) -> void:
	for hex: Vector2i in hexes:
		layer.set_cell(hex, 0, tile)


func _add_poi(hex: Vector2i, poi: PoiDef) -> void:
	var marker := PoiMarker.new()
	marker.poi = poi
	_place(marker, hex)


func _add_entry(hex: Vector2i, entry_name: StringName) -> void:
	var marker := EntryMarker.new()
	marker.entry_name = entry_name
	_place(marker, hex)


func _place(marker: HexMarker, hex: Vector2i) -> void:
	marker.position = _scene.terrain.map_to_local(hex)
	_scene.markers.add_child(marker)
