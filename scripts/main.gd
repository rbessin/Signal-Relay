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
	circuit_persistence_manager.setup_ui_references()

	_setup_manager_references()
	_connect_manager_signals()

	print("All managers initialized.")

func _setup_manager_references():
	# Setup selection manager references
	selection_manager.component_creation_manager = component_creation_manager
	# Setup component creation manager references
	component_creation_manager.selection_manager = selection_manager
	component_creation_manager.wire_manager = wire_manager
	component_creation_manager.gate_manager = gate_manager
	component_creation_manager.component_library_manager = component_library_manager
	# Setup circuit persistence manager references
	circuit_persistence_manager.gate_manager = gate_manager
	circuit_persistence_manager.wire_manager = wire_manager
	# Setup gate manager references
	gate_manager.selection_manager = selection_manager
	gate_manager.wire_manager = wire_manager
	# Setup wire manager references
	wire_manager.selection_manager = selection_manager

func _connect_manager_signals():
	# Component creation signals
	component_creation_manager.create_component_button.pressed.connect(
		component_creation_manager.on_create_component_button_pressed)
	component_creation_manager.create_button.pressed.connect(
		component_creation_manager.on_create_button_pressed)
	component_creation_manager.cancel_button.pressed.connect(
		component_creation_manager.on_cancel_button_pressed)
	
	# Component library signals
	component_library_manager.browse_components_button.pressed.connect(
		component_library_manager.on_browse_components_button_pressed)
	component_library_manager.browse_close_button.pressed.connect(
		component_library_manager.on_browse_close_button_pressed)
	component_library_manager.rename_confirm_button.pressed.connect(
		component_library_manager.on_rename_confirm_button_pressed)
	component_library_manager.rename_cancel_button.pressed.connect(
		component_library_manager.on_rename_cancel_button_pressed)

	# Circuit persistence signals
	circuit_persistence_manager.clear_button.pressed.connect(
		circuit_persistence_manager.empty_circuit)
	circuit_persistence_manager.save_button.pressed.connect(
		circuit_persistence_manager.on_save_button_pressed)
	circuit_persistence_manager.load_button.pressed.connect(
		circuit_persistence_manager.on_load_button_pressed)

func _connect_gate_pins(gate: Gate):
	for child in gate.get_children():
		if child is Pin:
			child.pin_clicked.connect(_on_pin_clicked)

func _on_pin_clicked(pin_instance: Pin):
	if current_mode == Mode.WIRE:
		if not wire_manager.is_creating_wire:
			if pin_instance.pin_type == Pin.PinType.OUTPUT:
				wire_manager.start_wire_creation(pin_instance)
		else:
			if pin_instance.pin_type == Pin.PinType.INPUT:
				wire_manager.complete_wire_creation(pin_instance)
			else: wire_manager.cancel_wire_creation()

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
	if current_mode == Mode.PLACE: gate_manager.instantiate_gate()
	elif current_mode == Mode.SELECT:
		if not Input.is_key_pressed(KEY_SHIFT): selection_manager.clear_selection()
func _handle_click_release(): # Handle click release
	selection_manager.stop_dragging()
func _handle_delete(): # Handle delete
	if current_mode == Mode.SELECT: 
		for gate in selection_manager.selected_gates.duplicate(): gate_manager.delete_gate(gate)
		selection_manager.selected_gates.clear()
		if selection_manager.selected_wire_instance != null: wire_manager.delete_selected_wire()
func _handle_stop(): # Handle stop
	if current_mode == Mode.WIRE: wire_manager.cancel_wire_creation()
	elif current_mode == Mode.SELECT: selection_manager.clear_selection()
func _handle_save(): circuit_persistence_manager.on_save_button_pressed()
func _handle_load(): circuit_persistence_manager.on_load_button_pressed()

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
	selection_manager.clear_selection()
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
