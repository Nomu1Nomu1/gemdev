extends Camera2D

@export var target: Node2D
var follow_target: bool = true

func _ready() -> void:
	# Jika target belum diisi di Inspector, cari player otomatis
	if target == null:
		target = get_tree().get_first_node_in_group("player")

func _process(_delta: float) -> void:
	# Setiap frame, posisi kamera akan selalu mengunci ke karakter
	if follow_target and target:
		global_position = target.global_position
