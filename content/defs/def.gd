@abstract
class_name Def extends Resource
## Base class for every content definition: terrain, items, POIs, maps, and later jobs and abilities.
##
## A Def is static data, edited in the inspector and saved as a .tres under res://content/data/.
## Never change one while playing: Resources are shared, so the change would leak everywhere.
## Runtime state lives in other classes and refers to Defs by [member id] when it needs saving.

## Unique across all content. Saves and tile custom data refer to content by this id.
@export var id: StringName
## The name players see.
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D


## Data mistakes in this definition, for the content validator. Subclasses extend the list.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if id.is_empty():
		problems.append("has no id")
	if display_name.is_empty():
		problems.append("has no display_name")
	return problems
