extends Node2D

# General configurations (camera)
@onready var camera: Camera2D = get_node("Camera2D")
@onready var pan_speed: int = 300
@onready var zoom_speed: float = 1
@onready var max_zoom: float = 3.0
@onready var min_zoom: float = 0.5

# Cursor configurations (mode, label)
enum Mode { SELECT, PLACE, WIRE, SIMULATE }
var current_mode: Mode = Mode.SELECT
@onready var mode_label: Label = get_node('UICanvas/UIControl/Inspector/VBoxContainer/ScrollableContent/ContentContainer/ToolsSection/ToolsContent/Current_Mode')

# PLACE mode
var gate_prefabs: Dictionary = {
	"AND": preload("res://scenes/gates/and_gate.tscn"),
	"NAND": preload("res://scenes/gates/nand_gate.tscn"),
	"OR": preload("res://scenes/gates/or_gate.tscn"),
	"NOR": preload("res://scenes/gates/nor_gate.tscn"),
	"NOT": preload("res://scenes/gates/not_gate.tscn"),
	"XOR": preload("res://scenes/gates/xor_gate.tscn"),
	"INPUT": preload("res://scenes/complex/input.tscn"),
	"OUTPUT": preload("res://scenes/complex/output_display.tscn"),
	"CLOCK": preload("res://scenes/complex/clock.tscn"),
	"D_FLIPFLOP": preload("res://scenes/complex/d_flipflop.tscn"),
}
var gate_to_place: PackedScene = null # Which gate type to place
var gate_type_to_place: String = ""
var current_uid: int = 0

# SELECT mode
var is_dragging: bool = false
var drag_offset: Vector2
var selected_gates: Array[Gate] = []
var drag_offsets: Dictionary = {}
var selected_wire_instance: Wire = null

# WIRE mode
var is_creating_wire: bool = false
var wire_start_pin: Pin = null
var wire_preview: Wire = null

## SIMULATE mode
### Nothing to show for now.

## Loading & Saving
var gates: Array[Gate] = []
var wires: Array[Wire] = []
@onready var file_name_input: LineEdit = get_node('UICanvas/UIControl/Inspector/VBoxContainer/ScrollableContent/ContentContainer/SimulationSection2/SimulationContent/FileNameInput')

# Component Creation
@onready var component_dialog_backdrop: Panel = get_node('UICanvas/UIControl/ComponentDialogBackdrop')
@onready var component_name_input: LineEdit = get_node('UICanvas/UIControl/ComponentDialogBackdrop/ComponentDialog/DialogContent/ComponentNameInput')
@onready var inputs_container: VBoxContainer = get_node('UICanvas/UIControl/ComponentDialogBackdrop/ComponentDialog/DialogContent/InputsList/InputsContainer')
@onready var outputs_container: VBoxContainer = get_node('UICanvas/UIControl/ComponentDialogBackdrop/ComponentDialog/DialogContent/OutputsList/OutputsContainer')
@onready var create_button: Button = get_node('UICanvas/UIControl/ComponentDialogBackdrop/ComponentDialog/DialogContent/CreateButton')
@onready var cancel_button: Button = get_node('UICanvas/UIControl/ComponentDialogBackdrop/ComponentDialog/DialogContent/CancelButton')
@onready var create_component_button: Button = get_node('UICanvas/UIControl/Inspector/VBoxContainer/ScrollableContent/ContentContainer/ToolsSection/ToolsContent/CreateComponentButton')
@onready var components_content: VBoxContainer = get_node('UICanvas/UIControl/Inspector/VBoxContainer/ScrollableContent/ContentContainer/ComponentsSection/ComponentsContent')
@onready var browse_components_button: Button = get_node('UICanvas/UIControl/Inspector/VBoxContainer/ScrollableContent/ContentContainer/ComponentsSection/ComponentsContent/BrowseComponentsButton')
var current_component_pin_data: Dictionary = {}

# Components Accessing
@onready var browse_backdrop: Panel = get_node('UICanvas/UIControl/BrowseComponentsBackdrop')
@onready var browse_components_container: VBoxContainer = get_node('UICanvas/UIControl/BrowseComponentsBackdrop/BrowseDialog/DialogContent/ComponentsList/ComponentsContainer')
@onready var browse_close_button: Button = get_node('UICanvas/UIControl/BrowseComponentsBackdrop/BrowseDialog/DialogContent/CloseButton')
@onready var rename_backdrop: Panel = get_node('UICanvas/UIControl/RenameComponentBackdrop')
@onready var rename_input: LineEdit = get_node('UICanvas/UIControl/RenameComponentBackdrop/RenameDialog/VBoxContainer/RenameInput')
@onready var rename_confirm_button: Button = get_node('UICanvas/UIControl/RenameComponentBackdrop/RenameDialog/VBoxContainer/HBoxContainer/RenameConfirmButton')
@onready var rename_cancel_button: Button = get_node('UICanvas/UIControl/RenameComponentBackdrop/RenameDialog/VBoxContainer/HBoxContainer/RenameCancelButton')
var component_being_renamed: String = ""

# Default functions which run on instantiation and every frame
func _ready():
	_populate_components_section()
func _process(delta):
	_drag()
	_position_wire_preview()
	_move_camera(delta)

# SELECT helpers
func _drag(): # Drag all selected gates together
	if is_dragging and selected_gates.size() > 0:
		var mouse_pos = get_global_mouse_position()
		for gate in selected_gates:
			if gate in drag_offsets:
				gate.global_position = mouse_pos + drag_offsets[gate]

func _select_gate_instance(gate_instance: Gate): # Select gate instance
	if current_mode == Mode.SIMULATE:
		if gate_instance.type == "INPUT": gate_instance.toggle()
		return
	elif current_mode == Mode.SELECT:
		# Check if Shift is held for multi-select
		if Input.is_key_pressed(KEY_SHIFT):
			# Toggle this gate in the selection
			if gate_instance in selected_gates:
				# Deselect it
				gate_instance.set_selected(false)
				selected_gates.erase(gate_instance)
			else:
				# Add to selection
				gate_instance.set_selected(true)
				selected_gates.append(gate_instance)
		else:
			# Single select - clear previous selections
			_clear_selection()
			gate_instance.set_selected(true)
			selected_gates.append(gate_instance)
		_update_create_component_button()
		
		# Start dragging - store offset for each selected gate
		if selected_gates.size() > 0:
			is_dragging = true
			drag_offsets.clear()
			var mouse_pos = get_global_mouse_position()
			for gate in selected_gates:
				drag_offsets[gate] = gate.global_position - mouse_pos

func _select_wire_instance(wire_instance: Wire):
	if current_mode == Mode.SELECT:
		_clear_selection()
		
		selected_wire_instance = wire_instance
		wire_instance.set_selected(true)

func _delete_gate_instance(gate: Gate): # Delete gate instance
	for child in gate.get_children():
		if child is Pin:
			for wire in child.connected_wires.duplicate():
				_delete_wire(wire)
	gates.erase(gate)
	gate.queue_free()

func _clear_selection():
	for gate in selected_gates:
		gate.set_selected(false)
	selected_gates.clear()
	_update_create_component_button()
	
	if selected_wire_instance != null:
		selected_wire_instance.set_selected(false)
		selected_wire_instance = null

# PLACE helpers
func instantiate_gate(): # Create gate instance
	if gate_type_to_place == "": return
	
	# Check if it's a custom component
	var component_file = "user://components/" + gate_type_to_place + ".json"
	if FileAccess.file_exists(component_file):
		# Create custom component
		var new_component = CustomComponent.new()
		new_component.component_definition_name = gate_type_to_place
		new_component.global_position = get_global_mouse_position()
		add_child(new_component)
		new_component.gate_clicked.connect(_select_gate_instance)
		call_deferred("_connect_gate_pins", new_component)
		gates.append(new_component)
	else:
		# Create regular gate
		_create_gate(gate_type_to_place, get_global_mouse_position())

func _create_gate(gate_type: String, pos: Vector2, uid: int = -1) -> Gate:
	if gate_type not in gate_prefabs: return null
	
	var new_gate = gate_prefabs[gate_type].instantiate()
	add_child(new_gate)
	
	if uid == -1: new_gate.uid = _generate_uid()
	else:
		new_gate.uid = uid
		current_uid = max(current_uid, uid)  # Keep UID counter in sync
	
	new_gate.name = new_gate.type + '_' + str(new_gate.uid)
	new_gate.global_position = pos
	new_gate.gate_clicked.connect(_select_gate_instance)
	call_deferred("_connect_gate_pins", new_gate)
	gates.append(new_gate)
	return new_gate

func _connect_gate_pins(gate: Gate):
	for child in gate.get_children():
		if child is Pin:
			child.pin_clicked.connect(_on_pin_clicked)

func _on_pin_clicked(pin_instance: Pin): # Handle pin clicks
	if current_mode == Mode.WIRE:
		if not is_creating_wire:
			if pin_instance.pin_type == Pin.PinType.OUTPUT:
				_start_wire_creation(pin_instance)
		else:
			if pin_instance.pin_type == Pin.PinType.INPUT:
				_complete_wire_creation(pin_instance)
			else: _cancel_wire_creation()

func _generate_uid(): # Create unique ID
	current_uid += 1
	return current_uid

# WIRE helpers
func _start_wire_creation(start_pin: Pin):
	is_creating_wire = true
	wire_start_pin = start_pin
	wire_preview = Wire.new()
	wire_preview.from_pin = wire_start_pin
	wire_preview.is_preview = true
	add_child(wire_preview)

func _complete_wire_creation(end_pin: Pin):
	if _is_duplicate_wire(wire_start_pin, end_pin):
		_cancel_wire_creation()
		return
	if end_pin.parent_gate == wire_start_pin.parent_gate: 
		_cancel_wire_creation()
		return
	if end_pin.connected_wires.size() > 0:
		_cancel_wire_creation()
		return

	wire_preview.to_pin = end_pin
	wire_preview.is_preview = false

	wire_preview.wire_clicked.connect(_select_wire_instance)
	wire_start_pin.connected_wires.append(wire_preview)
	end_pin.connected_wires.append(wire_preview)

	wires.append(wire_preview)

	is_creating_wire = false
	wire_start_pin = null
	wire_preview = null

func _cancel_wire_creation():
	if wire_preview != null:
		wire_preview.queue_free()
	is_creating_wire = false
	wire_start_pin = null
	wire_preview = null

func _delete_wire_instance():
	_delete_wire(selected_wire_instance)
	selected_wire_instance = null

func _delete_wire(wire: Wire):
	if wire.from_pin != null:
		wire.from_pin.connected_wires.erase(wire)
	if wire.to_pin != null:
		wire.to_pin.connected_wires.erase(wire)
	wires.erase(wire)
	wire.queue_free()

func _position_wire_preview():
	if is_creating_wire and wire_preview != null:
		wire_preview.preview_end_position = get_global_mouse_position()

func _is_duplicate_wire(from_pin: Pin, to_pin: Pin) -> bool:
	for wire in from_pin.connected_wires:
		if wire.from_pin == from_pin and wire.to_pin == to_pin:
			return true
	return false

## SIMULATE helpers

# Handle events
func _unhandled_input(event): # Handle inputs
	if event.is_action_pressed("Click"): _handle_click()
	elif event.is_action_released("Click"): _handle_click_release()
	elif event.is_action_pressed("Delete"): _handle_delete()
	elif event.is_action_pressed("Stop"): _handle_stop()
	elif event.is_action_pressed("Save_Circuit"): _handle_save()
	elif event.is_action_pressed("Load_Circuit"): _handle_load()
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_X: get_tree().quit()

func _handle_click(): # Handle click
	if current_mode == Mode.PLACE: instantiate_gate()
	elif current_mode == Mode.SELECT:
		if not Input.is_key_pressed(KEY_SHIFT): _clear_selection()
func _handle_click_release(): # Handle click release
	is_dragging = false
func _handle_delete(): # Handle delete
	if current_mode == Mode.SELECT: 
		for gate in selected_gates.duplicate(): _delete_gate_instance(gate)
		selected_gates.clear()
		if selected_wire_instance != null: _delete_wire_instance()
func _handle_stop(): # Handle stop
	if current_mode == Mode.WIRE: _cancel_wire_creation()
	elif current_mode == Mode.SELECT: _clear_selection()

# Enter mode
func _enter_select():
	pass
func _enter_place(gate_name: String = ""):
	if gate_name != "":
		if gate_name in gate_prefabs: # Base gate
			gate_to_place = gate_prefabs[gate_name]
			gate_type_to_place = gate_name
		else: # Assume it's a custom component
			gate_to_place = null  # We'll handle this differently
			gate_type_to_place = gate_name
func _enter_wire():
	pass
func _enter_simulate():
	await get_tree().process_frame
	for gate in gates: # Initialize all gates and connected wires
		gate.write_output_to_pin()
		gate.propagate_to_wires()
	for gate in gates:
		if gate is CustomComponent:
			gate._initialize_internal_circuit()
	for gate in gates:
		if gate.type == "CLOCK": gate.start_clock()

# Exit mode
func _exit_select():
	_clear_selection()
	is_dragging = false
func _exit_place():
	gate_to_place = null
func _exit_wire():
	if wire_preview != null:
		wire_preview.queue_free()
		wire_preview = null
	is_creating_wire = false
	wire_start_pin = null
func _exit_simulate():
	for gate in gates:
		if gate.type == "CLOCK": gate.stop_clock()

# Set mode by exiting old mode and entering new mode
func _set_mode(new_mode: Mode, gate_name: String = ''):
	match current_mode:
		Mode.SELECT: _exit_select()
		Mode.PLACE: _exit_place()
		Mode.WIRE: _exit_wire()
		Mode.SIMULATE: _exit_simulate()
	
	current_mode = new_mode
	mode_label.text = str(current_mode)

	match new_mode:
		Mode.SELECT: _enter_select()
		Mode.PLACE: _enter_place(gate_name)
		Mode.WIRE: _enter_wire()
		Mode.SIMULATE: _enter_simulate()

# Select mode
func select_select(): _set_mode(Mode.SELECT)
func select_place(gate_name: String): _set_mode(Mode.PLACE, gate_name)
func select_wire(): _set_mode(Mode.WIRE)
func select_simulate(): _set_mode(Mode.SIMULATE)

# UX helpers
func _move_camera(delta):
	if Input.is_key_pressed(KEY_Q):
		if camera.zoom <= Vector2(max_zoom, max_zoom): camera.zoom += Vector2(zoom_speed, zoom_speed) * delta
	if Input.is_key_pressed(KEY_E):
		if camera.zoom >= Vector2(min_zoom, min_zoom): camera.zoom -= Vector2(zoom_speed, zoom_speed) * delta

	if Input.is_key_pressed(KEY_S):
		camera.position.y += pan_speed * delta
	if Input.is_key_pressed(KEY_W):
		camera.position.y -= pan_speed * delta
	if Input.is_key_pressed(KEY_D):
		camera.position.x += pan_speed * delta
	if Input.is_key_pressed(KEY_A):
		camera.position.x -= pan_speed * delta

# Loading & Saving helpers
func _handle_save(): # Collect gates and wires
	_on_save_button_pressed()
func _handle_load(): # Load circuit
	_on_load_button_pressed()

func _load_circuit(circuit_name):
	_empty_circuit()

	var circuit_dict = CircuitSerializer.load_from_json(circuit_name)
	if circuit_dict == null: return
	var gates_by_uid: Dictionary = {}

	for gate in circuit_dict["gates"]:
		var new_gate = _create_gate(gate["type"], Vector2(gate["x"], gate["y"]), gate["uid"])
		if new_gate != null: gates_by_uid[gate["uid"]] = new_gate
	
	await get_tree().process_frame
	
	for wire in circuit_dict["wires"]:
		var source_gate = gates_by_uid[wire["from_gate"]]
		var destination_gate = gates_by_uid[wire["to_gate"]]
		print("Loading wire from ", source_gate.type, " to ", destination_gate.type)
		var source_pin = source_gate.get_pin_by_index(Pin.PinType.OUTPUT, wire["from_pin"])
		var destination_pin = destination_gate.get_pin_by_index(Pin.PinType.INPUT, wire["to_pin"])
		print("  source_pin:", source_pin, " dest_pin:", destination_pin)

		if source_pin == null or destination_pin == null:
			print("  ERROR: Pin lookup failed!")
			continue

		var new_wire = Wire.new()
		new_wire.from_pin = source_pin
		new_wire.to_pin = destination_pin
		add_child(new_wire)
		wires.append(new_wire)

		source_pin.connected_wires.append(new_wire)
		destination_pin.connected_wires.append(new_wire)

func _empty_circuit():
	for child in gates.duplicate(): _delete_gate_instance(child)

func _on_save_button_pressed():
	var circuit_name = file_name_input.text
	if circuit_name == "": circuit_name = "my_circuit"  # Default if empty
	CircuitSerializer.save_to_json(gates, wires, circuit_name)
	print("Circuit saved as: " + circuit_name)

func _on_load_button_pressed():
	var circuit_name = file_name_input.text
	if circuit_name == "": circuit_name = "my_circuit"  # Default if empty
	_load_circuit(circuit_name)
	print("Circuit loaded: " + circuit_name)

# Component Creation Functions
func _on_create_component_button_pressed():
	if selected_gates.size() < 2: return
	var pin_data = _detect_external_pins(selected_gates)
	_show_component_dialog(pin_data)

func _update_create_component_button():
	if create_component_button:
		create_component_button.disabled = selected_gates.size() < 2

func _detect_external_pins(selected_gate_list: Array[Gate]) -> Dictionary:
	var external_inputs: Array = []  # Array of {gate: Gate, pin_index: int, pin: Pin}
	var external_outputs: Array = []  # Array of {gate: Gate, pin_index: int, pin: Pin}

	for gate in selected_gate_list:
		var input_index = 0
		for child in gate.get_children():
			if child is Pin and child.pin_type == Pin.PinType.INPUT:
				var is_external = false
				
				if child.connected_wires.size() == 0: is_external = true
				else:
					for wire in child.connected_wires:
						if wire.from_pin and wire.from_pin.parent_gate not in selected_gate_list:
							is_external = true
							break
				
				if is_external:
					external_inputs.append({
						"gate": gate,
						"pin_index": input_index,
						"pin": child,
						"initial_name": gate.type + "_In" + str(input_index)
					})
				input_index += 1

		var output_index = 0
		for child in gate.get_children():
			if child is Pin and child.pin_type == Pin.PinType.OUTPUT:
				var is_external = false

				if child.connected_wires.size() == 0: is_external = true
				else:
					for wire in child.connected_wires:
						if wire.to_pin and wire.to_pin.parent_gate not in selected_gate_list:
							is_external = true
							break
				
				if is_external:
					external_outputs.append({
						"gate": gate,
						"pin_index": output_index,
						"pin": child,
						"initial_name": gate.type + "_Out" + str(output_index)
					})
				output_index += 1

	return {
		"inputs": external_inputs,
		"outputs": external_outputs
	}

func _show_component_dialog(pin_data: Dictionary):
	current_component_pin_data = pin_data

	for child in inputs_container.get_children():
		child.queue_free()
	for child in outputs_container.get_children():
		child.queue_free()
	
	component_name_input.text = "MyComponent"

	for input in pin_data["inputs"]:
		var pin_entry = HBoxContainer.new()

		var label = Label.new()
		label.text = input["initial_name"] + ":"
		label.custom_minimum_size = Vector2(150, 0)
		pin_entry.add_child(label)

		var name_edit = LineEdit.new()
		name_edit.text = input["initial_name"]
		name_edit.custom_minimum_size = Vector2(150, 0)
		pin_entry.add_child(name_edit)

		inputs_container.add_child(pin_entry)
		input["name_edit"] = name_edit

	for output in pin_data["outputs"]:
		var pin_entry = HBoxContainer.new()

		var label = Label.new()
		label.text = output["initial_name"] + ":"
		label.custom_minimum_size = Vector2(150, 0)
		pin_entry.add_child(label)

		var name_edit = LineEdit.new()
		name_edit.text = output["initial_name"]
		name_edit.custom_minimum_size = Vector2(150, 0)
		pin_entry.add_child(name_edit)

		outputs_container.add_child(pin_entry)
		output["name_edit"] = name_edit

	component_dialog_backdrop.visible = true

func _on_cancel_button_pressed():
	component_dialog_backdrop.visible = false
	current_component_pin_data = {}

func _on_create_button_pressed():
	var component_name = component_name_input.text.strip_edges()
	
	if component_name == "":
		print("Error: Component name cannot be empty")
		return
	
	# Collect renamed pins from the LineEdits
	for input in current_component_pin_data["inputs"]:
		input["final_name"] = input["name_edit"].text.strip_edges()
		if input["final_name"] == "":
			input["final_name"] = input["initial_name"]
	
	for output in current_component_pin_data["outputs"]:
		output["final_name"] = output["name_edit"].text.strip_edges()
		if output["final_name"] == "":
			output["final_name"] = output["initial_name"]
	
	# Save the component definition
	ComponentSerializer.save_component(component_name, selected_gates, wires, current_component_pin_data)
	
	print("Component created successfully!")
	
	# Calculate center position of selected gates
	var center_pos = Vector2.ZERO
	for gate in selected_gates:
		center_pos += gate.global_position
	center_pos /= selected_gates.size()
	
	# Delete selected gates (and their wires)
	for gate in selected_gates.duplicate():
		_delete_gate_instance(gate)
	selected_gates.clear()
	
	# Create an instance of the new component at the center position
	var new_component = CustomComponent.new()
	new_component.component_definition_name = component_name
	new_component.global_position = center_pos
	add_child(new_component)
	new_component.gate_clicked.connect(_select_gate_instance)
	call_deferred("_connect_gate_pins", new_component)
	gates.append(new_component)

	# Refresh the components list
	_populate_components_section()
	
	# Close dialog
	component_dialog_backdrop.visible = false
	current_component_pin_data = {}

func _on_browse_components_button_pressed():
	_show_browse_dialog()

# Scan components folder and return list of component names
func _get_available_components() -> Array[String]:
	var component_names: Array[String] = []
	var dir = DirAccess.open("user://components/")
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				# Remove .json extension to get component name
				var component_name = file_name.replace(".json", "")
				component_names.append(component_name)
			file_name = dir.get_next()
	else:
		print("Components directory doesn't exist yet")
	
	return component_names

# Populate the Components section with buttons
func _populate_components_section():
	# Clear existing component buttons (keep Browse All button)
	for child in components_content.get_children():
		if child != browse_components_button:
			child.queue_free()
	
	# Get available components
	var components = _get_available_components()
	
	# Create a button for each component
	for component_name in components:
		var button = Button.new()
		button.text = component_name
		
		# Style the button (copy styling from other gate buttons)
		# You can apply your NinePatch styling here
		
		# Connect to placement function
		button.pressed.connect(_on_component_button_pressed.bind(component_name))
		
		# Add before the Browse All button
		components_content.add_child(button)
		components_content.move_child(button, components_content.get_child_count() - 2)
	
	print("Loaded ", components.size(), " components")

# Handle component button press
func _on_component_button_pressed(component_name: String):
	_set_mode(Mode.PLACE, component_name)

# Show the browse components dialog
func _show_browse_dialog():
	_populate_browse_dialog()
	browse_backdrop.visible = true

# Populate the browse dialog with all components
func _populate_browse_dialog():
	# Clear existing entries
	for child in browse_components_container.get_children():
		child.queue_free()
	
	# Get available components
	var components = _get_available_components()
	
	if components.size() == 0:
		var label = Label.new()
		label.text = "No components yet. Create one!"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		browse_components_container.add_child(label)
		return
	
	# Create an entry for each component
	for component_name in components:
		var entry = HBoxContainer.new()
		entry.add_theme_constant_override("separation", 8)
		
		# Component name label
		var name_label = Label.new()
		name_label.text = component_name
		name_label.custom_minimum_size = Vector2(150, 0)
		entry.add_child(name_label)
		
		# Place button
		var place_btn = Button.new()
		place_btn.text = "Place"
		place_btn.custom_minimum_size = Vector2(60, 0)
		place_btn.pressed.connect(_on_browse_place_pressed.bind(component_name))
		entry.add_child(place_btn)
		
		# Preview button (disabled for now)
		var preview_btn = Button.new()
		preview_btn.text = "Preview"
		preview_btn.custom_minimum_size = Vector2(70, 0)
		preview_btn.disabled = true  # Will enable when we implement viewing
		entry.add_child(preview_btn)
		
		# Delete button
		var delete_btn = Button.new()
		delete_btn.text = "Delete"
		delete_btn.custom_minimum_size = Vector2(60, 0)
		delete_btn.pressed.connect(_on_browse_delete_pressed.bind(component_name))
		entry.add_child(delete_btn)
		
		# Rename button
		var rename_btn = Button.new()
		rename_btn.text = "Rename"
		rename_btn.custom_minimum_size = Vector2(70, 0)
		rename_btn.pressed.connect(_on_browse_rename_pressed.bind(component_name))
		entry.add_child(rename_btn)
		
		browse_components_container.add_child(entry)

# Handle Place button in browse dialog
func _on_browse_place_pressed(component_name: String):
	browse_backdrop.visible = false
	_set_mode(Mode.PLACE, component_name)

# Handle Delete button in browse dialog
func _on_browse_delete_pressed(component_name: String):
	var file_path = "user://components/" + component_name + ".json"
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)

		_populate_browse_dialog()
		_populate_components_section()
	else: print("Error: Component file not found")

# Handle Rename button in browse dialog
func _on_browse_rename_pressed(component_name: String):
	_show_rename_dialog(component_name)

func _on_browse_close_button_pressed():
	browse_backdrop.visible = false

# Show rename dialog
func _show_rename_dialog(component_name: String):
	component_being_renamed = component_name
	rename_input.text = component_name
	rename_backdrop.visible = true
	rename_input.grab_focus()
	rename_input.select_all()

# Confirm rename
func _on_rename_confirm_button_pressed():
	var new_name = rename_input.text.strip_edges()
	
	if new_name == "":
		print("Error: Component name cannot be empty")
		return
	
	if new_name == component_being_renamed:
		print("Name unchanged")
		rename_backdrop.visible = false
		return
	
	# Check if new name already exists
	if FileAccess.file_exists("user://components/" + new_name + ".json"):
		print("Error: Component with that name already exists")
		return
	
	# Rename the file
	var old_path = "user://components/" + component_being_renamed + ".json"
	var new_path = "user://components/" + new_name + ".json"
	
	# Load the component data
	var component_data = ComponentSerializer.load_component(component_being_renamed)
	if component_data.is_empty():
		print("Error: Could not load component to rename")
		return

	component_data["name"] = new_name
	
	# Save with new name
	var file = FileAccess.open(new_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(component_data, "\t"))
		file.close()
		DirAccess.remove_absolute(old_path)
		
		# Refresh UI
		_populate_browse_dialog()
		_populate_components_section()
		
		rename_backdrop.visible = false
	else: print("Error: Could not save renamed component")

func _on_rename_cancel_button_pressed(): # Cancel rename
	rename_backdrop.visible = false
