extends Node2D

@onready var spawn_point: Marker2D = $SpawnPoint

# Scene karakter untuk jalur Archer (bow)
const PLAYER_SCENE = preload("res://Sprites/player_sword.tscn")
const MELEE_ENEMY_SCENE = preload("res://Scene/Enemy/melee_enemy.tscn")
const RANGED_ENEMY_SCENE = preload("res://Scene/Enemy/ranged_enemy.tscn")

func _ready() -> void:
	if GameManager:
		GameManager.last_played_level = scene_file_path
	_spawn_player()
	_spawn_enemies()

func _spawn_player() -> void:
	if not PLAYER_SCENE:
		push_error("Error: Scene res://Sprites/player_sword.tscn tidak ditemukan!")
		return
		
	# Instantiate player dan posisikan di SpawnPoint
	var player = PLAYER_SCENE.instantiate()
	player.global_position = spawn_point.global_position
	add_child(player)

	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if camera:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = 1200
		camera.limit_bottom = 650
		camera.reset_smoothing()

func _spawn_enemies() -> void:
	var enemy_spawns = [
		{"scene": MELEE_ENEMY_SCENE, "pos": Vector2(450, 238)},
		{"scene": RANGED_ENEMY_SCENE, "pos": Vector2(700, 238)},
		{"scene": MELEE_ENEMY_SCENE, "pos": Vector2(950, 238)},
		{"scene": RANGED_ENEMY_SCENE, "pos": Vector2(1100, 238)},
	]
	
	for spawn_info in enemy_spawns:
		if spawn_info["scene"]:
			var enemy = spawn_info["scene"].instantiate()
			enemy.global_position = spawn_info["pos"]
			add_child(enemy)

