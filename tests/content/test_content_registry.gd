extends GutTest

var _registry: ContentRegistry


func before_each() -> void:
	_registry = ContentRegistry.new()


func test_registered_defs_are_found_by_id() -> void:
	var grass := FakeContent.terrain(&"grass")
	_registry.add(grass, "grass.tres")
	assert_true(_registry.has(&"grass"))
	assert_eq(_registry.get_def(&"grass"), grass)
	assert_eq(_registry.source_of(&"grass"), "grass.tres")
	assert_null(_registry.get_def(&"lava"))
	assert_true(_registry.problems.is_empty())


func test_duplicate_and_missing_ids_are_problems() -> void:
	_registry.add(FakeContent.terrain(&"grass"), "a.tres")
	_registry.add(FakeContent.terrain(&"grass"), "b.tres")
	_registry.add(FakeContent.terrain(&""), "c.tres")
	assert_eq(_registry.problems.size(), 2)
	assert_string_contains(_registry.problems[0], "duplicate id \"grass\" in a.tres and b.tres")
	assert_string_contains(_registry.problems[1], "c.tres has no id")
	assert_eq(_registry.all().size(), 1, "only the first grass was kept")


func test_all_of_filters_by_type() -> void:
	_registry.add(FakeContent.terrain(&"grass"))
	_registry.add(FakeContent.terrain(&"water"))
	_registry.add(FakeContent.item(&"potion"))
	assert_eq(_registry.all_of(TerrainDef).size(), 2)
	assert_eq(_registry.all_of(ItemDef).size(), 1)
	assert_eq(_registry.all_of(Def).size(), 3)


func test_validator_reports_each_defs_own_problems() -> void:
	_registry.add(FakeContent.terrain(&"void", 0.0), "void.tres")
	var problems := ContentValidator.validate(_registry)
	assert_eq(problems.size(), 1)
	assert_string_contains(problems[0], "void.tres: move_cost must be positive")


func test_validator_finds_references_to_unregistered_content() -> void:
	var potion := FakeContent.item(&"potion")
	var chest := FakeContent.poi(&"chest", [FakeContent.give(potion, 2)])
	_registry.add(chest, "chest.tres")
	var problems := ContentValidator.validate(_registry)
	assert_eq(problems.size(), 1)
	assert_string_contains(problems[0], "chest.tres: refers to \"potion\"")
	_registry.add(potion, "potion.tres")
	assert_true(ContentValidator.validate(_registry).is_empty(), "clean once the potion is registered")


func test_referenced_defs_looks_inside_arrays_dictionaries_and_embedded_resources() -> void:
	var potion := FakeContent.item(&"potion")
	var ether := FakeContent.item(&"ether")
	var chest := FakeContent.poi(&"chest", [FakeContent.give(potion, 1), FakeContent.give(ether, 3)])
	chest.conditions = [FakeContent.flag_condition(&"opened_gate")]
	var found := ContentValidator.referenced_defs(chest)
	assert_eq(found.size(), 2)
	assert_has(found, potion)
	assert_has(found, ether)
