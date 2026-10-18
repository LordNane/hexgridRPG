extends GutTest
## Whole battles in BattleMode with the real content: the starting party against the bandit
## patrol in the forest clearing.

const ARENA := "res://battle/arenas/forest_clearing.tscn"

var _mode: BattleMode


func after_each() -> void:
	await wait_process_frames(1, "let freed nodes go")


func test_a_battle_the_ai_plays_for_both_sides_ends_with_a_result() -> void:
	_mode = _start(true)
	await wait_for_signal(_mode.finished, 20.0, "the battle plays out")
	assert_signal_emitted(_mode, "finished")
	var result: BattleResult = get_signal_parameters(_mode, "finished")[0]
	assert_true(_mode.battle.is_over())
	assert_ne(result.outcome, BattleOutcome.Result.NONE)
	assert_true(result.is_victory(), "the starting party beats a bandit patrol")


func test_the_player_can_wait_out_a_turn() -> void:
	_mode = _start(false)
	await wait_process_frames(3, "the first turn starts")
	var first := _mode.battle.active
	assert_eq(first.team, BattleUnit.Team.PARTY, "the party goes first on ties")
	_mode.hud.command_chosen.emit(CommandState.WAIT)
	var confirm := InputEventAction.new()
	confirm.action = &"confirm"
	confirm.pressed = true
	_mode._unhandled_input(confirm)
	await wait_process_frames(2, "the next turn starts")
	assert_ne(_mode.battle.active, first)
	assert_false(first.moved or first.acted)


func _start(ai_for_party: bool) -> BattleMode:
	var party := Party.new()
	for id: StringName in [&"alden", &"brin", &"cass", &"dara"]:
		party.add(Character.from_def(ContentDB.get_def(id) as CharacterDef, ContentDB.registry))
	var request := BattleRequest.new(ARENA, party.members(), ContentDB.get_def(&"bandit_patrol") as EncounterDef, 7)
	var mode := BattleMode.create(request)
	mode.party_ai = ai_for_party
	mode.instant = true
	watch_signals(mode)
	add_child_autofree(mode)
	return mode
