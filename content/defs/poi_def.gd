class_name PoiDef extends Def
## A point of interest on a map: a chest, shrine, sign, cave mouth or person. Place one with a
## PoiMarker. What it does is its list of [member actions], run in order when it triggers.

enum Trigger {
	## When the party ends a walk on it (or next to it, if it blocks movement), or presses
	## confirm while there. For most POIs.
	ON_INTERACT,
	## As soon as the party steps onto it, even mid-walk. The walk stops. For ambushes and lookouts.
	ON_ENTER,
}

@export var trigger := Trigger.ON_INTERACT
## The party can't stand on it and interacts from a neighboring hex instead, like a sign or a person.
@export var blocks_movement := false
## Works only once per playthrough, like a chest. Afterwards it shows [member used_icon].
@export var once := false
## Every condition must hold for the POI to work; otherwise [member unavailable_text] is shown.
@export var conditions: Array[Condition] = []
@export_multiline var unavailable_text := ""
@export var actions: Array[PoiAction] = []
## The icon once a [member once] POI has been used, such as an open chest. Defaults to [member icon].
@export var used_icon: Texture2D


func validate() -> PackedStringArray:
	var problems := super()
	if actions.is_empty():
		problems.append("has no actions")
	if actions.has(null) or conditions.has(null):
		problems.append("has an empty action or condition slot")
	for action: PoiAction in actions:
		if action:
			problems.append_array(action.validate())
	if blocks_movement and trigger == Trigger.ON_ENTER:
		problems.append("blocks movement, so nobody can step onto it to trigger it")
	return problems
