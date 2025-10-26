extends Node2D

# Cursor configurations (mode)
enum Mode { INTERACT, PLACE }
var current_mode: Mode = Mode.INTERACT

# Gate selection (prefabs, selected, uid counter)
var gate_prefabs: Dictionary = {
	"AND": preload("res://scenes/gates/and_gate.tscn"),
	"NAND": preload("res://scenes/gates/nand_gate.tscn"),
	"OR": preload("res://scenes/gates/or_gate.tscn"),
	"NOR": preload("res://scenes/gates/nor_gate.tscn"),
	"NOT": preload("res://scenes/gates/not_gate.tscn"),
	"XOR": preload("res://scenes/gates/xor_gate.tscn")
}
var gate_to_place: PackedScene = preload("res://scenes/gates/and_gate.tscn")  # Which gate type to place
var selected_gate_instance: Gate = null  									  # Which gate is selected
var current_uid: int = 0

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if current_mode == Mode.PLACE:
				instantiate_gate()
			elif current_mode == Mode.INTERACT:
				selected_gate_instance = null


func instantiate_gate():
	if gate_to_place == null: return
	
	var new_gate = gate_to_place.instantiate()
	add_child(new_gate)
	new_gate.uid = _generate_uid()
	new_gate.name = new_gate.type + '_' + str(new_gate.uid)
	new_gate.gate_clicked.connect(_select_gate_instance)
	new_gate.global_position = get_global_mouse_position()

func _select_place(gate_name: String):
	if gate_name in gate_prefabs: 
		gate_to_place = gate_prefabs[gate_name]
	current_mode = Mode.PLACE
	selected_gate_instance = null

func _select_interact():
	current_mode = Mode.INTERACT

func _select_gate_instance(gate_instance: Gate):
	if current_mode == Mode.INTERACT:
		selected_gate_instance = gate_instance

func _on_mode_selected(mode_selection: Mode):
	current_mode = mode_selection

func _generate_uid():
	current_uid += 1
	return current_uid
