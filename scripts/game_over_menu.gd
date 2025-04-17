extends Control

@onready var play_button = $NinePatchRect/VBoxContainer4/PlayButton
@onready var quit_to_start_button = $NinePatchRect/VBoxContainer3/QTSButton
@onready var score_text = $NinePatchRect/VBoxContainer2/ScoreText



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	play_button.connect("pressed", Callable(self, "on_play_pressed"))
	quit_to_start_button.connect("pressed", Callable(self, "on_qts_pressed"))


func on_play_pressed():
	visible = false
	#screen_saver_movement = false
	#EnemySpawner.delete_all_enemies()
	#RespawnManager.respawn_at(Vector2(0, 0))
	#TimeOverlay.show_time()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
