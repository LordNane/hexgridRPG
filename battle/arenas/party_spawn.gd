@tool
class_name PartySpawn extends SpawnMarker
## Where a party member starts a battle. Members take the party spawns in scene order.


func team() -> BattleUnit.Team:
	return BattleUnit.Team.PARTY
