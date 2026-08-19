## main_menu.gd - Menu chính của game
## Port từ f.java state MAIN_MENU (v==1) + tribe selection logic
##
## Java gốc: f.java vẽ menu bằng Graphics.drawString(), xử lý key navigation
## Godot: Dùng Control nodes + Button signals
extends Control

@onready var new_game_btn: Button = $VBoxContainer/NewGameBtn
@onready var load_game_btn: Button = $VBoxContainer/LoadGameBtn
@onready var settings_btn: Button = $VBoxContainer/SettingsBtn
@onready var quit_btn: Button = $VBoxContainer/QuitBtn


func _ready() -> void:
	"""
	Tương ứng f.java khi v==1 (MAIN_MENU state):
	- Vẽ tiêu đề "TRIBES"
	- Hiển thị options: New Game, Load Game, Settings, Quit
	- Navigation bằng UP/DOWN + FIRE để chọn
	"""
	# Connect button signals
	new_game_btn.pressed.connect(_on_new_game)
	load_game_btn.pressed.connect(_on_load_game)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)
	
	# Focus default button (cho keyboard/gamepad navigation)
	new_game_btn.grab_focus()
	
	print("[MainMenu] Ready")


func _on_new_game() -> void:
	"""
	Bắt đầu game mới.
	Tương ứng f.java: chọn tribe → init game state → v=2 (GAMEPLAY)
	"""
	print("[MainMenu] New Game selected")
	GameManager.change_state(GameManager.GameState.GAMEPLAY)
	get_tree().change_scene_to_file("res://scenes/game_world.tscn")


func _on_load_game() -> void:
	"""
	Mở màn hình load game.
	Tương ứng f.java: check RecordStore slots 1-2
	"""
	print("[MainMenu] Load Game selected")
	# TODO: Implement save slot selection UI
	# Kiểm tra xem có save nào không
	var has_save_1 := GameManager.has_save_slot(1)
	var has_save_2 := GameManager.has_save_slot(2)
	print("  Slot 1: %s, Slot 2: %s" % [str(has_save_1), str(has_save_2)])


func _on_settings() -> void:
	"""Mở settings (sound, difficulty, language)"""
	print("[MainMenu] Settings selected")
	# TODO: Implement settings UI


func _on_quit() -> void:
	"""Thoát game"""
	print("[MainMenu] Quit")
	get_tree().quit()

</content>