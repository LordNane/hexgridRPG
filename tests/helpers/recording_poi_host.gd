class_name RecordingPoiHost extends PoiHost
## A PoiHost for tests: records everything POIs say and returns at once.

var said: Array[String] = []


func say(text: String) -> void:
	said.append(text)
