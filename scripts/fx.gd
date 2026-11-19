extends RefCounted
## Efeitos visuais reutilizáveis dos menus.

const LOGO_SHADER := """
shader_type canvas_item;
uniform float t = 0.0;
uniform float h = 24.0;
uniform float top_y = 0.0;
varying vec2 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	vec4 c = COLOR * texture(TEXTURE, UV);
	// só pinta o preenchimento (branco); contorno fica como está
	if (COLOR.r > 0.95 && COLOR.g > 0.95 && COLOR.b > 0.95) {
		float y = clamp((lp.y - top_y) / h, 0.0, 1.0);
		vec3 g1 = vec3(1.0, 0.97, 0.72);
		vec3 g2 = vec3(1.0, 0.78, 0.30);
		vec3 g3 = vec3(0.93, 0.40, 0.16);
		vec3 g = y < 0.5 ? mix(g1, g2, y * 2.0) : mix(g2, g3, (y - 0.5) * 2.0);
		// faixa de brilho que atravessa o logo
		float band = fract(t * 0.25) * 900.0 - 200.0;
		float s = smoothstep(18.0, 0.0, abs(lp.x - band + lp.y * 0.6));
		g = mix(g, vec3(1.0), s * 0.85);
		c.rgb = g;
	}
	COLOR = c;
}
"""

const BLUR_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float amount = 0.0;
void fragment() {
	vec2 ps = SCREEN_PIXEL_SIZE * 1.6 * amount;
	vec4 c = vec4(0.0);
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			c += texture(screen_tex, SCREEN_UV + vec2(float(x), float(y)) * ps);
		}
	}
	c /= 25.0;
	c.rgb = mix(c.rgb, c.rgb * vec3(0.32, 0.28, 0.55), amount * 0.85);
	COLOR = vec4(c.rgb, 1.0);
}
"""

const VIGNETTE_SHADER := """
shader_type canvas_item;
uniform float strength = 0.55;
void fragment() {
	vec2 d = UV - vec2(0.5);
	float v = smoothstep(0.35, 0.85, length(d * vec2(1.0, 1.25)));
	COLOR = vec4(0.04, 0.02, 0.10, v * strength);
}
"""


static func shader_mat(code: String) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


## Faz o botão "pular" ao passar o mouse/ganhar foco e afundar ao clicar.
static func juice_button(b: Button) -> void:
	b.resized.connect(func(): b.pivot_offset = b.size * 0.5)
	var grow := func():
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2(1.08, 1.08), 0.08).set_trans(Tween.TRANS_BACK)
		tw.tween_property(b, "scale", Vector2(1.04, 1.04), 0.08)
	var shrink := func():
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2.ONE, 0.1)
	b.mouse_entered.connect(func(): b.grab_focus())
	b.focus_entered.connect(grow)
	b.focus_exited.connect(shrink)
	b.button_down.connect(func(): b.scale = Vector2(0.96, 0.96))
	b.button_up.connect(func(): b.scale = Vector2(1.04, 1.04))


## Entrada em cascata: cada filho desliza e aparece com atraso.
static func cascade_in(nodes: Array, from := Vector2(40, 0), delay := 0.05) -> void:
	var i := 0
	for n in nodes:
		var c := n as Control
		if c == null:
			continue
		# Funciona dentro de containers: anima só transparência e escala.
		c.modulate.a = 0.0
		c.pivot_offset = c.size * 0.5 if c.size != Vector2.ZERO else Vector2.ZERO
		c.scale = Vector2(0.85, 0.85) if from != Vector2.ZERO else Vector2.ONE
		var tw := c.create_tween()
		tw.tween_interval(i * delay)
		tw.set_parallel(true)
		tw.tween_property(c, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "modulate:a", 1.0, 0.2)
		i += 1
