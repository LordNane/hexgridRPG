@tool
class_name EntryMarker extends HexMarker
## A named arrival point on an authored map, such as "start". Only visible in the editor.

const COLOR := Color(0.35, 0.9, 1.0)
const LABEL_SIZE := 8

@export var entry_name: StringName = &"start":
	set(value):
		entry_name = value
		queue_redraw()


func _ready() -> void:
	super()
	visible = Engine.is_editor_hint()


func _draw() -> void:
	draw_line(Vector2(0, 2), Vector2(0, -12), COLOR)
	draw_colored_polygon(PackedVector2Array([Vector2(1, -12), Vector2(7, -9), Vector2(1, -6)]), COLOR)
	draw_string(ThemeDB.fallback_font, Vector2(8, -6), String(entry_name), HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, COLOR)
