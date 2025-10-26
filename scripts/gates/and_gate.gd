extends Gate

# Called when the node enters the scene tree for the first time.
func _ready():
	type = "AND"
	num_inputs = 2
	input_values = [false, false]
	output_value = false
	color = Color.BLUE
	super._ready()

func evaluate() -> void:
	output_value = input_values[0] and input_values[1]
