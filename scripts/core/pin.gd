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
var color_rect: ColorRect
var color: Color = Color.GRAY
var size: Vector2 = Vector2(8, 8)

# Collision parameters
var area_2d: Area2D
var collision_shape_2d: CollisionShape2D
var rectangle_shape_2d: RectangleShape2D
signal pin_clicked(pin_instance)

# Runs on instantiation
func _ready() -> void:
	set_visuals()
	set_collisions()

# Set visuals
func set_visuals():
	color_rect = ColorRect.new()
	color_rect.color = color
	color_rect.size = size
	color_rect.position = -size / 2
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)

# Update visuals
func update_visuals():
	if signal_state == true: color_rect.color = Color.YELLOW
	else: color_rect.color = Color.GRAY

# Set collisions
func set_collisions() -> void:
	area_2d = Area2D.new()
	area_2d.input_pickable = true
	collision_shape_2d = CollisionShape2D.new()
	rectangle_shape_2d = RectangleShape2D.new()
	rectangle_shape_2d.size = size
	collision_shape_2d.shape = rectangle_shape_2d
	collision_shape_2d.position = Vector2.ZERO
	add_child(area_2d)
	area_2d.add_child(collision_shape_2d)
	area_2d.input_event.connect(_on_area_input_event)

# On area input event
func _on_area_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			pin_clicked.emit(self)
