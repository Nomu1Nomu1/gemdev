extends CanvasLayer

@onready var container: Control = $BossUIContainer # Sesuaikan dengan nama node pembungkus UI-mu
@onready var health_bar: ProgressBar = $BossUIContainer/VBoxContainer/HealthBar # Sesuaikan path ProgressBar-mu
@onready var boss_title: Label = $BossUIContainer/VBoxContainer/BossName    # Sesuaikan path Label nama bos

var tween_hp: Tween

func _ready() -> void:
	# Pastikan UI tersembunyi di awal permainan
	container.visible = false
	container.modulate.a = 0.0

# Dipanggil saat cutscene bos selesai
func activate_boss_bar(boss_name: String, max_hp: int) -> void:
	if boss_title:
		boss_title.text = boss_name
	
	health_bar.max_value = max_hp
	health_bar.value = max_hp
	
	container.visible = true
	# Efek Fade-in memunculkan bar
	var fade_tween = create_tween()
	fade_tween.tween_property(container, "modulate:a", 1.0, 0.8)

# Dipanggil setiap kali bos terkena damage (animasi bar meluncur mulus)
func update_hp(new_hp: int) -> void:
	# Hentikan tween sebelumnya jika player memukul bertubi-tubi
	if tween_hp and tween_hp.is_running():
		tween_hp.kill()
		
	tween_hp = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Mengurangi nilai bar secara halus selama 0.3 detik
	tween_hp.tween_property(health_bar, "value", float(new_hp), 0.3)

# Dipanggil saat bos mati
func hide_boss_bar() -> void:
	var fade_tween = create_tween()
	fade_tween.tween_property(container, "modulate:a", 0.0, 0.6)
	await fade_tween.finished
	container.visible = false
