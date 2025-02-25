extends Area2D

# Signal for detecting the player
signal player_detected(player)

# Called when another object enters the detection area
func _on_Area2D_area_entered(area):
	if area.is_in_group("player"):  # Ensure that you have a "player" group set for the player
		emit_signal("player_detected", area)
