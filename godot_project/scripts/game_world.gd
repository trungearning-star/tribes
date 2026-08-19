## game_world.gd - Scene chính của gameplay
## Port từ f.java run() loop + rendering pipeline
##
## Java gốc: f.java extends Canvas implements Runnable
##   - run(): game loop với Thread.sleep(50) ≈ 20 FPS
##   - paint(Graphics g): render tilemap → entities → UI
##   - keyPressed/keyReleased: input handling
##
## Godot: Node2D với _process() thay run(), _draw() thay paint()
##   Viewport 320x240 đã được set trong Project Settings
extends Node2D

# === CONSTANTS ===

## Tile size trong pixels (từ f.java: 22px wide, 16px tall per tile)
const TILE_WIDTH := 22
const TILE_HEIGHT := 16

## Viewport dimensions
const VIEW_WIDTH := 320
const VIEW_HEIGHT := 240

## Map dimensions (tiles) - sẽ được xác định khi load map
var map_width: int = 0
var map_height: int = 0

# === GAME STATE ===

## Data model trung tâm chứa toàn bộ game data
## Port từ b.java/f.java arrays
var game_state: GameState = null

# === CAMERA & SELECTION ===

## Camera offset (pixel coordinates, top-left of viewport)
## Tương ứng f.java I (camX), K (camY)
var camera_pixel_x: int = 0
var camera_pixel_y: int = 0

## Current selection cursor position (tile coordinates)
var cursor_tile_x: int = 0
var cursor_tile_y: int = 0

## Selected entity ID (-1 = none)
var selected_entity_id: int = -1
## Frame counter cho animation (từ f.java biến f)
var anim_frame: int = 0

## Scroll offset accumulator (từ f.java ah, ai)
var scroll_offset_x: int = 0
var scroll_offset_y: int = 0

# === NODE REFERENCES ===

@onready var tile_map_layer: Node2D = $TileMapLayer
@onready var entity_layer: Node2D = $EntityLayer
@onready var hud: Control = $UILayer/HUD
@onready var selection_cursor: Sprite2D = $SelectionCursor

# === LIFECYCLE ===

func _ready() -> void:
	"""
	Tương ứng f.java constructor + f() + g() init methods:
	- Khởi tạo GameState
	- Load resources (sprites, localization, tilemap)
	- Set initial camera position
	"""
	print("[GameWorld] Initializing...")
	
	# Khởi tạo game state data model
	game_state = GameState.new()
	
	# Preload sprites để tránh stutter khi render
	for pack in ResourceManager.SPRITE_PACKS:
		ResourceManager.preload_sprite_pack(pack)
	
	# Load localization và tilemap
	ResourceManager.load_localization(GameManager.locale_index)
	ResourceManager.load_tilemap()
	
	# TODO: Load game state từ save file nếu có
	# TODO: Set initial camera to player tribe's starting position
	
	# Placeholder map size (sẽ thay bằng tilemap thực)
	map_width = 20
	map_height = 15
	
	# Sync camera với game_state
	game_state.camera_tile_x = map_width / 2
	game_state.camera_tile_y = map_height / 2
	
	# Center cursor on screen
	cursor_tile_x = game_state.camera_tile_x
	cursor_tile_y = game_state.camera_tile_y
	
	print("[GameWorld] Ready - map %dx%d, camera at (%d, %d)" % [
		map_width, map_height, camera_pixel_x, camera_pixel_y])


func _process(delta: float) -> void:
	"""
	Game loop chính.
	Tương ứng f.java run() method:
	  while(true) { 
	    handleInput(); 
	    updateLogic(); 
	    repaint(); 
	    Thread.sleep(50); 
	  }
	
	Godot gọi _process mỗi frame (~60fps), delta = seconds since last frame
	"""
	_handle_input(delta)
	_update_camera(delta)
	_update_animation(delta)
	
	# Force redraw when camera or entities change
	queue_redraw()


func _draw() -> void:
	"""
	Render pipeline.
	Tương ứng f.java paint(Graphics g):
	  1. Draw background tiles (method o())
	  2. Draw static objects/buildings (≥175)
	  3. Draw units (1-100) with animation
	  4. Draw UI overlay (method m())
	  5. Draw effects/particles
	
	TODO: Implement actual tile/entity rendering
	Hiện tại chỉ vẽ placeholder grid.
	"""
	# Draw background tile grid
	_draw_placeholder_grid()
	
	# Draw entities (units/buildings) từ game_state
	_draw_entities()
	
	# Draw selection cursor highlight
	_draw_cursor_highlight()


# === INPUT HANDLING ===
## Port từ f.java keyPressed() L3402-3514

func _handle_input(delta: float) -> void:
	"""
	Xử lý input mỗi frame.
	Tương ứng f.java keyPressed() nhưng dùng polling thay vì event-driven.
	"""
	var dir := GameManager.get_movement_direction()
	
	if dir != Vector2i.ZERO:
		# Move cursor
		cursor_tile_x += dir.x
		cursor_tile_y += dir.y
		
		# Clamp to map bounds
		cursor_tile_x = clampi(cursor_tile_x, 0, map_width - 1)
		cursor_tile_y = clampi(cursor_tile_y, 0, map_height - 1)
		
		# Update selection cursor visual position
		selection_cursor.visible = true
		selection_cursor.position = Vector2(
			cursor_tile_x * TILE_WIDTH - camera_pixel_x,
			cursor_tile_y * TILE_HEIGHT - camera_pixel_y
		)
	
	# Accept/Action button
	if GameManager.is_accept_pressed():
		_on_accept_action()
	
	# Cancel button
	if GameManager.is_cancel_pressed():
		_on_cancel_action()
	
	# Build menu
	if Input.is_action_just_pressed("ui_build"):
		_open_build_menu()
	
	# Focus camera on selected entity
	if Input.is_action_just_pressed("ui_focus"):
		_focus_on_selection()


func _on_accept_action() -> void:
	"""
	Tương ứng KEY_FIRE (103) trong f.java:
	- Nếu chưa chọn gì → select unit/building tại cursor
	- Nếu đã chọn unit → issue move command đến cursor
	"""
	if not game_state:
		return
	
	var cx := cursor_tile_x
	var cy := cursor_tile_y
	
	# Bounds check
	if cx < 0 or cx >= GameState.MAX_MAP_WIDTH or cy < 0 or cy >= GameState.MAX_MAP_HEIGHT:
		_on_cancel_action()
		return
	
	var cell_value: int = game_state.map_collision[cy][cx]
	
	if selected_entity_id > 0 and cell_value == 0:
		# Đã chọn unit + click vào ô trống → di chuyển
		_issue_move_command(selected_entity_id, cx, cy)
	elif cell_value > 0 and game_state.is_valid_unit(cell_value):
		# Select unit tại cursor
		selected_entity_id = cell_value
		game_state.selected_unit_id = cell_value
		print("[GameWorld] Selected unit %d at (%d,%d) type=%d owner=%d hp=%d" % [
			cell_value, cx, cy,
			game_state.unit_type[cell_value],
			game_state.unit_owner[cell_value],
			game_state.unit_hp[cell_value]])
	else:
		# Empty tile hoặc building → deselect
		_on_cancel_action()


func _on_cancel_action() -> void:
	"""Tương ứng phím Back/Cancel: deselect hoặc mở pause menu"""
	selected_entity_id = -1
	if game_state:
		game_state.selected_unit_id = -1
		game_state.selected_building_id = -1
	selection_cursor.visible = false
	print("[GameWorld] Deselected")


func _issue_move_command(unit_id: int, target_x: int, target_y: int) -> void:
	"""
	Ra lệnh di chuyển cho unit.
	Port từ b.java pathfinding a(var1,var2,var3,var4,var5).
	Dùng Pathfinding.find_path() BFS để tìm đường đi hợp lệ.
	"""
	if not game_state or not game_state.is_valid_unit(unit_id):
		return
	
	var start := game_state.get_unit_position(unit_id)
	var owner: int = game_state.unit_owner[unit_id]
	
	# Find path using BFS
	var result := Pathfinding.find_path(
		game_state,
		start.x, start.y,
		target_x, target_y,
		owner
	)
	
	if result.found and result.path.size() > 1:
		# Move unit to next tile in path (one step per command for now)
		# TODO: Implement smooth multi-step movement with animation
		var next_tile: Vector2i = result.path[1]  # [0] is current position
		print("[GameWorld] Move unit %d: (%d,%d) → (%d,%d), path length=%d, cost=%d" % [
			unit_id, start.x, start.y, next_tile.x, next_tile.y,
			result.path.size(), result.total_cost])
		game_state.set_unit_position(unit_id, next_tile.x, next_tile.y)
	else:
		print("[GameWorld] No path found for unit %d to (%d,%d)" % [unit_id, target_x, target_y])


func _open_build_menu() -> void:
	"""Tương ứng phím 'b': mở build menu"""
	print("[GameWorld] Build menu")
	# TODO: Implement build menu UI


func _focus_on_selection() -> void:
	"""Tương ứng phím 'f': center camera on selected entity"""
	if GameManager.selected_entity_id > 0:
		# TODO: Get entity position và move camera
		print("[GameWorld] Focus on entity %d" % GameManager.selected_entity_id)


# === CAMERA ===

func _update_camera(delta: float) -> void:
	"""
	Cập nhật camera position.
	Tương ứng f.java n() method với scroll logic (ah, ai variables).
	Camera follow cursor với smooth scrolling.
	"""
	# Target: center cursor on screen
	var target_x := cursor_tile_x * TILE_WIDTH - VIEW_WIDTH / 2
	var target_y := cursor_tile_y * TILE_HEIGHT - VIEW_HEIGHT / 2
	
	# Smooth lerp (tương ứng scroll interpolation trong n())
	var speed := 8.0 * delta
	camera_pixel_x = lerpi(camera_pixel_x, target_x, speed)
	camera_pixel_y = lerpi(camera_pixel_y, target_y, speed)
	
	# Clamp to map bounds
	var max_cam_x := map_width * TILE_WIDTH - VIEW_WIDTH
	var max_cam_y := map_height * TILE_HEIGHT - VIEW_HEIGHT
	camera_pixel_x = clampi(camera_pixel_x, 0, maxi(max_cam_x, 0))
	camera_pixel_y = clampi(camera_pixel_y, 0, maxi(max_cam_y, 0))


# === ANIMATION ===

func _update_animation(delta: float) -> void:
	"""
	Update animation frame counter.
	Tương ứng f.java biến f increment trong run() loop.
	Dùng để cycle sprite animation frames.
	"""
	anim_frame += 1


# === PLACEHOLDER RENDERING ===

func _draw_placeholder_grid() -> void:
	"""Vẽ grid placeholder để verify camera/rendering hoạt động"""
	var start_col := camera_pixel_x / TILE_WIDTH
	var end_col := start_col + VIEW_WIDTH / TILE_WIDTH + 1
	var start_row := camera_pixel_y / TILE_HEIGHT
	var end_row := start_row + VIEW_HEIGHT / TILE_HEIGHT + 1
	
	var grid_color := Color(0.2, 0.2, 0.3, 0.5)
	
	for row in range(start_row, end_row + 1):
		var y := row * TILE_HEIGHT - camera_pixel_y
		draw_line(Vector2(0, y), Vector2(VIEW_WIDTH, y), grid_color)
	
	for col in range(start_col, end_col + 1):
		var x := col * TILE_WIDTH - camera_pixel_x
		draw_line(Vector2(x, 0), Vector2(x, VIEW_HEIGHT), grid_color)


func _draw_entities() -> void:
	"""
	Vẽ units và buildings lên screen.
	Port từ f.java o() + a(int,byte) rendering methods.
	Duyệt viewport area, check collision grid, draw sprite tương ứng.
	"""
	if not game_state:
		return
	
	var start_col := maxi(0, camera_pixel_x / TILE_WIDTH)
	var end_col := mini(GameState.MAX_MAP_WIDTH - 1, (camera_pixel_x + VIEW_WIDTH) / TILE_WIDTH + 1)
	var start_row := maxi(0, camera_pixel_y / TILE_HEIGHT)
	var end_row := mini(GameState.MAX_MAP_HEIGHT - 1, (camera_pixel_y + VIEW_HEIGHT) / TILE_HEIGHT + 1)
	
	for row in range(start_row, end_row + 1):
		for col in range(start_col, end_col + 1):
			var cell_value: int = game_state.map_collision[row][col]
			
			if cell_value > 0 and game_state.is_valid_unit(cell_value):
				_draw_unit(cell_value, col, row)
			elif cell_value < 0:
				_draw_building_placeholder(col, row, cell_value)


func _draw_unit(unit_id: int, col: int, row: int) -> void:
	"""Vẽ một unit tại vị trí grid"""
	var type_val: int = game_state.unit_type[unit_id]
	var owner: int = game_state.unit_owner[unit_id]
	
	# Thử load sprite từ pi0 pack (placeholder mapping)
	# TODO: Map chính xác type → sprite index từ j[][] lookup table
	var texture := ResourceManager.get_sprite("pi0", type_val)
	
	var draw_x := col * TILE_WIDTH - camera_pixel_x
	var draw_y := row * TILE_HEIGHT - camera_pixel_y
	
	if texture:
		draw_texture(texture, Vector2(draw_x, draw_y))
	else:
		# Fallback: colored rect based on owner tribe
		var color: Color
		match owner:
			0: color = Color(0.2, 0.8, 0.2)  # Tribe A: green
			1: color = Color(0.8, 0.2, 0.2)  # Tribe B: red
			2: color = Color(0.2, 0.2, 0.8)  # Tribe C: blue
			_: color = Color(0.5, 0.5, 0.5)  # Neutral: gray
		
		var rect := Rect2(draw_x + 2, draw_y + 2, TILE_WIDTH - 4, TILE_HEIGHT - 4)
		draw_rect(rect, color)
		
		# Draw HP bar nhỏ phía trên
		var hp: int = game_state.unit_hp[unit_id]
		if hp > 0:
			var hp_ratio := float(hp) / 100.0
			draw_rect(Rect2(draw_x + 2, draw_y, (TILE_WIDTH - 4) * hp_ratio, 2), Color.WHITE)


func _draw_building_placeholder(col: int, row: int, cell_value: int) -> void:
	"""Vẽ placeholder cho building (negative cell values)"""
	var rect := Rect2(
		col * TILE_WIDTH - camera_pixel_x + 1,
		row * TILE_HEIGHT - camera_pixel_y + 1,
		TILE_WIDTH - 2,
		TILE_HEIGHT - 2
	)
	draw_rect(rect, Color(0.6, 0.4, 0.2))


func _draw_cursor_highlight() -> void:
	"""Vẽ highlight quanh cursor tile"""
	var rect := Rect2(
		cursor_tile_x * TILE_WIDTH - camera_pixel_x,
		cursor_tile_y * TILE_HEIGHT - camera_pixel_y,
		TILE_WIDTH,
		TILE_HEIGHT
	)
	var color := Color(1, 1, 0, 0.6) if selected_entity_id <= 0 else Color(0, 1, 0, 0.6)
	draw_rect(rect, color, false, 2.0)

</content>