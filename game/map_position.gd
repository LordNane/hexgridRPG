class_name MapPosition extends RefCounted
## Where the party stands on one map: the map's id and the hex. Exploration moves it as the party
## walks, so the session always knows where to put the party back after loading.

## The MapDef id.
var map_id: StringName
var hex: Vector2i


func _init(on_map: StringName = &"", at_hex: Vector2i = Vector2i.ZERO) -> void:
	map_id = on_map
	hex = at_hex


func to_dict() -> Dictionary:
	return {"map": String(map_id), "hex": [hex.x, hex.y]}


static func from_dict(data: Dictionary) -> MapPosition:
	var coords: Array = data.get("hex", [0, 0])
	return MapPosition.new(StringName(data.get("map", "")), Vector2i(int(coords[0]), int(coords[1])))
