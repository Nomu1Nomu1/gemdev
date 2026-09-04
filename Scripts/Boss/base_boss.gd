class_name BaseBoss
extends CharacterBody2D

signal boss_hp_changed(current_hp: int, max_hp: int)
signal boss_defeated

@export var boss_name: String = "Boss Name"
@export var max_health: int = 100

var current_health: int = 100
var is_dead: bool = false
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int, _attacker: Node2D = null) -> void:
	if is_dead:
		return
	
	current_health = max(0, current_health - amount)
	boss_hp_changed.emit(current_health, max_health)
	
	# Efek kedip merah saat terkena serangan
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color.RED, 0.08)
	tw.tween_property(self, "modulate", Color.WHITE, 0.08)
	
	if current_health <= 0:
		_die()

func _die() -> void:
	is_dead = true
	boss_defeated.emit()
	set_physics_process(false)
