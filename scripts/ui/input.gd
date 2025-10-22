extends Button

# Identity parameters (uid)
@export var uid: int
# State parameters (state, target)
@export var state: bool = false
@export var target: Gate = null
@export var target_input: int = 0

func _on_pressed():
	state = !state
	target.set_input(target_input, state)
