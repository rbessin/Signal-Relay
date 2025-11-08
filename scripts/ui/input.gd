extends Gate

func _ready() -> void:
	type = "INPUT"
	num_inputs = 0
	output_value = false
	color = Color.GRAY
	super._ready()

func toggle():
	print("Toggled.")
	output_value = !output_value
	update_visual()
	write_output_to_pin()
	propagate_to_wires()

func update_visual():
	if output_value: color_rect.color = Color.YELLOW
	else: color_rect.color = Color.GRAY
