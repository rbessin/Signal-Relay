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
@export var border_thickness: Vector2 = Vector2(12, 12)
var color_rect: NinePatchRect
var border_rect: NinePatchRect
var selection_rect: NinePatchRect
var label: Label

# Collision parameters (area, shapes, signal)
var area_2d: Area2D
var collision_shape_2d: CollisionShape2D
var rectangle_shape_2d: RectangleShape2D
signal gate_clicked(gate_instance)

# Functions on mount and every frame
func _ready() -> void: # Sets visuals, collisions and pins when added to the scene
	set_visuals()
	set_collisions()
	create_pins()

# Functions to handle evaluation and propagation
func evaluate() -> void: # Evaluates inputs to set output (to be overriden by subclasses)
	pass

func evaluate_with_propagation() -> void: # Gets inputs, evaluates inputs, sets output (evaluation cycle)
	var old_output = output_value
	read_inputs_from_pins()
	evaluate()
	write_output_to_pin()
	if output_value != old_output: propagate_to_wires()

func propagate_to_wires(): # Propagate output to wires
	for child in get_children():
		if child is Pin:
			if child.pin_type == Pin.PinType.OUTPUT:
				for wire in child.connected_wires:
					wire.propagate()

# Calculate gate size based on text and pin count
func calculate_gate_size(font: Font) -> void:
	# Calculate width based on text length
	var text_size = font.get_string_size(type, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	var min_width = 96  # Minimum gate width
	var text_padding = 32  # Padding around text (16px on each side)
	var calculated_width = text_size.x + text_padding
	
	# Use the larger of minimum width or calculated width
	var final_width = max(min_width, calculated_width)
	
	# Calculate height based on number of pins (use the larger of inputs/outputs)
	var max_pins = max(num_inputs, num_outputs)
	var final_height = 24 + (20 * max_pins)
	
	# Set the size
	size = Vector2(final_width, final_height)

# Set visuals
func set_visuals() -> void:
	# Load assets
	var border_texture = load("res://assets/art/gate_border_64x64.png")
	var fill_texture = load("res://assets/art/gate_fill_64x64.png")
	var font = load("res://assets/fonts/DigitalDisco.ttf")
	
	# Calculate dynamic gate size
	calculate_gate_size(font)

	# Create background (NinePatch)
	color_rect = NinePatchRect.new()
	color_rect.texture = fill_texture
	color_rect.patch_margin_left = 4
	color_rect.patch_margin_right = 4
	color_rect.patch_margin_top = 4
	color_rect.patch_margin_bottom = 4
	color_rect.custom_minimum_size = size
	color_rect.position = -size / 2
	color_rect.self_modulate = color
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)
	
	# Create border (NinePatch) - always visible
	border_rect = NinePatchRect.new()
	border_rect.texture = border_texture
	border_rect.patch_margin_left = 4
	border_rect.patch_margin_right = 4
	border_rect.patch_margin_top = 4
	border_rect.patch_margin_bottom = 4
	border_rect.self_modulate = border_color
	border_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.add_child(border_rect)
	border_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create selection overlay (NinePatch) - only visible when selected
	selection_rect = NinePatchRect.new()
	selection_rect.texture = border_texture
	selection_rect.patch_margin_left = 4
	selection_rect.patch_margin_right = 4
	selection_rect.patch_margin_top = 4
	selection_rect.patch_margin_bottom = 4
	selection_rect.self_modulate = Color.WHITE
	selection_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_rect.visible = false  # Hidden by default
	color_rect.add_child(selection_rect)
	selection_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create label
	label = Label.new()
	label.text = type
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.BLACK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

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

func set_selected(select: bool) -> void: # Set selection
	selected = select
	if selection_rect: selection_rect.visible = selected

func _on_area_input_event(_viewport, event, _shape_idx) -> void: # Detect click on area 2d
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			gate_clicked.emit(self)

# Functions to handle inputs and outputs
func set_input(index, value) -> void: # Set input state
	input_values[index] = value
	evaluate()

func get_output() -> bool: # Get output state
	return output_value

func read_inputs_from_pins() -> void: # Read inputs from pins
	var input_num: int = 0
	for child in get_children():
		if child is Pin:
			if child.pin_type == Pin.PinType.INPUT:
				input_values[input_num] = child.signal_state
				input_num += 1

func write_output_to_pin() -> void: # Write output to pin
	for child in get_children():
		if child is Pin:
			if child.pin_type == Pin.PinType.OUTPUT:
				child.signal_state = output_value
				child.update_visuals()
				return

# Functions to handle pins
func create_pins(): # Create pins
	var pin_size = 12.0
	var pin_spacing = 8.0
	var border_thickness_val = 4.0  # Your border is 4px
	var interior_height = size.y - (border_thickness_val * 2)
	
	# Create input pins
	if num_inputs > 0:
		# Calculate equal top and bottom padding
		var total_pin_height = num_inputs * pin_size
		var total_gaps = (num_inputs - 1) * pin_spacing
		var remaining_space = interior_height - total_pin_height - total_gaps
		var top_padding = remaining_space / 2.0
		
		for i in range(num_inputs):
			var pin = Pin.new()
			pin.pin_type = Pin.PinType.INPUT
			pin.parent_gate = self
			var x_pos = -size.x / 2
			# Start from top border, add padding, then position each pin
			var y_pos = -size.y / 2 + border_thickness_val + top_padding + (pin_size / 2.0) + i * (pin_size + pin_spacing)
			pin.position = Vector2(x_pos, y_pos)
			add_child(pin)
	
	# Create output pins
	if num_outputs > 0:
		# Calculate equal top and bottom padding
		var total_pin_height = num_outputs * pin_size
		var total_gaps = (num_outputs - 1) * pin_spacing
		var remaining_space = interior_height - total_pin_height - total_gaps
		var top_padding = remaining_space / 2.0
		
		for i in range(num_outputs):
			var pin = Pin.new()
			pin.pin_type = Pin.PinType.OUTPUT
			pin.parent_gate = self
			var x_pos = size.x / 2
			# Start from top border, add padding, then position each pin
			var y_pos = -size.y / 2 + border_thickness_val + top_padding + (pin_size / 2.0) + i * (pin_size + pin_spacing)
			pin.position = Vector2(x_pos, y_pos)
			add_child(pin)

func get_pin_by_index(pin_type: Pin.PinType, index: int) -> Pin: # Get pin with pin index (loading)
	var counter = 0
	for child in get_children():
		if child is Pin and child.pin_type == pin_type:
			if counter == index: return child
			counter += 1
	return null

func get_pin_index(pin: Pin) -> int: # Get pin index with instance (saving)
	var counter = 0
	for child in get_children():
		if child is Pin and child.pin_type == pin.pin_type:
			if child == pin: return counter
			counter += 1
	return -1
