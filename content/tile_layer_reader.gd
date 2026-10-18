class_name TileLayerReader
## Reads painted TileMapLayers whose tiles name content in their custom data, such as "terrain_id",
## for the map builders. Every map, exploration or battle, is painted this way.


## Calls [param place] with each painted hex of [param layer] and the [param type] Def that its
## tile's [param key] custom data names. Returns the authoring mistakes found, as sentences.
static func read_defs(layer: TileMapLayer, key: StringName, type: Script, content: ContentRegistry, place: Callable) -> PackedStringArray:
	var problems := PackedStringArray()
	if layer.tile_set == null or layer.tile_set.get_custom_data_layer_by_name(key) < 0:
		problems.append("%s: its TileSet has no \"%s\" custom data layer" % [layer.name, key])
		return problems
	var unknown: Dictionary[StringName, Array] = {}
	for hex: Vector2i in layer.get_used_cells():
		var id: StringName = layer.get_cell_tile_data(hex).get_custom_data(key)
		var def := content.get_def(id)
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
	return problems
