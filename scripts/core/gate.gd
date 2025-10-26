class_name Gate
extends Node2D

# Identity parameters (uid, type)
@export var uid: int
@export var type: String = "BASE"

# State parameters (input, output)
@export var input_values: Array[bool] = []
@export var output_value: bool = false

# Structure parameters (# of inputs, # of outputs)
@export var num_inputs: int = 0
@export var num_outputs: int = 1

# Visual parameters (color, size, references)
@export var color: Color = Color.BLACK
@export var size: Vector2 = Vector2(60, 40)
var color_rect: ColorRect
var label: Label

# Collisions
var area_2d: Area2D
var collision_shape_2d: CollisionShape2D
var rectangle_shape_2d: RectangleShape2D
signal gate_clicked(gate_instance)

# Sets visuals and collisions when added to the scene
func _ready() -> void:
	set_visuals()
	set_collisions()

# Get input states to set output state
func evaluate() -> void:
	pass

# Set input state
func set_input(index, value):
	input_values[index] = value
	evaluate()

# Get output state
func get_output():
	return output_value

# Set visuals
func set_visuals() -> void:
	# Create background
	color_rect = ColorRect.new()
	color_rect.color = color
	color_rect.size = size
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)
	
	# Create label
	label = Label.new()
	label.text = type
	label.size = size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.WHITE)
	color_rect.add_child(label)

# Set collisions
func set_collisions() -> void:
	area_2d = Area2D.new()
	area_2d.input_pickable = true
	collision_shape_2d = CollisionShape2D.new()
	rectangle_shape_2d = RectangleShape2D.new()
	rectangle_shape_2d.size = size
	collision_shape_2d.shape = rectangle_shape_2d
	collision_shape_2d.position = size / 2
	add_child(area_2d)
	area_2d.add_child(collision_shape_2d)
	area_2d.input_event.connect(_on_area_input_event)

# On area input event
func _on_area_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			gate_clicked.emit(self)
