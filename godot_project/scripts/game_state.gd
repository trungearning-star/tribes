## game_state.gd - Data Model trung tâm của game
## Port từ b.java (AI/gameplay logic) + f.java (game state arrays)
##
## Java gốc: Tất cả game data nằm trong các mảng byte/int lớn:
##   - this.e[] (~10000+ bytes): Main game state (units, buildings, resources)
##   - this.a[][]: Player/tribe stats
##   - this.b[][]: Map collision/ownership grid
##   - this.c[][]: Visual map layer (sprite indices)
##   - this.f[][]: Building registry
##
## Godot: Tách thành các biến có tên rõ ràng thay vì magic indices.
## Class này được dùng như một resource/data container, KHÔNG phải Node.
class_name GameState

# === CONSTANTS - Map dimensions ===
## Từ f.java: map grid sử dụng tile 22x16 pixels
## Map size được xác định khi load tilemap, tối đa ~96x96 tiles
const MAX_MAP_WIDTH := 96
const MAX_MAP_HEIGHT := 96

## Số lượng units tối đa (từ b.java: loop 1..50 cho player units, 51..100 cho AI)
const MAX_UNITS := 100

## Số lượng buildings tối đa (từ f.java: loop 1..30)
const MAX_BUILDINGS := 30

## Số tribes (players) trong game
const NUM_TRIBES := 3

# === ENUMS ===

## Unit types (từ b.java e[2828+v] values)
enum UnitType {
	WARRIOR = 0,      # Lính cơ bản
	ARCHER = 1,       # Cung thủ
	MAGE = 2,         # Pháp sư
	BUILDER = 3,      # Thợ xây
	HEALER = 4,       # Healer
	SCOUT = 5,        # Trinh sát
	KING = 6,         # Vua/lãnh đạo
	SPECIAL = 7,      # Unit đặc biệt
	NONE = 255,
}

## Building types (từ f.java building IDs ≥175)
enum BuildingType {
	HUT = 0,          # Nhà ở (tăng population)
	FARM = 1,         # Nông trại (sản xuất food)
	TOWER = 2,        # Tháp canh (phòng thủ)
	TEMPLE = 3,       # Đền thờ (mana/research)
	WALL = 4,         # Tường thành
	BARRACKS = 5,     # Trại lính (train units)
	MARKET = 6,       # Chợ (trade)
	WONDER = 7,       # Kỳ quan (win condition)
	NONE = 255,
}

## Terrain types (từ b.java b[y][x] values < 175)
enum TerrainType {
	GRASS = 0,
	WATER = 1,
	MOUNTAIN = 2,
	FOREST = 3,
	DESERT = 4,
	SWAMP = 5,
	ROAD = 6,
	BRIDGE = 7,
}

# === PLAYER/TRIBE DATA ===
## Port từ this.a[][] arrays trong f.java/b.java

## Tài nguyên của mỗi tribe [tribe_id][resource_type]
## Resource types: 0=food, 1=wood, 2=stone, 3=gold, 4=mana
var tribe_resources: Array = []  # [NUM_TRIBES][5] → int

## Tech level của mỗi tribe
var tribe_tech_level: Array = []  # [NUM_TRIBES] → int

## Population hiện tại / tối đa
var tribe_population: Array = []  # [NUM_TRIBES] → int
var tribe_max_population: Array = []  # [NUM_TRIBES] → int

## Tribe ID đang điều khiển (0-2)
var current_tribe: int = 0

# === UNIT DATA ===
## Port từ this.e[] array với các offset cụ thể
## Mỗi unit có ID từ 1-100, data lưu tại e[offset + unit_id]

## Vị trí unit trên map
## Tương ứng e[0+v] (X), e[101+v] (Y) trong Java
var unit_x: PackedByteArray = PackedByteArray()  # [MAX_UNITS+1]
var unit_y: PackedByteArray = PackedByteArray()  # [MAX_UNITS+1]

## Loại unit
## Tương ứng e[2828+v]
var unit_type: PackedByteArray = PackedByteArray()  # [MAX_UNITS+1]

## Trạng thái unit (idle, moving, attacking, etc.)
## Tương ứng e[6565+v]
var unit_state: PackedByteArray = PackedByteArray()  # [MAX_UNITS+1]

## HP hiện tại của unit
## Tương ứng e[1414+v]
var unit_hp: PackedByteArray = PackedByteArray()  # [MAX_UNITS+1]

## Owner tribe của unit (0-2 cho player tribes, >2 cho neutral/hostile)
## Tương ứng logic trong b.java a(x,y,owner) function
var unit_owner: PackedByteArray = PackedByteArray()  # [MAX_UNITS+1]

## Animation frame counter
## Tương ứng e[1313+unit_id]
var unit_anim_frame: PackedByteArray = PackedByteArray()  # [MAX_UNITS+1]

## Direction/facing (0=South, 1=West, 2=North, 3=East)
## Tương ứng e[5151+ao] & 3
var unit_direction: PackedByteArray = PackedByteArray()  # [MAX_UNITS+1]

## Active flag (unit tồn tại hay đã bị destroy)
## Tương ứng e[1919+v] != 0
var unit_active: PackedByteArray = PackedByteArray()  # [MAX_UNITS+1]

# === BUILDING DATA ===
## Port từ this.f[][] và e[8749+] arrays

## Vị trí building
var building_x: PackedByteArray = PackedByteArray()  # [MAX_BUILDINGS+1]
var building_y: PackedByteArray = PackedByteArray()  # [MAX_BUILDINGS+1]

## Loại building
var building_type: PackedByteArray = PackedByteArray()  # [MAX_BUILDINGS+1]

## Owner tribe
var building_owner: PackedByteArray = PackedByteArray()  # [MAX_BUILDINGS+1]

## HP / construction progress
var building_hp: PackedByteArray = PackedByteArray()  # [MAX_BUILDINGS+1]

## Active flag
var building_active: PackedByteArray = PackedByteArray()  # [MAX_BUILDINGS+1]

# === MAP DATA ===
## Port từ this.b[][] (collision/ownership) và this.c[][] (visual)

## Collision/ownership grid: b[y][x]
## Giá trị: 0=passable, 1-50=unit ID, >50=building, <0=special terrain
var map_collision: Array = []  # [MAX_MAP_HEIGHT][MAX_MAP_WIDTH] → int

## Visual layer: c[y][x]
## Giá trị: sprite index hoặc unit/building ID âm
var map_visual: Array = []  # [MAX_MAP_HEIGHT][MAX_MAP_WIDTH] → int

## Fog of war grid (true = explored, false = hidden)
## Tương ứng logic fog trong f.java save/load
var map_fog: Array = []  # [MAX_MAP_HEIGHT][MAX_MAP_WIDTH] → bool

# === GAME PROGRESS ===

## Turn counter (số lượt đã chơi)
var turn_count: int = 0

## Difficulty level (0-2)
var difficulty: int = 0

## Selected unit ID (-1 = none)
var selected_unit_id: int = -1

## Selected building ID (-1 = none)  
var selected_building_id: int = -1

## Camera position (tile coordinates)
## Tương ứng I, K trong f.java
var camera_tile_x: int = 0
var camera_tile_y: int = 0

# === INITIALIZATION ===

func _init() -> void:
	"""Khởi tạo tất cả arrays với kích thước đúng"""
	_init_tribe_data()
	_init_unit_arrays()
	_init_building_arrays()
	_init_map_arrays()


func _init_tribe_data() -> void:
	tribe_resources.resize(NUM_TRIBES)
	tribe_tech_level.resize(NUM_TRIBES)
	tribe_population.resize(NUM_TRIBES)
	tribe_max_population.resize(NUM_TRIBES)
	
	for i in range(NUM_TRIBES):
		tribe_resources[i] = [0, 0, 0, 0, 0]  # 5 resource types
		tribe_tech_level[i] = 0
		tribe_population[i] = 0
		tribe_max_population[i] = 10


func _init_unit_arrays() -> void:
	var size := MAX_UNITS + 1
	unit_x.resize(size)
	unit_y.resize(size)
	unit_type.resize(size)
	unit_state.resize(size)
	unit_hp.resize(size)
	unit_owner.resize(size)
	unit_anim_frame.resize(size)
	unit_direction.resize(size)
	unit_active.resize(size)
	
	# Zero-initialize
	for i in range(size):
		unit_x[i] = 0
		unit_y[i] = 0
		unit_type[i] = UnitType.NONE
		unit_state[i] = 0
		unit_hp[i] = 0
		unit_owner[i] = 0
		unit_anim_frame[i] = 0
		unit_direction[i] = 0
		unit_active[i] = 0


func _init_building_arrays() -> void:
	var size := MAX_BUILDINGS + 1
	building_x.resize(size)
	building_y.resize(size)
	building_type.resize(size)
	building_owner.resize(size)
	building_hp.resize(size)
	building_active.resize(size)
	
	for i in range(size):
		building_x[i] = 0
		building_y[i] = 0
		building_type[i] = BuildingType.NONE
		building_owner[i] = 0
		building_hp[i] = 0
		building_active[i] = 0


func _init_map_arrays() -> void:
	map_collision.resize(MAX_MAP_HEIGHT)
	map_visual.resize(MAX_MAP_HEIGHT)
	map_fog.resize(MAX_MAP_HEIGHT)
	
	for y in range(MAX_MAP_HEIGHT):
		map_collision[y] = PackedByteArray()
		map_collision[y].resize(MAX_MAP_WIDTH)
		map_visual[y] = PackedByteArray()
		map_visual[y].resize(MAX_MAP_WIDTH)
		map_fog[y] = []
		map_fog[y].resize(MAX_MAP_WIDTH)
		
		for x in range(MAX_MAP_WIDTH):
			map_collision[y][x] = 0
			map_visual[y][x] = 0
			map_fog[y][x] = false


# === HELPER FUNCTIONS ===

func is_valid_unit(unit_id: int) -> bool:
	"""Kiểm tra unit ID có hợp lệ và active không"""
	return unit_id >= 1 and unit_id <= MAX_UNITS and unit_active[unit_id] != 0


func get_unit_position(unit_id: int) -> Vector2i:
	"""Lấy vị trí tile của unit"""
	if not is_valid_unit(unit_id):
		return Vector2i(-1, -1)
	return Vector2i(unit_x[unit_id], unit_y[unit_id])


func set_unit_position(unit_id: int, x: int, y: int) -> void:
	"""Cập nhật vị trí unit và map grids"""
	if not is_valid_unit(unit_id):
		return
	
	# Xóa khỏi vị trí cũ
	var old_x := unit_x[unit_id]
	var old_y := unit_y[unit_id]
	if old_y >= 0 and old_y < MAX_MAP_HEIGHT and old_x >= 0 and old_x < MAX_MAP_WIDTH:
		map_collision[old_y][old_x] = 0
	
	# Set vị trí mới
	unit_x[unit_id] = x
	unit_y[unit_id] = y
	if y >= 0 and y < MAX_MAP_HEIGHT and x >= 0 and x < MAX_MAP_WIDTH:
		map_collision[y][x] = unit_id


func spawn_unit(tribe_id: int, type: int, x: int, y: int) -> int:
	"""
	Tạo unit mới. Trả về unit ID hoặc -1 nếu thất bại.
	Tương ứng logic trong b.java khi create new unit.
	"""
	# Tìm slot trống
	for id in range(1, MAX_UNITS + 1):
		if unit_active[id] == 0:
			unit_active[id] = 1
			unit_owner[id] = tribe_id
			unit_type[id] = type
			unit_hp[id] = 100  # Default HP, sẽ adjust theo type
			set_unit_position(id, x, y)
			return id
	
	push_warning("[GameState] No free unit slots available")
	return -1


func destroy_unit(unit_id: int) -> void:
	"""Xóa unit khỏi game"""
	if not is_valid_unit(unit_id):
		return
	
	var x := unit_x[unit_id]
	var y := unit_y[unit_id]
	if y >= 0 and y < MAX_MAP_HEIGHT and x >= 0 and x < MAX_MAP_WIDTH:
		map_collision[y][x] = 0
	
	unit_active[unit_id] = 0
	unit_type[unit_id] = UnitType.NONE


# === SAVE/LOAD ===
## Port từ f.java RecordStore save/load (L6472-6787)

func serialize() -> PackedByteArray:
	"""
	Serialize toàn bộ game state thành binary buffer.
	Tương ứng f.java e(int var1) save method.
	Format giữ nguyên thứ tự để compatible với Java gốc.
	"""
	var buf := PackedByteArray()
	
	# Tribe data
	buf.append(current_tribe)
	buf.append(turn_count)
	buf.append(difficulty)
	
	for t in range(NUM_TRIBES):
		for r in range(5):
			buf.append(tribe_resources[t][r] & 0xFF)
		buf.append(tribe_tech_level[t] & 0xFF)
		buf.append(tribe_population[t] & 0xFF)
	
	# Unit data
	for i in range(1, MAX_UNITS + 1):
		buf.append(unit_x[i])
		buf.append(unit_y[i])
		buf.append(unit_type[i])
		buf.append(unit_state[i])
		buf.append(unit_hp[i])
		buf.append(unit_owner[i])
		buf.append(unit_active[i])
	
	# Building data
	for i in range(1, MAX_BUILDINGS + 1):
		buf.append(building_x[i])
		buf.append(building_y[i])
		buf.append(building_type[i])
		buf.append(building_owner[i])
		buf.append(building_hp[i])
		buf.append(building_active[i])
	
	# Camera
	buf.append(camera_tile_x & 0xFF)
	buf.append(camera_tile_y & 0xFF)
	
	return buf


func deserialize(data: PackedByteArray) -> bool:
	"""
	Deserialize từ binary buffer.
	Tương ứng f.java d(int var1) load method.
	Returns: true nếu thành công.
	"""
	if data.size() < 10:
		push_error("[GameState] Save data too small: %d bytes" % data.size())
		return false
	
	var idx := 0
	
	# Tribe data
	current_tribe = data[idx]; idx += 1
	turn_count = data[idx]; idx += 1
	difficulty = data[idx]; idx += 1
	
	for t in range(NUM_TRIBES):
		for r in range(5):
			tribe_resources[t][r] = data[idx]; idx += 1
		tribe_tech_level[t] = data[idx]; idx += 1
		tribe_population[t] = data[idx]; idx += 1
	
	# Unit data
	for i in range(1, MAX_UNITS + 1):
		unit_x[i] = data[idx]; idx += 1
		unit_y[i] = data[idx]; idx += 1
		unit_type[i] = data[idx]; idx += 1
		unit_state[i] = data[idx]; idx += 1
		unit_hp[i] = data[idx]; idx += 1
		unit_owner[i] = data[idx]; idx += 1
		unit_active[i] = data[idx]; idx += 1
	
	# Building data
	for i in range(1, MAX_BUILDINGS + 1):
		building_x[i] = data[idx]; idx += 1
		building_y[i] = data[idx]; idx += 1
		building_type[i] = data[idx]; idx += 1
		building_owner[i] = data[idx]; idx += 1
		building_hp[i] = data[idx]; idx += 1
		building_active[i] = data[idx]; idx += 1
	
	# Camera
	camera_tile_x = data[idx]; idx += 1
	camera_tile_y = data[idx]; idx += 1
	
	# Rebuild collision map từ unit positions
	_rebuild_collision_map()
	
	print("[GameState] Deserialized: turn=%d, tribe=%d" % [turn_count, current_tribe])
	return true


func _rebuild_collision_map() -> void:
	"""Rebuild map_collision từ unit/building positions sau khi load"""
	# Clear collision map
	for y in range(MAX_MAP_HEIGHT):
		for x in range(MAX_MAP_WIDTH):
			map_collision[y][x] = 0
	
	# Place units
	for i in range(1, MAX_UNITS + 1):
		if unit_active[i] != 0:
			var x := unit_x[i]
			var y := unit_y[i]
			if y >= 0 and y < MAX_MAP_HEIGHT and x >= 0 and x < MAX_MAP_WIDTH:
				map_collision[y][x] = i

</content>