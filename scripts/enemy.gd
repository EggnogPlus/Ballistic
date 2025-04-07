extends CharacterBody2D

var speed: float = 100.0

func _physics_process(delta):
	var player = get_node_or_null("/root/Level/Player/ball")
	if player and is_instance_valid(player):
		print(player.position);
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
