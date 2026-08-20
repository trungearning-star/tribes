extends Node2D

## Main Scene Controller
## Handles scene transitions and global game flow
## Ported from tribes.java (MIDlet lifecycle)

@onready var splash_sprite: Sprite2D = $SplashSprite
@onready var ui_layer: CanvasLayer = $UILayer
@onready var virtual_controls: VirtualControls = $UILayer/VirtualControls if $UILayer.has_node("VirtualControls") else null

var game_state: GameStateManager
var current_texture: Texture2D
var is_game_running: bool = false

func _ready() -> void:
	# Get or create game state manager
	if not GameStateManager.instance:
		game_state = GameStateManager.new()
		add_child(game_state)
	else:
		game_state = GameStateManager.instance
	
	# Connect to state changes
	game_state.state_changed.connect(_on_state_changed)
	
	# Setup virtual controls if available
	if virtual_controls:
		virtual_controls.show_controls = true
		_connect_control_signals()
	
	# Initialize display
	current_texture = game_state.get_current_splash_texture()
	if current_texture:
		splash_sprite.texture = current_texture

func _connect_control_signals() -> void:
	"""Connect virtual control signals to game actions"""
	virtual_controls.left_pressed.connect(_on_left_pressed)
	virtual_controls.left_released.connect(_on_left_released)
	virtual_controls.right_pressed.connect(_on_right_pressed)
	virtual_controls.right_released.connect(_on_right_released)
	virtual_controls.up_pressed.connect(_on_up_pressed)
	virtual_controls.up_released.connect(_on_up_released)
	virtual_controls.down_pressed.connect(_on_down_pressed)
	virtual_controls.down_released.connect(_on_down_released)
	virtual_controls.select_pressed.connect(_on_select_pressed)
	virtual_controls.menu_pressed.connect(_on_menu_pressed)
	virtual_controls.help_pressed.connect(_on_help_pressed)

func _process(_delta: float) -> void:
	"""Update display based on current state"""
	match game_state.current_state:
		GameStateManager.State.SPLASH_0, \
		GameStateManager.State.SPLASH_1, \
		GameStateManager.State.SPLASH_2:
			var tex = game_state.get_current_splash_texture()
			if tex and tex != current_texture:
				current_texture = tex
				splash_sprite.texture = current_texture
		GameStateManager.State.MENU:
			pass  # Menu scene handles itself
		GameStateManager.State.GAME:
			pass  # Game scene handles itself

func _on_state_changed(new_state: GameStateManager.State) -> void:
	"""Handle game state transitions"""
	print("State changed to: ", new_state)
	
	match new_state:
		GameStateManager.State.SPLASH_0, \
		GameStateManager.State.SPLASH_1, \
		GameStateManager.State.SPLASH_2:
			show_splash_screen()
		GameStateManager.State.MENU:
			show_main_menu()
		GameStateManager.State.GAME:
			start_game()

func show_splash_screen() -> void:
	"""Display current splash screen"""
	splash_sprite.visible = true
	current_texture = game_state.get_current_splash_texture()
	if current_texture:
		splash_sprite.texture = current_texture

func show_main_menu() -> void:
	"""Transition to main menu scene"""
	print("Showing main menu...")
	
	# Hide splash
	splash_sprite.visible = false
	
	# Show and enable menu
	if ui_layer.has_node("MainMenuScene"):
		var menu = ui_layer.get_node("MainMenuScene") as MainMenuScene
		menu.show()
		
		# Connect menu signals
		if not menu.new_game_selected.is_connected(_on_menu_new_game):
			menu.new_game_selected.connect(_on_menu_new_game)
		if not menu.continue_selected.is_connected(_on_menu_continue):
			menu.continue_selected.connect(_on_menu_continue)
		if not menu.options_selected.is_connected(_on_menu_options):
			menu.options_selected.connect(_on_menu_options)
		if not menu.help_selected.is_connected(_on_menu_help):
			menu.help_selected.connect(_on_menu_help)
		if not menu.exit_selected.is_connected(_on_menu_exit):
			menu.exit_selected.connect(_on_menu_exit)

func start_game() -> void:
	"""Start the main game"""
	print("Starting game...")
	
	# Hide menu if visible
	if ui_layer.has_node("MainMenuScene"):
		var menu = ui_layer.get_node("MainMenuScene") as MainMenuScene
		menu.hide_menu()
	
	# Show virtual controls for gameplay
	if virtual_controls:
		virtual_controls.show_controls = true
	
	# TODO: Initialize game scene
	is_game_running = true

# Menu signal handlers
func _on_menu_new_game() -> void:
	print("New Game selected")
	game_state.start_game()

func _on_menu_continue() -> void:
	print("Continue selected")
	var success = game_state.load_game(1)  # Load slot 1
	if success:
		game_state.current_state = GameStateManager.State.GAME
	else:
		print("No save game found")

func _on_menu_options() -> void:
	print("Options selected")
	# TODO: Show options screen

func _on_menu_help() -> void:
	print("Help selected")
	# TODO: Show help/tutorial screen

func _on_menu_exit() -> void:
	print("Exit selected")
	# On mobile, this will minimize the app
	get_tree().quit()

# Input handlers - mapped from Java key events
func _on_left_pressed() -> void:
	_handle_key_press(1)  # KEY_LEFT

func _on_left_released() -> void:
	_handle_key_release(1)

func _on_right_pressed() -> void:
	_handle_key_press(6)  # KEY_RIGHT

func _on_right_released() -> void:
	_handle_key_release(6)

func _on_up_pressed() -> void:
	_handle_key_press(2)  # KEY_UP

func _on_up_released() -> void:
	_handle_key_release(2)

func _on_down_pressed() -> void:
	_handle_key_press(5)  # KEY_DOWN

func _on_down_released() -> void:
	_handle_key_release(5)

func _on_select_pressed() -> void:
	_handle_key_press(0)  # SELECT/ENTER

func _on_menu_pressed() -> void:
	_handle_key_press(3)  # MENU/BACK

func _on_help_pressed() -> void:
	_handle_key_press(4)  # HELP/0

func _handle_key_press(key_code: int) -> void:
	"""Handle key press event (port of keyPressed in Java)"""
	match game_state.current_state:
		GameStateManager.State.SPLASH_0, \
		GameStateManager.State.SPLASH_1, \
		GameStateManager.State.SPLASH_2:
			# Skip splash on keypress
			pass
		GameStateManager.State.MENU:
			_menu_input(key_code)
		GameStateManager.State.GAME:
			_game_input(key_code)

func _handle_key_release(key_code: int) -> void:
	"""Handle key release event"""
	pass

func _menu_input(key_code: int) -> void:
	"""Handle menu input (port of menu key handling in f.java)"""
	if not ui_layer.has_node("MainMenuScene"):
		return
	
	var menu = ui_layer.get_node("MainMenuScene") as MainMenuScene
	
	match key_code:
		2:  # KEY_UP
			menu.handle_input("up")
		5:  # KEY_DOWN
			menu.handle_input("down")
		0:  # SELECT/ENTER
			menu.handle_input("select")
		3:  # MENU/BACK
			menu.handle_input("menu")

func _game_input(key_code: int) -> void:
	"""Handle in-game input"""
	# Game will handle its own input
	pass
