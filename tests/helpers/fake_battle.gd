class_name FakeBattle
## Builds battles in code for tests: flat maps, fighters with readable stats and a fixed seed.


## A flat map of [param terrain] (grass if null) covering every hex within [param radius] of the
## origin, with a party spawn at (-2, 0) and an enemy spawn at (2, 0).
static func flat_map(radius: int = 4, terrain: TerrainDef = null) -> BattleMap:
	var ground := terrain if terrain else FakeContent.terrain(&"grass")
	var map := BattleMap.new()
	for hex: Vector2i in Hex.disc(Vector2i.ZERO, radius):
		map.set_cell(hex, ground)
	map.party_spawns.append(BattleMap.Spawn.new(Vector2i(-2, 0), Hex.Dir.SE))
	map.enemy_spawns.append(BattleMap.Spawn.new(Vector2i(2, 0), Hex.Dir.NW))
	return map


## A character with FakeContent.own_stats(): 40 HP, 10 Attack, 6 Defense, 6 Speed. In a plain
## job they have Move 4 and Jump 3, and punch for 1 hex.
static func fighter(fighter_name: String, job: JobDef = null) -> Character:
	return Character.new(fighter_name, job if job else FakeContent.job(&"brawler"), FakeContent.own_stats())


static func unit(fighter_name: String, team: BattleUnit.Team, hex: Vector2i, job: JobDef = null) -> BattleUnit:
	var faces := Hex.Dir.SE if team == BattleUnit.Team.PARTY else Hex.Dir.NW
	return BattleUnit.new(fighter(fighter_name, job), team, hex, faces)


static func battle(map: BattleMap, units: Array[BattleUnit], seed_value: int = 1) -> Battle:
	return Battle.new(map, units, SeededRng.new(seed_value))
