class_name Character extends RefCounted
## One party member (and, from Phase 5, one enemy): their level and job, what they've learned in
## each job, their gear and ability loadout, and their HP and MP. Their stats are worked out from
## all of that with StatBlock.compute.
##
## Change a character only through its methods: they apply the rules, move gear to and from the
## inventory, and emit [signal changed]. Methods that can refuse return the reason as a sentence for
## the player, or an empty string when they succeed. Each has a preview that returns the stats the
## change would give, by trying it on a copy.

## Emitted after anything about the character changes.
signal changed

var name: String
## Read only; [method level_up] raises it.
var level := 1
## The current job. Its actions make up the primary command. Read only; use [method change_job].
var job: JobDef
## Read only; use [method equip] and [method unequip].
var equipment := Equipment.new()
## Read only; use [method set_secondary], [method equip_ability] and [method unequip_ability].
var loadout := AbilityLoadout.new()
## Current HP, kept between 0 and the maximum.
var hp: int:
	get:
		return _hp
	set(value):
		_hp = clampi(value, 0, max_hp())
		changed.emit()
## Current MP, kept between 0 and the maximum.
var mp: int:
	get:
		return _mp
	set(value):
		_mp = clampi(value, 0, max_mp())
		changed.emit()

## The character's own stats: they grow with each level, and their job scales them.
var _own: StatBlock
var _progress: Dictionary[JobDef, JobProgress] = {}
## The final stats, until something changes.
var _stats: StatBlock
var _hp := 0
var _mp := 0


## A character at level 1 in [param start_job] with [param own] as their own stats, fully rested.
func _init(character_name: String, start_job: JobDef, own: StatBlock) -> void:
	assert(start_job != null, "Every character has a job.")
	name = character_name
	job = start_job
	_own = own.duplicate()
	progress(job)
	_hp = max_hp()
	_mp = max_mp()


## The character [param def] describes, at its level and wearing its gear, fully rested. Each
## learned ability is recorded under the job that teaches it, looked up in [param content].
static func from_def(def: CharacterDef, content: ContentRegistry) -> Character:
	var character := Character.new(def.display_name, def.job, StatBlock.new(def.base_stats))
	for _level: int in def.level - 1:
		character.level_up()
	for ability: AbilityDef in def.learned:
		var teacher := def.job if def.job.teaches(ability) else _job_teaching(ability, content)
		if teacher:
			character.learn(teacher, ability)
		else:
			push_warning("%s knows \"%s\", but no job teaches it." % [def.id, ability.id])
	for item: EquipmentDef in def.equipment:
		character._put(item.slot, item)
	character.restore()
	return character


# --- Stats ------------------------------------------------------------------------------------


## The character's final stats: their own stats shaped by their job, plus every modifier from gear
## and equipped abilities.
func stats() -> StatBlock:
	if _stats == null:
		_stats = StatBlock.compute(base_stats(), modifiers())
	return _stats


## Their stats from level and job alone, before gear and abilities.
func base_stats() -> StatBlock:
	return job.base_stats(_own)


## Their own stats, before their job scales them.
func own_stats() -> StatBlock:
	return _own.duplicate()


## Every stat modifier from gear and equipped abilities. Battles add statuses to these.
func modifiers() -> Array[StatModifier]:
	var found := equipment.modifiers()
	found.append_array(loadout.modifiers())
	return found


func max_hp() -> int:
	return stats().value(Stat.Id.HP)


func max_mp() -> int:
	return stats().value(Stat.Id.MP)


## Gains a level: the current job's growth adds to the character's own stats, and HP and MP rise
## as much as their maximums do.
func level_up() -> void:
	var old_hp := max_hp()
	var old_mp := max_mp()
	level += 1
	for stat: Stat.Id in job.stat_growth:
		_own.set_value(stat, _own.exact(stat) + job.stat_growth[stat])
	_stats = null
	_hp += max_hp() - old_hp
	_mp += max_mp() - old_mp
	_refresh()


## Fully restores HP and MP, as at an inn.
func restore() -> void:
	_hp = max_hp()
	_mp = max_mp()
	changed.emit()


# --- Jobs and learning -----------------------------------------------------------------------


## What the character has gained in [param in_job]. Read only; use [method learn].
func progress(in_job: JobDef) -> JobProgress:
	if not _progress.has(in_job):
		_progress[in_job] = JobProgress.new()
	return _progress[in_job]


## Every job the character has been in or learned from, in the order they first did.
func jobs() -> Array[JobDef]:
	var found: Array[JobDef] = []
	found.assign(_progress.keys())
	return found


## Records [param ability] as learned from [param from_job], which must teach it. Spending JP on it
## arrives in Phase 8.
func learn(from_job: JobDef, ability: AbilityDef) -> void:
	assert(from_job.teaches(ability), "%s doesn't teach %s." % [from_job.id, ability.id])
	progress(from_job).learn(ability)
	changed.emit()


## Whether the character has learned [param ability] from any job.
func knows(ability: AbilityDef) -> bool:
	for job_progress: JobProgress in _progress.values():
		if job_progress.knows(ability):
			return true
	return false


## The actions learned from [param from_job], in its command's order.
func learned_actions(from_job: JobDef) -> Array[AbilityDef]:
	var found: Array[AbilityDef] = []
	if _progress.has(from_job):
		for ability: AbilityDef in from_job.actions():
			if _progress[from_job].knows(ability):
				found.append(ability)
	return found


## Every ability of [param kind] learned from any job, for the loadout's slots.
func learned_of_kind(kind: AbilityDef.Kind) -> Array[AbilityDef]:
	var found: Array[AbilityDef] = []
	for job_progress: JobProgress in _progress.values():
		for ability: AbilityDef in job_progress.learned():
			if ability.kind == kind and not found.has(ability):
				found.append(ability)
	return found


## Why the character can't change to [param new_job] now, or an empty string.
func can_change_job(new_job: JobDef, session: GameSession) -> String:
	if new_job == job:
		return "%s is already %s." % [name, English.with_article(job.display_name)]
	if not new_job.is_unlocked(session, self):
		return new_job.unlock_hint if new_job.unlock_hint else "%s isn't unlocked yet." % new_job.display_name
	return ""


## Changes to [param new_job]. Gear it can't use goes back to the session's inventory, and if its
## command was the secondary one, the secondary is cleared. Returns why it can't, or "".
func change_job(new_job: JobDef, session: GameSession) -> String:
	var reason := can_change_job(new_job, session)
	if reason:
		return reason
	_return_to(session.inventory, _switch_job(new_job))
	_refresh()
	return ""


## The stats the character would have in [param new_job], without the gear it can't use.
func preview_job(new_job: JobDef) -> StatBlock:
	var trial := _copy()
	trial._switch_job(new_job)
	return trial.stats()


## The gear [method change_job] to [param new_job] would take off.
func gear_lost_in_job(new_job: JobDef) -> Array[EquipmentDef]:
	return _copy()._switch_job(new_job)


# --- Gear -------------------------------------------------------------------------------------


## Kinds of gear the character may use: their job's, plus any an equipped ability adds.
func equip_tags() -> Array[StringName]:
	var allowed := job.equip_tags.duplicate()
	allowed.append_array(loadout.equip_tags())
	return allowed


## What the Attack command does: the weapon's attack, or the job's unarmed one.
func attack_ability() -> AbilityDef:
	var weapon := equipment.weapon()
	return weapon.attack if weapon else job.unarmed_attack


## Traits the character's gear grants, such as &"flying". Battles use them from Phase 6.
func tags() -> Array[StringName]:
	return equipment.granted_tags()


## Wears [param item], taken from [param inventory], in [param slot]. Whatever it replaces goes back
## to the inventory, and so does a shield when a two-handed weapon goes on. Returns why it can't,
## or "".
func equip(slot: EquipmentDef.Slot, item: EquipmentDef, inventory: Inventory) -> String:
	assert(item != null, "Use unequip to take gear off.")
	var reason := EquipRules.can_equip(self, item, slot)
	if reason.is_empty() and inventory.count_of(item.id) < 1:
		reason = "There's no %s in the inventory." % item.display_name
	if reason:
		return reason
	inventory.remove(item.id)
	_return_to(inventory, _put(slot, item))
	_refresh()
	return ""


## Takes off whatever is in [param slot] and puts it in [param inventory].
func unequip(slot: EquipmentDef.Slot, inventory: Inventory) -> void:
	var removed := _put(slot, null)
	if not removed.is_empty():
		_return_to(inventory, removed)
		_refresh()


## The stats the character would have with [param item] in [param slot], or with the slot empty
## when it's null. Doesn't check the rules.
func preview_equip(slot: EquipmentDef.Slot, item: EquipmentDef) -> StatBlock:
	var trial := _copy()
	trial._put(slot, item)
	return trial.stats()


# --- Ability loadout -------------------------------------------------------------------------


## Jobs whose command can be the secondary one: every other job the character has learned an
## action from.
func secondary_options() -> Array[JobDef]:
	var found: Array[JobDef] = []
	for other: JobDef in _progress:
		if other != job and not learned_actions(other).is_empty():
			found.append(other)
	return found


## Why [param command_job]'s command can't be the secondary one, or "". Clearing it (null) is
## always allowed.
func can_set_secondary(command_job: JobDef) -> String:
	if command_job == null:
		return ""
	if command_job == job:
		return "%s is already %s's main command." % [command_job.command_name, name]
	if learned_actions(command_job).is_empty():
		return "%s hasn't learned any %s yet." % [name, command_job.command_name]
	return ""


## Makes [param command_job]'s learned actions the secondary command, or clears it when null.
## Returns why it can't, or "".
func set_secondary(command_job: JobDef) -> String:
	var reason := can_set_secondary(command_job)
	if reason:
		return reason
	loadout.secondary = command_job
	_refresh()
	return ""


## Why [param ability] can't be equipped, or "".
func can_equip_ability(ability: AbilityDef) -> String:
	if ability.kind == AbilityDef.Kind.ACTION:
		return "%s is used from a command, not equipped." % ability.display_name
	if not knows(ability):
		return "%s hasn't learned %s." % [name, ability.display_name]
	return ""


## Equips [param ability] in the slot of its kind. Gear the character could only use thanks to the
## ability it replaces goes back to [param inventory]. Returns why it can't, or "".
func equip_ability(ability: AbilityDef, inventory: Inventory) -> String:
	var reason := can_equip_ability(ability)
	if reason:
		return reason
	_return_to(inventory, _set_ability(ability.kind, ability))
	_refresh()
	return ""


## Empties the [param kind] slot. Gear the character could only use thanks to that ability goes
## back to [param inventory].
func unequip_ability(kind: AbilityDef.Kind, inventory: Inventory) -> void:
	if loadout.get_ability(kind):
		_return_to(inventory, _set_ability(kind, null))
		_refresh()


## The stats the character would have with [param ability] in the [param kind] slot, or with it
## empty when null.
func preview_ability(kind: AbilityDef.Kind, ability: AbilityDef) -> StatBlock:
	var trial := _copy()
	trial._set_ability(kind, ability)
	return trial.stats()


## The gear putting [param ability] in the [param kind] slot (or emptying it) would take off.
func gear_lost_with_ability(kind: AbilityDef.Kind, ability: AbilityDef) -> Array[EquipmentDef]:
	return _copy()._set_ability(kind, ability)


# --- Saving -----------------------------------------------------------------------------------


func to_dict() -> Dictionary:
	var progress_by_job := {}
	for in_job: JobDef in _progress:
		progress_by_job[String(in_job.id)] = _progress[in_job].to_dict()
	return {
		"name": name,
		"level": level,
		"job": String(job.id),
		"own_stats": _own.to_dict(),
		"jobs": progress_by_job,
		"equipment": equipment.to_dict(),
		"loadout": loadout.to_dict(),
		"hp": _hp,
		"mp": _mp,
	}


## The saved character, with its Defs looked up in [param content]. Null, with an error, if its job
## no longer exists; other missing content is dropped with a warning.
static func from_dict(data: Dictionary, content: ContentRegistry) -> Character:
	var saved_job := content.get_def(StringName(data.get("job", ""))) as JobDef
	if saved_job == null:
		push_error("A saved character, \"%s\", has a job \"%s\" that doesn't exist." % [data.get("name"), data.get("job")])
		return null
	var character := Character.new(str(data.get("name", "")), saved_job, StatBlock.from_dict(data.get("own_stats", {})))
	character.level = int(data.get("level", 1))
	character._progress.clear()
	var progress_by_job: Dictionary = data.get("jobs", {})
	for job_id: Variant in progress_by_job:
		var in_job := content.get_def(StringName(job_id)) as JobDef
		if in_job:
			character._progress[in_job] = JobProgress.from_dict(progress_by_job[job_id], content)
		else:
			push_warning("%s has progress in a job \"%s\" that doesn't exist." % [character.name, job_id])
	character.progress(saved_job)
	character.equipment = Equipment.from_dict(data.get("equipment", {}), content)
	character.loadout = AbilityLoadout.from_dict(data.get("loadout", {}), content)
	character._stats = null
	character._hp = clampi(int(data.get("hp", 0)), 0, character.max_hp())
	character._mp = clampi(int(data.get("mp", 0)), 0, character.max_mp())
	return character


# --- Internals --------------------------------------------------------------------------------


## A copy to try changes on, for previews. It shares the character's job progress, which trials
## don't change.
func _copy() -> Character:
	var copy := Character.new(name, job, _own)
	copy.level = level
	copy._progress = _progress.duplicate()
	copy.equipment = equipment.duplicate()
	copy.loadout = loadout.duplicate()
	copy._stats = null
	return copy


## Wears [param item] in [param slot] (or empties it) without checking the rules. Returns every
## piece taken off.
func _put(slot: EquipmentDef.Slot, item: EquipmentDef) -> Array[EquipmentDef]:
	var removed: Array[EquipmentDef] = []
	if item:
		for displaced: EquipmentDef.Slot in EquipRules.displaced_slots(item, slot):
			var piece := equipment.set_item(displaced, null)
			if piece:
				removed.append(piece)
	var previous := equipment.set_item(slot, item)
	if previous:
		removed.append(previous)
	_stats = null
	return removed


func _switch_job(new_job: JobDef) -> Array[EquipmentDef]:
	job = new_job
	progress(new_job)
	if loadout.secondary == new_job:
		loadout.secondary = null
	return _drop_unusable_gear()


func _set_ability(kind: AbilityDef.Kind, ability: AbilityDef) -> Array[EquipmentDef]:
	loadout.set_ability(kind, ability)
	return _drop_unusable_gear()


## Takes off every piece the rules no longer allow, such as a sword after changing to Black Mage.
## Returns them.
func _drop_unusable_gear() -> Array[EquipmentDef]:
	var removed: Array[EquipmentDef] = []
	for slot: EquipmentDef.Slot in EquipmentDef.slots():
		var item := equipment.get_item(slot)
		if item and not EquipRules.can_equip(self, item, slot).is_empty():
			equipment.set_item(slot, null)
			removed.append(item)
	_stats = null
	return removed


## After a change: recomputes the stats, keeps HP and MP within the new maximums, and tells
## listeners.
func _refresh() -> void:
	_stats = null
	_hp = mini(_hp, max_hp())
	_mp = mini(_mp, max_mp())
	changed.emit()


static func _return_to(inventory: Inventory, items: Array[EquipmentDef]) -> void:
	for item: EquipmentDef in items:
		inventory.add(item.id)


static func _job_teaching(ability: AbilityDef, content: ContentRegistry) -> JobDef:
	for def: Def in content.all_of(JobDef):
		if (def as JobDef).teaches(ability):
			return def
	return null

