shader_type canvas_item;

// Warna
uniform vec4 bg_color : source_color = vec4(0.06, 0.42, 0.62, 0.65);     // Biru latar
uniform vec4 border_color : source_color = vec4(0.18, 0.78, 0.95, 1.0);  // Garis neon cyan

// Ukuran notch pojok kanan & tebal border (dalam piksel)
uniform float corner_cut : hint_range(1.0, 10.0) = 4.0;
uniform float border_size : hint_range(1.0, 4.0) = 1.0;
uniform float fade_end : hint_range(0.0, 1.0) = 0.65; // Titik mulai memudar ke kiri

varying vec2 local_pos;

void vertex() {
	// Ambil koordinat piksel lokal node
	local_pos = VERTEX;
}

void fragment() {
	vec2 node_size = local_pos / max(UV, vec2(0.0001));
	vec2 pixel_pos = local_pos;
	
	// 1. Potong sudut miring (notch) di pojok KANAN atas dan KANAN bawah
	float d_top_right = (node_size.x - pixel_pos.x) + pixel_pos.y;
	float d_bot_right = (node_size.x - pixel_pos.x) + (node_size.y - pixel_pos.y);
	
	if (d_top_right < corner_cut || d_bot_right < corner_cut) {
		discard; // Memotong sudut kanan ala Dead Cells
	}
	
	// 2. Efek memudar halus ke arah KIRI (UV.x mendekati 0.0 semakin transparan)
	float alpha_fade = clamp(UV.x / max(fade_end, 0.001), 0.0, 1.0);
	
	// 3. Garis border neon: KANAN vertikal, atas, dan bawah
	bool is_right_edge = (pixel_pos.x >= node_size.x - border_size);
	bool is_top_edge = (pixel_pos.y <= border_size);
	bool is_bottom_edge = (pixel_pos.y >= node_size.y - border_size);
	bool is_corner_edge = (d_top_right <= corner_cut + border_size) || (d_bot_right <= corner_cut + border_size);
	
	bool is_border = is_right_edge || is_top_edge || is_bottom_edge || is_corner_edge;
	
	// 4. Render warna
	if (is_border) {
		COLOR = vec4(border_color.rgb, border_color.a * alpha_fade);
	} else {
		COLOR = vec4(bg_color.rgb, bg_color.a * alpha_fade);
	}
}