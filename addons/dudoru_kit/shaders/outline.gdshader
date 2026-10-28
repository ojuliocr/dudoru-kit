shader_type canvas_item;
// Contorno por dentro da borda do sprite (não precisa de margem na textura,
// funciona em TextureRect, NinePatchRect, StyleBoxTexture e draw_texture_rect).
// Uso: ShaderMaterial num TextureRect/NinePatchRect etc.; ajuste `width` e `outline_color`.

uniform vec4 outline_color : source_color = vec4(0.204, 0.141, 0.110, 1.0);
// Espessura em pixels da TEXTURA (não da tela).
uniform float width : hint_range(0.0, 16.0) = 3.0;

const int DIRS = 16;

// TEXTURE só existe dentro do fragment(), então a textura vem por parâmetro.
float alpha_at(sampler2D tex, vec2 uv) {
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return 0.0; // fora da textura conta como transparente
	}
	return texture(tex, uv).a;
}

void fragment() {
	vec4 base = COLOR;
	if (base.a > 0.0 && width > 0.0) {
		float edge = 0.0;
		for (int i = 0; i < DIRS; i++) {
			float ang = TAU * float(i) / float(DIRS);
			vec2 d = vec2(cos(ang), sin(ang)) * TEXTURE_PIXEL_SIZE * width;
			edge = max(edge, 1.0 - alpha_at(TEXTURE, UV + d));
			edge = max(edge, 1.0 - alpha_at(TEXTURE, UV + d * 0.5));
		}
		COLOR.rgb = mix(base.rgb, outline_color.rgb, edge * outline_color.a);
		COLOR.a = base.a;
	}
}
