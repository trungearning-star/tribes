## Global Game State Manager
## Ported from tribes.java - Main game controller and state machine

class_name GameStateManager
extends Node

# Game states (equivalent to var_byte_a in d.java)
enum State {
	SPLASH_0 = 0,  # l0 - First splash screen
	SPLASH_1 = 1,  # l1 - Second splash screen
	SPLASH_2 = 2,  # l2 - Third splash screen
	MENU = 3,      # Main menu
	GAME = 5       # In-game
}

# Signals for state transitions
signal state_changed(new_state: State)
signal game_loaded(success: bool)

# Current state
var current_state: State = State.SPLASH_0

# Splash screen timing (in milliseconds, converted from Java Thread.sleep)
const SPLASH_DURATION_MS = 2000
const LOGO_DURATION_MS = 1000

# Singleton instance
static var instance: GameStateManager

# References to main scenes
var splash_screens: Array[Texture2D] = []
var current_splash_index: int = 0
var splash_timer: float = 0.0

func _ready() -> void:
	# Set up singleton
	instance = self
	
	# Load splash screen images
	load_splash_screens()
	
	# Start with first splash screen
	current_state = State.SPLASH_0
	splash_timer = LOGO_DURATION_MS / 1000.0  # Convert to seconds

func load_splash_screens() -> void:
	"""Load splash screen images from resources"""
	splash_screens.clear()
	
	# Load l0, l1, l2 images (logo screens)
	for i in range(3):
		var path = "res://sprites/l%d.png" % i
		if ResourceLoader.exists(path):
			var tex = load(path) as Texture2D
			splash_screens.append(tex)
		else:
			# Create placeholder if image not found
			var placeholder = Image.create(320, 240, false, Image.FORMAT_RGB8)
			placeholder.fill(Color(0.1, 0.1, 0.1 + i * 0.1))
			splash_screens.append(ImageTexture.create_from_image(placeholder))

func _process(delta: float) -> void:
	"""Handle state transitions and timing"""
	match current_state:
		State.SPLASH_0, State.SPLASH_1, State.SPLASH_2:
			handle_splash_state(delta)
		State.MENU:
			pass  # Menu handles its own logic
		State.GAME:
			pass  # Game handles its own logic

func handle_splash_state(delta: float) -> void:
	"""Handle splash screen timing and transitions"""
	splash_timer -= delta
	
	if splash_timer <= 0:
		current_splash_index += 1
		
		if current_splash_index < splash_screens.size():
			# Move to next splash screen
			current_state = current_splash_index as State
			splash_timer = LOGO_DURATION_MS / 1000.0
			state_changed.emit(current_state)
		else:
			# All splash screens shown, transition to menu
			current_state = State.MENU
			state_changed.emit(current_state)

func get_current_splash_texture() -> Texture2D:
	"""Get the current splash screen texture"""
	if current_splash_index >= 0 and current_splash_index < splash_screens.size():
		return splash_screens[current_splash_index]
	return null

func start_game() -> void:
	"""Transition to game state"""
	current_state = State.GAME
	state_changed.emit(current_state)

func return_to_menu() -> void:
	"""Return to main menu from any state"""
	current_state = State.MENU
	state_changed.emit(current_state)

func save_game() -> bool:
	"""Save current game state (port of boolean_e in f.java)"""
	# TODO: Implement save system
	return true

func load_game(slot: int) -> bool:
	"""Load game from save slot (port of boolean_d in f.java)"""
	# TODO: Implement load system
	return false
