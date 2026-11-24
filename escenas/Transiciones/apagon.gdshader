shader_type canvas_item;
render_mode unshaded;

uniform float intensidad : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 centro = (UV - vec2(0.5)) * vec2(1.25, 1.0);
	float vineta = smoothstep(0.12, 0.7, length(centro));
	float grano = fract(sin(dot(floor(UV * vec2(960.0, 540.0)), vec2(12.9898, 78.233)) + floor(TIME * 24.0)) * 43758.5453);
	COLOR = vec4(0.015, 0.025, 0.02, intensidad * (vineta * 0.72 + grano * 0.08));
}
