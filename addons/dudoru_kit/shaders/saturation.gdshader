shader_type canvas_item;
// Aumenta a saturação de tudo que o nó desenha (usado na pizza).
// Mesma conta do ajuste aplicado nos PNGs da cozinha: 1.2 = +20%.

uniform float saturation = 1.2;

void fragment() {
	vec4 c = COLOR;
	float gray = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(vec3(gray), c.rgb, saturation), c.a);
}
