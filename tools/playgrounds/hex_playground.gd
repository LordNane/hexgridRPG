extends Node2D
## Dev scene for the hex core: hover hexes and see paths, movement range, rings and lines drawn on
## random terrain. Not part of the game; it exercises Hex, HexLayout and HexPathfinder by hand.
##
## Mouse or arrow keys move the cursor; click or Enter sets the start hex.
## 1 path · 2 reach · 3 ring · 4 line · R new terrain

enum Mode { PATH, REACH, RING, LINE }
enum Terrain { GRASS, FOREST, HILLS, WATER, MOUNTAIN }

const RADIUS := 10
const MOVE_BUDGET := 6.0

## Indexed by Terrain: step cost (INF = impassable), fill color and name.
const TERRAIN_COST: Array[float] = [1.0, 2.0, 3.0, INF, INF]
const TERRAIN_COLOR: Array[Color] = [Color("5a9a4a"), Color("2f6b3a"), Color("9a8a5a"), Color("3a6ab0"), Color("6a6a72")]
const TERRAIN_NAME: Array[String] = ["grass", "forest", "hills", "water", "mountain"]

## Indexed by Mode.
const MODE_NAME: Array[String] = ["path", "reach", "ring", "line"]
const MODE_COLOR: Array[Color] = [Color(1, 0.85, 0.3, 0.6), Color(0.35, 0.65, 1, 0.5), Color(0.95, 0.45, 0.95, 0.6), Color(0.35, 0.95, 0.95, 0.6)]

const OUTLINE_COLOR := Color(0, 0, 0, 0.3)
const START_COLOR := Color("ffd84a")
const CURSOR_COLOR := Color.WHITE

const CURSOR_ACTIONS: Dictionary[StringName, Vector2] = {
	&"cursor_up": Vector2.UP,
	&"cursor_down": Vector2.DOWN,
	&"cursor_left": Vector2.LEFT,
	&"cursor_right": Vector2.RIGHT,
}

var _layout := HexLayout.new()
var _rng := SeededRng.new(7)
var _terrain: Dictionary[Vector2i, int] = {}
var _mode := Mode.PATH
var _start := Vector2i.ZERO
var _cursor := Vector2i(5, -3)
var _highlight: Array[Vector2i] = []

@onready var _info: Label = $Hud/Info


func _ready() -> void:
	_layout.origin = (get_viewport_rect().size / 2).floor()
	_generate_terrain()


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if event is InputEventMouseMotion:
		_move_cursor(_layout.to_hex(get_local_mouse_position()))
	elif click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		_set_start(_layout.to_hex(get_local_mouse_position()))
	elif event.is_action_pressed(&"confirm"):
		_set_start(_cursor)
	else:
		for action: StringName in CURSOR_ACTIONS:
			if event.is_action_pressed(action, true):
				_move_cursor(_layout.neighbor_toward(_cursor, CURSOR_ACTIONS[action]))
				return
		var key := event as InputEventKey
		if key and key.pressed and not key.echo:
			match key.keycode:
				KEY_1, KEY_2, KEY_3, KEY_4:
					_mode = (key.keycode - KEY_1) as Mode
					_refresh()
				KEY_R:
					_generate_terrain()


func _move_cursor(hex: Vector2i) -> void:
	if hex != _cursor and _terrain.has(hex):
		_cursor = hex
		_refresh()


func _set_start(hex: Vector2i) -> void:
	if _terrain.has(hex):
		_start = hex
		_refresh()


func _generate_terrain() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = _rng.randi_range(0, 1_000_000)
	noise.frequency = 0.006
	_terrain.clear()
	for hex: Vector2i in Hex.disc(Vector2i.ZERO, RADIUS):
		_terrain[hex] = _terrain_for(noise.get_noise_2dv(_layout.to_pixel(hex)))
	_terrain[_start] = Terrain.GRASS
	_refresh()


func _terrain_for(noise_value: float) -> Terrain:
	if noise_value < -0.25:
		return Terrain.WATER
	if noise_value < 0.12:
		return Terrain.GRASS
	if noise_value < 0.28:
		return Terrain.FOREST
	if noise_value < 0.4:
		return Terrain.HILLS
	return Terrain.MOUNTAIN


func _step_cost(_from: Vector2i, to: Vector2i) -> float:
	return TERRAIN_COST[_terrain[to]] if _terrain.has(to) else INF


func _refresh() -> void:
	var detail := ""
	match _mode:
		Mode.PATH:
			_highlight = HexPathfinder.find_path(_start, _cursor, _step_cost)
			detail = "no path" if _highlight.is_empty() else "path cost %s" % _path_cost(_highlight)
		Mode.REACH:
			var reach := HexPathfinder.reachable(_start, MOVE_BUDGET, _step_cost)
			_highlight = reach.hexes()
			detail = "%d hexes within %s; cursor costs %s" % [_highlight.size(), MOVE_BUDGET, reach.cost_to(_cursor)]
		Mode.RING:
			_highlight = Hex.ring(_start, Hex.distance(_start, _cursor))
			detail = "radius %d" % Hex.distance(_start, _cursor)
		Mode.LINE:
			_highlight = Hex.line(_start, _cursor)
			detail = "%d hexes, facing %s" % [_highlight.size(), _direction_name(Hex.direction_to(_start, _cursor))]
	var terrain: int = _terrain[_cursor]
	_info.text = "1 path  2 reach  3 ring  4 line  R new map  |  click/Enter sets start\n%s: %s  |  %s %s, step cost %s" % [
		MODE_NAME[_mode], detail, _cursor, TERRAIN_NAME[terrain], TERRAIN_COST[terrain]]
	queue_redraw()


func _draw() -> void:
	for hex: Vector2i in _terrain:
		draw_colored_polygon(_layout.corners(hex), TERRAIN_COLOR[_terrain[hex]])
	for hex: Vector2i in _highlight:
		draw_colored_polygon(_layout.corners(hex), MODE_COLOR[_mode])
	for hex: Vector2i in _terrain:
		_draw_outline(hex, OUTLINE_COLOR)
	_draw_outline(_start, START_COLOR)
	_draw_outline(_cursor, CURSOR_COLOR)


func _draw_outline(hex: Vector2i, color: Color) -> void:
	var points := _layout.corners(hex)
	points.append(points[0])
	draw_polyline(points, color)


func _path_cost(path: Array[Vector2i]) -> float:
	var total := 0.0
	for i: int in range(1, path.size()):
		total += _step_cost(path[i - 1], path[i])
	return total


func _direction_name(dir: int) -> String:
	return "-" if dir < 0 else Hex.Dir.keys()[dir]
