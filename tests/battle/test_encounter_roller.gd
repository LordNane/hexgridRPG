extends GutTest

var _session: GameSession
var _bandits: EncounterDef
var _wolves: EncounterDef
var _table: EncounterTable


func before_each() -> void:
	_session = GameSession.new(5)
	var job := FakeContent.job(&"brawler")
	_bandits = FakeContent.encounter(&"bandits", [FakeContent.enemy(&"bandit", job)])
	_wolves = FakeContent.encounter(&"wolves", [FakeContent.enemy(&"wolf", job)])
	_table = EncounterTable.new()
	_table.chance_per_step = 1.0
	_table.encounters = {_bandits: 1, _wolves: 3}


func test_no_battles_during_the_grace_period() -> void:
	_session.encounter_grace = 2
	assert_null(EncounterRoller.roll(_session, _table))
	assert_null(EncounterRoller.roll(_session, _table))
	assert_eq(_session.encounter_grace, 0)
	assert_not_null(EncounterRoller.roll(_session, _table))
	EncounterRoller.reset_grace(_session)
	assert_eq(_session.encounter_grace, EncounterRoller.GRACE_STEPS)


func test_no_battles_without_a_table_or_a_chance() -> void:
	_session.encounter_grace = 0
	assert_null(EncounterRoller.roll(_session, null))
	_table.chance_per_step = 0.0
	assert_null(EncounterRoller.roll(_session, _table))


func test_heavier_encounters_come_up_more_often() -> void:
	_session.encounter_grace = 0
	var counts: Dictionary[StringName, int] = {&"bandits": 0, &"wolves": 0}
	for _i: int in 400:
		counts[EncounterRoller.roll(_session, _table).id] += 1
	assert_between(counts[&"wolves"], 250, 350, "weight 3 of 4")


func test_arenas_come_from_the_encounter_then_the_feature_then_the_terrain() -> void:
	var grass := FakeContent.terrain(&"grass")
	grass.battle_arenas = ["res://plain.tscn"]
	var forest := FakeContent.feature(&"forest")
	forest.battle_arenas = ["res://woods.tscn"]
	var rng := SeededRng.new(1)
	assert_eq(EncounterRoller.pick_arena(_bandits, grass, null, rng), "res://plain.tscn")
	assert_eq(EncounterRoller.pick_arena(_bandits, grass, forest, rng), "res://woods.tscn")
	_bandits.arenas = ["res://camp.tscn"]
	assert_eq(EncounterRoller.pick_arena(_bandits, grass, forest, rng), "res://camp.tscn")
	assert_eq(EncounterRoller.pick_arena(_wolves, FakeContent.terrain(&"sand"), null, rng), "", "no arena for sand")
