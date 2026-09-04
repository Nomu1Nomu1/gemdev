extends Control

@onready var menu_box = $MarginContainer/HBoxContainer/VBoxContainer

func _ready() -> void:
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # Tombol ESC
		if visible:
			get_tree().paused = false
			hide()
		else:
			get_tree().paused = true
			show()
			menu_box.focus_first_button()
		get_viewport().set_input_as_handled()
