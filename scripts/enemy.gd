extends CharacterBody2D

# Variables
var speed = 100
var target_player = null
var path_follow : PathFollow2D
var detection_radius : Area2D

# Signal callback for when player is detected
func _on_player_detected(player):
	target_player = player  # Set the detected player as the target
	print("Player detected: " + str(player))

# Called when the node enters the scene tree
func _ready():
	path_follow = $PathFollow2D
	detection_radius = $Area2D
	
	# Use the proper connect syntax in Godot 4
	detection_radius.player_detected.connect(_on_player_detected)
	
	# Initially, stop the enemy from moving along the path
	path_follow.offset = 0  # Or stop any ongoing movement

# Update the enemy every frame
func _process(delta):
	if target_player != null:
		var direction = (target_player.position - position).normalized()
		velocity = direction * speed
		move_and_slide()
