class_name Wire
extends Node2D

var from_pin: Pin = null
var to_pin: Pin = null
var line: Line2D
var color: Color = Color.BLACK
var width: int = 2

var preview_end_position: Vector2 = Vector2.ZERO
var is_preview: bool = false

# Runs on instantiation
func _ready():
	line = Line2D.new()
	line.default_color = color
	line.width = width
	add_child(line)
	update_visuals()

# Runs on every frame.
func _process(_delta):
	update_visuals()

# Set visuals
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
