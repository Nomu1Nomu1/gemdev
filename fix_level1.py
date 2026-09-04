import os

level1_path = r"D:\Yodha\Lomba\Alif peler\gemdev\Scene\Main\Level\level_1.gd"
with open(level1_path, 'r', encoding='utf-8') as f:
    content = f.read()

new_spawn = """func _spawn_player() -> void:
	var player_scene = preload("res://Sprites/player_sword.tscn")
	
	if GameManager.selected_weapon == GameManager.WeaponType.BOW:
		player_scene = preload("res://Sprites/player_archer.tscn")
		
	if not player_scene:
		push_error("Error: Scene player tidak ditemukan!")
		return
		
	# Instantiate player dan posisikan di SpawnPoint
	var player = player_scene.instantiate()
	player.global_position = spawn_point.global_position
	add_child(player)"""

# Replace old spawn player block
# The old one had:
# const PLAYER_SCENE = preload("res://Sprites/player_sword.tscn")
# and func _spawn_player() -> void: ...

import re
content = re.sub(r'const PLAYER_SCENE.*?\n', '', content)
content = re.sub(r'func _spawn_player\(\) -> void:[\s\S]*?(?=func cinematic_focus_to)', new_spawn + '\n\n', content)

with open(level1_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated level_1.gd to use GameManager.selected_weapon")
