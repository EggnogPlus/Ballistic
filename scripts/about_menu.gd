extends Control

@onready var back_button = $NinePatchRect/VBoxContainer4/BackButton
@onready var pause_menu = get_node("../PauseMenu")
@onready var bg = $NinePatchRect/ColorRect
@onready var player = get_node("../Player")
@onready var RespawnManager = get_node("../RespawnManager")
@onready var EnemySpawner = get_node("../EnemySpawner")
@onready var TimeOverlay = get_node("../TimeOverlay")
@onready var start_menu = get_node("../StartMenu")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_button.connect("pressed", Callable(self, "on_back_pressed"))

func screen_on():
	visible = true
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ball = get_node("/root/Level/Player/ball")
	if ball:
		ball.queue_free() # Remove ball child of player
	


func on_back_pressed():
	visible = false
	start_menu.screen_on()
