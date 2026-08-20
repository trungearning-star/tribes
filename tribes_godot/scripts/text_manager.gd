## Text/Dialog Manager for Game Localization
## Ported from c.java - Handles text loading and display
## Supports Vietnamese localization (folder 0)

class_name TextManager
extends Node

# Singleton instance
static var instance: TextManager

# Text data arrays (from s.txt, t.txt, d0.txt)
var short_text: Array[String] = []      # s.txt - Short UI strings
var help_text: Array[String] = []       # t.txt - Help/tutorial text
var scene_text: Array[String] = []      # d0.txt - Scene/story dialog

# Current scene base index
var scene_base: int = 0

# File paths
const DATA_PATH = "res://data/"

# Text encoding (UTF-8 with | delimiter as per Java code)
const DELIMITER = "|"

func _ready() -> void:
	instance = self
	load_all_text()

func load_all_text() -> void:
	"""Load all text files from data folder"""
	load_short_text()
	load_help_text()
	load_scene_text()

func load_short_text() -> void:
	"""Load s.txt - Short UI strings"""
	short_text.clear()
	var path = DATA_PATH + "s.txt"
	
	if not ResourceLoader.exists(path):
		push_warning("Short text file not found: ", path)
		return
	
	var content = _load_file(path)
	if content != "":
		short_text = content.split(DELIMITER, false)
	
	print("Loaded %d short text strings" % short_text.size())

func load_help_text() -> void:
	"""Load t.txt - Help/tutorial text"""
	help_text.clear()
	var path = DATA_PATH + "t.txt"
	
	if not ResourceLoader.exists(path):
		push_warning("Help text file not found: ", path)
		return
	
	var content = _load_file(path)
	if content != "":
		help_text = content.split(DELIMITER, false)
	
	print("Loaded %d help text strings" % help_text.size())

func load_scene_text() -> void:
	"""Load d0.txt - Scene/story dialog"""
	scene_text.clear()
	var path = DATA_PATH + "d0.txt"
	
	if not ResourceLoader.exists(path):
		push_warning("Scene text file not found: ", path)
		return
	
	var content = _load_file(path)
	if content != "":
		scene_text = content.split(DELIMITER, false)
	
	print("Loaded %d scene text strings" % scene_text.size())

func _load_file(path: String) -> String:
	"""Load text file content"""
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		return content
	return ""

func get_short_text(index: int) -> String:
	"""Get short text by index (port of lookupShort in c.java)"""
	if index >= 0 and index < short_text.size():
		return short_text[index]
	
	# Fallback to help_text if out of range
	if index >= 0 and index < help_text.size():
		return help_text[index]
	
	return ""

func get_help_text(index: int) -> String:
	"""Get help text by index"""
	if index >= 0 and index < help_text.size():
		return help_text[index]
	return ""

func get_scene_text(index: int) -> String:
	"""Get scene text by index (port of lookupLong in c.java)"""
	# Apply scene base offset
	var actual_index = index
	if index >= 71:
		actual_index = index - 71 + scene_base
	
	if actual_index >= 0 and actual_index < scene_text.size():
		return scene_text[actual_index]
	
	# Fallback to help_text
	if index >= 0 and index < help_text.size():
		return help_text[index]
	
	# Fallback to scene_text without offset
	if index >= 0 and index < scene_text.size():
		return scene_text[index]
	
	return ""

func set_scene(scene_index: int) -> void:
	"""Set current scene index (port of a(int n) in c.java)"""
	scene_base = _get_scene_base_for(scene_index)
	print("Scene base set to: ", scene_base, " for scene ", scene_index)

func _get_scene_base_for(scene_index: int) -> int:
	"""Get scene base offset for a given scene index (port of sceneBaseFor in c.java)"""
	# Scene base mapping from Java code
	var scene_bases = [
		0,   # Scene 0
		3,   # Scene 1
		15,  # Scene 2
		18,  # Scene 3
		20,  # Scene 4
		22,  # Scene 5
		24,  # Scene 6
		26,  # Scene 7
		28,  # Scene 8
		29,  # Scene 9
		30,  # Scene 10
		31,  # Scene 11
		33,  # Scene 12
		34,  # Scene 13
		35,  # Scene 14
		36,  # Scene 15
		44,  # Scene 16
		45,  # Scene 17
		46,  # Scene 18
		57,  # Scene 19
		58,  # Scene 20
		59,  # Scene 21
		62,  # Scene 22
		64,  # Scene 23
		65,  # Scene 24
		67,  # Scene 25
		68,  # Scene 26
		70,  # Scene 27
		72,  # Scene 28
		77,  # Scene 29
		81,  # Scene 30
		84,  # Scene 31
		85,  # Scene 32
		86,  # Scene 33
		97,  # Scene 34
		102, # Scene 35
		108, # Scene 36
		109, # Scene 37
		111, # Scene 38
		116, # Scene 39
		117, # Scene 40
		119, # Scene 41
		123, # Scene 42
		128, # Scene 43
		137, # Scene 44
		143, # Scene 45
		145, # Scene 46
		148, # Scene 47
		149, # Scene 48
		165, # Scene 49
		167, # Scene 50
		181, # Scene 51
		184, # Scene 52
		190, # Scene 53
		197, # Scene 54
		203, # Scene 55
		204, # Scene 56
		207, # Scene 57
		208, # Scene 58
		211, # Scene 59
		212, # Scene 60
		216, # Scene 61
		219, # Scene 62
		222, # Scene 63
		223, # Scene 64
		224, # Scene 65
		225, # Scene 66
		226, # Scene 67
		227, # Scene 68
		228, # Scene 69
		229, # Scene 70
		230, # Scene 71
		231, # Scene 72
		232, # Scene 73
		233, # Scene 74
		234  # Scene 75
	]
	
	if scene_index < 0:
		return 0
	
	if scene_index >= scene_bases.size():
		return scene_bases[scene_bases.size() - 1]
	
	return scene_bases[scene_index]

func wrap_text(text: String, max_width: int) -> Array[String]:
	"""Wrap text to fit within max_width (simplified version)"""
	var lines: Array[String] = []
	var words = text.split(" ")
	var current_line = ""
	
	for word in words:
		var test_line = current_line + " " + word if current_line != "" else word
		if test_line.length() <= max_width:
			current_line = test_line
		else:
			if current_line != "":
				lines.append(current_line.strip_edges())
			current_line = word
	
	if current_line != "":
		lines.append(current_line.strip_edges())
	
	return lines

func clean_inline(text: String) -> String:
	"""Clean inline formatting codes (port of cleanInline in c.java)"""
	var result = ""
	for char in text:
		if char == '&':
			result += ' '
		elif char >= ' ':
			result += char
	return result

func normalize_long_text(text: String) -> String:
	"""Normalize long text with special characters (port of normalizeLong in c.java)"""
	var result = ""
	for char in text:
		if char == '&':
			result += '\n'
		elif char >= ' ':
			result += char
		else:
			result += ' '
	return result

func get_text_count() -> Dictionary:
	"""Get count of loaded texts"""
	return {
		"short": short_text.size(),
		"help": help_text.size(),
		"scene": scene_text.size()
	}
