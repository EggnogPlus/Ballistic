extends Control

@onready var resume_button =  $NinePatchRect/VBoxContainer4/ResumeButton 
@onready var qts_button = $NinePatchRect/VBoxContainer3/QTSButton
@onready var start_menu = get_node("../StartMenu")
@onready var TimeOverlay = get_node("../TimeOverlay")
@onready var EnemySpawner = get_node("../EnemySpawner")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	resume_button.connect("pressed", Callable(self, "toggle_pause"))
	qts_button.connect("pressed", Callable(self, "on_quit_to_start_pressed"))

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and not start_menu.screen_saver_movement:
		toggle_pause()

func toggle_pause():
	var is_paused = get_tree().paused
	get_tree().paused = !is_paused
	visible = !is_paused
	if is_paused:
		print("Game unpaused")
	else:
		print("Game paused")

func on_quit_to_start_pressed():
	EnemySpawner.delete_all_enemies()
	start_menu.screen_on()
	TimeOverlay.hide_time()
	toggle_pause()
