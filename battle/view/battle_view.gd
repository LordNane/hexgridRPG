class_name BattleView extends Node2D
## Draws a battle in 2.5D and plays its events: a CellView per hex and a UnitView per unit, drawn
## back to front, plus range highlights, the cursor and floating damage numbers. The model has
## already changed when [method play] runs; this only shows it.
##
## Each kind of BattleEvent has one handler in [member _handlers]. To animate a new kind of event,
## add one there.

const MOVE_COLOR := Color(0.35, 0.65, 1.0, 0.4)
const TARGET_COLOR := Color(1.0, 0.42, 0.3, 0.42)
const STEP_SECONDS := 0.16
const LUNGE_SECONDS := 0.1
const POPUP_SECONDS := 0.7
const THEME := preload("res://ui/theme/pixel_theme.tres")

## When on, events show their end state at once, without animating. For tests.
var instant := false
var projection: BattleProjection

var _battle: Battle
var _world := Node2D.new()
var _overlay := Node2D.new()
var _cursor := BattleCursor.new()
var _cells: Dictionary[Vector2i, CellView] = {}
var _units: Dictionary[BattleUnit, UnitView] = {}
var _picker: CellPicker
var _handlers: Dictionary[Script, Callable] = {}


func _init() -> void:
	_world.name = "World"
	_world.y_sort_enabled = true
	add_child(_world)
	_overlay.name = "Overlay"
	_overlay.z_index = 50
	add_child(_overlay)
	_cursor.hide()
	_overlay.add_child(_cursor)
	_handlers = {
		UnitMovedEvent: _play_moved,
		UnitTurnedEvent: _play_turned,
		AbilityUsedEvent: _play_ability,
		UnitDamagedEvent: _play_damaged,
		UnitDefeatedEvent: _play_defeated,
	}


## Draws [param battle] on [param arena]'s painted tiles. The arena must be in the scene tree.
func setup(arena: BattleArena, battle: Battle) -> void:
	_battle = battle
	var layout := HexLayout.new()
	layout.cell_size = arena.terrain.tile_set.tile_size
	projection = BattleProjection.new(layout)
	for hex: Vector2i in battle.map.hexes():
		var cell := CellView.new()
		cell.setup(projection, hex, arena.terrain, arena.heights, arena.props)
		_world.add_child(cell)
		_cells[hex] = cell
	for unit: BattleUnit in battle.units:
		var view := UnitView.new(unit)
		_world.add_child(view)
		_units[unit] = view
		_place(view, unit.hex)
		view.face(unit.facing)
	_picker = CellPicker.new(battle.map, projection)


## Shows [param events], one after another, and returns once they've played.
func play(events: Array[BattleEvent]) -> void:
	for event: BattleEvent in events:
		var handler: Callable = _handlers.get(event.get_script(), Callable())
		if handler.is_valid():
			@warning_ignore("redundant_await")  # Some handlers animate and some don't.
			await handler.call(event)


## Tints the top of each of [param hexes] with [param color].
func highlight(hexes: Array[Vector2i], color: Color) -> void:
	for hex: Vector2i in hexes:
		if _cells.has(hex):
			_cells[hex].highlight = color


func clear_highlights() -> void:
	for cell: CellView in _cells.values():
		cell.highlight = Color.TRANSPARENT


## Puts the cursor on [param hex].
func point_at(hex: Vector2i) -> void:
	_cursor.point_at(projection, hex, _battle.map.height_at(hex))
	_cursor.show()


func hide_cursor() -> void:
	_cursor.hide()


## The node the camera follows: the cursor.
func cursor_node() -> Node2D:
	return _cursor


## The hex under [param point], in this node's coordinates, or CellPicker.NONE.
func hex_at(point: Vector2) -> Vector2i:
	return _picker.pick(point)


## The area the map covers on screen, for the camera's limits.
func bounds() -> Rect2:
	var area := Rect2(projection.project(_battle.map.hexes()[0]), Vector2.ZERO)
	for hex: Vector2i in _battle.map.hexes():
		for corner: Vector2 in projection.silhouette(hex, _battle.map.height_at(hex)):
			area = area.expand(corner)
	return area.grow(24.0)


func unit_view(unit: BattleUnit) -> UnitView:
	return _units[unit]


func _place(view: UnitView, hex: Vector2i) -> void:
	view.position = projection.project(hex)
	view.lift = -projection.layout.elevation_offset(_battle.map.height_at(hex)).y


func _play_moved(event: UnitMovedEvent) -> void:
	var view := _units[event.unit]
	for i: int in range(1, event.path.size()):
		var hex := event.path[i]
		view.face(Hex.direction_to(event.path[i - 1], hex))
		if instant:
			continue
		var tween := create_tween().set_parallel()
		tween.tween_property(view, "position", projection.project(hex), STEP_SECONDS)
		var lift := -projection.layout.elevation_offset(_battle.map.height_at(hex)).y
		tween.tween_property(view, "lift", lift, STEP_SECONDS)
		await tween.finished
	_place(view, event.path[-1])
	view.face(event.unit.facing)


func _play_turned(event: UnitTurnedEvent) -> void:
	_units[event.unit].face(event.facing)


func _play_ability(event: AbilityUsedEvent) -> void:
	var view := _units[event.user]
	view.face(event.user.facing)
	if instant or event.target == event.user.hex:
		return
	var toward := (projection.project(event.target) - projection.project(event.user.hex)).normalized() * 6.0
	var tween := create_tween()
	tween.tween_property(view.sprite(), "position", view.sprite().position + toward, LUNGE_SECONDS)
	tween.tween_property(view.sprite(), "position", view.sprite().position, LUNGE_SECONDS)
	await tween.finished


func _play_damaged(event: UnitDamagedEvent) -> void:
	var view := _units[event.unit]
	view.refresh()
	if instant:
		return
	_popup(str(event.amount), view.position + Vector2(0, -view.lift - 26.0), Color(1.0, 0.95, 0.85))
	var tween := create_tween()
	tween.tween_property(view.sprite(), "modulate", Color(3, 3, 3), 0.05)
	tween.tween_property(view.sprite(), "modulate", _base_tint(event.unit), 0.15)
	await tween.finished


func _play_defeated(event: UnitDefeatedEvent) -> void:
	var view := _units[event.unit]
	view.refresh()
	var faded := Color(_base_tint(event.unit), 0.3)
	if instant:
		view.sprite().modulate = faded
		return
	var tween := create_tween()
	tween.tween_property(view.sprite(), "modulate", faded, 0.4)
	await tween.finished


## A number floating up from [param at] and fading.
func _popup(text: String, at: Vector2, color: Color) -> void:
	var label := Label.new()
	label.theme = THEME
	label.text = text
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_font_size_override(&"font_size", 16)
	label.position = at - Vector2(12, 8)
	label.size = Vector2(24, 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay.add_child(label)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 12.0, POPUP_SECONDS)
	tween.tween_property(label, "modulate:a", 0.0, POPUP_SECONDS).set_delay(POPUP_SECONDS * 0.5)
	tween.chain().tween_callback(label.queue_free)


func _base_tint(unit: BattleUnit) -> Color:
	return UnitView.ENEMY_TINT if unit.team == BattleUnit.Team.ENEMY else Color.WHITE
