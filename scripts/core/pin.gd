class_name Pin
extends Node2D

# Identity parameters (type, state)
enum PinType { INPUT, OUTPUT }
var pin_type: PinType = PinType.INPUT
var signal_state: bool = false

# Connection parameters (parents, wires)
var parent_gate: Gate
var connected_wires: Array = []

# Visual parameters (color, size, refs)
var color_rect: Sprite2D
var color: Color = Color.GRAY
var size: Vector2 = Vector2(12, 12)

# Collision parameters (area, shapes, signal)
var area_2d: Area2D
var collision_shape_2d: CollisionShape2D
var rectangle_shape_2d: RectangleShape2D
signal pin_clicked(pin_instance)

# Functions on mount and every frame
func _ready() -> void:
	set_visuals()
	set_collisions()

# Set visuals
func set_visuals():
	var pin_texture = load("res://assets/art/pin_12x12.png")
	
	var sprite = Sprite2D.new()
	sprite.texture = pin_texture
	sprite.centered = true
	add_child(sprite)
	
	# Store reference for updating colors
	color_rect = sprite  # Reusing the variable name to minimize changes
	update_visuals()

# Update visuals
func update_visuals(): # Colors reflect signal state
	if signal_state == true:
		color_rect.modulate = Color(1.0, 0.72, 0.3)  # Signal ON - bright copper #FFB84D
	else:
		color_rect.modulate = Color(0.24, 0.12, 0.1)  # Signal OFF - dark copper #3D1F1A

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
			pin_clicked.emit(self)
