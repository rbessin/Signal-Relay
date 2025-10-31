class_name Wire
extends Node2D

# Identity parameters
var from_pin: Pin = null
var to_pin: Pin = null

# Visual parameters
var line: Line2D
var color: Color = Color.BLACK
var width: int = 4

# Preview parameters
var preview_end_position: Vector2 = Vector2.ZERO
var is_preview: bool = false

# Collision parameters
var area_2d: Area2D
var collision_shape: CollisionShape2D
var rectangle_shape: RectangleShape2D
signal wire_clicked(wire_instance)
var selected: bool = false

func _ready():
	line = Line2D.new()
	line.default_color = color
	line.width = width
	add_child(line)
	
	set_collisions()
	update_visuals()

func _process(_delta):
	update_visuals()

func update_visuals():
	if from_pin == null: return
	
	var start_position = to_local(from_pin.global_position)
	var end_position: Vector2

	if is_preview:
		end_position = to_local(preview_end_position)
	elif to_pin != null:
		end_position = to_local(to_pin.global_position)
	else: return

	line.points = [start_position, end_position]
	update_collision()

func set_collisions():
	area_2d = Area2D.new()
	area_2d.input_pickable = true
	
	rectangle_shape = RectangleShape2D.new()
	collision_shape = CollisionShape2D.new()
	collision_shape.shape = rectangle_shape

	add_child(area_2d)
	area_2d.add_child(collision_shape)
	
	area_2d.input_event.connect(_on_area_input_event)
	update_collision()

func update_collision():
	if from_pin == null: return

	var start_pos: Vector2
	var end_pos: Vector2

	if is_preview:
		start_pos = to_local(from_pin.global_position)
		end_pos = to_local(preview_end_position)
	elif to_pin != null:
		start_pos = to_local(from_pin.global_position)
		end_pos = to_local(to_pin.global_position)
	else: return
	
	var line_length = start_pos.distance_to(end_pos)
	var line_angle = start_pos.angle_to_point(end_pos)
	var line_center = (start_pos + end_pos) / 2
	
	rectangle_shape.size = Vector2(line_length, width)
	collision_shape.position = line_center
	collision_shape.rotation = line_angle

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