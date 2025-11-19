class_name ComponentSerializer

static func save_component(component_name: String, selected_gates: Array[Gate], all_wires: Array[Wire], pin_mappings: Dictionary) -> void:
	var component_data = {
		"name": component_name,
		"gates": [],
		"wires": [],
		"external_inputs": [],
		"external_outputs": []
	}
	
	# Build a mapping of gate instances to their array indices for wire references
	var gate_uid_map = {}
	for gate in selected_gates: gate_uid_map[gate.uid] = gate
	
	# Save gates
	for gate in selected_gates:
		component_data["gates"].append({
			"type": gate.type,
			"uid": gate.uid,
			"x": gate.position.x,
			"y": gate.position.y,
			"color": gate.color.to_html()
		})
	
	# Save wires (only those connecting gates within selection)
	for wire in all_wires:
		if wire.from_pin == null or wire.to_pin == null: continue
		
		var from_gate = wire.from_pin.parent_gate
		var to_gate = wire.to_pin.parent_gate
		
		# Only save wires where both ends are in the selection
		if from_gate in selected_gates and to_gate in selected_gates:
			component_data["wires"].append({
				"from_gate": from_gate.uid,
				"from_pin": from_gate.get_pin_index(wire.from_pin),
				"to_gate": to_gate.uid,
				"to_pin": to_gate.get_pin_index(wire.to_pin)
			})
	
	# Save external pin mappings
	for input in pin_mappings["inputs"]:
		component_data["external_inputs"].append({
			"name": input["final_name"],
			"internal_gate_uid": input["gate"].uid,
			"internal_pin_index": input["pin_index"]
		})
	
	for output in pin_mappings["outputs"]:
		component_data["external_outputs"].append({
			"name": output["final_name"],
			"internal_gate_uid": output["gate"].uid,
			"internal_pin_index": output["pin_index"]
		})
	
	# Save to file
	var dir_path = "user://components/"
	DirAccess.make_dir_recursive_absolute(dir_path)
	
	var file_path = dir_path + component_name + ".json"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(component_data, "\t"))
		file.close()
		print("Component saved to: ", file_path)
	else:
		print("Error saving component!")

static func load_component(component_name: String) -> Dictionary:
	var file_path = "user://components/" + component_name + ".json"
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		print("Error: Could not open component file: ", file_path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Error parsing component JSON")
		return {}
	
	return json.data
