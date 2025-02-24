extends CharacterBody2D

# Variables to adjust the movement and rolling behavior
var MAX_SPEED: float = 700 # Max Speed of the ball
var BASE_SPEED: float = 100 # Default speed of ball
var friction: float = 0.05 # Friction of the ball (slows down momentum over time)
var torque_strength: float = 10 # How strong the rolling torque is
var max_velocity: float = 4000 # Max velocity the ball can reach
var multix: float = 0 # Momentum Multiplier*
# Movement vector
var velocity_vector: Vector2 = Vector2.ZERO

# Previous Input Vector
var current_vector = Vector2.ZERO

func buildSpeed(input_vector, reset):
	
	if reset == 1:
		multix = 0
	else:
		multix += 1
	
	return input_vector * (BASE_SPEED + multix)

func _physics_process(delta):
	# Get time for debugging
	var time = Time.get_time_dict_from_system()
	
	# Get input for movement
	var input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("ui_left"):
		input_vector.x = -1
	elif Input.is_action_pressed("ui_right"):
		input_vector.x = 1
	
	if Input.is_action_pressed("ui_up"):
		input_vector.y = -1
	elif Input.is_action_pressed("ui_down"):
		input_vector.y = 1
	
	# Normalize the direction to prevent diagonal speed boost
	input_vector = input_vector.normalized()

	# If there's input, apply force in that direction
	if input_vector != Vector2.ZERO:
		if input_vector != current_vector:
			# Make new vector the NEW current vector
			input_vector = current_vector
			# Reset the gained momentum
			velocity_vector = velocity_vector.lerp(buildSpeed(input_vector, 1), 0.1)
			print("new vector")
		else:
			velocity_vector = velocity_vector.lerp(buildSpeed(input_vector, 0), 0.1)
			print("Same vector ###")

	# Apply momentum by maintaining velocity even when no input is given
	if input_vector == Vector2.ZERO:
		# Apply friction to slow down the ball naturally
		velocity_vector = velocity_vector.lerp(Vector2.ZERO, friction)

	# Limit velocity to avoid excessive speed
	if velocity_vector.length() > max_velocity:
		velocity_vector = velocity_vector.normalized() * max_velocity

	# Move the ball using the velocity vector
	velocity = velocity_vector

	# Call move_and_slide to move the character using velocity
	move_and_slide()
