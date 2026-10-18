class_name TitleScreen extends CanvasLayer
## The first screen: start a new game, continue from the latest save, or quit. The Game autoload
## listens to the choices.

signal new_game_chosen
signal continue_chosen

const SCENE_PATH := "res://ui/title_screen.tscn"

var _can_continue := false

@onready var _new_game: Button = %NewGame
@onready var _continue: Button = %Continue
@onready var _quit: Button = %Quit


## A title screen that offers Continue only when [param can_continue], because a save exists.
static func create(can_continue: bool) -> TitleScreen:
	var title := (load(SCENE_PATH) as PackedScene).instantiate() as TitleScreen
	title._can_continue = can_continue
	return title


func _ready() -> void:
	_new_game.pressed.connect(new_game_chosen.emit)
	_continue.pressed.connect(continue_chosen.emit)
	_quit.pressed.connect(get_tree().quit)
	_continue.disabled = not _can_continue
	(_continue if _can_continue else _new_game).grab_focus()
