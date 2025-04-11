extends CharacterBody2D

var speed: float = 100.0
var turnSpeed = 5.0
enum ENEMY_STATE {PATROLLING, # 0
					 LOSING, # 1
					 HUNTING} # 2
@onready var currentState = ENEMY_STATE.PATROLLING

@onready var directionFacing: Vector2
@onready var sprite = $Sprite2D 
@onready var frontMarker = $Area2D/frontMarker
@onready var visionCone = $Area2D
@onready var player = get_node_or_null("/root/Level/Player/ball")

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

func patrolMovement():
	pass

func losingMovement():
	velocity = Vector2.ZERO
	move_and_slide()

func huntingMovement(delta):
	if not player:
		return
		
	# Calculate angle to player
	var to_player = player.global_position - global_position
	rotation = to_player.angle() + PI / 2  # Adjust based on your sprite's "forward"

	# Vector2.UP is (0, -1) → pointing up.
	# .rotated(rotation) turns it to match the direction the enemy is facing. as rotation = self.~objs cur angle 
	velocity = Vector2.UP.rotated(rotation) * speed

	move_and_slide()

#endregion

func stateActions(delta):
	get_facing_direction()
	match currentState:
		0: # PATROLLING
			patrolMovement()
		1: # LOSING
			losingMovement()
		2: # HUNTING
			huntingMovement(delta)

## Function constally run for enemy
func _physics_process(delta):
	if player and is_instance_valid(player):
		stateActions(delta)
		
