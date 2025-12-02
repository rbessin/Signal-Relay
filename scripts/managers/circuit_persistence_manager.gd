class_name CircuitPersistenceManager
extends Node

var main: Node2D # Reference to main script
var gate_manager: GateManager # Manager references
var wire_manager: WireManager

var file_name_input: LineEdit # UI references
var clear_button: Button
var save_button: Button
var load_button: Button

func _init(main_node: Node2D):
	main = main_node
	print("CircuitPersistenceManager instantiated.")

func setup_ui_references():
	var simulation_base = main.get_node('UICanvas/UIControl/Inspector/VBoxContainer/ScrollableContent/ContentContainer/SimulationSection')
	var simulation_primary = simulation_base.get_node('PrimarySimulationContent')
	var simulation_secondary = simulation_base.get_node('SecondarySimulationContent')
	file_name_input = simulation_secondary.get_node('FileNameInput')
	clear_button = simulation_primary.get_node('Clear Scene')
	save_button = simulation_primary.get_node('Save')
	load_button = simulation_primary.get_node('Load')

func handle_save():
	on_save_button_pressed()

func handle_load():
	on_load_button_pressed()

func on_save_button_pressed():
	var circuit_name = file_name_input.text # Retrieve name and save circuit to json using helper
	if circuit_name == "": circuit_name = "unnamed_circuit"
	CircuitSerializer.save_to_json(gate_manager.gates, wire_manager.wires, circuit_name)

func on_load_button_pressed():
	var circuit_name = file_name_input.text # Retrieve name and load circuit from json using helper
	if circuit_name == "": circuit_name = "unnamed_circuit"
	load_circuit(circuit_name)

func load_circuit(circuit_name: String):
	empty_circuit()

	var circuit_dict = CircuitSerializer.load_from_json(circuit_name) # Retrieve circuit data
	if circuit_dict == null: return

	var gates_by_uid: Dictionary = {}

	for gate in circuit_dict["gates"]: # Create circuit gates
		var new_gate = gate_manager.create_gate(
			gate["type"], 
			Vector2(gate["x"], gate["y"]),
			gate["uid"]
		)
		if new_gate != null: gates_by_uid[gate["uid"]] = new_gate
	
	await main.get_tree().process_frame

	for wire in circuit_dict["wires"]: # Create wire gates
		var source_gate = gates_by_uid[wire["from_gate"]] # Get wire gates
		var destination_gate = gates_by_uid[wire["to_gate"]]
		var source_pin = source_gate.get_pin_by_index(Pin.PinType.OUTPUT, wire["from_pin"]) # Get wire pins
		var destination_pin = destination_gate.get_pin_by_index(Pin.PinType.INPUT, wire["to_pin"])
		
		if source_pin == null or destination_pin == null: continue
		
		var new_wire = Wire.new()
		new_wire.from_pin = source_pin
		new_wire.to_pin = destination_pin
		main.add_child(new_wire)
		wire_manager.wires.append(new_wire)
		
		source_pin.connected_wires.append(new_wire)
		destination_pin.connected_wires.append(new_wire)

func empty_circuit():
	for child in gate_manager.gates.duplicate(): # Empty current scene
		gate_manager.delete_gate(child)
