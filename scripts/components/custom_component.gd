class_name CustomComponent
extends Gate

# Component definition data
var component_definition_name: String = ""
var component_data: Dictionary = {}

# Internal circuit
var internal_circuit_container: Node2D

# Pin mappings (external index → internal gate/pin reference)
var input_mappings: Array = []
var output_mappings: Array = []

func _init():
	# Set component-specific defaults
	type = "CUSTOM"
	color = Color(0.85, 0.65, 0.13)  # Purple to distinguish from base gates
	border_color = Color(0.65, 0.45, 0.08)

# Override _ready to handle component-specific setup
func _ready():
	if component_definition_name != "": _load_and_build_component()
	else: super._ready()  # Fall back to normal gate setup

# Load component definition and build internal circuit
func _load_and_build_component():
	# Load the JSON definition
	component_data = ComponentSerializer.load_component(component_definition_name)
	
	if component_data.is_empty():
		print("Error: Failed to load component definition")
		return
	
	# Set the gate type to the component name
	type = component_data["name"]
	
	# Set number of pins based on external pin count
	num_inputs = component_data["external_inputs"].size()
	num_outputs = component_data["external_outputs"].size()
	
	# Initialize input_values array
	input_values.resize(num_inputs)
	for i in range(num_inputs):
		input_values[i] = false
	
	# Initialize output_values array
	output_values.resize(num_outputs)
	for i in range(num_outputs):
		output_values[i] = false
	
	# Call parent's _ready to set up visuals, collisions, and create external pins
	super._ready()
	await _build_internal_circuit() # Build the internal circuit
	_update_pin_names() # Update pin names from mappings

# Build the internal circuit from the component definition
func _build_internal_circuit():
	# Create invisible container for internal circuit
	internal_circuit_container = Node2D.new()
	internal_circuit_container.visible = false
	add_child(internal_circuit_container)
	
	# Map to track internal gates by their UID
	var internal_gates_by_uid: Dictionary = {}
	
	# Instantiate internal gates
	for gate_data in component_data["gates"]:
		var internal_gate = _create_internal_gate(gate_data)
		if internal_gate:
			internal_gates_by_uid[gate_data["uid"]] = internal_gate
	
	# Wait a frame for pins to be created
	await get_tree().process_frame
	
	# Create internal wires
	for wire_data in component_data["wires"]:
		_create_internal_wire(wire_data, internal_gates_by_uid)
	
	# Set up pin mappings
	_setup_pin_mappings(internal_gates_by_uid)
	
	print("Internal circuit built for component: ", component_data["name"])

# Update external pin names from loaded mappings
func _update_pin_names():
	# Update input pin names
	var input_num = 0
	for child in get_children():
		if child is Pin and child.pin_type == Pin.PinType.INPUT:
			if input_num < input_mappings.size():
				child.pin_name = input_mappings[input_num]["name"]
			input_num += 1
	
	# Update output pin names
	var output_num = 0
	for child in get_children():
		if child is Pin and child.pin_type == Pin.PinType.OUTPUT:
			if output_num < output_mappings.size():
				child.pin_name = output_mappings[output_num]["name"]
			output_num += 1

# Initialize internal circuit state
func _initialize_internal_circuit():
	# Initialize all internal gates' outputs
	for child in internal_circuit_container.get_children():
		if child is Gate: child.write_output_to_pin()
	
	# Propagate initial states through internal wires
	for child in internal_circuit_container.get_children():
		if child is Gate: child.propagate_to_wires()

	_read_internal_outputs()
	write_output_to_pin()
	propagate_to_wires()

# Create an internal gate from definition data
func _create_internal_gate(gate_data: Dictionary) -> Gate:
	# Define gate prefabs for base gates
	var gate_prefabs = {
		"AND": preload("res://scenes/components/logic/and_gate.tscn"),
		"NAND": preload("res://scenes/components/logic/nand_gate.tscn"),
		"OR": preload("res://scenes/components/logic/or_gate.tscn"),
		"NOR": preload("res://scenes/components/logic/nor_gate.tscn"),
		"NOT": preload("res://scenes/components/logic/not_gate.tscn"),
		"XOR": preload("res://scenes/components/logic/xor_gate.tscn"),
		"BUFFER": preload("res://scenes/components/logic/buffer_gate.tscn"),
		"INPUT": preload("res://scenes/components/io/input.tscn"),
		"OUTPUT": preload("res://scenes/components/io/output_display.tscn"),
		"CLOCK": preload("res://scenes/components/io/clock.tscn"),
		"D-FLIPFLOP": preload("res://scenes/components/sequential/d_flipflop.tscn"),
	}
	
	# Check if it's a base gate
	if gate_data["type"] in gate_prefabs:
		var gate = gate_prefabs[gate_data["type"]].instantiate()
		gate.uid = gate_data["uid"]
		gate.position = Vector2(gate_data["x"], gate_data["y"])
		internal_circuit_container.add_child(gate)
		return gate
	else:
		# It might be a custom component! Check if component file exists
		var component_file = "user://components/" + gate_data["type"] + ".json"
		if FileAccess.file_exists(component_file):
			var custom_gate = CustomComponent.new()
			custom_gate.component_definition_name = gate_data["type"]
			custom_gate.uid = gate_data["uid"]
			custom_gate.position = Vector2(gate_data["x"], gate_data["y"])
			internal_circuit_container.add_child(custom_gate)
			return custom_gate
		else:
			print("Error: Unknown gate/component type: ", gate_data["type"])
			return null

# Create an internal wire between two internal gates
func _create_internal_wire(wire_data: Dictionary, gates_by_uid: Dictionary):
	var from_gate = gates_by_uid[wire_data["from_gate"]]
	var to_gate = gates_by_uid[wire_data["to_gate"]]
	
	if not from_gate or not to_gate:
		print("Error: Could not find gates for wire")
		return
	
	var from_pin = from_gate.get_pin_by_index(Pin.PinType.OUTPUT, wire_data["from_pin"])
	var to_pin = to_gate.get_pin_by_index(Pin.PinType.INPUT, wire_data["to_pin"])
	
	if not from_pin or not to_pin:
		print("Error: Could not find pins for wire")
		return
	
	var wire = Wire.new()
	wire.from_pin = from_pin
	wire.to_pin = to_pin
	
	internal_circuit_container.add_child(wire)
	
	from_pin.connected_wires.append(wire)
	to_pin.connected_wires.append(wire)

# Set up mappings between external pins and internal pins
func _setup_pin_mappings(gates_by_uid: Dictionary):
	# Map external inputs to internal pins
	for i in range(component_data["external_inputs"].size()):
		var input_data = component_data["external_inputs"][i]
		var internal_gate = gates_by_uid[input_data["internal_gate_uid"]]
		
		if internal_gate:
			var internal_pin = internal_gate.get_pin_by_index(Pin.PinType.INPUT, input_data["internal_pin_index"])
			
			input_mappings.append({
				"external_pin_index": i,
				"internal_pin": internal_pin,
				"name": input_data["name"]
			})
	
	# Map external outputs to internal pins
	for i in range(component_data["external_outputs"].size()):
		var output_data = component_data["external_outputs"][i]
		var internal_gate = gates_by_uid[output_data["internal_gate_uid"]]
		
		if internal_gate:
			var internal_pin = internal_gate.get_pin_by_index(Pin.PinType.OUTPUT, output_data["internal_pin_index"])
			
			output_mappings.append({
				"external_pin_index": i,
				"internal_pin": internal_pin,
				"name": output_data["name"]
			})

func get_default_input_name(index: int) -> String:
	if index < input_mappings.size():
		return input_mappings[index]["name"]
	return "In_" + str(index)

func get_default_output_name(index: int) -> String:
	if index < output_mappings.size():
		return output_mappings[index]["name"]
	return "Out_" + str(index)

# Override to handle reading inputs and propagating to internal circuit
func read_inputs_from_pins() -> void:
	# First, read external input pins (standard behavior)
	var input_num: int = 0
	for child in get_children():
		if child is Pin and child.pin_type == Pin.PinType.INPUT:
			input_values[input_num] = child.signal_state
			input_num += 1
	
	# Track which internal gates need evaluation
	var gates_to_evaluate: Array[Gate] = []
	
	# Now propagate external inputs to mapped internal pins
	for mapping in input_mappings:
		var external_index = mapping["external_pin_index"]
		var internal_pin = mapping["internal_pin"]
		
		if internal_pin and external_index < input_values.size():
			# Store old state to detect changes
			var old_state = internal_pin.signal_state
			
			# Set the internal pin's signal state from the external input
			internal_pin.signal_state = input_values[external_index]
			internal_pin.update_visuals()
			
			# If the state changed, trigger evaluation of the gate that owns this pin
			if old_state != internal_pin.signal_state:
				var parent_gate = internal_pin.parent_gate
				if parent_gate and parent_gate not in gates_to_evaluate:
					gates_to_evaluate.append(parent_gate)
	
	# Evaluate all affected internal gates (this will propagate through the circuit)
	for gate in gates_to_evaluate:
		gate.evaluate_with_propagation()

# Override evaluate to trigger internal circuit evaluation
func evaluate() -> void:
	_read_internal_outputs()

# Override evaluation cycle for custom components
func evaluate_with_propagation() -> void:
	var old_outputs = output_values.duplicate()
	
	read_inputs_from_pins()
	_read_internal_outputs()
	write_output_to_pin()
	
	var changed = false
	for i in range(output_values.size()):
		if i < old_outputs.size() and output_values[i] != old_outputs[i]:
			changed = true
			break
	
	if changed: propagate_to_wires()

# Read internal output pins and set component's output
func _read_internal_outputs():
	for i in range(output_mappings.size()):
		var mapping = output_mappings[i]
		var internal_pin = mapping["internal_pin"]
		
		if internal_pin and i < output_values.size():
			output_values[i] = internal_pin.signal_state

# Override write output to handle multiple outputs if needed
func write_output_to_pin() -> void:
	var output_num: int = 0
	for child in get_children():
		if child is Pin and child.pin_type == Pin.PinType.OUTPUT:
			# Set external output pin from the mapped internal pin
			if output_num < output_values.size():
				child.signal_state = output_values[output_num]
				child.update_visuals()
			output_num += 1
