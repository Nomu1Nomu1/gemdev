extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

func change_scene(target_path: String, duration: float = 0.6) -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(color_rect, "modulate:a", 1.0, duration)
	await tw.finished
	
	get_tree().change_scene_to_file(target_path)
	
	await get_tree().process_frame
	
	var tw_in = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw_in.tween_property(color_rect, "modulate:a", 0.0, duration)
	await tw_in.finished
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
