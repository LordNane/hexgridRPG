class_name UnitView extends Node2D
## One unit on the 2.5D battle map: its job's figure standing on its hex, a ring in its side's color
## at its feet and a small HP bar. It sits on the hex's ground point, raised by [member lift], so a
## y-sorted parent draws it just after its hex. BattleView moves it around.

const PARTY_COLOR := Color(0.4, 0.75, 1.0)
const ENEMY_COLOR := Color(1.0, 0.42, 0.35)
## Enemies share the party's job figures until they have art of their own; this tint tells them apart.
const ENEMY_TINT := Color(1.0, 0.72, 0.68)
const RING_RADIUS := 7.0
const BAR_WIDTH := 14.0

var unit: BattleUnit
## How far above its ground point the unit stands: its hex's height in pixels.
var lift := 0.0:
	set(value):
		lift = value
		_sprite.position.y = -lift
		queue_redraw()

var _sprite := Sprite2D.new()


func _init(battle_unit: BattleUnit) -> void:
	unit = battle_unit
	_sprite.texture = unit.character.job.sprite
	_sprite.centered = true
	if _sprite.texture:
		_sprite.offset = Vector2(0, -_sprite.texture.get_height() / 2.0 + 2.0)
	if unit.team == BattleUnit.Team.ENEMY:
		_sprite.modulate = ENEMY_TINT
	add_child(_sprite)


## Turns the figure toward [param facing]: art faces right, so westward facings mirror it.
func face(facing: int) -> void:
	if facing == Hex.Dir.NW or facing == Hex.Dir.SW:
		_sprite.flip_h = true
	elif facing == Hex.Dir.NE or facing == Hex.Dir.SE:
		_sprite.flip_h = false


## The figure, for flashes and fades.
func sprite() -> Sprite2D:
	return _sprite


func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	if not unit.is_alive():
		return
	var feet := Vector2(0, -lift)
	draw_set_transform(feet, 0.0, Vector2(1.0, 0.5))
	draw_arc(Vector2.ZERO, RING_RADIUS, 0.0, TAU, 20, PARTY_COLOR if unit.team == BattleUnit.Team.PARTY else ENEMY_COLOR, 1.5)
	draw_set_transform(Vector2.ZERO)
	var ratio := clampf(float(unit.character.hp) / maxf(1.0, unit.character.max_hp()), 0.0, 1.0)
	var bar := Rect2(feet + Vector2(-BAR_WIDTH / 2.0, 3.0), Vector2(BAR_WIDTH, 2.0))
	draw_rect(bar.grow(1.0), Color(0, 0, 0, 0.7))
	var fill := Color(0.45, 0.85, 0.4) if ratio > 0.5 else (Color(0.95, 0.8, 0.3) if ratio > 0.25 else Color(0.95, 0.35, 0.3))
	draw_rect(Rect2(bar.position, Vector2(roundf(BAR_WIDTH * ratio), bar.size.y)), fill)
