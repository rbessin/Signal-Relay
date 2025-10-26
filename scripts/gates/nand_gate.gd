extends Gate

# Called when the node enters the scene tree for the first time.
func _ready():
	type = "NAND"
	num_inputs = 2
	input_values = [false, false]
	output_value = true
	color = Color.LIGHT_BLUE
	super._ready()

func evaluate() -> void:
	output_value = not(input_values[0] and input_values[1])
