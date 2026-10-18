extends SceneTree
## Measures exploration on a large generated map: building the model, a route across the whole map,
## opening the map in ExploreMode (fog included) and, when run with a window, frame times while
## panning. Phase 2's bar: opening in under a second, routes that feel instant, smooth panning.
## [codeblock]
## godot --path . -s res://tools/benchmarks/explore_benchmark.gd              # everything
## godot --headless --path . -s res://tools/benchmarks/explore_benchmark.gd   # skip panning
## [/codeblock]
## ExploreMode and the autoloads are only reached at runtime: this script compiles before they exist,
## and the work starts on the second frame, once the autoloads are ready.

const MAP_SIZE := Vector2i(200, 150)
const PAN_FRAMES := 300

var _camera: Camera2D
var _pan_from := Vector2.ZERO
var _pan_to := Vector2.ZERO
var _frame := 0
var _pan_frame := 0
var _frame_times := PackedFloat64Array()


func _process(delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_measure_loading()
	elif _camera:
		_pan(delta)
	return false


func _measure_loading() -> void:
	var scene := _make_map()
	var registry: ContentRegistry = root.get_node("ContentDB").get("registry")

	var started := Time.get_ticks_usec()
	var map := ExploreMapBuilder.new(registry).build(scene, &"benchmark")
	_report("build the model of %d hexes" % map.hexes().size(), started)

	var west := Hex.from_offset(Vector2i(2, MAP_SIZE.y / 2))
	var east := Hex.from_offset(Vector2i(MAP_SIZE.x - 3, MAP_SIZE.y / 2))
	var exploration := Exploration.new(GameSession.new(), map, west, false)
	started = Time.get_ticks_usec()
	var route := exploration.route_to(east)
	_report("route across the whole map (%d hexes)" % route.size(), started)
	# Players can only click hexes on screen, so this is the realistic case.
	var screen_away := Hex.from_offset(Vector2i(2 + 25, MAP_SIZE.y / 2))
	started = Time.get_ticks_usec()
	route = exploration.route_to(screen_away)
	_report("route across one screen (%d hexes)" % route.size(), started)

	var mode := (load("res://explore/view/explore_mode.tscn") as PackedScene).instantiate()
	mode.set("map_id", &"")
	root.add_child(mode)
	mode.set_process_unhandled_input(false)
	var map_def := MapDef.new()
	map_def.id = &"benchmark"
	map_def.display_name = "Benchmark"
	started = Time.get_ticks_usec()
	mode.call("explore", map_def, scene, &"start")
	_report("open it in ExploreMode with fog of war", started)

	if DisplayServer.get_name() == "headless":
		quit()
		return
	# Pan across the explored map's full width with fog turned off, so every tile is on screen.
	(mode.get_node("Fog") as CanvasItem).hide()
	_camera = mode.get_node("MapCamera")
	_camera.set("target", null)
	var layout := HexLayout.new()
	_pan_from = layout.to_pixel(west)
	_pan_to = layout.to_pixel(east)


func _pan(delta: float) -> void:
	_pan_frame += 1
	if _pan_frame > 10:
		_frame_times.append(delta * 1000.0)
	_camera.global_position = _pan_from.lerp(_pan_to, float(_pan_frame) / PAN_FRAMES)
	if _pan_frame >= PAN_FRAMES:
		var worst := 0.0
		var total := 0.0
		for ms: float in _frame_times:
			worst = maxf(worst, ms)
			total += ms
		print("pan across the map: %d frames, average %.1f ms, worst %.1f ms (%.0f fps)" % [
			_frame_times.size(), total / _frame_times.size(), worst, 1000.0 * _frame_times.size() / total])
		quit()


## A MAP_SIZE map painted from noise with the overworld tiles, and a "start" entry in the middle.
func _make_map() -> ExploreMapScene:
	var tile_set: TileSet = load("res://assets/tilesets/overworld_tileset.tres")
	var scene := ExploreMapScene.new()
	for layer_name: String in ["Terrain", "Features", "Regions"]:
		var layer := TileMapLayer.new()
		layer.name = layer_name
		layer.tile_set = tile_set
		scene.add_child(layer)
	scene.terrain = scene.get_node("Terrain")
	scene.features = scene.get_node("Features")
	scene.features.y_sort_enabled = true
	scene.regions = scene.get_node("Regions")
	scene.markers = Node2D.new()
	scene.add_child(scene.markers)
	var noise := FastNoiseLite.new()
	noise.seed = 3
	noise.frequency = 0.05
	var rng := SeededRng.new(3)
	for col: int in MAP_SIZE.x:
		for row: int in MAP_SIZE.y:
			var hex := Hex.from_offset(Vector2i(col, row))
			var value := noise.get_noise_2d(col, row)
			var terrain_row := 4 if value < -0.35 else (2 if value > 0.3 else 0)
			scene.terrain.set_cell(hex, 0, Vector2i(rng.randi_range(0, 3), terrain_row))
			if terrain_row == 0 and rng.chance(0.3):
				scene.features.set_cell(hex, 1, Vector2i(rng.randi_range(0, 1), rng.randi_range(0, 1)))
			scene.regions.set_cell(hex, 2, Vector2i(col * 3 / MAP_SIZE.x, 0))
	var start := Hex.from_offset(MAP_SIZE / 2)
	scene.terrain.set_cell(start, 0, Vector2i(0, 0))
	scene.features.erase_cell(start)
	var entry := EntryMarker.new()
	entry.position = scene.terrain.map_to_local(start)
	scene.markers.add_child(entry)
	return scene


func _report(what: String, started_usec: int) -> void:
	print("%-45s %7.1f ms" % [what, (Time.get_ticks_usec() - started_usec) / 1000.0])
