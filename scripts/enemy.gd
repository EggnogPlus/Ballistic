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
	

#region state movements

func patrolMovement(delta):
	patrolTime += 1.0 / Engine.get_frames_per_second()

	if patrolTime >= maxPatrolTime or target_direction == Vector2.ZERO:
		patrolTime = 0.0
		maxPatrolTime = randf_range(1.5, 3.0)
		
		# Generate a random unit vector (direction)
		var rand_angle = randf_range(0, TAU)
		target_direction = Vector2.RIGHT.rotated(rand_angle).normalized()

	# Smoothly rotate toward the direction
	var target_angle = target_direction.angle() + PI / 2
	rotation = lerp_angle(rotation, target_angle, turnSpeed * delta)

	# 🚨 Move in the direction you chose (not based on UP anymore)
	velocity = target_direction * speed
	move_and_slide()

func losingMovement(delta):
	# Move Toward Where player was last seen
	var to_last_seen_player = lastKnownLocation - global_position
	rotation = to_last_seen_player.angle() + PI / 2 
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
	
	# Move toward the next point along the path
	var next_position = 0
	if not navigationAgent.is_navigation_finished():
		next_position = navigationAgent.get_next_path_position()

	#var next_position = navigationAgent.get_next_path_position()
	var to_next = global_position.direction_to(next_position)
	
	# Smoothly rotate toward the next path point
	var desired_angle = to_next.angle() + PI / 2
	rotation = desired_angle

	# Apply movement using rotation-based direction (if you want the old "Vector2.UP" style)
	velocity = Vector2.UP.rotated(rotation) * huntSpeed
	
	#region old hunting movement code
	#var to_player = player.global_position - global_position
	## Continually update lastKnownLocation for when enemy loses sight
	#lastKnownLocation = player.global_position
	#rotation = to_player.angle() + PI / 2 
#
	## Vector2.UP is (0, -1) → pointing up.
	## .rotated(rotation) turns it to match the direction the enemy is facing. as rotation = self.~objs cur angle 
	#velocity = Vector2.UP.rotated(rotation) * huntSpeed
	#endregion

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
		
		
func _draw():
	if navigationAgent and not navigationAgent.is_navigation_finished():
		var path = navigationAgent.get_current_navigation_path()
		
		for i in range(path.size()):
			# Convert world path point to local rotated space
			var local_point = (path[i] - global_position).rotated(-rotation)
			
			draw_circle(local_point, 4, Color.GREEN)
			
			if i < path.size() - 1:
				var next_local_point = (path[i + 1] - global_position).rotated(-rotation)
				draw_line(local_point, next_local_point, Color.GREEN, 2)
