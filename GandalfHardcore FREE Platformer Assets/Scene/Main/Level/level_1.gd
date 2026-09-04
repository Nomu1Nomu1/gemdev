extends Node2D

@onready var spawn_point: Marker2D = $SpawnPoint

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
	

func cinematic_focus_to(target_pos: Vector2, zoom_target: Vector2 = Vector2(1.5, 1.5), duration: float = 0.8) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if not camera:
		return
		
	# Hitung selisih posisi target relatif terhadap anchor kamera saat ini
	var target_offset: Vector2 = target_pos - camera.global_position + camera.offset
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "offset", target_offset, duration)
	tween.tween_property(camera, "zoom", zoom_target, duration)
