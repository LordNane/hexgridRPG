@tool
@abstract
class_name SpawnMarker extends HexMarker
## Where a unit starts a battle on an authored BattleArena: a PartySpawn or an EnemySpawn. Units
## take the spawns of their side in scene order, the number drawn on each. Only visible in the editor.

const RADIUS := 6.0

## The way a unit starting here faces.
@export var facing: Hex.Dir = Hex.Dir.SE:
	set(value):
		facing = value
		queue_redraw()


## Which side starts here.
@abstract func team() -> BattleUnit.Team


func _ready() -> void:
	super()
	visible = Engine.is_editor_hint()


func _notification(what: int) -> void:
	super(what)
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		queue_redraw()


func _draw() -> void:
	var color := Color(0.4, 0.75, 1.0) if team() == BattleUnit.Team.PARTY else Color(1.0, 0.4, 0.35)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 16, color)
	var layout := HexLayout.new()
	var toward := (layout.to_pixel(Hex.OFFSETS[facing]) - layout.to_pixel(Vector2i.ZERO)).normalized()
	draw_line(Vector2.ZERO, toward * (RADIUS + 5.0), color)
	draw_string(ThemeDB.fallback_font, Vector2(-3, 4), str(_order() + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, color)


## This marker's place among its side's spawns.
func _order() -> int:
	var arena := owner as BattleArena
	if arena == null or arena.markers == null:
		return 0
	var order := 0
	for marker: HexMarker in HexMarker.find_all(arena.markers):
		if marker == self:
			return order
		if marker is SpawnMarker and (marker as SpawnMarker).team() == team():
			order += 1
	return order
