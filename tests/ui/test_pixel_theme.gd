extends GutTest
## The UI theme's font, whichever it is: it must have every character the game shows, and a bitmap
## font must only be drawn at whole multiples of its size so its pixels stay crisp.

## Characters the game shows besides printable ASCII: counts, the "·" separator, empty slots and
## stat previews.
const EXTRA_CHARACTERS := "×·—»"
const THEME_PATH := "res://ui/theme/pixel_theme.tres"
const SCENES_WITH_TEXT: Array[String] = ["res://ui/title_screen.tscn", "res://explore/view/explore_hud.tscn"]

var _theme: Theme


func before_all() -> void:
	_theme = load(THEME_PATH)


func test_the_font_has_every_character_the_game_shows() -> void:
	var font := _theme.default_font
	assert_not_null(font, "the theme sets a default font")
	var missing := PackedStringArray()
	for code: int in range(32, 127):
		if not font.has_char(code):
			missing.append(char(code))
	for character: String in EXTRA_CHARACTERS:
		if not font.has_char(character.unicode_at(0)):
			missing.append(character)
	assert_eq(missing, PackedStringArray(), "characters the font lacks")


func test_a_bitmap_font_is_only_used_at_whole_multiples_of_its_size() -> void:
	var font := _theme.default_font as FontFile
	if font == null or font.fixed_size == 0:
		pass_test("the font is a scalable one; any size is fine")
		return
	var sizes: Array[int] = [_theme.default_font_size]
	for type: StringName in _theme.get_font_size_type_list():
		for size_name: StringName in _theme.get_font_size_list(type):
			sizes.append(_theme.get_font_size(size_name, type))
	for path: String in SCENES_WITH_TEXT:
		var scene := (load(path) as PackedScene).instantiate()
		for node: Node in scene.find_children("*", "Control", true, false):
			if (node as Control).has_theme_font_size_override(&"font_size"):
				sizes.append((node as Control).get_theme_font_size(&"font_size"))
		scene.free()
	for size: int in sizes:
		assert_eq(size % font.fixed_size, 0, "font size %d is a multiple of %d" % [size, font.fixed_size])
