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
	bg.color = Color(0.03, 0.01, 0.08, 0.6 if compact else 0.0)
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
	var hp0 := Game.max_hp(m)
	var atk0 := int(Game.stat(m, "atk") * 10)
	var def0 := int(Game.stat(m, "def") * 10)
	m["id"] = new_id
	Game.dex_register(m)
	m["hp"] = Game.max_hp(m)
	var gains := "Vida %d>%d   Ataque %d>%d   Defesa %d>%d   +2 Pontos de Alma" % [hp0, Game.max_hp(m), atk0, int(Game.stat(m, "atk") * 10), def0, int(Game.stat(m, "def") * 10)]
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
	var gl := Label.new()
	gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gl.size = Vector2(640, 14) * K
	gl.position = Vector2(0, 342 if not compact else 338) * K
	gl.text = gains
	gl.add_theme_font_size_override("font_size", 7 if compact else 10)
	gl.add_theme_color_override("font_color", Color("9effd8"))
	gl.modulate.a = 0.0
	add_child(gl)
	create_tween().tween_property(gl, "modulate:a", 1.0, 0.5).set_delay(0.7)
	label.add_theme_color_override("font_color", Color("ffd84a"))
	label.pivot_offset = Vector2(320, 10) * K
	label.scale = Vector2(0.5, 0.5)
	create_tween().tween_property(label, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(2.6).timeout
	await create_tween().tween_property(self, "modulate:a", 0.0, 0.4).finished
	queue_free()


## DESPERTAR (4ª forma): cena grande e dourada. A alma do Digialma se abre:
## anéis de runas, colunas de luz, a silhueta sobe, explode em ouro e volta
## com aura e nome novo.
func run_awaken(m: Dictionary) -> void:
	var id: int = m["id"]
	var col: Color = Game.MONSTERS[id]["cor"]
	var gold := Color("ffd25a")
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.01, 0.05, 0.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.size = Game.BASE * K
	add_child(bg)
	rays = Rays.new()
	rays.position = Vector2(320, 200) * K
	rays.scale = Vector2(K, K) * 1.4
	rays.col = gold
	add_child(rays)
	var rings := AwakenRings.new()
	rings.position = Vector2(320, 200) * K
	rings.scale = Vector2(K, K)
	add_child(rings)
	spr = AnimatedSprite2D.new()
	spr.sprite_frames = Game.monster_frames(id)
	spr.play("idle")
	spr.centered = false
	spr.offset = Game.foot_offset(id)
	spr.scale = Vector2(2, 2) * K
	spr.position = Vector2(320, 270) * K
	spr.material = Game.sprite_mat()
	mat = spr.material
	spr.modulate.a = 0.0
	add_child(spr)
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(640, 24) * K
	label.position = Vector2(0, 296) * K
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)
	create_tween().tween_property(spr, "modulate:a", 1.0, 0.8)
	await create_tween().tween_property(bg, "color:a", 0.95, 0.8).finished
	label.text = "O Cristal do Despertar ressoa com %s..." % Game.MONSTERS[id]["nome"]
	await get_tree().create_timer(1.4).timeout
	label.text = "Os três mundos purificados respondem!"
	# runas giram, sobem 3 colunas de luz
	var tw := create_tween().set_parallel(true)
	tw.tween_property(rings, "power", 1.0, 1.6)
	tw.tween_property(rays, "power", 0.6, 1.6)
	await tw.finished
	for i in 3:
		var col_l := LightColumn.new()
		col_l.position = Vector2(200 + i * 120, 0) * K
		col_l.h = 360.0 * K
		col_l.col = [gold, col.lightened(0.4), Color("bff6ff")][i]
		add_child(col_l)
		Game.sfx("zona", -4.0, 0.0)
		await get_tree().create_timer(0.45).timeout
	label.text = ""
	# a silhueta sobe e pulsa cada vez mais rápido
	create_tween().tween_method(func(v): mat.set_shader_parameter("silhouette", v), 0.0, 1.0, 1.0)
	create_tween().tween_property(spr, "position:y", 240.0 * K, 1.6).set_trans(Tween.TRANS_SINE)
	var delay := 0.5
	while delay > 0.05:
		var p := create_tween()
		p.tween_property(spr, "scale", Vector2(2.35, 2.35) * K, delay * 0.4)
		p.tween_property(spr, "scale", Vector2(2.0, 2.0) * K, delay * 0.6)
		await get_tree().create_timer(delay).timeout
		delay *= 0.8
	# explosão dourada
	var flash := ColorRect.new()
	flash.color = Color(1, 0.95, 0.7, 1)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.size = Game.BASE * K
	add_child(flash)
	Game.awaken(m)
	# se a linha tem forma D desenhada, o sprite troca no clarão
	spr.sprite_frames = Game.monster_frames(m["id"])
	spr.offset = Game.foot_offset(m["id"])
	spr.play("idle")
	mat.set_shader_parameter("silhouette", 0.0)
	rays.power = 1.0
	await get_tree().create_timer(0.25).timeout
	create_tween().tween_property(flash, "color:a", 0.0, 1.2)
	var burst := CPUParticles2D.new()
	burst.position = Vector2(320, 200) * K
	burst.amount = 140
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.lifetime = 2.0
	burst.spread = 180.0
	burst.initial_velocity_min = 120.0 * K
	burst.initial_velocity_max = 380.0 * K
	burst.gravity = Vector2(0, 40)
	burst.scale_amount_min = 2.0
	burst.scale_amount_max = 6.0
	var g := Gradient.new()
	g.set_color(0, Color("fff3c0"))
	g.set_color(1, Color(gold, 0.0))
	burst.color_ramp = g
	add_child(burst)
	burst.emitting = true
	var aura := AwakenGlow.new()
	aura.position = Vector2(320, 230) * K
	aura.scale = Vector2(K, K) * 2.0
	add_child(aura)
	move_child(aura, spr.get_index())
	spr.play("attack")
	spr.animation_finished.connect(func(): spr.play("idle"), CONNECT_ONE_SHOT)
	if int(m["id"]) != id:
		label.text = "%s DESPERTOU: %s!" % [Game.MONSTERS[id]["nome"].to_upper(), Game.MONSTERS[m["id"]]["nome"].to_upper()]
	else:
		label.text = "%s DESPERTOU!" % Game.MONSTERS[id]["nome"].to_upper()
	label.add_theme_color_override("font_color", gold)
	label.pivot_offset = Vector2(320, 12) * K
	label.scale = Vector2(0.4, 0.4)
	create_tween().tween_property(label, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var sub := Label.new()
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(640, 16) * K
	sub.position = Vector2(0, 324) * K
	sub.text = "+25% em todos os atributos  ·  +5 Pontos de Alma  ·  Aura do Despertar"
	sub.add_theme_font_size_override("font_size", 10)
	sub.add_theme_color_override("font_color", Color("fff3c0"))
	sub.modulate.a = 0.0
	add_child(sub)
	create_tween().tween_property(sub, "modulate:a", 1.0, 0.6).set_delay(0.6)
	await get_tree().create_timer(4.0).timeout
	await create_tween().tween_property(self, "modulate:a", 0.0, 0.6).finished
	queue_free()


class AwakenRings extends Node2D:
	var t := 0.0
	var power := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		if power <= 0.0:
			return
		for ring in 3:
			var r := 70.0 + ring * 34.0
			var n := 10 + ring * 4
			var dir := 1.0 if ring % 2 == 0 else -1.0
			draw_arc(Vector2.ZERO, r, 0, TAU, 64, Color(1, 0.85, 0.35, 0.35 * power), 2.0)
			for i in n:
				var a := TAU * i / n + t * 0.5 * dir
				var p := Vector2(cos(a), sin(a) * 0.45) * r
				draw_rect(Rect2((p - Vector2(2, 2)).round(), Vector2(4, 4)), Color(1, 0.92, 0.6, 0.8 * power))


class LightColumn extends Node2D:
	var h := 360.0
	var col := Color.WHITE
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var w := 6.0 + minf(t, 0.4) * 30.0
		var a := clampf(1.0 - (t - 1.2) / 1.5, 0.0, 1.0)
		draw_rect(Rect2(Vector2(-w * 0.5, 0), Vector2(w, h)), Color(col, 0.18 * a))
		draw_rect(Rect2(Vector2(-w * 0.15, 0), Vector2(w * 0.3, h)), Color(col.lightened(0.5), 0.5 * a))
		if t > 3.0:
			queue_free()


class AwakenGlow extends Node2D:
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var p := 0.5 + 0.5 * sin(t * 3.0)
		for i in 6:
			draw_circle(Vector2.ZERO, 40.0 - i * 5.0 + p * 3.0, Color(1, 0.85, 0.35, 0.05 + i * 0.025))
