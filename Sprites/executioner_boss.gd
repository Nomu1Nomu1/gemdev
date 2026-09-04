extends CharacterBody2D

enum State { WAKEUP, CHASE, ATTACK, SKILL, DEATH }
var current_state: State = State.WAKEUP
signal hp_changed(new_hp: int)
signal boss_died

@export var speed: float = 45.0
@export var max_health: int = 150
@export var attack_damage: int = 0
var current_health: int

@export var attack_cooldown: float = 1.5
var can_attack: bool = true

var player: CharacterBody2D = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_range: Area2D = $AttackRange
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_collision: CollisionShape2D = $Hitbox/CollisionShape2D

func _ready() -> void:
	current_health = max_health
	if hitbox_collision:
		hitbox_collision.disabled = true
	
	player = get_tree().get_first_node_in_group("player")
	
	# Sambungkan sinyal animasi
	sprite.animation_finished.connect(_on_animation_finished)

	current_state = State.WAKEUP
	velocity = Vector2.ZERO
	sprite.play("wakeup")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	match current_state:
		State.WAKEUP, State.ATTACK, State.SKILL, State.DEATH:
			velocity.x = 0

		State.CHASE:
			if player:
				var diff_x: float = player.global_position.x - global_position.x
				
				# Beri deadzone sebesar 8 pixel agar tidak bolak-balik saat tumpang-tindih
				if abs(diff_x) > 8.0:
					var dir: float = sign(diff_x)
					velocity.x = dir * speed
					
					# Balik arah hadap bos dan hitbox
					sprite.flip_h = (dir < 0)
					attack_range.scale.x = -1.0 if dir < 0 else 1.0
					hitbox.scale.x = -1.0 if dir < 0 else 1.0
				else:
					# Berhenti melangkah jika sudah tepat di tengah player
					velocity.x = 0.0
					
				sprite.play("idle")
	move_and_slide()

# Terpicu saat player melangkah masuk ke jangkauan sabit bos
func _on_attack_range_body_entered(body: Node2D) -> void:
	if (body.is_in_group("player") or body.name == "player_sword"):
		if current_state == State.CHASE and can_attack:
			_start_attack()

func _start_attack() -> void:
	can_attack = false # Kunci serangan
	current_state = State.ATTACK
	velocity.x = 0.0
	if hitbox_collision:
		hitbox_collision.set_deferred("disabled", true)
	sprite.play("attack")


# 2. Penanganan Animasi Selesai & Re-Attack Otomatis
func _on_animation_finished() -> void:
	match sprite.animation:
		"wakeup":
			current_state = State.CHASE

		"attack":
			if hitbox_collision:
				hitbox_collision.set_deferred("disabled", true)
			
			# Kembalikan bos ke mode kejar/idle dulu
			current_state = State.CHASE
			sprite.play("idle")
			
			# Mulai jeda cooldown antar serangan
			await get_tree().create_timer(attack_cooldown).timeout
			can_attack = true # Buka kunci serangan
			
			# Jika player masih diam menempel di dalam jangkauan sabit, serang lagi
			if current_state == State.CHASE:
				for b in attack_range.get_overlapping_bodies():
					if b.is_in_group("player") or b.name == "player_sword":
						_start_attack()
						break

		"skill":
			current_state = State.CHASE

		"death":
			# 1. Ambil kamera aktif
			var camera: Camera2D = get_viewport().get_camera_2d()
			if camera:
				var cam_reset = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				# Kembalikan zoom ke default (sesuaikan jika zoom default gamemu bukan 1.0)
				cam_reset.tween_property(camera, "zoom", Vector2(1.0, 1.0), 0.8)
				cam_reset.tween_property(camera, "offset", Vector2.ZERO, 0.8)
				
				# TUNGGU sampai tween selesai sebelum menghapus bos
				await cam_reset.finished
			
			# 2. Hapus node bos setelah kamera aman kembali ke posisi semula
			queue_free()

# Menghantarkan damage ke player
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "player_sword":
		if body.has_method("take_damage"):
			body.take_damage(attack_damage, self)
		elif "current_hp" in body:
			body.current_hp -= attack_damage
		elif "health" in body:
			body.health -= attack_damage
# Menerima damage saat ditebas player
func take_damage(amount: int, attacker: Node2D = null) -> void:
	if current_state == State.DEATH:
		return
	current_health -= amount
	current_health = max(0, current_health)

	# Kirim sisa HP ke UI
	hp_changed.emit(current_health)

	if attacker:
		var knock_dir: float = sign(global_position.x - attacker.global_position.x)
		velocity.x = knock_dir * 80.0

	if current_health <= 0:
		current_state = State.DEATH
		velocity = Vector2.ZERO
		if hitbox_collision:
			hitbox_collision.set_deferred("disabled", true)
		
		boss_died.emit()
		
		# --- EFEK KAMERA FOKUS KE BOS ---
		_focus_camera_on_boss_death()
		sprite.play("death")
		
func _focus_camera_on_boss_death() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera:
		# Hitung offset agar kamera tepat menghadap ke tengah badan bos
		var target_offset = global_position - camera.global_position + camera.offset
		
		# Efek zoom in dan pergeseran fokus
		var cam_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		cam_tween.tween_property(camera, "offset", target_offset, 0.7)
		cam_tween.tween_property(camera, "zoom", Vector2(1.5, 1.5), 0.7)
		
		# Opsional: Slow motion sesaat agar kematian bos terasa klimaks
		Engine.time_scale = 0.4
		await get_tree().create_timer(0.4 * 0.4).timeout # Tunggu dalam hitungan real-time
		Engine.time_scale = 1.0

func _on_animated_sprite_2d_frame_changed() -> void:
	if current_state == State.ATTACK and sprite.animation == "attack":
		match sprite.frame:
			2:
				# Ganti angka 3 ke index frame saat sabit mengayun
				if hitbox_collision:
					hitbox_collision.set_deferred("disabled", false)
			4:
				# Ganti angka 4 ke index frame setelah sabit lewat
				if hitbox_collision:
					hitbox_collision.set_deferred("disabled", true)
					
			9:
				# Ganti angka 3 ke index frame saat sabit mengayun
				if hitbox_collision:
					hitbox_collision.set_deferred("disabled", false)
			12:
				# Ganti angka 4 ke index frame setelah sabit lewat
				if hitbox_collision:
					hitbox_collision.set_deferred("disabled", true)
					
			
