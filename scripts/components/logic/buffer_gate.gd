extends Gate

func _ready():
	type = "BUFFER"
	num_inputs = 1
	num_outputs = 1
	input_values = [false]
	color = Color(0.4, 0.4, 0.4)  # Gray
	border_color = Color(0.6, 0.6, 0.6)
	super._ready()

func evaluate() -> void:
	# Just pass input directly to output
	output_values[0] = input_values[0]

func get_default_input_name(_index: int) -> String: return "In"

func get_default_output_name(_index: int) -> String: return "Out"
