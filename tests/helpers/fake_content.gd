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


static func map_def(id: StringName) -> MapDef:
	var def := MapDef.new()
	_name(def, id)
	return def


static func enter(map: MapDef, entry: StringName = &"start") -> EnterMapAction:
	var action := EnterMapAction.new()
	action.map = map
	action.entry = entry
	return action


static func flag_condition(flag: StringName) -> FlagCondition:
	var condition := FlagCondition.new()
	condition.flag = flag
	return condition


static func modifier(stat: Stat.Id, value: float, kind: StatModifier.Kind = StatModifier.Kind.FLAT) -> StatModifier:
	return StatModifier.new(stat, value, kind)


## An action that deals damage of [param power] to whoever stands [param range_min] to
## [param range_max] steps away.
static func attack(id: StringName, range_min: int = 1, range_max: int = 1, power: float = 1.0) -> AbilityDef:
	var def := ability(id)
	def.targeting = TargetingDef.new()
	def.targeting.range_min = range_min
	def.targeting.range_max = range_max
	var damage := DamageEffect.new()
	damage.power = power
	def.effects = [damage]
	return def


static func ability(id: StringName, kind: AbilityDef.Kind = AbilityDef.Kind.ACTION, modifiers: Array[StatModifier] = []) -> AbilityDef:
	var def := AbilityDef.new()
	_name(def, id)
	def.kind = kind
	def.modifiers = modifiers
	return def


## A job using gear tagged [param equip_tags] that teaches [param abilities] for 100 JP each. Its
## command is called "<Name> Arts", and it punches when unarmed.
static func job(id: StringName, equip_tags: Array[StringName] = [], abilities: Array[AbilityDef] = []) -> JobDef:
	var def := JobDef.new()
	_name(def, id)
	def.command_name = def.display_name + " Arts"
	def.equip_tags = equip_tags
	def.unarmed_attack = attack(StringName(String(id) + "_punch"))
	for taught: AbilityDef in abilities:
		def.abilities[taught] = 100
	return def


static func gear(id: StringName, slot: EquipmentDef.Slot, equip_tag: StringName = &"", modifiers: Array[StatModifier] = []) -> EquipmentDef:
	var def := EquipmentDef.new()
	_name(def, id)
	def.slot = slot
	def.equip_tag = equip_tag
	def.modifiers = modifiers
	return def


## A weapon tagged [param equip_tag] that adds [param attack_bonus] Attack, with an attack of its own.
static func weapon(id: StringName, equip_tag: StringName, attack_bonus: int = 0, two_handed: bool = false) -> WeaponDef:
	var def := WeaponDef.new()
	_name(def, id)
	def.equip_tag = equip_tag
	def.two_handed = two_handed
	def.attack = attack(StringName(String(id) + "_attack"))
	if attack_bonus != 0:
		def.modifiers = [modifier(Stat.Id.ATTACK, attack_bonus)]
	return def


static func prop(id: StringName, blocks_movement: bool = true) -> PropDef:
	var def := PropDef.new()
	_name(def, id)
	def.blocks_movement = blocks_movement
	return def


static func enemy(id: StringName, enemy_job: JobDef, gold: int = 0) -> EnemyDef:
	var def := EnemyDef.new()
	_name(def, id)
	def.job = enemy_job
	def.base_stats = {Stat.Id.HP: 40, Stat.Id.MP: 10, Stat.Id.ATTACK: 10, Stat.Id.DEFENSE: 6, Stat.Id.SPEED: 6}
	def.gold = gold
	return def


static func encounter(id: StringName, enemies: Array[EnemyDef]) -> EncounterDef:
	var def := EncounterDef.new()
	_name(def, id)
	def.enemies = enemies
	return def


## Own stats for a test character: 40 HP, 10 MP, 10 Attack, 6 Defense, 8 Magic, 5 Resist, 6 Speed.
static func own_stats() -> StatBlock:
	return StatBlock.new({
		Stat.Id.HP: 40, Stat.Id.MP: 10, Stat.Id.ATTACK: 10, Stat.Id.DEFENSE: 6,
		Stat.Id.MAGIC: 8, Stat.Id.RESIST: 5, Stat.Id.SPEED: 6,
	})


## A registry holding [param defs], for loading saves in tests.
static func registry(defs: Array[Def]) -> ContentRegistry:
	var content := ContentRegistry.new()
	for def: Def in defs:
		content.add(def)
	return content


## A map of [param terrain_def] covering every hex within [param radius] of the origin.
static func uniform_map(radius: int, terrain_def: TerrainDef, map_id: StringName = &"test") -> ExploreMap:
	var map := ExploreMap.new(map_id)
	for hex: Vector2i in Hex.disc(Vector2i.ZERO, radius):
		map.set_terrain(hex, terrain_def)
	return map


static func _name(def: Def, id: StringName) -> void:
	def.id = id
	def.display_name = String(id).capitalize()
