extends CharacterBody2D

var speed: float = 100.0
var turnSpeed = 5.0
enum ENEMY_STATE {PATROLLING, # 0
					 LOSING, # 1
					 HUNTING} # 2
var currentState = ENEMY_STATE.PATROLLING

var directionFacing: Vector2
@onready var sprite = $Sprite2D 
@onready var frontMarker = $Area2D/frontMarker
@onready var visionCone = $Area2D

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
		print("Player entered vision cone!")
		currentState = ENEMY_STATE.HUNTING # 2

## function for when player EXITS vision cone
func _on_body_exited(body):
	if body.name == "ball":
		print("Player exited vision cone!")
		currentState = ENEMY_STATE.LOSING # 1
#endregion

#region state movements

func patrolMovement():
	pass

func losingMovement():
	velocity = Vector2.ZERO
	move_and_slide()

func huntingMovement(player, delta):
	# Calculate the direction vector from the enemy to the player
	var direction = player.global_position - global_position
	
	# Debug: Print direction to verify player position
	print("Hunting: direction to player=", direction)

	# Move toward the player
	velocity = direction.normalized() * speed
	
	# Debug: Print velocity to confirm movement
	print("Hunting: velocity=", velocity)

	# Calculate the angle to face the player
	var targetAngle = direction.angle()
	
	# Adjust rotation to face the player
	# If sprite faces left at rotation=0, uncomment the next line
	# targetAngle += PI
	
	# Option 1: Smooth rotation (uncomment for smooth turning)
	# rotation = lerp_angle(rotation, targetAngle, turnSpeed * delta)
	
	# Option 2: Instant rotation (as per your latest attempt)
	rotation = targetAngle
	
	# Debug: Print rotation to confirm
	print("Hunting: rotation=", rad_to_deg(rotation), " degrees, targetAngle=", rad_to_deg(targetAngle), " degrees")
	
	# Ensure sprite aligns with rotation (optional if sprite inherits rotation)
	sprite.rotation = rotation
	
	# Move the enemy
	move_and_slide()



#endregion

func stateActions(player, delta):
	get_facing_direction()
	match currentState:
		0: # PATROLLING
			patrolMovement()
		1: # LOSING
			losingMovement()
		2: # HUNTING
			huntingMovement(player, delta)

## Function constally run for enemy
func _physics_process(delta):
	var player = get_node_or_null("/root/Level/Player/ball")
	if player and is_instance_valid(player):
		stateActions(player, delta)
		
