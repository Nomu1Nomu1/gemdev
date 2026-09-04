extends Node2D

@onready var spawn_point: Marker2D = $SpawnPoint

# TODO: belum ada scene karakter Archer (CharacterBody2D) sendiri di project ini,
# jadi untuk sementara tetap pakai player_sword.tscn supaya scene tidak kosong.
# Ganti PLAYER_SCENE ini begitu scene archer (mis. res://Sprites/player_archer.tscn) sudah dibuat.
const PLAYER_SCENE = preload("res://Sprites/player_sword.tscn")

func _ready() -> void:
	if GameManager:
		GameManager.last_played_level = scene_file_path
	_spawn_player()

func _spawn_player() -> void:
	if not PLAYER_SCENE:
		push_error("Error: Scene player untuk Archer tidak ditemukan!")
		return

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

