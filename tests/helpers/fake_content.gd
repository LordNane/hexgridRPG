class_name FakeContent
## Builds content definitions in code for tests, with readable defaults. Display names come from ids.


static func terrain(id: StringName, move_cost: float = 1.0, passable: bool = true, blocks_sight: bool = false) -> TerrainDef:
	var def := TerrainDef.new()
	_name(def, id)
	def.move_cost = move_cost
	def.passable = passable
	def.blocks_sight = blocks_sight
	return def


static func feature(id: StringName, extra_move_cost: float = 0.0, blocks_movement: bool = false,
		blocks_sight: bool = false, sight_bonus: int = 0) -> FeatureDef:
	var def := FeatureDef.new()
	_name(def, id)
	def.extra_move_cost = extra_move_cost
	def.blocks_movement = blocks_movement
	def.blocks_sight = blocks_sight
	def.sight_bonus = sight_bonus
	return def


static func region(id: StringName) -> RegionDef:
	var def := RegionDef.new()
	_name(def, id)
	return def


static func item(id: StringName) -> ItemDef:
	var def := ItemDef.new()
	_name(def, id)
	return def


static func poi(id: StringName, actions: Array[PoiAction] = [], trigger: PoiDef.Trigger = PoiDef.Trigger.ON_INTERACT) -> PoiDef:
	var def := PoiDef.new()
	_name(def, id)
	def.actions = actions
	def.trigger = trigger
	return def


static func message(text: String) -> ShowMessageAction:
	var action := ShowMessageAction.new()
	action.text = text
	return action


static func give(item_def: ItemDef, count: int) -> GiveItemsAction:
	var action := GiveItemsAction.new()
	action.items[item_def] = count
	return action


static func flag_condition(flag: StringName) -> FlagCondition:
	var condition := FlagCondition.new()
	condition.flag = flag
	return condition


## A map of [param terrain_def] covering every hex within [param radius] of the origin.
static func uniform_map(radius: int, terrain_def: TerrainDef, map_id: StringName = &"test") -> ExploreMap:
	var map := ExploreMap.new(map_id)
	for hex: Vector2i in Hex.disc(Vector2i.ZERO, radius):
		map.set_terrain(hex, terrain_def)
	return map


static func _name(def: Def, id: StringName) -> void:
	def.id = id
	def.display_name = String(id).capitalize()
