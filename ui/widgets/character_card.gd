class_name CharacterCard extends VBoxContainer
## A character at a glance: their look, name, job and level, HP and MP, stats, gear and abilities.
## Redraws whenever the character changes.

const CARD_STATS: Array[Stat.Id] = [
	Stat.Id.ATTACK, Stat.Id.DEFENSE, Stat.Id.MAGIC, Stat.Id.RESIST,
	Stat.Id.SPEED, Stat.Id.EVASION, Stat.Id.MOVE, Stat.Id.JUMP,
]

var _character: Character
var _sprite := TextureRect.new()
var _name := MenuScreen.make_label("", &"HeaderLabel")
var _job := MenuScreen.make_label("", &"DimLabel")
var _vitals := MenuScreen.make_label("")
var _stats := StatsPanel.new(CARD_STATS, 2)
var _gear := GridContainer.new()
var _loadout := GridContainer.new()


func _init() -> void:
	add_theme_constant_override("separation", 3)
	var header := HBoxContainer.new()
	_sprite.custom_minimum_size = Vector2(32, 48)
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(_sprite)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 0)
	for label: Label in [_name, _job, _vitals]:
		titles.add_child(label)
	header.add_child(titles)
	add_child(header)
	add_child(_stats)
	add_child(HSeparator.new())
	for grid: GridContainer in [_gear, _loadout]:
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 0)
	add_child(_gear)
	add_child(HSeparator.new())
	add_child(_loadout)


## Shows [param character] from now on, following their changes.
func show_character(character: Character) -> void:
	if _character == character:
		return
	if _character:
		_character.changed.disconnect(_refresh)
	_character = character
	_character.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var character := _character
	var job := character.job
	_sprite.texture = job.sprite
	_name.text = character.name
	_job.text = "%s  ·  Level %d" % [job.display_name, character.level]
	_vitals.text = "HP %d/%d   MP %d/%d" % [character.hp, character.max_hp(), character.mp, character.max_mp()]
	_stats.show_stats(character.stats())
	_clear(_gear)
	for slot: EquipmentDef.Slot in EquipmentDef.slots():
		var item := character.equipment.get_item(slot)
		_add_row(_gear, EquipmentDef.slot_name(slot), item.display_name if item else Describe.NOTHING)
	_clear(_loadout)
	var commands := job.command_name
	if character.loadout.secondary:
		commands += ", " + character.loadout.secondary.command_name
	_add_row(_loadout, "Commands", commands)
	for kind: AbilityDef.Kind in AbilityLoadout.SLOTS:
		var ability := character.loadout.get_ability(kind)
		_add_row(_loadout, AbilityDef.kind_name(kind), ability.display_name if ability else Describe.NOTHING)


static func _add_row(grid: GridContainer, heading: String, value: String) -> void:
	grid.add_child(MenuScreen.make_label(heading, &"DimLabel"))
	grid.add_child(MenuScreen.make_label(value))


static func _clear(grid: GridContainer) -> void:
	for child: Node in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
