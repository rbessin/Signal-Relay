extends Gate

var tick_rate: float
@onready var timer: Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	type = "CLOCK"
	num_inputs = 0
	output_value = false
	color = Color.GRAY
	super._ready()

	timer = Timer.new()
	add_child(timer)
	timer.wait_time = tick_rate
	timer.timeout.connect(toggle)

func toggle():
	output_value = !output_value
	update_visual()
	write_output_to_pin()
	propagate_to_wires()

func start_clock():
	output_value = false
	update_visual()
	write_output_to_pin()
	propagate_to_wires()
	timer.start()

func stop_clock():
	timer.stop()
	output_value = false
	update_visual()
	write_output_to_pin()
	propagate_to_wires()

func update_visual():
	if output_value: color_rect.color = Color.YELLOW
	else: color_rect.color = Color.GRAY
