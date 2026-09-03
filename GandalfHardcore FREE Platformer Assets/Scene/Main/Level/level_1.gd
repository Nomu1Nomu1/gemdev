extends Node2D

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var camera: Camera2D = $Camera2D

# Path file scene karakter
const PLAYER_SCENE = preload("res://GandalfHardcore FREE Platformer Assets/Sprites/player_sword.tscn")

func _ready() -> void:
	_spawn_player()

func _spawn_player() -> void:
	if not PLAYER_SCENE:
		push_error("Error: Scene res://player.tscn tidak ditemukan!")
		return
		
	# Instantiate player dan posisikan di SpawnPoint
	var player = PLAYER_SCENE.instantiate()
	player.global_position = spawn_point.global_position
	add_child(player)
	
	# Setup kamera agar halus dan menempel ke player
	if camera:
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 6.0
		camera.reparent(player)
		camera.position = Vector2.ZERO
