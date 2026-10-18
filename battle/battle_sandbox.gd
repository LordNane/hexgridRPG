class_name BattleSandbox extends Node
## A test bench for battles: plays one in an arena with the starting party against an encounter,
## and starts over when it ends. Running an arena scene by itself (F6) opens it here; or run this
## scene and choose the arena and encounter in the inspector.

const DEFAULT_ARENA := "res://battle/arenas/forest_clearing.tscn"
const DEFAULT_ENCOUNTER := &"bandit_patrol"

## The arena to fight in. An arena scene run by itself takes its place.
@export_file("*.tscn") var arena := ""
## Who to fight; defaults to the bandit patrol.
@export var encounter: EncounterDef
## Lets the AI fight for the party too, to watch whole battles play out.
@export var auto_play := false

var _mode: BattleMode
var _rng := SeededRng.new(int(Time.get_unix_time_from_system()))


func _ready() -> void:
	_start()


func _start() -> void:
	var path := arena
	if not BattleArena.run_alone_path.is_empty():
		path = BattleArena.run_alone_path
	elif path.is_empty():
		path = DEFAULT_ARENA
	var enemies := encounter if encounter else ContentDB.get_def(DEFAULT_ENCOUNTER) as EncounterDef
	var request := BattleRequest.new(path, Game.starting_party().members(), enemies, _rng.randi_range(0, 0x7FFFFFFF))
	_mode = BattleMode.create(request)
	_mode.party_ai = auto_play
	_mode.finished.connect(_on_finished)
	add_child(_mode)


func _on_finished(_result: BattleResult) -> void:
	_mode.queue_free()
	_start.call_deferred()
