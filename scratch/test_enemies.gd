extends SceneTree

func _init() -> void:
	print("--- TESTING ENEMY INSTANTIATION ---")
	
	# 1. Test Melee Enemy
	var melee_scene = load("res://Scene/Enemy/melee_enemy.tscn")
	assert(melee_scene != null, "melee_enemy.tscn failed to load!")
	var melee = melee_scene.instantiate()
	assert(melee != null, "melee_enemy failed to instantiate!")
	print("Melee enemy instantiated successfully. Type:", melee.get_class(), "Group:", melee.is_in_group("enemies"))
	assert(melee.collision_layer == 2, "Melee enemy collision_layer must be 2!")
	assert(melee.has_method("take_damage"), "Melee enemy must have take_damage method!")
	melee.free()
	
	# 2. Test Ranged Enemy
	var ranged_scene = load("res://Scene/Enemy/ranged_enemy.tscn")
	assert(ranged_scene != null, "ranged_enemy.tscn failed to load!")
	var ranged = ranged_scene.instantiate()
	assert(ranged != null, "ranged_enemy failed to instantiate!")
	print("Ranged enemy instantiated successfully. Type:", ranged.get_class(), "Group:", ranged.is_in_group("enemies"))
	assert(ranged.collision_layer == 2, "Ranged enemy collision_layer must be 2!")
	assert(ranged.has_method("take_damage"), "Ranged enemy must have take_damage method!")
	ranged.free()
	
	# 3. Test Projectile
	var proj_scene = load("res://Scene/Enemy/enemy_projectile.tscn")
	assert(proj_scene != null, "enemy_projectile.tscn failed to load!")
	var proj = proj_scene.instantiate()
	assert(proj != null, "enemy_projectile failed to instantiate!")
	print("Enemy projectile instantiated successfully. Type:", proj.get_class())
	assert(proj.collision_mask == 5, "Projectile collision_mask must be 5 (World + Player)!")
	proj.free()
	
	print("--- ALL ENEMY RESOURCE CHECKS PASSED ---")
	quit(0)
