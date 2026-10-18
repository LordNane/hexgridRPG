extends Node
## Autoload "ContentDB": every content definition, looked up by id.
##
## Loads each Def saved under res://content/data/ at startup. Code that only has an id (tile custom
## data, save files) gets the Def with [method get_def]. Loading problems are reported as errors;
## deeper checks run in the content tests.

const DATA_DIR := "res://content/data/"

## The game's content. Tests build their own ContentRegistry instead of using this.
var registry := ContentRegistry.new()


func _ready() -> void:
	registry.load_dir(DATA_DIR)
	for problem: String in registry.problems:
		push_error("Content: " + problem)


## The Def registered as [param id], or null.
func get_def(id: StringName) -> Def:
	return registry.get_def(id)
