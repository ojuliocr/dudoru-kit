shader_type canvas_item;
// Seleção dos objetos da cozinha: brilho quente em volta do formato do sprite.
// bands = 0 deixa o brilho suave; 2 ou 3 deixa em faixas chapadas (estilo cel).

uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 glow_color : source_color = vec4(1.0, 0.714, 0.153, 1.0);
uniform float radius = 18.0;
uniform float strength : hint_range(0.0, 1.0) = 0.9;
uniform float bands = 0.0;
uniform float pulse_speed = 3.0;
uniform float pulse_amount : hint_range(0.0, 0.5) = 0.0;

// Aumenta o retângulo desenhado para o brilho caber fora do sprite. Precisa ser >= radius.
const float GROW = 24.0;

varying vec4 tint;

void vertex() {
	tint = COLOR;
	vec2 dir = UV * 2.0 - 1.0;
	VERTEX += dir * GROW;
	UV += dir * GROW * TEXTURE_PIXEL_SIZE;
}

float inside(vec2 uv) {
	return step(0.0, uv.x) * step(0.0, uv.y) * step(uv.x, 1.0) * step(uv.y, 1.0);
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	base.a *= inside(UV);
	vec4 result = base;

	if (amount > 0.0) {
		// Média ponderada do alfa em anéis em volta do pixel = um blur barato da silhueta.
		float sum = 0.0;
		float total = 0.0;
		for (int k = 1; k <= 4; k++) {
			float r = radius * float(k) / 4.0;
			float w = 1.2 - float(k) * 0.2;
			for (int i = 0; i < 16; i++) {
				float ang = float(i) * 6.2831853 / 16.0;
				vec2 uv = UV + vec2(cos(ang), sin(ang)) * r * TEXTURE_PIXEL_SIZE;
				sum += texture(TEXTURE, uv).a * inside(uv) * w;
				total += w;
			}
		}
		float g = smoothstep(0.0, 1.0, clamp(sum / total / 0.35, 0.0, 1.0));
		if (bands > 0.0) {
			g = clamp(ceil(g * bands - 0.15) / bands, 0.0, 1.0);
		}
		float pulse = 1.0 - pulse_amount + pulse_amount * sin(TIME * pulse_speed);
		float ga = g * strength * amount * pulse;

		float a = base.a + ga * (1.0 - base.a);
		vec3 rgb = a > 0.0 ? (base.rgb * base.a + glow_color.rgb * ga * (1.0 - base.a)) / a : vec3(0.0);
		result = vec4(rgb, a);
	}
	COLOR = result * tint;
}
