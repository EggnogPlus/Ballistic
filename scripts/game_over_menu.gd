extends Control

@onready var play_button = $NinePatchRect/VBoxContainer4/PlayButton
@onready var quit_to_start_button = $NinePatchRect/VBoxContainer3/QTSButton
@onready var score_text = $NinePatchRect/VBoxContainer2/ScoreText
@onready var start_menu = get_node("../StartMenu")
@onready var EnemySpawner = get_node("../EnemySpawner")
@onready var RespawnManager = get_node("../RespawnManager")
@onready var TimeOverlay = get_node("../TimeOverlay")

var added_time = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	play_button.connect("pressed", Callable(self, "on_play_pressed"))
	quit_to_start_button.connect("pressed", Callable(self, "on_qts_pressed"))


func on_play_pressed():
	visible = false
	start_menu.screen_saver_movement = false
	EnemySpawner.delete_all_enemies()
	EnemySpawner.CAN_SPAWN = true
	RespawnManager.respawn_at(Vector2(0, 0))
	TimeOverlay.show_time()

func on_qts_pressed():
	visible = false
	start_menu.screen_on()
	TimeOverlay.hide_time()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not added_time and visible:
		TimeOverlay.visible = false
		added_time = true
		var minutes = int(TimeOverlay.time_elapsed) / 60
		var seconds = int(TimeOverlay.time_elapsed) % 60
		var milliseconds = int((TimeOverlay.time_elapsed - int(TimeOverlay.time_elapsed)) * 100)
		score_text.add_text(" %02d:%02d.%02d" % [minutes, seconds, milliseconds])
