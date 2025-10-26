extends Gate

# Called when the node enters the scene tree for the first time.
func _ready():
	type = "XOR"
	num_inputs = 2
	input_values = [false, false]
	output_value = false
	color = Color.PURPLE
	super._ready()

func evaluate() -> void:
	output_value = input_values[0] != input_values[1]
