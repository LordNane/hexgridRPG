class_name Party extends RefCounted
## The characters traveling together, in formation order. Saved with the session.

## Emitted when someone joins or leaves.
signal changed

var _members: Array[Character] = []


## Every member, in order.
func members() -> Array[Character]:
	return _members.duplicate()


func add(character: Character) -> void:
	assert(not has(character), "%s is already in the party." % character.name)
	_members.append(character)
	changed.emit()


func remove(character: Character) -> void:
	if has(character):
		_members.erase(character)
		changed.emit()


func has(character: Character) -> bool:
	return _members.has(character)


func size() -> int:
	return _members.size()


func to_dict() -> Dictionary:
	var saved: Array[Dictionary] = []
	for character: Character in _members:
		saved.append(character.to_dict())
	return {"members": saved}


## The saved party, with Defs looked up in [param content]. Members that can't be loaded are left
## out, with an error.
static func from_dict(data: Dictionary, content: ContentRegistry) -> Party:
	var party := Party.new()
	for saved: Variant in data.get("members", []):
		var character := Character.from_dict(saved, content)
		if character:
			party._members.append(character)
	return party
