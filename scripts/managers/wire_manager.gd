class_name WireManager
extends Node

var main: Node2D # Reference to main script

# Creation
var is_creating_wire: bool = false
var wire_start_pin: Pin = null
var wire_preview: Wire = null

# Tracking
var wires: Array[Wire] = []

func _init(main_node: Node2D):
	main = main_node
	print("WireManager instantiated.")

func start_wire_creation(start_pin: Pin):
	is_creating_wire = true
	wire_start_pin = start_pin
	wire_preview = Wire.new()
	wire_preview.from_pin = wire_start_pin
	wire_preview.is_preview = true
	main.add_child(wire_preview)

func complete_wire_creation(end_pin: Pin):
	if is_duplicate_wire(wire_start_pin, end_pin):
		cancel_wire_creation()
		return
	if end_pin.parent_gate == wire_start_pin.parent_gate:
		cancel_wire_creation()
		return
	if end_pin.connected_wires.size() > 0:
		cancel_wire_creation()
		return
	
	wire_preview.to_pin = end_pin
	wire_preview.is_preview = false

	wire_preview.wire_clicked.connect(main._select_wire_instance)
	wire_start_pin.connected_wires.append(wire_preview)
	end_pin.connected_wires.append(wire_preview)

	wires.append(wire_preview)

	is_creating_wire = false
	wire_start_pin = null
	wire_preview = null

func cancel_wire_creation():
	if wire_preview != null:
		wire_preview.queue_free()
	is_creating_wire = false
	wire_start_pin = null
	wire_preview = null

func delete_wire(wire: Wire):
	if wire.from_pin != null:
		wire.from_pin.connected_wires.erase(wire)
	if wire.to_pin != null:
		wire.to_pin.connected_wires.erase(wire)
	wires.erase(wire)
	wire.queue_free()

func delete_selected_wire():
	if main.selection_manager.selected_wire_instance != null:
		delete_wire(main.selection_manager.select_wire_instance)
		main.selection_manager.selected_wire_instance = null

func position_wire_preview():
	if is_creating_wire and wire_preview != null:
		wire_preview.preview_end_position = main.get_global_mouse_position()

func is_duplicate_wire(from_pin: Pin, to_pin: Pin) -> bool:
	for wire in from_pin.connected_wires:
		if wire.from_pin == from_pin and wire.to_pin == to_pin: return true
	return false

func clear_preview():
	if wire_preview != null:
		wire_preview.queue_free()
		wire_preview = null
	is_creating_wire = false
	wire_start_pin = null
