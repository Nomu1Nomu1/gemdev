class_name RangedEnemy
extends "res://Scene/Enemy/enemy_base.gd"

@export_group("Ranged Behavior")
@export var ideal_distance_min: float = 120.0
@export var ideal_distance_max: float = 200.0
@export var retreat_speed: float = 50.0
@export var advance_speed: float = 60.0
@export var projectile_scene: PackedScene = preload("res://Scene/Enemy/enemy_projectile.tscn")

@onready var projectile_spawn_point: Marker2D = $Visuals/ProjectileSpawnPoint

var _has_spawned_projectile: bool = false

func _ready() -> void:
	super._ready()
	# Set default stats for ranged enemy
	if max_health == 50:
		max_health = 40
		current_health = 40
	attack_cooldown = 2.0
	detection_range = 320.0

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if current_state == State.HURT:
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		move_and_slide()
		return
	
	if current_state == State.ATTACK:
		velocity.x = 0
		move_and_slide()
		return
	
	_find_player()
	
	if target_player and is_instance_valid(target_player):
		var diff_x = target_player.global_position.x - global_position.x
		var dist_x = abs(diff_x)
		var dir_to_player = sign(diff_x)
		
		if dist_x <= detection_range:
			_set_facing(dir_to_player)
			
			if dist_x < ideal_distance_min:
				# MC is too close: Maintain distance by backing away!
				if is_on_wall() and sign(get_wall_normal().x) == dir_to_player:
					# Wall is behind us, cannot retreat further
					velocity.x = 0
					_play_anim("idle")
				else:
					velocity.x = -dir_to_player * retreat_speed
					_play_anim("walk")
			elif dist_x > ideal_distance_max:
				# MC is too far: Advance forward to enter range
				velocity.x = dir_to_player * advance_speed
				_play_anim("walk")
			else:
				# In optimal firing sweet-spot!
				velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
				
				if can_attack:
					_start_ranged_attack()
				else:
					_play_anim("idle")
		else:
			# Player beyond detection range
			current_state = State.IDLE
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			_play_anim("idle")
	else:
		current_state = State.IDLE
		velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
		_play_anim("idle")
	
	move_and_slide()

func _start_ranged_attack() -> void:
	current_state = State.ATTACK
	velocity.x = 0
	_has_spawned_projectile = false
	_play_anim("attack")

func _on_frame_changed() -> void:
	if current_state == State.ATTACK and sprite.animation == "attack":
		# Frame 2 is the projectile cast/release frame
		if sprite.frame == 2 and not _has_spawned_projectile:
			_spawn_projectile()

func _spawn_projectile() -> void:
	_has_spawned_projectile = true
	if projectile_scene == null:
		return
	
	var proj = projectile_scene.instantiate()
	var spawn_pos: Vector2
	if projectile_spawn_point:
		spawn_pos = projectile_spawn_point.global_position
	else:
		spawn_pos = global_position + Vector2(20.0 * facing_direction, -30.0)
	
	proj.global_position = spawn_pos
	proj.damage = attack_damage
	
	# Calculate aim vector towards player chest/center
	var aim_dir: Vector2
	if target_player and is_instance_valid(target_player):
		var target_pos = target_player.global_position + Vector2(0, -20)
		aim_dir = (target_pos - spawn_pos).normalized()
	else:
		aim_dir = Vector2(facing_direction, 0).normalized()
	
	if proj.has_method("set_direction"):
		proj.set_direction(aim_dir)
	
	# Add projectile to the scene root / level so its position is in world space
	get_tree().current_scene.add_child(proj)
