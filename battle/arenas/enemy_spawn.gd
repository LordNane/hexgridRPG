@tool
class_name EnemySpawn extends SpawnMarker
## Where an enemy starts a battle. An encounter's enemies take the enemy spawns in scene order.


func team() -> BattleUnit.Team:
	return BattleUnit.Team.ENEMY
