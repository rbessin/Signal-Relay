class_name ComponentCreationManager
extends Node

var main: Node2D # Reference to main script

# UI References
var component_dialog_backdrop: Panel
var component_name_input: LineEdit
var inputs_container: VBoxContainer
var outputs_container: VBoxContainer
var create_button: Button
var cancel_button: Button
var create_component_button: Button

# Creation state
var current_component_pin_data: Dictionary = {}

func _init(main_node: Node2D):
	main = main_node
	print("ComponentCreationManager instantiated.")

func setup_ui_references():
	var dialog_base = main.get_node('UICanvas/UIControl/ComponentDialogBackdrop')
	var dialog_content = dialog_base.get_node('ComponentDialog/DialogContent')
	var inspector_tools = main.get_node('UICanvas/UIControl/Inspector/VBoxContainer/ScrollableContent/ContentContainer/ToolsSection/ToolsContent')
	
	component_dialog_backdrop = dialog_base
	component_name_input = dialog_content.get_node('ComponentNameInput')
	inputs_container = dialog_content.get_node('InputsList/InputsContainer')
	outputs_container = dialog_content.get_node('OutputsList/OutputsContainer')
	create_button = dialog_content.get_node('CreateButton')
	cancel_button = dialog_content.get_node('CancelButton')
	create_component_button = inspector_tools.get_node('CreateComponentButton')

func update_create_component_button():
	if main.selection_manager.selected_gates.size() >= 2:
		create_component_button.disabled = false
		create_component_button.modulate = Color(1, 1, 1, 1)
	else:
		create_component_button.disabled = true
		create_component_button.modulate = Color(1, 1, 1, 0.5)

func on_create_component_button_pressed():
	if main.selection_manager.selected_gates.size() < 2:
		print("Need at least 2 gates selected to create a component")
		return
	
	var pin_data = detect_external_pins(main.selection_manager.selected_gates)
	show_component_dialog(pin_data)

func detect_external_pins(selected_gate_list: Array[Gate]) -> Dictionary:
	var external_inputs = []
	var external_outputs = []

	for gate in selected_gate_list:
		# Collect input pins from gate's children
		for child in gate.get_children():
			if child is Pin and child.pin_type == Pin.PinType.INPUT:
				var is_external = true
				for wire in main.wire_manager.wires:
					if wire.to_pin == child:
						if wire.from_pin.parent_gate in selected_gate_list:
							is_external = false
							break
				if is_external:
					external_inputs.append({
						"gate": gate,
						"pin": child,
						"pin_name": child.pin_name
					})
		
		# Collect output pins from gate's children
		for child in gate.get_children():
			if child is Pin and child.pin_type == Pin.PinType.OUTPUT:
				var has_wire_to_outside = false
				var has_any_wire = false
				
				for wire in main.wire_manager.wires:
					if wire.from_pin == child:
						has_any_wire = true
						if not (wire.to_pin.parent_gate in selected_gate_list):
							has_wire_to_outside = true
							break
				
				# External if: unconnected OR connected to outside
				if not has_any_wire or has_wire_to_outside:
					external_outputs.append({
						"gate": gate,
						"pin": child,
						"pin_name": child.pin_name
					})

	return {
		"inputs": external_inputs,
		"outputs": external_outputs
	}

func show_component_dialog(pin_data: Dictionary):
	current_component_pin_data = pin_data
	component_name_input.text = ""
	
	for child in inputs_container.get_children():
		child.queue_free()
	for child in outputs_container.get_children():
		child.queue_free()
	
	for input_data in pin_data.inputs:
		var label = Label.new()
		label.text = "Input: " + input_data.pin_name
		inputs_container.add_child(label)
	
	for output_data in pin_data.outputs:
		var label = Label.new()
		label.text = "Output: " + output_data.pin_name
		outputs_container.add_child(label)
	
	component_dialog_backdrop.visible = true

func on_cancel_button_pressed():
	component_dialog_backdrop.visible = false
	current_component_pin_data = {}

func on_create_button_pressed():
	var component_name = component_name_input.text.strip_edges()
	
	if component_name == "":
		print("Component name cannot be empty")
		return
	
	print("Creating component: ", component_name)
	
	# Calculate center position
	var center_pos = Vector2.ZERO
	for gate in main.selection_manager.selected_gates:
		center_pos += gate.global_position
	center_pos /= main.selection_manager.selected_gates.size()
	
	# Transform pin data to match ComponentSerializer's expected format
	var pin_mappings = {
		"inputs": [],
		"outputs": []
	}
	
	for input_data in current_component_pin_data["inputs"]:
		var gate = input_data["gate"]
		var pin = input_data["pin"]
		var pin_index = gate.get_pin_index(pin)
		
		pin_mappings["inputs"].append({
			"final_name": input_data["pin_name"],
			"gate": gate,
			"pin_index": pin_index
		})
	
	for output_data in current_component_pin_data["outputs"]:
		var gate = output_data["gate"]
		var pin = output_data["pin"]
		var pin_index = gate.get_pin_index(pin)
		
		pin_mappings["outputs"].append({
			"final_name": output_data["pin_name"],
			"gate": gate,
			"pin_index": pin_index
		})
	
	# Save component with correct parameter order
	ComponentSerializer.save_component(
		component_name,
		main.selection_manager.selected_gates,
		main.wire_manager.wires,
		pin_mappings
	)
	
	print("Component saved successfully")
	
	# Now delete the selected gates
	for gate in main.selection_manager.selected_gates.duplicate():
		main.gate_manager.delete_gate(gate)
	main.selection_manager.selected_gates.clear()
	
	# Create an instance of the new component
	var new_component = main.gate_manager.create_custom_component(component_name, center_pos)
	print("Component instance created: ", new_component)
	
	# Refresh the UI
	main._populate_components_section()
	
	component_dialog_backdrop.visible = false
	current_component_pin_data = {}