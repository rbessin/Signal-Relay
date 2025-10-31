extends Gate

func _ready() -> void:
	type = "OUTPUT"
	num_inputs = 1
	num_outputs = 0
	color = Color.GRAY
	input_values = [false]
	super._ready()

func evaluate():
	if input_values.size() > 0:
		output_value = input_values[0]  # Just pass through the input
		update_visual()

func update_visual():
	if output_value:
		color_rect.color = Color.GREEN
		label.text = "True"
	else:
		color_rect.color = Color.GRAY
		label.text = "False"
