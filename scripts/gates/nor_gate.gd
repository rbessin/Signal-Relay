extends Gate

# Called when the node enters the scene tree for the first time.
func _ready():
	type = "NOR"
	num_inputs = 2
	input_values = [false, false]
	output_value = true
	color = Color('#3D4F5C')
	border_color = Color('#8FB3A8')
	super._ready()

func evaluate() -> void:
	output_value = not(input_values[0] or input_values[1])
