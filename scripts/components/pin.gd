class_name Pin
extends Node2D

# Identity parameters (type, state)
enum PinType { INPUT, OUTPUT }
var pin_type: PinType = PinType.INPUT
var signal_state: bool = false
var pin_name: String = ""

# Connection parameters (parents, wires)
var parent_gate: Gate
var connected_wires: Array = []

# Visual parameters (color, size, refs)
var color_rect: Sprite2D
var color: Color = Color.GRAY
var size: Vector2 = Vector2(12, 12)

# Tooltip parameters
var tooltip_label: Label
var tooltip_edit: LineEdit
var is_hovering: bool = false
var is_editing: bool = false
var original_name: String = ""

# Collision parameters (area, shapes, signal)
var area_2d: Area2D
var collision_shape_2d: CollisionShape2D
var rectangle_shape_2d: RectangleShape2D
signal pin_clicked(pin_instance)

# Functions on mount and every frame
func _ready() -> void:
	set_visuals()
	set_collisions()
	create_tooltip()

func _process(_delta):
	# Handle escape key to cancel editing
	if is_editing and Input.is_action_just_pressed("ui_cancel"):
		exit_edit_mode(false)
		return
	
	# Check if mouse is over the pin (only when not editing)
	if not is_editing:
		var mouse_pos = get_global_mouse_position()
		var pin_rect = Rect2(global_position - size / 2, size)
		
		if pin_rect.has_point(mouse_pos):
			if not is_hovering and pin_name != "":
				show_tooltip()
				is_hovering = true
		else:
			if is_hovering:
				hide_tooltip()
				is_hovering = false

# Set visuals
func set_visuals():
	var pin_texture = load("res://assets/art/pin_12x12.png")
	
	var sprite = Sprite2D.new()
	sprite.texture = pin_texture
	sprite.centered = true
	add_child(sprite)
	
	# Store reference for updating colors
	color_rect = sprite
	update_visuals()

# Update visuals
func update_visuals(): # Colors reflect signal state
	if signal_state == true:
		color_rect.modulate = Color(1.0, 0.72, 0.3)  # Signal ON - bright copper #FFB84D
	else:
		color_rect.modulate = Color(0.24, 0.12, 0.1)  # Signal OFF - dark copper #3D1F1A

func create_tooltip():
	tooltip_label = Label.new()
	tooltip_label.visible = false
	tooltip_label.z_index = 10

	# Load your font
	var font = load("res://assets/fonts/DigitalDisco.ttf")
	tooltip_label.add_theme_font_override("font", font)
	tooltip_label.add_theme_font_size_override("font_size", 16)
	tooltip_label.add_theme_color_override("font_color", Color(0.91, 0.94, 0.95))

	# Add background
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	stylebox.border_width_left = 2
	stylebox.border_width_right = 2
	stylebox.border_width_top = 2
	stylebox.border_width_bottom = 2
	stylebox.border_color = Color(0.56, 0.7, 0.66)
	tooltip_label.add_theme_stylebox_override("normal", stylebox)

	add_child(tooltip_label)

	# Create the edit field
	tooltip_edit = LineEdit.new()
	tooltip_edit.visible = false
	tooltip_edit.z_index = 100
	tooltip_edit.max_length = 20
	tooltip_edit.add_theme_font_override("font", font)
	tooltip_edit.add_theme_font_size_override("font_size", 16)
	tooltip_edit.custom_minimum_size = Vector2(100, 24)
	
	add_child(tooltip_edit)
	
	# Connect signals
	tooltip_edit.text_submitted.connect(_on_edit_submitted)
	tooltip_edit.focus_exited.connect(_on_edit_focus_lost)

func show_tooltip():
	if pin_name == "": return

	tooltip_label.text = pin_name
	tooltip_label.visible = true

	# Position based on pin type
	if pin_type == PinType.INPUT:
		tooltip_label.position = Vector2(-tooltip_label.size.x - 10, -tooltip_label.size.y / 2)
	else: tooltip_label.position = Vector2(10, -tooltip_label.size.y / 2)

func hide_tooltip():
	tooltip_label.visible = false

# Set collisions
func set_collisions() -> void:
	# Create area 2d
	area_2d = Area2D.new()
	area_2d.input_pickable = true
	add_child(area_2d)
	area_2d.input_event.connect(_on_area_input_event)

	# Create rectangle shape 2d
	rectangle_shape_2d = RectangleShape2D.new()
	rectangle_shape_2d.size = size

	# Create collision shape 2d
	collision_shape_2d = CollisionShape2D.new()
	collision_shape_2d.shape = rectangle_shape_2d
	collision_shape_2d.position = Vector2.ZERO
	area_2d.add_child(collision_shape_2d)

# Functions to handle pin
func _on_area_input_event(_viewport, event, _shape_idx) -> void: # Detect click on area 2d
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click and is_hovering: enter_edit_mode()
			else: pin_clicked.emit(self)

func enter_edit_mode():
	is_editing = true
	original_name = pin_name
	
	# Hide label, show edit
	tooltip_label.visible = false
	tooltip_edit.visible = true
	tooltip_edit.text = pin_name
	
	# Position the edit field (same logic as tooltip)
	if pin_type == PinType.INPUT:
		tooltip_edit.position = Vector2(-tooltip_edit.custom_minimum_size.x - 8, -tooltip_edit.custom_minimum_size.y / 2)
	else:
		tooltip_edit.position = Vector2(8, -tooltip_edit.custom_minimum_size.y / 2)
	
	# Focus the field and select all text
	tooltip_edit.grab_focus()
	tooltip_edit.select_all()

func exit_edit_mode(save: bool):
	is_editing = false
	
	if save: # Validate and save
		var new_name = tooltip_edit.text.strip_edges()
		if new_name.length() > 0: pin_name = new_name
		else: pin_name = original_name
	else: pin_name = original_name
	
	# Hide edit, show label
	tooltip_edit.visible = false
	tooltip_label.text = pin_name
	tooltip_label.visible = true

func _on_edit_submitted(_new_text: String):
	exit_edit_mode(true)

func _on_edit_focus_lost():
	if is_editing: exit_edit_mode(true)
