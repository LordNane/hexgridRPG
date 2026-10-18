@tool
class_name HexMarker extends Node2D
## A node placed on an authored hex map, such as a POI, an arrival point or a battle spawn. In the
## editor it snaps to the nearest hex center of its map's terrain layer: the [code]terrain[/code]
## of the scene root, an ExploreMapScene or a BattleArena.


func _ready() -> void:
	set_notify_local_transform(Engine.is_editor_hint())


func _notification(what: int) -> void:
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		_snap_to_hex()


## Every HexMarker under [param root], at any depth.
static func find_all(root: Node) -> Array[HexMarker]:
	var found: Array[HexMarker] = []
	for child: Node in root.get_children():
		if child is HexMarker:
			found.append(child)
		found.append_array(find_all(child))
	return found


## The hex this marker stands on, in [param tiles]' coordinates.
func hex_on(tiles: TileMapLayer) -> Vector2i:
	return tiles.local_to_map(tiles.to_local(global_position))


func _snap_to_hex() -> void:
	var tiles: TileMapLayer = owner.get(&"terrain") as TileMapLayer if owner else null
	if tiles == null:
		return
	var center := tiles.to_global(tiles.map_to_local(hex_on(tiles)))
	if not global_position.is_equal_approx(center):
		global_position = center
