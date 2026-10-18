@tool
class_name PoiMarker extends HexMarker
## Places a POI on an authored map and draws its icon standing on the hex. While playing,
## [member used] swaps in the POI's used icon, such as an open chest.

## Icons stand a little above the hex center so they read as standing on it.
const LIFT := Vector2(0, -4)
const MISSING_ICON_COLOR := Color(1, 0, 1)

@export var poi: PoiDef:
	set(value):
		poi = value
		queue_redraw()
		update_configuration_warnings()

## Whether the POI's one-time use is spent.
var used := false:
	set(value):
		used = value
		queue_redraw()


func _draw() -> void:
	var icon := _icon()
	if icon:
		draw_texture(icon, (LIFT - icon.get_size() / 2).round())
	else:
		draw_colored_polygon(PackedVector2Array([LIFT + Vector2(0, -5), LIFT + Vector2(5, 0), LIFT + Vector2(0, 5), LIFT + Vector2(-5, 0)]), MISSING_ICON_COLOR)


func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray() if poi else PackedStringArray(["Assign the PoiDef this marker places."])


func _icon() -> Texture2D:
	if poi == null:
		return null
	return poi.used_icon if used and poi.used_icon else poi.icon
