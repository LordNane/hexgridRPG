class_name ExploreMode extends Node2D
## Plays an exploration map: loads its scene, builds its rules (an Exploration) and turns clicks
## and keys into walks and POI visits. The rules decide; this node animates and presents. Make one
## with [method arriving] or [method resuming] and push it onto the ModeRouter.
##
## Click a hex to walk there; arrow keys step one hex; confirm interacts with a POI where the party
## stands; cancel stops a walk; the menu button opens the party menu. Fog hides the terrain,
## features and POIs the party hasn't seen.

const SCENE_PATH := "res://explore/view/explore_mode.tscn"

## Draw order: painted ground; then features, POIs and the party, sorted by row; then the route
## overlay; then fog.
const Z_TERRAIN := -10
const Z_OVERLAY := 5
const Z_FOG := 10

## Fog tiles in fog_tileset.tres.
const FOG_SOURCE := 0
const FOG_UNEXPLORED := Vector2i(0, 0)
const FOG_REMEMBERED := Vector2i(1, 0)

const CURSOR_ACTIONS: Dictionary[StringName, Vector2] = {
	&"cursor_up": Vector2.UP,
	&"cursor_down": Vector2.DOWN,
	&"cursor_left": Vector2.LEFT,
	&"cursor_right": Vector2.RIGHT,
}

var _session: GameSession
var _map_def: MapDef
## The arrival point the party enters at. Unused when resuming at [member _position].
var _entry: StringName
## The party's entry in the session's map stack; set once it arrives.
var _position: MapPosition
var _map_scene: ExploreMapScene
var _exploration: Exploration
var _layout: HexLayout
var _poi_host: ExplorePoiHost
var _markers: Dictionary[Vector2i, PoiMarker] = {}
## Feature tiles hidden until their hex is explored: hex → [source id, atlas coords, alternative].
var _hidden_features: Dictionary[Vector2i, Array] = {}
var _hovered := Vector2i.MAX
## While the party walks or a POI runs, other input waits.
var _busy := false
## An ON_ENTER POI the last walk stopped on, to run once the walk ends.
var _triggered_poi: PoiDef
var _triggered_hex: Vector2i
## A random battle the last walk ran into, to fight once the walk ends.
var _encounter: EncounterDef

@onready var _world: Node2D = $World
@onready var _token: PartyToken = $World/PartyToken
@onready var _overlay: ExploreOverlay = $Overlay
@onready var _fog: TileMapLayer = $Fog
@onready var _camera: MapCamera = $MapCamera
@onready var _hud: ExploreHud = $Hud
@onready var _menu: ScreenStack = $Menu


## A mode that brings the party onto [param map_def] at its arrival point [param entry]. Once it's
## ready, the map is on top of the session's map stack. [param scene] is the map's scene, already
## instantiated; by default it's loaded from the MapDef.
static func arriving(session: GameSession, map_def: MapDef, entry: StringName, scene: ExploreMapScene = null) -> ExploreMode:
	var mode := _create(session, map_def, scene)
	mode._entry = entry
	return mode


## A mode that carries on exploring [param map_def] with the party [param at] an entry of the
## session's map stack, such as after loading a save.
static func resuming(session: GameSession, map_def: MapDef, at: MapPosition) -> ExploreMode:
	assert(at.map_id == map_def.id, "The party's position is on %s, not %s." % [at.map_id, map_def.id])
	var mode := _create(session, map_def, null)
	mode._position = at
	return mode


static func _create(session: GameSession, map_def: MapDef, scene: ExploreMapScene) -> ExploreMode:
	var mode := (load(SCENE_PATH) as PackedScene).instantiate() as ExploreMode
	mode._session = session
	mode._map_def = map_def
	mode._map_scene = scene
	return mode


func _ready() -> void:
	if _map_def == null:
		push_warning("ExploreMode has no map to explore. Run the game from game/main.tscn.")
		return
	if _map_scene == null:
		_map_scene = (load(_map_def.scene) as PackedScene).instantiate() as ExploreMapScene
	_explore()


func _enter_tree() -> void:
	# Back from a mode pushed over this one, such as a cave: time has passed meanwhile.
	if _exploration:
		_update_status()


func _explore() -> void:
	_world.add_child(_map_scene)
	_world.move_child(_map_scene, 0)
	_map_scene.terrain.z_index = Z_TERRAIN
	var builder := ExploreMapBuilder.new(ContentDB.registry)
	var map := builder.build(_map_scene, _map_def.id)
	for problem: String in builder.problems:
		push_warning("%s: %s" % [_map_def.id, problem])
	if _position == null:
		assert(map.has_entry(_entry), "%s has no entry named \"%s\"." % [_map_def.id, _entry])
		_position = _session.enter_map(_map_def.id, map.entry(_entry))
		_hud.show_banner(_map_def.display_name)

	_layout = _layout_matching(_map_scene.terrain)
	_exploration = Exploration.new(_session, map, _position, _map_def.fog_of_war, _map_def.vision_radius)
	_poi_host = ExplorePoiHost.new(_hud, _exploration.arena_for)
	_token.place(_layout, _exploration.party_hex)
	_token.stepped.connect(_on_token_stepped)
	_overlay.setup(_layout)
	_overlay.z_index = Z_OVERLAY
	_camera.target = _token
	_camera.set_bounds(_map_bounds(map))
	for marker: HexMarker in HexMarker.find_all(_map_scene.markers):
		if marker is PoiMarker:
			var hex := marker.hex_on(_map_scene.terrain)
			_markers[hex] = marker
			(marker as PoiMarker).used = _exploration.is_used(hex)
	_setup_fog()
	_update_status()
	_update_purse()
	_session.gold_changed.connect(_update_purse.unbind(1))
	_menu.closed.connect(_on_menu_closed)


func _unhandled_input(event: InputEvent) -> void:
	if _menu.is_open():
		return
	if event.is_action_pressed(&"cancel") and _token.is_walking:
		_token.stop()
		return
	if _busy or _exploration == null:
		return
	var click := event as InputEventMouseButton
	if event.is_action_pressed(&"menu"):
		get_viewport().set_input_as_handled()
		_open_menu()
	elif event is InputEventMouseMotion:
		_hover_at(_hex_under_mouse())
	elif click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		_go_to(_hex_under_mouse())
	elif event.is_action_pressed(&"confirm"):
		_interact_at(_exploration.party_hex)
	else:
		for action: StringName in CURSOR_ACTIONS:
			if event.is_action_pressed(action, true):
				_step_toward(CURSOR_ACTIONS[action])
				return


## Walks to [param target], then interacts with whatever is there.
func _go_to(target: Vector2i) -> void:
	var route := _exploration.route_to(target)
	if route.is_empty():
		return
	_busy = true
	_overlay.clear()
	_camera.recenter()
	await _token.walk(route)
	if _triggered_poi:
		var poi := _triggered_poi
		_triggered_poi = null
		await _run_poi(poi, _triggered_hex)
	elif _encounter:
		var encounter := _encounter
		_encounter = null
		await _poi_host.start_battle(encounter)
	elif _token.hex == route[-1]:
		await _interact_at(target)
	_busy = false
	_hovered = Vector2i.MAX
	_hover_at(_hex_under_mouse())


## Steps one hex in a screen direction, or talks to a blocking POI standing there.
func _step_toward(screen_dir: Vector2) -> void:
	var next := _layout.neighbor_toward(_exploration.party_hex, screen_dir)
	if _exploration.poi_to_interact(next):
		_interact_at(next)
	elif _exploration.can_step_to(next):
		_go_to(next)


func _interact_at(target: Vector2i) -> void:
	var poi := _exploration.poi_to_interact(target)
	if poi:
		await _run_poi(poi, target)


func _run_poi(poi: PoiDef, hex: Vector2i) -> void:
	_busy = true
	_overlay.clear()
	await PoiRunner.run(poi, PoiContext.new(_session, _exploration.map_state, hex, _poi_host))
	if _markers.has(hex):
		_markers[hex].used = _exploration.is_used(hex)
	_busy = false
	if _poi_host.exit_requested:
		_poi_host.exit_requested = false
		# Deferred, so the walk or keypress that ran the POI wraps up before this mode is popped.
		# The router ignores input from then on.
		Game.exit_map.call_deferred()


## Opens the party menu over the map, which waits, camera and all, until it closes.
func _open_menu() -> void:
	_overlay.clear()
	_hud.show_hex_info("")
	_hovered = Vector2i.MAX
	_camera.process_mode = Node.PROCESS_MODE_DISABLED
	_menu.push(PartyScreen.new(_session, ContentDB.registry))


func _on_menu_closed() -> void:
	_camera.process_mode = Node.PROCESS_MODE_INHERIT
	_hover_at(_hex_under_mouse())


func _on_token_stepped(hex: Vector2i) -> void:
	var outcome := _exploration.step_to(hex)
	for changed: Vector2i in outcome.fog_changed:
		_update_fog_at(changed)
	if outcome.entered_region:
		_hud.show_banner(outcome.entered_region.display_name)
	if outcome.triggered_poi:
		_triggered_poi = outcome.triggered_poi
		_triggered_hex = hex
		_token.stop()
	elif outcome.encounter:
		_encounter = outcome.encounter
		_token.stop()
	_update_status()


func _hover_at(hex: Vector2i) -> void:
	if hex == _hovered:
		return
	_hovered = hex
	if not _exploration.is_known(hex):
		_overlay.clear()
		_hud.show_hex_info("")
		return
	var route: Array[Vector2i] = []
	if hex != _exploration.party_hex:
		route = _exploration.route_to(hex)
	_overlay.show_hover(hex, route)
	_hud.show_hex_info(_describe(hex, route))


func _describe(hex: Vector2i, route: Array[Vector2i]) -> String:
	var map := _exploration.map
	var terrain := map.terrain_at(hex)
	var feature := map.feature_at(hex)
	var poi := map.poi_at(hex)
	var lines := PackedStringArray()
	if poi:
		lines.append(poi.display_name + (" (empty)" if _exploration.is_used(hex) else ""))
	lines.append(terrain.display_name if feature == null else "%s on %s" % [feature.display_name, terrain.display_name])
	if hex == _exploration.party_hex:
		lines.append("You are here")
	elif route.is_empty():
		lines.append("Can't get there")
	else:
		lines.append("%d h away" % ceili(_exploration.route_hours(route)))
	return "\n".join(lines)


func _update_status() -> void:
	var region := _exploration.map.region_at(_exploration.party_hex)
	var place := region.display_name if region else _map_def.display_name
	_hud.show_status("Day %d  %02d:00  ·  %s" % [_session.day(), _session.hour_of_day(), place])


func _update_purse() -> void:
	_hud.show_purse("%d gold\nTab: party" % _session.gold)


func _setup_fog() -> void:
	_fog.z_index = Z_FOG
	_fog.global_position = _map_scene.terrain.global_position
	if _exploration.fog == null:
		_fog.hide()
		return
	var features := _map_scene.features
	for hex: Vector2i in _exploration.map.hexes():
		if features and features.get_cell_source_id(hex) != -1 and not _exploration.fog.is_explored(hex):
			_hidden_features[hex] = [features.get_cell_source_id(hex), features.get_cell_atlas_coords(hex),
				features.get_cell_alternative_tile(hex)]
			features.erase_cell(hex)
		_update_fog_at(hex)


## Redraws the fog on [param hex] and reveals what's there once the party has seen it.
func _update_fog_at(hex: Vector2i) -> void:
	var fog := _exploration.fog
	if fog.is_visible(hex):
		_fog.erase_cell(hex)
	elif fog.is_explored(hex):
		_fog.set_cell(hex, FOG_SOURCE, FOG_REMEMBERED)
	else:
		_fog.set_cell(hex, FOG_SOURCE, FOG_UNEXPLORED)
	var explored := fog.is_explored(hex)
	if explored and _hidden_features.has(hex):
		var tile: Array = _hidden_features[hex]
		_map_scene.features.set_cell(hex, tile[0], tile[1], tile[2])
		_hidden_features.erase(hex)
	if _markers.has(hex):
		_markers[hex].visible = explored


func _hex_under_mouse() -> Vector2i:
	return _layout.to_hex(get_local_mouse_position())


## A HexLayout that agrees with [param tiles]' grid, in this node's coordinates.
func _layout_matching(tiles: TileMapLayer) -> HexLayout:
	var layout := HexLayout.new()
	layout.cell_size = tiles.tile_set.tile_size
	layout.origin = to_local(tiles.to_global(tiles.map_to_local(Vector2i.ZERO)))
	return layout


## The map's extent in pixels: every hex center, plus half a hex all around.
func _map_bounds(map: ExploreMap) -> Rect2:
	var hexes := map.hexes()
	var bounds := Rect2(_layout.to_pixel(hexes[0]), Vector2.ZERO)
	for hex: Vector2i in hexes:
		bounds = bounds.expand(_layout.to_pixel(hex))
	var half := Vector2(_layout.cell_size) / 2.0
	return bounds.grow_individual(half.x, half.y, half.x, half.y)
