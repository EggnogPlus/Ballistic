extends CharacterBody2D

var speed: float = 100.0
var huntSpeed: float = 150.0
var turnSpeed = 2.0
enum ENEMY_STATE {PATROLLING, # 0
					 LOSING, # 1
					 HUNTING, # 2
					 BLIND_HUNT} # 3
# Blind
var blindHuntTimer = 0
var blindHuntLimit = 4

# Patrolling variables
var lastKnownLocation: Vector2
var mustHaveBeenTheWind = 3.0
var currentLostTime = 0.0

var patrolTime = 0.0
var maxPatrolTime = 3.0  # How long to move in one direction
var target_direction: Vector2

#region All @onready vars 
@onready var currentState = ENEMY_STATE.PATROLLING
@onready var directionFacing: Vector2
@onready var sprite = $Sprite2D 
@onready var frontMarker = $Area2D/frontMarker
@onready var visionCone = $Area2D
@onready var player = get_node_or_null("/root/Level/Player/ball")
@onready var navigationAgent: NavigationAgent2D = $NavigationAgent2D

#endregion

#region Get Direction w/ get_facing_direction, and hooks for entering / exiting vision code 
## Sets the enemies "forward" direction to be the vec between the frontMarker and self
func get_facing_direction() -> Vector2:
	directionFacing = frontMarker.global_position - self.global_position
	return directionFacing
	
## Runs once and hooks up player entering and exiting enemy visionCone plus wait for physics frame
func _ready():
	visionCone.connect("body_entered", Callable(self, "_on_body_entered"))
	visionCone.connect("body_exited", Callable(self, "_on_body_exited"))
	set_physics_process(false)
	call_deferred("waitForPhysics")
	
## Wait for physics frame and then set physics process back to true
func waitForPhysics():
	await get_tree().physics_frame
	set_physics_process(true)

## function for when player ENTERS vision cone
func _on_body_entered(body):
	if body.name == "ball":  # Or however your player is named
		currentState = ENEMY_STATE.HUNTING # 2

## function for when player EXITS vision cone
func _on_body_exited(body):
	if body.name == "ball":
		currentState = ENEMY_STATE.BLIND_HUNT # 3
#endregion

func set_new_patrol_target():
	var max_distance := 3000
	var random_offset = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(300, max_distance)
	var target = global_position + random_offset
	var nav_map = navigationAgent.get_navigation_map()
	var safe_point = NavigationServer2D.map_get_closest_point(nav_map, target)

	navigationAgent.target_position = safe_point




#region state movements

func patrolMovement(delta):
	if navigationAgent.is_navigation_finished():
		set_new_patrol_target()

	var path = navigationAgent.get_current_navigation_path() # full path
	var next_position = navigationAgent.get_next_path_position()
	
	# Avoid other enemies
	var enemies = get_tree().get_nodes_in_group("enemies")  # Assuming all enemies are in the "enemies" group
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
		var next_next_position = path[1]  # index 1 is the "next next" position
		# If super close to next position - skip it - avoid spinning
		if global_position.distance_to(to_next) < 50:
			print("TOO CLOSE")
			to_next = global_position.direction_to(next_next_position)

	var target_angle = to_next.angle() + PI / 2
	#rotation = lerp_angle(rotation, target_angle, turnSpeed * delta)
	
	var angle_diff = abs(wrapf(rotation - target_angle, -PI, PI))
	var effective_turn_speed = turnSpeed
	if global_position.distance_to(next_position) < 50:
		effective_turn_speed *= 3

	rotation = lerp_angle(rotation, target_angle, effective_turn_speed * delta)

	# Only move if mostly facing the target
	if angle_diff < 0.5:
		velocity = Vector2.UP.rotated(rotation) * speed
	else:
		velocity = Vector2.ZERO

	
	velocity = Vector2.UP.rotated(rotation) * speed
	move_and_slide()


func losingMovement(delta):
	# Move Toward Where player was last seen
	navigationAgent.target_position = lastKnownLocation
	
	# Move toward the next point along the path
	var next_position = navigationAgent.get_next_path_position()

	#var next_position = navigationAgent.get_next_path_position()
	var to_next = global_position.direction_to(next_position)
	
	# Smoothly rotate toward the next path point
	var desired_angle = to_next.angle() + PI / 2
	rotation = desired_angle

	# Apply movement using rotation-based direction (if you want the old "Vector2.UP" style)
	velocity = Vector2.UP.rotated(rotation) * huntSpeed
	
	# Wait mustHaveBeenTheWind time before returning to patrol state
	currentLostTime += delta
	if currentLostTime >= mustHaveBeenTheWind:
		# Lost Player
		currentState = ENEMY_STATE.PATROLLING
		currentLostTime = 0
	else:
		# Still searching
		currentState = ENEMY_STATE.LOSING
		
	
	move_and_slide()

func huntingMovement(delta):
	if not player:
		return

	# Update target destination
	navigationAgent.target_position = player.global_position
	
	# Continually update last locaiton
	lastKnownLocation = player.global_position
	
	if navigationAgent.is_navigation_finished():
		return
	
	# Move toward the next point along the path
	var next_position = navigationAgent.get_next_path_position()

	#var next_position = navigationAgent.get_next_path_position()
	var to_next = global_position.direction_to(next_position)
	
	# Smoothly rotate toward the next path point
	var desired_angle = to_next.angle() + PI / 2
	rotation = desired_angle

	# Apply movement using rotation-based direction (if you want the old "Vector2.UP" style)
	velocity = Vector2.UP.rotated(rotation) * huntSpeed
	
	move_and_slide()

func blindMovement(delta):
	blindHuntTimer += delta
	if (blindHuntTimer >= blindHuntLimit):
		# Lost Player
		currentState = ENEMY_STATE.LOSING
		blindHuntTimer = 0
	else:
		# Keep Hunting
		huntingMovement(delta)

#endregion

func stateActions(delta):
	get_facing_direction()
	match currentState:
		0: # PATROLLING
			sprite.modulate = Color(1, 1, 1)
			patrolMovement(delta)
		1: # LOSING
			sprite.modulate = Color(1, 0, 1)
			losingMovement(delta)
		2: # HUNTING
			sprite.modulate = Color(1, 0, 0)
			huntingMovement(delta)
		3: # BLIND_HUNT
			sprite.modulate = Color(0, 1, 0)
			blindMovement(delta)

## Function constally run for enemy
func _physics_process(delta):
	queue_redraw()
	if player and is_instance_valid(player):
		stateActions(delta)
		

## Draws Enemy Pathing --FYI drawn line does not dissapear
#func _draw():
	#if navigationAgent and not navigationAgent.is_navigation_finished():
		#var path = navigationAgent.get_current_navigation_path()
#
		#for i in range(path.size()):
			## Draw circle at each path point in global space, converted to local
			#var local_point = to_local(path[i])
			#draw_circle(local_point, 4, Color.GREEN)
#
			#if i < path.size() - 1:
				#var next_local_point = to_local(path[i + 1])
				#draw_line(local_point, next_local_point, Color.GREEN, 2)
