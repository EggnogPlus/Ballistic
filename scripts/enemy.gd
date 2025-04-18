extends CharacterBody2D

var speed: float = 100.0
var hunt_speed: float = 200.0
var turn_speed = 2.0
enum ENEMY_STATE {PATROLLING, # 0
					 LOSING, # 1
					 HUNTING, # 2
					 BLIND_HUNT} # 3

# Blind Hunt Variables
var blind_hunt_timer = 0
var blind_hunt_limit = 4

# Patrolling variables
var last_known_location: Vector2
var must_have_been_the_wind = 3.0
var current_lost_time = 0.0

#region All @onready vars 
@onready var current_state = ENEMY_STATE.PATROLLING
@onready var sprite = $Sprite2D 
@onready var front_marker = $Area2D/frontMarker
@onready var vision_cone = $Area2D
@onready var player = get_node_or_null("/root/Level/Player/ball")
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var start_menu = get_node("../StartMenu")

#endregion

#region Get Direction w/ get_facing_direction, and hooks for entering / exiting vision code 
## Runs once and hooks up player entering and exiting enemy vision_cone plus wait for physics frame
func _ready():
	vision_cone.connect("body_entered", Callable(self, "_on_body_entered"))
	vision_cone.connect("body_exited", Callable(self, "_on_body_exited"))
	set_physics_process(false)
	call_deferred("waitForPhysics")
	
## Wait for physics frame and then set physics process back to true
func waitForPhysics():
	await get_tree().physics_frame
	set_physics_process(true)

## function for when player ENTERS vision cone
func _on_body_entered(body):
	if body.name == "ball":
		current_state = ENEMY_STATE.HUNTING # 2

## function for when player EXITS vision cone
func _on_body_exited(body):
	if body.name == "ball":
		current_state = ENEMY_STATE.BLIND_HUNT # 3
#endregion

## Sets new patrol target from a random angled far away point then cap it within the nav region 
func set_new_patrol_target():
	var max_distance := 3000
	var random_offset = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(300, max_distance)
	var target = global_position + random_offset
	var nav_map = navigation_agent.get_navigation_map()
	var safe_point = NavigationServer2D.map_get_closest_point(nav_map, target) # Cap within navigation region
	navigation_agent.target_position = safe_point

#region State movements

func patrolMovement(delta):
	if navigation_agent.is_navigation_finished():
		set_new_patrol_target()

	var path = navigation_agent.get_current_navigation_path() # full path
	var next_position = navigation_agent.get_next_path_position() # next path "point"
	
	# Avoid other enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	var avoidance_vector = Vector2.ZERO
	for enemy in enemies:
		if enemy != self and global_position.distance_to(enemy.global_position) < 100:
			var repulsion = (global_position - enemy.global_position).normalized() * 100
			avoidance_vector += repulsion
	next_position += avoidance_vector
	
	var to_next = global_position.direction_to(next_position)
	
	# Avoid spinning if we're too close to the point
	if global_position.distance_to(next_position) < 5:
		set_new_patrol_target()
		return
		
	# Avoid spinning if next dot is too close
	if path.size() > 1:
		# If super close to next position - pick new target - wiggle solution
		if global_position.distance_to(to_next) < 50:
			set_new_patrol_target()
	
	var target_angle = to_next.angle() + PI / 2	
	var angle_diff = abs(wrapf(rotation - target_angle, -PI, PI))
	var effective_turn_speed = turn_speed
	
	# Turn fasted if close to next path point
	if global_position.distance_to(next_position) < 50:
		effective_turn_speed *= 3
	
	# Smooth rotation
	rotation = lerp_angle(rotation, target_angle, effective_turn_speed * delta)

	# Only move if mostly facing the target - avoid weird snaking
	if angle_diff < 0.5:
		velocity = Vector2.UP.rotated(rotation) * speed
	else:
		velocity = Vector2.ZERO

	
	velocity = Vector2.UP.rotated(rotation) * speed
	move_and_slide()

func losingMovement(delta):	
	# Move Toward Where player was last seen
	navigation_agent.target_position = last_known_location
	
	var next_position = navigation_agent.get_next_path_position()

	var to_next = global_position.direction_to(next_position)
	
	# Smoothly rotate toward the next path point
	var desired_angle = to_next.angle() + PI / 2
	rotation = desired_angle

	# Apply movement using rotation-based direction
	velocity = Vector2.UP.rotated(rotation) * hunt_speed
	
	# Wait must_have_been_the_wind time before returning to patrol state
	current_lost_time += delta
	if current_lost_time >= must_have_been_the_wind:
		# Lost Player
		current_state = ENEMY_STATE.PATROLLING
		current_lost_time = 0
	else:
		# Still searching
		current_state = ENEMY_STATE.LOSING
	
	move_and_slide()

func huntingMovement(delta):
	# If player does not exist - return to patrolling
	if not player:
		current_state = ENEMY_STATE.PATROLLING
		return
	
	# Update target destination
	navigation_agent.target_position = player.global_position
	
	# Continually update last locaiton for if "lost" player
	last_known_location = player.global_position
	
	if navigation_agent.is_navigation_finished():
		return
	
	# Move toward the next point along the path
	var next_position = navigation_agent.get_next_path_position()
	
	var to_next = global_position.direction_to(next_position)
	
	# Smoothly rotate toward the next path point
	var desired_angle = to_next.angle() + PI / 2
	rotation = desired_angle
	
	# Apply movement using rotation-based direction
	velocity = Vector2.UP.rotated(rotation) * hunt_speed
	
	move_and_slide()

func blindMovement(delta):
	blind_hunt_timer += delta
	if (blind_hunt_timer >= blind_hunt_limit):
		# Lost Player
		current_state = ENEMY_STATE.LOSING
		blind_hunt_timer = 0
	else:
		# Keep Hunting
		huntingMovement(delta)

#endregion

## Function that calls the correct enemy movement function depenging on the state 
func stateActions(delta):
	match current_state:
		0: # PATROLLING
			sprite.modulate = Color(1, 1, 1)
			patrolMovement(delta)
		1: # LOSING
			sprite.modulate = Color(0.5, 0.5, 0.5)
			losingMovement(delta)
		2: # HUNTING
			sprite.modulate = Color(1, 0, 0)
			huntingMovement(delta)
		3: # BLIND_HUNT
			sprite.modulate = Color(0.6, 0, 0)
			blindMovement(delta)

## Function constally run for enemy
func _physics_process(delta):
	queue_redraw()

	if not is_instance_valid(player):
		var possible_player = get_node_or_null("/root/Level/Player/ball")
		if possible_player:
			player = possible_player
	
	# Have enemies move if on Start/About page (screen saver patrolling) OR
	# if player exists 
	if start_menu.screen_saver_movement or (player and is_instance_valid(player)):
		stateActions(delta)

## remove from group to allow more spawning then free the node
func execute():
	if is_in_group("enemies"):
		remove_from_group("enemies")
	queue_free()

#region Draws Enemy Pathing --FYI drawn line does not dissapear
#func _draw():
	#if navigation_agent and not navigation_agent.is_navigation_finished():
		#var path = navigation_agent.get_current_navigation_path()
#
		#for i in range(path.size()):
			## Draw circle at each path point in global space, converted to local
			#var local_point = to_local(path[i])
			#draw_circle(local_point, 4, Color.GREEN)
#
			#if i < path.size() - 1:
				#var next_local_point = to_local(path[i + 1])
				#draw_line(local_point, next_local_point, Color.GREEN, 2)
#endregion
