extends Gate

# Called when the node enters the scene tree for the first time.
func _ready():
	type = "XOR"
	num_inputs = 2
	input_values = [false, false]
	output_value = false

func evaluate() -> void:
	if input_values[0] and not input_values[1]:
		output_value = true
	elif input_values[1] and not input_values[0]:
		output_value = true
	else: output_value = false
