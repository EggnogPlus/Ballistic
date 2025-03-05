extends Sprite2D

func _ready():
	var collision_shape = get_parent().get_node("CollisionShape2D")  # Get sibling CollisionShape2D
	if collision_shape:
		fit_texture_to_collision(collision_shape)

func fit_texture_to_collision(collision_shape):
	if collision_shape.shape is RectangleShape2D:
		var shape_size = collision_shape.shape.size
		var texture_size = texture.get_size()

		# Calculate the scale factor
		var scale_x = shape_size.x / texture_size.x
		var scale_y = shape_size.y / texture_size.y

		# Apply the scale
		self.scale = Vector2(scale_x, scale_y)
