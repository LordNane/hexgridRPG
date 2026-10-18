class_name GameSession extends RefCounted
## Everything about one playthrough that changes during play: what the party carries, what it has
## done and how much time has passed. Phase 3 adds the party, gold, the map stack and saving.

## The hour the journey starts, on day 1.
const START_HOUR := 8.0

var inventory := Inventory.new()
var world := WorldState.new()
var rng: SeededRng
## Hours since midnight before day 1. Travel advances it: a move cost of 1 takes an hour.
var hours := START_HOUR


func _init(seed_value: int = 0) -> void:
	rng = SeededRng.new(seed_value)


func advance_time(amount: float) -> void:
	hours += amount


## The current day, starting at 1.
func day() -> int:
	return int(hours / 24.0) + 1


## The hour of the current day, 0–23.
func hour_of_day() -> int:
	return int(hours) % 24


func to_dict() -> Dictionary:
	return {
		"inventory": inventory.to_dict(),
		"world": world.to_dict(),
		"hours": hours,
		# A string, because JSON numbers can't hold every 64-bit value exactly.
		"rng_state": str(rng.state),
	}


static func from_dict(data: Dictionary) -> GameSession:
	var session := GameSession.new()
	session.inventory = Inventory.from_dict(data.get("inventory", {}))
	session.world = WorldState.from_dict(data.get("world", {}))
	session.hours = float(data.get("hours", START_HOUR))
	session.rng.state = str(data.get("rng_state", "0")).to_int()
	return session
