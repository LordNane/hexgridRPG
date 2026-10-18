extends SceneTree
## Generates a placeholder pixel font, so the UI looks pixel-art before the final font is chosen:
## a proportional bitmap font with 7-pixel capitals and 2-pixel descenders, saved as a BMFont (a
## .fnt description and a .png of glyphs) that Godot imports as a FontFile.
## [codeblock]
## godot --headless --path . -s res://tools/gen_placeholder_font.gd
## [/codeblock]
## Writes res://assets/fonts/placeholder/pixel_font.fnt and pixel_font.png. ui/theme/pixel_theme.tres
## uses it as its default font; to use another font, change the theme's default font (and its
## font sizes). Re-running this overwrites hand edits to the .png.

const OUT_DIR := "res://assets/fonts/placeholder/"
const FILE_NAME := "pixel_font"
## The font's size in Godot. Theme font sizes that are whole multiples of it (8, 16, 24) draw crisp.
const SIZE := 8
## Pixels from one line's top to the next's.
const LINE_HEIGHT := 11
## Pixels from a line's top to its baseline.
const BASE := 8
## Glyph rows are numbered from the capital height: capitals fill rows 0–6, lowercase letters rows
## 2–6, descenders reach rows 7–8. Row 0 sits this many pixels below the top of the line.
const TOP := 1
const SPACE_ADVANCE := 3
## Pixels between glyphs.
const TRACKING := 1
const SHEET_WIDTH := 128

## Each glyph: its first row, then its rows of pixels ("#" on, "." off), all the same width.
const GLYPHS: Dictionary[String, Array] = {
	"A": [0, ".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"B": [0, "####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
	"C": [0, ".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
	"D": [0, "####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
	"E": [0, "#####", "#....", "#....", "####.", "#....", "#....", "#####"],
	"F": [0, "#####", "#....", "#....", "####.", "#....", "#....", "#...."],
	"G": [0, ".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".####"],
	"H": [0, "#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"I": [0, "###", ".#.", ".#.", ".#.", ".#.", ".#.", "###"],
	"J": [0, "...#", "...#", "...#", "...#", "#..#", "#..#", ".##."],
	"K": [0, "#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
	"L": [0, "#...", "#...", "#...", "#...", "#...", "#...", "####"],
	"M": [0, "#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
	"N": [0, "#...#", "##..#", "##..#", "#.#.#", "#..##", "#..##", "#...#"],
	"O": [0, ".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"P": [0, "####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
	"Q": [0, ".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
	"R": [0, "####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
	"S": [0, ".###.", "#...#", "#....", ".###.", "....#", "#...#", ".###."],
	"T": [0, "#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
	"U": [0, "#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"V": [0, "#...#", "#...#", "#...#", "#...#", ".#.#.", ".#.#.", "..#.."],
	"W": [0, "#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
	"X": [0, "#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
	"Y": [0, "#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
	"Z": [0, "#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
	"a": [2, ".##.", "...#", ".###", "#..#", ".###"],
	"b": [0, "#...", "#...", "###.", "#..#", "#..#", "#..#", "###."],
	"c": [2, ".###", "#...", "#...", "#...", ".###"],
	"d": [0, "...#", "...#", ".###", "#..#", "#..#", "#..#", ".###"],
	"e": [2, ".##.", "#..#", "####", "#...", ".###"],
	"f": [0, "..##", ".#..", "###.", ".#..", ".#..", ".#..", ".#.."],
	"g": [2, ".###", "#..#", "#..#", "#..#", ".###", "...#", ".##."],
	"h": [0, "#...", "#...", "###.", "#..#", "#..#", "#..#", "#..#"],
	"i": [0, "#", ".", "#", "#", "#", "#", "#"],
	"j": [0, ".#", "..", ".#", ".#", ".#", ".#", ".#", ".#", "#."],
	"k": [0, "#...", "#...", "#..#", "#.#.", "##..", "#.#.", "#..#"],
	"l": [0, "#.", "#.", "#.", "#.", "#.", "#.", ".#"],
	"m": [2, "##.#.", "#.#.#", "#.#.#", "#.#.#", "#.#.#"],
	"n": [2, "###.", "#..#", "#..#", "#..#", "#..#"],
	"o": [2, ".##.", "#..#", "#..#", "#..#", ".##."],
	"p": [2, "###.", "#..#", "#..#", "#..#", "###.", "#...", "#..."],
	"q": [2, ".###", "#..#", "#..#", "#..#", ".###", "...#", "...#"],
	"r": [2, "#.##", "##..", "#...", "#...", "#..."],
	"s": [2, ".###", "#...", ".##.", "...#", "###."],
	"t": [1, ".#.", "###", ".#.", ".#.", ".#.", "..#"],
	"u": [2, "#..#", "#..#", "#..#", "#..#", ".###"],
	"v": [2, "#...#", "#...#", ".#.#.", ".#.#.", "..#.."],
	"w": [2, "#...#", "#...#", "#.#.#", "#.#.#", ".#.#."],
	"x": [2, "#...#", ".#.#.", "..#..", ".#.#.", "#...#"],
	"y": [2, "#..#", "#..#", "#..#", "#..#", ".###", "...#", ".##."],
	"z": [2, "####", "...#", ".##.", "#...", "####"],
	"0": [0, ".##.", "#..#", "#..#", "#..#", "#..#", "#..#", ".##."],
	"1": [0, "..#.", ".##.", "..#.", "..#.", "..#.", "..#.", ".###"],
	"2": [0, ".##.", "#..#", "...#", "..#.", ".#..", "#...", "####"],
	"3": [0, "###.", "...#", "...#", ".##.", "...#", "...#", "###."],
	"4": [0, "#..#", "#..#", "#..#", "####", "...#", "...#", "...#"],
	"5": [0, "####", "#...", "#...", "###.", "...#", "...#", "###."],
	"6": [0, ".##.", "#...", "#...", "###.", "#..#", "#..#", ".##."],
	"7": [0, "####", "...#", "...#", "..#.", ".#..", ".#..", ".#.."],
	"8": [0, ".##.", "#..#", "#..#", ".##.", "#..#", "#..#", ".##."],
	"9": [0, ".##.", "#..#", "#..#", ".###", "...#", "...#", ".##."],
	"!": [0, "#", "#", "#", "#", "#", ".", "#"],
	"\"": [0, "#.#", "#.#"],
	"#": [0, ".#.#.", ".#.#.", "#####", ".#.#.", "#####", ".#.#.", ".#.#."],
	"$": [0, "..#..", ".####", "#.#..", ".###.", "..#.#", "####.", "..#.."],
	"%": [0, "##..#", "##.#.", "...#.", "..#..", ".#...", ".#.##", "#..##"],
	"&": [0, ".##..", "#..#.", "#.#..", ".#...", "#.#.#", "#..#.", ".##.#"],
	"'": [0, "#", "#"],
	"(": [0, ".#", "#.", "#.", "#.", "#.", "#.", ".#"],
	")": [0, "#.", ".#", ".#", ".#", ".#", ".#", "#."],
	"*": [1, "..#..", "#.#.#", ".###.", "#.#.#", "..#.."],
	"+": [2, "..#..", "..#..", "#####", "..#..", "..#.."],
	",": [6, ".#", "#."],
	"-": [4, "###"],
	".": [6, "#"],
	"/": [0, "....#", "...#.", "...#.", "..#..", ".#...", ".#...", "#...."],
	":": [3, "#", ".", ".", "#"],
	";": [3, ".#", "..", "..", ".#", "#."],
	"<": [2, "..#", ".#.", "#..", ".#.", "..#"],
	"=": [3, "####", "....", "####"],
	">": [2, "#..", ".#.", "..#", ".#.", "#.."],
	"?": [0, ".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.."],
	"@": [0, ".###.", "#...#", "#.###", "#.#.#", "#.###", "#....", ".###."],
	"[": [0, "##", "#.", "#.", "#.", "#.", "#.", "##"],
	"\\": [0, "#....", ".#...", ".#...", "..#..", "...#.", "...#.", "....#"],
	"]": [0, "##", ".#", ".#", ".#", ".#", ".#", "##"],
	"^": [0, "..#..", ".#.#.", "#...#"],
	"_": [7, "#####"],
	"`": [0, "#.", ".#"],
	"{": [0, "..#", ".#.", ".#.", "#..", ".#.", ".#.", "..#"],
	"|": [0, "#", "#", "#", "#", "#", "#", "#", "#"],
	"}": [0, "#..", ".#.", ".#.", "..#", ".#.", ".#.", "#.."],
	"~": [3, ".#..#", "#.##."],
	"×": [3, "#.#", ".#.", "#.#"],
	"·": [4, "#"],
	"»": [2, "#.#..", ".#.#.", "..#.#", ".#.#.", "#.#.."],
	"«": [2, "..#.#", ".#.#.", "#.#..", ".#.#.", "..#.#"],
	"—": [4, "#######"],
	"–": [4, "#####"],
	"…": [6, "#.#.#"],
	"’": [0, ".#", "#."],
	"→": [2, "..#..", "...#.", "#####", "...#.", "..#.."],
}


func _init() -> void:
	var placed := _layout()
	var height := 0
	for at: Rect2i in placed.values():
		height = maxi(height, at.end.y + 1)
	var sheet := Image.create_empty(SHEET_WIDTH, height, false, Image.FORMAT_RGBA8)
	var lines := PackedStringArray([
		'info face="Placeholder Pixel" size=%d bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1 outline=0' % SIZE,
		"common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0 alphaChnl=0 redChnl=4 greenChnl=4 blueChnl=4" % [LINE_HEIGHT, BASE, SHEET_WIDTH, height],
		'page id=0 file="%s.png"' % FILE_NAME,
		"chars count=%d" % (GLYPHS.size() + 1),
		"char id=32 x=0 y=0 width=0 height=0 xoffset=0 yoffset=0 xadvance=%d page=0 chnl=15" % SPACE_ADVANCE,
	])
	for character: String in GLYPHS:
		var glyph: Array = GLYPHS[character]
		var at := placed[character]
		for row: int in at.size.y:
			var pixels: String = glyph[row + 1]
			for column: int in pixels.length():
				if pixels[column] == "#":
					sheet.set_pixel(at.position.x + column, at.position.y + row, Color.WHITE)
		lines.append("char id=%d x=%d y=%d width=%d height=%d xoffset=0 yoffset=%d xadvance=%d page=0 chnl=15" % [
			character.unicode_at(0), at.position.x, at.position.y, at.size.x, at.size.y,
			TOP + int(glyph[0]), at.size.x + TRACKING])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var error := sheet.save_png(OUT_DIR + FILE_NAME + ".png")
	var file := FileAccess.open(OUT_DIR + FILE_NAME + ".fnt", FileAccess.WRITE)
	if file:
		file.store_string("\n".join(lines) + "\n")
		file.close()
	else:
		error = FileAccess.get_open_error()
	print("%s %s%s.fnt and .png (%d glyphs)" % ["wrote" if error == OK else "FAILED", OUT_DIR, FILE_NAME, GLYPHS.size() + 1])
	quit(0 if error == OK else 1)


## Where each glyph goes on the sheet: left to right, a pixel apart, wrapping to new rows.
func _layout() -> Dictionary[String, Rect2i]:
	var placed: Dictionary[String, Rect2i] = {}
	var cursor := Vector2i.ZERO
	var row_height := 0
	for character: String in GLYPHS:
		var glyph: Array = GLYPHS[character]
		var size := Vector2i(String(glyph[1]).length(), glyph.size() - 1)
		if cursor.x + size.x > SHEET_WIDTH:
			cursor = Vector2i(0, cursor.y + row_height + 1)
			row_height = 0
		placed[character] = Rect2i(cursor, size)
		cursor.x += size.x + 1
		row_height = maxi(row_height, size.y)
	return placed
