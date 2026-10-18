extends GutTest
## Reading an arena built in code with the game's TileSet: grass is terrain tile (0, 0), height
## tiles are source 3 (height = x), and a tree is prop tile (0, 0) of source 4.

const TILE_SET := "res://assets/tilesets/overworld_tileset.tres"
const TERRAIN_SOURCE := 0
const HEIGHT_SOURCE := 3
const PROP_SOURCE := 4

var _arena: BattleArena
var _content: ContentRegistry


func before_each() -> void:
	_content = FakeContent.registry([FakeContent.terrain(&"grass"), FakeContent.prop(&"tree")])
	_arena = BattleArena.new()
	var tile_set: TileSet = load(TILE_SET)
	for layer_name: String in ["Terrain", "Heights", "Props"]:
		var layer := TileMapLayer.new()
		layer.name = layer_name
		layer.tile_set = tile_set
		_arena.add_child(layer)
	_arena.terrain = _arena.get_node("Terrain")
	_arena.heights = _arena.get_node("Heights")
	_arena.props = _arena.get_node("Props")
	_arena.markers = Node2D.new()
	_arena.add_child(_arena.markers)
	for hex: Vector2i in Hex.disc(Vector2i.ZERO, 3):
		_arena.terrain.set_cell(hex, TERRAIN_SOURCE, Vector2i(0, 0))
	add_child_autofree(_arena)


func test_reads_terrain_heights_props_and_spawns() -> void:
	_arena.heights.set_cell(Vector2i(1, 0), HEIGHT_SOURCE, Vector2i(2, 0))
	_arena.props.set_cell(Vector2i(0, 1), PROP_SOURCE, Vector2i(0, 0))
	_spawn(PartySpawn.new(), Vector2i(-2, 0), Hex.Dir.NE)
	_spawn(PartySpawn.new(), Vector2i(-2, 1), Hex.Dir.SE)
	_spawn(EnemySpawn.new(), Vector2i(2, 0), Hex.Dir.NW)
	var builder := BattleMapBuilder.new(_content)
	var map := builder.build(_arena)
	assert_eq(builder.problems, PackedStringArray())
	assert_eq(map.hexes().size(), Hex.disc(Vector2i.ZERO, 3).size())
	assert_eq(map.terrain_at(Vector2i.ZERO).id, &"grass")
	assert_eq(map.height_at(Vector2i(1, 0)), 2)
	assert_eq(map.height_at(Vector2i.ZERO), 0, "unpainted hexes are at height 0")
	assert_eq(map.prop_at(Vector2i(0, 1)).id, &"tree")
	assert_eq(map.party_spawns.size(), 2)
	assert_eq(map.party_spawns[0].hex, Vector2i(-2, 0), "spawns keep scene order")
	assert_eq(map.party_spawns[0].facing, Hex.Dir.NE)
	assert_eq(map.enemy_spawns[0].hex, Vector2i(2, 0))


func test_authoring_mistakes_are_reported() -> void:
	_arena.props.set_cell(Vector2i(0, 1), PROP_SOURCE, Vector2i(0, 1))
	_arena.props.set_cell(Vector2i(1, 1), PROP_SOURCE, Vector2i(0, 0))
	_arena.heights.set_cell(Vector2i(9, 0), HEIGHT_SOURCE, Vector2i(1, 0))
	_spawn(PartySpawn.new(), Vector2i(1, 1), Hex.Dir.SE)
	var builder := BattleMapBuilder.new(_content)
	builder.build(_arena)
	var problems := "\n".join(builder.problems)
	assert_string_contains(problems, "\"rock\", which isn't a PropDef")
	assert_string_contains(problems, "a height tile at (9, 0) has no terrain under it")
	assert_string_contains(problems, "on a hex nobody can stand on")
	assert_string_contains(problems, "needs at least one PartySpawn and one EnemySpawn")


func _spawn(marker: SpawnMarker, hex: Vector2i, facing: Hex.Dir) -> void:
	marker.name = "%s%d" % [marker.get_script().get_global_name(), _arena.markers.get_child_count()]
	marker.position = _arena.terrain.map_to_local(hex)
	marker.facing = facing
	_arena.markers.add_child(marker)
