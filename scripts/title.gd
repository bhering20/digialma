extends Control
## Tela inicial: logo animado, cenário vivo, menu principal, escolha de personagem e opções.

const FX = preload("res://scripts/fx.gd")

enum St { PRESS, MENU, SELECT, OPTIONS }
var state := St.PRESS
var t := 0.0
var logo: LogoNode
var fx_layer: FxLayer
var press_label: Label
var menu_box: VBoxContainer
var hand: TextureRect
var select_root: Control
var options_root: Control
var cards: Array = []
var chosen := "player"
var name_edit: LineEdit
var dim: ColorRect


class LogoNode extends Node2D:
	var font: Font
	var sub_font: Font
	var t := 0.0
	var mat: ShaderMaterial
	const SIZE := 40

	func _draw() -> void:
		var txt: String = Game.GAME_TITLE
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x
		var p := Vector2(-w * 0.5, 0)
		# sombra longa estilo arcade
		for i in range(6, 0, -1):
			draw_string_outline(font, p + Vector2(i, i), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, 8, Color(0.07, 0.03, 0.16, 1))
		draw_string_outline(font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, 8, Color("2a1640"))
		draw_string_outline(font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, 3, Color("ff8a3d"))
		draw_string(font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, Color.WHITE)
		var st: String = Game.GAME_SUBTITLE.to_upper()
		var sw := sub_font.get_string_size(st, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		var sp := Vector2(-sw * 0.5, 22)
		draw_rect(Rect2(sp.x - 10, sp.y - 10, sw + 20, 14), Color(0.07, 0.03, 0.16, 0.85))
		draw_rect(Rect2(sp.x - 10, sp.y - 10, sw + 20, 1), Color("ffd84a"))
		draw_rect(Rect2(sp.x - 10, sp.y + 3, sw + 20, 1), Color("ffd84a"))
		draw_string(sub_font, sp, st, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("bff6ff"))


## Camada de partículas: vaga-lumes, folhas caindo e raios de luz.
class FxLayer extends Node2D:
	var t := 0.0
	var flies: Array = []
	var leaves: Array = []
	var rng := RandomNumberGenerator.new()

	func _ready() -> void:
		rng.randomize()
		for i in 28:
			flies.append({"p": Vector2(rng.randf_range(0, 640), rng.randf_range(120, 330)), "ph": rng.randf() * TAU, "s": rng.randf_range(0.5, 1.2)})
		for i in 14:
			leaves.append({"p": Vector2(rng.randf_range(0, 640), rng.randf_range(-360, 0)), "ph": rng.randf() * TAU, "v": rng.randf_range(14, 26), "c": [Color("8fd45a"), Color("ffc24a"), Color("ff8a5a")][i % 3]})

	func _process(delta: float) -> void:
		t += delta
		for l in leaves:
			l["p"].y += l["v"] * delta
			l["p"].x += sin(t * 1.3 + l["ph"]) * 14.0 * delta - 6.0 * delta
			if l["p"].y > 370:
				l["p"] = Vector2(rng.randf_range(0, 700), -10)
		queue_redraw()

	func _draw() -> void:
		# raios de sol
		for i in 4:
			var a := 0.05 + 0.03 * sin(t * 0.7 + i)
			var x0 := 380.0 + i * 70.0
			draw_colored_polygon(PackedVector2Array([Vector2(x0, -10), Vector2(x0 + 30, -10), Vector2(x0 - 140, 380), Vector2(x0 - 210, 380)]), Color(1, 0.95, 0.7, a))
		for f in flies:
			var p: Vector2 = f["p"] + Vector2(sin(t * f["s"] + f["ph"]) * 12.0, cos(t * f["s"] * 1.3 + f["ph"]) * 8.0)
			var a := 0.5 + 0.5 * sin(t * 3.0 + f["ph"])
			draw_circle(p.round(), 3.0, Color(1, 0.95, 0.5, a * 0.25))
			draw_rect(Rect2(p.round(), Vector2(1, 1)), Color(1, 1, 0.8, a))
		for l in leaves:
			var p: Vector2 = (l["p"] as Vector2).round()
			var flip := int(t * 4.0 + l["ph"]) % 2 == 0
			draw_rect(Rect2(p, Vector2(3 if flip else 2, 2)), l["c"])
			draw_rect(Rect2(p + Vector2(1, 2), Vector2(1, 1)), (l["c"] as Color).darkened(0.3))


func _ready() -> void:
	theme = Game.make_theme()
	_build_scene()
	_build_menu()
	_build_select()
	var ver := Label.new()
	ver.text = "v%s · versão de teste" % Game.VERSION
	ver.add_theme_font_size_override("font_size", 8)
	ver.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	ver.position = Vector2(500, 344)
	add_child(ver)
	_build_options()
	_intro()


func _process(delta: float) -> void:
	t += delta
	logo.t = t
	logo.mat.set_shader_parameter("t", t)
	if state != St.PRESS or logo.position.y >= 60.0:
		logo.position.y = 64.0 + sin(t * 1.6) * 2.0
	press_label.modulate.a = 0.35 + 0.65 * absf(sin(t * 2.5))
	_update_hand()


func _unhandled_input(event: InputEvent) -> void:
	if state == St.PRESS and (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) and event.is_pressed():
		_show_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and (state == St.SELECT or state == St.OPTIONS):
		_back_to_menu()


# ---------------------------------------------------------------- montagem
func _build_scene() -> void:
	var bg := TextureRect.new()
	bg.texture = Game.tex(Game.MP + "backgrounds/background1.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	fx_layer = FxLayer.new()
	add_child(fx_layer)
	# monstros (formas finais) à direita, olhando para a esquerda
	# iniciais em 2x (mesma densidade de pixel das crianças)
	var mons := [[1, Vector2(392, 336)], [7, Vector2(484, 340)], [12, Vector2(576, 336)]]
	for m in mons:
		var s := AnimatedSprite2D.new()
		s.sprite_frames = Game.monster_frames(m[0])
		s.play("idle")
		s.frame = randi() % 4
		s.centered = false
		s.offset = Game.foot_offset(m[0])
		s.scale = Vector2(2, 2)
		s.position = m[1]
		add_child(s)
	# crianças à esquerda
	var kids := [["player", Vector2(84, 342)], ["young_girl", Vector2(170, 342)]]
	for k in kids:
		var s := AnimatedSprite2D.new()
		s.sprite_frames = Game.char_frames(k[0])
		s.play("idle_right")
		s.centered = false
		s.offset = Vector2(-64, -128)
		s.position = k[1]
		add_child(s)
	var vig := ColorRect.new()
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.size = Game.BASE
	vig.material = FX.shader_mat(FX.VIGNETTE_SHADER)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vig)
	logo = LogoNode.new()
	logo.font = Game.font_title
	logo.sub_font = Game.font
	logo.mat = FX.shader_mat(FX.LOGO_SHADER)
	logo.mat.set_shader_parameter("h", 34.0)
	logo.mat.set_shader_parameter("top_y", -32.0)
	logo.material = logo.mat
	logo.position = Vector2(320, -80)
	add_child(logo)
	press_label = Label.new()
	press_label.text = "PRESSIONE QUALQUER TECLA"
	press_label.add_theme_font_override("font", Game.font_title)
	press_label.add_theme_font_size_override("font_size", 8)
	press_label.add_theme_color_override("font_color", Color("fff6e8"))
	press_label.add_theme_color_override("font_outline_color", Color("2a1640"))
	press_label.add_theme_constant_override("outline_size", 4)
	press_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	press_label.size = Vector2(640, 12)
	press_label.position = Vector2(0, 200)
	add_child(press_label)
	var ver := Label.new()
	ver.text = "v0.4  protótipo"
	ver.add_theme_font_size_override("font_size", 9)
	ver.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	ver.position = Vector2(560, 346)
	add_child(ver)


func _build_menu() -> void:
	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 5)
	menu_box.custom_minimum_size = Vector2(150, 0)
	menu_box.position = Vector2(245, 128)
	menu_box.size = Vector2(150, 0)
	menu_box.visible = false
	add_child(menu_box)
	var items := [["NOVO JOGO", _on_new], ["CONTINUAR", _on_continue], ["MODO IDLE", _on_idle], ["OPÇÕES", _on_options], ["SAIR", _on_quit]]
	if Game.TEST_BUILD:
		items.insert(3, ["TESTE: MID GAME", _on_teste_mid])
	for it in items:
		var b := Button.new()
		b.text = it[0]
		b.custom_minimum_size = Vector2(150, 22)
		b.pressed.connect(it[1])
		FX.juice_button(b)
		menu_box.add_child(b)
	hand = TextureRect.new()
	hand.texture = Game.tex(Game.GP + "ui/hand.png")
	hand.visible = false
	hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hand)


func _build_select() -> void:
	select_root = Control.new()
	select_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	select_root.size = Game.BASE
	select_root.visible = false
	add_child(select_root)
	dim = ColorRect.new()
	dim.color = Color(0.04, 0.02, 0.1, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.size = Game.BASE
	select_root.add_child(dim)
	var panel := PanelContainer.new()
	panel.position = Vector2(110, 46)
	panel.custom_minimum_size = Vector2(420, 0)
	select_root.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	var title := Label.new()
	title.text = "ESCOLHA SEU PERSONAGEM"
	title.add_theme_font_override("font", Game.font_title)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("ffd84a"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	for key in ["player", "young_girl"]:
		var card := Button.new()
		card.custom_minimum_size = Vector2(150, 150)
		card.toggle_mode = true
		card.add_theme_stylebox_override("normal", Game.sb("slot", 5))
		card.add_theme_stylebox_override("hover", Game.sb("slot_sel", 5))
		card.add_theme_stylebox_override("focus", Game.sb("slot_sel", 5))
		card.add_theme_stylebox_override("pressed", Game.sb("slot_sel", 5))
		card.add_theme_stylebox_override("hover_pressed", Game.sb("slot_sel", 5))
		var info: Dictionary = Game.CHARACTERS[key]
		var glow := ColorRect.new()
		glow.color = Color(info["cor"], 0.0)
		glow.position = Vector2(6, 6)
		glow.size = Vector2(138, 112)
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(glow)
		var spr := AnimatedSprite2D.new()
		spr.sprite_frames = Game.char_frames(key)
		spr.play("idle_down")
		spr.position = Vector2(75, 62)
		card.add_child(spr)
		var lb := Label.new()
		lb.text = "%s\n%s" % [info["nome"], info["titulo"]]
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.position = Vector2(0, 120)
		lb.size = Vector2(150, 24)
		card.add_child(lb)
		card.pressed.connect(func(): _choose(key))
		card.mouse_entered.connect(func(): card.grab_focus())
		card.focus_entered.connect(func(): _choose(key))
		row.add_child(card)
		cards.append({"key": key, "card": card, "spr": spr, "glow": glow})
	var nh := HBoxContainer.new()
	nh.alignment = BoxContainer.ALIGNMENT_CENTER
	nh.add_theme_constant_override("separation", 6)
	var nl := Label.new()
	nl.text = "NOME:"
	nh.add_child(nl)
	name_edit = LineEdit.new()
	name_edit.custom_minimum_size = Vector2(140, 20)
	name_edit.max_length = 12
	name_edit.text = "Léo"
	nh.add_child(name_edit)
	v.add_child(nh)
	var bh := HBoxContainer.new()
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	bh.add_theme_constant_override("separation", 10)
	var back := Button.new()
	back.text = "VOLTAR"
	back.custom_minimum_size = Vector2(100, 22)
	back.pressed.connect(_back_to_menu)
	FX.juice_button(back)
	var go := Button.new()
	go.text = "COMEÇAR AVENTURA!"
	go.custom_minimum_size = Vector2(170, 22)
	go.pressed.connect(_start_game)
	FX.juice_button(go)
	bh.add_child(back)
	bh.add_child(go)
	v.add_child(bh)


func _build_options() -> void:
	options_root = Control.new()
	options_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	options_root.size = Game.BASE
	options_root.visible = false
	add_child(options_root)
	var d := ColorRect.new()
	d.color = Color(0.04, 0.02, 0.1, 0.6)
	d.set_anchors_preset(Control.PRESET_FULL_RECT)
	d.size = Game.BASE
	options_root.add_child(d)
	var panel := PanelContainer.new()
	panel.position = Vector2(170, 100)
	panel.custom_minimum_size = Vector2(300, 0)
	options_root.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var title := Label.new()
	Game.heading(title, "OPÇÕES", 16)
	title.add_theme_color_override("font_color", Color("ffd84a"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	for k in ["musica", "efeitos"]:
		var h := HBoxContainer.new()
		var l := Label.new()
		l.text = "MÚSICA" if k == "musica" else "EFEITOS"
		l.custom_minimum_size = Vector2(80, 0)
		h.add_child(l)
		var s := HSlider.new()
		s.custom_minimum_size = Vector2(170, 16)
		s.value = Game.options[k]
		s.value_changed.connect(func(val): Game.options[k] = val)
		h.add_child(s)
		v.add_child(h)
	var wa := CheckButton.new()
	wa.text = "JANELA DE TEMPO AMPLA"
	wa.tooltip_text = "Deixa esquiva, aparo e anéis mais tolerantes."
	wa.button_pressed = Game.options["janela_ampla"]
	wa.toggled.connect(func(on): Game.options["janela_ampla"] = on)
	v.add_child(wa)
	var dc := CheckButton.new()
	dc.text = "DICAS DO ELO"
	dc.button_pressed = Game.options["dicas"]
	dc.toggled.connect(func(on): Game.options["dicas"] = on)
	v.add_child(dc)
	var sid := CheckButton.new()
	sid.text = "SONS DO IDLE (SUAVES)"
	sid.tooltip_text = "Plings baixinhos ao purificar, subir de nível, achar itens... Também dá para ligar/desligar na própria faixa."
	sid.button_pressed = Game.options.get("sons_idle", true)
	sid.toggled.connect(func(on): Game.options["sons_idle"] = on)
	v.add_child(sid)
	var asom := CheckButton.new()
	asom.text = "ALERTA SONORO (RARO E SANTUÁRIO)"
	asom.tooltip_text = "O idle é silencioso; só toca um sininho quando um raro aparece ou o Santuário chega."
	asom.button_pressed = Game.options.get("alerta_som", true)
	asom.toggled.connect(func(on): Game.options["alerta_som"] = on)
	v.add_child(asom)
	var dfx := CheckButton.new()
	dfx.text = "DUELO NA FAIXA DO IDLE"
	dfx.tooltip_text = "Raros Épicos/Lendários lutam ali mesmo na faixa. Desligado: abre a batalha completa no painel."
	dfx.button_pressed = Game.options.get("duelo_faixa", true)
	dfx.toggled.connect(func(on): Game.options["duelo_faixa"] = on)
	v.add_child(dfx)
	var jc := CheckButton.new()
	jc.text = "JOGO EM JANELA COMPACTA"
	jc.tooltip_text = "Ao sair do idle, o jogo abre numa janela pequena no canto (estilo TBH)."
	jc.button_pressed = Game.options.get("jogo_compacto", true)
	jc.toggled.connect(func(on): Game.options["jogo_compacto"] = on)
	v.add_child(jc)
	var ps := Button.new()
	var ps_txt := func(): return "TAMANHO DO PAINEL: %d%%" % roundi(Game.options.get("painel", 1.25) * 100)
	ps.text = ps_txt.call()
	ps.tooltip_text = "Tamanho da janela da bolsa, duelos e jogo compacto."
	ps.pressed.connect(func():
		var i := Game.PANEL_SIZES.find(Game.options.get("painel", 1.25))
		Game.options["painel"] = Game.PANEL_SIZES[(i + 1) % Game.PANEL_SIZES.size()]
		ps.text = ps_txt.call())
	v.add_child(ps)
	var fs := CheckButton.new()
	fs.text = "TELA CHEIA"
	fs.button_pressed = Game.options["fullscreen"]
	fs.toggled.connect(func(on): Game.set_fullscreen(on))
	v.add_child(fs)
	var back := Button.new()
	back.text = "VOLTAR"
	back.custom_minimum_size = Vector2(120, 22)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_back_to_menu)
	FX.juice_button(back)
	v.add_child(back)


# ---------------------------------------------------------------- fluxo
func _intro() -> void:
	var tw := create_tween()
	tw.tween_property(logo, "position:y", 64.0, 0.9).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	press_label.modulate.a = 0.0


func _show_menu() -> void:
	state = St.MENU
	press_label.visible = false
	menu_box.visible = true
	await get_tree().process_frame
	FX.cascade_in(menu_box.get_children(), Vector2(0, 20), 0.07)
	(menu_box.get_child(0) as Button).grab_focus()


func _back_to_menu() -> void:
	state = St.MENU
	select_root.visible = false
	options_root.visible = false
	logo.visible = true
	menu_box.visible = true
	(menu_box.get_child(0) as Button).grab_focus()


func _pop(c: Control) -> void:
	c.visible = true
	var p := c.get_child(1) as Control
	p.pivot_offset = p.size * 0.5
	p.scale = Vector2(0.7, 0.7)
	p.modulate.a = 0.0
	var tw := c.create_tween().set_parallel(true)
	tw.tween_property(p, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "modulate:a", 1.0, 0.2)


func _on_new() -> void:
	state = St.SELECT
	menu_box.visible = false
	logo.visible = false
	_pop(select_root)
	(cards[0]["card"] as Button).grab_focus()


func _on_continue() -> void:
	Game.change_scene("res://scenes/map.tscn" if Game.team.size() > 0 else "res://scenes/intro.tscn")


func _on_idle() -> void:
	# sem time ainda: começa direto na faixa com o Brasito
	if Game.team.is_empty():
		Game.new_game(7)
	Game.region = mini(Game.badges, Game.REGIONS.size() - 1)
	Game.change_scene("res://scenes/idle.tscn")


## Só nas versões de teste: começa no Pântano Sombrio com um time pronto.
## O save anterior é guardado em user://save_antes_do_teste.json.
func _on_teste_mid() -> void:
	Game.start_test_mid()
	Game.change_scene("res://scenes/idle.tscn")


func _on_options() -> void:
	state = St.OPTIONS
	menu_box.visible = false
	logo.visible = false
	_pop(options_root)


func _on_quit() -> void:
	Game.quit_game()


func _choose(key: String) -> void:
	chosen = key
	var info: Dictionary = Game.CHARACTERS[key]
	if name_edit and (name_edit.text == "" or name_edit.text in ["Léo", "Lia"]):
		name_edit.text = info["nome"]
	for c in cards:
		var on: bool = c["key"] == key
		(c["spr"] as AnimatedSprite2D).play("down" if on else "idle_down")
		(c["card"] as Button).modulate = Color.WHITE if on else Color(0.6, 0.6, 0.7)
		var g: ColorRect = c["glow"]
		var tw := g.create_tween()
		tw.tween_property(g, "color:a", 0.22 if on else 0.0, 0.2)


func _start_game() -> void:
	Game.player_char = chosen
	Game.player_name = name_edit.text if name_edit.text.strip_edges() != "" else Game.CHARACTERS[chosen]["nome"]
	Game.change_scene("res://scenes/intro.tscn")


func _update_hand() -> void:
	var f := get_viewport().gui_get_focus_owner()
	if f is Button and f.is_visible_in_tree() and (state == St.MENU or state == St.SELECT or state == St.OPTIONS) and not (f in cards.map(func(c): return c["card"])):
		hand.visible = true
		var r: Rect2 = f.get_global_rect()
		var target := Vector2(r.position.x - 30 + sin(t * 8.0) * 2.0, r.position.y + r.size.y * 0.5 - 16)
		hand.position = hand.position.lerp(target, 0.35) if hand.position.distance_to(target) < 120 else target
	else:
		hand.visible = false
