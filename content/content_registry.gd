class_name ContentRegistry extends RefCounted
## A set of content definitions, looked up by id. The ContentDB autoload holds the game's
## registry; tests build their own.

## Problems found while adding content, such as duplicate ids or non-Def files.
var problems := PackedStringArray()

var _defs: Dictionary[StringName, Def] = {}
var _sources: Dictionary[StringName, String] = {}


## Adds every [Def] saved under [param dir] and its subfolders. Works in exported builds too.
func load_dir(dir: String) -> void:
	for entry: String in ResourceLoader.list_directory(dir):
		var path := dir.path_join(entry)
		if entry.ends_with("/"):
			load_dir(path)
			continue
		var def := load(path) as Def
		if def:
			add(def, path)
		else:
			problems.append("%s isn't a Def; only content definitions belong in %s" % [path, dir])


## Adds [param def]. [param source] says where it came from in problem reports.
func add(def: Def, source: String = "") -> void:
	var where := source if source else str(def)
	if def.id.is_empty():
		problems.append("%s has no id" % where)
	elif _defs.has(def.id):
		problems.append("duplicate id \"%s\" in %s and %s" % [def.id, _sources[def.id], where])
	else:
		_defs[def.id] = def
		_sources[def.id] = where


## Whether a Def with [param id] is registered.
func has(id: StringName) -> bool:
	return _defs.has(id)


## The Def registered as [param id], or null.
func get_def(id: StringName) -> Def:
	return _defs.get(id)


## Every registered Def.
func all() -> Array[Def]:
	var result: Array[Def] = []
	result.assign(_defs.values())
	return result


## Every registered Def of [param type], a Def script such as TerrainDef.
func all_of(type: Script) -> Array[Def]:
	var result: Array[Def] = []
	for def: Def in _defs.values():
		if is_instance_of(def, type):
			result.append(def)
	return result


## Where the Def with [param id] was loaded from, for problem reports.
func source_of(id: StringName) -> String:
	return _sources.get(id, "")
