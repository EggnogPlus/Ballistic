extends CharacterBody2D

# Base Movement
var acceleration: float = 400
var max_roll_speed: float = 400
var friction: float = 0.01

# Execute vars
var execute_threshold: float = 600
var can_execute = false

# Arcade Elements
var started_moving = false
var death_timer = 0
var death_limit = 3.5
var death_displacement_radius = 50
var reference_position: Vector2 = Vector2.ZERO  # Center of area

@onready var mesh_instance_2d: MeshInstance2D = $MeshInstance2D
@onready var camera = get_viewport().get_camera_2d()
@onready var grapple_raycast_node: RayCast2D = get_node("/root/Level/Player/GrappleRaycast")
@onready var grapple_drawer: Node2D = get_node("/root/Level/Player/GrappleDrawer")

# Grappling vars
var is_grappling: bool = false
var grapple_point: Vector2 = Vector2.ZERO
var swing_strength: float = 400
var grapple_max_distance: float = 0.0

func _ready():
	if grapple_raycast_node == null:
		print("Error: GrappleRaycast node not found!")
	grapple_raycast_node.enabled = false

	if grapple_drawer == null:
		print("Error: GrappleDrawer node not found!")

func _physics_process(delta):
	if get_tree().paused:  # Skip gameplay when paused
		return
	
	if Input.is_action_just_pressed("grapple"):
		if is_grappling:
			release_grapple()
		else:
			activate_grapple()
	
	if is_grappling:
		swing(delta)
		grapple_drawer.queue_redraw()
	else:
		apply_movement(delta)

	if not is_grappling:
		if velocity.length() > 5:
			velocity *= (1 - friction * delta * 30)

	# Check for Debug mesh Modulation TODO add fire animation
	if velocity.length() > max_roll_speed:
		if velocity.length() > execute_threshold:
			can_execute = true
			mesh_instance_2d.modulate = Color(0, 1, 0)
		else:
			can_execute = false
			mesh_instance_2d.modulate = Color(1, 0, 0)
	else:
		can_execute = false
		mesh_instance_2d.modulate = Color(1, 1, 1)
	
	# PLAYER INDICATOR TODO 
	if started_moving and global_position:
		if death_timer >= death_limit:
			queue_free()
		else:
			if death_timer >= 2.5:
				mesh_instance_2d.modulate = Color(1, 0, 0)
			elif death_timer >= 1.5:
				mesh_instance_2d.modulate = Color(0, 0, 1)
			elif death_timer >= 0.5:
				mesh_instance_2d.modulate = Color(0, 1, 0)

	move_and_slide()
	check_for_enemy_execution()
	update_death_status(delta)
	
	queue_redraw()

func _draw():
	if velocity.length() > 0:
		var velocity_scaled = velocity * 0.1
		draw_line(Vector2.ZERO, velocity_scaled, Color(1, 1, 1), 3.0) # -velocity_scaled has trailing line
	#if death_timer > 0:
		#draw_circle(Vector2.ZERO, death_displacement_radius, Color(0, 1, 0, 0.2))

#region Death & Execution AND apply_movement 
func update_death_status(delta):
	var distance = global_position.distance_to(reference_position)
	if distance <= death_displacement_radius:
		death_timer += delta
	else:
		death_timer = 0.0
		reference_position = global_position

func check_for_enemy_execution():
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("enemies"):
			print("------")
			print("TIME: ", Time.get_datetime_dict_from_system().second)
			print("VELOCITY: ", velocity.length())
			print("EXECUTE THRESHOLD: ", execute_threshold)
			if can_execute and not is_grappling:
				velocity = velocity * 1.1
				collider.execute()
				if camera and "start_shake" in camera:
					camera.start_shake(8.0)

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
		started_moving = true
		var input_force = input_vector * acceleration * delta
		var new_velocity = velocity
		if abs(velocity.x) < max_roll_speed:
			new_velocity.x += input_force.x
		if abs(velocity.y) < max_roll_speed:
			new_velocity.y += input_force.y
		if new_velocity.length() > max_roll_speed:
			var input_direction = input_force.normalized()
			var velocity_direction = velocity.normalized()
			if input_direction.dot(velocity_direction) > 0:
				var parallel_component = input_direction.dot(velocity_direction) * velocity_direction
				var perpendicular_component = input_direction - parallel_component
				var adjusted_force = perpendicular_component * acceleration * delta
				new_velocity = velocity + adjusted_force
		velocity = new_velocity
#endregion

#region Grapple Functions
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
	started_moving = true
	var direction_to_grapple = (self.grapple_point - self.global_position).normalized()
	var current_distance = self.global_position.distance_to(self.grapple_point)
	if current_distance > self.grapple_max_distance:
		var correction_vector = (self.global_position - self.grapple_point).normalized() * (current_distance - self.grapple_max_distance)
		self.global_position -= correction_vector
		self.velocity -= correction_vector / delta
	var tangent_dir_1 = Vector2(-direction_to_grapple.y, direction_to_grapple.x)
	var tangent_dir_2 = Vector2(direction_to_grapple.y, -direction_to_grapple.x)
	var tangent_direction = tangent_dir_1 if self.velocity.dot(tangent_dir_1) > self.velocity.dot(tangent_dir_2) else tangent_dir_2
	var swing_force = tangent_direction * swing_strength * delta
	self.velocity += swing_force

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
#endregion
