class_name SaveService extends RefCounted
## Save slots: one JSON file per slot, such as user://saves/autosave.json. Each file records the save
## format version it was written in; reading an older file upgrades its data one version at a time
## with the migration functions, so old saves keep loading as the game grows. Works on plain
## Dictionaries, such as [method GameSession.to_dict].

const DEFAULT_DIR := "user://saves/"
const EXTENSION := ".json"

## The save format version this build writes: one more than the number of migrations.
var version: int

var _dir: String
var _migrations: Array[Callable]
## When this service last saved. Each save is stamped later than the one before, even within one
## tick of the clock, so the most recent slot always sorts first.
var _last_saved_at := 0.0


## [param migrations] holds one function per change to the saved data's shape, oldest first. Each
## takes the data of one version and returns it in the shape of the next, so the first upgrades
## version 1 saves to version 2. Adding one bumps [member version].
func _init(save_dir: String = DEFAULT_DIR, migrations: Array[Callable] = []) -> void:
	_dir = save_dir
	_migrations = migrations
	version = migrations.size() + 1


## Saves [param data] in [param slot], replacing what was there.
func write(slot: String, data: Dictionary) -> Error:
	assert(slot.is_valid_filename(), "\"%s\" can't be used as a file name." % slot)
	var error := DirAccess.make_dir_recursive_absolute(_dir)
	if error != OK:
		return error
	# Write a temporary file first, so a crash mid-save can't ruin the slot's previous save.
	var path := _path(slot)
	var temp_path := path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	_last_saved_at = maxf(Time.get_unix_time_from_system(), _last_saved_at + 0.001)
	# Keys stay unsorted: some data's order matters, such as the order items were acquired in.
	var saved := {"version": version, "saved_at": _last_saved_at, "data": data}
	file.store_string(JSON.stringify(saved, "\t", false))
	error = file.get_error()
	file.close()
	if error != OK:
		return error
	return DirAccess.rename_absolute(temp_path, path)


## The data saved in [param slot], upgraded to the current [member version]. Empty if the slot is
## missing or can't be read; the reason is reported as an error.
func read(slot: String) -> Dictionary:
	var path := _path(slot)
	var saved := _read_file(path)
	if saved.is_empty():
		return {}
	var saved_version := int(saved.get("version", 0))
	if saved_version < 1 or saved_version > version or not saved.get("data") is Dictionary:
		push_error("%s: can't read a version %d save (this build reads versions 1 to %d)." % [path, saved_version, version])
		return {}
	var data: Dictionary = saved["data"]
	for from_version: int in range(saved_version, version):
		data = _migrations[from_version - 1].call(data)
	return data


func has_slot(slot: String) -> bool:
	return FileAccess.file_exists(_path(slot))


## Every slot holding a save, most recently saved first.
func slots() -> Array[String]:
	var found: Array[String] = []
	if not DirAccess.dir_exists_absolute(_dir):
		return found
	var saved_at: Dictionary[String, float] = {}
	for file: String in DirAccess.get_files_at(_dir):
		if file.ends_with(EXTENSION):
			saved_at[file.get_basename()] = float(_read_file(_dir.path_join(file)).get("saved_at", 0.0))
	found.assign(saved_at.keys())
	found.sort_custom(func(a: String, b: String) -> bool: return saved_at[a] > saved_at[b])
	return found


func _path(slot: String) -> String:
	return _dir.path_join(slot + EXTENSION)


## The JSON object in the file at [param path], or empty (with an error reported) if there isn't one.
func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("%s: no such save." % path)
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		push_error("%s: broken save, %s on line %d." % [path, json.get_error_message(), json.get_error_line()])
		return {}
	if not json.data is Dictionary:
		push_error("%s: broken save, not a JSON object." % path)
		return {}
	return json.data
