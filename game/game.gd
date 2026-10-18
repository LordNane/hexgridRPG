extends Node
## Autoload "Game": the global entry point. Starts and continues playthroughs, autosaves them, and
## moves the party between maps and into battles through the ModeRouter.
##
## Systems should receive the session as a parameter where practical rather than reaching for this
## autoload, so tests can build their own.

## Where a new game begins.
const START_MAP := &"test_overworld"
const START_ENTRY := &"start"
## Who a new game begins with, as CharacterDef ids, and what they carry besides their gear.
const START_PARTY: Array[StringName] = [&"alden", &"brin", &"cass", &"dara"]
const START_ITEMS: Dictionary[StringName, int] = {&"potion": 3, &"iron_sword": 1, &"dagger": 1, &"sprint_shoes": 1}
## The save slot written whenever the party changes maps.
const AUTOSAVE_SLOT := "autosave"

## The playthrough in progress, or null on the title screen.
var session: GameSession
## The game's mode stack, handed over by the main scene in [method start].
var router: ModeRouter
var saves := SaveService.new(SaveService.DEFAULT_DIR, migrations())
## When on, battles play themselves at once, the AI fighting for the party too. For tests.
var autoplay_battles := false


## Takes over [param mode_router] and shows the title screen. The main scene calls this once.
func start(mode_router: ModeRouter) -> void:
	router = mode_router
	show_title()


func show_title() -> void:
	session = null
	var title := TitleScreen.create(not saves.slots().is_empty())
	title.new_game_chosen.connect(new_game)
	title.continue_chosen.connect(continue_game)
	router.switch_to([title])


## Starts a new playthrough with the starting party, at the start of the first map.
func new_game() -> void:
	session = GameSession.new(int(Time.get_unix_time_from_system()))
	session.party = starting_party()
	for item_id: StringName in START_ITEMS:
		session.inventory.add(item_id, START_ITEMS[item_id])
	router.switch_to([_arrive(ContentDB.get_def(START_MAP) as MapDef, START_ENTRY)])


## Loads the latest save and puts the party back where it was, with each map it came through
## waiting below.
func continue_game() -> void:
	var slots := saves.slots()
	if slots.is_empty():
		return
	var loaded := GameSession.from_dict(saves.read(slots[0]), ContentDB.registry)
	if loaded.map_stack.is_empty():
		push_error("The save in \"%s\" doesn't say where the party is." % slots[0])
		return
	for at: MapPosition in loaded.map_stack:
		if not (ContentDB.get_def(at.map_id) is MapDef):
			push_error("The save in \"%s\" is on \"%s\", which isn't a map." % [slots[0], at.map_id])
			return
	session = loaded
	var modes: Array[Node] = []
	for at: MapPosition in session.map_stack:
		modes.append(ExploreMode.resuming(session, ContentDB.get_def(at.map_id) as MapDef, at))
	router.switch_to(modes)


## Takes the party into [param map_def] at its arrival point [param entry]. Returns once the party
## has left that map again.
func enter_map(map_def: MapDef, entry: StringName) -> void:
	await router.push(_arrive(map_def, entry))


## Takes the party back to the map it entered the current one from, on the hex it entered from.
func exit_map() -> void:
	if session.map_stack.size() < 2:
		push_error("Nowhere to exit to: %s is the bottom map." % session.location().map_id)
		return
	session.leave_map()
	await router.pop()
	autosave()


## Fights [param encounter] with the party, in the arena scene [param arena]. Returns once the battle
## is won, with the loot added, the party restored and the game autosaved. Losing ends the game:
## the title screen comes back, and this never returns.
func start_battle(encounter: EncounterDef, arena: String) -> BattleResult:
	var request := BattleRequest.new(arena, session.party.members(), encounter, session.rng.randi_range(0, 0x7FFFFFFF))
	var mode := BattleMode.create(request)
	mode.party_ai = autoplay_battles
	mode.instant = autoplay_battles
	mode.finished.connect(_on_battle_finished, CONNECT_ONE_SHOT)
	var result: BattleResult = await router.push(mode)
	result.apply_to(session)
	EncounterRoller.reset_grace(session)
	autosave()
	return result


func autosave() -> void:
	var error := saves.write(AUTOSAVE_SLOT, session.to_dict())
	if error != OK:
		push_error("Autosave failed: %s." % error_string(error))


## The party every journey starts with, newly made.
func starting_party() -> Party:
	var party := Party.new()
	for id: StringName in START_PARTY:
		party.add(Character.from_def(ContentDB.get_def(id) as CharacterDef, ContentDB.registry))
	return party


## One function per change to the save format, oldest first. See SaveService.
func migrations() -> Array[Callable]:
	return [_add_starting_party]


func _on_battle_finished(result: BattleResult) -> void:
	if result.is_victory():
		router.pop(result)
	else:
		show_title()


## Version 1 to 2: saves from before the party existed get the starting party.
func _add_starting_party(data: Dictionary) -> Dictionary:
	data["party"] = starting_party().to_dict()
	return data


## A mode that brings the party onto [param map_def] at [param entry] and autosaves once it's there.
func _arrive(map_def: MapDef, entry: StringName) -> ExploreMode:
	var mode := ExploreMode.arriving(session, map_def, entry)
	mode.ready.connect(autosave, CONNECT_ONE_SHOT)
	return mode
