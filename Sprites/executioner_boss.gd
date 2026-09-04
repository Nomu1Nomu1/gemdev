extends CharacterBody2D

enum State { WAKEUP, CHASE, ATTACK, SKILL, DEATH }
var current_state: State = State.WAKEUP

@export var speed: float = 45.0
@export var max_health: int = 150
@export var attack_damage: int = 20
var current_health: int

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
	if (body.is_in_group("player") or body.name == "player_sword") and current_state == State.CHASE:
		_start_attack()

func _start_attack() -> void:
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
			
			# Cek apakah player masih ada di dalam AttackRange
			var bodies = attack_range.get_overlapping_bodies()
			var player_still_inside: bool = false
			for b in bodies:
				if b.is_in_group("player") or b.name == "player_sword":
					player_still_inside = true
					break
			
			if player_still_inside:
				# Cooldown singkat sebelum tebasan berikutnya
				await get_tree().create_timer(0.3).timeout
				if current_state == State.ATTACK:
					_start_attack()
			else:
				current_state = State.CHASE

		"skill":
			current_state = State.CHASE

		"death":
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

	if attacker:
		var knock_dir: float = sign(global_position.x - attacker.global_position.x)
		velocity.x = knock_dir * 80.0

	if current_health <= 0:
		current_state = State.DEATH
		velocity = Vector2.ZERO
		if hitbox_collision:
			hitbox_collision.set_deferred("disabled", true)
		sprite.play("death")

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
					
			
