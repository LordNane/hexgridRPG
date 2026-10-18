class_name UnitCard extends PanelContainer
## A battle unit at a glance: name, job and level, and HP and MP with bars.


## A thin bar filled to [member ratio].
class Bar extends Control:
	var ratio := 1.0:
		set(value):
			ratio = clampf(value, 0.0, 1.0)
			queue_redraw()
	var color := Color.WHITE

	func _init(fill: Color) -> void:
		color = fill
		custom_minimum_size = Vector2(60, 3)
		size_flags_vertical = SIZE_SHRINK_CENTER

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(Vector2.ZERO, Vector2(roundf(size.x * ratio), size.y)), color)


var _name := MenuScreen.make_label("")
var _job := MenuScreen.make_label("", &"DimLabel")
var _hp := MenuScreen.make_label("")
var _mp := MenuScreen.make_label("")
var _hp_bar := Bar.new(Color(0.45, 0.85, 0.4))
var _mp_bar := Bar.new(Color(0.45, 0.65, 1.0))
var _unit: BattleUnit


func _init() -> void:
	theme_type_variation = &"InsetPanel"
	custom_minimum_size = Vector2(150, 0)
	size_flags_vertical = SIZE_SHRINK_END
	mouse_filter = MOUSE_FILTER_IGNORE
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 0)
	add_child(rows)
	rows.add_child(_name)
	rows.add_child(_job)
	for pair: Array in [[_hp, _hp_bar], [_mp, _mp_bar]]:
		var row := HBoxContainer.new()
		(pair[0] as Label).custom_minimum_size.x = 64
		row.add_child(pair[0])
		row.add_child(pair[1])
		rows.add_child(row)
	modulate.a = 0.0


## Shows [param unit], or fades the card out when null. It keeps its place either way, so the
## layout around it doesn't shift.
func show_unit(unit: BattleUnit) -> void:
	_unit = unit
	modulate.a = 1.0 if unit else 0.0
	refresh()


## Redraws the card for its unit's current HP and MP.
func refresh() -> void:
	if _unit == null:
		return
	var character := _unit.character
	_name.text = character.name
	_name.theme_type_variation = &"" if _unit.team == BattleUnit.Team.PARTY else &"WarningLabel"
	_job.text = "%s  ·  Level %d" % [character.job.display_name, character.level]
	_hp.text = "HP %d/%d" % [character.hp, character.max_hp()]
	_mp.text = "MP %d/%d" % [character.mp, character.max_mp()]
	_hp_bar.ratio = float(character.hp) / maxf(1.0, character.max_hp())
	_mp_bar.ratio = float(character.mp) / maxf(1.0, character.max_mp())
