extends Node2D

var is_grappling: bool = false
var grapple_point: Vector2 = Vector2.ZERO
var ball: CharacterBody2D
var grapple_raycast_node: RayCast2D

func _ready():
	self.visible = true
	# Do not assume ball or raycast are ready yet – these will be set via RespawnManager

func _draw():
	if not is_instance_valid(ball):
		return

	if is_grappling:
		var local_ball_position = to_local(ball.global_position)
		var local_grapple_point = to_local(grapple_point)
		# Change values here to grapple color/size
		draw_line(local_ball_position, local_grapple_point, Color.SILVER, 3.0)

func release_grapple():
	is_grappling = false
	if is_instance_valid(grapple_raycast_node):
		grapple_raycast_node.enabled = false
	queue_redraw()
