## Sprite Data Loader and Manager
## Ported from e.java - Handles loading sprite data from pi0, pi8, pi9 folders
## Manages sprite sheets and animation frames

class_name SpriteDataManager
extends Node

# Singleton instance
static var instance: SpriteDataManager

# Sprite sets (pi0, pi8, pi9)
const SPRITE_SETS = ["pi0", "pi8", "pi9"]

# Loaded sprite textures
var sprite_textures: Dictionary = {}  # set_name -> Array of Texture2D
var sprite_data: Dictionary = {}      # set_name -> Array of sprite data

# Sprite metadata from pd0.txt equivalent
var sprite_widths: Dictionary = {}
var sprite_heights: Dictionary = {}

# Current sprite set index (0=pi0, 1=pi9, 2=pi8 as per Java code)
var current_set_index: int = 0

func _ready() -> void:
	instance = self
	load_all_sprites()

func load_all_sprites() -> void:
	"""Load all sprite sets from resources"""
	for set_name in SPRITE_SETS:
		load_sprite_set(set_name)

func load_sprite_set(set_name: String) -> void:
	"""Load a specific sprite set (pi0, pi8, or pi9)"""
	if sprite_textures.has(set_name):
		return  # Already loaded
	
	sprite_textures[set_name] = []
	sprite_data[set_name] = []
	
	# Find all PNG files in the sprite folder
	var dir_path = "res://sprites/%s/" % set_name
	var dir = DirAccess.open(dir_path)
	
	if not dir:
		push_warning("Sprite directory not found: ", dir_path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var sprite_files: Array[String] = []
	
	while file_name != "":
		if file_name.ends_with(".png") and not file_name.begins_with("."):
			sprite_files.append(file_name)
		file_name = dir.get_next()
	
	# Sort files by name (pi0_000.png, pi0_001.png, etc.)
	sprite_files.sort()
	
	# Load each sprite
	for sprite_file in sprite_files:
		var path = dir_path + sprite_file
		if ResourceLoader.exists(path):
			var tex = load(path) as Texture2D
			if tex:
				sprite_textures[set_name].append(tex)
				
				# Store sprite metadata
				var sprite_info = {
					"filename": sprite_file,
					"width": tex.get_width(),
					"height": tex.get_height(),
					"path": path
				}
				sprite_data[set_name].append(sprite_info)
	
	dir.list_dir_end()
	
	print("Loaded %d sprites from %s" % [sprite_textures[set_name].size(), set_name])

func get_sprite(set_name: String, index: int) -> Texture2D:
	"""Get a specific sprite texture by set name and index"""
	if not sprite_textures.has(set_name):
		load_sprite_set(set_name)
	
	var textures = sprite_textures.get(set_name, [])
	if index >= 0 and index < textures.size():
		return textures[index]
	
	return null

func get_sprite_count(set_name: String) -> int:
	"""Get the number of sprites in a set"""
	if not sprite_textures.has(set_name):
		load_sprite_set(set_name)
	
	return sprite_textures.get(set_name, []).size()

func set_current_sprite_set(index: int) -> void:
	"""Set the current active sprite set (0=pi0, 1=pi9, 2=pi8)"""
	if index >= 0 and index < SPRITE_SETS.size():
		current_set_index = index

func get_current_sprite_set_name() -> String:
	"""Get the name of the current sprite set"""
	if current_set_index >= 0 and current_set_index < SPRITE_SETS.size():
		return SPRITE_SETS[current_set_index]
	return "pi0"

func get_current_sprite(index: int) -> Texture2D:
	"""Get a sprite from the current active set"""
	return get_sprite(get_current_sprite_set_name(), index)

func preload_sprites_for_animation(set_name: String, start_index: int, count: int) -> void:
	"""Preload a range of sprites for animation"""
	for i in range(start_index, start_index + count):
		get_sprite(set_name, i)

func get_sprite_dimensions(set_name: String, index: int) -> Vector2i:
	"""Get the dimensions of a specific sprite"""
	var textures = sprite_textures.get(set_name, [])
	if index >= 0 and index < textures.size():
		var tex = textures[index]
		return Vector2i(tex.get_width(), tex.get_height())
	return Vector2i(0, 0)

func clear_cache() -> void:
	"""Clear loaded sprite cache to free memory"""
	for set_name in SPRITE_SETS:
		sprite_textures[set_name].clear()
		sprite_data[set_name].clear()
