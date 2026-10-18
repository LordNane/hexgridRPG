class_name MapCamera extends Camera2D
## Follows a target and lets the player look around with the camera keys, a stick or a middle-mouse
## drag. Zooms in whole steps so pixels stay crisp, and never shows past the map's edges.

## Pixels per second when panning with keys or a stick.
@export var pan_speed := 220.0
## Zoom steps. Whole numbers keep pixel art crisp.
@export var zoom_levels: Array[int] = [1, 2]

## The node to follow, usually the party token.
var target: Node2D

var _look_offset := Vector2.ZERO
var _zoom_index := 0
var _bounds := Rect2()


## Keeps the view inside [param bounds], in world pixels.
func set_bounds(bounds: Rect2) -> void:
	_bounds = bounds
	limit_left = floori(bounds.position.x)
	limit_top = floori(bounds.position.y)
	limit_right = ceili(bounds.end.x)
	limit_bottom = ceili(bounds.end.y)


## Looks back at the target, for example when the party sets off.
func recenter() -> void:
	_look_offset = Vector2.ZERO


func _process(delta: float) -> void:
	var pan := Input.get_vector(&"camera_pan_left", &"camera_pan_right", &"camera_pan_up", &"camera_pan_down")
	_look_offset += pan * pan_speed * delta / zoom.x
	if target == null:
		return
	var wanted := target.global_position + _look_offset
	if _bounds.has_area():
		wanted = wanted.clamp(_bounds.position, _bounds.end)
		_look_offset = wanted - target.global_position
	global_position = wanted


func _unhandled_input(event: InputEvent) -> void:
	var drag := event as InputEventMouseMotion
	if drag and drag.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		_look_offset -= drag.relative / zoom.x
	elif event.is_action_pressed(&"camera_zoom_in"):
		_set_zoom_index(_zoom_index + 1)
	elif event.is_action_pressed(&"camera_zoom_out"):
		_set_zoom_index(_zoom_index - 1)


func _set_zoom_index(index: int) -> void:
	_zoom_index = clampi(index, 0, zoom_levels.size() - 1)
	zoom = Vector2.ONE * zoom_levels[_zoom_index]
