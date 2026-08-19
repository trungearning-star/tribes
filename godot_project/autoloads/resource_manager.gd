## ResourceManager.gd - Singleton quản lý tài nguyên game
## Port từ e.java (Resource Manager class)
##
## Java gốc: e.java load tất cả binary resources qua getResourceAsStream()
## Godot: Dùng ResourceLoader để load sprites PNG đã extract sẵn,
##        FileAccess để đọc binary tilemap/audio/localization
##
## Sprites: Đã convert sang PNG rời trong res://data/sprites/{pack}/
## Tilemap (a): 312 segments + 5 index tables, RLE-like encoding
## Audio: sa=MIDI (26616 bytes), ma=SFX (42381 bytes)
## Localization: Pipe-delimited UTF-8 text trong folders 0-4
extends Node

# === CACHED RESOURCES ===

## Sprite textures đã load từ các file PNG rời
## Key: "pack/index" (ví dụ "pi0/5"), Value: Texture2D
var _sprite_cache: Dictionary = {}

## Mapping từ global sprite ID → {pack: String, index: int}
## Được xây dựng từ f.java/j.java lookup tables khi cần
## Tạm thời dùng direct access qua get_sprite_by_pack()
var _sprite_id_map: Dictionary = {}

## Tilemap data đã parse từ file /a
## Format: PackedByteArray chứa tile indices
var _tilemap_data: PackedByteArray = PackedByteArray()

## Localization strings
## Key: "category/index" (ví dụ "s/5" = UI label #5), Value: String
var _localize_cache: Dictionary = {}



# === CONSTANTS ===

## Paths đến resources trong project
const SPRITE_BASE_PATH := "res://data/sprites"
const TILEMAP_PATH := "res://data/maps/a.txt"

const LOCALIZE_BASE_PATH := "res://data/localize"

## Tên các sprite packs (thư mục con trong data/sprites/)
const SPRITE_PACKS := ["pi0", "pi8", "pi9"]

# === INITIALIZATION ===

func _ready() -> void:
	## Khởi tạo resource manager, preload các resources cần thiết
	print("[ResourceManager] Initializing...")
	# Resources sẽ được load on-demand hoặc preload tùy nhu cầu


# === SPRITE LOADING ===
## Sprites đã được extract sẵn thành các file PNG rời
## Naming convention: {pack}_{NNN}.png (ví dụ: pi0_005.png)
## Port từ e.java getImage() nhưng không cần parse binary nữa

func get_sprite(pack: String, index: int) -> Texture2D:
	## Lấy texture theo pack name và index.
	## Ví dụ: get_sprite("pi0", 5) → load res://data/sprites/pi0/pi0_005.png
	##
	## Tương ứng e.java: sprite index trong j[][] lookup table
	## trỏ đến vị trí trong sprite pack.
	##
	## Returns: Texture2D hoặc null nếu không tìm thấy
	var cache_key := "%s/%d" % [pack, index]

	# Check cache trước
	if _sprite_cache.has(cache_key):
		return _sprite_cache[cache_key]

	# Build file path: res://data/sprites/pi0/pi0_005.png
	var file_path := "%s/%s/%s_%03d.png" % [SPRITE_BASE_PATH, pack, pack, index]

	if not ResourceLoader.exists(file_path):
		push_warning("[ResourceManager] Sprite not found: %s" % file_path)
		return null

	var texture: Texture2D = load(file_path)
	if texture:
		_sprite_cache[cache_key] = texture

	return texture


func preload_sprite_pack(pack: String) -> int:
	## Preload toàn bộ sprites trong một pack vào cache.
	## Hữu ích khi vào game để tránh stutter khi load on-demand.
	##
	## Returns: Số lượng sprites đã load thành công
	var count := 0
	var dir_path := "%s/%s" % [SPRITE_BASE_PATH, pack]

	# Thử load từ index 0 đến khi nào không còn file
	for i in range(256):  # Tối đa 256 sprites per pack
		var file_path := "%s/%s_%03d.png" % [dir_path, pack, i]
		if ResourceLoader.exists(file_path):
			var texture: Texture2D = load(file_path)
			if texture:
				var cache_key := "%s/%d" % [pack, i]
				_sprite_cache[cache_key] = texture
				count += 1
		else:
			break  # Hết file trong pack

	print("[ResourceManager] Preloaded %d sprites from pack '%s'" % [count, pack])
	return count


# === TILEMAP LOADING ===
## Port từ e.java tilemap parsing (L183-225)
##
## Binary format của file /a:
##   1. 312 segments: mỗi segment = 2 bytes little-endian (size), rồi size bytes data
##      Segment offsets tích lũy: offset[i+1] = offset[i] + size[i]
##      Total raw data buffer: 17638 bytes (this.a.a[])
##   2. 5 index tables: mỗi table = 2 bytes LE (count), rồi count x 2-byte entries (big-endian short)
##      Table offsets tích lũy: c[i+1] = c[i] + count[i]
##      Total index entries: 570 shorts (this.a.b[])
##
## Sau khi parse:
##   - _tilemap_segments[seg_id] = PackedByteArray (raw segment data)
##   - _tilemap_indices[table_id][entry_id] = int (index value)

## Parsed tilemap segments (312 segments)
var _tilemap_segments: Array = []  # Array of PackedByteArray

## Parsed tilemap index tables (5 tables)
var _tilemap_indices: Array = []  # Array of PackedInt32Array

## Cumulative offsets cho segments (312 values)
var _segment_offsets: PackedInt32Array = PackedInt32Array()

## Cumulative offsets cho index tables (5 values)
var _index_table_offsets: PackedInt32Array = PackedInt32Array()

func load_tilemap() -> bool:
	## Parse tilemap binary từ file /a.
	## Port chính xác từ e.java L190-225.
	if not FileAccess.file_exists(TILEMAP_PATH):
		push_warning("[ResourceManager] Tilemap file not found: %s" % TILEMAP_PATH)
		return false
	
	var file := FileAccess.open(TILEMAP_PATH, FileAccess.READ)
	if file == null:
		push_error("[ResourceManager] Failed to open tilemap")
		return false
	
	var data := file.get_buffer(file.get_length())
	file.close()
	
	var pos := 0
	
	# === Phase 1: Read 312 segments ===
	# Java: this.a.a = new byte[17638]; this.a.a = new short[312];
	_segment_offsets.resize(312)
	_tilemap_segments.resize(312)
	_segment_offsets[0] = 0
	
	for seg in range(312):
		if pos + 2 > data.size():
			push_error("[ResourceManager] Tilemap truncated at segment %d" % seg)
			return false
		
		# Read 2-byte little-endian size
		var lo: int = data[pos] & 0xFF
		var hi: int = (data[pos + 1] & 0xFF) << 8
		var seg_size: int = hi + lo
		pos += 2
		
		# Store cumulative offset
		if seg < 311:
			_segment_offsets[seg + 1] = _segment_offsets[seg] + seg_size
		
		# Read segment data
		if seg_size > 0:
			if pos + seg_size > data.size():
				push_error("[ResourceManager] Tilemap segment %d data truncated" % seg)
				return false
			_tilemap_segments[seg] = data.slice(pos, pos + seg_size)
			pos += seg_size
		else:
			_tilemap_segments[seg] = PackedByteArray()
	
	# === Phase 2: Read 5 index tables ===
	# Java: this.a.b = new short[570]; this.a.c = new short[5];
	_index_table_offsets.resize(5)
	_tilemap_indices.resize(5)
	_index_table_offsets[0] = 0
	
	for tbl in range(5):
		if pos + 2 > data.size():
			push_error("[ResourceManager] Tilemap index table %d truncated" % tbl)
			return false
		
		# Read 2-byte little-endian count
		var lo: int = data[pos] & 0xFF
		var hi: int = (data[pos + 1] & 0xFF) << 8
		var count: int = hi + lo
		pos += 2
		
		# Store cumulative offset
		if tbl < 4:
			_index_table_offsets[tbl + 1] = _index_table_offsets[tbl] + count
		
		# Read index entries (each is 2-byte big-endian short)
		var indices := PackedInt32Array()
		indices.resize(count)
		for i in range(count):
			if pos + 2 > data.size():
				push_error("[ResourceManager] Tilemap index entry truncated")
				return false
			var elo: int = data[pos] & 0xFF
			var ehi: int = (data[pos + 1] & 0xFF) << 8
			indices[i] = ehi + elo
			pos += 2
		
		_tilemap_indices[tbl] = indices
	
	print("[ResourceManager] Tilemap parsed: 312 segments (%d bytes), 5 index tables" % data.size())
	for tbl in range(5):
		print("  Index table %d: %d entries" % [tbl, _tilemap_indices[tbl].size()])
	
	return true


func get_tilemap_segment(seg_id: int) -> PackedByteArray:
	## Lấy raw data của một tilemap segment
	if seg_id < 0 or seg_id >= _tilemap_segments.size():
		return PackedByteArray()
	return _tilemap_segments[seg_id]


func get_tilemap_index(table_id: int, entry_id: int) -> int:
	## Lấy giá trị index từ bảng chỉ mục
	## table_id: 0-4, entry_id: index trong bảng
	if table_id < 0 or table_id >= _tilemap_indices.size():
		return 0
	var indices: PackedInt32Array = _tilemap_indices[table_id]
	if entry_id < 0 or entry_id >= indices.size():
		return 0
	return indices[entry_id]


func get_tilemap_index_table(table_id: int) -> PackedInt32Array:
	## Lấy toàn bộ index table
	if table_id < 0 or table_id >= _tilemap_indices.size():
		return PackedInt32Array()
	return _tilemap_indices[table_id]


# === LOCALIZATION ===
## Port từ c.java text loading
## Files: d0=story text, s=UI labels, t=help text
## Format: pipe-delimited UTF-8

func load_localization(locale: int = 0) -> bool:
	## Load localization strings cho ngôn ngữ chỉ định.
	##
	## locale: 0=Vietnamese, 1-4=other languages
	##
	## Tương ứng c.java constructor loading từ /0/s, /0/t, /0/d0
	var locale_dir := "%s/%d" % [LOCALIZE_BASE_PATH, locale]
	var categories := ["s", "t", "d0"]

	for category in categories:
		var path := "%s/%s" % [locale_dir, category]
		if not FileAccess.file_exists(path):
			push_warning("[ResourceManager] Localize file not found: %s" % path)
			continue

		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue

		var content := file.get_as_text()
		file.close()
		
		# Strip BOM nếu có (một số editor thêm BOM vào đầu file UTF-8)
		if content.begins_with("\ufeff"):
			content = content.substr(1)
		
		# Split by pipe delimiter
		var entries := content.split("|")
		for i in range(entries.size()):
			var key := "%s/%d" % [category, i]
			_localize_cache[key] = entries[i].strip_edges()

	print("[ResourceManager] Loaded %d localized strings for locale %d" % [
		_localize_cache.size(), locale])
	return true


func get_text(category: String, index: int) -> String:
	## Lấy localized string theo category và index.
	##
	## Tương ứng c.java getText(category, index)
	var key := "%s/%d" % [category, index]
	if _localize_cache.has(key):
		return _localize_cache[key]

	push_warning("[ResourceManager] Missing text: %s" % key)
	return "[%s]" % key  # Placeholder hiển thị key bị thiếu


# === AUDIO ===
## Audio đã được convert sang OGG/WAV và quản lý bởi AudioManager autoload.
## ResourceManager không còn load raw audio binary nữa.
