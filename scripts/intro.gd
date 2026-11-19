extends Control
## Introdução: o Elo cai do céu, conversa com o jogador e ele escolhe o primeiro parceiro.

const FX = preload("res://scripts/fx.gd")
const Dialog = preload("res://scripts/dialog.gd")
const STARTERS := [7, 12, 1]

var dialog: Dialog
var stars: Stars
var picked := -1


class Stars extends Node2D:
	var t := 0.0
	var pts: Array = []

	func _ready() -> void:
		for i in 70:
			pts.append(Vector3(randf() * 640, randf() * 170, randf() * TAU))

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		for p in pts:
			var a := 0.4 + 0.6 * absf(sin(t * 1.5 + p.z))
			draw_rect(Rect2(Vector2(p.x, p.y).round(), Vector2(1, 1)), Color(1, 1, 0.9, a))


func _ready() -> void:
	theme = Game.make_theme()
	var bg := TextureRect.new()
	bg.texture = Game.tex(Game.MP + "backgrounds/background1.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.22, 0.26, 0.5)
	add_child(bg)
	stars = Stars.new()
	add_child(stars)
	var kid := AnimatedSprite2D.new()
	kid.sprite_frames = Game.char_frames(Game.player_char)
	kid.play("idle_right")
	kid.position = Vector2(230, 200)
	kid.modulate = Color(0.55, 0.6, 0.9)
	add_child(kid)
	dialog = Dialog.new()
	add_child(dialog)
	_run()


func _run() -> void:
	await get_tree().create_timer(0.8).timeout
	# o Elo cai riscando o céu
	var elo := TextureRect.new()
	elo.texture = Game.tex("res://assets/items/elo_px.png")
	elo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	elo.size = Vector2(48, 60)
	elo.position = Vector2(620, -40)
	add_child(elo)
	var trail := CPUParticles2D.new()
	trail.amount = 60
	trail.lifetime = 0.7
	trail.gravity = Vector2.ZERO
	trail.initial_velocity_max = 10.0
	trail.scale_amount_min = 2.0
	trail.scale_amount_max = 4.0
	var g := Gradient.new()
	g.set_color(0, Color("5cff9c"))
	g.set_color(1, Color(0.36, 1, 0.6, 0))
	trail.color_ramp = g
	trail.position = Vector2(24, 22)
	elo.add_child(trail)
	trail.emitting = true
	var tw := create_tween()
	tw.tween_property(elo, "position", Vector2(290, 200), 1.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	trail.emitting = false
	var glow := ColorRect.new()
	glow.color = Color(0.4, 1, 0.6, 0.6)
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.size = Game.BASE
	add_child(glow)
	create_tween().tween_property(glow, "color:a", 0.0, 0.7)
	var bob := create_tween().set_loops()
	bob.tween_property(elo, "position:y", 194.0, 0.6).set_trans(Tween.TRANS_SINE)
	bob.tween_property(elo, "position:y", 200.0, 0.6).set_trans(Tween.TRANS_SINE)
	await dialog.play(Game.STORY["intro"])
	bob.kill()
	_choose_starter()


func _choose_starter() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.01, 0.08, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.size = Game.BASE
	add_child(dim)
	var panel := PanelContainer.new()
	panel.position = Vector2(40, 34)
	panel.custom_minimum_size = Vector2(560, 0)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	var title := Label.new()
	Game.heading(title, "ESCOLHA SEU PARCEIRO", 16)
	title.add_theme_color_override("font_color", Color("ffd84a"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var info := Label.new()
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(520, 24)
	var go := Button.new()
	go.text = "ESTE É O MEU PARCEIRO!"
	go.custom_minimum_size = Vector2(200, 24)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.disabled = true
	FX.juice_button(go)
	var cards: Array = []
	for id in STARTERS:
		var d: Dictionary = Game.MONSTERS[id]
		var c := Button.new()
		c.custom_minimum_size = Vector2(164, 170)
		for st in ["normal", "disabled"]:
			c.add_theme_stylebox_override(st, Game.sb("slot", 5))
		for st in ["hover", "focus", "pressed", "hover_pressed"]:
			c.add_theme_stylebox_override(st, Game.sb("slot_sel", 5))
		var glow := ColorRect.new()
		glow.color = Color(d["cor"], 0.0)
		glow.position = Vector2(6, 6)
		glow.size = Vector2(152, 130)
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(glow)
		var s := AnimatedSprite2D.new()
		s.sprite_frames = Game.monster_frames(id)
		s.play("idle")
		s.centered = false
		s.offset = Vector2(-48, -96)
		s.flip_h = true
		s.scale = Vector2(1.5, 1.5)
		s.position = Vector2(82, 140)
		c.add_child(s)
		var nl := Label.new()
		nl.text = "%s\n%s" % [d["nome"], d["tipo"].to_upper()]
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.add_theme_color_override("font_color", d["cor"].lightened(0.3))
		nl.position = Vector2(0, 140)
		nl.size = Vector2(164, 26)
		c.add_child(nl)
		var sel := func():
			picked = id
			go.disabled = false
			info.text = "%s é %s. Tipo %s. Forte contra %s." % [d["nome"], d["jeito"], d["tipo"], ", ".join(Game.STRONG[d["tipo"]])]
			for k in cards:
				var on: bool = k["id"] == id
				k["btn"].modulate = Color.WHITE if on else Color(0.55, 0.55, 0.65)
				create_tween().tween_property(k["glow"], "color:a", 0.25 if on else 0.0, 0.2)
				k["spr"].play("attack" if on else "idle")
		c.pressed.connect(sel)
		c.focus_entered.connect(sel)
		c.mouse_entered.connect(func(): c.grab_focus())
		s.animation_finished.connect(func(): s.play("idle"))
		row.add_child(c)
		cards.append({"id": id, "btn": c, "glow": glow, "spr": s})
	v.add_child(info)
	go.pressed.connect(func():
		if picked < 0:
			return
		Game.new_game(picked)
		Game.change_scene("res://scenes/map.tscn"))
	v.add_child(go)
	panel.pivot_offset = Vector2(280, 130)
	panel.scale = Vector2(0.7, 0.7)
	create_tween().tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	(cards[0]["btn"] as Button).grab_focus.call_deferred()
