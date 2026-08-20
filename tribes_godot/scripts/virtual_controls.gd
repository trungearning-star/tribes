## Virtual Touch Controls for Android
## Provides virtual D-Pad and action buttons for touch input
## Maps to Java game key controls

class_name VirtualControls
extends CanvasLayer

# Control visibility
@export var show_controls: bool = true

# Opacity for touch buttons (0-1)
@export var button_opacity: float = 0.5

# Signals for control inputs (matching Java game actions)
signal left_pressed
signal left_released
signal right_pressed
signal right_released
signal up_pressed
signal up_released
signal down_pressed
signal down_released
signal select_pressed
signal select_released
signal menu_pressed
signal menu_released
signal help_pressed
signal num7_pressed
signal num9_pressed

# Button nodes
var dpad_left: TextureButton
var dpad_right: TextureButton
var dpad_up: TextureButton
var dpad_down: TextureButton
var btn_select: TextureButton
var btn_menu: TextureButton
var btn_help: TextureButton
var btn_num7: TextureButton
var btn_num9: TextureButton

# Touch tracking
var active_touches: Dictionary = {}  # touch_id -> button_name
const TOUCH_DEADZONE: float = 10.0

func _ready() -> void:
	if not show_controls:
		hide()
		return
	
	create_virtual_controls()
	setup_input_mapping()

func create_virtual_controls() -> void:
	"""Create virtual control buttons programmatically"""
	
	# Create container for D-Pad (left side)
	var dpad_container = Control.new()
	dpad_container.name = "DPadContainer"
	dpad_container.anchor_left = 0.0
	dpad_container.anchor_top = 1.0
	dpad_container.anchor_right = 0.35
	dpad_container.anchor_bottom = 1.0
	dpad_container.offset_left = 20
	dpad_container.offset_top = -180
	dpad_container.offset_right = 140
	dpad_container.offset_bottom = -20
	add_child(dpad_container)
	
	# Create D-Pad buttons
	dpad_up = create_dpad_button("up", Vector2(60, 20), dpad_container)
	dpad_down = create_dpad_button("down", Vector2(60, 100), dpad_container)
	dpad_left = create_dpad_button("left", Vector2(20, 60), dpad_container)
	dpad_right = create_dpad_button("right", Vector2(100, 60), dpad_container)
	
	# Create container for action buttons (right side)
	var action_container = Control.new()
	action_container.name = "ActionContainer"
	action_container.anchor_left = 0.65
	action_container.anchor_top = 1.0
	action_container.anchor_right = 1.0
	action_container.anchor_bottom = 1.0
	action_container.offset_left = -140
	action_container.offset_top = -180
	action_container.offset_right = -20
	action_container.offset_bottom = -20
	add_child(action_container)
	
	# Create action buttons
	btn_select = create_action_button("select", "SELECT", Vector2(20, 100), action_container)
	btn_menu = create_action_button("menu", "MENU", Vector2(100, 100), action_container)
	btn_help = create_action_button("help", "0", Vector2(60, 140), action_container)
	btn_num7 = create_action_button("num7", "7", Vector2(20, 40), action_container)
	btn_num9 = create_action_button("num9", "9", Vector2(100, 40), action_container)

func create_dpad_button(direction: String, position: Vector2, parent: Control) -> TextureButton:
	"""Create a D-Pad direction button"""
	var btn = TextureButton.new()
	btn.name = "DPad" + direction.capitalize()
	btn.position = position
	btn.custom_minimum_size = Vector2(40, 40)
	
	# Create placeholder texture
	var img = Image.create(40, 40, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.3, 0.3, 0.3, button_opacity))
	
	# Draw direction indicator
	var center = Vector2(20, 20)
	var arrow_color = Color(0.8, 0.8, 0.8, button_opacity)
	match direction:
		"up":
			draw_triangle(img, center - Vector2(0, 15), center - Vector2(10, 5), center + Vector2(10, 5), arrow_color)
		"down":
			draw_triangle(img, center + Vector2(0, 15), center - Vector2(10, -5), center + Vector2(10, -5), arrow_color)
		"left":
			draw_triangle(img, center - Vector2(15, 0), center - Vector2(-5, -10), center - Vector2(-5, 10), arrow_color)
		"right":
			draw_triangle(img, center + Vector2(15, 0), center + Vector2(-5, -10), center + Vector2(-5, 10), arrow_color)
	
	var tex = ImageTexture.create_from_image(img)
	btn.texture_normal = tex
	
	# Connect touch events
	btn.gui_input.connect(_on_button_gui_input.bind(direction))
	
	parent.add_child(btn)
	return btn

func create_action_button(name: String, label: String, position: Vector2, parent: Control) -> TextureButton:
	"""Create an action button"""
	var btn = TextureButton.new()
	btn.name = "Btn" + name.capitalize()
	btn.position = position
	btn.custom_minimum_size = Vector2(50, 50)
	
	# Create placeholder texture with label
	var img = Image.create(50, 50, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.4, 0.6, button_opacity))
	
	# Draw border
	for i in range(5):
		img.draw_rect(Rect2(i, i, 50-i*2, 50-i*2), Color(0.4, 0.6, 0.8, button_opacity), false)
	
	var tex = ImageTexture.create_from_image(img)
	btn.texture_normal = tex
	
	# Add label (would need Label node for proper text, simplified here)
	var label_node = Label.new()
	label_node.text = label
	label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_node.size = Vector2(50, 50)
	label_node.add_theme_font_size_override("font_size", 16)
	label_node.add_theme_color_override("font_color", Color(1, 1, 1, button_opacity))
	btn.add_child(label_node)
	
	# Connect touch events
	btn.gui_input.connect(_on_button_gui_input.bind(name))
	
	parent.add_child(btn)
	return btn

func draw_triangle(img: Image, p1: Vector2, p2: Vector2, p3: Vector2, color: Color) -> void:
	"""Draw a filled triangle on an image"""
	# Simple scanline fill
	var min_y = mini(p1.y, p2.y, p3.y) as int
	var max_y = maxi(p1.y, p2.y, p3.y) as int
	
	for y in range(min_y, min(max_y + 1, img.get_height())):
		var intersections = []
		if abs(p2.y - p1.y) > 0.01:
			var x = p1.x + (y - p1.y) * (p2.x - p1.x) / (p2.y - p1.y)
			intersections.append(x)
		if abs(p3.y - p2.y) > 0.01:
			var x = p2.x + (y - p2.y) * (p3.x - p2.x) / (p3.y - p2.y)
			intersections.append(x)
		if abs(p1.y - p3.y) > 0.01:
			var x = p3.x + (y - p3.y) * (p1.x - p3.x) / (p1.y - p3.y)
			intersections.append(x)
		
		if intersections.size() >= 2:
			intersections.sort()
			var x1 = clampi(intersections[0] as int, 0, img.get_width() - 1)
			var x2 = clampi(intersections[-1] as int, 0, img.get_width() - 1)
			for x in range(x1, x2 + 1):
				img.set_pixel(x, y, color)

func setup_input_mapping() -> void:
	"""Map virtual controls to game actions"""
	pass  # Signals handle the mapping

func _on_button_gui_input(event: InputEvent, button_name: String) -> void:
	"""Handle button touch events"""
	if event is InputEventScreenTouch:
		var touch_event = event as InputEventScreenTouch
		var touch_id = touch_event.index
		
		if touch_event.pressed:
			active_touches[touch_id] = button_name
			_emit_button_pressed(button_name)
		else:
			if active_touches.has(touch_id) and active_touches[touch_id] == button_name:
				active_touches.erase(touch_id)
				_emit_button_released(button_name)
	
	elif event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed:
			_emit_button_pressed(button_name)
		else:
			_emit_button_released(button_name)

func _emit_button_pressed(button_name: String) -> void:
	"""Emit appropriate signal for button press"""
	match button_name:
		"left":
			left_pressed.emit()
		"right":
			right_pressed.emit()
		"up":
			up_pressed.emit()
		"down":
			down_pressed.emit()
		"select":
			select_pressed.emit()
		"menu":
			menu_pressed.emit()
		"help":
			help_pressed.emit()
		"num7":
			num7_pressed.emit()
		"num9":
			num9_pressed.emit()

func _emit_button_released(button_name: String) -> void:
	"""Emit appropriate signal for button release"""
	match button_name:
		"left":
			left_released.emit()
		"right":
			right_released.emit()
		"up":
			up_released.emit()
		"down":
			down_released.emit()
		"select":
			select_released.emit()
		"menu":
			menu_released.emit()
		"help":
			help_released.emit()
		"num7":
			num7_released.emit()
		"num9":
			num9_released.emit()

func _input(event: InputEvent) -> void:
	"""Handle keyboard input as fallback"""
	if event is InputEventKey:
		var key_event = event as InputEventKey
		if key_event.pressed:
			match key_event.keycode:
				KEY_LEFT, KEY_A:
					left_pressed.emit()
				KEY_RIGHT, KEY_D:
					right_pressed.emit()
				KEY_UP, KEY_W:
					up_pressed.emit()
				KEY_DOWN, KEY_S:
					down_pressed.emit()
				KEY_ENTER, KEY_SPACE:
					select_pressed.emit()
				KEY_ESCAPE, KEY_BACKSPACE:
					menu_pressed.emit()
				KEY_0:
					help_pressed.emit()
				KEY_7:
					num7_pressed.emit()
				KEY_9:
					num9_pressed.emit()
