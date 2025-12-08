extends Gate

var on_color = Color('#FFB84D')

func _ready() -> void:
	type = "INPUT"
	num_inputs = 0
	num_outputs = 1
	color = Color('#6F4F2D')
	border_color = Color('#8FB3A8')
	super._ready()

func toggle():
	print("Toggled.")
	output_values[0] = !output_values[0]
	update_visual()
	write_output_to_pin()
	propagate_to_wires()

func update_visual():
	if output_values.size() > 0 and output_values[0]:
		color_rect.modulate = on_color
	else: color_rect.modulate = color

func get_default_output_name(_index: int) -> String:
	return "Out_0"
