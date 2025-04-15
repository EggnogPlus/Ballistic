extends CharacterBody2D

var acceleration: float = 200
var max_roll_speed: float = 400
var friction: float = 0.01

@onready var mesh_instance_2d: MeshInstance2D = $MeshInstance2D

var is_grappling: bool = false
var grapple_point: Vector2 = Vector2.ZERO
var swing_strength: float = 600
var grapple_raycast_node: RayCast2D
var grapple_drawer: Node2D
var grapple_max_distance: float = 0.0

func _ready():
	grapple_raycast_node = get_node("/root/Level/Player/GrappleRaycast") as RayCast2D
	if grapple_raycast_node == null:
		print("Error: GrappleRaycast node not found!")
	grapple_raycast_node.enabled = false

	grapple_drawer = get_node("/root/Level/Player/GrappleDrawer")
	if grapple_drawer == null:
		print("Error: GrappleDrawer node not found!")

func _physics_process(delta):
	if Input.is_action_just_pressed("grapple") and not is_grappling:
		activate_grapple()

	if is_grappling:
		swing(delta)
		grapple_drawer.queue_redraw()
	else:
		apply_movement(delta)

	if not is_grappling:
		if velocity.length() > 5:
			velocity *= (1 - friction * delta * 30)

	if velocity.length() > max_roll_speed:
		mesh_instance_2d.modulate = Color(1, 0, 0)
	else:
		mesh_instance_2d.modulate = Color(1, 1, 1)
	move_and_slide()

	if not is_grappling and velocity.length() > max_roll_speed:
		#print(velocity.length())
		#print(max_roll_speed)
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var normal = collision.get_normal()

			var impact_alignment = abs(velocity.normalized().dot(normal))
			var momentum_loss_factor = clamp(impact_alignment, 0.0, 1.0)

			# Lose up to 90% of velocity on a head-on hit
			var loss_strength = lerp(0.1, 0.9, momentum_loss_factor)
			velocity *= (1.0 - loss_strength)


	if is_grappling:
		queue_redraw()

func apply_movement(delta):
	var input_vector = Vector2.ZERO

	if Input.is_action_pressed("ui_left"):
		input_vector.x = -1
	elif Input.is_action_pressed("ui_right"):
		input_vector.x = 1

	if Input.is_action_pressed("ui_up"):
		input_vector.y = -1
	elif Input.is_action_pressed("ui_down"):
		input_vector.y = 1

	input_vector = input_vector.normalized()

	if input_vector != Vector2.ZERO:
		var input_force = input_vector * acceleration * delta

		if (velocity + input_force).length() < max_roll_speed:
			velocity += input_force
		else:
			#if not in_grapple_momentum:
			# Momentum steering — influence without cancelling velocity
			var velocity_direction = velocity.normalized()
			var parallel_component = input_vector.dot(velocity_direction) * velocity_direction
			var perpendicular_component = input_vector - parallel_component
			velocity += perpendicular_component  # Adjust delta for appropriate steering strength
				
				

func activate_grapple():
	var nearest_grapple = find_nearest_grapple_point()
	if nearest_grapple:
		grapple_point = nearest_grapple.position
		is_grappling = true
		grapple_max_distance = self.global_position.distance_to(grapple_point)
		grapple_drawer.is_grappling = true
		grapple_drawer.grapple_point = grapple_point
	else:
		print("No grapple point in range!\n")

func swing(delta):
	var direction_to_grapple = (self.grapple_point - self.global_position).normalized()
	var current_distance = self.global_position.distance_to(self.grapple_point)

	if current_distance > self.grapple_max_distance:
		var correction_vector = (self.global_position - self.grapple_point).normalized() * (current_distance - self.grapple_max_distance)
		self.global_position -= correction_vector
		self.velocity -= correction_vector / delta

	var tangent_dir_1 = Vector2(-direction_to_grapple.y, direction_to_grapple.x)
	var tangent_dir_2 = Vector2(direction_to_grapple.y, -direction_to_grapple.x)

	var tangent_direction = tangent_dir_1 if self.velocity.dot(tangent_dir_1) > self.velocity.dot(tangent_dir_2) else tangent_dir_2

	var swing_force = tangent_direction * self.swing_strength * delta
	self.velocity += swing_force

	if Input.is_action_just_pressed("release_grapple"):
		release_grapple()

func release_grapple():
	is_grappling = false
	grapple_raycast_node.enabled = false
	grapple_drawer.release_grapple()

func find_nearest_grapple_point():
	var nearest = null
	var min_distance = 250
	var closest_distance = min_distance

	for grapple in get_tree().get_nodes_in_group("grapple_point"):
		if grapple is StaticBody2D:
			var dist = self.global_position.distance_to(grapple.global_position)
			if dist <= min_distance and (nearest == null or dist < closest_distance):
				closest_distance = dist
				nearest = grapple

	return nearest
