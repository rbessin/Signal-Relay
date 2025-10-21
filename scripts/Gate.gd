class_name Gate
extends Node2D

# Identity parameters (uid, type)
@export var uid: int
@export var type: String
# State parameters (input, output)
@export var input_values: Array[bool]
@export var output_value: bool
# Structure parameters (# of inputs, # of outputs)
@export var num_inputs: int
@export var num_outputs: int
# Visual parameters (coordinates)
@export var coordinates: Vector2

# Get input states to set output state
func evaluate() -> void:
	pass
# Set input state
func set_input(index, value):
	input_values[index] = value
	evaluate()
# Get output state
func get_output():
	return output_value
