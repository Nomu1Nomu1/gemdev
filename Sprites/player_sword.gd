extends CharacterBody2D

# --- Parameter Pergerakan & Status ---
@export var walk_speed: float = 130.0
@export var run_speed: float = 210.0
@export var jump_velocity: float = -350.0
@export var max_health: int = 100

var can_move: bool = true
var current_health: int = 100
var is_dead: bool = false
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- Parameter Tameng / Stamina ---
@export var max_shield_stamina: float = 100.0
var current_shield_stamina: float = 100.0
var shield_drain_rate: float = 20.0        # Berkurang saat menahan block
var shield_regen_rate: float = 8.0         # Kecepatan regen pasif
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
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@onready var health_bar: ProgressBar = $CanvasLayer/HUD/PlayerStatus/PanelContainer/StatusRow/BarsContainer/HealthBar
@onready var shield_bar: ProgressBar = $CanvasLayer/HUD/PlayerStatus/PanelContainer/StatusRow/BarsContainer/ShieldBar

var is_attacking: bool = false
var is_blocking: bool = false
var default_shield_pos: Vector2
var _hit_targets_in_swing: Array[Node] = []

func _ready() -> void:
	if not is_in_group("player"):
		add_to_group("player")
	
	current_health = max_health
	current_shield_stamina = max_shield_stamina
	default_shield_pos = shield.position
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	if shield_bar:
		shield_bar.max_value = max_shield_stamina
		shield_bar.value = current_shield_stamina
	
	attack_shape.disabled = true
	attack_area.collision_mask = 2 # Detect enemies on layer 2
	
	anim.animation_finished.connect(_on_animation_finished)
	attack_area.body_entered.connect(_on_attack_body_hit)
	attack_area.area_entered.connect(_on_attack_hit)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	# Kunci kontrol jika sedang cutscene intro bos
	if not can_move:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * delta * 5.0)
		move_and_slide()
		_play_anim("Idle")
		return

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
	_hit_targets_in_swing.clear()
	_play_anim("Attack")

func _on_animation_finished(anim_name: StringName) -> void:
	if str(anim_name).to_lower() == "attack":
		is_attacking = false
		_hit_targets_in_swing.clear()

# --- Deteksi Serangan Mengenai Objek Lain ---
func _deal_attack_damage(target: Node2D) -> void:
	if not is_attacking or target == null or target == self:
		return
	if _hit_targets_in_swing.has(target):
		return
	_hit_targets_in_swing.append(target)
	
	if target.has_method("take_damage"):
		target.take_damage(15, self)
		
		# Restore stamina tameng saat tebasan berhasil mengenai musuh
		current_shield_stamina = min(current_shield_stamina + shield_hit_restore, max_shield_stamina)
		if shield_bar:
			shield_bar.value = current_shield_stamina

func _on_attack_body_hit(body: Node2D) -> void:
	_deal_attack_damage(body)

func _on_attack_hit(area: Area2D) -> void:
	var target = area.owner if area.owner else area.get_parent()
	if target is Node2D:
		_deal_attack_damage(target)

# --- Logika Menerima Serangan ---
func take_damage(amount: int, attacker: Node2D = null) -> void:
	if is_dead:
		return

	var blocked_successfully: bool = false

	if is_blocking and attacker != null and not is_shield_broken:
		var attack_direction: float = sign(attacker.global_position.x - global_position.x)
		var facing_direction: float = 1.0 if visuals.scale.x < 0 else -1.0
		
		if attack_direction == facing_direction:
			blocked_successfully = true

	if blocked_successfully:
		current_shield_stamina -= amount * 1.5
		regen_delay_timer = regen_delay_duration
		
		if current_shield_stamina <= 0.0:
			current_shield_stamina = 0.0
			is_shield_broken = true
			is_blocking = false
		
		var reduced_damage: int = int(amount * 0.2)
		current_health -= reduced_damage
	else:
		current_health -= amount

	current_health = max(current_health, 0)
	if health_bar:
		health_bar.value = current_health

	if current_health <= 0:
		_die()

# --- Penanganan Kematian Karakter ---
func _die() -> void:
	is_dead = true
	can_move = false
	velocity = Vector2.ZERO
	set_physics_process(false)
	
	# Matikan tabrakan agar tidak terus terbentur/terdorong musuh
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if attack_shape:
		attack_shape.set_deferred("disabled", true)

	# Mainkan animasi mati jika tersedia, atau efek fallback
	if anim.has_animation("Death") or anim.has_animation("death"):
		var death_anim = "Death" if anim.has_animation("Death") else "death"
		anim.play(death_anim)
		await anim.animation_finished
	else:
		# Jika belum ada animasi mati, buat karakter berkedip merah dan memudar
		var death_tween = create_tween()
		death_tween.tween_property(visuals, "modulate", Color.RED, 0.2)
		death_tween.tween_property(visuals, "modulate:a", 0.0, 0.8)
		await death_tween.finished

	# Jeda sebelum reset scene
	await get_tree().create_timer(0.5).timeout
	if Engine.has_singleton("SceneTransition"):
		SceneTransition.change_scene("res://Scene/gameover_screen.tscn", 0.4)
	elif get_tree():
		get_tree().change_scene_to_file("res://Scene/gameover_screen.tscn")
