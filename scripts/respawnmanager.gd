extends Node

@onready var level = get_node("/root/Level")
@onready var player_node = get_node("/root/Level/Player")
var ball_scene = preload("res://scenes/ball.tscn")

func respawn_at(position: Vector2):
	# Remove existing ball
	if player_node.has_node("ball"):
		player_node.get_node("ball").queue_free()

	await get_tree().process_frame  # Ensure node is freed before adding a new one

	# Instantiate the full Player scene (Node2D root)
	var temp_instance = ball_scene.instantiate() as Node2D
	# Extract the ball CharacterBody2D child
	var new_ball = temp_instance.get_node("ball") as CharacterBody2D
	if not new_ball:
		print("Error: No 'ball' CharacterBody2D found in ball.tscn")
		temp_instance.queue_free()
		return

	# Remove the ball node from the temporary instance
	temp_instance.remove_child(new_ball)
	# Free the temporary instance (the rest of the scene)
	temp_instance.queue_free()

	# Add the extracted ball to the Player node
	new_ball.name = "ball"
	new_ball.position = position
	player_node.add_child(new_ball)

	# Reconnect to GrappleDrawer
	var grapple_drawer = player_node.get_node_or_null("GrappleDrawer")
	if grapple_drawer:
		grapple_drawer.ball = new_ball  # Assign the new ball (CharacterBody2D)
		grapple_drawer.grapple_raycast_node = player_node.get_node_or_null("GrappleRaycast")
