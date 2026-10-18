class_name English
## Small helpers for building sentences shown to the player.


## [param noun] with "a" or "an" in front, by its first letter: "an Archer", "a Squire".
static func with_article(noun: String) -> String:
	return ("an " if noun.left(1).to_upper() in ["A", "E", "I", "O", "U"] else "a ") + noun


## [param words] joined as a list: "A", "A and B", "A, B and C".
static func list(words: PackedStringArray) -> String:
	if words.size() < 2:
		return "".join(words)
	return ", ".join(words.slice(0, -1)) + " and " + words[-1]
