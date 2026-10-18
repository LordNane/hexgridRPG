class_name ExploreHud extends CanvasLayer
## The exploration screen's text: the day, hour and region; what's under the cursor; what the party
## carries; region names as the party enters them; and POI messages that wait for the player.

## Emitted when the player dismisses the message box.
signal message_dismissed

## How long a region banner stays fully visible.
const BANNER_SECONDS := 1.8

var _banner_tween: Tween

@onready var _status: Label = %Status
@onready var _hex_info: Label = %HexInfo
@onready var _inventory: Label = %Inventory
@onready var _banner: Label = %Banner
@onready var _message_panel: PanelContainer = %MessagePanel
@onready var _message: Label = %Message


func show_status(text: String) -> void:
	_status.text = text


func show_hex_info(text: String) -> void:
	_hex_info.text = text


func show_inventory(text: String) -> void:
	_inventory.text = text


## Fades [param text] in at the top of the screen, then out again.
func show_banner(text: String) -> void:
	_banner.text = text
	if _banner_tween:
		_banner_tween.kill()
	_banner.modulate.a = 0.0
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.3)
	_banner_tween.tween_interval(BANNER_SECONDS)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.6)


## Shows [param text] in the message box and waits until the player confirms or clicks.
func show_message(text: String) -> void:
	_message.text = text
	_message_panel.show()
	await message_dismissed
	_message_panel.hide()


func is_showing_message() -> bool:
	return _message_panel.visible


func _unhandled_input(event: InputEvent) -> void:
	if not _message_panel.visible:
		return
	var click := event as InputEventMouseButton
	if event.is_action_pressed(&"confirm") or (click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()
		message_dismissed.emit()
