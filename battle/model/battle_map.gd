class_name BattleMap extends RefCounted
## The rules side of a battle arena: each hex's terrain, height and prop, and where each side's
## units start. BattleMapBuilder fills it from an authored BattleArena; it never touches nodes.


## Where a unit starts: its hex and the [enum Hex.Dir] it faces.
class Spawn:
	var hex: Vector2i
	var facing: int

	func _init(at: Vector2i, faces: int) -> void:
		hex = at
		facing = faces


## Where the party's units start, in the order members are placed.
var party_spawns: Array[Spawn] = []
## Where the enemies start, in the order an encounter lists them.
var enemy_spawns: Array[Spawn] = []

var _terrain: Dictionary[Vector2i, TerrainDef] = {}
var _heights: Dictionary[Vector2i, int] = {}
var _props: Dictionary[Vector2i, PropDef] = {}


## Makes [param hex] part of the map, with [param terrain] at [param height] levels up.
func set_cell(hex: Vector2i, terrain: TerrainDef, height: int = 0) -> void:
	_terrain[hex] = terrain
	_heights[hex] = height


func set_height(hex: Vector2i, height: int) -> void:
	_heights[hex] = height


func set_prop(hex: Vector2i, prop: PropDef) -> void:
	_props[hex] = prop


func has_hex(hex: Vector2i) -> bool:
	return _terrain.has(hex)


## Every hex of the map.
func hexes() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.assign(_terrain.keys())
	return result


## The terrain on [param hex], or null off the map.
func terrain_at(hex: Vector2i) -> TerrainDef:
	return _terrain.get(hex)


## How many elevation levels up [param hex] is; 0 off the map.
func height_at(hex: Vector2i) -> int:
	return _heights.get(hex, 0)


## The prop on [param hex], or null.
func prop_at(hex: Vector2i) -> PropDef:
	return _props.get(hex)


## Whether a unit could stand on [param hex]: it's on the map, its terrain can be entered and no
## prop blocks it.
func is_walkable(hex: Vector2i) -> bool:
	var terrain := terrain_at(hex)
	var prop := prop_at(hex)
	return terrain != null and terrain.passable and not (prop and prop.blocks_movement)
