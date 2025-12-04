extends Gate

# Clock control
@export var tick_rate: float = 0.5  # Seconds per tick
@export var manual_mode: bool = true  # Enable manual stepping
var is_running: bool = false

@onready var timer: Timer
var on_color = Color('#FFB84D')

func _ready():
	type = "CLOCK"
	num_inputs = 0
	output_value = false
	color = Color('#6F4F2D')
	border_color = Color('#8FB3A8')
	super._ready()

	timer = Timer.new()
	add_child(timer)
	timer.wait_time = tick_rate
	timer.timeout.connect(toggle)
	timer.one_shot = false  # Repeat automatically

func toggle():
	output_value = !output_value
	update_visual()
	write_output_to_pin()
	propagate_to_wires()

func manual_step(): # Trigger clock pulse
	if manual_mode and is_running:
		toggle()
		print("Clock stepped!")

func start_clock():
	is_running = true
	output_value = false
	update_visual()
	write_output_to_pin()
	propagate_to_wires()
	
	if not manual_mode:
		timer.start()
		print("Clock running automatically at ", 1.0/tick_rate, " Hz")
	else: print("Clock in MANUAL mode - use Step Clock button")

func stop_clock():
	is_running = false
	timer.stop()
	output_value = false
	update_visual()
	write_output_to_pin()
	propagate_to_wires()

func set_speed(hz: float): # Change clock speed in cycles per second
	tick_rate = 1.0 / hz
	timer.wait_time = tick_rate
	if is_running and not manual_mode:
		timer.start()  # Restart with new speed
	print("Clock speed set to ", hz, " Hz (", tick_rate, " seconds per tick)")

func update_visual():
	if output_value: color_rect.modulate = on_color
	else: color_rect.modulate = color

func get_default_output_name(index: int) -> String:
	return "CLK"
