extends Control

@onready var hover_sfx: AudioStreamPlayer = $HoverSfx
@onready var click_sfx: AudioStreamPlayer = $ClickSfx
@onready var vanguard_card: Button = $MarginContainer/CenterUI/CardsHBox/VanguardCard
@onready var archer_card: Button = $MarginContainer/CenterUI/CardsHBox/ArcherCard
@onready var vanguard_bg: ColorRect = $MarginContainer/CenterUI/CardsHBox/VanguardCard/CardBG
@onready var archer_bg: ColorRect = $MarginContainer/CenterUI/CardsHBox/ArcherCard/CardBG

const COLOR_ACTIVE_BORDER = Color("#FF2B43")
const COLOR_ACTIVE_BG = Color("#0D0D11")
const COLOR_INACTIVE_BORDER = Color("#3A3D45")
const COLOR_INACTIVE_BG = Color("#121316cc")

var is_locked: bool = false
var current_card: Button = null
var is_ready: bool = false

func _ready() -> void:
	vanguard_bg.material = vanguard_bg.material.duplicate()
	archer_bg.material = archer_bg.material.duplicate()
	
	_setup_card(vanguard_card, GameManager.WeaponType.SWORD)
	_setup_card(archer_card, GameManager.WeaponType.BOW)
	
	await get_tree().process_frame
	vanguard_card.grab_focus()
	
	await get_tree().create_timer(0.1).timeout
	is_ready = true

func _setup_card(card: Button, weapon_type: GameManager.WeaponType) -> void:
	card.pressed.connect(func(): _on_card_pressed(card, weapon_type))
	card.focus_entered.connect(func(): _on_card_focused(card))
	card.mouse_entered.connect(func():
		if not is_locked and not card.has_focus():
			card.grab_focus()
	)

func _on_card_focused(card: Button) -> void:
	if is_locked or card == current_card:
		return
	current_card = card
	
	if is_ready and hover_sfx and hover_sfx.stream:
		hover_sfx.pitch_scale = randf_range(0.96, 1.04)
		hover_sfx.play()
	
	_highlight_card(vanguard_card, vanguard_bg, card == vanguard_card)
	_highlight_card(archer_card, archer_bg, card == archer_card)

func _get_anim_player(card: Button) -> Variant:
	var anim_sprites = card.find_children("*", "AnimatedSprite2D", true, false)
	if anim_sprites.size() > 0:
		return anim_sprites[0]
		
	var anim_players = card.find_children("*", "AnimationPlayer", true, false)
	if anim_players.size() > 0:
		return anim_players[0]
		
	return null

func _highlight_card(card: Button, bg_node: ColorRect, active: bool) -> void:
	var mat = bg_node.material as ShaderMaterial
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var anim = _get_anim_player(card)
	
	if active:
		tween.tween_property(card, "scale", Vector2(1.05, 1.05), 0.12)
		if mat:
			mat.set_shader_parameter("border_color", COLOR_ACTIVE_BORDER)
			mat.set_shader_parameter("bg_color", COLOR_ACTIVE_BG)
			mat.set_shader_parameter("border_size", 2.0)
		card.modulate = Color(1.0, 1.0, 1.0, 1.0)
		
		if anim is AnimatedSprite2D:
			anim.play()
		elif anim is AnimationPlayer:
			anim.play()
	else:
		tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.12)
		if mat:
			mat.set_shader_parameter("border_color", COLOR_INACTIVE_BORDER)
			mat.set_shader_parameter("bg_color", COLOR_INACTIVE_BG)
			mat.set_shader_parameter("border_size", 1.0)
		card.modulate = Color(0.65, 0.65, 0.7, 0.85)
		
		if anim is AnimatedSprite2D:
			anim.pause()
			anim.frame = 0
		elif anim is AnimationPlayer:
			anim.pause()
			anim.seek(0.0, true)

func _on_card_pressed(card: Button, weapon_type: GameManager.WeaponType) -> void:
	if is_locked:
		return
	is_locked = true
	
	if click_sfx and click_sfx.stream:
		click_sfx.pitch_scale = randf_range(0.98, 1.02)
		click_sfx.play()
	
	GameManager.selected_weapon = weapon_type
	
	var flash_tween = create_tween().set_loops(2)
	flash_tween.tween_property(card, "modulate", Color(2.5, 2.5, 2.5), 0.08)
	flash_tween.tween_property(card, "modulate", Color(1.0, 1.0, 1.0), 0.08)
	
	var other_card = archer_card if card == vanguard_card else vanguard_card
	var fade_tween = create_tween()
	fade_tween.tween_property(other_card, "modulate:a", 0.0, 0.25)
	
	await get_tree().create_timer(0.4).timeout
	
	if ResourceLoader.exists("res://Scene/Main/Level/level_1.tscn"):
		SceneTransition.change_scene("res://Scene/Main/Level/level_1.tscn", 0.5)
	else:
		get_tree().change_scene_to_file("res://Scene/Main/Level/level_1.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not is_locked:
		is_locked = true
		if click_sfx and click_sfx.stream:
			click_sfx.play()
		SceneTransition.change_scene("res://Scene/MainMenu/main_menu.tscn", 0.4)
