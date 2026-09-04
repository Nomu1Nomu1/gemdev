extends Area2D

@export var speed: float = 400.0
@export var damage: int = 20
@export var lifetime: float = 2.0

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# Destroy the arrow after `lifetime` seconds to prevent memory leaks
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	# Rotate the arrow to match the direction
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	# Prevent the arrow from damaging the player who shot it if accidentally hitting them
	if body.is_in_group("Player"):
		return
		
	if body.has_method("take_damage"):
		body.take_damage(damage, self)
		
	# Destroy the arrow upon hitting something
	queue_free()
