extends VBoxContainer

@onready var bar: Control = $Bar
@onready var hover_sfx: AudioStreamPlayer = $HoverS
@onready var click_sfx: AudioStreamPlayer = $ClickS

var buttons: Array[Button] = []
var current_button: Button = null

func _ready() -> void:
	buttons.clear()
	for child in get_children():
		if child is Button:
			buttons.append(child)
			child.mouse_entered.connect(_on_button_hovered.bind(child))
			child.focus_entered.connect(_on_button_focused.bind(child))
			child.pressed.connect(_on_button_pressed.bind(child))

func focus_first_button() -> void:
	if buttons.size() > 0:
		buttons[0].grab_focus()
		_move_bar_to(buttons[0], true)

func _on_button_hovered(btn: Button) -> void:
	if not btn.has_focus():
		btn.grab_focus()

func _on_button_focused(btn: Button) -> void:
	current_button = btn
	if hover_sfx and hover_sfx.stream:
		hover_sfx.pitch_scale = randf_range(0.95, 1.05)
		hover_sfx.play()
	_move_bar_to(btn)

func _move_bar_to(btn: Button, instant: bool = false) -> void:
	if not bar:
		return
	var target_pos = Vector2(bar.position.x, btn.position.y + (btn.size.y - bar.size.y) / 2.0)
	if instant:
		bar.position = target_pos
	else:
		var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(bar, "position", target_pos, 0.15)

func _on_button_pressed(btn: Button) -> void:
	if click_sfx and click_sfx.stream:
		click_sfx.play()
	
	var label = btn.text.strip_edges().to_lower()
	
	if "restart" in label:
		_restart_game()
	elif "menu" in label:
		_to_main_menu()
	elif "exit" in label:
		_quit_game()

func _restart_game() -> void:
	get_tree().reload_current_scene()

func _to_main_menu() -> void:
	get_tree().paused = false
	SceneTransition.change_scene("res://GandalfHardcore FREE Platformer Assets/Scene/MainMenu/main_menu.tscn", 0.4)

func _quit_game() -> void:
	get_tree().quit()
