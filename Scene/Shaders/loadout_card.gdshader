shader_type canvas_item;

uniform vec4 bg_color : source_color = vec4(0.04, 0.06, 0.09, 0.95);
uniform vec4 border_color : source_color = vec4(0.22, 0.92, 1.0, 1.0);
uniform float corner_cut : hint_range(1.0, 25.0) = 10.0;
uniform float border_size : hint_range(1.0, 8.0) = 2.0;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec2 node_size = local_pos / max(UV, vec2(0.0001));
	vec2 p = local_pos;
	
	// Pemotongan 4 sudut chamfered / notched
	float d_tl = p.x + p.y;
	float d_tr = (node_size.x - p.x) + p.y;
	float d_bl = p.x + (node_size.y - p.y);
	float d_br = (node_size.x - p.x) + (node_size.y - p.y);
	
	if (d_tl < corner_cut || d_tr < corner_cut || d_bl < corner_cut || d_br < corner_cut) {
		discard;
	}
	
	// Deteksi garis tepi border
	bool is_edge_x = (p.x <= border_size) || (p.x >= node_size.x - border_size);
	bool is_edge_y = (p.y <= border_size) || (p.y >= node_size.y - border_size);
	bool is_edge_corner = (d_tl <= corner_cut + border_size) || 
	                      (d_tr <= corner_cut + border_size) || 
	                      (d_bl <= corner_cut + border_size) || 
	                      (d_br <= corner_cut + border_size);
	
	if (is_edge_x || is_edge_y || is_edge_corner) {
		COLOR = border_color;
	} else {
		COLOR = bg_color;
	}
}