class_name CircuitLibraryManager
extends Node

var main: Node2D # Reference to main script
var circuit_persistence_manager: CircuitPersistenceManager # Manager references

# UI references
var simulation_content: VBoxContainer
var browse_circuits_button: Button
var browse_backdrop: Panel
var browse_circuits_container: VBoxContainer
var browse_close_button: Button
var rename_backdrop: Panel
var rename_input: LineEdit
var rename_confirm_button: Button
var rename_cancel_button: Button

# States
var circuit_being_renamed: String = ""

func _init(main_node: Node2D):
	main = main_node
	print("ComponentLibraryManager instantiated.")

func setup_ui_references():
	var inspector_base = main.get_node('UICanvas/UIControl/Inspector/VBoxContainer/ScrollableContent/ContentContainer')
	var browse_dialog = main.get_node('UICanvas/UIControl/BrowseCircuitsBackdrop/BrowseDialog/MarginContainer/DialogContent')
	var rename_dialog = main.get_node('UICanvas/UIControl/RenameBackdrop/RenameDialog/MarginContainer/VBoxContainer')
	
	simulation_content = inspector_base.get_node('SimulationSection/SecondarySimulationContent')
	browse_circuits_button = simulation_content.get_node('BrowseCircuitsButton')
	
	browse_backdrop = main.get_node('UICanvas/UIControl/BrowseCircuitsBackdrop')
	browse_circuits_container = browse_dialog.get_node('CircuitsList/CircuitsContainer')
	browse_close_button = browse_dialog.get_node('CloseButton')
	
	rename_backdrop = main.get_node('UICanvas/UIControl/RenameBackdrop')
	rename_input = rename_dialog.get_node('RenameInput')
	rename_confirm_button = rename_dialog.get_node('HBoxContainer/RenameConfirmButton')
	rename_cancel_button = rename_dialog.get_node('HBoxContainer/RenameCancelButton')

func get_available_circuits() -> Array[String]:
	var circuit_names: Array[String] = [] # Get circuits from local files
	var dir = DirAccess.open("user://circuits/")

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "": # Loop over files and retrieve component names
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var circuit_name = file_name.replace(".json", "")
				circuit_names.append(circuit_name)
			file_name = dir.get_next()
	
	return circuit_names

func on_browse_circuits_button_pressed():
	show_browse_dialog() # Show dialog when browse button clicked

func show_browse_dialog():
	populate_browse_dialog() # Display the dialog and populate with available circuits
	browse_backdrop.visible = true

func populate_browse_dialog():
	for child in browse_circuits_container.get_children(): # Clear previous children
		child.queue_free()

	var circuits = get_available_circuits() # Retrieve component names

	var custom_font = load("res://assets/fonts/DigitalDisco.ttf")

	if circuits.size() == 0: # Display label if there are no components
		var label = Label.new()
		label.text = "No circuits yet. Create one!"
		label.add_theme_font_override("font", custom_font)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		browse_circuits_container.add_child(label)
		return
	
	var button_texture_normal = load("res://assets/art/button_blue_368x32.png")
	var button_texture_hover = load("res://assets/art/button_light_blue_368x32.png")
	var button_texture_pressed = load("res://assets/art/button_lighter_blue_368x32.png")
	
	for circuit_name in circuits: # Create entries for each circuit
		# Create margin container first
		var entry_margin = MarginContainer.new()
		entry_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry_margin.add_theme_constant_override("margin_left", 16)
		entry_margin.add_theme_constant_override("margin_right", 16)
		entry_margin.add_theme_constant_override("margin_top", 4)
		entry_margin.add_theme_constant_override("margin_bottom", 4)
		
		# Create entry HBox
		var entry = HBoxContainer.new()
		entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry.add_theme_constant_override("separation", 0)

		var name_label = Label.new() # Add circuit name to entry
		name_label.text = circuit_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.add_theme_font_override("font", custom_font)
		entry.add_child(name_label)

		var buttons_container = HBoxContainer.new()
		buttons_container.size_flags_horizontal = Control.SIZE_SHRINK_END
		buttons_container.add_theme_constant_override("separation", 0)

		var load_btn = create_styled_button("Load", Vector2(80, 32), button_texture_normal, button_texture_hover, button_texture_pressed, custom_font)
		load_btn.pressed.connect(on_browse_load_pressed.bind(circuit_name))
		buttons_container.add_child(load_btn)

		var delete_btn = create_styled_button("Delete", Vector2(80, 32), button_texture_normal, button_texture_hover, button_texture_pressed, custom_font)
		delete_btn.pressed.connect(on_browse_delete_pressed.bind(circuit_name))
		buttons_container.add_child(delete_btn)
		
		var rename_btn = create_styled_button("Rename", Vector2(80, 32), button_texture_normal, button_texture_hover, button_texture_pressed, custom_font)
		rename_btn.pressed.connect(on_browse_rename_pressed.bind(circuit_name))
		buttons_container.add_child(rename_btn)

		entry.add_child(buttons_container)

		entry_margin.add_child(entry)
		browse_circuits_container.add_child(entry_margin)

func create_styled_button(text: String, size: Vector2, tex_normal: Texture2D, tex_hover: Texture2D, tex_pressed: Texture2D, font: Font) -> Button:
	var button = Button.new() # Function to create a textured button with consistent styling
	button.text = text
	button.custom_minimum_size = size
	button.focus_mode = Control.FOCUS_NONE
	
	# Create StyleBoxTexture for each state
	var style_normal = StyleBoxTexture.new()
	style_normal.texture = tex_normal
	style_normal.draw_center = true
	
	var style_hover = StyleBoxTexture.new()
	style_hover.texture = tex_hover
	style_hover.draw_center = true
	
	var style_pressed = StyleBoxTexture.new()
	style_pressed.texture = tex_pressed
	style_pressed.draw_center = true
	
	# Apply styles to button
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_font_override("font", font)
	
	return button

func on_browse_load_pressed(circuit_name: String):
	browse_backdrop.visible = false # Close dialog and select component
	circuit_persistence_manager.load_circuit(circuit_name)

func on_browse_delete_pressed(circuit_name: String):
	var file_path = "user://circuits/" + circuit_name + ".json" # Delete component
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
		populate_browse_dialog() # Redisplay available circuits

func on_browse_rename_pressed(circuit_name: String):
	show_rename_dialog(circuit_name)

func on_browse_close_button_pressed():
	browse_backdrop.visible = false

func show_rename_dialog(circuit_name: String):
	circuit_being_renamed = circuit_name # Show rename dialog
	rename_input.text = circuit_name
	rename_backdrop.visible = true
	rename_input.grab_focus() # UX helpers
	rename_input.select_all()

func on_rename_confirm_button_pressed():
	var new_name = rename_input.text.strip_edges() # Retrieve new name
	
	if new_name == "": return # Handle incorrect options
	if new_name == circuit_being_renamed:
		rename_backdrop.visible = false
		return
	
	if FileAccess.file_exists("user://circuits/" + new_name + ".json"): return

	var old_path = "user://circuits/" + circuit_being_renamed + ".json" # Create file paths
	var new_path = "user://circuits/" + new_name + ".json"

	var circuit_data = CircuitSerializer.load_from_json(circuit_being_renamed) # Update circuit name
	if circuit_data.is_empty(): return
	circuit_data["circuit_name"] = new_name

	var file = FileAccess.open(new_path, FileAccess.WRITE) # Create new file using filepath and delete old filepath
	if file:
		file.store_string(JSON.stringify(circuit_data, "\t"))
		file.close()
		DirAccess.remove_absolute(old_path)

		populate_browse_dialog() # Redisplay available circuits
		rename_backdrop.visible = false

func on_rename_cancel_button_pressed():
	rename_backdrop.visible = false
