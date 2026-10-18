extends Node
## The main scene: hands its ModeRouter to the Game autoload, which opens the title screen.


func _ready() -> void:
	Game.start($ModeRouter as ModeRouter)
