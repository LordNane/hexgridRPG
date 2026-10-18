class_name InventoryScreen extends MenuScreen
## Everything the party carries, grouped by kind, with what the highlighted item does, which jobs
## can use it and who's wearing one.

## The groups items are listed in, by heading.
const GROUPS: Array[String] = ["Items", "Weapons", "Shields", "Head", "Body", "Accessories"]

var _session: GameSession
var _content: ContentRegistry
var _list := MenuList.new()
var _icon := TextureRect.new()
var _name := MenuScreen.make_label("", &"HeaderLabel")
var _kind := MenuScreen.make_label("", &"DimLabel")
var _text := MenuScreen.make_label("", &"", true)
var _users := MenuScreen.make_label("", &"DimLabel", true)


func _init(session: GameSession, content: ContentRegistry) -> void:
	super()
	_session = session
	_content = content


func _ready() -> void:
	var row := _build_frame("Inventory")
	_add_column(row, "", 230).add_child(_list)
	var details := _add_column(row, "")
	var header := HBoxContainer.new()
	_icon.custom_minimum_size = Vector2(32, 32)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(_icon)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 0)
	titles.add_child(_name)
	titles.add_child(_kind)
	header.add_child(titles)
	details.add_child(header)
	details.add_child(_text)
	details.add_child(HSeparator.new())
	details.add_child(_users)
	_list.highlighted.connect(_on_highlighted)
	_fill()
	show_hint("%d gold" % _session.gold)


func _fill() -> void:
	var grouped: Dictionary[String, Array] = {}
	var inventory := _session.inventory
	for item_id: StringName in inventory.item_ids():
		var item := _content.get_def(item_id) as ItemDef
		if item:
			var group := _group_of(item)
			if not grouped.has(group):
				grouped[group] = []
			grouped[group].append(item)
	if grouped.is_empty():
		_list.add_heading("The party carries nothing.")
	for group: String in GROUPS:
		if not grouped.has(group):
			continue
		_list.add_heading(group)
		for item: ItemDef in grouped[group]:
			_list.add_option(item.display_name, item, "×%d" % inventory.count_of(item.id), item.icon)


func _on_highlighted(value: Variant) -> void:
	var item: ItemDef = value
	_icon.texture = item.icon
	_name.text = item.display_name
	_kind.text = Describe.item_kind(item)
	_text.text = Describe.item(item)
	_users.text = _who_uses(item)


## Which jobs can use [param item] and which party members wear one, for gear.
func _who_uses(item: ItemDef) -> String:
	var gear := item as EquipmentDef
	if gear == null:
		return ""
	var jobs := PackedStringArray()
	for def: Def in _content.all_of(JobDef):
		if gear.equip_tag.is_empty() or (def as JobDef).equip_tags.has(gear.equip_tag):
			jobs.append(def.display_name)
	jobs.sort()
	var lines := PackedStringArray(["Anyone can use it." if gear.equip_tag.is_empty() else "Used by: %s." % English.list(jobs)])
	var wearers := PackedStringArray()
	for member: Character in _session.party.members():
		if member.equipment.items().has(gear):
			wearers.append(member.name)
	if not wearers.is_empty():
		lines.append("Worn by %s." % English.list(wearers))
	return "\n".join(lines)


static func _group_of(item: ItemDef) -> String:
	var gear := item as EquipmentDef
	if gear == null:
		return GROUPS[0]
	match gear.slot:
		EquipmentDef.Slot.WEAPON:
			return GROUPS[1]
		EquipmentDef.Slot.SHIELD:
			return GROUPS[2]
		EquipmentDef.Slot.HEAD:
			return GROUPS[3]
		EquipmentDef.Slot.BODY:
			return GROUPS[4]
		_:
			return GROUPS[5]
