extends Node

enum WeaponType { SWORD, BOW }

var selected_weapon: WeaponType = WeaponType.SWORD
var last_played_level: String = "res://sword_2d.tscn"

func restart_current_level() -> void:
	var target = last_played_level if last_played_level != "" else "res://sword_2d.tscn"
	if has_node("/root/SceneTransition"):
		get_node("/root/SceneTransition").change_scene(target, 0.4)
	else:
		get_tree().change_scene_to_file(target)

