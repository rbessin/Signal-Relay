class_name GridBackground
extends Node2D

@export var grid_size: int = 32  # Size of each grid square in pixels
@export var grid_color: Color = Color(0.15, 0.35, 0.25, 0.6)  # Dark PCB green, semi-transparent
@export var grid_width: float = 2.0  # Line thickness
@export var major_grid_interval: int = 4  # Draw thicker line every N squares
@export var major_grid_color: Color = Color(0.2, 0.5, 0.35, 0.8)  # Slightly brighter for major lines
@export var major_grid_width: float = 4.0

@export var snap_enabled: bool = true

var camera: Camera2D

func _ready():
	# Find the camera
	camera = get_viewport().get_camera_2d()
	if not camera: push_error("GridBackground: No camera found!")

func _draw():
	if not camera: return
	
	var viewport_size = get_viewport_rect().size
	var camera_pos = camera.get_screen_center_position()
	var camera_zoom = camera.zoom.x
	
	# Calculate visible area with some padding
	var padding = grid_size * 2
	var start_x = int((camera_pos.x - (viewport_size.x / camera_zoom / 2) - padding) / grid_size) * grid_size
	var end_x = int((camera_pos.x + (viewport_size.x / camera_zoom / 2) + padding) / grid_size) * grid_size
	var start_y = int((camera_pos.y - (viewport_size.y / camera_zoom / 2) - padding) / grid_size) * grid_size
	var end_y = int((camera_pos.y + (viewport_size.y / camera_zoom / 2) + padding) / grid_size) * grid_size
	
	# Draw vertical lines
	var x = start_x
	while x <= end_x:
		var is_major = (x / grid_size) % major_grid_interval == 0
		var color = major_grid_color if is_major else grid_color
		var width = major_grid_width if is_major else grid_width
		draw_line(Vector2(x, start_y), Vector2(x, end_y), color, width)
		x += grid_size
	
	# Draw horizontal lines
	var y = start_y
	while y <= end_y:
		var is_major = (y / grid_size) % major_grid_interval == 0
		var color = major_grid_color if is_major else grid_color
		var width = major_grid_width if is_major else grid_width
		draw_line(Vector2(start_x, y), Vector2(end_x, y), color, width)
		y += grid_size

func _process(_delta):
	queue_redraw()  # Redraw each frame to follow camera movement

static func snap_to_grid(pos: Vector2, size: int = 32) -> Vector2:
	return Vector2(round(pos.x / size) * size, round(pos.y / size) * size)
