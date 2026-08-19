## save_manager.gd - Singleton quản lý Save/Load game
## Port từ f.java RecordStore save/load (L6472-6787)
##
## Java gốc: Dùng javax.microedition.rms.RecordStore để lưu binary data
##   - Slot 0: Global settings (tribe, sound, difficulty)
##   - Slot 1-2: Full game state
##
## Godot: Dùng FileAccess + user:// directory
##   Trên Android/Web: user:// map đến app data directory tự động
extends Node

# === CONSTANTS ===

## Số lượng save slots tối đa
const MAX_SAVE_SLOTS := 3

## Path prefix cho save files
const SAVE_PATH_PREFIX := "user://save_slot_"

## Magic number để verify save file hợp lệ
const SAVE_MAGIC := 0x54524942  # "TRIB" in ASCII

## Version của save format (để handle migration sau này)
const SAVE_VERSION := 1


func _ready() -> void:
	print("[SaveManager] Initialized")


# === SAVE ===

func save_game(slot: int, game_state: GameState) -> bool:
	"""
	Lưu game state vào slot chỉ định.
	Tương ứng f.java e(int var1) method.
	
	slot: 0 = settings only, 1-2 = full game state
	
	Returns: true nếu lưu thành công
	"""
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		push_error("[SaveManager] Invalid save slot: %d" % slot)
		return false
	
	var path := "%s%d.dat" % [SAVE_PATH_PREFIX, slot]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Failed to open save file for writing: %s" % path)
		return false
	
	# Write header
	file.store_32(SAVE_MAGIC)
	file.store_8(SAVE_VERSION)
	file.store_8(slot)
	
	# Serialize game state
	var data := game_state.serialize()
	file.store_32(data.size())
	file.store_buffer(data)
	
	file.close()
	
	print("[SaveManager] Saved slot %d: %d bytes → %s" % [slot, data.size(), path])
	return true


# === LOAD ===

func load_game(slot: int, game_state: GameState) -> bool:
	"""
	Load game state từ slot chỉ định.
	Tương ứng f.java d(int var1) method.
	
	slot: 0 = settings only, 1-2 = full game state
	
	Returns: true nếu load thành công
	"""
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		push_error("[SaveManager] Invalid save slot: %d" % slot)
		return false
	
	var path := "%s%d.dat" % [SAVE_PATH_PREFIX, slot]
	if not FileAccess.file_exists(path):
		print("[SaveManager] No save file at slot %d" % slot)
		return false
	
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[SaveManager] Failed to open save file: %s" % path)
		return false
	
	# Read & verify header
	var magic := file.get_32()
	if magic != SAVE_MAGIC:
		push_error("[SaveManager] Invalid save file magic: 0x%08X" % magic)
		file.close()
		return false
	
	var version := file.get_8()
	if version != SAVE_VERSION:
		push_warning("[SaveManager] Save version mismatch: expected %d, got %d" % [SAVE_VERSION, version])
		# TODO: Handle migration if needed
	
	var saved_slot := file.get_8()
	var data_size := file.get_32()
	
	# Read serialized data
	var data := file.get_buffer(data_size)
	file.close()
	
	if data.size() != data_size:
		push_error("[SaveManager] Save data truncated: expected %d, got %d" % [data_size, data.size()])
		return false
	
	# Deserialize
	var success := game_state.deserialize(data)
	if success:
		print("[SaveManager] Loaded slot %d: %d bytes from %s" % [slot, data_size, path])
	else:
		push_error("[SaveManager] Failed to deserialize save data from slot %d" % slot)
	
	return success


# === SLOT MANAGEMENT ===

func has_save(slot: int) -> bool:
	"""Kiểm tra xem slot có save file không"""
	var path := "%s%d.dat" % [SAVE_PATH_PREFIX, slot]
	return FileAccess.file_exists(path)


func delete_save(slot: int) -> bool:
	"""Xóa save file tại slot chỉ định"""
	var path := "%s%d.dat" % [SAVE_PATH_PREFIX, slot]
	if FileAccess.file_exists(path):
		var err := DirAccess.remove_absolute(path)
		if err == OK:
			print("[SaveManager] Deleted save slot %d" % slot)
			return true
		else:
			push_error("[SaveManager] Failed to delete save slot %d: error %d" % [slot, err])
			return false
	return false


func get_save_info(slot: int) -> Dictionary:
	"""
	Lấy thông tin cơ bản về save file mà không cần load toàn bộ.
	Dùng để hiển thị trong menu Load Game.
	
	Returns: {exists: bool, turn_count: int, tribe: int, timestamp: String}
	"""
	var info := {"exists": false, "turn_count": 0, "tribe": 0, "timestamp": ""}
	
	if not has_save(slot):
		return info
	
	info.exists = true
	
	var path := "%s%d.dat" % [SAVE_PATH_PREFIX, slot]
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return info
	
	# Skip magic + version + slot
	file.get_32()
	file.get_8()
	file.get_8()
	
	var data_size := file.get_32()
	if data_size >= 3:
		# Read first 3 bytes of serialized data: tribe, turn_count, difficulty
		info.tribe = file.get_8()
		info.turn_count = file.get_8()
		# difficulty = file.get_8()  # Not needed for display
	
	file.close()
	
	# Get file modification time
	var modified_time := FileAccess.get_modified_time(path)
	if modified_time > 0:
		var dt := Time.get_datetime_dict_from_unix_time(modified_time)
		info.timestamp = "%04d-%02d-%02d %02d:%02d" % [
			dt.year, dt.month, dt.day, dt.hour, dt.minute
		]
	
	return info

</content>