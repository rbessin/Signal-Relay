extends Control

@export var header_button: Button
@export var content_containers: Array[Control] = []
var is_collapsed: bool = true

func _ready():
	# Auto-find header button if not set
	if header_button == null:
		header_button = _find_header_button()
	
	# Auto-find all content containers if not set
	if content_containers.is_empty():
		content_containers = _find_content_containers()
	
	# Initialize collapsed state
	_update_visibility()
	
	# Connect header button
	if header_button: header_button.pressed.connect(_on_header_pressed)

func _find_header_button() -> Button: # Find header button
	for child in get_children():
		if child is Button: return child
	return null

func _find_content_containers() -> Array[Control]: # Find container children except header button
	var containers: Array[Control] = []
	
	for child in get_children():
		# Skip the header button
		if child == header_button or child is Button: continue
		
		# Add any container type
		if child is Container or child is Control:
			containers.append(child)
	
	return containers

func _on_header_pressed(): # Handle header press
	is_collapsed = !is_collapsed
	_update_visibility()
	_update_arrow()

func _update_visibility(): # Toggle visibility of all containers
	for container in content_containers:
		if container: container.visible = !is_collapsed

func _update_arrow(): # Update arrow display
	if not header_button: return
	
	if is_collapsed: header_button.text = header_button.text.replace("▼", "▶")
	else: header_button.text = header_button.text.replace("▶", "▼")
