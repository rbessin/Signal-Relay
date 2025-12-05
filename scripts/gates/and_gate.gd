extends Gate

# Called when the node enters the scene tree for the first time.
func _ready():
	type = "AND"
	num_inputs = 2
	num_outputs = 1
	input_values = [false, false]
	color = Color('#1E4D5C')
	border_color = Color('#8FB3A8')
	super._ready()

func evaluate() -> void:
	output_values[0] = input_values[0] and input_values[1]
