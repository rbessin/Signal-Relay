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

# Grid snapping
const GRID_SIZE: int = 32

# Collision parameters (area, shapes, signal)
var area_2d: Area2D
var collision_shapes: Array[CollisionShape2D] = []
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

# Calculate orthogonal path between two points
func calculate_orthogonal_path(start: Vector2, end: Vector2) -> Array[Vector2]:
	var path: Array[Vector2] = []
	
	# Start point
	path.append(start)
	
	# Calculate offset
	var dx = end.x - start.x
	var dy = end.y - start.y
	
	# Snap midpoints to grid for cleaner routing
	var mid_x = GridBackground.snap_to_grid(Vector2(start.x + dx / 2, 0), GRID_SIZE).x
	var mid_y = GridBackground.snap_to_grid(Vector2(0, start.y + dy / 2), GRID_SIZE).y
	
	# Route based on which direction is dominant
	if abs(dx) > abs(dy):
		# Horizontal first, then vertical
		path.append(Vector2(mid_x, start.y))
		path.append(Vector2(mid_x, end.y))
	else:
		# Vertical first, then horizontal
		path.append(Vector2(start.x, mid_y))
		path.append(Vector2(end.x, mid_y))
	
	# End point
	path.append(end)
	
	return path

# Updates visuals (accounts for gate movements and orthogonal routing)
func update_visuals():
	if from_pin == null:
		return
	
	var start_position = to_local(from_pin.global_position)
	var end_position: Vector2

	if is_preview:
		end_position = to_local(preview_end_position)
	elif to_pin != null:
		end_position = to_local(to_pin.global_position)
	else:
		return

	# Calculate orthogonal path
	var path = calculate_orthogonal_path(start_position, end_position)
	
	# Update line points
	line.clear_points()
	for point in path:
		line.add_point(point)

# Set collisions
func set_collisions():
	# Create area 2d
	area_2d = Area2D.new()
	area_2d.input_pickable = true
	add_child(area_2d)
	area_2d.input_event.connect(_on_area_input_event)

# Update collisions (accounts for gate movements and multiple segments)
func update_collision():
	if from_pin == null:
		return
	
	# Clear old collision shapes
	for shape in collision_shapes:
		shape.queue_free()
	collision_shapes.clear()
	
	# Wait for line points to be updated
	if line.get_point_count() < 2:
		return
	
	# Create collision shape for each line segment
	for i in range(line.get_point_count() - 1):
		var p1 = line.get_point_position(i)
		var p2 = line.get_point_position(i + 1)
		
		# Calculate segment properties
		var line_length = p1.distance_to(p2)
		var line_angle = p1.angle_to_point(p2)
		var line_center = (p1 + p2) / 2
		
		# Create collision shape for this segment
		var rectangle_shape = RectangleShape2D.new()
		rectangle_shape.size = Vector2(line_length, width + 2)  # Slightly wider for easier clicking
		
		var collision_shape = CollisionShape2D.new()
		collision_shape.shape = rectangle_shape
		collision_shape.position = line_center
		collision_shape.rotation = line_angle
		
		area_2d.add_child(collision_shape)
		collision_shapes.append(collision_shape)

# Functions to handle selection
func set_selected(is_selected: bool):
	selected = is_selected
	if selected:
		line.default_color = Color.YELLOW
		line.width = width + 1
	else:
		line.default_color = color
		line.width = width

func _on_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			wire_clicked.emit(self)

# Functions to handle signal propagation
func propagate():
	# Sets line color based on signal state
	if from_pin.signal_state == true:
		line.default_color = Color.LIGHT_YELLOW
	else:
		line.default_color = Color.BLACK

	# Sets pin states
	to_pin.signal_state = from_pin.signal_state
	to_pin.update_visuals()

	# Starts pin signal propagation
	to_pin.get_parent().evaluate_with_propagation()