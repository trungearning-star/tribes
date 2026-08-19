## GameManager.gd - Singleton quản lý trạng thái game chính
## Port từ tribes.java (MIDlet lifecycle) + f.java (game state machine)
## 
## Java gốc: tribes.java startApp() → f.java run() loop với biến v (state)
## Godot: _ready() thay startApp(), _process() thay run() loop
extends Node

# === ENUMS - Tương ứng với các magic number trong Java code ===

## Trạng thái game chính (từ f.java biến v)
enum GameState {
	SPLASH = 0,      # Màn hình logo/splash (d.java)
	MAIN_MENU = 1,   # Menu chọn tribe/save slot
	GAMEPLAY = 2,    # Vòng lặp game chính
	PAUSED = 3,      # Tạm dừng
	DIALOGUE = 4,    # Hộp thoại/cutscene
	GAME_OVER = 5,   # Kết thúc game
}

## ID của 3 tribes trong game (từ b.java, index 0-2 cho player tribes)
enum TribeId {
	TRIBE_A = 0,
	TRIBE_B = 1,
	TRIBE_C = 2,
	NONE = 255,
}

# === STATE VARIABLES ===

## Trạng thái hiện tại của game
var current_state: GameState = GameState.SPLASH

## Tribe đang được người chơi điều khiển (0-2)
var player_tribe: int = TribeId.TRIBE_A

## Difficulty level (từ save slot 0, byte r)
var difficulty: int = 0

## Sound enabled flag (từ save slot 0, bool W)
var sound_enabled: bool = true

## Current turn number (từ f.java biến c, đọc ở L6540)
var turn_number: int = 0

## Camera position (từ f.java I=camX, K=camY, L6545)
var camera_x: int = 0
var camera_y: int = 0

## Fog of war enabled (từ f.java biến N, L6546)
var fog_of_war: bool = false

## Selected unit/building index (1-100 cho units, 1-60 cho buildings)
var selected_entity_id: int = -1

## Language/locale index (0=Vietnamese, 1-4=others)
var locale_index: int = 0

# === SIGNALS ===

## Phát ra khi trạng thái game thay đổi
signal state_changed(new_state: GameState)

## Phát ra khi lượt mới bắt đầu
signal turn_started(turn: int)

## Phát ra khi entity được chọn/bỏ chọn
signal entity_selected(entity_id: int)

# === LIFECYCLE ===

func _ready() -> void:
	"""
	Tương ứng tribes.java startApp():
	- Khởi tạo resource manager
	- Load settings từ save slot 0
	- Chuyển sang SPLASH screen
	
	Trong Java: startApp() → new f() → f.run()
	Trong Godot: _ready() tự động gọi khi scene tree sẵn sàng
	"""
	print("[GameManager] Initializing...")
	
	# Load global settings từ save slot 0
	load_global_settings()
	
	# Bắt đầu với splash screen
	change_state(GameState.SPLASH)


func change_state(new_state: GameState) -> void:
	"""
	Thay đổi trạng thái game và phát signal.
	Tương ứng với việc gán this.v = newState trong f.java
	"""
	if current_state == new_state:
		return
	
	var old_state := current_state
	current_state = new_state
	print("[GameManager] State: %s → %s" % [GameState.keys()[old_state], GameState.keys()[new_state]])
	state_changed.emit(new_state)


# === SAVE/LOAD SYSTEM ===
## Port từ f.java L6472-6787 (RecordStore → FileAccess)
## Save slot 0: Global settings
## Save slot 1-2: Full game state

const SAVE_PATH_FORMAT := "user://save_slot_%d.dat"

func load_global_settings() -> void:
	"""
	Load save slot 0 chứa global settings.
	Tương ứng f.java L6482-6493:
	  readInt(l) → last_tribe
	  readBoolean(W) → sound_enabled  
	  readByte(r) → difficulty
	  readByte(s/t/c/p) → various flags
	"""
	var path := SAVE_PATH_FORMAT % 0
	if not FileAccess.file_exists(path):
		print("[GameManager] No save slot 0 found, using defaults")
		return
	
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("[GameManager] Failed to open save slot 0")
		return
	
	# Đọc theo đúng thứ tự binary big-endian như Java DataInputStream
	player_tribe = file.get_32()  # readInt → last selected tribe
	sound_enabled = file.get_8() != 0  # readBoolean
	difficulty = file.get_8()  # readByte
	
	file.close()
	print("[GameManager] Loaded settings: tribe=%d, sound=%s, diff=%d" % [
		player_tribe, str(sound_enabled), difficulty])


func save_global_settings() -> void:
	"""
	Lưu global settings vào save slot 0.
	Tương ứng f.java e(int var1) với var1==0
	"""
	var path := SAVE_PATH_FORMAT % 0
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[GameManager] Failed to write save slot 0")
		return
	
	file.store_32(player_tribe)
	file.store_8(1 if sound_enabled else 0)
	file.store_8(difficulty)
	
	file.close()
	print("[GameManager] Saved global settings")


func has_save_slot(slot: int) -> bool:
	"""Kiểm tra xem save slot có tồn tại không"""
	return FileAccess.file_exists(SAVE_PATH_FORMAT % slot)


# === INPUT HELPERS ===
## Map từ J2ME key codes sang Godot input actions
## Tham khảo f.java keyPressed() L3402-3514

func get_movement_direction() -> Vector2i:
	"""
	Trả về hướng di chuyển từ input.
	Tương ứng với việc kiểm tra KEY_UP/DOWN/LEFT/RIGHT trong keyPressed()
	"""
	var dir := Vector2i.ZERO
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1
	if Input.is_action_pressed("ui_down"):
		dir.y += 1
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		dir.x += 1
	return dir


func is_accept_pressed() -> bool:
	"""Tương ứng KEY_FIRE (103) / getGameAction(8)"""
	return Input.is_action_just_pressed("ui_accept")


func is_cancel_pressed() -> bool:
	"""Tương ứng phím Back/Cancel"""
	return Input.is_action_just_pressed("ui_cancel")

</content>