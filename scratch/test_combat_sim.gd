extends SceneTree

# Lightweight player stub for testing damage reception
class PlayerStub extends CharacterBody2D:
	var max_health: int = 100
	var current_health: int = 100
	var is_dead: bool = false
	var is_blocking: bool = false
	
	func take_damage(amount: int, _attacker = null) -> void:
		if is_dead:
			return
		current_health = max(current_health - amount, 0)
		if current_health <= 0:
			is_dead = true
	
	func _ready() -> void:
		add_to_group("player")

var _sim_done: bool = false

func _initialize() -> void:
	print("--- STARTING COMBAT SIMULATION TEST ---")

func _process(_delta: float) -> bool:
	if not _sim_done:
		_sim_done = true
		_run_simulation()
	return false  # continue processing

func _run_simulation() -> void:
	var root_node = self.root
	
	# Load enemy scenes
	var melee_scene = load("res://Scene/Enemy/melee_enemy.tscn")
	var ranged_scene = load("res://Scene/Enemy/ranged_enemy.tscn")
	var proj_scene = load("res://Scene/Enemy/enemy_projectile.tscn")
	
	assert(melee_scene != null, "melee_enemy.tscn failed to load")
	assert(ranged_scene != null, "ranged_enemy.tscn failed to load")
	assert(proj_scene != null, "enemy_projectile.tscn failed to load")
	print("All enemy scenes loaded successfully.")
	
	# Create stub player
	var player = PlayerStub.new()
	root_node.add_child(player)
	player.global_position = Vector2(100, 300)
	print("1. Player stub created. HP:", player.current_health)
	
	# Instantiate melee enemy
	var melee = melee_scene.instantiate()
	root_node.add_child(melee)
	melee.global_position = Vector2(200, 300)
	print("2. Melee enemy instantiated. HP:", melee.current_health)
	
	# TEST 1: Player damages Melee Enemy
	print("\n[TEST 1] Player attacks Melee Enemy (take_damage 15)...")
	var initial_enemy_hp = melee.current_health
	melee.take_damage(15, player)
	assert(melee.current_health < initial_enemy_hp, "Melee enemy should have taken damage from player!")
	print("   SUCCESS: Melee enemy HP reduced from %d to %d" % [initial_enemy_hp, melee.current_health])
	
	# TEST 2: Melee Enemy deals damage to Player
	print("\n[TEST 2] Melee Enemy deals damage to Player...")
	var initial_player_hp = player.current_health
	melee._deal_melee_damage(player)
	assert(player.current_health < initial_player_hp, "Player should have taken damage from Melee Enemy!")
	print("   SUCCESS: Player HP reduced from %d to %d" % [initial_player_hp, player.current_health])
	
	# TEST 3: Melee Enemy Death
	print("\n[TEST 3] Killing Melee Enemy with lethal damage...")
	melee.current_health = 5
	melee.is_dead = false
	melee.take_damage(100, player)
	assert(melee.is_dead == true, "Melee enemy should be dead!")
	assert(melee.current_health == 0, "Melee enemy health should be 0!")
	print("   SUCCESS: Melee enemy killed. is_dead=%s HP=%d" % [str(melee.is_dead), melee.current_health])
	
	# TEST 4: Instantiate Ranged Enemy
	print("\n[TEST 4] Ranged Enemy creation and health...")
	var ranged = ranged_scene.instantiate()
	root_node.add_child(ranged)
	ranged.global_position = Vector2(300, 300)
	assert(ranged.current_health > 0, "Ranged enemy should start with health > 0!")
	print("   SUCCESS: Ranged enemy created. HP:", ranged.current_health)
	
	# TEST 5: Player takes damage (projectile simulation - direct call)
	print("\n[TEST 5] Player takes projectile damage (simulated)...")
	var hp_before_proj = player.current_health
	player.take_damage(10, ranged)
	assert(player.current_health < hp_before_proj, "Player should take damage!")
	print("   SUCCESS: Player HP reduced from %d to %d" % [hp_before_proj, player.current_health])
	
	# TEST 6: Player kills Ranged Enemy
	print("\n[TEST 6] Player attacks and kills Ranged Enemy...")
	var initial_ranged_hp = ranged.current_health
	ranged.take_damage(15, player)
	assert(ranged.current_health < initial_ranged_hp, "Ranged enemy should have taken damage!")
	print("   Ranged enemy HP after 1 hit: %d" % ranged.current_health)
	ranged.current_health = 5
	ranged.is_dead = false
	ranged.take_damage(100, player)
	assert(ranged.is_dead == true, "Ranged enemy should be dead!")
	print("   SUCCESS: Ranged enemy killed. is_dead=%s" % str(ranged.is_dead))
	
	print("\n--- ALL COMBAT AND DAMAGE MECHANIC TESTS PASSED SUCCESSFULLY! ---")
	print("Simulation finished.")
	
	var f = FileAccess.open("res://scratch/sim_results.txt", FileAccess.WRITE)
	if f:
		f.store_string("ALL_TESTS_PASSED_OK\n")
		f.close()
		print("Results written to scratch/sim_results.txt")
	else:
		print("WARNING: Could not write sim_results.txt. Error: " + str(FileAccess.get_open_error()))
	
	quit(0)
