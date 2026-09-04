extends Node2D

@onready var spawn_point: Marker2D = $SpawnPoint

# Path file scene karakter
const MELEE_ENEMY_SCENE = preload("res://Scene/Enemy/melee_enemy.tscn")
const RANGED_ENEMY_SCENE = preload("res://Scene/Enemy/ranged_enemy.tscn")

func _ready() -> void:
	if GameManager:
		GameManager.last_played_level = scene_file_path
	_spawn_player()
	_spawn_enemies()

func _spawn_player() -> void:
	var player_scene = preload("res://Sprites/player_sword.tscn")
	
	if GameManager.selected_weapon == GameManager.WeaponType.BOW:
		player_scene = preload("res://Sprites/player_archer.tscn")
		
	if not player_scene:
		push_error("Error: Scene player tidak ditemukan!")
		return
		
	# Instantiate player dan posisikan di SpawnPoint
	var player = player_scene.instantiate()
	player.global_position = spawn_point.global_position
	add_child(player)

func _spawn_enemies() -> void:
	var enemy_spawns = [
		{"scene": MELEE_ENEMY_SCENE, "pos": Vector2(450, 238)},
		{"scene": RANGED_ENEMY_SCENE, "pos": Vector2(700, 238)},
		{"scene": MELEE_ENEMY_SCENE, "pos": Vector2(880, 238)},
	]
	
	for spawn_info in enemy_spawns:
		if spawn_info["scene"]:
			var enemy = spawn_info["scene"].instantiate()
			enemy.global_position = spawn_info["pos"]
			add_child(enemy)

func cinematic_focus_to(target_pos: Vector2, zoom_target: Vector2 = Vector2(1.5, 1.5), duration: float = 0.8) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if not camera:
		return
		
	var target_offset: Vector2 = target_pos - camera.global_position + camera.offset
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "offset", target_offset, duration)
	tween.tween_property(camera, "zoom", zoom_target, duration)
