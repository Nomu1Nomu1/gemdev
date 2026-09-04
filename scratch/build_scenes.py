import os

def create_projectile_tscn():
    content = """[gd_scene format=3]

[ext_resource type="Script" path="res://Scene/Enemy/enemy_projectile.gd" id="1_proj"]
[ext_resource type="Texture2D" path="res://Sprites/Enemies/Yurei/Charge_1.png" id="2_fly"]
[ext_resource type="Texture2D" path="res://Sprites/Enemies/Yurei/Charge_2.png" id="3_hit"]

[sub_resource type="AtlasTexture" id="AtlasTexture_fly0"]
atlas = ExtResource("2_fly")
region = Rect2(0, 0, 24, 24)

[sub_resource type="AtlasTexture" id="AtlasTexture_fly1"]
atlas = ExtResource("2_fly")
region = Rect2(24, 0, 24, 24)

[sub_resource type="AtlasTexture" id="AtlasTexture_fly2"]
atlas = ExtResource("2_fly")
region = Rect2(48, 0, 24, 24)

[sub_resource type="AtlasTexture" id="AtlasTexture_hit0"]
atlas = ExtResource("3_hit")
region = Rect2(0, 0, 24, 24)

[sub_resource type="AtlasTexture" id="AtlasTexture_hit1"]
atlas = ExtResource("3_hit")
region = Rect2(24, 0, 24, 24)

[sub_resource type="AtlasTexture" id="AtlasTexture_hit2"]
atlas = ExtResource("3_hit")
region = Rect2(48, 0, 24, 24)

[sub_resource type="AtlasTexture" id="AtlasTexture_hit3"]
atlas = ExtResource("3_hit")
region = Rect2(72, 0, 24, 24)

[sub_resource type="SpriteFrames" id="SpriteFrames_proj"]
animations = [{
"frames": [{
"duration": 1.0,
"texture": SubResource("AtlasTexture_fly0")
}, {
"duration": 1.0,
"texture": SubResource("AtlasTexture_fly1")
}, {
"duration": 1.0,
"texture": SubResource("AtlasTexture_fly2")
}],
"loop": true,
"name": &"fly",
"speed": 10.0
}, {
"frames": [{
"duration": 1.0,
"texture": SubResource("AtlasTexture_hit0")
}, {
"duration": 1.0,
"texture": SubResource("AtlasTexture_hit1")
}, {
"duration": 1.0,
"texture": SubResource("AtlasTexture_hit2")
}, {
"duration": 1.0,
"texture": SubResource("AtlasTexture_hit3")
}],
"loop": false,
"name": &"hit",
"speed": 14.0
}]

[sub_resource type="CircleShape2D" id="CircleShape2D_proj"]
radius = 6.0

[node name="EnemyProjectile" type="Area2D"]
collision_layer = 0
collision_mask = 5
script = ExtResource("1_proj")

[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]
sprite_frames = SubResource("SpriteFrames_proj")
animation = &"fly"
autoplay = "fly"

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_proj")
"""
    with open("Scene/Enemy/enemy_projectile.tscn", "w", encoding="utf-8") as f:
        f.write(content)
    print("Created Scene/Enemy/enemy_projectile.tscn")

def generate_enemy_tscn(enemy_type, enemy_folder, script_path, anim_specs, out_path, is_ranged=False):
    # anim_specs: list of (anim_name, filename, frame_count, speed, loop)
    lines = ["[gd_scene format=3]\n"]
    lines.append(f'[ext_resource type="Script" path="{script_path}" id="1_script"]')
    
    ext_id = 2
    ext_map = {}
    for anim_name, filename, count, speed, loop in anim_specs:
        if filename not in ext_map:
            ext_map[filename] = f"{ext_id}_tex_{anim_name}"
            lines.append(f'[ext_resource type="Texture2D" path="res://Sprites/Enemies/{enemy_folder}/{filename}" id="{ext_map[filename]}"]')
            ext_id += 1
    
    lines.append("")
    
    # Generate AtlasTextures
    atlas_subresources = []
    for anim_name, filename, count, speed, loop in anim_specs:
        tex_id = ext_map[filename]
        frame_subs = []
        for i in range(count):
            sub_id = f"AtlasTexture_{anim_name}_{i}"
            lines.append(f'[sub_resource type="AtlasTexture" id="{sub_id}"]')
            lines.append(f'atlas = ExtResource("{tex_id}")')
            lines.append(f'region = Rect2({i * 128}, 0, 128, 128)')
            lines.append("")
            frame_subs.append(sub_id)
        atlas_subresources.append((anim_name, speed, loop, frame_subs))
    
    # Generate SpriteFrames
    lines.append('[sub_resource type="SpriteFrames" id="SpriteFrames_enemy"]')
    lines.append("animations = [")
    anim_blocks = []
    for anim_name, speed, loop, frame_subs in atlas_subresources:
        f_lines = []
        for s_id in frame_subs:
            f_lines.append(f'{{\n"duration": 1.0,\n"texture": SubResource("{s_id}")\n}}')
        f_str = ", ".join(f_lines)
        loop_str = "true" if loop else "false"
        anim_blocks.append(f'{{\n"frames": [{f_str}],\n"loop": {loop_str},\n"name": &"{anim_name}",\n"speed": {speed:.1f}\n}}')
    lines.append(", ".join(anim_blocks))
    lines.append("]\n")
    
    # Shapes and styles
    lines.append('[sub_resource type="CapsuleShape2D" id="CapsuleShape2D_body"]')
    lines.append("radius = 14.0")
    lines.append("height = 46.0\n")
    
    if not is_ranged:
        lines.append('[sub_resource type="RectangleShape2D" id="RectangleShape2D_hitbox"]')
        lines.append("size = Vector2(36, 40)\n")
    
    lines.append('[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_bg"]')
    lines.append("bg_color = Color(0.1, 0.1, 0.12, 0.8)")
    lines.append("corner_radius_top_left = 2")
    lines.append("corner_radius_top_right = 2")
    lines.append("corner_radius_bottom_right = 2")
    lines.append("corner_radius_bottom_left = 2\n")
    
    lines.append('[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_fill"]')
    fill_color = "Color(0.85, 0.2, 0.2, 1.0)" if not is_ranged else "Color(0.6, 0.3, 0.9, 1.0)"
    lines.append(f"bg_color = {fill_color}")
    lines.append("corner_radius_top_left = 2")
    lines.append("corner_radius_top_right = 2")
    lines.append("corner_radius_bottom_right = 2")
    lines.append("corner_radius_bottom_left = 2\n")
    
    # Root Node
    root_name = "MeleeEnemy" if not is_ranged else "RangedEnemy"
    lines.append(f'[node name="{root_name}" type="CharacterBody2D" groups=["enemies"]]')
    lines.append("collision_layer = 2")
    lines.append("collision_mask = 1")
    lines.append('script = ExtResource("1_script")\n')
    
    # Visuals
    lines.append('[node name="Visuals" type="Node2D" parent="."]\n')
    lines.append('[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="Visuals"]')
    lines.append('position = Vector2(0, -64)')
    lines.append('sprite_frames = SubResource("SpriteFrames_enemy")')
    lines.append('animation = &"idle"')
    lines.append('autoplay = "idle"\n')
    
    if not is_ranged:
        lines.append('[node name="MeleeHitbox" type="Area2D" parent="Visuals"]')
        lines.append("collision_layer = 0")
        lines.append("collision_mask = 4\n")
        lines.append('[node name="CollisionShape2D" type="CollisionShape2D" parent="Visuals/MeleeHitbox"]')
        lines.append("position = Vector2(25, -24)")
        lines.append('shape = SubResource("RectangleShape2D_hitbox")')
        lines.append("disabled = true\n")
    else:
        lines.append('[node name="ProjectileSpawnPoint" type="Marker2D" parent="Visuals"]')
        lines.append("position = Vector2(24, -30)\n")
    
    # Body Collision
    lines.append('[node name="CollisionShape2D" type="CollisionShape2D" parent="."]')
    lines.append("position = Vector2(0, -23)")
    lines.append('shape = SubResource("CapsuleShape2D_body")\n')
    
    # HealthBar
    lines.append('[node name="HealthBar" type="ProgressBar" parent="."]')
    lines.append("offset_left = -18.0")
    lines.append("offset_top = -54.0")
    lines.append("offset_right = 18.0")
    lines.append("offset_bottom = -49.0")
    lines.append('theme_override_styles/background = SubResource("StyleBoxFlat_bg")')
    lines.append('theme_override_styles/fill = SubResource("StyleBoxFlat_fill")')
    lines.append("value = 100.0")
    lines.append("show_percentage = false\n")
    
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"Created {out_path}")

create_projectile_tscn()

# Gotoku (Melee)
gotoku_anims = [
    ("idle", "Idle.png", 5, 8.0, True),
    ("walk", "Walk.png", 6, 8.0, True),
    ("run", "Run.png", 7, 10.0, True),
    ("attack", "Attack_1.png", 4, 8.0, False),
    ("hurt", "Hurt.png", 3, 8.0, False),
    ("dead", "Dead.png", 5, 6.0, False)
]
generate_enemy_tscn("MeleeEnemy", "Gotoku", "res://Scene/Enemy/melee_enemy.gd", gotoku_anims, "Scene/Enemy/melee_enemy.tscn", is_ranged=False)

# Yurei (Ranged)
yurei_anims = [
    ("idle", "Idle.png", 5, 7.0, True),
    ("walk", "Walk.png", 5, 8.0, True),
    ("run", "Run.png", 5, 10.0, True),
    ("attack", "Attack_1.png", 4, 7.0, False),
    ("hurt", "Hurt.png", 3, 8.0, False),
    ("dead", "Dead.png", 4, 6.0, False)
]
generate_enemy_tscn("RangedEnemy", "Yurei", "res://Scene/Enemy/ranged_enemy.gd", yurei_anims, "Scene/Enemy/ranged_enemy.tscn", is_ranged=True)
