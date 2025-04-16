extends Control

@onready var play_button =  $NinePatchRect/VBoxContainer4/PlayButton
@onready var quit_to_desktop_button =  $NinePatchRect/VBoxContainer3/QTDButton
@onready var pause_menu = get_node("../PauseMenu")
@onready var bg = $NinePatchRect/ColorRect
@onready var player = get_node("../Player")
@onready var RespawnManager = get_node("../RespawnManager")
@onready var EnemySpawner = get_node("../EnemySpawner")

var on_start_menu = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#visible = true
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	print("-- Started New Instance --")
	#pause_menu.toggle_pause() # Pause game initially
	get_node("/root/Level/Player/ball").queue_free() # Remove ball child of player
	play_button.connect("pressed", Callable(self, "on_play_pressed"))
	quit_to_desktop_button.connect("pressed", Callable(self, "on_qtd_pressed"))


func on_play_pressed():
	print("Play Pressed")
	visible = false
	on_start_menu = false
	EnemySpawner.delete_all_enemies()
	RespawnManager.respawn_at(Vector2(0, 0))
	
	
func on_qtd_pressed():
	print("Quiting...")
	get_tree().quit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
