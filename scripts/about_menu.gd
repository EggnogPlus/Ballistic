extends Control

@onready var back_button = $NinePatchRect/VBoxContainer4/BackButton
@onready var StartMenu = get_node("../StartMenu")
@onready var bg = $NinePatchRect/ColorRect
@onready var player = get_node("../Player")
@onready var RespawnManager = get_node("../RespawnManager")
@onready var EnemySpawner = get_node("../EnemySpawner")
@onready var TimeOverlay = get_node("../TimeOverlay")

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
		ball.queue_free()
	
	
func on_back_pressed():
	visible = false
	StartMenu.screen_on()
