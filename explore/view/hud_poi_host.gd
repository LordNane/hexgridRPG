class_name HudPoiHost extends PoiHost
## Lets POIs talk to the player through the exploration HUD.

var _hud: ExploreHud


func _init(hud: ExploreHud) -> void:
	_hud = hud


func say(text: String) -> void:
	await _hud.show_message(text)
