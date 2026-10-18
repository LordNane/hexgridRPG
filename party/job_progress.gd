class_name JobProgress extends RefCounted
## What one character has gained in one job: JP to spend there, and the abilities learned from it.
## Earning and spending JP arrive in Phase 8.

var jp := 0

var _learned: Array[AbilityDef] = []


func knows(ability: AbilityDef) -> bool:
	return _learned.has(ability)


## Adds [param ability] to what's been learned here.
func learn(ability: AbilityDef) -> void:
	if not knows(ability):
		_learned.append(ability)


## Every ability learned here, in the order learned.
func learned() -> Array[AbilityDef]:
	return _learned.duplicate()


func to_dict() -> Dictionary:
	var ids: Array[String] = []
	for ability: AbilityDef in _learned:
		ids.append(String(ability.id))
	return {"jp": jp, "learned": ids}


## Abilities [param content] doesn't have any more are dropped with a warning.
static func from_dict(data: Dictionary, content: ContentRegistry) -> JobProgress:
	var progress := JobProgress.new()
	progress.jp = int(data.get("jp", 0))
	for id: Variant in data.get("learned", []):
		var ability := content.get_def(StringName(id)) as AbilityDef
		if ability:
			progress.learn(ability)
		else:
			push_warning("A save says an ability \"%s\" was learned, but there's no such ability." % id)
	return progress
