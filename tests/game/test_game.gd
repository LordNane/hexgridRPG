extends GutTest
## Game's flows with the real content: a new game, a trip into the test cave and back, and
## continuing from the autosave. Uses its own Game, router and save folder, not the autoload's.

const GameScript := preload("res://game/game.gd")
const SAVE_DIR := "user://test_game_saves/"
const CAVE := &"test_cave"

var _game: GameScript
var _router: ModeRouter


func before_each() -> void:
	_router = ModeRouter.new()
	_router.fade_seconds = 0.0
	add_child_autofree(_router)
	_game = GameScript.new()
	_game.saves = SaveService.new(SAVE_DIR, _game.migrations())
	add_child_autofree(_game)
	_game.start(_router)


func after_each() -> void:
	await wait_process_frames(1, "let modes the router discarded be deleted")
	if DirAccess.dir_exists_absolute(SAVE_DIR):
		for file: String in DirAccess.get_files_at(SAVE_DIR):
			DirAccess.remove_absolute(SAVE_DIR.path_join(file))
		DirAccess.remove_absolute(SAVE_DIR)


func test_a_new_game_starts_on_the_first_map_and_autosaves() -> void:
	assert_is(_router.top(), TitleScreen)
	_game.new_game()
	assert_is(_router.top(), ExploreMode)
	assert_eq(_game.session.location().map_id, GameScript.START_MAP)
	assert_eq(_saved().location().map_id, GameScript.START_MAP)


func test_a_new_game_starts_with_the_starting_party_and_items() -> void:
	_game.new_game()
	var party := _game.session.party
	assert_eq(party.size(), GameScript.START_PARTY.size())
	for character: Character in party.members():
		assert_eq(character.hp, character.max_hp(), "%s starts rested" % character.name)
		assert_false(character.equipment.items().is_empty(), "%s starts with gear" % character.name)
	for item_id: StringName in GameScript.START_ITEMS:
		assert_true(ContentDB.get_def(item_id) is ItemDef, "%s is an item" % item_id)
		assert_eq(_game.session.inventory.count_of(item_id), GameScript.START_ITEMS[item_id])
	var saved_party := _saved().party
	assert_eq(saved_party.size(), party.size(), "the party is in the autosave")
	assert_true(saved_party.members()[0].stats().same_as(party.members()[0].stats()))


func test_saves_from_before_the_party_get_the_starting_party() -> void:
	var old_format := SaveService.new(SAVE_DIR)
	assert_eq(old_format.version, 1)
	var session := GameSession.new()
	session.enter_map(GameScript.START_MAP, Vector2i.ZERO)
	var data := session.to_dict()
	data.erase("party")
	old_format.write(GameScript.AUTOSAVE_SLOT, data)
	var loaded := _saved()
	assert_eq(loaded.party.size(), GameScript.START_PARTY.size())
	assert_eq(loaded.location().map_id, GameScript.START_MAP, "the rest of the save is untouched")


func test_leaving_a_cave_returns_to_the_hex_it_was_entered_from() -> void:
	_game.new_game()
	var overworld := _router.top()
	var entered_from := _game.session.location().hex
	_game.enter_map(_map(CAVE), &"start")
	assert_eq(_router.depth(), 2)
	assert_eq(_game.session.location().map_id, CAVE)
	assert_eq(_saved().location().map_id, CAVE, "autosaved on arrival")

	await _game.exit_map()
	assert_same(_router.top(), overworld)
	assert_eq(_game.session.location().map_id, GameScript.START_MAP)
	assert_eq(_game.session.location().hex, entered_from)
	assert_eq(_saved().location().map_id, GameScript.START_MAP, "autosaved on leaving")


func test_continuing_puts_the_party_back_where_it_was_saved() -> void:
	_game.new_game()
	_game.enter_map(_map(CAVE), &"start")
	var cave_hex := _game.session.location().hex
	var cave_state := _game.session.world.map_state(CAVE)
	cave_state.mark_used(Vector2i(4, 4))
	var explored := cave_state.explored.size()
	_game.autosave()

	_game.show_title()
	assert_null(_game.session)
	_game.continue_game()
	assert_eq(_router.depth(), 2, "the overworld waits below the cave")
	assert_eq(_game.session.location().map_id, CAVE)
	assert_eq(_game.session.location().hex, cave_hex)
	var loaded_state := _game.session.world.map_state(CAVE)
	assert_true(loaded_state.is_used(Vector2i(4, 4)), "the chest stays open")
	assert_eq(loaded_state.explored.size(), explored, "explored hexes stay explored")

	await _game.exit_map()
	assert_eq(_game.session.location().map_id, GameScript.START_MAP)
	assert_true(_router.top().is_inside_tree())


func test_winning_a_battle_pays_out_and_returns_to_the_same_hex() -> void:
	_game.new_game()
	_game.autoplay_battles = true
	# A fixed seed and an easy fight: a lost battle ends the game, and start_battle never returns.
	_game.session.rng = SeededRng.new(11)
	var overworld := _router.top()
	var hex := _game.session.location().hex
	var gold := _game.session.gold
	var encounter := ContentDB.get_def(&"bandit_scouts") as EncounterDef
	var outcome: Array[BattleResult] = []
	var fight := func() -> void:
		outcome.append(await _game.start_battle(encounter, "res://battle/arenas/forest_clearing.tscn"))
	fight.call()
	await wait_until(func() -> bool: return not outcome.is_empty(), 30.0, "the battle is won")
	assert_eq(outcome.size(), 1, "the battle came back with a result")
	if outcome.is_empty():
		return
	var result := outcome[0]
	assert_true(result.is_victory())
	assert_same(_router.top(), overworld)
	assert_eq(_game.session.location().hex, hex)
	assert_eq(_game.session.gold, gold + result.gold, "the loot is collected")
	for member: Character in _game.session.party.members():
		assert_eq(member.hp, member.max_hp(), "%s is restored after the victory" % member.name)
	assert_eq(_game.session.encounter_grace, EncounterRoller.GRACE_STEPS)
	assert_eq(_saved().gold, _game.session.gold, "autosaved after the battle")


func test_losing_a_battle_ends_the_game() -> void:
	_game.new_game()
	var defeat := BattleResult.new()
	defeat.outcome = BattleOutcome.Result.DEFEAT
	_game._on_battle_finished(defeat)
	assert_is(_router.top(), TitleScreen)
	assert_null(_game.session)


func _map(id: StringName) -> MapDef:
	return ContentDB.get_def(id) as MapDef


## The session in the autosave.
func _saved() -> GameSession:
	return GameSession.from_dict(_game.saves.read(GameScript.AUTOSAVE_SLOT), ContentDB.registry)
