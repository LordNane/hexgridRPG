class_name ExploreMovement extends RefCounted
## How the party moves on an exploration map, as step costs for HexPathfinder.
##
## A step costs the terrain's move cost plus the feature's extra cost. Impassable terrain, sheer
## features, POIs that block movement and, on fogged maps, unseen hexes can't be entered. Party
## traits such as boats or mounts will plug in here.

var _map: ExploreMap
var _fog: FogOfWar
var _min_step_cost := INF


## [param fog] is null on maps without fog of war.
func _init(map: ExploreMap, fog: FogOfWar = null) -> void:
	_map = map
	_fog = fog
	for hex: Vector2i in map.hexes():
		var terrain := map.terrain_at(hex)
		if terrain.passable:
			_min_step_cost = minf(_min_step_cost, terrain.move_cost)


## The cost of stepping from [param _from] onto its neighbor [param to], or INF if the party can't.
func step_cost(_from: Vector2i, to: Vector2i) -> float:
	var terrain := _map.terrain_at(to)
	if terrain == null or not terrain.passable:
		return INF
	if _fog and not _fog.is_explored(to):
		return INF
	var feature := _map.feature_at(to)
	if feature and feature.blocks_movement:
		return INF
	var poi := _map.poi_at(to)
	if poi and poi.blocks_movement:
		return INF
	return terrain.move_cost + (feature.extra_move_cost if feature else 0.0)


## The cheapest any step on this map can cost; it keeps A* searches optimal.
func min_step_cost() -> float:
	return _min_step_cost if _min_step_cost < INF else 1.0
