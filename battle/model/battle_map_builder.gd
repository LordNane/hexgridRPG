class_name BattleMapBuilder extends RefCounted
## Reads an authored BattleArena (painted terrain, height and prop layers plus spawn markers) into
## a BattleMap, looking content up by the ids in the tiles' custom data. Authoring mistakes are
## collected in [member problems] instead of stopping the build.

## Custom data on height tiles: the elevation, 0–9.
const HEIGHT := &"height"
## Custom data on prop tiles: the PropDef id.
const PROP_ID := &"prop_id"

## Mistakes found by the last [method build], as readable sentences.
var problems := PackedStringArray()

var _content: ContentRegistry


func _init(content: ContentRegistry) -> void:
	_content = content


## The arena must be in the scene tree, so its markers' positions can be read.
func build(arena: BattleArena) -> BattleMap:
	problems.clear()
	var map := BattleMap.new()
	if arena.terrain == null:
		problems.append("the arena has no terrain layer")
		return map
	problems.append_array(TileLayerReader.read_defs(arena.terrain, ExploreMapBuilder.TERRAIN_ID, TerrainDef, _content,
			func(hex: Vector2i, def: Def) -> void: map.set_cell(hex, def as TerrainDef)))
	if arena.heights:
		_read_heights(arena.heights, map)
	if arena.props:
		problems.append_array(TileLayerReader.read_defs(arena.props, PROP_ID, PropDef, _content,
				func(hex: Vector2i, def: Def) -> void:
					if _is_on_map(map, hex, "a %s prop" % def.id):
						map.set_prop(hex, def as PropDef)))
	if arena.markers:
		for marker: HexMarker in HexMarker.find_all(arena.markers):
			if marker is SpawnMarker:
				_add_spawn(map, marker as SpawnMarker, marker.hex_on(arena.terrain))
	if map.party_spawns.is_empty() or map.enemy_spawns.is_empty():
		problems.append("the arena needs at least one PartySpawn and one EnemySpawn")
	return map


func _read_heights(layer: TileMapLayer, map: BattleMap) -> void:
	if layer.tile_set == null or layer.tile_set.get_custom_data_layer_by_name(HEIGHT) < 0:
		problems.append("%s: its TileSet has no \"%s\" custom data layer" % [layer.name, HEIGHT])
		return
	for hex: Vector2i in layer.get_used_cells():
		if _is_on_map(map, hex, "a height tile"):
			map.set_height(hex, int(layer.get_cell_tile_data(hex).get_custom_data(HEIGHT)))


func _add_spawn(map: BattleMap, marker: SpawnMarker, hex: Vector2i) -> void:
	if not _is_on_map(map, hex, marker.name):
		return
	if not map.is_walkable(hex):
		problems.append("%s at %s is on a hex nobody can stand on" % [marker.name, hex])
		return
	for spawn: BattleMap.Spawn in map.party_spawns + map.enemy_spawns:
		if spawn.hex == hex:
			problems.append("%s shares hex %s with another spawn" % [marker.name, hex])
			return
	var spawns := map.party_spawns if marker.team() == BattleUnit.Team.PARTY else map.enemy_spawns
	spawns.append(BattleMap.Spawn.new(hex, marker.facing))


func _is_on_map(map: BattleMap, hex: Vector2i, what: String) -> bool:
	if map.has_hex(hex):
		return true
	problems.append("%s at %s has no terrain under it" % [what, hex])
	return false
