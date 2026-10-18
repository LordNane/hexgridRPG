class_name GameSession extends RefCounted
## Everything about one playthrough that changes during play: who's in the party, where it is, what
## it carries, what it has done and how much time has passed. Saved whole by the Game autoload.

## Emitted when the party's gold changes; [param gold] is the new total.
signal gold_changed(gold: int)

## The hour the journey starts, on day 1.
const START_HOUR := 8.0

var party := Party.new()
var inventory := Inventory.new()
var gold := 0
var world := WorldState.new()
## Where the party is. The last entry is the map it's on now; each entry below it is the map it
## entered that one from, still holding the hex it left from, so leaving puts it back there.
## Empty until the journey starts.
var map_stack: Array[MapPosition] = []
var rng: SeededRng
## Hours since midnight before day 1. Travel advances it: a move cost of 1 takes an hour.
var hours := START_HOUR
## Steps left before random battles can happen again. See EncounterRoller.
var encounter_grace := EncounterRoller.GRACE_STEPS


func _init(seed_value: int = 0) -> void:
	rng = SeededRng.new(seed_value)


func add_gold(amount: int) -> void:
	assert(amount > 0, "Add a positive amount.")
	gold += amount
	gold_changed.emit(gold)


## Where the party is now, or null before the journey starts.
func location() -> MapPosition:
	return null if map_stack.is_empty() else map_stack.back()


## Puts the party on [param hex] of the map [param map_id], remembering the map it came from.
## Returns its new position, which exploring that map keeps up to date.
func enter_map(map_id: StringName, hex: Vector2i) -> MapPosition:
	var position := MapPosition.new(map_id, hex)
	map_stack.append(position)
	return position


## Takes the party back to the map it entered the current one from, on the hex it left from.
func leave_map() -> void:
	assert(map_stack.size() > 1, "The party is on the bottom map; there's nowhere to go back to.")
	map_stack.pop_back()


func advance_time(amount: float) -> void:
	hours += amount


## The current day, starting at 1.
func day() -> int:
	return int(hours / 24.0) + 1


## The hour of the current day, 0–23.
func hour_of_day() -> int:
	return int(hours) % 24


func to_dict() -> Dictionary:
	var stack: Array[Dictionary] = []
	for position: MapPosition in map_stack:
		stack.append(position.to_dict())
	return {
		"party": party.to_dict(),
		"inventory": inventory.to_dict(),
		"gold": gold,
		"world": world.to_dict(),
		"map_stack": stack,
		"hours": hours,
		"encounter_grace": encounter_grace,
		# A string, because JSON numbers can't hold every 64-bit value exactly.
		"rng_state": str(rng.state),
	}


## The saved session, with the content it refers to looked up in [param content].
static func from_dict(data: Dictionary, content: ContentRegistry) -> GameSession:
	var session := GameSession.new()
	session.party = Party.from_dict(data.get("party", {}), content)
	session.inventory = Inventory.from_dict(data.get("inventory", {}))
	session.gold = int(data.get("gold", 0))
	session.world = WorldState.from_dict(data.get("world", {}))
	for position: Variant in data.get("map_stack", []):
		session.map_stack.append(MapPosition.from_dict(position))
	session.hours = float(data.get("hours", START_HOUR))
	session.encounter_grace = int(data.get("encounter_grace", EncounterRoller.GRACE_STEPS))
	session.rng.state = str(data.get("rng_state", "0")).to_int()
	return session
