extends VBoxContainer

var header_button: Button
var content: Control

var is_collapsed: bool = true

func _ready():
	for child in get_children(): # Find the first Button child (the header)
		if child is Button:
			header_button = child
			break
	
	for child in get_children(): # Find the first VBoxContainer child (the content)
		if child is VBoxContainer and child != self:
			content = child
			break
	
	# Hide content and connect the button
	if content: content.visible = false
	if header_button: header_button.pressed.connect(_on_header_pressed)

func _on_header_pressed():
	is_collapsed = !is_collapsed
	content.visible = !is_collapsed
	
	# Update arrow direction
	if is_collapsed: header_button.text = header_button.text.replace("▼", "▶")
	else: header_button.text = header_button.text.replace("▶", "▼")
