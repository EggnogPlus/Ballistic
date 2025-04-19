extends Control

@onready var play_button =  $NinePatchRect/VBoxContainer4/PlayButton
@onready var quit_to_desktop_button =  $NinePatchRect/VBoxContainer3/QTDButton
@onready var about_button = $NinePatchRect/VBoxContainer5/AboutButton
@onready var pause_menu = get_node("../PauseMenu")
@onready var bg = $NinePatchRect/ColorRect
@onready var player = get_node("../Player")
@onready var RespawnManager = get_node("../RespawnManager")
@onready var EnemySpawner = get_node("../EnemySpawner")
@onready var TimeOverlay = get_node("../TimeOverlay")
@onready var AboutMenu = get_node("../AboutMenu")

var screen_saver_movement = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("-- Starting New Instance --")
	screen_on()

func screen_on():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	screen_saver_movement = true
	EnemySpawner.CAN_SPAWN = true
	visible = true
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var ball = get_node("/root/Level/Player/ball")
	if ball:
		ball.queue_free() # Remove ball child of player
	play_button.connect("pressed", Callable(self, "on_play_pressed"))
	quit_to_desktop_button.connect("pressed", Callable(self, "on_qtd_pressed"))
	about_button.connect("pressed", Callable(self, "on_about_pressed"))


func on_play_pressed():
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	screen_saver_movement = false
	EnemySpawner.delete_all_enemies()
	RespawnManager.respawn_at(Vector2(0, 0))
	TimeOverlay.show_time()
	
func on_about_pressed():
	visible = false
	AboutMenu.screen_on()
	
func on_qtd_pressed():
	print("Quiting...")
	get_tree().quit()
	
	
func _process(delta: float) -> void:
	pass
