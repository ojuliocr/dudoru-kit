shader_type canvas_item;
// Faixa de brilho diagonal que atravessa a textura; só aparece onde há alpha.

uniform float progress = -1.0; // -0.2 a 1.2 atravessa a logo inteira
uniform float width = 0.1;
uniform float strength = 0.5;
uniform float slant = 0.35;

void fragment() {
	vec4 c = COLOR;
	float x = (UV.x + (1.0 - UV.y) * slant) / (1.0 + slant);
	float s = smoothstep(width, 0.0, abs(x - progress)) * strength;
	c.rgb = mix(c.rgb, vec3(1.0), s);
	COLOR = c;
}
