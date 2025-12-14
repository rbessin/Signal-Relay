extends Gate

# Clock control
@export var tick_rate: float = 0.5
@export var manual_mode: bool = false
var is_running: bool = false

@onready var timer: Timer
var on_color = Color('#FFB84D')

# Speed editing
var speed_label: Label
var speed_edit: LineEdit
var is_hovering: bool = false
var is_editing_speed: bool = false
var original_tick_rate: float = 0.5

func _ready():
	type = "CLOCK"
	num_inputs = 0
	num_outputs = 1
	color = Color('#6F4F2D')
	border_color = Color('#8FB3A8')
	super._ready()

	timer = Timer.new()
	add_child(timer)
	timer.wait_time = tick_rate
	timer.timeout.connect(toggle)
	timer.one_shot = false
	
	create_speed_tooltip()

func _process(_delta):
	if is_editing_speed and Input.is_action_just_pressed("ui_cancel"): # Cancel editing
		exit_speed_edit_mode(false)
		return

	if not is_editing_speed: # Checke if mouse is over the gate
		var mouse_pos = get_global_mouse_position()
		var gate_rect = Rect2(global_position - size / 2, size)
		
		if gate_rect.has_point(mouse_pos):
			if not is_hovering:
				show_speed_tooltip()
				is_hovering = true
		elif is_hovering:
			hide_speed_tooltip()
			is_hovering = false

func create_speed_tooltip():
	speed_label = Label.new()
	speed_label.visible = false
	speed_label.z_index = 10
	
	var font = load("res://assets/fonts/DigitalDisco.ttf")
	speed_label.add_theme_font_override("font", font)
	speed_label.add_theme_font_size_override("font_size", 14)
	speed_label.add_theme_color_override("font_color", Color.WHITE)
	
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	stylebox.border_width_left = 2
	stylebox.border_width_right = 2
	stylebox.border_width_top = 2
	stylebox.border_width_bottom = 2
	stylebox.border_color = Color(0.56, 0.7, 0.66)
	speed_label.add_theme_stylebox_override("normal", stylebox)
	
	add_child(speed_label)
	
	speed_edit = LineEdit.new()
	speed_edit.visible = false
	speed_edit.z_index = 100
	speed_edit.max_length = 10
	speed_edit.add_theme_font_override("font", font)
	speed_edit.add_theme_font_size_override("font_size", 14)
	speed_edit.custom_minimum_size = Vector2(80, 24)
	speed_edit.placeholder_text = "Hz"
	
	add_child(speed_edit)
	
	speed_edit.text_submitted.connect(_on_speed_edit_submitted)
	speed_edit.focus_exited.connect(_on_speed_edit_focus_lost)

func show_speed_tooltip(): # Update text and show tooltip
	var hz = 1.0 / tick_rate
	speed_label.text = "%.2f Hz" % hz
	speed_label.visible = true
	speed_label.position = Vector2(-speed_label.size.x / 2, size.y / 2 + 2)

func hide_speed_tooltip(): speed_label.visible = false

func enter_speed_edit_mode():
	is_editing_speed = true
	is_hovering = false
	original_tick_rate = tick_rate
	
	speed_label.visible = false
	speed_edit.visible = true
	speed_edit.text = "%.2f" % (1.0 / tick_rate)
	speed_edit.position = Vector2(-speed_edit.custom_minimum_size.x / 2, size.y / 2 + 10)
	
	speed_edit.grab_focus()
	speed_edit.select_all()

func exit_speed_edit_mode(save: bool):
	if not is_editing_speed: return
	is_editing_speed = false
	
	if save:
		var new_hz = float(speed_edit.text.strip_edges())
		if new_hz >= 0.01 and new_hz <= 100: set_speed(new_hz)
		elif new_hz > 100: set_speed(100)
		else: set_speed(0.01)
	else: tick_rate = original_tick_rate
	
	speed_edit.visible = false # Hide edit field
	
	var mouse_pos = get_global_mouse_position()
	var gate_rect = Rect2(global_position - size / 2, size)
	is_hovering = gate_rect.has_point(mouse_pos)
	
	# Show tooltip only if still hovering
	if is_hovering: show_speed_tooltip()

func _on_speed_edit_submitted(_new_text: String): exit_speed_edit_mode(true)

func _on_speed_edit_focus_lost(): # Only exit if still in editing mode
	if is_editing_speed: exit_speed_edit_mode(true)

func toggle():
	output_values[0] = !output_values[0]
	update_visual()
	write_output_to_pin()
	propagate_to_wires()

func manual_step():
	if manual_mode and is_running: toggle()

func start_clock():
	is_running = true
	output_values[0] = false
	update_visual()
	write_output_to_pin()
	propagate_to_wires()
	
	if not manual_mode:
		timer.start()

func stop_clock():
	is_running = false
	timer.stop()
	output_values[0] = false
	update_visual()
	write_output_to_pin()
	propagate_to_wires()

func set_speed(hz: float):
	tick_rate = 1.0 / hz
	timer.wait_time = tick_rate
	if is_running and not manual_mode:
		timer.stop()
		timer.start()

func update_visual():
	if output_values.size() > 0 and output_values[0]:
		color_rect.modulate = on_color
	else: color_rect.modulate = color

func _on_area_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click and is_hovering: enter_speed_edit_mode()
			else: gate_clicked.emit(self)

func get_default_output_name(_index: int) -> String: return "CLK"
