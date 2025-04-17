extends Node

@export var enemy_scene: PackedScene
@export var spawn_points: Array[Node2D]
@export var spawn_interval: float = 2.0

var timer := 0.0
var max_enemies = 15
var CAN_SPAWN = true

func _process(delta):
	timer += delta
	if timer >= spawn_interval:
		timer = 0.0
		spawn_enemy()

func spawn_enemy():
	var num_enemies = get_tree().get_nodes_in_group("enemies").size()
	if enemy_scene and spawn_points.size() > 0 and num_enemies < max_enemies and CAN_SPAWN:
		var spawn_point = spawn_points.pick_random()
		var enemy = enemy_scene.instantiate()
		enemy.global_position = spawn_point.global_position
		get_tree().current_scene.add_child(enemy)

func delete_all_enemies():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		enemy.execute()
