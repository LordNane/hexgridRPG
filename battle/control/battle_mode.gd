class_name BattleMode extends Node2D
## Plays a battle: builds it from a BattleRequest (the arena, both sides and a seed), runs its turns
## through a state machine and presents them. The rules (Battle) decide; this node turns input into
## actions and plays their events. When the battle ends, [signal finished] hands back the result.
##
## Each turn: TurnStart → Command → SelectMove or SelectTarget → Resolve → back to Command, until
## Facing ends the turn with a WaitAction. Enemies (and the party, with [member party_ai]) take
## AiTurn instead. End shows the result.

## Emitted once the player has seen how the battle ended.
signal finished(result: BattleResult)

const CURSOR_ACTIONS: Dictionary[StringName, Vector2] = {
	&"cursor_up": Vector2.UP,
	&"cursor_down": Vector2.DOWN,
	&"cursor_left": Vector2.LEFT,
	&"cursor_right": Vector2.RIGHT,
}

## Whether the AI plays the party too, so the battle plays itself.
var party_ai := false
## Whether events show at once without animating, and the AI acts a frame apart instead of
## pausing. For tests.
var instant := false
var request: BattleRequest
var battle: Battle
var view := BattleView.new()
var hud := BattleHud.new()
var camera := MapCamera.new()
## The hex under the cursor.
var cursor := Vector2i.ZERO

var _machine := StateMachine.new()


static func create(battle_request: BattleRequest) -> BattleMode:
	var mode := BattleMode.new()
	mode.request = battle_request
	return mode


func _ready() -> void:
	var arena := (load(request.arena) as PackedScene).instantiate() as BattleArena
	arena.hide()
	add_child(arena)
	var builder := BattleMapBuilder.new(ContentDB.registry)
	var map := builder.build(arena)
	for problem: String in builder.problems:
		push_warning("%s: %s" % [request.arena, problem])
	battle = Battle.new(map, _units_for(map), SeededRng.new(request.rng_seed))
	view.instant = instant
	add_child(view)
	view.setup(arena, battle)
	camera.target = view.cursor_node()
	add_child(camera)
	camera.set_bounds(view.bounds())
	add_child(hud)
	var states: Dictionary[StringName, BattleState] = {
		&"start": StartState.new(), &"turn_start": TurnStartState.new(), &"command": CommandState.new(),
		&"select_move": SelectMoveState.new(), &"select_target": SelectTargetState.new(),
		&"resolve": ResolveState.new(), &"facing": FacingState.new(), &"ai_turn": AiTurnState.new(),
		&"end": EndState.new(),
	}
	for state_name: StringName in states:
		states[state_name].mode = self
		_machine.add(state_name, states[state_name])
	# Deferred, so whoever added this mode can listen for the battle's end before it starts.
	_machine.transition_to.call_deferred(&"start")


func _unhandled_input(event: InputEvent) -> void:
	_machine.handle_input(event)


## Whether the AI decides [param unit]'s turns.
func ai_controls(unit: BattleUnit) -> bool:
	return unit.team == BattleUnit.Team.ENEMY or party_ai


## Puts the cursor on [param hex] and shows the unit there, if it isn't the active one.
func set_cursor(hex: Vector2i) -> void:
	cursor = hex
	view.point_at(hex)
	var unit := battle.unit_at(hex)
	hud.show_target(unit if unit != battle.active else null)


## Moves the cursor for arrow keys and mouse movement. Returns whether [param event] did.
func move_cursor(event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		var hex := view.hex_at(view.get_local_mouse_position())
		if hex != CellPicker.NONE and hex != cursor:
			set_cursor(hex)
		return true
	for action: StringName in CURSOR_ACTIONS:
		if event.is_action_pressed(action, true):
			var next := view.projection.layout.neighbor_toward(cursor, CURSOR_ACTIONS[action])
			if battle.map.has_hex(next):
				set_cursor(next)
			return true
	return false


## Whether [param event] confirms the cursor's hex: the confirm button, or a click on a hex (which
## moves the cursor there first).
func confirms(event: InputEvent) -> bool:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		var hex := view.hex_at(view.get_local_mouse_position())
		if hex == CellPicker.NONE:
			return false
		set_cursor(hex)
		return true
	return event.is_action_pressed(&"confirm")


## Plays [param events] and brings the HUD up to date.
func play(events: Array[BattleEvent]) -> void:
	await view.play(events)
	hud.refresh_cards()
	hud.show_turn_order(battle.turn_order(BattleHud.TURNS_SHOWN))


## Hands [param result] back to whoever started the battle.
func finish(result: BattleResult) -> void:
	finished.emit(result)


## Waits [param seconds], or just a frame when [member instant]. Either way the battle moves on from
## a fresh frame, so a battle the AI plays never runs in one go.
func pause(seconds: float) -> void:
	if instant:
		await get_tree().process_frame
	else:
		await get_tree().create_timer(seconds).timeout


## The battle's units: the party's members on the party spawns and the encounter's enemies on the
## enemy spawns, as many as there are spawns for.
func _units_for(map: BattleMap) -> Array[BattleUnit]:
	var units: Array[BattleUnit] = []
	for i: int in mini(request.party.size(), map.party_spawns.size()):
		var spawn := map.party_spawns[i]
		units.append(BattleUnit.new(request.party[i], BattleUnit.Team.PARTY, spawn.hex, spawn.facing))
	var enemies := request.encounter.enemies
	for i: int in mini(enemies.size(), map.enemy_spawns.size()):
		var spawn := map.enemy_spawns[i]
		var fighter := Character.from_def(enemies[i], ContentDB.registry)
		units.append(BattleUnit.new(fighter, BattleUnit.Team.ENEMY, spawn.hex, spawn.facing, enemies[i]))
	return units
