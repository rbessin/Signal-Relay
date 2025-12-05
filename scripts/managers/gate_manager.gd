class_name GateManager
extends Node

var main: Node2D # Reference to main script
var selection_manager: SelectionManager # Manager references
var wire_manager: WireManager

# Hard-coded gate prefabs
var gate_prefabs: Dictionary = {
	"AND": preload("res://scenes/gates/and_gate.tscn"),
	"NAND": preload("res://scenes/gates/nand_gate.tscn"),
	"OR": preload("res://scenes/gates/or_gate.tscn"),
	"NOR": preload("res://scenes/gates/nor_gate.tscn"),
	"NOT": preload("res://scenes/gates/not_gate.tscn"),
	"XOR": preload("res://scenes/gates/xor_gate.tscn"),
	"BUFFER": preload("res://scenes/gates/buffer_gate.tscn"),
	"INPUT": preload("res://scenes/complex/input.tscn"),
	"OUTPUT": preload("res://scenes/complex/output_display.tscn"),
	"CLOCK": preload("res://scenes/complex/clock.tscn"),
	"D_FLIPFLOP": preload("res://scenes/complex/d_flipflop.tscn"),
}

# Placement
var gate_to_place: PackedScene = null
var gate_type_to_place: String = ""

# Tracking
var gates: Array[Gate] = []

func _init(main_node: Node2D):
	main = main_node
	print("GateManager instantiated.")

func instantiate_gate():
	if gate_type_to_place == "": return # Return if there is no chosen gate
	var mouse_pos = main.get_global_mouse_position()
	var snapped_pos = GridBackground.snap_to_grid(mouse_pos, 32)

	# Build file path and instantiate component/gate
	if gate_type_to_place in gate_prefabs: create_gate(gate_type_to_place, snapped_pos)
	else: create_custom_component(gate_type_to_place, snapped_pos)

func create_gate(gate_type: String, pos: Vector2, uid: String = "") -> Gate:
	if gate_type not in gate_prefabs: return null # Return if there exists no hard-coded gate

	var new_gate = gate_prefabs[gate_type].instantiate() # Instantiate hard-coded gate
	main.add_child(new_gate)

	if uid == "": new_gate.uid = generate_uid() # Generate uid or use chosen
	else: new_gate.uid = uid
	
	# Set gate properties
	new_gate.name = new_gate.type + '_' + str(new_gate.uid)
	new_gate.global_position = pos
	new_gate.gate_clicked.connect(selection_manager.select_gate_instance)
	main.call_deferred("_connect_gate_pins", new_gate)
	gates.append(new_gate)
	return new_gate

func create_custom_component(component_name: String, pos: Vector2) -> CustomComponent:
	var new_component = CustomComponent.new() # Create custom component

	# Set custom component properties
	new_component.component_definition_name = component_name
	new_component.uid = generate_uid()
	new_component.global_position = pos
	new_component.name = component_name + '_' + new_component.uid
	main.add_child(new_component)
	new_component.gate_clicked.connect(selection_manager.select_gate_instance)
	main.call_deferred("_connect_gate_pins", new_component)
	gates.append(new_component)
	return new_component

func delete_gate(gate: Gate):
	for child in gate.get_children(): # Loop over gate children to find pins
		if child is Pin:
			for wire in child.connected_wires.duplicate(): # Loop over pin wires
				wire_manager.delete_wire(wire) # Delete each wire
	
	gates.erase(gate) # Delete gate
	gate.queue_free()

func generate_uid() -> String: # Generate random 8 character strings
	const CHARS = "abcdefghijklmnopqrstuvwxyz0123456789"
	var uid = ""
	for i in range(8): uid += CHARS[randi() % CHARS.length()]
	return uid

func set_gate_to_place(gate_name: String):
	gate_type_to_place = gate_name # Choose hard-coded gate type to place
	if gate_name in gate_prefabs: gate_to_place = gate_prefabs[gate_name]
	else: gate_to_place = null

func clear_gate_to_place():
	gate_to_place = null # Clear selected gate to place
	gate_type_to_place = ""
