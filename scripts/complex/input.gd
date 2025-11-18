extends Gate

var on_color = Color('#FFB84D')

func _ready() -> void:
	type = "INPUT"
	num_inputs = 0
	output_value = false
	color = Color('#6F4F2D')
	border_color = Color('#8FB3A8')
	super._ready()

func toggle():
	print("Toggled.")
	output_value = !output_value
	update_visual()
	write_output_to_pin()
	propagate_to_wires()

func update_visual():
	if output_value: color_rect.modulate = on_color
	else: color_rect.modulate = color

func get_default_output_name(_index: int) -> String:
	return "Out_0"
