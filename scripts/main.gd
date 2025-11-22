extends Node2D

# Managers
var selection_manager: SelectionManager
var gate_manager: GateManager
var wire_manager: WireManager
var component_creation_manager: ComponentCreationManager
var component_library_manager: ComponentLibraryManager
var circuit_persistence_manager: CircuitPersistenceManager

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

## Loading & Saving
@onready var file_name_input: LineEdit = get_node('UICanvas/UIControl/Inspector/VBoxContainer/ScrollableContent/ContentContainer/SimulationSection2/SimulationContent/FileNameInput')

# Default functions which run on instantiation and every frame
func _ready():
	_initialize_managers()
	component_library_manager.populate_components_section()
func _process(delta):
	selection_manager.drag()
	wire_manager.position_wire_preview()
	_move_camera(delta)

func _initialize_managers():
	selection_manager = SelectionManager.new(self)
	gate_manager = GateManager.new(self)
	wire_manager = WireManager.new(self)
	component_creation_manager = ComponentCreationManager.new(self)
	component_library_manager = ComponentLibraryManager.new(self)
	circuit_persistence_manager = CircuitPersistenceManager.new(self)

	component_creation_manager.setup_ui_references()
	component_library_manager.setup_ui_references()

	print("All managers initialized.")

# SELECT helpers
func _select_gate_instance(gate_instance: Gate): # Select gate instance
	selection_manager.select_gate_instance(gate_instance)

func _select_wire_instance(wire_instance: Wire):
	selection_manager.select_wire_instance(wire_instance)

func _delete_gate_instance(gate: Gate): # Delete gate instance
	gate_manager.delete_gate(gate)

func _clear_selection():
	selection_manager.clear_selection()

# PLACE helpers
func instantiate_gate(): # Create gate instance
	gate_manager.instantiate_gate()

func _create_gate(gate_type: String, pos: Vector2, uid: String = "") -> Gate:
	return gate_manager.create_gate(gate_type, pos, uid)

func _connect_gate_pins(gate: Gate):
	for child in gate.get_children():
		if child is Pin:
			child.pin_clicked.connect(_on_pin_clicked)

func _on_pin_clicked(pin_instance: Pin): # Handle pin clicks
	if current_mode == Mode.WIRE:
		if not wire_manager.is_creating_wire:
			if pin_instance.pin_type == Pin.PinType.OUTPUT:
				_start_wire_creation(pin_instance)
		else:
			if pin_instance.pin_type == Pin.PinType.INPUT:
				_complete_wire_creation(pin_instance)
			else: _cancel_wire_creation()

# WIRE helpers
func _start_wire_creation(start_pin: Pin):
	wire_manager.start_wire_creation(start_pin)

func _complete_wire_creation(end_pin: Pin):
	wire_manager.complete_wire_creation(end_pin)

func _cancel_wire_creation():
	wire_manager.cancel_wire_creation()

func _delete_wire_instance():
	wire_manager.delete_selected_wire()

func _delete_wire(wire: Wire):
	wire_manager.delete_wire(wire)

func _position_wire_preview():
	wire_manager.position_wire_preview()

func _is_duplicate_wire(from_pin: Pin, to_pin: Pin) -> bool:
	return wire_manager.is_duplicate_wire(from_pin, to_pin)

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
	selection_manager.stop_dragging()
func _handle_delete(): # Handle delete
	if current_mode == Mode.SELECT: 
		for gate in selection_manager.selected_gates.duplicate(): _delete_gate_instance(gate)
		selection_manager.selected_gates.clear()
		if selection_manager.selected_wire_instance != null: _delete_wire_instance()
func _handle_stop(): # Handle stop
	if current_mode == Mode.WIRE: _cancel_wire_creation()
	elif current_mode == Mode.SELECT: _clear_selection()

# Enter mode
func _enter_select():
	pass
func _enter_place(gate_name: String = ""):
	if gate_name != "":
		gate_manager.set_gate_to_place(gate_name)
func _enter_wire():
	pass
func _enter_simulate():
	await get_tree().process_frame
	for gate in gate_manager.gates: # Initialize all gates and connected wires
		gate.write_output_to_pin()
		gate.propagate_to_wires()
	for gate in gate_manager.gates:
		if gate is CustomComponent:
			gate._initialize_internal_circuit()
	for gate in gate_manager.gates:
		if gate.type == "CLOCK": gate.start_clock()

# Exit mode
func _exit_select():
	_clear_selection()
	selection_manager.stop_dragging()
func _exit_place():
	gate_manager.clear_gate_to_place()
func _exit_wire():
	wire_manager.cancel_wire_creation()
func _exit_simulate():
	for gate in gate_manager.gates:
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
		wire_manager.wires.append(new_wire)

		source_pin.connected_wires.append(new_wire)
		destination_pin.connected_wires.append(new_wire)

func _empty_circuit():
	for child in gate_manager.gates.duplicate(): _delete_gate_instance(child)

func _on_save_button_pressed():
	var circuit_name = file_name_input.text
	if circuit_name == "": circuit_name = "my_circuit"  # Default if empty
	CircuitSerializer.save_to_json(gate_manager.gates, wire_manager.wires, circuit_name)
	print("Circuit saved as: " + circuit_name)

func _on_load_button_pressed():
	var circuit_name = file_name_input.text
	if circuit_name == "": circuit_name = "my_circuit"  # Default if empty
	_load_circuit(circuit_name)
	print("Circuit loaded: " + circuit_name)

# Component Creation Functions
func _on_create_component_button_pressed():
	component_creation_manager.on_create_component_button_pressed()

func _update_create_component_button():
	component_creation_manager.update_create_component_button()

func _detect_external_pins(selected_gate_list: Array[Gate]) -> Dictionary:
	return component_creation_manager.detect_external_pins(selected_gate_list)

func _show_component_dialog():
	component_creation_manager.show_component_dialog()

func _on_cancel_button_pressed():
	component_creation_manager.on_cancel_button_pressed()

func _on_create_button_pressed():
	component_creation_manager.on_create_button_pressed()

func _on_browse_components_button_pressed():
	component_library_manager.on_browse_components_button_pressed()

# Scan components folder and return list of component names
func _get_available_components() -> Array[String]:
	return component_library_manager.get_available_components()

# Populate the Components section with buttons
func _populate_components_section():
	component_library_manager.populate_components_section()

# Handle component button press
func _on_component_button_pressed(component_name: String):
	component_library_manager.on_component_button_pressed(component_name)

# Show the browse components dialog
func _show_browse_dialog():
	component_library_manager.show_browse_dialog()

# Populate the browse dialog with all components
func _populate_browse_dialog():
	component_library_manager.populate_browse_dialog()

# Handle Place button in browse dialog
func _on_browse_place_pressed(component_name: String):
	component_library_manager.on_browse_place_pressed(component_name)

# Handle Delete button in browse dialog
func _on_browse_delete_pressed(component_name: String):
	component_library_manager.on_browse_delete_pressed(component_name)

# Handle Rename button in browse dialog
func _on_browse_rename_pressed(component_name: String):
	component_library_manager.on_browse_rename_pressed(component_name)

func _on_browse_close_button_pressed():
	component_library_manager.on_browse_close_button_pressed()

# Show rename dialog
func _show_rename_dialog(component_name: String):
	component_library_manager.show_rename_dialog(component_name)

# Confirm rename
func _on_rename_confirm_button_pressed():
	component_library_manager.on_rename_confirm_button_pressed()

func _on_rename_cancel_button_pressed(): # Cancel rename
	component_library_manager.on_rename_cancel_button_pressed()
