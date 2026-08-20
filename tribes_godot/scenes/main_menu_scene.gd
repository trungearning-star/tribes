## Main Menu Scene Controller
## Ported from f.java - Main menu rendering and input handling (state 3)
## Handles menu display, navigation, and selection

class_name MainMenuScene
extends CanvasLayer

# Signals
signal new_game_selected
signal continue_selected
signal options_selected
signal help_selected
signal exit_selected

# Menu constants (from Java code)
const MENU_ITEMS = ["Chơi mới", "Tiếp tục", "Tùy chọn", "Hướng dẫn", "Thoát"]
const MENU_ITEM_COUNT = 5

# Menu state
var selected_index: int = 0
var has_save_game: bool = false

# UI nodes
var menu_container: Control
var title_label: Label
var menu_items: Array[Label] = []
var version_label: Label

# Background splash texture
var bg_texture: Texture2D

# Audio
var menu_bgm_index: int = 0
var select_sfx_index: int = 0
var navigate_sfx_index: int = 1

func _ready() -> void:
	setup_ui()
	load_menu_data()
	update_menu_display()
	
	# Play menu BGM
	if AudioManager.instance:
		AudioManager.instance.play_bgm(menu_bgm_index, true)

func setup_ui() -> void:
	"""Create menu UI elements"""
	# Main container
	menu_container = Control.new()
	menu_container.name = "MenuContainer"
	menu_container.anchor_left = 0.0
	menu_container.anchor_top = 0.0
	menu_container.anchor_right = 1.0
	menu_container.anchor_bottom = 1.0
	add_child(menu_container)
	
	# Background color
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.05, 0.0, 1.0)
	menu_container.add_theme_stylebox_override("panel", style)
	
	# Title label
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "PREHISTORIC TRIBES"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	title_label.offset_top = 20
	title_label.offset_left = 20
	title_label.offset_right = -20
	title_label.offset_bottom = 60
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3, 1.0))
	menu_container.add_child(title_label)
	
	# Create menu items
	var item_y_start = 100
	var item_height = 30
	var spacing = 10
	
	for i in range(MENU_ITEM_COUNT):
		var item_label = Label.new()
		item_label.name = "MenuItem%d" % i
		item_label.text = MENU_ITEMS[i]
		item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		item_label.offset_left = 80
		item_label.offset_top = item_y_start + i * (item_height + spacing)
		item_label.offset_right = -80
		item_label.offset_bottom = item_y_start + i * (item_height + spacing) + item_height
		item_label.add_theme_font_size_override("font_size", 16)
		
		# Store reference
		menu_items.append(item_label)
		menu_container.add_child(item_label)
	
	# Version label
	version_label = Label.new()
	version_label.name = "VersionLabel"
	version_label.text = "Phiên bản: 0.1.30"
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	version_label.offset_top = -30
	version_label.offset_left = 20
	version_label.offset_right = -20
	version_label.offset_bottom = -10
	version_label.add_theme_font_size_override("font_size", 10)
	version_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
	menu_container.add_child(version_label)

func load_menu_data() -> void:
	"""Load menu text and check for save game"""
	# Check if save game exists
	has_save_game = check_for_save_game()
	
	# Update "Continue" option based on save availability
	if not has_save_game:
		MENU_ITEMS[1] = "Tiếp tục (không có lưu)"
	else:
		MENU_ITEMS[1] = "Tiếp tục"

func check_for_save_game() -> bool:
	"""Check if a save game file exists (port of boolean_d in f.java)"""
	var save_path = "user://savegame.dat"
	return FileAccess.file_exists(save_path)

func update_menu_display() -> void:
	"""Update menu item colors based on selection"""
	for i in range(menu_items.size()):
		var label = menu_items[i]
		
		if i == selected_index:
			# Selected item - bright yellow with cursor
			label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
			label.text = "> " + MENU_ITEMS[i] + " <"
		else:
			# Unselected items - dimmer
			label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
			label.text = "  " + MENU_ITEMS[i]
		
		# Gray out Continue if no save
		if i == 1 and not has_save_game:
			label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1.0))

func handle_input(action: String) -> void:
	"""Handle menu input (mapped from Java key events)"""
	match action:
		"up":
			navigate_up()
		"down":
			navigate_down()
		"select":
			select_current_item()
		"menu":
			# Back button - could exit or go to previous screen
			pass

func navigate_up() -> void:
	"""Move selection up"""
	selected_index = (selected_index - 1 + MENU_ITEM_COUNT) % MENU_ITEM_COUNT
	update_menu_display()
	
	# Play navigation sound
	if AudioManager.instance:
		AudioManager.instance.play_sfx(navigate_sfx_index)

func navigate_down() -> void:
	"""Move selection down"""
	selected_index = (selected_index + 1) % MENU_ITEM_COUNT
	update_menu_display()
	
	# Play navigation sound
	if AudioManager.instance:
		AudioManager.instance.play_sfx(navigate_sfx_index)

func select_current_item() -> void:
	"""Handle selection of current menu item"""
	# Play select sound
	if AudioManager.instance:
		AudioManager.instance.play_sfx(select_sfx_index)
	
	match selected_index:
		0: # New Game
			new_game_selected.emit()
		1: # Continue
			if has_save_game:
				continue_selected.emit()
		2: # Options
			options_selected.emit()
		3: # Help/Tutorial
			help_selected.emit()
		4: # Exit
			exit_selected.emit()

func show() -> void:
	"""Show the menu scene"""
	visible = true
	update_menu_display()

func hide_menu() -> void:
	"""Hide the menu scene"""
	visible = false
