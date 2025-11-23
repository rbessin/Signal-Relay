class_name WireManager
extends Node

var main: Node2D # Reference to main script
var selection_manager: SelectionManager # Reference to selection manager

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
	is_creating_wire = true # Create wire and set as preview
	wire_start_pin = start_pin
	wire_preview = Wire.new()
	wire_preview.from_pin = wire_start_pin
	wire_preview.is_preview = true
	main.add_child(wire_preview)

func complete_wire_creation(end_pin: Pin):
	if is_duplicate_wire(wire_start_pin, end_pin): # Cancel wire if is duplicate
		cancel_wire_creation()
		return
	elif end_pin.parent_gate == wire_start_pin.parent_gate: # Cancel wire if start and end are the same pin
		cancel_wire_creation()
		return
	elif end_pin.connected_wires.size() > 0: # Cancel wire if input pin is already wired
		cancel_wire_creation()
		return
	else: # Complete wire creation
		wire_preview.to_pin = end_pin # Remove wire preview and convert to real wire
		wire_preview.is_preview = false

		wire_preview.wire_clicked.connect(selection_manager.select_wire_instance) # Add wire signals and add instance to trackers
		wire_start_pin.connected_wires.append(wire_preview)
		end_pin.connected_wires.append(wire_preview)
		wires.append(wire_preview)

		is_creating_wire = false # Stop wire creation
		wire_start_pin = null
		wire_preview = null

func cancel_wire_creation():
	if wire_preview != null: wire_preview.queue_free() # Delete wire preview
	is_creating_wire = false # Stop wire creation
	wire_start_pin = null
	wire_preview = null

func delete_wire(wire: Wire):
	if wire.from_pin != null: wire.from_pin.connected_wires.erase(wire) # Remove wire from trackers
	if wire.to_pin != null: wire.to_pin.connected_wires.erase(wire)
	wires.erase(wire)
	wire.queue_free() # Delete wire instance

func delete_selected_wire():
	if selection_manager.selected_wire_instance != null: # Delete selected wire if wire is selected
		delete_wire(selection_manager.selected_wire_instance)
		selection_manager.selected_wire_instance = null

func position_wire_preview():
	if is_creating_wire and wire_preview != null: # Move preview wire end to follow mouse
		wire_preview.preview_end_position = main.get_global_mouse_position()

func is_duplicate_wire(from_pin: Pin, to_pin: Pin) -> bool:
	for wire in from_pin.connected_wires: # Check if two wires follow the same path
		if wire.from_pin == from_pin and wire.to_pin == to_pin: return true
	return false
