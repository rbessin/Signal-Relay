class_name SelectionManager
extends Node

var main: Node2D # Reference to main script
var component_creation_manager: ComponentCreationManager # Reference to component creation manager

# Dragging
var is_dragging: bool = false
var drag_offsets: Dictionary = {}

# Selections
var selected_gates: Array[Gate] = []
var selected_wire_instance: Wire = null

func _init(main_node: Node2D):
	main = main_node
	print("SelectionManager instantiated.")

func drag():
	if is_dragging and selected_gates.size() > 0: # Check if dragging and existance of selected gates
		var mouse_pos = main.get_global_mouse_position()
		for gate in selected_gates:
			if gate in drag_offsets: gate.global_position = mouse_pos + drag_offsets[gate] # Drag each gate by its offset from the mouse

func select_gate_instance(gate_instance: Gate):
	if main.current_mode == main.Mode.SIMULATE: # Toggle inputs if in SIMULATE
		if gate_instance.type == "INPUT": gate_instance.toggle()
	elif main.current_mode == main.Mode.SELECT: # Select gates if in SELECT
		if Input.is_key_pressed(KEY_SHIFT): # Allows selection for multiple gates
			if gate_instance in selected_gates: # Remove gate from selection
				gate_instance.set_selected(false)
				selected_gates.erase(gate_instance)
			else: # Add gate to selection
				gate_instance.set_selected(true)
				selected_gates.append(gate_instance)
		else: # Limits selection to one gate
			clear_selection()
			gate_instance.set_selected(true)
			selected_gates.append(gate_instance)
		
		update_create_component_button() # Update component creation button

		if selected_gates.size() > 0: # Reset dragging variables and start dragging
			is_dragging = true
			drag_offsets.clear()
			var mouse_pos = main.get_global_mouse_position()
			for gate in selected_gates: drag_offsets[gate] = gate.global_position - mouse_pos

func select_wire_instance(wire_instance: Wire):
	if main.current_mode == main.Mode.SELECT: # Clear wire selection and add new wire
		clear_selection()
		selected_wire_instance = wire_instance
		wire_instance.set_selected(true)

func clear_selection(): # Clear selection of gates and wire
	for gate in selected_gates:
		gate.set_selected(false)
	selected_gates.clear()
	update_create_component_button()

	if selected_wire_instance != null:
		selected_wire_instance.set_selected(false)
		selected_wire_instance = null

func update_create_component_button(): # Disable button if there are less than two selected gates
	component_creation_manager.update_create_component_button()

func stop_dragging(): is_dragging = false # Update dragging variables
