class_name PartyScreen extends MenuScreen
## The party menu's first screen: everyone in the party, with the highlighted member's details.
## Choose a member to manage their gear, job and abilities, or look through the inventory.

const INVENTORY := &"inventory"
const CLOSE := &"close"

var _session: GameSession
var _content: ContentRegistry
var _list := MenuList.new()
var _card := CharacterCard.new()
## The member last highlighted, focused again when coming back from their screens.
var _current: Character


func _init(session: GameSession, content: ContentRegistry) -> void:
	super()
	_session = session
	_content = content


func _ready() -> void:
	var row := _build_frame("Party")
	_add_column(row, "", 170).add_child(_list)
	_add_column(row, "").add_child(_card)
	_list.highlighted.connect(_on_highlighted)
	_list.chosen.connect(_on_chosen)
	_fill()


func default_focus() -> Control:
	var option := _list.option_for(_current)
	return option if option else _list.first()


func revealed() -> void:
	_fill()


func _fill() -> void:
	_list.clear()
	for member: Character in _session.party.members():
		_list.add_option(member.name, member, "%s  Lv %d" % [member.job.display_name, member.level])
	_list.add_heading("")
	_list.add_option("Inventory", INVENTORY)
	_list.add_option("Close", CLOSE)


func _on_highlighted(value: Variant) -> void:
	if value is Character:
		_current = value
		_card.show_character(_current)
		show_hint("%d gold" % _session.gold)
	elif value == INVENTORY:
		show_hint("Everything the party carries.")
	else:
		show_hint("")


func _on_chosen(value: Variant) -> void:
	if value is Character:
		stack.push(CharacterScreen.new(value, _session, _content))
	elif value == INVENTORY:
		stack.push(InventoryScreen.new(_session, _content))
	elif value == CLOSE:
		stack.close()
