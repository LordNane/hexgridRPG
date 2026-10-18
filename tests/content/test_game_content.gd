extends GutTest
## Checks the game's real content: everything loads, every reference resolves, and every map plays.

const TILESETS: Array[String] = ["res://assets/tilesets/overworld_tileset.tres"]
const ID_KEYS: Array[StringName] = [ExploreMapBuilder.TERRAIN_ID, ExploreMapBuilder.FEATURE_ID, ExploreMapBuilder.REGION_ID]

var _registry: ContentRegistry


func before_all() -> void:
	_registry = ContentRegistry.new()
	_registry.load_dir(ContentDB.DATA_DIR)


func test_all_content_loads() -> void:
	assert_eq(_registry.problems, PackedStringArray())
	assert_gt(_registry.all().size(), 0)


func test_content_has_no_mistakes_or_broken_references() -> void:
	assert_eq(ContentValidator.validate(_registry), PackedStringArray())


func test_every_map_builds_cleanly_and_every_poi_can_be_reached() -> void:
	var maps := _registry.all_of(MapDef)
	assert_gt(maps.size(), 0)
	for def: Def in maps:
		var map_def := def as MapDef
		var scene := (load(map_def.scene) as PackedScene).instantiate() as ExploreMapScene
		add_child_autofree(scene)
		var builder := ExploreMapBuilder.new(_registry)
		var map := builder.build(scene, map_def.id)
		assert_eq(builder.problems, PackedStringArray(), "%s builds cleanly" % map_def.id)
		assert_true(map.has_entry(&"start"), "%s has a start" % map_def.id)
		if not map.has_entry(&"start"):
			continue
		var exploration := Exploration.new(GameSession.new(), map, map.entry(&"start"), false)
		for hex: Vector2i in map.poi_hexes():
			assert_false(exploration.route_to(hex).is_empty(), "%s: %s at %s can be reached" % [map_def.id, map.poi_at(hex).id, hex])


func test_tile_ids_name_registered_content() -> void:
	for path: String in TILESETS:
		var tile_set: TileSet = load(path)
		for source_index: int in tile_set.get_source_count():
			var source_id := tile_set.get_source_id(source_index)
			var source := tile_set.get_source(source_id) as TileSetAtlasSource
			for tile_index: int in source.get_tiles_count():
				var coords := source.get_tile_id(tile_index)
				for key: StringName in ID_KEYS:
					var id: StringName = source.get_tile_data(coords, 0).get_custom_data(key)
					if not id.is_empty():
						assert_true(_registry.has(id), "%s: tile %s in source %d names unknown \"%s\"" % [path, coords, source_id, id])
