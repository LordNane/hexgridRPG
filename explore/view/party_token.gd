class_name PartyToken extends Node2D
## The party on an exploration map. Walks a route one hex at a time, reporting each step so the
## caller can reveal fog or stop the walk early.

## Emitted after each step, once the token stands on [param hex].
signal stepped(hex: Vector2i)

## Seconds per step.
@export var step_time := 0.14

## The hex the token stands on.
var hex: Vector2i
var is_walking := false

var _layout: HexLayout
var _stop_requested := false

@onready var _sprite: Sprite2D = $Sprite


## Puts the token on [param target] at once; [param layout] places it from now on.
func place(layout: HexLayout, target: Vector2i) -> void:
	_layout = layout
	hex = target
	position = layout.to_pixel(target)


## Walks [param route], which starts at the token's hex, to its end or until [method stop] is called.
func walk(route: Array[Vector2i]) -> void:
	is_walking = true
	_stop_requested = false
	for i: int in range(1, route.size()):
		var target := _layout.to_pixel(route[i])
		if not is_equal_approx(target.x, position.x):
			_sprite.flip_h = target.x < position.x
		var tween := create_tween()
		tween.tween_property(self, "position", target, step_time)
		await tween.finished
		hex = route[i]
		stepped.emit(hex)
		if _stop_requested:
			break
	is_walking = false


## Ends the walk after the current step.
func stop() -> void:
	_stop_requested = true
