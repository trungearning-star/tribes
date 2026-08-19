## AudioManager.gd - Singleton quản lý âm thanh
## Port từ a.java (Audio Player class)
##
## Java gốc: a.java dùng javax.microedition.media.Manager để play MIDI/SFX
## Godot: Dùng AudioStreamPlayer cho BGM (OGG) và SFX (WAV)
##
## Asset pipeline:
## - BGM: /sa (MIDI 5 tracks) → bgm_0.ogg .. bgm_4.ogg
## - SFX: /ma (raw PCM 10 segments) → sfx_0.wav .. sfx_9.wav
extends Node

# === CONSTANTS ===

const BGM_BASE_PATH := "res://data/audio/bgm/bgm_"
const SFX_BASE_PATH := "res://data/audio/sfx/sfx_"
const MAX_BGM_TRACKS := 5
const MAX_SFX_COUNT := 10

# === NODES ===

## Player cho background music (OGG)
var _bgm_player: AudioStreamPlayer

## Pool players cho sound effects (round-robin)
var _sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_CHANNELS := 4

## Index luân phiên cho SFX round-robin
var _sfx_channel_index: int = 0

# === STATE ===

## BGM track hiện tại (-1 = none)
var _current_bgm_track: int = -1

## Volume settings (0.0 - 1.0)
var bgm_volume: float = 1.0
var sfx_volume: float = 1.0

## Master mute (synced với GameManager.sound_enabled)
var muted: bool = false

# === CACHED STREAMS ===

## Cache BGM streams để tránh load lại từ disk
## Key: track_id (int), Value: AudioStreamOggVorbis
var _bgm_cache: Dictionary = {}

## Cache SFX streams
## Key: sfx_id (int), Value: AudioStreamWAV
var _sfx_cache: Dictionary = {}

# === LIFECYCLE ===

func _ready() -> void:
	"""Khởi tạo audio players và preload assets"""
	# Tạo BGM player
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	add_child(_bgm_player)

	# Tạo SFX player pool
	for i in MAX_SFX_CHANNELS:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_sfx_players.append(player)

	# Sync mute state với GameManager
	muted = not GameManager.sound_enabled

	print("[AudioManager] Initialized with %d SFX channels" % MAX_SFX_CHANNELS)


func _process(_delta: float) -> void:
	"""Sync mute state mỗi frame (phòng khi user toggle trong settings)"""
	var should_mute := not GameManager.sound_enabled
	if muted != should_mute:
		muted = should_mute
		_apply_volume()


# === BGM CONTROL ===

func play_bgm(track_id: int) -> void:
	"""
	Phát background music track.
	track_id: 0-4 tương ứng bgm_0.ogg .. bgm_4.ogg
	"""
	if track_id < 0 or track_id >= MAX_BGM_TRACKS:
		push_warning("[AudioManager] Invalid BGM track: %d" % track_id)
		return

	if _current_bgm_track == track_id and _bgm_player.playing:
		return  # Already playing this track

	_current_bgm_track = track_id

	var stream := _get_bgm_stream(track_id)
	if stream == null or muted:
		return

	_bgm_player.stream = stream
	_bgm_player.play()
	_apply_volume()


func stop_bgm() -> void:
	"""Dừng BGM"""
	_bgm_player.stop()
	_current_bgm_track = -1


func _get_bgm_stream(track_id: int) -> AudioStreamOggVorbis:
	"""Load hoặc lấy từ cache BGM stream"""
	if _bgm_cache.has(track_id):
		return _bgm_cache[track_id]

	var path := "%s%d.ogg" % [BGM_BASE_PATH, track_id]
	if not ResourceLoader.exists(path):
		push_warning("[AudioManager] BGM file not found: %s" % path)
		return null

	var stream: AudioStreamOggVorbis = load(path)
	if stream:
		_bgm_cache[track_id] = stream
	return stream


# === SFX CONTROL ===

func play_sfx(sfx_id: int) -> void:
	"""
	Phát sound effect.
	sfx_id: 0-9 tương ứng sfx_0.wav .. sfx_9.wav
	"""
	if muted:
		return

	if sfx_id < 0 or sfx_id >= MAX_SFX_COUNT:
		push_warning("[AudioManager] Invalid SFX id: %d" % sfx_id)
		return

	var stream := _get_sfx_stream(sfx_id)
	if stream == null:
		return

	# Lấy channel tiếp theo (round-robin)
	var player := _sfx_players[_sfx_channel_index]
	_sfx_channel_index = (_sfx_channel_index + 1) % MAX_SFX_CHANNELS

	player.stream = stream
	player.play()


func _get_sfx_stream(sfx_id: int) -> AudioStreamWAV:
	"""Load hoặc lấy từ cache SFX stream"""
	if _sfx_cache.has(sfx_id):
		return _sfx_cache[sfx_id]

	var path := "%s%d.wav" % [SFX_BASE_PATH, sfx_id]
	if not ResourceLoader.exists(path):
		push_warning("[AudioManager] SFX file not found: %s" % path)
		return null

	var stream: AudioStreamWAV = load(path)
	if stream:
		_sfx_cache[sfx_id] = stream
	return stream


# === VOLUME CONTROL ===

func set_bgm_volume(vol: float) -> void:
	"""Set BGM volume (0.0 - 1.0)"""
	bgm_volume = clampf(vol, 0.0, 1.0)
	_apply_volume()


func set_sfx_volume(vol: float) -> void:
	"""Set SFX volume (0.0 - 1.0)"""
	sfx_volume = clampf(vol, 0.0, 1.0)
	_apply_volume()


func _apply_volume() -> void:
	"""Áp dụng volume settings vào tất cả players"""
	var bgm_db := linear_to_db(bgm_volume) if not muted else -80.0
	var sfx_db := linear_to_db(sfx_volume) if not muted else -80.0

	_bgm_player.volume_db = bgm_db
	for player in _sfx_players:
		player.volume_db = sfx_db

</content>