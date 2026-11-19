extends Control
## Cena de evolução especial: escuridão, raios de luz, silhueta piscando entre as formas,
## partículas sendo puxadas, clarão e revelação. Uso: await evo.run(monstro)

const FX = preload("res://scripts/fx.gd")

var rays: Rays
var spr: AnimatedSprite2D
var mat: ShaderMaterial
var label: Label
var t := 0.0
## Versão compacta (janelinha do idle): tudo na metade do tamanho.
var compact := false
var K := 1.0


class Rays extends Node2D:
	var t := 0.0
	var power := 0.0
	var col := Color.WHITE

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		if power <= 0.0:
			return
		for i in 16:
			var a := t * 0.6 + i * TAU / 16.0
			var w := 0.09
			var pts := PackedVector2Array([Vector2.ZERO, Vector2(cos(a - w), sin(a - w)) * 520.0, Vector2(cos(a + w), sin(a + w)) * 520.0])
			draw_colored_polygon(pts, Color(col, 0.10 * power * (0.6 + 0.4 * sin(t * 3.0 + i))))
		draw_circle(Vector2.ZERO, 70.0 * power, Color(col, 0.18 * power))


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	K = 0.5 if compact else 1.0
	size = Game.BASE * K
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = Game.make_theme()


func run(m: Dictionary) -> void:
	var old_id: int = m["id"]
	var new_id: int = Game.evo_target(m)
	var col: Color = Game.MONSTERS[old_id]["cor"]
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.01, 0.08, 0.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.size = Game.BASE * K
	add_child(bg)
	rays = Rays.new()
	rays.position = Vector2(320, 170) * K
	rays.scale = Vector2(K, K)
	rays.col = col.lightened(0.4)
	add_child(rays)
	spr = AnimatedSprite2D.new()
	spr.sprite_frames = Game.monster_frames(old_id)
	spr.play("idle")
	spr.centered = false
	spr.offset = Game.foot_offset(old_id)
	spr.scale = Vector2(2, 2) * K
	spr.position = Vector2(320, 250) * K
	spr.material = Game.sprite_mat()
	mat = spr.material
	spr.modulate.a = 0.0
	add_child(spr)
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(640, 20) * K
	label.position = Vector2(0, 300) * K
	label.add_theme_font_size_override("font_size", 10 if compact else 18)
	add_child(label)
	create_tween().tween_property(spr, "modulate:a", 1.0, 0.6)
	await create_tween().tween_property(bg, "color:a", 0.92, 0.6).finished
	label.text = "Hã? %s está reagindo ao vínculo..." % Game.MONSTERS[old_id]["nome"]
	await get_tree().create_timer(1.0).timeout
	label.text = ""
	# brilho crescente + partículas puxadas
	var tw := create_tween().set_parallel(true)
	tw.tween_property(rays, "power", 1.0, 1.2)
	tw.tween_method(func(v): mat.set_shader_parameter("silhouette", v), 0.0, 1.0, 1.2)
	var parts := CPUParticles2D.new()
	parts.position = Vector2(320, 170) * K
	parts.amount = 80
	parts.lifetime = 0.9
	parts.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
	parts.emission_sphere_radius = 200.0 * K
	parts.radial_accel_min = -520.0
	parts.radial_accel_max = -380.0
	parts.gravity = Vector2.ZERO
	parts.scale_amount_min = 2.0
	parts.scale_amount_max = 4.0
	var g := Gradient.new()
	g.set_color(0, Color(col.lightened(0.5), 0.0))
	g.set_color(1, Color.WHITE)
	parts.color_ramp = g
	add_child(parts)
	parts.emitting = true
	await tw.finished
	# silhueta alterna entre forma antiga e nova, cada vez mais rápido
	var new_frames := Game.monster_frames(new_id)
	var old_frames := Game.monster_frames(old_id)
	var delay := 0.4
	var flip := false
	while delay > 0.04:
		flip = not flip
		spr.sprite_frames = new_frames if flip else old_frames
		spr.play("idle")
		var pulse := create_tween()
		pulse.tween_property(spr, "scale", Vector2(2.2, 2.2) * K, delay * 0.4)
		pulse.tween_property(spr, "scale", Vector2(2.0, 2.0) * K, delay * 0.6)
		await get_tree().create_timer(delay).timeout
		delay *= 0.78
	# clarão
	spr.sprite_frames = new_frames
	spr.play("idle")
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 1)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.size = Game.BASE * K
	add_child(flash)
	parts.emitting = false
	mat.set_shader_parameter("silhouette", 0.0)
	await get_tree().create_timer(0.15).timeout
	create_tween().tween_property(flash, "color:a", 0.0, 0.8)
	# revelação
	m["id"] = new_id
	var old_max := Game.max_hp(m)
	m["hp"] = Game.max_hp(m)
	var burst := CPUParticles2D.new()
	burst.position = Vector2(320, 170) * K
	burst.amount = 70
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.lifetime = 1.4
	burst.spread = 180.0
	burst.initial_velocity_min = 80.0
	burst.initial_velocity_max = 260.0
	burst.gravity = Vector2(0, 60)
	burst.scale_amount_min = 2.0
	burst.scale_amount_max = 5.0
	var g2 := Gradient.new()
	g2.set_color(0, Color("ffd84a"))
	g2.set_color(1, Color(col, 0.0))
	burst.color_ramp = g2
	add_child(burst)
	burst.emitting = true
	spr.play("attack")
	spr.animation_finished.connect(func(): spr.play("idle"), CONNECT_ONE_SHOT)
	label.text = "%s evoluiu para %s!" % [Game.MONSTERS[old_id]["nome"], Game.MONSTERS[new_id]["nome"]]
	var ramo: String = Game.MONSTERS[new_id].get("ramo", "")
	if ramo != "":
		var rl := Label.new()
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rl.size = Vector2(640, 16) * K
		rl.position = Vector2(0, 324) * K
		rl.text = "Caminho da FÚRIA: seu jeito agressivo moldou a alma dele." if ramo == "furia" else "Caminho da GUARDA: sua paciência moldou a alma dele."
		if compact:
			rl.add_theme_font_size_override("font_size", 8)
			rl.text = "Caminho da FÚRIA" if ramo == "furia" else "Caminho da GUARDA"
		rl.add_theme_color_override("font_color", Color("ff8a5a") if ramo == "furia" else Color("8ac4ff"))
		rl.modulate.a = 0.0
		add_child(rl)
		create_tween().tween_property(rl, "modulate:a", 1.0, 0.6).set_delay(0.4)
	label.add_theme_color_override("font_color", Color("ffd84a"))
	label.pivot_offset = Vector2(320, 10) * K
	label.scale = Vector2(0.5, 0.5)
	create_tween().tween_property(label, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(2.6).timeout
	await create_tween().tween_property(self, "modulate:a", 0.0, 0.4).finished
	queue_free()
