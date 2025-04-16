extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	#$NinePatchRect/VBoxContainer4/ResumeButton.connect("pressed", self, "_on_resume_pressed")
	#$NinePatchRect/VBoxContainer4/ResumeButton.connect("pressed", _on_resume_pressed())

func on_pause_pressed():
	get_tree().paused = true
	visible = true

func _on_resume_pressed():
	get_tree().paused = false
	visible = false
