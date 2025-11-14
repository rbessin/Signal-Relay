extends Gate

var previous_clock_state: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	type = "D_FLIPFLOP"
	num_inputs = 2
	input_values = [false, false]
	output_value = false
	color = Color('#4F3D5C')
	border_color = Color('#8FB3A8')
	super._ready()

func evaluate() -> void:
	if previous_clock_state == false and input_values[1] == true:
		output_value = input_values[0]
	previous_clock_state = input_values[1]
