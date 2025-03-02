extends Node2D

var is_grappling: bool = false
var grapple_point: Vector2 = Vector2.ZERO
var ball: CharacterBody2D  # Reference to the ball node
var grapple_raycast_node: RayCast2D

func _ready():
	# Access Ball and GrappleRaycast from the root level (Node2D)
	ball = get_node("/root/Level/Node2D/ball")  # Ball is a child of Node2D
	grapple_raycast_node = get_node("/root/Level/Node2D/GrappleRaycast")  # GrappleRaycast
	grapple_raycast_node.enabled = false  # Initially, the grapple raycast is disabled

func _draw():
	# Only draw the grapple line if we're grappling
	if is_grappling:
		draw_line(Vector2.ZERO, to_local(grapple_point), Color.BLACK, 2.0)  # Draw the line

func release_grapple():
	# When releasing the grapple, stop drawing the line
	is_grappling = false
	grapple_raycast_node.enabled = false
	
