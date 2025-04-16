extends Control

@onready var resume_button =  $NinePatchRect/VBoxContainer4/ResumeButton 


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	resume_button.connect("pressed", Callable(self, "toggle_pause"))

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		toggle_pause()

func toggle_pause():	
	var is_paused = get_tree().paused
	get_tree().paused = !is_paused
	visible = !is_paused
	if is_paused:
		print("Game unpaused")
	else:
		print("Game paused")

func _on_resume_pressed():
	toggle_pause()
