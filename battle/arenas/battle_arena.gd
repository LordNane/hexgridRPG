@tool
class_name BattleArena extends Node2D
## The root of an authored battle arena: painted tile layers plus spawn markers. BattleMapBuilder
## reads it into a BattleMap, and the battle view draws it in 2.5D from the same tiles.
##
## Paint ground on [member terrain] with terrain tiles, elevation on [member heights] with the 0–9
## height tiles (unpainted hexes are at 0) and trees or rocks on [member props]. Put PartySpawn and
## EnemySpawn markers under [member markers]. In the editor, the arena is drawn in 2.5D beside the
## painted layers as you paint. Running the scene by itself plays a test battle in it.

const SANDBOX_SCENE := "res://battle/battle_sandbox.tscn"
## Space between the painted layers and the 2.5D preview, in pixels.
const PREVIEW_GAP := 48.0

## The arena scene last run by itself, for the sandbox to play a battle in.
static var run_alone_path := ""

@export var terrain: TileMapLayer
## Hidden while playing.
@export var heights: TileMapLayer
@export var props: TileMapLayer
@export var markers: Node2D
## Whether the editor draws the 2.5D preview.
@export var show_preview := true:
	set(value):
		show_preview = value
		_queue_preview()

var _preview: Node2D
var _preview_queued := false


func _ready() -> void:
	if Engine.is_editor_hint():
		for layer: TileMapLayer in [terrain, heights, props]:
			if layer and not layer.changed.is_connected(_queue_preview):
				layer.changed.connect(_queue_preview)
		_queue_preview()
		return
	if heights:
		heights.hide()
	if get_tree().current_scene == self:
		# Run on its own (F6): play a test battle here instead.
		run_alone_path = scene_file_path
		get_tree().change_scene_to_file.call_deferred(SANDBOX_SCENE)


## Redraws the 2.5D preview once the current batch of changes is done.
func _queue_preview() -> void:
	if not Engine.is_editor_hint() or _preview_queued or not is_inside_tree():
		return
	_preview_queued = true
	_rebuild_preview.call_deferred()


func _rebuild_preview() -> void:
	_preview_queued = false
	if _preview:
		_preview.queue_free()
		_preview = null
	if not show_preview or terrain == null or terrain.tile_set == null:
		return
	var projection := BattleProjection.new(_layout_for(terrain))
	_preview = Node2D.new()
	_preview.name = "Preview"
	_preview.y_sort_enabled = true
	var cells := terrain.get_used_cells()
	for hex: Vector2i in cells:
		var cell := CellView.new()
		cell.setup(projection, hex, terrain, heights, props)
		_preview.add_child(cell)
	# Not owned, so it's never saved with the scene.
	add_child(_preview, false, INTERNAL_MODE_BACK)
	var painted := terrain.get_used_rect()
	var right := terrain.map_to_local(painted.end)
	_preview.position = Vector2(right.x - terrain.map_to_local(painted.position).x + PREVIEW_GAP, 0.0)


## A HexLayout matching [param tiles]' grid, in this node's coordinates.
func _layout_for(tiles: TileMapLayer) -> HexLayout:
	var layout := HexLayout.new()
	layout.cell_size = tiles.tile_set.tile_size
	layout.origin = to_local(tiles.to_global(tiles.map_to_local(Vector2i.ZERO)))
	return layout
