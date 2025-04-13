extends Node2D

var is_grappling: bool = false
var grapple_point: Vector2 = Vector2.ZERO
var ball: CharacterBody2D  # Reference to the ball node
var grapple_raycast_node: RayCast2D

func _ready():
	# Access Ball and GrappleRaycast from the root level (Node2D)
	ball = get_node("/root/Level/Player/ball")  # Ball is a child of Node2D
	grapple_raycast_node = get_node("/root/Level/Player/GrappleRaycast")  # GrappleRaycast
	grapple_raycast_node.enabled = false  # Initially, the grapple raycast is disabled

	# Ensure the GrappleDrawer is visible
	self.visible = true  # Make sure the node is visible

func _draw():
	# Only draw the grapple line if we're grappling
	if is_grappling:
		# Convert both the ball and grapple_point positions to the local coordinates of this Node2D
		var local_ball_position = to_local(ball.global_position)
		var local_grapple_point = to_local(grapple_point)

		# Draw the line from the ball to the grapple point in local coordinates
		draw_line(local_ball_position, local_grapple_point, Color.SILVER, 3.0)  # Draw the line

func release_grapple():
	# When releasing the grapple, stop drawing the line
	is_grappling = false
	grapple_raycast_node.enabled = false
	queue_redraw()  # Request a redraw after releasing the grapple
