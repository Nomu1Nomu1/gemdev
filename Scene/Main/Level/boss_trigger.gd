extends Area2D

@export var boss_scene: PackedScene
@export var spawn_point: Marker2D

var has_triggered: bool = false

func _ready() -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if not (body.is_in_group("player") or body.name == "player_sword"):
		return

	if has_triggered:
		return

	has_triggered = true
	set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)
	
	_start_boss_intro.call_deferred(body)

func _start_boss_intro(player: Node2D) -> void:
	# 1. Bekukan player
	if "can_move" in player:
		player.can_move = false
	player.set_physics_process(false)
	if "velocity" in player:
		player.velocity = Vector2.ZERO

	# Cari kamera player
	var player_cam: Camera2D = player.get_node_or_null("Camera2D")

	# 2. Spawn Bos
	if boss_scene == null:
		push_error("Slot Boss Scene KOSONG di Inspector!")
		if "can_move" in player:
			player.can_move = true
		player.set_physics_process(true)
		return

	var boss_instance = boss_scene.instantiate()
	if spawn_point:
		boss_instance.global_position = spawn_point.global_position
	else:
		boss_instance.global_position = global_position + Vector2(250, 0)

	get_parent().add_child(boss_instance)

	# Tunggu 1 frame agar semua sub-node bos terdaftar di tree
	await get_tree().process_frame

	# Berikan referensi player & bangunkan AI bos
	boss_instance.player = player
	if boss_instance.has_method("wakeup_boss"):
		boss_instance.wakeup_boss()

	# 3. Pindah ke Kamera Bos
	var boss_cam: Camera2D = boss_instance.get_node_or_null("BossCamera")

	if boss_cam and boss_cam.is_inside_tree():
		boss_cam.enabled = true
		boss_cam.position_smoothing_enabled = true
		boss_cam.position_smoothing_speed = 4.0
		boss_cam.make_current()

		# Beri jeda kamera meluncur
		await get_tree().create_timer(0.8).timeout

		# Efek Shake
		var shake_tween = create_tween()
		for i in range(10):
			var offset_val = Vector2(randf_range(-7.0, 7.0), randf_range(-7.0, 7.0))
			shake_tween.tween_property(boss_cam, "offset", offset_val, 0.04)
		shake_tween.tween_property(boss_cam, "offset", Vector2.ZERO, 0.04)
		await shake_tween.finished
	else:
		push_warning("BossCamera belum siap di dalam tree atau tidak ditemukan!")

	# Jeda sejenak selama bos animasi bangun
	await get_tree().create_timer(1.2).timeout

	# 4. Kembalikan Kamera ke Player
	if player_cam and player_cam.is_inside_tree():
		player_cam.position_smoothing_enabled = true
		player_cam.position_smoothing_speed = 4.0
		player_cam.make_current()
		
		# Waktu kamera meluncur balik ke player
		await get_tree().create_timer(0.8).timeout

	# 5. Hubungkan UI Bar Bos
	var boss_ui = get_tree().get_first_node_in_group("boss_ui")
	if boss_ui and boss_instance:
		boss_ui.activate_boss_bar("EXECUTIONER", boss_instance.max_health)
		if boss_instance.has_signal("hp_changed"):
			boss_instance.hp_changed.connect(boss_ui.update_hp)
		if boss_instance.has_signal("boss_died"):
			boss_instance.boss_died.connect(boss_ui.hide_boss_bar)

	# 6. Buka kembali kontrol Player
	if "can_move" in player:
		player.can_move = true
	player.set_physics_process(true)
