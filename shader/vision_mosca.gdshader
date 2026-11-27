shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
// Radio en píxeles: independiente de la relación de aspecto de la ventana.
uniform float radio_hexagono : hint_range(24.0, 240.0, 1.0) = 100.0;
uniform float grosor_borde : hint_range(0.0, 12.0, 0.5) = 2.0;
// Curvatura del mosaico completo; cero recupera la retícula plana.
uniform float curvatura_global : hint_range(-25, 1.5, 0.01) = 0.65;
// Separación RGB radial dentro de cada lente, en coordenadas de su imagen.
uniform float aberracion_cromatica : hint_range(0.0, 0.05, 0.001) = 0.012;
uniform float distorsion : hint_range(0.0, 1.0, 0.01) = 0.15;
uniform vec4 color_borde : source_color = vec4(0.025, 0.035, 0.02, 1.0);

void fragment() {
	float radio = max(radio_hexagono, 1.0);
	vec2 pantalla = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 centrado = (SCREEN_UV - vec2(0.5)) * pantalla;
	// Distancia en píxeles para mantener la curvatura circular en cualquier formato.
	vec2 radial = centrado / (length(pantalla) * 0.5);
	vec2 punto = centrado * (1.0 + curvatura_global * dot(radial, radial)) / radio;
	// Dos retículas alternas: el centro más próximo define cada hexágono.
	vec2 paso = vec2(1.732050808, 3.0);
	vec2 a = punto - paso * floor(punto / paso + vec2(0.5));
	vec2 b = punto - paso * (floor(punto / paso) + vec2(0.5));
	vec2 local = dot(a, a) < dot(b, b) ? a : b;
	vec2 lente = local / vec2(0.866025404, 1.0);
	lente *= 1.0 + distorsion * dot(local, local);
	vec2 uv = clamp(vec2(0.5) + lente * 0.5, vec2(0.0), vec2(1.0));
	// El desplazamiento nace en el centro de CADA hexágono y aumenta al borde.
	vec2 separacion = lente * dot(local, local) * aberracion_cromatica;
	vec3 vista;
	vista.r = texture(screen_tex, clamp(uv + separacion, vec2(0.0), vec2(1.0))).r;
	vista.g = texture(screen_tex, uv).g;
	vista.b = texture(screen_tex, clamp(uv - separacion, vec2(0.0), vec2(1.0))).b;
	float distancia_lado = max(abs(local.x), dot(abs(local), vec2(0.5, 0.866025404)));
	float distancia_borde = (0.866025404 - distancia_lado) * radio;
	float borde = 1.0 - smoothstep(grosor_borde * 0.5, grosor_borde * 0.5 + max(fwidth(distancia_borde), 0.5), distancia_borde);
	borde *= step(0.001, grosor_borde) * color_borde.a;
	COLOR = vec4(mix(vista, color_borde.rgb, borde), 1.0);
}
