extends SceneTree
## Compiles every project script with each GDScript warning promoted to an error, so no warning
## goes unnoticed. Godot caches warning levels at startup, so this runs in two passes; use
## tools/lint.ps1, which runs both and always removes the temporary override file:
## [codeblock]
## godot --headless --path . -s res://tools/lint.gd -- --prepare   # writes res://override.cfg
## godot --headless --path . -s res://tools/lint.gd                # compiles every script
## [/codeblock]

const OVERRIDE_PATH := "res://override.cfg"
const WARNING_SETTINGS := "debug/gdscript/warnings/"
const SKIPPED_DIRS: Array[String] = ["res://addons", "res://.godot"]

## Godot's warning levels for debug/gdscript/warnings/* settings.
const LEVEL_WARN := 1
const LEVEL_ERROR := 2


## Counts every error the engine logs, from any thread.
class ErrorCounter extends Logger:
	var count := 0
	var _mutex := Mutex.new()

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String,
			_editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		_mutex.lock()
		count += 1
		_mutex.unlock()


## Runs after the autoloads are registered, so scripts that use them (ContentDB, Game) compile.
func _initialize() -> void:
	if OS.get_cmdline_user_args().has("--prepare"):
		quit(_write_overrides())
	else:
		quit(_compile_all())


## Writes an override.cfg that turns every warning currently set to "Warn" into "Error".
func _write_overrides() -> int:
	var overrides := ConfigFile.new()
	for property: Dictionary in ProjectSettings.get_property_list():
		var setting: String = property.name
		if setting.begins_with(WARNING_SETTINGS) and property.type == TYPE_INT \
				and ProjectSettings.get_setting(setting) == LEVEL_WARN:
			overrides.set_value("debug", setting.trim_prefix("debug/"), LEVEL_ERROR)
	return overrides.save(OVERRIDE_PATH)


## Loads every script. Godot prints each problem with its file and line; returns 1 if any were found.
func _compile_all() -> int:
	var errors := ErrorCounter.new()
	OS.add_logger(errors)
	var scripts := _find_scripts("res://")
	var failed: Array[String] = []
	for path: String in scripts:
		# This script is running, so it compiled cleanly; parsing it again would replace it mid-run.
		if path == (get_script() as Script).resource_path:
			continue
		var errors_before := errors.count
		# Parse afresh: scripts the autoloads use were compiled at startup, before the counter was
		# listening, and the cache would hand back those results without reporting them again.
		ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if errors.count > errors_before:
			failed.append(path)
	OS.remove_logger(errors)
	if failed.is_empty():
		print("Lint: %d scripts, no warnings." % scripts.size())
		return 0
	printerr("Lint: %d of %d scripts have warnings or errors:\n  %s" % [failed.size(), scripts.size(), "\n  ".join(failed)])
	return 1


func _find_scripts(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	for file: String in DirAccess.get_files_at(dir_path):
		if file.get_extension() == "gd":
			found.append(dir_path.path_join(file))
	for subdir: String in DirAccess.get_directories_at(dir_path):
		var path := dir_path.path_join(subdir)
		if path not in SKIPPED_DIRS:
			found.append_array(_find_scripts(path))
	return found
