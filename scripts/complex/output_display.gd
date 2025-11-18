extends Gate

func _ready() -> void:
	type = "OUTPUT"
	num_inputs = 1
	num_outputs = 0
	color = Color('#1F3D5C')
	border_color = Color('#8FB3A8')
	input_values = [false]
	super._ready()

func evaluate():
	if input_values.size() > 0:
		output_value = input_values[0]  # Just pass through the input
		update_visual()

func update_visual():
	if output_value:
		color_rect.modulate = Color('#4A8F6F')
		label.text = "True"
	else:
		color_rect.modulate = Color('#5C1F1A')
		label.text = "False"

func get_default_input_name(_index: int) -> String:
	return "In_0"
