extends GutTest

var _router: ModeRouter
var _push_results: Array = []


func before_each() -> void:
	_router = ModeRouter.new()
	_router.fade_seconds = 0.0
	add_child_autofree(_router)
	_push_results.clear()


func after_each() -> void:
	await wait_process_frames(1, "let modes the router discarded be deleted")


func test_a_pushed_mode_pauses_the_one_below_until_it_pops() -> void:
	var overworld := Node2D.new()
	var cave := Node2D.new()
	await _router.switch_to([overworld])
	_router.push(cave)
	assert_eq(_router.top(), cave)
	assert_true(cave.is_inside_tree())
	assert_false(overworld.is_inside_tree(), "the overworld waits out of the tree")
	assert_true(is_instance_valid(overworld))

	await _router.pop()
	assert_eq(_router.top(), overworld)
	assert_true(overworld.is_inside_tree())
	assert_false(cave.is_inside_tree())
	assert_true(cave.is_queued_for_deletion())


func test_a_push_returns_what_its_mode_pops_with() -> void:
	await _router.switch_to([Node.new()])
	_record_push(Node.new())
	assert_eq(_push_results, [], "still waiting")
	await _router.pop(&"victory")
	assert_eq(_push_results, [&"victory"])


func test_switching_replaces_every_mode_and_shows_only_the_new_top() -> void:
	var title := Node.new()
	await _router.switch_to([title])
	var overworld := Node.new()
	var cave := Node.new()
	await _router.switch_to([overworld, cave])
	assert_true(title.is_queued_for_deletion())
	assert_eq(_router.depth(), 2)
	assert_true(cave.is_inside_tree())
	assert_false(overworld.is_inside_tree(), "joins the tree once the cave pops")
	await _router.pop()
	assert_true(overworld.is_inside_tree())


func test_freeing_the_router_frees_the_modes_waiting_below() -> void:
	var overworld := Node.new()
	await _router.switch_to([overworld, Node.new()])
	_router.free()
	assert_false(is_instance_valid(overworld))


func test_changes_fade_and_report_when_done() -> void:
	_router.fade_seconds = 0.05
	var title := Node.new()
	_router.switch_to([title])
	assert_true(_router.is_changing())
	await wait_for_signal(_router.changed, 1.0)
	assert_false(_router.is_changing())
	assert_eq(_router.top(), title)


func _record_push(mode: Node) -> void:
	_push_results.append(await _router.push(mode))
