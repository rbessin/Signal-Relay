class_name ComponentLibraryManager
extends Node

var main: Node2D # Reference to main script

# UI references
var components_content: VBoxContainer
var browse_components_button: Button
var browse_backdrop: Panel
var browse_components_container: VBoxContainer
var browse_close_button: Button
var rename_backdrop: Panel
var rename_input: LineEdit
var rename_confirm_button: Button
var rename_cancel_button: Button

# States
var component_being_renamed: String = ""

func _init(main_node: Node2D):
	main = main_node
	print("ComponentLibraryManager instantiated.")

func setup_ui_references():
	var inspector_base = main.get_node('UICanvas/UIControl/Inspector/VBoxContainer/ScrollableContent/ContentContainer')
	var browse_dialog = main.get_node('UICanvas/UIControl/BrowseComponentsBackdrop/BrowseDialog/MarginContainer/DialogContent')
	var rename_dialog = main.get_node('UICanvas/UIControl/RenameComponentBackdrop/RenameDialog/MarginContainer/VBoxContainer')
	
	components_content = inspector_base.get_node('ComponentsSection/ComponentsContent')
	browse_components_button = components_content.get_node('BrowseComponentsButton')
	
	browse_backdrop = main.get_node('UICanvas/UIControl/BrowseComponentsBackdrop')
	browse_components_container = browse_dialog.get_node('ComponentsList/ComponentsContainer')
	browse_close_button = browse_dialog.get_node('CloseButton')
	
	rename_backdrop = main.get_node('UICanvas/UIControl/RenameComponentBackdrop')
	rename_input = rename_dialog.get_node('RenameInput')
	rename_confirm_button = rename_dialog.get_node('HBoxContainer/RenameConfirmButton')
	rename_cancel_button = rename_dialog.get_node('HBoxContainer/RenameCancelButton')

func get_available_components() -> Array[String]:
	var component_names: Array[String] = [] # Get components from local files
	var dir = DirAccess.open("user://components/")

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "": # Loop over files and retrieve component names
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var component_name = file_name.replace(".json", "")
				component_names.append(component_name)
			file_name = dir.get_next()
	
	return component_names

func populate_components_section():
	for child in components_content.get_children(): # Clear previous children
		if child != browse_components_button:
			child.queue_free()
	
	var components = get_available_components() # Retrieve component names

	# Load your textures
	var tex_normal = load("res://assets/art/button_yellow_368x32.png")
	var tex_hover = load("res://assets/art/button_light_yellow_368x32.png")
	var tex_pressed = load("res://assets/art/button_lighter_yellow_368x32.png")
	var custom_font = load("res://assets/fonts/DigitalDisco.ttf")

	# Create themes
	var style_normal = StyleBoxTexture.new()
	style_normal.texture = tex_normal
	var style_hover = StyleBoxTexture.new()
	style_hover.texture = tex_hover
	var style_pressed = StyleBoxTexture.new()
	style_pressed.texture = tex_pressed

	for component_name in components: # Create component buttons
		var button = Button.new()
		button.text = component_name
		button.custom_minimum_size = Vector2(368, 32)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(on_component_button_pressed.bind(component_name))

		button.add_theme_stylebox_override("normal", style_normal) # Apply themes
		button.add_theme_stylebox_override("hover", style_hover)
		button.add_theme_stylebox_override("pressed", style_pressed)
		button.add_theme_font_override("font", custom_font)

		components_content.add_child(button)
		components_content.move_child(button, components_content.get_child_count() - 2)

func on_component_button_pressed(component_name: String):
	main.select_place(component_name) # Switch placement mode when component buttons clicked

func on_browse_components_button_pressed():
	show_browse_dialog() # Show dialog when browse button clicked

func show_browse_dialog():
	populate_browse_dialog() # Display the dialog and populate with available components
	browse_backdrop.visible = true

func populate_browse_dialog():
	for child in browse_components_container.get_children(): # Clear previous children
		child.queue_free()

	var components = get_available_components() # Retrieve component names

	if components.size() == 0: # Display label if there are no components
		var label = Label.new()
		label.text = "No components yet. Create one!"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		browse_components_container.add_child(label)
		return
	
	var button_texture_normal = load("res://assets/art/button_blue_368x32.png")
	var button_texture_hover = load("res://assets/art/button_light_blue_368x32.png")
	var button_texture_pressed = load("res://assets/art/button_lighter_blue_368x32.png")
	var custom_font = load("res://assets/fonts/DigitalDisco.ttf")
	
	for component_name in components: # Create entries for each component
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

		var name_label = Label.new() # Add component name to entry
		name_label.text = component_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.add_theme_font_override("font", custom_font)
		entry.add_child(name_label)

		var buttons_container = HBoxContainer.new()
		buttons_container.size_flags_horizontal = Control.SIZE_SHRINK_END
		buttons_container.add_theme_constant_override("separation", 0)

		var place_button = create_styled_button("Place", Vector2(80, 32), button_texture_normal, button_texture_hover, button_texture_pressed, custom_font)
		place_button.pressed.connect(on_browse_place_pressed.bind(component_name))
		buttons_container.add_child(place_button)

		var preview_button = create_styled_button("Preview", Vector2(80, 32), button_texture_normal, button_texture_hover, button_texture_pressed, custom_font)
		preview_button.disabled = true
		buttons_container.add_child(preview_button)

		var delete_btn = create_styled_button("Delete", Vector2(80, 32), button_texture_normal, button_texture_hover, button_texture_pressed, custom_font)
		delete_btn.pressed.connect(on_browse_delete_pressed.bind(component_name))
		buttons_container.add_child(delete_btn)
		
		var rename_btn = create_styled_button("Rename", Vector2(80, 32), button_texture_normal, button_texture_hover, button_texture_pressed, custom_font)
		rename_btn.pressed.connect(on_browse_rename_pressed.bind(component_name))
		buttons_container.add_child(rename_btn)

		entry.add_child(buttons_container)

		entry_margin.add_child(entry)
		browse_components_container.add_child(entry_margin)

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

func on_browse_place_pressed(component_name: String):
	browse_backdrop.visible = false # Close dialog and select component
	main.select_place(component_name)

func on_browse_delete_pressed(component_name: String):
	var file_path = "user://components/" + component_name + ".json" # Delete component
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
		populate_browse_dialog() # Redisplay available components
		populate_components_section()

func on_browse_rename_pressed(component_name: String):
	show_rename_dialog(component_name)

func on_browse_close_button_pressed():
	browse_backdrop.visible = false

func show_rename_dialog(component_name: String):
	component_being_renamed = component_name # Show rename dialog
	rename_input.text = component_name
	rename_backdrop.visible = true
	rename_input.grab_focus() # UX helpers
	rename_input.select_all()

func on_rename_confirm_button_pressed():
	var new_name = rename_input.text.strip_edges() # Retrieve new name
	
	if new_name == "": return # Handle incorrect options
	if new_name == component_being_renamed:
		rename_backdrop.visible = false
		return
	
	if FileAccess.file_exists("user://components/" + new_name + ".json"): return

	var old_path = "user://components/" + component_being_renamed + ".json" # Create file paths
	var new_path = "user://components/" + new_name + ".json"

	var component_data = ComponentSerializer.load_component(component_being_renamed) # Update component name
	if component_data.is_empty(): return
	component_data["name"] = new_name

	var file = FileAccess.open(new_path, FileAccess.WRITE) # Create new file using filepath and delete old filepath
	if file:
		file.store_string(JSON.stringify(component_data, "\t"))
		file.close()
		DirAccess.remove_absolute(old_path)

		populate_browse_dialog() # Redisplay available components
		populate_components_section()
		rename_backdrop.visible = false

func on_rename_cancel_button_pressed():
	rename_backdrop.visible = false
