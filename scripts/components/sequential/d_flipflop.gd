extends Gate

var previous_clock_state: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	type = "D-FLIPFLOP"
	num_inputs = 2
	num_outputs = 1
	input_values = [false, false]
	color = Color('#4F3D5C')
	border_color = Color('#8FB3A8')
	super._ready()

func evaluate() -> void:
	if previous_clock_state == false and input_values[1] == true:
		output_values[0] = input_values[0]
	previous_clock_state = input_values[1]

func get_default_input_name(index: int) -> String:
	if index == 0:
		return "D"
	elif index == 1:
		return "CLK"
	return "In_" + str(index)

func get_default_output_name(_index: int) -> String:
	return "Out_0"
