class_name ContentValidator
## Checks a ContentRegistry for data mistakes: the problems each Def reports about itself, plus any
## reference to content that isn't registered (for example an item saved outside content/data).


## Every problem found, as readable sentences. Empty means the content is clean.
static func validate(registry: ContentRegistry) -> PackedStringArray:
	var problems := PackedStringArray(registry.problems)
	for def: Def in registry.all():
		var where := registry.source_of(def.id)
		for problem: String in def.validate():
			problems.append("%s: %s" % [where, problem])
		for referenced: Def in referenced_defs(def):
			if registry.get_def(referenced.id) != referenced:
				problems.append("%s: refers to \"%s\" (%s), which isn't registered content" % [
					where, referenced.id, referenced.resource_path])
	return problems


## The Defs that [param resource]'s script properties point to, looking inside arrays, dictionaries
## and embedded resources (such as a POI's actions). Referenced Defs aren't searched further.
static func referenced_defs(resource: Resource) -> Array[Def]:
	var found: Array[Def] = []
	var visited: Dictionary[Resource, bool] = {resource: true}
	_collect_from_properties(resource, found, visited)
	return found


static func _collect_from_properties(resource: Resource, found: Array[Def], visited: Dictionary[Resource, bool]) -> void:
	for property: Dictionary in resource.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			_collect(resource.get(property.name), found, visited)


static func _collect(value: Variant, found: Array[Def], visited: Dictionary[Resource, bool]) -> void:
	if value is Def:
		if not found.has(value):
			found.append(value)
	elif value is Resource:
		if not visited.has(value):
			visited[value] = true
			_collect_from_properties(value, found, visited)
	elif value is Array:
		for element: Variant in value:
			_collect(element, found, visited)
	elif value is Dictionary:
		for key: Variant in value:
			_collect(key, found, visited)
			_collect(value[key], found, visited)
