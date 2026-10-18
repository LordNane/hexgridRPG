@tool
class_name ExploreMapScene extends Node2D
## The root of an authored exploration map (overworld, cave or town): painted tile layers plus
## marker nodes. ExploreMapBuilder reads it into an ExploreMap.
##
## Paint ground on [member terrain], nature on [member features] and named areas on
## [member regions], using tiles whose custom data names TerrainDef, FeatureDef and RegionDef ids.
## Put PoiMarker and EntryMarker nodes anywhere under [member markers].

@export var terrain: TileMapLayer
@export var features: TileMapLayer
## Painted in the editor only; hidden while playing.
@export var regions: TileMapLayer
@export var markers: Node2D


func _ready() -> void:
	if regions and not Engine.is_editor_hint():
		regions.hide()
