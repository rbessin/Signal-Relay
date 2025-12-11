class_name CircuitPersistenceManager
extends Node

var main: Node2D # Reference to main script
var gate_manager: GateManager # Manager references
var wire_manager: WireManager

var file_name_input: LineEdit # UI references
var clear_button: Button
var save_button: Button
var load_button: Button
var step_clock_button: Button
var clock_mode_toggle_button: Button

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
	step_clock_button = simulation_secondary.get_node('StepClockButton')
	clock_mode_toggle_button = simulation_secondary.get_node('ClockModeButton')

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

	for gate in circuit_dict["gates"]:
		var new_gate: Gate = null
		
		var component_file = "user://components/" + gate["type"] + ".json"
		if FileAccess.file_exists(component_file): # Check if it's a custom component
			new_gate = gate_manager.create_custom_component(gate["type"], Vector2(gate["x"], gate["y"]))
			if new_gate: # Override the auto-generated UID with the saved one
				new_gate.uid = gate["uid"]
				new_gate.name = gate["type"] + '_' + gate["uid"]
		else: # It's a hardcoded gate
			new_gate = gate_manager.create_gate(
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
	
	main.center_camera_on_circuit()
	update_clock_mode_button_text()

func empty_circuit():
	main.selection_manager.clear_selection() # Clear selection
	for child in gate_manager.gates.duplicate(): # Empty current scene
		gate_manager.delete_gate(child)
	
	update_clock_mode_button_text()
	
	if main.current_mode == main.Mode.SIMULATE:
		update_step_clock_button_visibility()

func step_manual_clocks(): # Step all clocks that are in manual mode
	var stepped_count = 0
	for gate in gate_manager.gates:
		if gate.type == "CLOCK" and gate.has_method("manual_step"):
			if gate.manual_mode and gate.is_running:
				gate.manual_step()
				stepped_count += 1
	
	if stepped_count > 0: print("Stepped ", stepped_count, " clock(s)")
	else: print("No manual clocks to step")

func update_step_clock_button_visibility(): # Show button in SIMULATE and manual modes
	if main.current_mode != main.Mode.SIMULATE:
		step_clock_button.visible = false
		return
	
	# Check if any manual clocks exist
	var has_manual_clock = false
	for gate in gate_manager.gates:
		if gate.type == "CLOCK" and gate.manual_mode:
			has_manual_clock = true
			break
	
	step_clock_button.visible = has_manual_clock

func toggle_clock_mode(): # Find all clocks and toggle their mode
	var has_clocks = false
	var new_mode = null
	
	for gate in gate_manager.gates:
		if gate.type == "CLOCK":
			has_clocks = true
			if new_mode == null: new_mode = !gate.manual_mode  # Flip the mode
			if gate.is_running: gate.stop_clock()
	
	if has_clocks:
		for gate in gate_manager.gates:
			if gate.type == "CLOCK": 
				gate.manual_mode = new_mode
				# Restart clock if in simulate mode
				if main.current_mode == main.Mode.SIMULATE: gate.start_clock()
		
		# Update button text
		clock_mode_toggle_button.text = "Clock: Manual" if new_mode else "Clock: Auto"
		update_step_clock_button_visibility()

func update_clock_mode_button_text(): # Update clock mode button text
	var is_manual = false
	for gate in gate_manager.gates:
		if gate.type == "CLOCK":
			is_manual = gate.manual_mode
			break

	clock_mode_toggle_button.text = "Clock [MANUAL]" if is_manual else "Clock [AUTO]"
