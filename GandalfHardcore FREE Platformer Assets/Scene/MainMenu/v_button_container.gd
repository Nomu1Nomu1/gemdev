extends VBoxContainer

@onready var bg: ColorRect = $Bar
@onready var hover_sfx: AudioStreamPlayer = $HoverS
@onready var click_sfx: AudioStreamPlayer = $ClickS
# Hubungkan ke node BgmMusic (sesuaikan path jika berada di luar VBoxContainer, misal: $"../BgmMusic")
@onready var bgm_music: AudioStreamPlayer = $BgmS

var current_button: Button = null
var tween: Tween
var is_ready: bool = false

func _ready() -> void:
	for child in get_children():
		if child is Button:
			child.mouse_entered.connect(_on_button_hovered.bind(child))
			child.focus_entered.connect(_on_button_hovered.bind(child))
			# Teruskan info tombol mana yang ditekan
			child.pressed.connect(_on_button_pressed.bind(child))
			child.flat = true
	
	await get_tree().process_frame
	var first_btn = _get_first_button()
	if first_btn:
		current_button = first_btn
		_move_background_to(first_btn, true)
	
	await get_tree().create_timer(0.1).timeout
	is_ready = true
	
	if bgm_music:
		bgm_music.volume_db = 0.0
		if not bgm_music.playing:
			bgm_music.play()

func _on_button_hovered(target_btn: Button) -> void:
	if target_btn != current_button:
		current_button = target_btn
		_move_background_to(target_btn, false)
		
		if is_ready and hover_sfx and hover_sfx.stream:
			hover_sfx.pitch_scale = randf_range(0.96, 1.04)
			hover_sfx.play()

func _on_button_pressed(clicked_btn: Button) -> void:
	if click_sfx and click_sfx.stream:
		click_sfx.play()
	
	# Cek apakah tombol yang diklik adalah Play
	if clicked_btn.text.to_lower() == "play" or "play" in clicked_btn.name.to_lower():
			print("Tombol play terdeteksi, mulai fade out...")
			fade_out_bgm(1.2)

func fade_out_bgm(duration: float) -> void:
	if not bgm_music or not bgm_music.playing:
		return
		
	var bgm_tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	
	# Animasi dari volume 1.0 (100%) turun ke 0.0 (0%) secara bertahap
	bgm_tween.tween_method(
		func(linear_vol: float):
			bgm_music.volume_db = linear_to_db(max(linear_vol, 0.0001)),
		1.0,
		0.0,
		duration
	)
	
	# Baru stop lagu setelah durasi benar-benar habis
	bgm_tween.finished.connect(func():
		bgm_music.stop()
		# Jika ingin pindah scene, taruh di sini:
		# get_tree().change_scene_to_file("res://world.tscn")
	)

func _move_background_to(target_btn: Button, instant: bool) -> void:
	var target_pos_y = target_btn.position.y
	var target_size_y = target_btn.size.y
	var target_size_x = target_btn.size.x
	
	if instant:
		bg.position.y = target_pos_y
		bg.size.y = target_size_y
		bg.size.x = target_size_x
		return
		
	if tween and tween.is_running():
		tween.kill()
		
	tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(bg, "position:y", target_pos_y, 0.18)
	tween.tween_property(bg, "size:y", target_size_y, 0.18)
	tween.tween_property(bg, "size:x", target_size_x, 0.18)

func _get_first_button() -> Button:
	for child in get_children():
		if child is Button:
			return child
	return null
