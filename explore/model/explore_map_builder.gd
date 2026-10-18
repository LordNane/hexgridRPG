class_name ExploreMapBuilder extends RefCounted
## Reads an authored ExploreMapScene (painted tile layers plus markers) into an ExploreMap, looking
## content up by the ids in the tiles' custom data. Authoring mistakes are collected in
## [member problems] instead of stopping the build, so one bad tile doesn't hide the rest.

const TERRAIN_ID := &"terrain_id"
const FEATURE_ID := &"feature_id"
const REGION_ID := &"region_id"

## Mistakes found by the last [method build], as readable sentences.
var problems := PackedStringArray()

var _content: ContentRegistry


func _init(content: ContentRegistry) -> void:
	_content = content


func build(source: ExploreMapScene, map_id: StringName) -> ExploreMap:
	problems.clear()
	var map := ExploreMap.new(map_id)
	if source.terrain == null:
		problems.append("the map has no terrain layer")
		return map
	_read_layer(source.terrain, TERRAIN_ID, TerrainDef, map.set_terrain)
	if source.features:
		_read_layer(source.features, FEATURE_ID, FeatureDef, func(hex: Vector2i, def: Def) -> void:
			if _is_on_map(map, hex, "a %s feature" % def.id):
				map.set_feature(hex, def as FeatureDef))
	if source.regions:
		_read_layer(source.regions, REGION_ID, RegionDef, func(hex: Vector2i, def: Def) -> void:
			if map.has_hex(hex):
				map.set_region(hex, def as RegionDef))
	if source.markers:
		for marker: HexMarker in HexMarker.find_all(source.markers):
			_add_marker(map, marker, marker.hex_on(source.terrain))
	return map


## Calls [param place] with each painted hex of [param layer] and the [param type] Def that its
## tile's [param key] custom data names.
func _read_layer(layer: TileMapLayer, key: StringName, type: Script, place: Callable) -> void:
	if layer.tile_set == null or layer.tile_set.get_custom_data_layer_by_name(key) < 0:
		problems.append("%s: its TileSet has no \"%s\" custom data layer" % [layer.name, key])
		return
	var unknown: Dictionary[StringName, Array] = {}
	for hex: Vector2i in layer.get_used_cells():
		var id: StringName = layer.get_cell_tile_data(hex).get_custom_data(key)
		var def := _content.get_def(id)
		if def and is_instance_of(def, type):
			place.call(hex, def)
		else:
			if not unknown.has(id):
				unknown[id] = []
			unknown[id].append(hex)
	for id: StringName in unknown:
		var hexes: Array = unknown[id]
		var what := "no %s" % key if id.is_empty() else "\"%s\", which isn't a %s" % [id, type.get_global_name()]
		problems.append("%s: %d tiles have %s (first at %s)" % [layer.name, hexes.size(), what, hexes[0]])


func _add_marker(map: ExploreMap, marker: HexMarker, hex: Vector2i) -> void:
	if not _is_on_map(map, hex, marker.name):
		return
	if marker is PoiMarker:
		var poi := (marker as PoiMarker).poi
		if poi == null:
			problems.append("%s has no PoiDef" % marker.name)
		elif map.poi_at(hex):
			problems.append("%s shares hex %s with another POI" % [marker.name, hex])
		else:
			map.set_poi(hex, poi)
	elif marker is EntryMarker:
		var entry_name := (marker as EntryMarker).entry_name
		if map.has_entry(entry_name):
			problems.append("two entries are named \"%s\"" % entry_name)
		else:
			map.set_entry(entry_name, hex)


func _is_on_map(map: ExploreMap, hex: Vector2i, what: String) -> bool:
	if map.has_hex(hex):
		return true
	problems.append("%s at %s has no terrain under it" % [what, hex])
	return false
