extends Label

# Identity parameters
@export var source_gate: Gate = null

func _process(delta):
	if source_gate != null:
		var output = source_gate.get_output()
		text = "Output: " + str(output)
