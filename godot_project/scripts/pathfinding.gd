## pathfinding.gd - BFS Pathfinding utility
## Port từ b.java pathfinding logic (L462-700)
##
## Java gốc: Bresenham-like line drawing + collision check
##   a(var1,var2,var3,var4,var5): tính đường đi từ (x1,y1) đến (x2,y2)
##   Lưu path vào this.d[3][0/1][] (x/y coords), tối đa this.i steps
##   Collision check: b[y][x] == 0 = passable
##
## Godot: BFS trên grid với 8 hướng di chuyển.
## Class này là static utility, KHÔNG phải Node.
class_name Pathfinding

# === CONSTANTS ===

## 8 hướng di chuyển (N, NE, E, SE, S, SW, W, NW)
const DIR_X := [0, 1, 1, 1, 0, -1, -1, -1]
const DIR_Y := [-1, -1, 0, 1, 1, 1, 0, -1]

## Chi phí di chuyển: orthogonal = 10, diagonal = 14 (≈√2 * 10)
const COST_ORTHOGONAL := 10
const COST_DIAGONAL := 14


# === PATHFINDING RESULT ===

class PathResult:
	var found: bool = false
	var path: Array = []  # Array of Vector2i
	var total_cost: int = 0
	
	func _init(p_found: bool = false, p_path: Array = [], p_cost: int = 0) -> void:
		found = p_found
		path = p_path
		total_cost = p_cost


# === MAIN PATHFINDING FUNCTION ===

static func find_path(
	game_state: GameState,
	start_x: int, start_y: int,
	end_x: int, end_y: int,
	owner_id: int = 0,
	max_steps: int = 200
) -> PathResult:
	"""
	Tìm đường đi ngắn nhất từ start đến end bằng BFS.
	Port từ b.java a(var1,var2,var3,var4,var5).
	
	Parameters:
		game_state: GameState chứa map_collision
		start_x, start_y: Vị trí bắt đầu (tile coords)
		end_x, end_y: Vị trí đích (tile coords)
		owner_id: Tribe ID của unit đang di chuyển (để check ownership)
		max_steps: Giới hạn số bước tìm kiếm (tránh infinite loop)
	
	Returns: PathResult với path tìm được hoặc empty nếu không có đường
	"""
	# Bounds check
	if not _in_bounds(start_x, start_y) or not _in_bounds(end_x, end_y):
		return PathResult.new(false)
	
	# Same position
	if start_x == end_x and start_y == end_y:
		return PathResult.new(true, [Vector2i(start_x, start_y)], 0)
	
	# BFS data structures
	# visited[y][x] = true if already explored
	var visited: Array = []
	for y in range(GameState.MAX_MAP_HEIGHT):
		var row := PackedByteArray()
		row.resize(GameState.MAX_MAP_WIDTH)
		visited.append(row)
	
	# parent[y][x] = Vector2i of previous tile in path
	var parent: Array = []
	for y in range(GameState.MAX_MAP_HEIGHT):
		var row := []
		row.resize(GameState.MAX_MAP_WIDTH)
		for x in range(GameState.MAX_MAP_WIDTH):
			row[x] = Vector2i(-1, -1)
		parent.append(row)
	
	# cost[y][x] = movement cost to reach this tile
	var cost: Array = []
	for y in range(GameState.MAX_MAP_HEIGHT):
		var row := PackedInt32Array()
		row.resize(GameState.MAX_MAP_WIDTH)
		for x in range(GameState.MAX_MAP_WIDTH):
			row[x] = 999999
		cost.append(row)
	
	# BFS queue: Array of Vector2i
	var queue: Array = [Vector2i(start_x, start_y)]
	visited[start_y][start_x] = 1
	cost[start_y][start_x] = 0
	
	var steps := 0
	var found := false
	
	while queue.size() > 0 and steps < max_steps:
		steps += 1
		
		# Dequeue front (BFS = FIFO)
		var current: Vector2i = queue.pop_front()
		var cx := current.x
		var cy := current.y
		
		# Check if reached destination
		if cx == end_x and cy == end_y:
			found = true
			break
		
		# Explore 8 neighbors
		for dir in range(8):
			var nx := cx + DIR_X[dir]
			var ny := cy + DIR_Y[dir]
			
			# Bounds check
			if not _in_bounds(nx, ny):
				continue
			
			# Already visited
			if visited[ny][nx] != 0:
				continue
			
			# Passability check (port từ b.java a(x,y,owner))
			if not _is_passable(game_state, nx, ny, owner_id):
				continue
			
			# Calculate movement cost
			var move_cost := COST_DIAGONAL if (dir % 2 == 1) else COST_ORTHOGONAL
			var new_cost: int = cost[cy][cx] + move_cost
			
			# Only proceed if cheaper path
			if new_cost < cost[ny][nx]:
				cost[ny][nx] = new_cost
				parent[ny][nx] = Vector2i(cx, cy)
				visited[ny][nx] = 1
				queue.append(Vector2i(nx, ny))
	
	if not found:
		return PathResult.new(false)
	
	# Reconstruct path from end to start
	var path: Array = []
	var px := end_x
	var py := end_y
	
	while px != start_x or py != start_y:
		path.append(Vector2i(px, py))
		var prev: Vector2i = parent[py][px]
		if prev.x == -1 and prev.y == -1:
			# Should not happen if found=true
			break
		px = prev.x
		py = prev.y
	
	# Add start position
	path.append(Vector2i(start_x, start_y))
	
	# Reverse to get start→end order
	path.reverse()
	
	return PathResult.new(true, path, cost[end_y][end_x])


# === LINE OF SIGHT / DIRECT PATH ===

static func has_line_of_sight(
	game_state: GameState,
	x1: int, y1: int,
	x2: int, y2: int,
	owner_id: int = 0
) -> bool:
	"""
	Kiểm tra xem có đường thẳng không bị chặn giữa 2 điểm.
	Port từ b.java Bresenham line drawing trong a(var1,var2,var3,var4,var5).
	Dùng Bresenham's line algorithm để duyệt tiles trên đường thẳng.
	"""
	var dx := absi(x2 - x1)
	var dy := absi(y2 - y1)
	var sx := 1 if x1 < x2 else -1
	var sy := 1 if y1 < y2 else -1
	var err := dx - dy
	
	var cx := x1
	var cy := y1
	
	while true:
		if cx == x2 and cy == y2:
			return true
		
		if not _is_passable(game_state, cx, cy, owner_id):
			return false
		
		var e2 := 2 * err
		if e2 > -dy:
			err -= dy
			cx += sx
		if e2 < dx:
			err += dx
			cy += sy
		
		if not _in_bounds(cx, cy):
			return false


# === HELPER FUNCTIONS ===

static func _in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < GameState.MAX_MAP_WIDTH and y >= 0 and y < GameState.MAX_MAP_HEIGHT


static func _is_passable(game_state: GameState, x: int, y: int, owner_id: int) -> bool:
	"""
	Kiểm tra xem tile có thể đi qua được không.
	Port từ b.java a(int var1, int var2, int var3) collision check.
	
	Logic gốc:
	- b[y][x] == 0 → passable (empty)
	- b[y][x] == owner_id → passable (own territory/unit)
	- b[y][x] > 0 && b[y][x] <= 122 → blocked by unit
	- b[y][x] == -128 → special passable (gate/bridge)
	- b[y][x] < -111 → blocked by building
	"""
	if not _in_bounds(x, y):
		return false
	
	var cell: int = game_state.map_collision[y][x]
	
	# Empty tile
	if cell == 0:
		return true
	
	# Own unit
	if cell == owner_id:
		return true
	
	# Special passable (gate/bridge marker)
	if cell == -128:
		return true
	
	# Blocked by other unit (positive values 1-122 are unit IDs)
	if cell > 0 and cell <= 122:
		return false
	
	# Blocked by building (negative values < -111)
	if cell < -111:
		return false
	
	# Default: passable
	return true


static func get_distance_squared(x1: int, y1: int, x2: int, y2: int) -> int:
	"""
	Tính bình phương khoảng cách Euclidean.
	Port từ b.java distance calculation trong f() method.
	Dùng squared distance để tránh sqrt khi so sánh.
	"""
	var dx := x1 - x2
	var dy := y1 - y2
	return dx * dx + dy * dy

</content>