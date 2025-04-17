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

# Glow properties
var glow_radius: float = 12.5  # Radius of the glow circle (adjust to match player size)
var glow_width: float = 3.0    # Thickness of the glow line
var glow_color: Color = Color(1.0, 0.0, 0.0, 1.0)  # Red glow
var glow_points: int = 32      # Number of points for circle approximation

# Trail properties
var trail_length: float = 0.1 # Scale factor for trail lines (shorter than original 0.1)
var trail_width: float = 3    # Width of trail lines
var trail_offset: float = 5.0   # Offset distance for left/right lines
var trail_dash_length: float = 4.0  # Length of dashes
var trail_gap_length: float = 4.0   # Gap between dashes
var trail_color_slow: Color = Color(1.0, 1.0, 1.0, 1.0)  # white trail
var trail_color_fast: Color = Color(1.0, 0.0, 0.0, 1.0)  # Red trail
var trail_dash_offset: float = 3.0  # Forward/backward offset magnitude

@onready var mesh_instance_2d: MeshInstance2D = $MeshInstance2D
@onready var camera = get_viewport().get_camera_2d()
@onready var grapple_raycast_node: RayCast2D = get_node("/root/Level/Player/GrappleRaycast")
@onready var grapple_drawer: Node2D = get_node("/root/Level/Player/GrappleDrawer")
@onready var TimeOverlay = get_node("/root/Level/TimeOverlay")
@onready var EnemySpawner = get_node("/root/Level/EnemySpawner")
@onready var StartMenu = get_node("/root/Level/StartMenu")
@onready var GameOverMenu = get_node("/root/Level/GameOverMenu")

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
	if velocity.length() > execute_threshold and not is_grappling:
		can_execute = true
		mesh_instance_2d.modulate = Color(1, 1, 1)
	else:
		can_execute = false
		mesh_instance_2d.modulate = Color(1, 1, 1)
	
	# PLAYER INDICATOR TODO 
	if started_moving and global_position:
		if death_timer >= death_limit:
			die()
		else:
			if death_timer >= 2.5:
				mesh_instance_2d.modulate = Color(0.25, 0.25, 0.25)
			elif death_timer >= 1.5:
				mesh_instance_2d.modulate = Color(0.5, 0.5, 0.5)
			elif death_timer >= 0.5:
				mesh_instance_2d.modulate = Color(0.8, 0.8, 0.8)

	move_and_slide()
	check_for_enemy_execution()
	if started_moving:
		update_death_status(delta)
	
	queue_redraw()

func _draw():
	# Draw velocity trail (three red/white dotted lines)
	if velocity.length() > 0:
		var trail_color = trail_color_fast if can_execute else trail_color_slow
		var velocity_scaled = velocity * trail_length
		var trail_end = -velocity_scaled  # Trail behind the ball
		var perp_vector = Vector2(-velocity_scaled.y, velocity_scaled.x).normalized() * trail_offset
		var dir = (trail_end - Vector2.ZERO).normalized()
		
		# Draw three dashed lines: center, left, right with dynamic offsets
		for i in range(3):
			var offset = Vector2.ZERO
			if i == 1:
				offset = perp_vector
			elif i == 2:
				offset = -perp_vector
			
			# Apply cyclic offset to start/end points
			var time = float(Time.get_ticks_msec()) / 500.0  # Animate over time
			var dash_offset
			if i == 1:
				dash_offset = trail_dash_offset * cos(time * 5.0 + i * 2.0)  # Vary per line
			else:
				dash_offset = trail_dash_offset * sin(time * 5.0 + i * 2.0)  # Vary per line
				
			var start = offset + dir * dash_offset
			var end = trail_end + offset + dir * dash_offset
			
			draw_dashed_line(start, end, trail_color, trail_width, trail_dash_length, trail_gap_length)


#region Death & Execution AND apply_movement 

func die():
	queue_free()
	TimeOverlay.stop_timer()
	StartMenu.screen_saver_movement = true
	EnemySpawner.CAN_SPAWN = false
	GameOverMenu.visible = true

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
		pass

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
