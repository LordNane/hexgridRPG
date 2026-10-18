class_name CharacterScreen extends MenuScreen
## One party member's details, with the screens for changing their gear, job and abilities.

const EQUIP := &"equip"
const JOBS := &"jobs"
const ABILITIES := &"abilities"
const HINTS: Dictionary[StringName, String] = {
	EQUIP: "Change weapons, armor and accessories.",
	JOBS: "Change job, and see what each job teaches.",
	ABILITIES: "Choose a second command, and reaction, support and movement abilities.",
}

var _character: Character
var _session: GameSession
var _content: ContentRegistry
var _list := MenuList.new()
var _card := CharacterCard.new()


func _init(character: Character, session: GameSession, content: ContentRegistry) -> void:
	super()
	_character = character
	_session = session
	_content = content


func _ready() -> void:
	var row := _build_frame(_character.name)
	var commands := _add_column(row, "", 120)
	commands.add_child(_list)
	_list.add_option("Equip", EQUIP)
	_list.add_option("Jobs", JOBS)
	_list.add_option("Abilities", ABILITIES)
	_add_column(row, "").add_child(_card)
	_card.show_character(_character)
	_list.highlighted.connect(func(value: Variant) -> void: show_hint(HINTS[value]))
	_list.chosen.connect(_on_chosen)


func _on_chosen(value: Variant) -> void:
	match value:
		EQUIP:
			stack.push(EquipScreen.new(_character, _session, _content))
		JOBS:
			stack.push(JobsScreen.new(_character, _session, _content))
		ABILITIES:
			stack.push(AbilitiesScreen.new(_character, _session))
