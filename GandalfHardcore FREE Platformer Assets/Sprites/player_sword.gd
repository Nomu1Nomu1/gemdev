extends CharacterBody2D

# --- Parameter Pergerakan & Status ---
@export var walk_speed: float = 130.0
@export var run_speed: float = 210.0
@export var jump_velocity: float = -350.0
@export var max_health: int = 100

var current_health: int = 100
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- Parameter Tameng / Stamina ---
@export var max_shield_stamina: float = 100.0
var current_shield_stamina: float = 100.0
var shield_drain_rate: float = 20.0        # Berkurang saat menahan block
var shield_regen_rate: float = 8.0         # Kecepatan regen pasif (dibuat lambat)
var shield_hit_restore: float = 25.0       # Bonus stamina saat tebasan kena musuh

var regen_delay_timer: float = 0.0
var regen_delay_duration: float = 1.5      # Jeda waktu (detik) sebelum regen pasif mulai
var is_shield_broken: bool = false

# --- Referensi Node Karakter ---
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var visuals: Node2D = $Visuals
@onready var shield: Sprite2D = $Visuals/Shield
@onready var attack_area: Area2D = $Visuals/AttackArea
@onready var attack_shape: CollisionShape2D = $Visuals/AttackArea/CollisionShape2D

@onready var health_bar: ProgressBar = $CanvasLayer/HUD/PlayerStatus/PanelContainer/StatusRow/BarsContainer/HealthBar
@onready var shield_bar: ProgressBar = $CanvasLayer/HUD/PlayerStatus/PanelContainer/StatusRow/BarsContainer/ShieldBar

var is_attacking: bool = false
var is_blocking: bool = false
var default_shield_pos: Vector2

func _ready() -> void:
	current_health = max_health
	current_shield_stamina = max_shield_stamina
	default_shield_pos = shield.position
	
	health_bar.max_value = max_health
	health_bar.value = current_health
	shield_bar.max_value = max_shield_stamina
	shield_bar.value = current_shield_stamina
	
	attack_shape.disabled = true
	
	anim.animation_finished.connect(_on_animation_finished)
	attack_area.body_entered.connect(_on_attack_body_hit)
	attack_area.area_entered.connect(_on_attack_hit)

func _physics_process(delta: float) -> void:
	# 1. Gravitasi
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Pemulihan Guard Break (aktif kembali jika stamina mencapai minimal 25%)
	if is_shield_broken and current_shield_stamina >= 25.0:
		is_shield_broken = false

	# 3. Logika Bertahan (Block) & Konsumsi Stamina
	if Input.is_action_pressed("block") and not is_attacking and is_on_floor() and not is_shield_broken:
		is_blocking = true
		regen_delay_timer = regen_delay_duration # Reset jeda waktu regenerasi
		shield.position.x = default_shield_pos.x - 3.0
		shield.modulate = Color(1.2, 1.2, 1.2)
		
		current_shield_stamina -= shield_drain_rate * delta
		if current_shield_stamina <= 0.0:
			current_shield_stamina = 0.0
			is_shield_broken = true
			is_blocking = false
	else:
		is_blocking = false
		shield.position = default_shield_pos
		shield.modulate = Color(1.0, 0.4, 0.4) if is_shield_broken else Color.WHITE
		
		# Hitung mundur jeda waktu sebelum regenerasi lambat berjalan
		if regen_delay_timer > 0.0:
			regen_delay_timer -= delta
		elif current_shield_stamina < max_shield_stamina:
			current_shield_stamina += shield_regen_rate * delta
			current_shield_stamina = min(current_shield_stamina, max_shield_stamina)

	shield_bar.value = current_shield_stamina

	# Hentikan gerak saat menahan block
	if is_blocking:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * delta * 5.0)
		move_and_slide()
		_play_anim("Idle")
		return

	# 4. Input Serangan
	if Input.is_action_just_pressed("attack") and not is_attacking and is_on_floor():
		_start_attack()

	if is_attacking:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * delta * 5.0)
		move_and_slide()
		return

	# 5. Input Lompat
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# 6. Input Gerak Horizontal
	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := run_speed if Input.is_action_pressed("run") else walk_speed

	if direction != 0:
		velocity.x = direction * target_speed
		visuals.scale.x = -1.0 if direction > 0 else 1.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, target_speed)

	move_and_slide()
	_update_animation(direction)

func _update_animation(direction: float) -> void:
	if is_attacking or is_blocking:
		return

	if not is_on_floor():
		if velocity.y < 0:
			_play_anim("Jump")
		else:
			_play_anim("Fall")
		return

	if direction == 0:
		_play_anim("Idle")
	else:
		if Input.is_action_pressed("run"):
			_play_anim("Run")
		else:
			_play_anim("Walk")

func _play_anim(anim_name: String) -> void:
	if anim.has_animation(anim_name) and anim.current_animation != anim_name:
		anim.play(anim_name)

func _start_attack() -> void:
	is_attacking = true
	velocity.x = 0
	_play_anim("Attack")

func _on_animation_finished(anim_name: StringName) -> void:
	if str(anim_name).to_lower() == "attack":
		is_attacking = false

# --- Deteksi Serangan Mengenai Objek Lain ---
func _on_attack_body_hit(body: Node2D) -> void:
	if body != self:
		if body.has_method("take_damage"):
			body.take_damage(10, self)
			
			# Restore stamina tameng saat tebasan berhasil mengenai musuh
			current_shield_stamina = min(current_shield_stamina + shield_hit_restore, max_shield_stamina)
			shield_bar.value = current_shield_stamina

func _on_attack_hit(_area: Area2D) -> void:
	pass

# --- Logika Menerima Serangan ---
func take_damage(amount: int, attacker: Node2D = null) -> void:
	var blocked_successfully: bool = false

	if is_blocking and attacker != null and not is_shield_broken:
		var attack_direction: float = sign(attacker.global_position.x - global_position.x)
		var facing_direction: float = 1.0 if visuals.scale.x < 0 else -1.0
		
		if attack_direction == facing_direction:
			blocked_successfully = true

	if blocked_successfully:
		current_shield_stamina -= amount * 1.5
		regen_delay_timer = regen_delay_duration # Reset jeda saat tameng terhantam
		
		if current_shield_stamina <= 0.0:
			current_shield_stamina = 0.0
			is_shield_broken = true
			is_blocking = false
		
		var reduced_damage: int = int(amount * 0.2)
		current_health -= reduced_damage
	else:
		current_health -= amount

	current_health = max(current_health, 0)
	health_bar.value = current_health

	if current_health <= 0:
		_die()

func _die() -> void:
	set_physics_process(false)
	_play_anim("Idle")
