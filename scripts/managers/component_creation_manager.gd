class_name ComponentCreationManager
extends Node

var main: Node2D # Reference to main script
var selection_manager: SelectionManager # Manager references
var wire_manager: WireManager
var gate_manager: GateManager
var component_library_manager: ComponentLibraryManager

# UI references
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
	var _primary_tools = main.get_node('UICanvas/UIControl/Inspector/VBoxContainer/ScrollableContent/ContentContainer/ToolsSection/PrimaryToolsContent')
	var secondary_tools = main.get_node('UICanvas/UIControl/Inspector/VBoxContainer/ScrollableContent/ContentContainer/ToolsSection/SecondaryToolsContent')
	
	component_dialog_backdrop = dialog_base
	component_name_input = dialog_content.get_node('ComponentNameInput')
	inputs_container = dialog_content.get_node('InputsList/InputsContainer')
	outputs_container = dialog_content.get_node('OutputsList/OutputsContainer')
	create_button = dialog_content.get_node('CreateButton')
	cancel_button = dialog_content.get_node('CancelButton')
	create_component_button = secondary_tools.get_node('CreateComponentButton')

func update_create_component_button():
	if selection_manager.selected_gates.size() >= 2: # Show button if at least two gates are selected
		create_component_button.visible = true
	else: # Hide button if less than two gates (0 | 1) are selected
		create_component_button.visible = false

func on_create_component_button_pressed():
	if selection_manager.selected_gates.size() < 2: # Stop component creation if less than two gates are selected
		print("Need at least 2 gates selected to create a component")
		return
	
	current_component_pin_data = detect_external_pins(selection_manager.selected_gates) # Find component pins
	show_component_dialog() # Open component dialog

func detect_external_pins(selected_gate_list: Array[Gate]) -> Dictionary:
	var external_inputs = [] # Component pin arrays
	var external_outputs = []

	for gate in selected_gate_list:
		# Find input pins from gate's children
		for child in gate.get_children():
			if child is Pin and child.pin_type == Pin.PinType.INPUT:
				var is_external = true
				for wire in wire_manager.wires:
					if wire.to_pin == child:
						if wire.from_pin.parent_gate in selected_gate_list: # Pin is external if wire comes from outside gate
							is_external = false
							break
				if is_external:
					external_inputs.append({ # Add input pin to component
						"gate": gate,
						"pin": child,
						"pin_name": child.pin_name
					})
		
		# Collect output pins from gate's children
		for child in gate.get_children():
			if child is Pin and child.pin_type == Pin.PinType.OUTPUT:
				var has_wire_to_outside = false
				var has_any_wire = false
				
				for wire in wire_manager.wires:
					if wire.from_pin == child:
						has_any_wire = true # If there is a wire
						if not (wire.to_pin.parent_gate in selected_gate_list):
							has_wire_to_outside = true # If a wire goes outside the component
							break
				
				# Pin is external if it is unconnected or connected to outside gate
				if not has_any_wire or has_wire_to_outside:
					external_outputs.append({ # Add output pin to component
						"gate": gate,
						"pin": child,
						"pin_name": child.pin_name
					})

	return {"inputs": external_inputs, "outputs": external_outputs} # Return external inputs and outputs for component

func show_component_dialog():
	component_name_input.text = ""
	
	for child in inputs_container.get_children(): # Remove previous input and output data
		child.queue_free()
	for child in outputs_container.get_children():
		child.queue_free()
	
	for input_data in current_component_pin_data.inputs: # Add current component input data
		var label = Label.new()
		label.text = "Input: " + input_data.pin_name
		inputs_container.add_child(label)
	
	for output_data in current_component_pin_data.outputs: # Add current component output data
		var label = Label.new()
		label.text = "Output: " + output_data.pin_name
		outputs_container.add_child(label)
	
	component_dialog_backdrop.visible = true # Show component dialog to user

func on_cancel_button_pressed():
	component_dialog_backdrop.visible = false # Hide component dialog from user
	current_component_pin_data = {} # Reset pin data tracker

func on_create_button_pressed():
	var component_name = component_name_input.text.strip_edges() # Retrieve name without whitespace
	
	if component_name == "": return # Stop component creation if component doesn't have a name
	
	# Calculate center position of component
	var center_pos = Vector2.ZERO
	for gate in selection_manager.selected_gates:
		center_pos += gate.global_position
	center_pos /= selection_manager.selected_gates.size()
	
	# Transform pin data to match ComponentSerializer's expected format
	var pin_mappings = {"inputs": [], "outputs": []}
	
	for input_data in current_component_pin_data["inputs"]: # Tranform input pin data
		var gate = input_data["gate"]
		var pin = input_data["pin"]
		var pin_index = gate.get_pin_index(pin)
		
		pin_mappings["inputs"].append({
			"final_name": input_data["pin_name"],
			"gate": gate,
			"pin_index": pin_index
		})

	for output_data in current_component_pin_data["outputs"]: # Tranform output pin data
		var gate = output_data["gate"]
		var pin = output_data["pin"]
		var pin_index = gate.get_pin_index(pin)
		
		pin_mappings["outputs"].append({
			"final_name": output_data["pin_name"],
			"gate": gate,
			"pin_index": pin_index
		})
	
	ComponentSerializer.save_component( # Save component using helper functions
		component_name,
		selection_manager.selected_gates,
		wire_manager.wires,
		pin_mappings
	)
	
	for gate in selection_manager.selected_gates.duplicate(): # Delete selected gates
		gate_manager.delete_gate(gate)
	selection_manager.selected_gates.clear()
	
	# Create an instance of the new component
	gate_manager.create_custom_component(component_name, center_pos)
	
	# Refresh the UI
	component_library_manager.populate_components_section()
	component_dialog_backdrop.visible = false
	current_component_pin_data = {}
