extends Gate


# Called when the node enters the scene tree for the first time.
func _ready():
	type = "NOT"
	num_inputs = 1
	input_values = [false]
	output_value = true
	color = Color.ORANGE
	super._ready()

func evaluate() -> void:
	output_value = not input_values[0]
