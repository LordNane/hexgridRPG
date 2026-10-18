extends GutTest
## Checks the game's real content: everything loads, every reference resolves, and every map plays.

const GameScript := preload("res://game/game.gd")
const TILESETS: Array[String] = ["res://assets/tilesets/overworld_tileset.tres"]
const ID_KEYS: Array[StringName] = [ExploreMapBuilder.TERRAIN_ID, ExploreMapBuilder.FEATURE_ID, ExploreMapBuilder.REGION_ID, BattleMapBuilder.PROP_ID]

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
		var builder := ExploreMapBuilder.new(_registry)
		var map := _build(map_def, builder)
		assert_eq(builder.problems, PackedStringArray(), "%s builds cleanly" % map_def.id)
		assert_true(map.has_entry(&"start"), "%s has a start" % map_def.id)
		if not map.has_entry(&"start"):
			continue
		var exploration := Exploration.new(GameSession.new(), map, MapPosition.new(map_def.id, map.entry(&"start")), false)
		for hex: Vector2i in map.poi_hexes():
			assert_false(exploration.route_to(hex).is_empty(), "%s: %s at %s can be reached" % [map_def.id, map.poi_at(hex).id, hex])


func test_every_way_into_a_map_arrives_at_an_entry_it_has() -> void:
	for def: Def in _registry.all_of(PoiDef):
		for action: PoiAction in (def as PoiDef).actions:
			var enter := action as EnterMapAction
			if enter and enter.map:
				var map := _build(enter.map, ExploreMapBuilder.new(_registry))
				assert_true(map.has_entry(enter.entry), "%s enters %s at \"%s\"" % [def.id, enter.map.id, enter.entry])


func test_every_premade_character_can_use_its_gear_and_knows_what_it_learned() -> void:
	var characters := _registry.all_of(CharacterDef)
	assert_gt(characters.size(), 0)
	for def: Def in characters:
		var character_def := def as CharacterDef
		var character := Character.from_def(character_def, _registry)
		for item: EquipmentDef in character_def.equipment:
			var reason := EquipRules.can_equip(character, item, item.slot)
			assert_eq(reason, "", "%s wears %s" % [def.id, item.id])
		for ability: AbilityDef in character_def.learned:
			assert_true(character.knows(ability), "%s knows %s, which some job teaches" % [def.id, ability.id])


func test_each_ability_is_taught_by_at_most_one_job() -> void:
	var teachers: Dictionary[AbilityDef, StringName] = {}
	for def: Def in _registry.all_of(JobDef):
		for ability: AbilityDef in (def as JobDef).abilities:
			assert_false(teachers.has(ability), "%s is taught by %s and %s" % [ability.id, teachers.get(ability), def.id])
			teachers[ability] = def.id


func test_every_arena_builds_cleanly_with_room_for_its_battles() -> void:
	var arenas := _arena_paths()
	assert_gt(arenas.size(), 0)
	var most_enemies := 0
	for def: Def in _registry.all_of(EncounterDef):
		most_enemies = maxi(most_enemies, (def as EncounterDef).enemies.size())
	for path: String in arenas:
		var arena := (load(path) as PackedScene).instantiate() as BattleArena
		add_child_autofree(arena)
		var builder := BattleMapBuilder.new(_registry)
		var map := builder.build(arena)
		assert_eq(builder.problems, PackedStringArray(), "%s builds cleanly" % path)
		assert_gte(map.party_spawns.size(), GameScript.START_PARTY.size(), "%s has room for the party" % path)
		assert_gte(map.enemy_spawns.size(), most_enemies, "%s has room for the biggest encounter" % path)


func test_every_random_battle_has_an_arena_wherever_it_can_happen() -> void:
	for def: Def in _registry.all_of(MapDef):
		var map := _build(def as MapDef, ExploreMapBuilder.new(_registry))
		var missing: Dictionary[String, Vector2i] = {}
		for hex: Vector2i in map.hexes():
			var region := map.region_at(hex)
			if region == null or region.encounters == null or not map.terrain_at(hex).passable:
				continue
			for encounter: EncounterDef in region.encounters.encounters:
				var what := "%s on %s" % [encounter.id, map.terrain_at(hex).id]
				if encounter.arena_pool(map.terrain_at(hex), map.feature_at(hex)).is_empty() and not missing.has(what):
					missing[what] = hex
		assert_eq(missing.size(), 0, "%s: battles without an arena: %s" % [def.id, missing])


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


## Every arena scene in a terrain's, feature's or encounter's pool.
func _arena_paths() -> Array[String]:
	var paths: Array[String] = []
	for def: Def in _registry.all():
		var pool: Array[String] = []
		if def is TerrainDef:
			pool = (def as TerrainDef).battle_arenas
		elif def is FeatureDef:
			pool = (def as FeatureDef).battle_arenas
		elif def is EncounterDef:
			pool = (def as EncounterDef).arenas
		for path: String in pool:
			if not paths.has(path):
				paths.append(path)
	return paths


## Builds [param map_def]'s scene with [param builder]. The scene must be in the tree to be read.
func _build(map_def: MapDef, builder: ExploreMapBuilder) -> ExploreMap:
	var scene := (load(map_def.scene) as PackedScene).instantiate() as ExploreMapScene
	add_child_autofree(scene)
	return builder.build(scene, map_def.id)
