extends CharacterBody2D

var speed: float = 100.0
var huntSpeed: float = 150.0
var turnSpeed = 2.0
enum ENEMY_STATE {PATROLLING, # 0
					 LOSING, # 1
					 HUNTING} # 2
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
#endregion

#region Get Direction w/ get_facing_direction, and hooks for entering / exiting vision code 
## Sets the enemies "forward" direction to be the vec between the frontMarker and self
func get_facing_direction() -> Vector2:
	directionFacing = frontMarker.global_position - self.global_position
	return directionFacing
	
## Runs once and hooks up player entering and exiting enemy visionCone
func _ready():
	visionCone.connect("body_entered", Callable(self, "_on_body_entered"))
	visionCone.connect("body_exited", Callable(self, "_on_body_exited"))

## function for when player ENTERS vision cone
func _on_body_entered(body):
	if body.name == "ball":  # Or however your player is named
		currentState = ENEMY_STATE.HUNTING # 2

## function for when player EXITS vision cone
func _on_body_exited(body):
	if body.name == "ball":
		currentState = ENEMY_STATE.LOSING # 1
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
	
	var to_player = player.global_position - global_position
	# Continually update lastKnownLocation for when enemy loses sight
	lastKnownLocation = player.global_position
	rotation = to_player.angle() + PI / 2 

	# Vector2.UP is (0, -1) → pointing up.
	# .rotated(rotation) turns it to match the direction the enemy is facing. as rotation = self.~objs cur angle 
	velocity = Vector2.UP.rotated(rotation) * huntSpeed

	move_and_slide()

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

## Function constally run for enemy
func _physics_process(delta):
	if player and is_instance_valid(player):
		stateActions(delta)
		
