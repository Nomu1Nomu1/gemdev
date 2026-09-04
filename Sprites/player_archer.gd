extends CharacterBody2D

# --- Parameter Pergerakan ---
@export var walk_speed: float = 140.0
@export var run_speed: float = 230.0
@export var jump_velocity: float = -350.0
@export var max_health: int = 100

var current_health: int = 100
var is_dead: bool = false
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- Parameter Dodge & Energy ---
var is_dodging: bool = false
var dodge_speed: float = 400.0
var dodge_duration: float = 0.4
var dodge_cooldown: float = 0.8
var can_dodge: bool = true

@export var max_stamina: float = 100.0
var current_stamina: float = 100.0
var dodge_cost: float = 30.0
var stamina_regen_rate: float = 15.0

# --- Parameter Serangan ---
var is_shooting: bool = false
@export var arrow_scene: PackedScene 

# --- Referensi Node ---
@onready var anim = $Visuals/AnimatedSprite2D
@onready var visuals = $Visuals
@onready var health_bar: ProgressBar = $CanvasLayer/HUD/PlayerStatus/PanelContainer/StatusRow/BarsContainer/HealthBar
@onready var shield_bar: ProgressBar = $CanvasLayer/HUD/PlayerStatus/PanelContainer/StatusRow/BarsContainer/ShieldBar
@onready var collision_shape = $CollisionShape2D

func _ready() -> void:
	current_health = max_health
	current_stamina = max_stamina
	add_to_group("Player")
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		
	if shield_bar:
		shield_bar.visible = true
		shield_bar.max_value = max_stamina
		shield_bar.value = current_stamina

	if anim:
		anim.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	if is_dead: return

	if not is_on_floor():
		velocity.y += gravity * delta

	if is_dodging:
		move_and_slide()
		return

	if is_shooting:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * delta * 5.0)
		move_and_slide()
		return

	if Input.is_action_just_pressed("block") and can_dodge and is_on_floor() and current_stamina >= dodge_cost:
		_start_dodge()
		return

	if Input.is_action_just_pressed("attack") and not is_shooting and is_on_floor():
		_start_shoot()
		return

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := run_speed if Input.is_action_pressed("run") else walk_speed

	if direction != 0:
		velocity.x = direction * target_speed
		if visuals: visuals.scale.x = 1.0 if direction > 0 else -1.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, target_speed)

	# Stamina regeneration
	if not is_dodging and current_stamina < max_stamina:
		current_stamina += stamina_regen_rate * delta
		current_stamina = min(current_stamina, max_stamina)
		if shield_bar:
			shield_bar.value = current_stamina

	move_and_slide()
	_update_animation(direction)

func _update_animation(direction: float) -> void:
	if is_shooting or is_dodging: return
	if not anim: return

	if not is_on_floor():
		_play_anim("jumping")
		return

	if direction == 0:
		_play_anim("idle")
	else:
		_play_anim("running")

func _play_anim(anim_name: String) -> void:
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)

func _start_dodge() -> void:
	is_dodging = true
	can_dodge = false
	
	current_stamina -= dodge_cost
	if shield_bar:
		shield_bar.value = current_stamina
		
	var facing = 1.0 if (visuals and visuals.scale.x > 0) else -1.0
	velocity.x = facing * dodge_speed
	velocity.y = 0
	_play_anim("dodge")
	
	if has_node("Hurtbox/CollisionShape2D"):
		$"Hurtbox/CollisionShape2D".set_deferred("disabled", true)
	
	await get_tree().create_timer(dodge_duration).timeout
	is_dodging = false
	
	if has_node("Hurtbox/CollisionShape2D"):
		$"Hurtbox/CollisionShape2D".set_deferred("disabled", false)
	
	await get_tree().create_timer(dodge_cooldown).timeout
	can_dodge = true

func _start_shoot() -> void:
	is_shooting = true
	velocity.x = 0
	_play_anim("attack_normal")
	
	await get_tree().create_timer(0.4).timeout
	if is_dead: return
	
	if arrow_scene:
		var arrow = arrow_scene.instantiate()
		var facing = 1.0 if (visuals and visuals.scale.x > 0) else -1.0
		
		if has_node("Visuals/BowPivot/ArrowSpawnPoint"):
			arrow.global_position = $Visuals/BowPivot/ArrowSpawnPoint.global_position
		else:
			arrow.global_position = global_position + Vector2(20 * facing, -10)
			
		if arrow.has_method("set_direction"):
			arrow.set_direction(Vector2(facing, 0))
		get_parent().add_child(arrow)

func _on_animation_finished() -> void:
	var anim_name = anim.animation
	if anim_name == "attack_normal" or anim_name == "attack_high" or anim_name == "attack_low":
		is_shooting = false

func take_damage(amount: int, attacker: Node2D = null) -> void:
	if is_dead: return
	if is_dodging: return
		
	current_health -= amount
	current_health = max(current_health, 0)
	
	if health_bar:
		health_bar.value = current_health

	if current_health <= 0:
		_die()

func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if has_node("Hurtbox/CollisionShape2D"):
		$"Hurtbox/CollisionShape2D".set_deferred("disabled", true)
		
	# --- EFEK KAMERA DEKATI PEMAIN ---
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera:
		var cam_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		cam_tween.tween_property(camera, "zoom", Vector2(1.6, 1.6), 0.6)
		cam_tween.tween_property(camera, "offset", Vector2(0, -10), 0.6)

	_play_anim("death")
	
	await get_tree().create_timer(1.0).timeout
	if SceneTransition and SceneTransition.has_method("change_scene"):
		SceneTransition.change_scene("res://GandalfHardcore FREE Platformer Assets/Scene/gameover_screen.tscn", 0.4)
