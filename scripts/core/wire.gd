class_name Wire
extends Node2D

# Identity parameters (pins, selected)
var from_pin: Pin = null
var to_pin: Pin = null
var selected: bool = false

# Visual parameters (color, line, width)
var line: Line2D
var color: Color = Color.BLACK
var width: int = 4

# Preview parameters (end position, preview)
var preview_end_position: Vector2 = Vector2.ZERO
var is_preview: bool = false

# Collision parameters (area, shapes, signal)
var area_2d: Area2D
var collision_shape: CollisionShape2D
var rectangle_shape: RectangleShape2D
signal wire_clicked(wire_instance)

# Functions on mount and every frame
func _ready():
	line = Line2D.new()
	line.default_color = color
	line.width = width
	add_child(line)
	
	set_collisions()
	update_visuals()

func _process(_delta):
	update_visuals()
	update_collision()

# Updates visuals (accounts for gate movements)
func update_visuals():
	if from_pin == null: return
	
	var start_position = to_local(from_pin.global_position)
	var end_position: Vector2

	if is_preview: end_position = to_local(preview_end_position)
	elif to_pin != null: end_position = to_local(to_pin.global_position)
	else: return

	line.points = [start_position, end_position]

# Set collisions
func set_collisions():
	# Create area 2d
	area_2d = Area2D.new()
	area_2d.input_pickable = true
	add_child(area_2d)
	area_2d.input_event.connect(_on_area_input_event)
	
	# Create rectangle shape 2d
	rectangle_shape = RectangleShape2D.new()

	# Create collision shape 2d
	collision_shape = CollisionShape2D.new()
	collision_shape.shape = rectangle_shape
	area_2d.add_child(collision_shape)
	
	update_collision() # Update collisions

# Update collisions (accounts for gate movements)
func update_collision():
	if from_pin == null: return

	var start_pos: Vector2
	var end_pos: Vector2

	if is_preview: # Handles wire preview
		start_pos = to_local(from_pin.global_position)
		end_pos = to_local(preview_end_position)
	elif to_pin != null: # Handles instantiated wire
		start_pos = to_local(from_pin.global_position)
		end_pos = to_local(to_pin.global_position)
	else: return # Handles non-complete wire
	
	# Line calculations
	var line_length = start_pos.distance_to(end_pos)
	var line_angle = start_pos.angle_to_point(end_pos)
	var line_center = (start_pos + end_pos) / 2
	
	# Collision shape updates
	rectangle_shape.size = Vector2(line_length, width)
	collision_shape.position = line_center
	collision_shape.rotation = line_angle

# Functions to handle gate
func set_selected(is_selected: bool): # Set selection
	selected = is_selected
	if selected: 
		line.default_color = Color.YELLOW
		line.width = width + 1
	else: 
		line.default_color = color
		line.width = width

func _on_area_input_event(_viewport, event, _shape_idx): # Detect click on area 2d
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT: wire_clicked.emit(self)

# Functions to handle signal propagation
func propagate(): # Propagates signal from start pin to end pin
	# Sets line color
	if from_pin.signal_state == true: line.default_color = Color.LIGHT_YELLOW
	else: line.default_color = Color.BLACK

	# Sets pin states
	to_pin.signal_state = from_pin.signal_state
	to_pin.update_visuals()

	# Starts pin signal propagation
	to_pin.get_parent().evaluate_with_propagation()
