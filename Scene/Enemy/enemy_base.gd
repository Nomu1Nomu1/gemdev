class_name EnemyBase
extends CharacterBody2D

signal health_changed(new_health: int, max_health: int)
signal died

enum State { IDLE, PATROL, CHASE, RETREAT, ATTACK, HURT, DEAD }

@export_group("Stats")
@export var max_health: int = 50
@export var attack_damage: int = 15
@export var walk_speed: float = 60.0
@export var run_speed: float = 90.0

@export_group("Detection & Combat")
@export var detection_range: float = 240.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.2

var current_health: int = 100  # Will be set to max_health in _ready()
var current_state: State = State.IDLE
var is_dead: bool = false
var can_attack: bool = true
var facing_direction: float = 1.0 # 1.0 = right, -1.0 = left
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

var target_player: CharacterBody2D = null

@onready var visuals: Node2D = $Visuals
@onready var sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	current_health = max_health
	_update_health_bar()
	_find_player()
	
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)
		sprite.frame_changed.connect(_on_frame_changed)

func _find_player() -> void:
	if target_player == null or not is_instance_valid(target_player):
		if not get_tree():
			return
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target_player = players[0] as CharacterBody2D
		else:
			target_player = get_tree().root.find_child("player_sword", true, false) as CharacterBody2D

func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		# Show health bar only after taking damage, and hide when dead
		health_bar.visible = (current_health < max_health and not is_dead)

func _set_facing(dir: float) -> void:
	if dir == 0 or is_dead or current_state == State.ATTACK:
		return
	facing_direction = 1.0 if dir > 0 else -1.0
	if visuals:
		visuals.scale.x = facing_direction

func take_damage(amount: int, attacker: Node2D = null) -> void:
	if is_dead:
		return
	
	current_health = max(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	_update_health_bar()
	
	# Hit flash effect (white/red flash)
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(2.8, 0.4, 0.4, 1.0), 0.08)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)
	
	# Knockback away from attacker
	if attacker:
		var knock_dir = sign(global_position.x - attacker.global_position.x)
		if knock_dir == 0:
			knock_dir = -facing_direction
		velocity.x = knock_dir * 90.0
	
	if current_health <= 0:
		_die()
	else:
		if current_state != State.ATTACK:
			current_state = State.HURT
			velocity.x = 0
			_play_anim("hurt")

func _die() -> void:
	is_dead = true
	current_state = State.DEAD
	velocity = Vector2.ZERO
	died.emit()
	
	if health_bar:
		health_bar.visible = false
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	_disable_hitboxes()
	
	if not is_inside_tree():
		return
	
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("dead"):
		sprite.play("dead")
		await sprite.animation_finished
	else:
		if get_tree():
			await get_tree().create_timer(0.4).timeout
	
	var fade_tween = create_tween()
	if fade_tween:
		fade_tween.tween_property(self, "modulate:a", 0.0, 0.4)
		await fade_tween.finished
	queue_free()

func _disable_hitboxes() -> void:
	pass

func _play_anim(anim_name: String) -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name or not sprite.is_playing():
			sprite.play(anim_name)

func _on_animation_finished() -> void:
	if is_dead:
		return
	if current_state == State.HURT:
		current_state = State.IDLE
	elif current_state == State.ATTACK:
		_on_attack_finished()

func _on_attack_finished() -> void:
	current_state = State.IDLE
	can_attack = false
	if get_tree():
		get_tree().create_timer(attack_cooldown).timeout.connect(func():
			can_attack = true
		)
	else:
		can_attack = true

func _on_frame_changed() -> void:
	pass
