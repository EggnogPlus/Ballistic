shader_type canvas_item;

uniform float radius = 0.5; // Radius of the circle (relative to UV coordinates)
uniform float outline_thickness = 0.03; // Thickness of the outline
uniform vec4 fill_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // Black fill
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // White outline

void fragment() {
	// Center the UV coordinates (assuming UV ranges from 0 to 1)
	vec2 uv = UV - vec2(0.5, 0.5);
	
	// Calculate distance from the center
	float dist = length(uv);
	
	// Define the circle's edge and outline boundaries
	float inner_edge = radius - outline_thickness * 0.5;
	float outer_edge = radius + outline_thickness * 0.5;
	
	// Use smoothstep for smooth transitions
	float fill = smoothstep(inner_edge - 0.005, inner_edge + 0.005, dist);
	float outline = smoothstep(outer_edge - 0.005, outer_edge + 0.005, dist);
	
	// Combine fill and outline
	if (dist <= inner_edge) {
		// Solid fill inside the circle
		COLOR = fill_color;
	} else if (dist <= outer_edge) {
		// Outline region
		COLOR = outline_color;
	} else {
		// Outside the circle and outline
		COLOR = vec4(0.0, 0.0, 0.0, 0.0); // Transparent
	}
	
	// Optional: Blend the edges for smoother appearance
	COLOR.a *= 1.0 - outline;
}