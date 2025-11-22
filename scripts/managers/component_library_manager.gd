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

# State
var component_being_renamed: String = ""

func _init(main_node: Node2D):
	main = main_node
	print("ComponentLibraryManager instantiated.")

func setup_ui_references():
	var inspector_base = main.get_node('UICanvas/UIControl/Inspector/VBoxContainer/ScrollableContent/ContentContainer')
	var browse_dialog = main.get_node('UICanvas/UIControl/BrowseComponentsBackdrop/BrowseDialog/DialogContent')
	var rename_dialog = main.get_node('UICanvas/UIControl/RenameComponentBackdrop/RenameDialog/VBoxContainer')
	
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
	var component_names: Array[String] = []
	var dir = DirAccess.open("user://components/")

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var component_name = file_name.replace(".json", "")
				component_names.append(component_name)
			file_name = dir.get_next()
	
	return component_names

func populate_components_section():
	for child in components_content.get_children():
		if child != browse_components_button:
			child.queue_free()
	
	var components = get_available_components()

	for component_name in components:
		var button = Button.new()
		button.text = component_name
		button.pressed.connect(on_component_button_pressed.bind(component_name))

		components_content.add_child(button)
		components_content.move_child(button, components_content.get_child_count() - 2)

func on_component_button_pressed(component_name: String):
	main.select_place(component_name)

func on_browse_components_button_pressed():
	show_browse_dialog()

func show_browse_dialog():
	populate_browse_dialog()
	browse_backdrop.visible = true

func populate_browse_dialog():
	for child in browse_components_container.get_children():
		child.queue_free()

	var components = get_available_components()

	if components.size() == 0:
		var label = Label.new()
		label.text = "No components yet. Create one!"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		browse_components_container.add_child(label)
		return
	
	for component_name in components:
		var entry = HBoxContainer.new()
		entry.add_theme_constant_override("seperation", 8)

		var name_label = Label.new()
		name_label.text = component_name
		name_label.custom_minimum_size = Vector2(150, 0)
		entry.add_child(name_label)

		var place_button = Button.new()
		place_button.text = "Place"
		place_button.custom_minimum_size = Vector2(60, 0)
		place_button.pressed.connect(on_browse_place_pressed.bind(component_name))
		entry.add_child(place_button)

		var preview_button = Button.new()
		preview_button.text = "Preview"
		preview_button.custom_minimum_size = Vector2(70, 0)
		preview_button.disabled = true
		entry.add_child(preview_button)

		var delete_btn = Button.new()
		delete_btn.text = "Delete"
		delete_btn.custom_minimum_size = Vector2(60, 0)
		delete_btn.pressed.connect(on_browse_delete_pressed.bind(component_name))
		entry.add_child(delete_btn)
		
		var rename_btn = Button.new()
		rename_btn.text = "Rename"
		rename_btn.custom_minimum_size = Vector2(70, 0)
		rename_btn.pressed.connect(on_browse_rename_pressed.bind(component_name))
		entry.add_child(rename_btn)

		browse_components_container.add_child(entry)

func on_browse_place_pressed(component_name: String):
	browse_backdrop.visible = false
	main.select_place(component_name)

func on_browse_delete_pressed(component_name: String):
	var file_path = "user://components/" + component_name + ".json"
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
		populate_browse_dialog()
		populate_components_section()

func on_browse_rename_pressed(component_name: String):
	show_rename_dialog(component_name)

func on_browse_close_button_pressed():
	browse_backdrop.visible = false

func show_rename_dialog(component_name: String):
	component_being_renamed = component_name
	rename_input.text = component_name
	rename_backdrop.visible = true
	rename_input.grab_focus()
	rename_input.select_all()

func on_rename_confirm_button_pressed():
	var new_name = rename_input.text.strip_edges()
	
	if new_name == "": return
	if new_name == component_being_renamed:
		rename_backdrop.visible = false
		return
	
	if FileAccess.file_exists("user://components/" + new_name + ".json"): return

	var old_path = "user://components/" + component_being_renamed + ".json"
	var new_path = "user://components/" + new_name + ".json"

	var component_data = ComponentSerializer.load_component(component_being_renamed)
	if component_data.is_empty(): return
	component_data["name"] = new_name

	var file = FileAccess.open(new_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(component_data, "\t"))
		file.close()
		DirAccess.remove_absolute(old_path)

		populate_browse_dialog()
		populate_components_section()
		rename_backdrop.visible = false

func on_rename_cancel_button_pressed():
	rename_backdrop.visible = false
