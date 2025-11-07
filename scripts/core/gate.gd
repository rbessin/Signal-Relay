class_name Gate
extends Node2D

# Identity parameters (uid, type, selected)
@export var uid: int
@export var type: String = "BASE"
@export var selected: bool = false

# State parameters (input, output)
@export var input_values: Array[bool] = []
var previous_output_value: bool = false
@export var output_value: bool = false

# Structure parameters (# of inputs, # of outputs)
@export var num_inputs: int = 0
@export var num_outputs: int = 1

# Visual parameters (color, size, references)
@export var color: Color = Color.BLACK
@export var size: Vector2 = Vector2(60, 40)
@export var border_color: Color = Color.WHITE
@export var border_thickness: Vector2 = Vector2(6, 6)
var color_rect: ColorRect
var border_rect: ColorRect
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
	create_pins()

# Get input states to set output state
func evaluate() -> void:
	pass

func evaluate_with_propagation():
	var old_output = output_value
	read_inputs_from_pins()
	evaluate()
	write_output_to_pin()
	if output_value != old_output:
		propagate_to_wires()
	print(type, " evaluating, output: ", output_value)

# Set input state
func set_input(index, value):
	input_values[index] = value
	evaluate()

# Get output state
func get_output():
	return output_value

# Set visuals
func set_visuals() -> void:
	# Create selection border
	border_rect = ColorRect.new()
	border_rect.color = border_color
	border_rect.size = size + border_thickness
	border_rect.position = -(size + border_thickness) / 2
	border_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border_rect)
	border_rect.visible = false

	# Create background
	color_rect = ColorRect.new()
	color_rect.color = color
	color_rect.size = size
	color_rect.position = -size / 2
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)
	
	# Create label
	label = Label.new()
	label.text = type
	label.size = size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.WHITE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.add_child(label)

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

# Set selection
func set_selected(select: bool) -> void:
	selected = select
	if selected: border_rect.visible = true
	else: border_rect.visible = false

# On area input event
func _on_area_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			gate_clicked.emit(self)

# Create pins
func create_pins():
	for i in range(num_inputs): # Create input pins
		var pin = Pin.new()
		pin.pin_type = Pin.PinType.INPUT
		pin.parent_gate = self
		var x_pos = -size.x / 2
		var y_pos = -size.y / 2 + (size.y / (num_inputs + 1)) * (i + 1)
		pin.position = Vector2(x_pos, y_pos)
		add_child(pin)

	for i in range(num_outputs): # Create output pins
		var pin = Pin.new()
		pin.pin_type = Pin.PinType.OUTPUT
		pin.parent_gate = self
		var x_pos = size.x / 2
		var y_pos = -size.y / 2 + (size.y / (num_outputs + 1)) * (i + 1)
		pin.position = Vector2(x_pos, y_pos)
		add_child(pin)

# Get pin index with instance
func get_pin_by_index(pin_type: Pin.PinType, index: int) -> Pin:
	var counter = 0
	for child in get_children():
		if child is Pin and child.pin_type == pin_type:
			if counter == index:
				return child
			counter += 1
	return null
# Get pin index with instance (for saving)
func get_pin_index(pin: Pin) -> int:
	var counter = 0
	for child in get_children():
		if child is Pin and child.pin_type == pin.pin_type:
			if child == pin:
				return counter
			counter += 1
	return -1

# Read inputs
func read_inputs_from_pins():
	var input_num: int = 0
	for child in get_children():
		if child is Pin:
			if child.pin_type == Pin.PinType.INPUT:
				input_values[input_num] = child.signal_state
				input_num += 1

# Write output
func write_output_to_pin():
	for child in get_children():
		if child is Pin:
			if child.pin_type == Pin.PinType.OUTPUT:
				child.signal_state = output_value
				child.update_visuals()
				return

# Propagate output
func propagate_to_wires():
	for child in get_children():
		if child is Pin:
			if child.pin_type == Pin.PinType.OUTPUT:
				for wire in child.connected_wires:
					wire.propagate()
