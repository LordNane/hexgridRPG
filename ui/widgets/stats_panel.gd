class_name StatsPanel extends GridContainer
## Stats in rows, such as "ATK 12", and optionally what a change would make them: "ATK 12 » 15",
## with the new value colored by whether it's higher or lower.

var _stats: Array[Stat.Id] = []
var _values: Dictionary[Stat.Id, Label] = {}
var _previews: Dictionary[Stat.Id, Label] = {}


## Shows [param stats] (all of them if empty), [param per_row] to a row.
func _init(stats: Array[Stat.Id] = [], per_row: int = 1) -> void:
	if stats.is_empty():
		_stats = Stat.all()
	else:
		_stats = stats
	columns = 3 * per_row
	add_theme_constant_override("h_separation", 6)
	add_theme_constant_override("v_separation", 0)
	for stat: Stat.Id in _stats:
		add_child(MenuScreen.make_label(Stat.short_name(stat), &"DimLabel"))
		var value := MenuScreen.make_label("")
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.custom_minimum_size.x = 18
		add_child(value)
		_values[stat] = value
		var preview := MenuScreen.make_label("")
		preview.custom_minimum_size.x = 30
		add_child(preview)
		_previews[stat] = preview


## Shows [param current], and next to each stat that would change, its value in [param preview].
func show_stats(current: StatBlock, preview: StatBlock = null) -> void:
	for stat: Stat.Id in _stats:
		_values[stat].text = str(current.value(stat))
		var label := _previews[stat]
		if preview and preview.value(stat) != current.value(stat):
			label.text = "» %d" % preview.value(stat)
			label.theme_type_variation = &"UpLabel" if preview.value(stat) > current.value(stat) else &"DownLabel"
		else:
			label.text = ""


## What the panel shows for [param stat], such as "12" or "12 » 15".
func shown_text(stat: Stat.Id) -> String:
	return ("%s %s" % [_values[stat].text, _previews[stat].text]).strip_edges()
