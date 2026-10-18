class_name PartyDefeated extends BattleOutcome
## Defeat once no party member is left standing.


func check(battle: Battle) -> Result:
	return Result.DEFEAT if battle.living(BattleUnit.Team.PARTY).is_empty() else Result.NONE
