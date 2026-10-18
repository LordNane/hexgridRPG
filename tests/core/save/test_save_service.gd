extends GutTest

const DIR := "user://test_saves/"

var _saves: SaveService


func before_each() -> void:
	_saves = SaveService.new(DIR)


func after_each() -> void:
	if DirAccess.dir_exists_absolute(DIR):
		for file: String in DirAccess.get_files_at(DIR):
			DirAccess.remove_absolute(DIR.path_join(file))
		DirAccess.remove_absolute(DIR)


func test_a_session_survives_a_save_file() -> void:
	var session := GameSession.new(5)
	session.inventory.add(&"potion")
	session.inventory.add(&"ether")
	session.add_gold(20)
	session.enter_map(&"overworld", Vector2i(3, 4))
	session.world.map_state(&"overworld").explored[Vector2i(3, 4)] = true
	assert_eq(_saves.write("autosave", session.to_dict()), OK)
	var loaded := GameSession.from_dict(_saves.read("autosave"), ContentRegistry.new())
	var items: Array[StringName] = [&"potion", &"ether"]
	assert_eq(loaded.inventory.item_ids(), items, "items keep the order they were acquired in")
	assert_eq(loaded.gold, 20)
	assert_eq(loaded.location().hex, Vector2i(3, 4))
	assert_true(loaded.world.map_state(&"overworld").explored.has(Vector2i(3, 4)))
	assert_false(FileAccess.file_exists(DIR + "autosave.json.tmp"), "no temporary file is left behind")


func test_slots_list_the_most_recent_save_first() -> void:
	assert_true(_saves.slots().is_empty())
	_saves.write("slot_1", {})
	_saves.write("autosave", {})
	_saves.write("slot_1", {"again": true})
	var expected: Array[String] = ["slot_1", "autosave"]
	assert_eq(_saves.slots(), expected)
	assert_true(_saves.has_slot("autosave"))
	assert_false(_saves.has_slot("slot_2"))


func test_older_saves_are_upgraded_one_version_at_a_time() -> void:
	_saves.write("old", {"name": "Rin"})
	var migrations: Array[Callable] = [
		func(data: Dictionary) -> Dictionary: return {"hero": data["name"]},
		func(data: Dictionary) -> Dictionary: return data.merged({"level": 1}),
	]
	var newer := SaveService.new(DIR, migrations)
	assert_eq(newer.version, 3)
	assert_eq(newer.read("old"), {"hero": "Rin", "level": 1})


func test_saves_from_a_newer_version_are_refused() -> void:
	var migrations: Array[Callable] = [func(data: Dictionary) -> Dictionary: return data]
	SaveService.new(DIR, migrations).write("future", {"hero": "Rin"})
	assert_eq(_saves.read("future"), {})
	assert_push_error("can't read a version 2 save")


func test_missing_and_broken_saves_read_as_empty() -> void:
	assert_eq(_saves.read("nothing"), {})
	assert_push_error("no such save")
	DirAccess.make_dir_recursive_absolute(DIR)
	var file := FileAccess.open(DIR + "broken.json", FileAccess.WRITE)
	file.store_string("{\"version\": 1, \"data\": ")
	file.close()
	assert_eq(_saves.read("broken"), {})
	assert_push_error("broken save")
