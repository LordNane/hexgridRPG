class_name JobsScreen extends MenuScreen
## Changing one character's job. Highlighting a job shows what it teaches and the gear it uses, and
## previews the stats it would give; a locked job says what unlocks it.

var _character: Character
var _session: GameSession
var _jobs: Array[JobDef] = []
var _list := MenuList.new()
var _abilities := GridContainer.new()
var _gear := MenuScreen.make_label("", &"", true)
var _stats := StatsPanel.new()


func _init(character: Character, session: GameSession, content: ContentRegistry) -> void:
	super()
	_character = character
	_session = session
	_jobs.assign(content.all_of(JobDef))
	_jobs.sort_custom(func(a: JobDef, b: JobDef) -> bool: return a.display_name < b.display_name)


func _ready() -> void:
	var row := _build_frame("Jobs: %s" % _character.name)
	_add_column(row, "Job", 140).add_child(_list)
	var taught := _add_column(row, "Teaches", 190)
	_abilities.columns = 3
	_abilities.add_theme_constant_override("h_separation", 8)
	_abilities.add_theme_constant_override("v_separation", 0)
	taught.add_child(_abilities)
	taught.add_child(HSeparator.new())
	taught.add_child(_gear)
	_add_column(row, "Stats").add_child(_stats)
	_list.highlighted.connect(_on_highlighted)
	_list.chosen.connect(_on_chosen)
	_fill()


func default_focus() -> Control:
	return _list.option_for(_character.job)


func _fill() -> void:
	_list.clear()
	for job: JobDef in _jobs:
		var locked := not job.is_unlocked(_session, _character)
		var detail := "now" if job == _character.job else ("locked" if locked else "")
		_list.add_option(job.display_name, job, detail, null, locked)


func _on_highlighted(value: Variant) -> void:
	var job: JobDef = value
	_show_abilities(job)
	_gear.text = "Uses: " + ", ".join(PackedStringArray(job.equip_tags))
	_stats.show_stats(_character.stats(), _character.preview_job(job))
	var reason := _character.can_change_job(job, _session)
	if reason and job != _character.job:
		show_hint(reason, true)
		return
	var lost: Array[EquipmentDef] = []
	if job != _character.job:
		lost = _character.gear_lost_in_job(job)
	var change := "" if lost.is_empty() else "Changing takes off the %s." % Describe.names(lost)
	show_hint(("%s %s" % [job.description, change]).strip_edges())


func _on_chosen(value: Variant) -> void:
	var job: JobDef = value
	var before := _character.equipment.items()
	var reason := _character.change_job(job, _session)
	if reason:
		show_hint(reason, true)
		return
	_fill()
	_list.option_for(job).grab_focus()
	var returned := Describe.returned(_gear_taken_off(_character, before))
	show_hint("%s is now %s. %s" % [_character.name, English.with_article(job.display_name), returned])


## Lists what [param job] teaches, with JP costs, marking what the character has learned.
func _show_abilities(job: JobDef) -> void:
	for child: Node in _abilities.get_children():
		_abilities.remove_child(child)
		child.queue_free()
	for ability: AbilityDef in job.abilities:
		var learned := _character.knows(ability)
		_abilities.add_child(MenuScreen.make_label(ability.display_name, &"" if learned else &"DimLabel"))
		_abilities.add_child(MenuScreen.make_label(AbilityDef.kind_name(ability.kind), &"DimLabel"))
		_abilities.add_child(MenuScreen.make_label("learned" if learned else "%d JP" % job.jp_cost(ability), &"DimLabel"))
