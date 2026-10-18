class_name DefeatAllEnemies extends BattleOutcome
## Victory once no enemy is left standing.


func check(battle: Battle) -> Result:
	return Result.VICTORY if battle.living(BattleUnit.Team.ENEMY).is_empty() else Result.NONE
