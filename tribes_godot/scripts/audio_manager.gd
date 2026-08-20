## Audio Manager for BGM and SFX
## Ported from a.java (BGM player) and audio loading in e.java
## Handles background music and sound effects playback

class_name AudioManager
extends Node

# Singleton instance
static var instance: AudioManager

# Audio players
var bgm_players: Array[AudioStreamPlayer] = []
var sfx_players: Array[AudioStreamPlayer] = []

# Loaded audio streams
var bgm_streams: Array[AudioStream] = []
var sfx_streams: Array[AudioStream] = []

# Current BGM index
var current_bgm_index: int = -1

# Volume levels (0.0 to 1.0)
var bgm_volume: float = 0.7
var sfx_volume: float = 1.0

# Audio paths
const BGM_PATH = "res://audio/bgm/"
const SFX_PATH = "res://audio/sfx/"

func _ready() -> void:
	instance = self
	setup_audio_players()
	load_all_audio()

func setup_audio_players() -> void:
	"""Create audio players for BGM and SFX"""
	# Create BGM players (for crossfade support)
	for i in range(2):
		var player = AudioStreamPlayer.new()
		player.name = "BGMPlayer%d" % i
		player.volume_db = linear_to_db(bgm_volume)
		add_child(player)
		bgm_players.append(player)
	
	# Create SFX players (multiple for overlapping sounds)
	for i in range(8):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % i
		player.volume_db = linear_to_db(sfx_volume)
		add_child(player)
		sfx_players.append(player)

func load_all_audio() -> void:
	"""Load all BGM and SFX files"""
	load_bgm()
	load_sfx()

func load_bgm() -> void:
	"""Load background music files"""
	bgm_streams.clear()
	
	var dir = DirAccess.open(BGM_PATH)
	if not dir:
		push_warning("BGM directory not found: ", BGM_PATH)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var bgm_files: Array[String] = []
	
	while file_name != "":
		if file_name.ends_with(".ogg") and not file_name.begins_with("."):
			bgm_files.append(file_name)
		file_name = dir.get_next()
	
	bgm_files.sort()
	
	for bgm_file in bgm_files:
		var path = BGM_PATH + bgm_file
		if ResourceLoader.exists(path):
			var stream = load(path) as AudioStream
			if stream:
				bgm_streams.append(stream)
	
	dir.list_dir_end()
	
	print("Loaded %d BGM tracks" % bgm_streams.size())

func load_sfx() -> void:
	"""Load sound effect files"""
	sfx_streams.clear()
	
	var dir = DirAccess.open(SFX_PATH)
	if not dir:
		push_warning("SFX directory not found: ", SFX_PATH)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var sfx_files: Array[String] = []
	
	while file_name != "":
		if file_name.ends_with(".wav") and not file_name.begins_with("."):
			sfx_files.append(file_name)
		file_name = dir.get_next()
	
	sfx_files.sort()
	
	for sfx_file in sfx_files:
		var path = SFX_PATH + sfx_file
		if ResourceLoader.exists(path):
			var stream = load(path) as AudioStream
			if stream:
				sfx_streams.append(stream)
	
	dir.list_dir_end()
	
	print("Loaded %d SFX sounds" % sfx_streams.size())

func play_bgm(index: int, fade_in: bool = true) -> void:
	"""Play background music track by index (port of a.java's a method)"""
	if index < 0 or index >= bgm_streams.size():
		push_warning("BGM index out of range: ", index)
		return
	
	if index == current_bgm_index and bgm_players[0].playing:
		return  # Already playing this track
	
	# Stop current BGM
	stop_bgm(fade_in)
	
	# Play new BGM
	var player = bgm_players[0]
	player.stream = bgm_streams[index]
	player.volume_db = linear_to_db(bgm_volume) if not fade_in else -40.0
	player.play()
	
	if fade_in:
		fade_in_bgm()
	
	current_bgm_index = index

func stop_bgm(fade_out: bool = true) -> void:
	"""Stop background music (port of void_a in a.java)"""
	var player = bgm_players[0]
	
	if fade_out and player.playing:
		fade_out_bgm()
	else:
		player.stop()
	
	current_bgm_index = -1

func fade_in_bgm() -> void:
	"""Fade in background music"""
	var tween = create_tween()
	tween.tween_property(bgm_players[0], "volume_db", linear_to_db(bgm_volume), 2.0)

func fade_out_bgm() -> void:
	"""Fade out background music"""
	var tween = create_tween()
	tween.tween_property(bgm_players[0], "volume_db", -40.0, 1.0).connect("finished", _on_fade_out_finished)

func _on_fade_out_finished() -> void:
	bgm_players[0].stop()

func play_sfx(index: int, loop: bool = false) -> void:
	"""Play a sound effect by index"""
	if index < 0 or index >= sfx_streams.size():
		push_warning("SFX index out of range: ", index)
		return
	
	# Find available SFX player
	var player = get_available_sfx_player()
	if player:
		player.stream = sfx_streams[index]
		player.volume_db = linear_to_db(sfx_volume)
		player.play()

func stop_sfx() -> void:
	"""Stop all sound effects"""
	for player in sfx_players:
		player.stop()

func get_available_sfx_player() -> AudioStreamPlayer:
	"""Get an available SFX player (not currently playing)"""
	for player in sfx_players:
		if not player.playing:
			return player
	
	# If all busy, return first one anyway
	return sfx_players[0] if sfx_players.size() > 0 else null

func set_bgm_volume(volume: float) -> void:
	"""Set BGM volume (0.0 to 1.0)"""
	bgm_volume = clampf(volume, 0.0, 1.0)
	if bgm_players[0].playing:
		bgm_players[0].volume_db = linear_to_db(bgm_volume)

func set_sfx_volume(volume: float) -> void:
	"""Set SFX volume (0.0 to 1.0)"""
	sfx_volume = clampf(volume, 0.0, 1.0)
	for player in sfx_players:
		player.volume_db = linear_to_db(sfx_volume)

func pause_all() -> void:
	"""Pause all audio (for game pause)"""
	for player in bgm_players:
		if player.playing:
			player.stream_paused = true
	
	for player in sfx_players:
		player.stream_paused = true

func resume_all() -> void:
	"""Resume all audio (from pause)"""
	for player in bgm_players:
		if player.playing:
			player.stream_paused = false
	
	for player in sfx_players:
		player.stream_paused = false

func is_bgm_playing() -> bool:
	"""Check if BGM is currently playing"""
	return bgm_players[0].playing

func get_bgm_count() -> int:
	"""Get number of loaded BGM tracks"""
	return bgm_streams.size()

func get_sfx_count() -> int:
	"""Get number of loaded SFX sounds"""
	return sfx_streams.size()
