class_name AbilitiesScreen extends MenuScreen
## Choosing what one character takes into battle. Their job sets the main command; choose a second
## command from another job they've learned actions in, and a reaction, support and movement
## ability from any they've learned. Highlighting a choice shows what it does and previews stats.

const PRIMARY := &"primary"
const SECONDARY := &"secondary"
## The loadout slot each ability kind goes in, by the value its slot option stands for.
const SLOT_KINDS: Dictionary[StringName, AbilityDef.Kind] = {
	&"reaction": AbilityDef.Kind.REACTION,
	&"support": AbilityDef.Kind.SUPPORT,
	&"movement": AbilityDef.Kind.MOVEMENT,
}

var _character: Character
var _session: GameSession
var _slots := MenuList.new()
var _options := MenuList.new()
var _details := MenuScreen.make_label("", &"", true)
var _stats := StatsPanel.new()
## Whether the options for [member _slot] are listed; otherwise a slot is being chosen.
var _choosing := false
var _slot := PRIMARY


func _init(character: Character, session: GameSession) -> void:
	super()
	_character = character
	_session = session


func _ready() -> void:
	var row := _build_frame("Abilities: %s" % _character.name)
	_add_column(row, "Slots", 190).add_child(_slots)
	_add_column(row, "Learned", 150).add_child(_options)
	var details := _add_column(row, "Details")
	_details.custom_minimum_size.y = 64
	details.add_child(_details)
	details.add_child(HSeparator.new())
	details.add_child(_stats)
	_slots.highlighted.connect(_on_slot_highlighted)
	_slots.chosen.connect(_on_slot_chosen)
	_options.highlighted.connect(_on_option_highlighted)
	_options.chosen.connect(_on_option_chosen)
	_fill_slots()
	_stats.show_stats(_character.stats())


func default_focus() -> Control:
	return _slots.first()


func cancel() -> void:
	if _choosing:
		_close_slot()
	else:
		super()


func _fill_slots() -> void:
	_slots.clear()
	var loadout := _character.loadout
	_slots.add_option("Command", PRIMARY, _character.job.command_name)
	_slots.add_option("Second", SECONDARY, loadout.secondary.command_name if loadout.secondary else Describe.NOTHING)
	for slot: StringName in SLOT_KINDS:
		var ability := loadout.get_ability(SLOT_KINDS[slot])
		_slots.add_option(AbilityDef.kind_name(SLOT_KINDS[slot]), slot, ability.display_name if ability else Describe.NOTHING)
	_slots.set_focusable(not _choosing)


func _on_slot_highlighted(value: Variant) -> void:
	var slot: StringName = value
	var loadout := _character.loadout
	if slot == PRIMARY:
		_details.text = Describe.command(_character.learned_actions(_character.job))
		show_hint("%s's job sets the main command. Change jobs to change it." % _character.name)
	elif slot == SECONDARY:
		_details.text = Describe.command(_character.learned_actions(loadout.secondary)) if loadout.secondary else ""
		show_hint("A second command, from another job's learned actions.")
	else:
		var ability := loadout.get_ability(SLOT_KINDS[slot])
		_details.text = Describe.ability(ability) if ability else ""
		show_hint("Choose a %s ability from those %s has learned." % [String(slot), _character.name])
	_stats.show_stats(_character.stats())


## Lists the choices for the chosen slot: nothing, then each learned option.
func _on_slot_chosen(value: Variant) -> void:
	var slot: StringName = value
	if slot == PRIMARY:
		show_hint("%s's job sets the main command. Change jobs to change it." % _character.name, true)
		return
	_slot = slot
	_options.clear()
	_options.add_option("None", null)
	if slot == SECONDARY:
		for job: JobDef in _character.secondary_options():
			_options.add_option(job.command_name, job)
	else:
		for ability: AbilityDef in _character.learned_of_kind(SLOT_KINDS[slot]):
			_options.add_option(ability.display_name, ability)
	_choosing = true
	_slots.set_focusable(false)
	var current: Resource
	if slot == SECONDARY:
		current = _character.loadout.secondary
	else:
		current = _character.loadout.get_ability(SLOT_KINDS[slot])
	var option := _options.option_for(current)
	(option if option else _options.first()).grab_focus()


func _on_option_highlighted(value: Variant) -> void:
	if _slot == SECONDARY:
		var job := value as JobDef
		_details.text = Describe.command(_character.learned_actions(job)) if job else "No second command."
		show_hint(_character.can_set_secondary(job), true)
		_stats.show_stats(_character.stats())
		return
	var kind := SLOT_KINDS[_slot]
	var ability := value as AbilityDef
	_details.text = Describe.ability(ability) if ability else "Leave the slot empty."
	_stats.show_stats(_character.stats(), _character.preview_ability(kind, ability))
	var lost := _character.gear_lost_with_ability(kind, ability)
	show_hint("" if lost.is_empty() else "This takes off the %s." % Describe.names(lost), true)


func _on_option_chosen(value: Variant) -> void:
	var before := _character.equipment.items()
	var reason := ""
	if _slot == SECONDARY:
		reason = _character.set_secondary(value as JobDef)
	elif value == null:
		_character.unequip_ability(SLOT_KINDS[_slot], _session.inventory)
	else:
		reason = _character.equip_ability(value as AbilityDef, _session.inventory)
	if reason:
		show_hint(reason, true)
		return
	_close_slot()
	show_hint(Describe.returned(_gear_taken_off(_character, before)))


func _close_slot() -> void:
	_choosing = false
	_options.clear()
	_fill_slots()
	_slots.option_for(_slot).grab_focus()
