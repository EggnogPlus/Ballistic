extends Control

var time_elapsed := 0.0
var is_running := false

@onready var label = $VBoxContainer/RichTextLabel
#@onready var ball = get_node("../Player/ball")

func _ready() -> void:
		visible = false

func _process(delta):
	if is_running and get_node("../Player/ball").started_moving:
		time_elapsed += delta
		update_display()

func update_display():
	var minutes = int(time_elapsed) / 60
	var seconds = int(time_elapsed) % 60
	var milliseconds = int((time_elapsed - int(time_elapsed)) * 100)
	label.text = "%02d:%02d.%02d" % [minutes, seconds, milliseconds]
	
func show_time():
	visible = true
	start_timer()

func hide_time():
	visible = false
	stop_timer()
	time_elapsed = 0.0

func start_timer():
	is_running = true
	time_elapsed = 0.0

func stop_timer():
	is_running = false
