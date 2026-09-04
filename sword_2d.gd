extends Node2D

@onready var spawn_point: Marker2D = $SpawnPoint

# Scene karakter untuk jalur Vanguard (sword)
const PLAYER_SCENE = preload("res://Sprites/player_sword.tscn")

func _ready() -> void:
	_spawn_player()

func _spawn_player() -> void:
	if not PLAYER_SCENE:
		push_error("Error: Scene res://Sprites/player_sword.tscn tidak ditemukan!")
		return

	var player = PLAYER_SCENE.instantiate()
	player.global_position = spawn_point.global_position
	add_child(player)

	# Konfigurasi batas kamera agar fokus dan sejajar dengan tanah & karakter
	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if camera:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = 1200
		camera.limit_bottom = 650
		camera.reset_smoothing()
