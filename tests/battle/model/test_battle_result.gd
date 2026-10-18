extends GutTest

var _potion: ItemDef
var _bandit: EnemyDef
var _hero: BattleUnit
var _foe: BattleUnit
var _battle: Battle


func before_each() -> void:
	_potion = FakeContent.item(&"potion")
	_bandit = FakeContent.enemy(&"bandit", FakeContent.job(&"brawler"), 30)
	_bandit.drops = {_potion: 1.0}
	_hero = FakeBattle.unit("Hero", BattleUnit.Team.PARTY, Vector2i(0, 0))
	_foe = BattleUnit.new(Character.from_def(_bandit, ContentRegistry.new()), BattleUnit.Team.ENEMY, Vector2i(2, 0), 0, _bandit)
	_battle = FakeBattle.battle(FakeBattle.flat_map(), [_hero, _foe])


func test_a_victory_collects_each_fallen_enemys_gold_and_drops() -> void:
	_foe.character.hp = 0
	_battle.result = BattleOutcome.Result.VICTORY
	var result := BattleResult.of(_battle)
	assert_true(result.is_victory())
	assert_eq(result.gold, 30)
	var won: Dictionary[StringName, int] = {&"potion": 1}
	assert_eq(result.items, won)


func test_unlikely_drops_can_miss() -> void:
	_bandit.drops = {_potion: 0.000001}
	_foe.character.hp = 0
	_battle.result = BattleOutcome.Result.VICTORY
	assert_true(BattleResult.of(_battle).items.is_empty())


func test_applying_a_victory_pays_out_and_restores_the_party() -> void:
	var session := GameSession.new()
	session.party.add(_hero.character)
	_hero.character.hp = 0
	_foe.character.hp = 0
	_battle.result = BattleOutcome.Result.VICTORY
	BattleResult.of(_battle).apply_to(session)
	assert_eq(session.gold, 30)
	assert_eq(session.inventory.count_of(&"potion"), 1)
	assert_eq(_hero.character.hp, _hero.character.max_hp(), "the fallen get back up after a victory")


func test_a_defeat_wins_nothing() -> void:
	var session := GameSession.new()
	_hero.character.hp = 0
	_battle.result = BattleOutcome.Result.DEFEAT
	var result := BattleResult.of(_battle)
	result.apply_to(session)
	assert_false(result.is_victory())
	assert_eq(session.gold, 0)
	assert_eq(result.gold, 0)
