@tool
class_name TileArt
## The art of painted tiles, for views that draw a map their own way, like the 2.5D battle view
## drawing each painted hex raised to its height.

## Custom data on terrain tiles: one elevation level of the cliff below that terrain.
const CLIFF := &"cliff"


## The texture of the tile painted on [param hex] of [param layer], or null where nothing is.
static func texture_at(layer: TileMapLayer, hex: Vector2i) -> Texture2D:
	var source_id := layer.get_cell_source_id(hex)
	if source_id < 0:
		return null
	var source := layer.tile_set.get_source(source_id) as TileSetAtlasSource
	if source == null:
		return null
	var texture := AtlasTexture.new()
	texture.atlas = source.texture
	texture.region = source.get_tile_texture_region(layer.get_cell_atlas_coords(hex))
	return texture


## How far the tile on [param hex] is drawn up and left of the hex center, as set in its TileSet.
static func origin_at(layer: TileMapLayer, hex: Vector2i) -> Vector2:
	var data := layer.get_cell_tile_data(hex)
	return Vector2(data.texture_origin) if data else Vector2.ZERO


## The [param key] custom data of the tile on [param hex], or null.
static func data_at(layer: TileMapLayer, hex: Vector2i, key: StringName) -> Variant:
	var data := layer.get_cell_tile_data(hex)
	if data == null or layer.tile_set.get_custom_data_layer_by_name(key) < 0:
		return null
	return data.get_custom_data(key)
