extends Gate

# Called when the node enters the scene tree for the first time.
func _ready():
	type = "NAND"
	num_inputs = 2
	input_values = [false, false]
	output_value = true

func evaluate() -> void:
	if input_values[0] and input_values[1]:
		output_value = false
	else: output_value = true
