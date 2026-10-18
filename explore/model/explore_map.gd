class_name ExploreMap extends RefCounted
## The rules side of an explorable map: the terrain, nature feature, region and POI on each hex,
## plus named arrival points. ExploreMapBuilder fills it from an authored scene; it never touches nodes.

## The MapDef id, used to find this map's saved state.
var id: StringName

var _terrain: Dictionary[Vector2i, TerrainDef] = {}
var _features: Dictionary[Vector2i, FeatureDef] = {}
var _regions: Dictionary[Vector2i, RegionDef] = {}
var _pois: Dictionary[Vector2i, PoiDef] = {}
var _entries: Dictionary[StringName, Vector2i] = {}


func _init(map_id: StringName = &"") -> void:
	id = map_id


func set_terrain(hex: Vector2i, terrain: TerrainDef) -> void:
	_terrain[hex] = terrain


func set_feature(hex: Vector2i, feature: FeatureDef) -> void:
	_features[hex] = feature


func set_region(hex: Vector2i, region: RegionDef) -> void:
	_regions[hex] = region


func set_poi(hex: Vector2i, poi: PoiDef) -> void:
	_pois[hex] = poi


func set_entry(entry_name: StringName, hex: Vector2i) -> void:
	_entries[entry_name] = hex


## Whether [param hex] is part of the map (has terrain).
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


## The nature feature on [param hex], or null.
func feature_at(hex: Vector2i) -> FeatureDef:
	return _features.get(hex)


## The region [param hex] belongs to, or null.
func region_at(hex: Vector2i) -> RegionDef:
	return _regions.get(hex)


## The POI on [param hex], or null.
func poi_at(hex: Vector2i) -> PoiDef:
	return _pois.get(hex)


## Every hex that has a POI.
func poi_hexes() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.assign(_pois.keys())
	return result


## Whether the map has an arrival point named [param entry_name].
func has_entry(entry_name: StringName) -> bool:
	return _entries.has(entry_name)


## The hex of the arrival point named [param entry_name].
func entry(entry_name: StringName) -> Vector2i:
	return _entries[entry_name]


## Whether [param hex] stops line of sight past it.
func blocks_sight(hex: Vector2i) -> bool:
	var terrain := terrain_at(hex)
	var feature := feature_at(hex)
	return (terrain != null and terrain.blocks_sight) or (feature != null and feature.blocks_sight)


## Extra vision range while standing on [param hex].
func sight_bonus(hex: Vector2i) -> int:
	var feature := feature_at(hex)
	return feature.sight_bonus if feature else 0
