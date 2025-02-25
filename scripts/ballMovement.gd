extends CharacterBody2D

# Variables to adjust the movement and rolling behavior
var MAX_SPEED: float = 700 # Max Speed of the ball
var BASE_SPEED: float = 100 # Default speed of ball
var friction: float = 0.05 # Friction of the ball (slows down momentum over time)
var torque_strength: float = 10 # How strong the rolling torque is
var max_velocity: float = 4000 # Max velocity the ball can reach
var multix: float = 0 # Momentum Multiplier
# Movement vector
var velocity_vector: Vector2 = Vector2.ZERO

# Previous Input Vector
var current_vector = Vector2.ZERO

# Time accumulator for momentum buildup
var momentum_accumulator: float = 0.0
var momentum_increase_rate: float = 50.0 # The rate at which momentum increases

func buildSpeed(input_vector, reset):
	if reset == 1:
		momentum_accumulator = 0.0 # Reset momentum when there's no input
	else:
		# Increase momentum over time when input is held
		momentum_accumulator += momentum_increase_rate * get_process_delta_time()
	
	# Increase speed based on momentum
	var speed = BASE_SPEED + momentum_accumulator
	return input_vector * speed

func _physics_process(delta):
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
		current_vector = input_vector  # Update current_vector with new input
		velocity_vector = velocity_vector.lerp(buildSpeed(input_vector, 0), 0.1)
	else:
		#velocity_vector = velocity_vector.lerp(Vector2.ZERO, 0.1)
		# Apply friction to slow down the ball naturally when there's no input
		velocity_vector *= (1 - friction)

	# Move the ball using the velocity vector
	velocity = velocity_vector

	# Call move_and_slide to move the character using velocity
	move_and_slide()
