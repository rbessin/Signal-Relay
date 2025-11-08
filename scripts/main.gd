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
@onready var mode_label: Label = get_node("UI/Toolbar/Current_Mode")

# PLACE mode
var gate_prefabs: Dictionary = {
	"AND": preload("res://scenes/gates/and_gate.tscn"),
	"NAND": preload("res://scenes/gates/nand_gate.tscn"),
	"OR": preload("res://scenes/gates/or_gate.tscn"),
	"NOR": preload("res://scenes/gates/nor_gate.tscn"),
	"NOT": preload("res://scenes/gates/not_gate.tscn"),
	"XOR": preload("res://scenes/gates/xor_gate.tscn"),
	"INPUT": preload("res://scenes/ui/input.tscn"),
	"OUTPUT": preload("res://scenes/ui/output_display.tscn"),
	"CLOCK": preload("res://scenes/ui/clock.tscn"),
	"D_FLIPFLOP": preload("res://scenes/ui/d_flipflop.tscn"),
}
var gate_to_place: PackedScene = null # Which gate type to place
var gate_type_to_place: String = ""
var current_uid: int = 0

# SELECT mode
var is_dragging: bool = false
var drag_offset: Vector2
var selected_gate_instance: Gate = null
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
@onready var file_name_input: LineEdit = get_node("UI/Toolbar/FileNameInput")

# Default functions which run on instantiation and every frame
func _ready():
	pass
func _process(delta):
	_drag()
	_position_wire_preview()
	_move_camera(delta)

# SELECT helpers
func _drag(): # Drag gate instance
	if is_dragging and selected_gate_instance != null:
		selected_gate_instance.global_position = get_global_mouse_position() + drag_offset

func _select_gate_instance(gate_instance: Gate): # Select gate instance
	if current_mode == Mode.SIMULATE:
		if gate_instance.type == "INPUT": gate_instance.toggle()
		return
	elif current_mode == Mode.SELECT:
		_clear_selection()

		selected_gate_instance = gate_instance
		gate_instance.set_selected(true)
		is_dragging = true
		drag_offset = selected_gate_instance.global_position - get_global_mouse_position()

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
	if selected_gate_instance != null:
		selected_gate_instance.set_selected(false)
		selected_gate_instance = null
	if selected_wire_instance != null:
		selected_wire_instance.set_selected(false)
		selected_wire_instance = null

# PLACE helpers
func instantiate_gate(): # Create gate instance
	if gate_type_to_place == "": return
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

func _handle_click(): # Handle click
	if current_mode == Mode.PLACE: instantiate_gate()
	elif current_mode == Mode.SELECT:
		if selected_gate_instance != null:
			selected_gate_instance.set_selected(false)
			selected_gate_instance = null
func _handle_click_release(): # Handle click release
	is_dragging = false
func _handle_delete(): # Handle delete
	if current_mode == Mode.SELECT: 
		if selected_gate_instance != null: 
			_delete_gate_instance(selected_gate_instance)
			selected_gate_instance = null
		if selected_wire_instance != null: _delete_wire_instance()
func _handle_stop(): # Handle stop
	if current_mode == Mode.WIRE: _cancel_wire_creation()
	elif current_mode == Mode.SELECT: selected_gate_instance = null

# Enter mode
func _enter_select():
	pass
func _enter_place(gate_name: String = ""):
	if gate_name != "" and gate_name in gate_prefabs:
		gate_to_place = gate_prefabs[gate_name]
		gate_type_to_place = gate_name
func _enter_wire():
	pass
func _enter_simulate():
	await get_tree().process_frame
	for gate in gates: # Initialize all gates and connected wires
		gate.write_output_to_pin()
		gate.propagate_to_wires()
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
