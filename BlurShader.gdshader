shader_type canvas_item;

// Mengambil tampilan layar game di belakang menu
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 2.5;
uniform vec4 tint_color : source_color = vec4(0.05, 0.05, 0.08, 0.45); // Sedikit redup gelap

void fragment() {
    // Ambil warna layar dengan tingkat blur (LOD)
    vec4 screen_color = textureLod(screen_texture, SCREEN_UV, blur_amount);
    // Campurkan dengan warna redup
    COLOR = mix(screen_color, vec4(tint_color.rgb, 1.0), tint_color.a);
}