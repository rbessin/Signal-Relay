class_name CircuitSerializer

# Saves circuit to JSON file [Arrays -> JSON]
static func save_to_json(gates_array: Array, wires_array: Array, circuit_name: String) -> bool:
	# Define dictionary structure
	var saving_dictionary: Dictionary = {
		"circuit_name": circuit_name,
		"gates": [],
		"wires": []
	}

	# Add gate instances to dictionary
	for gate in gates_array:
		var gate_info: Dictionary = {}
		gate_info["uid"] = gate.uid
		gate_info["type"] = gate.type
		gate_info["x"] = gate.position.x
		gate_info["y"] = gate.position.y
		saving_dictionary["gates"].append(gate_info)
	
	# Add wire instances to dictionary
	for wire in wires_array:
		var wire_info: Dictionary = {}
		wire_info["from_gate"] = wire.from_pin.parent_gate.uid
		wire_info["from_pin"] = wire.from_pin.parent_gate.get_pin_index(wire.from_pin)
		wire_info["to_gate"] = wire.to_pin.parent_gate.uid
		wire_info["to_pin"] = wire.to_pin.parent_gate.get_pin_index(wire.to_pin)
		saving_dictionary["wires"].append(wire_info)
	
	# Convert dictionary to JSON string
	var json_string: String = JSON.stringify(saving_dictionary, "\t")

	# Handle folder existance
	var dir = DirAccess.open("user://")
	if not dir:
		print("ERROR: Could not open user directory.")
		return false
	
	# Handle subfolder existance
	if not dir.dir_exists("circuits"):
		var error = dir.make_dir("circuits")
		if error != OK:
			print("ERROR: Could not create circuits directory.")
			return false

	# Safely convert name and define filepath
	var safe_name: String = circuit_name.replace("/", "_")
	var filepath = "user://circuits/" + safe_name + ".json"

	# Open JSON file and handle opening errors
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if not file:
		print("ERROR: Could not open file for writing: ", filepath)
		return false
	
	# Store JSON string in JSON file
	file.store_string(json_string)
	
	return true

# Loads circuit from JSON file [JSON -> Dictionary]
static func load_from_json(circuit_name: String):
	# Safely convert name and define filepath
	var safe_name: String = circuit_name.replace("/", "_")
	var filepath = "user://circuits/" + safe_name + ".json"
	
	# Open JSON file and handle opening errors
	var file = FileAccess.open(filepath, FileAccess.READ)
	if not file:
		print("ERROR: Could not open file for reading: ", filepath)
		return null
	
	# Read JSON file -> string -> dictionary
	var json_string = file.get_as_text()
	var json_dict = JSON.parse_string(json_string)

	# Handle wrong filepath
	if not json_dict:
		print("ERROR: Could not read file: ", filepath)
		return null
	
	# Handle missing information (name, gates, wires)
	if not json_dict.has("circuit_name"):
		print("ERROR: File does not include a circuit name.")
		return null
	if not json_dict.has("gates"):
		print("ERROR: File does not include a gates array.")
		return null
	if not json_dict.has("wires"):
		print("ERROR: File does not include a wires array.")
		return null
	
	return json_dict
