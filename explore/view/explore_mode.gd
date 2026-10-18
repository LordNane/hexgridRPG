class_name ExploreMode extends Node2D
## Plays an exploration map: loads its scene, builds its rules (an Exploration) and turns clicks
## and keys into walks and POI visits. The rules decide; this node animates and presents.
##
## Click a hex to walk there; arrow keys step one hex; confirm interacts with a POI where the party
## stands; cancel stops a walk. Fog hides the terrain, features and POIs the party hasn't seen.

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

## The MapDef to explore when the scene starts. Phase 3's mode router will choose it instead.
@export var map_id: StringName = &"test_overworld"
## The arrival point to start at.
@export var entry_name: StringName = &"start"

var _exploration: Exploration
var _map_scene: ExploreMapScene
var _layout: HexLayout
var _poi_host: HudPoiHost
var _markers: Dictionary[Vector2i, PoiMarker] = {}
## Feature tiles hidden until their hex is explored: hex → [source id, atlas coords, alternative].
var _hidden_features: Dictionary[Vector2i, Array] = {}
var _hovered := Vector2i.MAX
## While the party walks or a POI runs, other input waits.
var _busy := false
## An ON_ENTER POI the last walk stopped on, to run once the walk ends.
var _triggered_poi: PoiDef
var _triggered_hex: Vector2i

@onready var _world: Node2D = $World
@onready var _token: PartyToken = $World/PartyToken
@onready var _overlay: ExploreOverlay = $Overlay
@onready var _fog: TileMapLayer = $Fog
@onready var _camera: MapCamera = $MapCamera
@onready var _hud: ExploreHud = $Hud


func _ready() -> void:
	if map_id.is_empty():
		return
	var map_def := ContentDB.get_def(map_id) as MapDef
	assert(map_def != null, "No MapDef with id \"%s\"." % map_id)
	explore(map_def, (load(map_def.scene) as PackedScene).instantiate() as ExploreMapScene, entry_name)


## Starts exploring [param map_def] using [param scene], its instantiated map scene, with the party
## at the arrival point named [param entry].
func explore(map_def: MapDef, scene: ExploreMapScene, entry: StringName) -> void:
	_map_scene = scene
	_world.add_child(scene)
	_world.move_child(scene, 0)
	scene.terrain.z_index = Z_TERRAIN
	var builder := ExploreMapBuilder.new(ContentDB.registry)
	var map := builder.build(scene, map_def.id)
	for problem: String in builder.problems:
		push_warning("%s: %s" % [map_def.id, problem])
	assert(map.has_entry(entry), "%s has no entry named \"%s\"." % [map_def.id, entry])

	_layout = _layout_matching(scene.terrain)
	_exploration = Exploration.new(Game.session, map, map.entry(entry), map_def.fog_of_war, map_def.vision_radius)
	_poi_host = HudPoiHost.new(_hud)
	_token.place(_layout, _exploration.party_hex)
	_token.stepped.connect(_on_token_stepped)
	_overlay.setup(_layout)
	_overlay.z_index = Z_OVERLAY
	_camera.target = _token
	_camera.set_bounds(_map_bounds(map))
	for marker: HexMarker in HexMarker.find_all(scene.markers):
		if marker is PoiMarker:
			var hex := marker.hex_on(scene.terrain)
			_markers[hex] = marker
			(marker as PoiMarker).used = _exploration.is_used(hex)
	_setup_fog()
	_update_status()
	_update_inventory()
	Game.session.inventory.changed.connect(func(_item_id: StringName, _count: int) -> void: _update_inventory())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cancel") and _token.is_walking:
		_token.stop()
		return
	if _busy or _exploration == null:
		return
	var click := event as InputEventMouseButton
	if event is InputEventMouseMotion:
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
	await PoiRunner.run(poi, PoiContext.new(Game.session, _exploration.map_state, hex, _poi_host))
	if _markers.has(hex):
		_markers[hex].used = _exploration.is_used(hex)
	_busy = false


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
	var session := Game.session
	var region := _exploration.map.region_at(_exploration.party_hex)
	var place := ("  ·  " + region.display_name) if region else ""
	_hud.show_status("Day %d  %02d:00%s" % [session.day(), session.hour_of_day(), place])


func _update_inventory() -> void:
	var inventory := Game.session.inventory
	var lines := PackedStringArray()
	for item_id: StringName in inventory.item_ids():
		var item := ContentDB.get_def(item_id)
		lines.append("%s ×%d" % [item.display_name if item else String(item_id), inventory.count_of(item_id)])
	_hud.show_inventory("\n".join(lines))


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
