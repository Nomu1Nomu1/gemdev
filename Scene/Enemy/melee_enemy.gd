class_name MeleeEnemy
extends "res://Scene/Enemy/enemy_base.gd"

@onready var melee_hitbox: Area2D = $Visuals/MeleeHitbox
@onready var melee_shape: CollisionShape2D = $Visuals/MeleeHitbox/CollisionShape2D

var _already_hit_player: bool = false

func _ready() -> void:
	super._ready()
	if melee_shape:
		melee_shape.disabled = true
	if melee_hitbox:
		melee_hitbox.body_entered.connect(_on_melee_body_entered)

func _disable_hitboxes() -> void:
	if melee_shape:
		melee_shape.set_deferred("disabled", true)

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
		var dir = sign(diff_x)
		
		if dist_x <= detection_range:
			_set_facing(dir)
			
			if dist_x <= attack_range:
				# Within melee range
				if can_attack:
					_start_attack()
				else:
					# Waiting for attack cooldown
					velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
					_play_anim("idle")
			else:
				# Chase player
				current_state = State.CHASE
				velocity.x = dir * run_speed
				_play_anim("run")
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

func _start_attack() -> void:
	current_state = State.ATTACK
	velocity.x = 0
	_already_hit_player = false
	if melee_shape:
		melee_shape.set_deferred("disabled", true)
	_play_anim("attack")

func _on_frame_changed() -> void:
	if current_state == State.ATTACK and sprite.animation == "attack":
		# Frame 2 is the forward claw/slash strike frame
		if sprite.frame == 2:
			if melee_shape:
				melee_shape.set_deferred("disabled", false)
			_check_melee_hit()
		elif sprite.frame == 3:
			if melee_shape:
				melee_shape.set_deferred("disabled", true)

func _check_melee_hit() -> void:
	if _already_hit_player or melee_hitbox == null:
		return
	var bodies = melee_hitbox.get_overlapping_bodies()
	for b in bodies:
		if b.is_in_group("player") or b.name == "player_sword":
			_deal_melee_damage(b)
			break

func _on_melee_body_entered(body: Node2D) -> void:
	if current_state == State.ATTACK and not _already_hit_player:
		if body.is_in_group("player") or body.name == "player_sword":
			_deal_melee_damage(body)

func _deal_melee_damage(player_body: Node2D) -> void:
	_already_hit_player = true
	if player_body.has_method("take_damage"):
		player_body.take_damage(attack_damage, self)
	if melee_shape:
		melee_shape.set_deferred("disabled", true)

func _on_attack_finished() -> void:
	if melee_shape:
		melee_shape.set_deferred("disabled", true)
	super._on_attack_finished()
