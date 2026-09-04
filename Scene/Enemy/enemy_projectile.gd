class_name EnemyProjectile
extends Area2D

@export var speed: float = 220.0
@export var damage: int = 15
@export var lifetime: float = 4.0

var direction: Vector2 = Vector2.RIGHT
var is_impacted: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("fly"):
		sprite.play("fly")
	
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(func():
		if not is_impacted:
			queue_free()
	)

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	if is_impacted:
		return
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if is_impacted:
		return
	
	# Check if hit player
	if body.is_in_group("player") or body.name == "player_sword":
		if body.has_method("take_damage"):
			body.take_damage(damage, self)
		_impact()
	elif body is StaticBody2D or body is TileMap:
		# Hit wall or ground
		_impact()

func _on_area_entered(area: Area2D) -> void:
	if is_impacted:
		return
	var target = area.owner if area.owner else area.get_parent()
	if target and (target.is_in_group("player") or target.name == "player_sword"):
		if target.has_method("take_damage"):
			target.take_damage(damage, self)
		_impact()

func _impact() -> void:
	is_impacted = true
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("hit"):
		sprite.play("hit")
		await sprite.animation_finished
	queue_free()
