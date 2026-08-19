## splash_screen.gd - Màn hình splash/logo khi khởi động game
## Port từ d.java (Splash Canvas)
##
## Java gốc: d.java hiển thị logo trong 3 giây rồi chuyển sang f.java (main menu)
## Godot: Dùng Timer node + GameManager.change_state()
extends Control

## Thời gian hiển thị splash (giây)
@export var splash_duration: float = 3.0

## Path đến logo image (sẽ thay bằng texture thực từ /l0 PNG)
@export var logo_path: String = ""

@onready var logo_texture: TextureRect = $LogoTexture
@onready var timer: Timer = $Timer


func _ready() -> void:
	"""
	Tương ứng d.java constructor + paint():
	- Load splash image từ /l0 (PNG)
	- Hiển thị trong N giây
	- Tự động chuyển sang main menu
	
	Lưu ý: Trong Java, splash chạy trên thread riêng.
	Trong Godot, dùng Timer signal để tránh blocking.
	"""
	# Set timer duration
	timer.wait_time = splash_duration
	
	# Load logo texture nếu có
	if logo_path != "" and ResourceLoader.exists(logo_path):
		logo_texture.texture = load(logo_path)
	else:
		# Placeholder: vẽ text thay vì image
		print("[SplashScreen] No logo texture set, using placeholder")
	
	# Bắt đầu timer
	timer.timeout.connect(_on_splash_timeout)
	timer.start()
	
	print("[SplashScreen] Showing splash for %.1fs" % splash_duration)


func _input(event: InputEvent) -> void:
	"""
	Cho phép skip splash bằng cách nhấn phím bất kỳ.
	Tương ứng d.java keyPressed() → skip to main menu
	"""
	if event is InputEventKey and event.pressed:
		_skip_splash()
	elif event is InputEventScreenTouch and event.pressed:
		_skip_splash()


func _on_splash_timeout() -> void:
	"""Hết thời gian splash → chuyển sang main menu"""
	_go_to_main_menu()


func _skip_splash() -> void:
	"""Skip splash ngay lập tức"""
	timer.stop()
	_go_to_main_menu()


func _go_to_main_menu() -> void:
	"""
	Chuyển scene sang main menu.
	Tương ứng d.java → tribes.java notifyDestroyed() → new f()
	"""
	print("[SplashScreen] → Main Menu")
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

</content>