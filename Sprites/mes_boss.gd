extends BaseBoss

enum State { SLEEP, WAKEUP, CHASE, ATTACK, SKILL, DEATH }
var current_state: State = State.SLEEP

@export var speed: float = 90.0
@export var attack_damage: int = 20
@export var skill_damage: int = 30
@export var skill_dash_speed: float = 280.0
@export var skill_cooldown: float = 6.0

var can_skill: bool = true
var is_busy: bool = false
var current_damage_output: int = 0
var player_in_attack_range: bool = false
var player: CharacterBody2D = null

# Arah hadap terakhir (1 = kanan, -1 = kiri)
var facing_dir: float = 1.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_range: Area2D = $AttackRange
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var boss_camera: Camera2D = $BossCamera

func _ready() -> void:
	super._ready()
	
	boss_camera.enabled = false
	hitbox_shape.disabled = true
	
	# Hubungkan sinyal jika belum tersambung via editor
	if not attack_range.body_entered.is_connected(_on_attack_range_body_entered):
		attack_range.body_entered.connect(_on_attack_range_body_entered)
	if not attack_range.body_exited.is_connected(_on_attack_range_body_exited):
		attack_range.body_exited.connect(_on_attack_range_body_exited)
	if not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
		hitbox.body_entered.connect(_on_hitbox_body_entered)
	if not sprite.animation_finished.is_connected(_on_animation_finished):
		sprite.animation_finished.connect(_on_animation_finished)
	
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	if is_dead or current_state == State.SLEEP:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	# Jangan izinkan navigasi baru jika sedang animasi bangun atau terkunci aksi
	if current_state == State.WAKEUP or is_busy:
		move_and_slide()
		return

	if player:
		var diff_x = player.global_position.x - global_position.x
		var distance = global_position.distance_to(player.global_position)
		
		# --- DEADZONE FIX (Mencegah sprite berkedip bolak-balik saat pemain di tengah) ---
		if abs(diff_x) > 12.0:
			facing_dir = sign(diff_x)
			sprite.flip_h = (facing_dir < 0)
			attack_range.scale.x = facing_dir
			hitbox.scale.x = facing_dir

		# Prioritas aksi AI
		if can_skill and distance > 140.0:
			_use_skill(facing_dir)
		elif player_in_attack_range:
			_perform_attack()
		else:
			_chase_player(facing_dir)

	move_and_slide()

# --- FUNGSI AKSI ---

func wakeup_boss() -> void:
	current_state = State.WAKEUP
	is_busy = true
	can_skill = false # Kunci skill agar tidak langsung dash begitu bangun
	velocity = Vector2.ZERO
	sprite.play("wakeup")
	
	# Buka skill setelah beberapa detik game berjalan
	get_tree().create_timer(4.0).timeout.connect(func(): can_skill = true)
	
	# Failsafe jika sinyal animasi macet
	await get_tree().create_timer(1.2).timeout
	if current_state == State.WAKEUP and not is_dead:
		_finish_wakeup()

func _finish_wakeup() -> void:
	# 1. Tahan bos dalam kondisi sibuk agar tidak langsung mengejar/menyerang
	is_busy = true
	velocity = Vector2.ZERO
	sprite.play("idle")
	
	# 2. Berikan jeda waktu (misal 1.0 detik) agar pemain punya waktu bersiap
	await get_tree().create_timer(1.0).timeout
	
	# 3. Setelah jeda selesai, baru aktifkan mode serang/kejar
	if not is_dead:
		is_busy = false
		current_state = State.CHASE

func _chase_player(dir_x: float) -> void:
	velocity.x = dir_x * speed
	if sprite.animation != "chase" or not sprite.is_playing():
		sprite.play("chase")

func _perform_attack() -> void:
	is_busy = true
	velocity.x = 0
	current_state = State.ATTACK
	current_damage_output = attack_damage
	sprite.play("attack")
	
	# Waktu ayunan serangan
	await get_tree().create_timer(0.25).timeout
	if not is_dead and current_state == State.ATTACK:
		hitbox_shape.disabled = false
		
	await get_tree().create_timer(0.2).timeout
	hitbox_shape.disabled = true

	# Jeda sebelum bos bisa bergerak lagi
	await get_tree().create_timer(0.3).timeout
	if current_state == State.ATTACK and not is_dead:
		is_busy = false
		current_state = State.CHASE

func _use_skill(dir_x: float) -> void:
	is_busy = true
	can_skill = false
	current_state = State.SKILL
	current_damage_output = skill_damage
	sprite.play("skill")
	
	# Dash menerjang
	velocity.x = dir_x * skill_dash_speed
	hitbox_shape.disabled = false
	
	await get_tree().create_timer(0.4).timeout
	velocity.x = 0
	hitbox_shape.disabled = true
	is_busy = false
	current_state = State.CHASE
	
	# Timer cooldown di latar belakang
	await get_tree().create_timer(skill_cooldown).timeout
	can_skill = true

func _die() -> void:
	super._die()
	current_state = State.DEATH
	velocity = Vector2.ZERO
	hitbox_shape.set_deferred("disabled", true)
	sprite.play("death")

# --- SINYAL & DETEKSI ---

func _on_animation_finished() -> void:
	if is_dead:
		return

	if sprite.animation == "wakeup":
		_finish_wakeup()
	elif sprite.animation in ["attack", "skill"]:
		is_busy = false
		hitbox_shape.disabled = true
		current_state = State.CHASE

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body == player:
		player_in_attack_range = true

func _on_attack_range_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_attack_range = false

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body == self:
		return
	# Berikan damage ke player jika memiliki fungsi take_damage
	if body.has_method("take_damage"):
		body.take_damage(current_damage_output, self)
