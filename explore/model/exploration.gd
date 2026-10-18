class_name Exploration extends RefCounted
## The rules of exploring one map: where the party is, what it can see, where it can go and what
## each step triggers. ExploreMode animates and presents; this class decides, without any nodes.


## What a single step changed, for the view to present.
class StepOutcome:
	## Hexes whose fog changed.
	var fog_changed: Array[Vector2i] = []
	## The region just entered, or null if the party is still in the same one.
	var entered_region: RegionDef
	## An ON_ENTER POI the party just stepped onto. The walk should stop and run it.
	var triggered_poi: PoiDef
	## A random battle the step ran into. The walk should stop and the battle start.
	var encounter: EncounterDef
	## Hours the step took.
	var hours := 0.0


var session: GameSession
var map: ExploreMap
var map_state: MapState
## Null on maps without fog of war.
var fog: FogOfWar
var movement: ExploreMovement
## Where the party stands on this map: its entry in the session's map stack, moved with every step.
var position: MapPosition
## The hex the party stands on.
var party_hex: Vector2i:
	get:
		return position.hex
var vision_radius: int


## [param at] is where the party stands on [param explore_map], usually [method GameSession.location].
func _init(game_session: GameSession, explore_map: ExploreMap, at: MapPosition, has_fog: bool = true, sight: int = 3) -> void:
	assert(at.map_id == explore_map.id, "The party's position is on %s, not %s." % [at.map_id, explore_map.id])
	session = game_session
	map = explore_map
	map_state = session.world.map_state(map.id)
	if has_fog:
		fog = FogOfWar.new(map, map_state.explored)
	movement = ExploreMovement.new(map, fog)
	vision_radius = sight
	position = at
	look()


## Recomputes what the party sees and returns the hexes whose fog changed.
func look() -> Array[Vector2i]:
	if fog == null:
		return []
	return fog.look_from(party_hex, vision_radius + map.sight_bonus(party_hex))


## Whether the player knows [param hex]: it's on the map and, on fogged maps, has been seen.
func is_known(hex: Vector2i) -> bool:
	return map.has_hex(hex) and (fog == null or fog.is_explored(hex))


## Whether the party can step from its hex onto the neighboring [param hex].
func can_step_to(hex: Vector2i) -> bool:
	return Hex.distance(party_hex, hex) == 1 and movement.step_cost(party_hex, hex) < INF


## The walk toward [param target], starting at the party's hex: onto it, or to the cheapest free
## neighbor when a POI there blocks movement. Empty if it can't be reached.
func route_to(target: Vector2i) -> Array[Vector2i]:
	if not is_known(target):
		return []
	var poi := map.poi_at(target)
	if poi == null or not poi.blocks_movement:
		return HexPathfinder.find_path(party_hex, target, movement.step_cost, movement.min_step_cost())
	if Hex.distance(party_hex, target) == 1:
		var here: Array[Vector2i] = [party_hex]
		return here
	var best: Array[Vector2i] = []
	for neighbor: Vector2i in Hex.neighbors(target):
		var path := HexPathfinder.find_path(party_hex, neighbor, movement.step_cost, movement.min_step_cost())
		if not path.is_empty() and (best.is_empty() or route_hours(path) < route_hours(best)):
			best = path
	return best


## How many hours walking [param route] takes. Its first hex is where the walk starts.
func route_hours(route: Array[Vector2i]) -> float:
	var total := 0.0
	for i: int in range(1, route.size()):
		total += movement.step_cost(route[i - 1], route[i])
	return total


## Moves the party onto the neighboring [param hex] and applies what the step triggers.
func step_to(hex: Vector2i) -> StepOutcome:
	assert(can_step_to(hex), "Can't step from %s to %s" % [party_hex, hex])
	var outcome := StepOutcome.new()
	var previous_region := map.region_at(party_hex)
	outcome.hours = movement.step_cost(party_hex, hex)
	session.advance_time(outcome.hours)
	position.hex = hex
	outcome.fog_changed = look()
	var region := map.region_at(hex)
	if region and region != previous_region:
		outcome.entered_region = region
	var poi := map.poi_at(hex)
	if poi and poi.trigger == PoiDef.Trigger.ON_ENTER and not is_used(hex):
		outcome.triggered_poi = poi
	else:
		outcome.encounter = EncounterRoller.roll(session, region.encounters if region else null)
	return outcome


## An arena for a battle against [param encounter] where the party stands, or "" if there's none.
func arena_for(encounter: EncounterDef) -> String:
	return EncounterRoller.pick_arena(encounter, map.terrain_at(party_hex), map.feature_at(party_hex), session.rng)


## The POI to interact with at [param target] once the party has walked toward it (or pressed
## confirm): one on the party's own hex, or a movement-blocking one right next to it. Null otherwise.
func poi_to_interact(target: Vector2i) -> PoiDef:
	var poi := map.poi_at(target)
	if poi == null or poi.trigger != PoiDef.Trigger.ON_INTERACT or is_used(target):
		return null
	var in_reach := target == party_hex or (poi.blocks_movement and Hex.distance(party_hex, target) == 1)
	return poi if in_reach else null


## Whether the one-time POI on [param hex] has been used up.
func is_used(hex: Vector2i) -> bool:
	var poi := map.poi_at(hex)
	return poi != null and poi.once and map_state.is_used(hex)
