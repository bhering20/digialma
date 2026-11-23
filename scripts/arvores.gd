extends Control
## ÁRVORES: Árvore de Alma (por Digialma, com Pontos de Alma), Árvore do Elo
## (upgrades comprados com bits) e Equipe (escolher quem vai para o time).

const FX = preload("res://scripts/fx.gd")

var tab := "itens"
var sel := 0  # índice na lista (equipe + reserva)
var body: Control
var info: Label
var tabs: Dictionary = {}
var bits_l: Label


func _ready() -> void:
	theme = Game.make_theme()
	var bg := TextureRect.new()
	bg.texture = Game.tex(Game.MP + "backgrounds/background1.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.3, 0.27, 0.45)
	add_child(bg)
	var amb = preload("res://scripts/ambient.gd").new()
	amb.kind = "floresta"
	add_child(amb)
	var title := Label.new()
	Game.heading(title, "MENU", 16)
	title.add_theme_color_override("font_color", Color("ffd84a"))
	title.position = Vector2(16, 10)
	add_child(title)
	var th := HBoxContainer.new()
	th.position = Vector2(84, 10)
	th.add_theme_constant_override("separation", 2)
	add_child(th)
	if Game.return_to.begins_with("tab:"):
		tab = Game.return_to.substr(4)
	for k in [["itens", "AMULETOS"], ["mochila", "MOCHILA"], ["alma", "ALMA"], ["fusao", "FUSÃO"], ["elo", "ELO"], ["insignias", "INSÍGNIAS"], ["equipe", "EQUIPE"]]:
		var b := Button.new()
		b.text = k[1]
		b.custom_minimum_size = Vector2(48, 22)
		b.add_theme_font_size_override("font_size", 8)
		var key: String = k[0]
		b.pressed.connect(func():
			tab = key
			_build())
		FX.juice_button(b)
		th.add_child(b)
		tabs[key] = b
	bits_l = Label.new()
	bits_l.position = Vector2(486, 8)
	bits_l.add_theme_color_override("font_color", Color("ffd84a"))
	add_child(bits_l)
	var back := Button.new()
	back.text = "VOLTAR"
	back.position = Vector2(560, 10)
	back.custom_minimum_size = Vector2(70, 22)
	back.text = "FECHAR" if Game.in_panel(self) else ("IDLE" if Game.return_to == "idle" else "VOLTAR")
	back.pressed.connect(func():
		if Game.in_panel(self):
			get_window().queue_free()
		elif Game.return_to == "idle":
			Game.return_to = ""
			Game.change_scene("res://scenes/idle.tscn")
		else:
			Game.change_scene("res://scenes/map.tscn"))
	add_child(back)
	body = Control.new()
	body.position = Vector2(0, 40)
	body.size = Vector2(640, 290)
	add_child(body)
	info = Label.new()
	info.position = Vector2(16, 334)
	info.size = Vector2(608, 20)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	add_child(info)
	_build()


func _all() -> Array:
	return Game.team + Game.reserve


func _build() -> void:
	for c in body.get_children():
		c.queue_free()
	for k in tabs:
		(tabs[k] as Button).modulate = Color("ffd84a") if k == tab else Color.WHITE
	bits_l.text = "BITS  %d\nCRISTAIS  %d" % [Game.bits, Game.cristais]
	bits_l.add_theme_font_size_override("font_size", 8)
	match tab:
		"itens":
			_build_itens()
		"mochila":
			_build_mochila()
		"alma":
			_build_alma()
		"fusao":
			_build_fusao()
		"elo":
			_build_elo()
		"insignias":
			_build_insignias()
		"equipe":
			_build_equipe()


# ---------------------------------------------------------------- ALMA
func _mon_list() -> void:
	var list := _all()
	sel = clampi(sel, 0, list.size() - 1)
	var sc := ScrollContainer.new()
	sc.position = Vector2(12, 4)
	sc.size = Vector2(156, 284)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(sc)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 3)
	sc.add_child(lv)
	for i in list.size():
		var m: Dictionary = list[i]
		Game.make_partner(m)
		var b := Button.new()
		b.custom_minimum_size = Vector2(148, 30)
		b.text = "%s Nv%d\n%s" % [Game.mon_name(m), m["lv"], ("PA %d" % m.get("pa", 0)) if tab == "alma" else Game.RARITY[int(m.get("rar", 0))]["nome"]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 8)
		b.add_theme_color_override("font_color", Game.rar_color(int(m.get("rar", 0))))
		if i == sel:
			b.modulate = Color(1.25, 1.2, 0.9)
		b.icon = Game.menu_icon(m["id"])
		var idx := i
		b.pressed.connect(func():
			sel = idx
			_build())
		lv.add_child(b)


func _build_alma() -> void:
	_mon_list()
	var m: Dictionary = _all()[sel]
	var tree := TreeView.new()
	tree.position = Vector2(170, 0)
	tree.size = Vector2(462, 290)
	tree.m = m
	tree.owner_ui = self
	body.add_child(tree)
	info.text = "Passe o mouse num nó para ver o que ele faz. Clique para gastar Pontos de Alma."


func _node_desc(m: Dictionary, k: String) -> String:
	var tipo: String = Game.MONSTERS[m["id"]]["tipo"]
	match k:
		"a1":
			var sp := ""
			for mk in Game.MONSTERS[m["id"]]["moves"]:
				if Game.MOVES[mk]["cd"] > 0:
					sp = mk
			if sp == "":
				sp = Game.TYPE_SPECIAL[tipo]
			return "Libera o golpe especial %s." % Game.MOVES[sp]["nome"]
		"f5":
			return "Libera o Golpe Supremo %s (custa 5 de Energia)." % Game.MOVES[Game.TYPE_SUPREME[tipo]]["nome"]
	return Game.SOUL_TREE[k]["desc"]


func _hover(m: Dictionary, k: String) -> void:
	if k == "":
		info.text = "Passe o mouse num nó para ver o que ele faz. Clique para gastar Pontos de Alma."
		return
	var nd: Dictionary = Game.SOUL_TREE[k]
	var st := "ADQUIRIDO" if m["tree"].has(k) else "%d PA" % nd["custo"]
	if not m["tree"].has(k) and nd["req"] != "" and not m["tree"].has(nd["req"]):
		st = "requer %s" % Game.SOUL_TREE[nd["req"]]["nome"]
	info.text = "%s  [%s]  —  %s" % [nd["nome"], st, _node_desc(m, k)]


func _buy_node(m: Dictionary, k: String) -> void:
	var nd: Dictionary = Game.SOUL_TREE[k]
	if m["tree"].has(k):
		return
	if nd["req"] != "" and not m["tree"].has(nd["req"]):
		info.text = "Primeiro desbloqueie %s." % Game.SOUL_TREE[nd["req"]]["nome"]
		return
	if m.get("pa", 0) < nd["custo"]:
		info.text = "Pontos de Alma insuficientes. Suba de nível (no idle ou nas batalhas)."
		return
	m["pa"] -= nd["custo"]
	m["tree"][k] = true
	_build()
	info.text = "%s despertou %s!" % [Game.mon_name(m), nd["nome"]]


## Teia da Árvore de Alma: nós redondos ligados por linhas, que acendem.
class TreeView extends Control:
	const COL := {"raiz": Color("ffe9a8"), "furia": Color("ff7a4a"), "guarda": Color("6ab8ff"), "vinculo": Color("7af0a0")}
	var m: Dictionary
	var owner_ui
	var hov := ""
	var t := 0.0
	var center := Vector2(231, 120)
	var portrait: Texture2D
	var fnt: Font

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		fnt = get_theme_font("font", "Label")
		portrait = Game.menu_icon(m["id"])

	func _process(d: float) -> void:
		t += d
		queue_redraw()

	func _p(k: String) -> Vector2:
		return center + Game.SOUL_TREE[k]["pos"]

	func _r(k: String) -> float:
		return 15.0 if Game.SOUL_TREE[k].get("chave", false) else 10.0

	func _state(k: String) -> int:
		# 2 = adquirido, 1 = disponível, 0 = trancado
		if m["tree"].has(k):
			return 2
		var req: String = Game.SOUL_TREE[k]["req"]
		return 1 if req == "" or m["tree"].has(req) else 0

	func _hit(pos: Vector2) -> String:
		for k in Game.SOUL_TREE:
			if pos.distance_to(_p(k)) <= _r(k) + 3.0:
				return k
		return ""

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseMotion:
			var k := _hit(e.position)
			if k != hov:
				hov = k
				owner_ui._hover(m, k)
				mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if k != "" else Control.CURSOR_ARROW
		elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			var k := _hit(e.position)
			if k != "":
				owner_ui._buy_node(m, k)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.02, 0.1, 0.6))
		# estrelinhas de fundo
		for i in 40:
			var h := (i * 7919) % 1000
			var sp := Vector2(float(h % 460), float((h * 37) % 288))
			draw_rect(Rect2(sp, Vector2(1, 1)), Color(1, 1, 1, 0.15 + 0.15 * sin(t * 1.5 + i)))
		# halo atrás do centro
		for i in 5:
			draw_circle(center, 44.0 - i * 6.0, Color(1, 0.9, 0.6, 0.025 + i * 0.012))
		# ligações
		for k in Game.SOUL_TREE:
			var req: String = Game.SOUL_TREE[k]["req"]
			if req == "":
				continue
			var a := _p(req)
			var b := _p(k)
			var dir := (b - a).normalized()
			a += dir * _r(req)
			b -= dir * _r(k)
			var st := _state(k)
			var c: Color = COL[Game.SOUL_TREE[k]["ramo"]]
			if st == 2:
				draw_line(a, b, c.darkened(0.3), 4.0)
				draw_line(a, b, c.lightened(0.3), 2.0)
			elif st == 1:
				draw_dashed_line(a, b, Color(c, 0.55 + 0.25 * sin(t * 4.0)), 2.0, 4.0)
			else:
				draw_dashed_line(a, b, Color(0.5, 0.45, 0.6, 0.35), 1.0, 3.0)
		# nós
		for k in Game.SOUL_TREE:
			var nd: Dictionary = Game.SOUL_TREE[k]
			var p := _p(k)
			var r := _r(k)
			var st := _state(k)
			var c: Color = COL[nd["ramo"]]
			var can_buy: bool = st == 1 and m.get("pa", 0) >= nd["custo"]
			if st == 2:
				draw_circle(p, r + 5.0, Color(c, 0.18 + 0.06 * sin(t * 2.0)))
			elif can_buy:
				draw_circle(p, r + 3.0 + 2.0 * sin(t * 5.0), Color(c, 0.25))
			var fill := c.darkened(0.55) if st == 2 else (Color("1c1430") if st == 1 else Color("120c1e"))
			draw_circle(p, r + 2.0, Color("0a0614"))
			draw_circle(p, r, fill)
			var ring := c if st == 2 else (Color(c, 0.85) if st == 1 else Color(0.4, 0.36, 0.5))
			draw_arc(p, r, 0, TAU, 32, ring, 2.0 if k != hov else 3.0)
			if nd.get("chave", false):
				draw_arc(p, r - 4.0, 0, TAU, 28, Color(ring, 0.6), 1.0)
			var ic := c.lightened(0.4) if st == 2 else (c if st == 1 else Color(0.45, 0.42, 0.55))
			_icon(k, nd["ramo"], p, r * 0.55, ic)
			if st != 2:
				var cost := str(nd["custo"])
				draw_circle(p + Vector2(r * 0.75, r * 0.75), 5.0, Color("0a0614"))
				draw_string(fnt, p + Vector2(r * 0.75 - 3, r * 0.75 + 3), cost, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("ffd84a") if can_buy else Color(0.6, 0.6, 0.7))
		# retrato no centro da CENTELHA
		if portrait and m["tree"].has("a1"):
			draw_texture(portrait, _p("a1") - portrait.get_size() * 0.5, Color(1, 1, 1, 0.9))
		# legenda dos ramos
		draw_string(fnt, Vector2(14, 20), "FÚRIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL["furia"])
		draw_string(fnt, Vector2(size.x - 50, 20), "GUARDA", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL["guarda"])
		draw_string(fnt, Vector2(center.x + 30, size.y - 14), "VÍNCULO", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL["vinculo"])
		draw_string(fnt, Vector2(size.x * 0.5 - 70, 20), "PONTOS DE ALMA: %d" % m.get("pa", 0), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("ffd84a"))

	func _icon(k: String, ramo: String, p: Vector2, s: float, c: Color) -> void:
		match ramo:
			"furia":
				for i in 3:
					var o := Vector2(-s * 0.6 + i * s * 0.6, 0)
					draw_line(p + o + Vector2(-s * 0.3, s * 0.8), p + o + Vector2(s * 0.3, -s * 0.8), c, 2.0)
			"guarda":
				var pts := PackedVector2Array([p + Vector2(-s, -s * 0.8), p + Vector2(s, -s * 0.8), p + Vector2(s * 0.8, s * 0.2), p + Vector2(0, s), p + Vector2(-s * 0.8, s * 0.2)])
				draw_colored_polygon(pts, Color(c, 0.35))
				pts.append(pts[0])
				draw_polyline(pts, c, 1.5)
			"vinculo":
				draw_circle(p + Vector2(-s * 0.45, -s * 0.25), s * 0.5, c)
				draw_circle(p + Vector2(s * 0.45, -s * 0.25), s * 0.5, c)
				draw_colored_polygon(PackedVector2Array([p + Vector2(-s * 0.92, -s * 0.05), p + Vector2(s * 0.92, -s * 0.05), p + Vector2(0, s * 0.9)]), c)
			_:
				var pts := PackedVector2Array()
				for i in 10:
					var rr := s * (1.1 if i % 2 == 0 else 0.45)
					var ang := -PI / 2 + i * PI / 5
					pts.append(p + Vector2(cos(ang), sin(ang)) * rr)
				draw_colored_polygon(pts, c)


# ---------------------------------------------------------------- ITENS
func _gear_style(rar: int, filled: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Game.rar_color(rar).darkened(0.75), 0.9) if filled else Color(0.06, 0.03, 0.12, 0.85)
	sb.border_color = Game.rar_color(rar) if filled else Color(0.4, 0.35, 0.55)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	return sb


func _gear_button(g: Dictionary, sz: float) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(sz, sz)
	b.focus_mode = Control.FOCUS_NONE
	var filled := not g.is_empty()
	var rar: int = g["rar"] if filled else 0
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb := _gear_style(rar, filled)
		if st == "hover":
			sb.bg_color = sb.bg_color.lightened(0.15)
			sb.set_border_width_all(3)
		b.add_theme_stylebox_override(st, sb)
	if filled:
		var ic := TextureRect.new()
		ic.texture = Game.tex("res://assets/gear/%s.png" % g["base"])
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.position = Vector2((sz - 36) * 0.5, (sz - 36) * 0.5)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(ic)
	return b


func _build_itens() -> void:
	_mon_list()
	var m: Dictionary = _all()[sel]
	if not m.has("eq"):
		m["eq"] = []
	# --- painel do Digialma
	var pan := Panel.new()
	pan.position = Vector2(174, 4)
	pan.size = Vector2(206, 284)
	body.add_child(pan)
	var nm := Label.new()
	nm.text = "%s  Nv%d" % [Game.mon_name(m), m["lv"]]
	nm.position = Vector2(184, 12)
	nm.add_theme_color_override("font_color", Game.rar_color(int(m.get("rar", 0))))
	body.add_child(nm)
	var rl := Label.new()
	rl.text = "%s  ·  atributos x%.2f" % [Game.RARITY[int(m.get("rar", 0))]["nome"].to_upper(), Game.rar_mult(m)]
	rl.position = Vector2(184, 26)
	rl.add_theme_font_size_override("font_size", 8)
	rl.add_theme_color_override("font_color", Game.rar_color(int(m.get("rar", 0))))
	body.add_child(rl)
	var holder := Node2D.new()
	holder.position = Vector2(277, 150)
	body.add_child(holder)
	var aura := FX_Aura.new()
	aura.col = Game.rar_color(int(m.get("rar", 0)))
	holder.add_child(aura)
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = Game.monster_frames(m["id"])
	spr.play("idle")
	spr.centered = false
	spr.offset = Game.foot_offset(m["id"])
	spr.flip_h = true
	holder.add_child(spr)
	# --- espaços de amuleto
	var sl := Label.new()
	sl.text = "AMULETOS"
	sl.position = Vector2(184, 176)
	sl.add_theme_font_size_override("font_size", 8)
	sl.add_theme_color_override("font_color", Color("ffd84a"))
	body.add_child(sl)
	for i in 2:
		var unlocked := i < Game.gear_slots(m)
		var g: Dictionary = Game.gear_by_uid(m["eq"][i]) if i < m["eq"].size() else {}
		var b := _gear_button(g, 46)
		b.position = Vector2(196 + i * 60, 192)
		body.add_child(b)
		if not unlocked:
			b.disabled = true
			b.text = "Nv20"
			b.add_theme_font_size_override("font_size", 8)
			b.mouse_entered.connect(func(): info.text = "O segundo espaço de amuleto abre no nível 20.")
		elif g.is_empty():
			b.text = "+"
			b.mouse_entered.connect(func(): info.text = "Espaço livre: clique num amuleto à direita para equipar.")
		else:
			var uid: int = g["uid"]
			b.mouse_entered.connect(func(): info.text = "%s — %s. Clique para desequipar." % [Game.gear_name(g), Game.gear_desc(g)])
			b.pressed.connect(func():
				m["eq"].erase(uid)
				_build()
				info.text = "%s guardado na bolsa." % Game.gear_name(g))
	var bonus := Label.new()
	bonus.position = Vector2(184, 244)
	bonus.size = Vector2(190, 40)
	bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bonus.add_theme_font_size_override("font_size", 8)
	var parts: Array = []
	for uid in m["eq"]:
		var g := Game.gear_by_uid(uid)
		if not g.is_empty():
			parts.append(Game.gear_desc(g))
	bonus.text = ", ".join(parts) if parts.size() > 0 else "Sem amuletos equipados."
	body.add_child(bonus)
	# --- bolsa de amuletos
	var bl := Label.new()
	bl.text = "BOLSA  (%d)" % Game.gear.size()
	bl.position = Vector2(392, 4)
	bl.add_theme_color_override("font_color", Color("ffd84a"))
	body.add_child(bl)
	var sc := ScrollContainer.new()
	sc.position = Vector2(390, 20)
	sc.size = Vector2(244, 240)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	sc.add_child(grid)
	var sorted: Array = Game.gear.duplicate()
	sorted.sort_custom(func(a, b): return a["rar"] > b["rar"] if a["rar"] != b["rar"] else a["base"] < b["base"])
	for g in sorted:
		var b := _gear_button(g, 44)
		var who := Game.gear_owner(g["uid"])
		if not who.is_empty():
			b.modulate = Color(0.55, 0.55, 0.6)
			var tag := Label.new()
			tag.text = "EQ"
			tag.position = Vector2(26, 30)
			tag.add_theme_font_size_override("font_size", 8)
			tag.add_theme_color_override("font_color", Color("ffd84a"))
			tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(tag)
		var gg: Dictionary = g
		b.mouse_entered.connect(func(): info.text = "%s — %s.%s" % [Game.gear_name(gg), Game.gear_desc(gg), ("  (com %s)" % Game.mon_name(who)) if not who.is_empty() else ""])
		b.pressed.connect(func():
			Game.equip(m, gg["uid"])
			_build()
			info.text = "%s equipou %s!" % [Game.mon_name(m), Game.gear_name(gg)])
		grid.add_child(b)
	if Game.gear.is_empty():
		var e := Label.new()
		e.text = "Nenhum amuleto ainda.\nEles caem dos Nefastos no idle."
		e.add_theme_font_size_override("font_size", 8)
		grid.add_child(e)
	var fuse := Button.new()
	fuse.text = "FUNDIR 3 IGUAIS"
	fuse.position = Vector2(470, 264)
	fuse.custom_minimum_size = Vector2(130, 20)
	fuse.add_theme_font_size_override("font_size", 8)
	fuse.tooltip_text = "3 amuletos do mesmo tipo e raridade (não equipados) viram 1 da raridade acima."
	fuse.pressed.connect(func():
		var n := Game.fuse_gear()
		_build()
		info.text = ("Fusão! %d amuleto(s) subiram de raridade." % n) if n > 0 else "Você precisa de 3 amuletos iguais (tipo e raridade) fora de uso.")
	body.add_child(fuse)
	info.text = "Clique num amuleto da bolsa para equipar no Digialma selecionado. Raridade: Comum, Incomum, Raro, Épico, Lendário."


## Brilho da raridade atrás do Digialma.
class FX_Aura extends Node2D:
	var col := Color.WHITE
	var t := 0.0

	func _process(d: float) -> void:
		t += d
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2(0, -6), 0, Vector2(1.0, 0.35))
		for i in 5:
			draw_circle(Vector2.ZERO, 56.0 - i * 9.0, Color(col, 0.05 + i * 0.03 + 0.02 * sin(t * 2.0)))
		draw_set_transform(Vector2.ZERO)
		for i in 6:
			var a := t * 0.6 + i * TAU / 6.0
			var p := Vector2(cos(a) * 40.0, -40.0 + sin(a * 1.7) * 22.0)
			draw_rect(Rect2(p, Vector2(2, 2)), Color(col, 0.5 + 0.4 * sin(t * 3.0 + i)))


# ---------------------------------------------------------------- FUSÃO
var fmode := "res"
var fpick := -1


func _build_fusao() -> void:
	_mon_list()
	var list := _all()
	var a: Dictionary = list[sel]
	var pan := Panel.new()
	pan.position = Vector2(174, 4)
	pan.size = Vector2(206, 284)
	body.add_child(pan)
	# modos
	var mh := HBoxContainer.new()
	mh.position = Vector2(180, 8)
	mh.add_theme_constant_override("separation", 4)
	body.add_child(mh)
	for k in [["res", "RESSONÂNCIA"], ["ess", "ESSÊNCIA"]]:
		var b := Button.new()
		b.text = k[1]
		b.custom_minimum_size = Vector2(95, 18)
		b.add_theme_font_size_override("font_size", 8)
		if fmode == k[0]:
			b.modulate = Color("ffd84a")
		var key: String = k[0]
		b.pressed.connect(func():
			fmode = key
			fpick = -1
			_build())
		mh.add_child(b)
	# alvo
	var holder := Node2D.new()
	holder.position = Vector2(277, 128)
	holder.name = "FusaoAlvo"
	body.add_child(holder)
	var aura := FX_Aura.new()
	aura.col = Game.TYPE_COLORS.get(a.get("essencia", ""), Game.rar_color(int(a.get("rar", 0))))
	holder.add_child(aura)
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = Game.monster_frames(a["id"])
	spr.play("idle")
	spr.centered = false
	spr.offset = Game.foot_offset(a["id"])
	spr.flip_h = true
	holder.add_child(spr)
	var nm := Label.new()
	nm.text = "%s  Nv%d" % [Game.mon_name(a), a["lv"]]
	nm.position = Vector2(184, 30)
	nm.add_theme_color_override("font_color", Game.rar_color(int(a.get("rar", 0))))
	body.add_child(nm)
	# ressonância (5 pontinhos) e essência
	var rl := Label.new()
	rl.position = Vector2(184, 140)
	rl.add_theme_font_size_override("font_size", 8)
	var pts := ""
	for i in Game.RES_MAX:
		pts += "◆ " if i < int(a.get("res", 0)) else "◇ "
	rl.text = "RESSONÂNCIA  %d/%d  (+%d%% atributos)" % [int(a.get("res", 0)), Game.RES_MAX, int(a.get("res", 0)) * 5]
	rl.add_theme_color_override("font_color", Color("7affe0"))
	body.add_child(rl)
	var pips := ResPips.new()
	pips.n = int(a.get("res", 0))
	pips.position = Vector2(186, 156)
	body.add_child(pips)
	var el := Label.new()
	el.position = Vector2(184, 168)
	el.size = Vector2(190, 30)
	el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	el.add_theme_font_size_override("font_size", 8)
	if a.has("essencia"):
		var hyb: bool = Game.HYBRIDS.has(a["essencia"])
		el.text = "ESSÊNCIA%s: %s%s\nGolpe extra: %s" % [" HÍBRIDA" if hyb else "", a["essencia"].to_upper(), (" (" + Game.HYBRIDS[a["essencia"]]["desc"] + ")") if hyb else "", Game.MOVES[Game.essence_move(a["essencia"])]["nome"]]
		el.add_theme_color_override("font_color", Game.TYPE_COLORS[a["essencia"]])
		var eic := TextureRect.new()
		eic.texture = Game.tex("res://assets/ui/idle_tipo_%s.png" % Game.TYPE_SLUG.get(a["essencia"], "normal"))
		eic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		eic.position = Vector2(356, 108)
		eic.scale = Vector2(1.5, 1.5)
		body.add_child(eic)
	else:
		el.text = "ESSÊNCIA: nenhuma"
		el.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	body.add_child(el)
	# fraquezas que ele enxerga
	var wk := Label.new()
	wk.position = Vector2(184, 200)
	wk.size = Vector2(190, 40)
	wk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wk.add_theme_font_size_override("font_size", 8)
	var alvos: Array = []
	for tp in Game.attack_types(a):
		for d in Game.strong_vs(tp):
			if not alvos.has(d):
				alvos.append(d)
	wk.text = "Explora pontos fracos de: %s" % (", ".join(alvos) if alvos.size() > 0 else "—")
	wk.add_theme_color_override("font_color", Color("ff9a9a"))
	body.add_child(wk)
	# candidatos
	var hl := Label.new()
	hl.text = "FUNDIR COM:" if fmode == "res" else "ESSÊNCIA DE:"
	hl.position = Vector2(392, 4)
	hl.add_theme_color_override("font_color", Color("ffd84a"))
	body.add_child(hl)
	var sc := ScrollContainer.new()
	sc.position = Vector2(390, 20)
	sc.size = Vector2(244, 232)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(sc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	sc.add_child(v)
	var any := false
	for i in list.size():
		if i == sel:
			continue
		var b: Dictionary = list[i]
		var why: String = Game.can_resonate(a, b) if fmode == "res" else Game.can_essence(a, b)
		# esconde quem nunca serviria (outra espécie na ressonância / mesmo tipo na essência)
		if fmode == "res" and why.begins_with("Só ressoa"):
			continue
		if fmode == "ess" and (why.begins_with("A essência") or why.begins_with("Só uma")):
			continue
		any = true
		var bt := Button.new()
		bt.custom_minimum_size = Vector2(236, 28)
		bt.alignment = HORIZONTAL_ALIGNMENT_LEFT
		bt.icon = Game.menu_icon(b["id"])
		bt.add_theme_font_size_override("font_size", 8)
		bt.text = "%s Nv%d · %s" % [Game.mon_title(b), b["lv"], Game.MONSTERS[b["id"]]["tipo"]]
		if fmode == "ess":
			var res_t := Game.essence_result(a, b)
			if Game.HYBRIDS.has(res_t):
				bt.text += "  > " + res_t.to_upper()
		bt.add_theme_color_override("font_color", Game.rar_color(int(b.get("rar", 0))))
		if i == fpick:
			bt.modulate = Color(1.3, 1.25, 0.9)
		var idx := i
		bt.pressed.connect(func():
			fpick = idx
			_build()
			info.text = why if why != "" else _fuse_preview(a, list[idx]))
		v.add_child(bt)
	if not any:
		var e := Label.new()
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		e.custom_minimum_size = Vector2(230, 0)
		e.add_theme_font_size_override("font_size", 8)
		e.text = "Nenhum Digialma serve. Capture outro da mesma espécie (ou família) para ressoar." if fmode == "res" else "Nenhum serve. A essência vem de um Digialma EVOLUÍDO de outro tipo."
		v.add_child(e)
	var go := Button.new()
	go.text = ("FUNDIR  (%d cristal)" % Game.RES_COST) if fmode == "res" else ("FUNDIR  (%d cristais)" % Game.ESS_COST)
	go.position = Vector2(440, 260)
	go.custom_minimum_size = Vector2(150, 22)
	var ok := fpick >= 0 and fpick < list.size() and fpick != sel
	var why2 := ""
	if ok:
		why2 = Game.can_resonate(a, list[fpick]) if fmode == "res" else Game.can_essence(a, list[fpick])
	go.disabled = not ok or why2 != ""
	go.pressed.connect(func(): _do_fuse(a, list[fpick]))
	body.add_child(go)
	var help := Button.new()
	help.text = "?  COMO FUNCIONA"
	help.position = Vector2(390, 260)
	help.custom_minimum_size = Vector2(46, 22)
	help.add_theme_font_size_override("font_size", 8)
	help.text = "?"
	help.tooltip_text = "Como funcionam as fusões"
	help.pressed.connect(_fusion_help)
	body.add_child(help)
	if fmode == "res":
		info.text = "RESSONÂNCIA: queima uma cópia da mesma família. +5% de atributos por nível (máx. 5). A RARIDADE NÃO MUDA."
	else:
		info.text = "ESSÊNCIA: queima uma EVOLUÇÃO de outro tipo. Ganha um 2º elemento, o golpe dele e novos pontos fracos."


## Explicação completa das duas fusões (sobreposta ao painel).
func _fusion_help() -> void:
	_overlay("COMO FUNCIONAM AS FUSÕES", [
		["res", "RESSONÂNCIA  ·  queimar cópias  ·  1 Cristal de Ressonância", Color("7affe0")],
		["", "Escolha um Digialma e queime outro da MESMA FAMÍLIA (ex.: Brasito, Tatubrasa e Vulcatatu são da mesma família). O queimado desaparece para sempre.", Color.WHITE],
		["", "O seu ganha +5% de vida, ataque e defesa por nível de Ressonância (até 5 níveis = +25%).", Color.WHITE],
		["", "A RARIDADE NÃO MUDA. O NÍVEL NÃO MUDA. Para ter um Lendário, você precisa capturar um Lendário.", Color("ffd84a")],
		["fusao", "ESSÊNCIA  ·  novo elemento  ·  2 Cristais de Ressonância", Color("ff9a5a")],
		["", "Queime uma forma EVOLUÍDA de OUTRO tipo. O seu ganha um 2º elemento: um golpe novo e passa a acertar os pontos fracos desse elemento.", Color.WHITE],
		["", "Elementos que combinam viram HÍBRIDOS: Fogo + Água = Vapor, Elétrico + Água = Tormenta, Planta + Água = Pântano... Uma essência por Digialma.", Color.WHITE],
		["res", "Cristais de Ressonância caem dos Nefastos no idle e dos duelos contra raros.", Color(1, 1, 1, 0.7)],
	])


## Painel de explicação genérico (fecha com um clique).
func _overlay(title: String, rows: Array) -> void:
	var o := Control.new()
	o.size = Game.BASE
	o.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(o)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.02, 0.08, 0.96)
	bg.size = Game.BASE
	o.add_child(bg)
	var tl := Label.new()
	Game.heading(tl, title, 14)
	tl.add_theme_color_override("font_color", Color("ffd84a"))
	tl.position = Vector2(20, 12)
	o.add_child(tl)
	var y := 42.0
	for r in rows:
		if r[0] != "":
			var ic := TextureRect.new()
			ic.texture = Game.tex("res://assets/ui/idle_%s.png" % r[0])
			ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			ic.position = Vector2(20, y)
			o.add_child(ic)
		var l := Label.new()
		l.text = r[1]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.position = Vector2(40, y - 1)
		l.size = Vector2(580, 30)
		l.add_theme_font_size_override("font_size", 9 if r[0] != "" else 8)
		l.add_theme_color_override("font_color", r[2])
		o.add_child(l)
		y += 34.0 if r[1].length() > 110 else 24.0
	var ok := Button.new()
	ok.text = "ENTENDI"
	ok.position = Vector2(530, 324)
	ok.custom_minimum_size = Vector2(90, 24)
	ok.pressed.connect(o.queue_free)
	o.add_child(ok)


# ---------------------------------------------------------------- MOCHILA
## Tudo o que você carrega, com para que serve cada coisa (e USAR quando dá).
var bag_sel := ""  # item escolhido na mochila


func _bag_rows() -> Array:
	var rows: Array = []
	for k in ["orbe_alma", "pocao", "super_pocao", "cristal_despertar", "chip_elo", "fruta", "doce", "ovo", "mapa", "bits"]:
		if int(Game.inventory.get(k, 0)) > 0:
			rows.append([k, Game.ITEMS[k]["nome"], int(Game.inventory[k]), Game.ITEMS[k]["desc"], Game.ITEM_ICON.get(k, "gema")])
	if Game.cristais > 0:
		rows.insert(mini(1, rows.size()), ["cristais", "Cristal de Ressonância", Game.cristais, "Combustível das FUSÕES: 1 para Ressonância (queimar uma cópia: +5% de atributos, raridade não muda), 2 para Essência (ganhar um 2º elemento). Cai dos Nefastos e dos duelos.", "res"])
	if Game.gear.size() > 0:
		rows.append(["amuletos", "Amuletos de Alma", Game.gear.size(), "Equipe até 2 por Digialma (2º espaço no Nv 20) na aba AMULETOS. Presa = dano, Escama = menos dano recebido, Coração = vida, Pena = esquiva, Trevo = XP, Moeda = bits, Cristal = Sincronia. 3 iguais viram 1 mais raro.", "gema"])
	return rows


func _build_mochila() -> void:
	var rows := _bag_rows()
	if bag_sel == "" or not rows.any(func(r): return r[0] == bag_sel):
		bag_sel = rows[0][0] if rows.size() > 0 else ""
	# a mochila de couro, com os itens nos espaços
	var bag := TextureRect.new()
	bag.texture = Game.tex("res://assets/ui/bag/mochila.png")
	bag.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bag.position = Vector2(6, 2)
	body.add_child(bag)
	var plate := Label.new()
	plate.text = "MOCHILA"
	plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.position = Vector2(110, 37)
	plate.size = Vector2(120, 20)
	plate.add_theme_font_size_override("font_size", 10)
	plate.add_theme_color_override("font_color", Color("4a2a18"))
	body.add_child(plate)
	for n in 15:
		var sl := BagSlot.new()
		sl.position = Vector2(33 + (n % 5) * 56, 93 + (n / 5) * 56)
		if n < rows.size():
			var r: Array = rows[n]
			sl.key = r[0]
			sl.icon = Game.tex("res://assets/ui/idle_%s.png" % r[4])
			sl.count = r[2]
			sl.selected = r[0] == bag_sel
			sl.tooltip_text = r[1]
			sl.pressed_cb = func(k):
				bag_sel = k
				_build()
		body.add_child(sl)
	# o cartão do item
	var card := TextureRect.new()
	card.texture = Game.tex("res://assets/ui/bag/cartao.png")
	card.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	card.position = Vector2(344, 2)
	body.add_child(card)
	info.text = "Clique num item da mochila para ver para que ele serve."
	var row: Array = []
	for r in rows:
		if r[0] == bag_sel:
			row = r
	if row.is_empty():
		var em := Label.new()
		em.text = "Mochila vazia."
		em.position = Vector2(344, 130)
		em.size = Vector2(280, 20)
		em.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		em.add_theme_color_override("font_color", Color("4a2a18"))
		body.add_child(em)
		return
	var big := TextureRect.new()
	big.texture = Game.tex("res://assets/ui/idle_%s.png" % row[4])
	big.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	big.size = Vector2(42, 42)
	big.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	big.position = Vector2(344 + 140 - 21, 2 + 59 - 21)
	body.add_child(big)
	var nm := Label.new()
	nm.text = row[1]
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.position = Vector2(356, 106)
	nm.size = Vector2(256, 20)
	nm.add_theme_font_size_override("font_size", 11)
	nm.add_theme_color_override("font_color", Color("4a2a18"))
	body.add_child(nm)
	var qt := Label.new()
	qt.text = "você tem  x%d" % row[2]
	qt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qt.position = Vector2(356, 124)
	qt.size = Vector2(256, 16)
	qt.add_theme_font_size_override("font_size", 8)
	qt.add_theme_color_override("font_color", Color("8a5a30"))
	body.add_child(qt)
	var ds := Label.new()
	ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ds.text = row[3]
	ds.position = Vector2(366, 146)
	ds.size = Vector2(236, 90)
	ds.add_theme_font_size_override("font_size", 8)
	ds.add_theme_color_override("font_color", Color("3a2014"))
	body.add_child(ds)
	if row[0] in ["orbe_alma", "pocao", "super_pocao"]:
		var use := Button.new()
		use.text = "USAR"
		use.position = Vector2(434, 242)
		use.custom_minimum_size = Vector2(100, 26)
		var key: String = row[0]
		use.pressed.connect(func(): _use_item(key))
		body.add_child(use)
	info.text = "Almas (Digialmas caídos) só voltam com Orbe de Alma."


class BagSlot extends Control:
	var key := ""
	var icon: Texture2D
	var count := 0
	var selected := false
	var pressed_cb: Callable
	var tt := 0.0

	func _ready() -> void:
		custom_minimum_size = Vector2(50, 50)
		size = Vector2(50, 50)
		mouse_filter = Control.MOUSE_FILTER_STOP if key != "" else Control.MOUSE_FILTER_IGNORE
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	func _process(d: float) -> void:
		if selected:
			tt += d
			queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if key != "" and e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			Game.sfx("item")
			pressed_cb.call(key)

	func _draw() -> void:
		# espaço afundado no couro
		draw_rect(Rect2(Vector2.ZERO, size), Color("3a2014"))
		draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color("4a2a18"))
		draw_rect(Rect2(Vector2(2, 2), Vector2(size.x - 4, 3)), Color("2e180e"))
		draw_rect(Rect2(Vector2(2, size.y - 4), Vector2(size.x - 4, 2)), Color("7a4a2c"))
		if key == "":
			return
		var hover := get_global_rect().has_point(get_global_mouse_position())
		if hover and not selected:
			draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(1, 0.9, 0.6, 0.08))
		draw_texture_rect(icon, Rect2(Vector2(11, 9), Vector2(28, 28)), false)
		var f := get_theme_font("font", "Label")
		var txt := "x%d" % count if count < 1000 else "%dk" % (count / 1000)
		var p := Vector2(size.x - 4 - f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x, size.y - 5)
		for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
			draw_string(f, p + o, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("1e0e06"))
		draw_string(f, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("fff0c8"))
		if selected:
			var a := 0.7 + 0.3 * sin(tt * 5.0)
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.85, 0.3, a), false, 2.0)


func _use_item(k: String) -> void:
	if k == "orbe_alma":
		var ri := Game.use_soul_orb()
		info.text = ("%s voltou da forma de alma!" % Game.mon_name(Game.team[ri])) if ri >= 0 else "Ninguém virou alma: o Orbe fica guardado."
	else:
		var amt := 20 if k == "pocao" else 60
		var target := {}
		for m in Game.team:
			if int(m["hp"]) > 0 and int(m["hp"]) < Game.max_hp(m):
				target = m
				break
		if target.is_empty():
			info.text = "Ninguém precisa de cura (almas só voltam com Orbe)."
			return
		target["hp"] = mini(Game.max_hp(target), int(target["hp"]) + amt)
		Game.inventory[k] = int(Game.inventory[k]) - 1
		if Game.inventory[k] <= 0:
			Game.inventory.erase(k)
		info.text = "%s recuperou %d de vida." % [Game.mon_name(target), amt]
	var keep := info.text
	_build()
	info.text = keep


func _fuse_preview(a: Dictionary, b: Dictionary) -> String:
	if fmode == "res":
		return "%s queima %s: Ressonância %d > %d (+5%% atributos). A raridade continua %s. (%s some.)" % [Game.mon_name(a), Game.mon_name(b), int(a.get("res", 0)), int(a.get("res", 0)) + 1, Game.RARITY[int(a.get("rar", 0))]["nome"], Game.mon_name(b)]
	var tp := Game.essence_result(a, b)
	var hyb: bool = Game.HYBRIDS.has(tp)
	var head := ("%s + %s = %s! " % [Game.MONSTERS[a["id"]]["tipo"].to_upper(), Game.MONSTERS[b["id"]]["tipo"].to_upper(), tp.to_upper()]) if hyb else ""
	return "%s%s ganha a essência %s (golpe %s, forte contra %s)%s. (%s some.)" % [head, Game.mon_name(a), tp.to_upper(), Game.MOVES[Game.essence_move(tp)]["nome"], ", ".join(Game.strong_vs(tp)), " no lugar de " + a["essencia"] if a.has("essencia") else "", Game.mon_name(b)]


func _do_fuse(a: Dictionary, b: Dictionary) -> void:
	if Game.team.size() <= 1 and Game.team.has(b):
		info.text = "Esse é o único da equipe. Coloque outro na equipe antes."
		return
	var col: Color = Game.TYPE_COLORS[Game.essence_result(a, b)] if fmode == "ess" else Color("7affe0")
	# o doador vira luz e entra no alvo
	var orb := TextureRect.new()
	orb.texture = Game.menu_icon(b["id"])
	orb.position = Vector2(500, 120)
	orb.pivot_offset = Vector2(16, 16)
	add_child(orb)
	var to := Vector2(261, 140)
	var tw := create_tween()
	tw.tween_property(orb, "modulate", Color(3, 3, 3, 1), 0.2)
	tw.tween_property(orb, "position", to, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(orb, "scale", Vector2(0.3, 0.3), 0.45)
	await tw.finished
	orb.queue_free()
	var flash := ColorRect.new()
	flash.color = Color(col, 0.0)
	flash.size = Game.BASE
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var t2 := create_tween()
	t2.tween_property(flash, "color:a", 0.75, 0.08)
	t2.tween_property(flash, "color:a", 0.0, 0.5)
	t2.tween_callback(flash.queue_free)
	if fmode == "res":
		Game.resonate(a, b)
	else:
		Game.fuse_essence(a, b)
	fpick = -1
	sel = _all().find(a)
	_build()
	info.text = "Fusão completa! %s ficou mais forte." % Game.mon_name(a)


class ResPips extends Node2D:
	var n := 0

	func _draw() -> void:
		for i in Game.RES_MAX:
			var p := Vector2(i * 14, 0)
			var pts := PackedVector2Array([p + Vector2(5, 0), p + Vector2(10, 5), p + Vector2(5, 10), p + Vector2(0, 5)])
			draw_colored_polygon(pts, Color("140a22"))
			var inner := PackedVector2Array([p + Vector2(5, 2), p + Vector2(8, 5), p + Vector2(5, 8), p + Vector2(2, 5)])
			draw_colored_polygon(inner, Color("7affe0") if i < n else Color(0.25, 0.22, 0.35))


# ---------------------------------------------------------------- ELO
func _build_elo() -> void:
	var hd := Label.new()
	hd.text = "ELO  Nv %d" % Game.elo_lv
	Game.heading(hd, hd.text, 12)
	hd.add_theme_color_override("font_color", Color("7affc1"))
	hd.position = Vector2(20, 0)
	body.add_child(hd)
	var xb := ProgressBar.new()
	xb.show_percentage = false
	xb.position = Vector2(130, 6)
	xb.size = Vector2(150, 8)
	xb.max_value = Game.elo_need()
	xb.value = Game.elo_xp
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color("7affc1")
	xb.add_theme_stylebox_override("fill", fs)
	body.add_child(xb)
	var cap := Label.new()
	cap.add_theme_font_size_override("font_size", 8)
	cap.position = Vector2(292, 2)
	cap.size = Vector2(340, 20)
	var parts: Array = []
	for r in Game.CAPTURE_LV:
		var ok: bool = Game.elo_lv >= Game.CAPTURE_LV[r]
		parts.append("%s Nv%d%s" % [Game.RARITY[r]["nome"], Game.CAPTURE_LV[r], " (ok)" if ok else ""])
	cap.text = "Capturar: " + "  ·  ".join(parts)
	cap.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	body.add_child(cap)
	var g := GridContainer.new()
	g.columns = 2
	g.position = Vector2(20, 26)
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 8)
	body.add_child(g)
	for k in Game.ELO_UPGRADES:
		var u: Dictionary = Game.ELO_UPGRADES[k]
		var lvl := Game.elo_level(k)
		var maxl: int = u["custos"].size()
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(290, 64)
		g.add_child(p)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		p.add_child(v)
		var t := Label.new()
		t.text = "%s   %d/%d" % [u["nome"], lvl, maxl]
		t.add_theme_color_override("font_color", Color("ffd84a") if lvl > 0 else Color.WHITE)
		t.add_theme_font_size_override("font_size", 8)
		v.add_child(t)
		var d := Label.new()
		d.text = u["desc"][mini(lvl, maxl - 1)] if lvl < maxl else "Nível máximo."
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(270, 0)
		d.add_theme_font_size_override("font_size", 8)
		v.add_child(d)
		var b := Button.new()
		b.custom_minimum_size = Vector2(120, 16)
		b.add_theme_font_size_override("font_size", 8)
		var req_ok: bool = u["req"] == "" or Game.elo_level(u["req"]) > 0
		if lvl >= maxl:
			b.text = "COMPLETO"
			b.disabled = true
		elif not req_ok:
			b.text = "REQUER %s" % Game.ELO_UPGRADES[u["req"]]["nome"].split(" ")[0]
			b.disabled = true
		else:
			var cost: int = u["custos"][lvl]
			b.text = "COMPRAR  %d bits" % cost
			b.disabled = Game.bits < cost
			var key: String = k
			b.pressed.connect(func():
				Game.bits -= cost
				Game.elo_up[key] = lvl + 1
				_build()
				info.text = "Elo aprimorado: %s!" % u["nome"])
		v.add_child(b)
	info.text = "Bits vêm das purificações (o modo idle é a melhor fonte). Melhorias do Elo valem para todo o time."


# ---------------------------------------------------------------- INSÍGNIAS
func _build_insignias() -> void:
	Game.badge_autoequip()
	var slots := Game.badge_slots()
	var hd := Label.new()
	Game.heading(hd, "INSÍGNIAS  ·  ESPAÇOS NO ELO  %d/%d" % [Game.badge_eq.size(), slots], 12)
	hd.add_theme_color_override("font_color", Color("ffd84a"))
	hd.position = Vector2(20, 0)
	body.add_child(hd)
	var nx := ""
	for need in Game.BADGE_SLOT_ELO:
		if Game.elo_lv < need:
			nx = "Próximo espaço no Elo Nv %d" % need
			break
	var sub := Label.new()
	sub.text = nx if nx != "" else "Todos os espaços abertos"
	sub.add_theme_font_size_override("font_size", 8)
	sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	sub.position = Vector2(420, 4)
	body.add_child(sub)
	var g := GridContainer.new()
	g.columns = 3
	g.position = Vector2(10, 24)
	g.add_theme_constant_override("h_separation", 4)
	g.add_theme_constant_override("v_separation", 6)
	body.add_child(g)
	var owned := Game.badge_owned()
	for r in Game.REGIONS.size():
		var ld: Dictionary = Game.REGIONS[r]["lider"]
		var k: String = ld["badge"]
		var fx: Dictionary = Game.BADGE_FX.get(k, {})
		var has := owned.has(k)
		var lvl := Game.badge_level(k)
		var on: bool = Game.badge_eq.has(k)
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(202, 124)
		if on:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.25, 0.2, 0.05, 0.85)
			sb.border_color = Color("ffd84a")
			sb.set_border_width_all(2)
			sb.content_margin_left = 12
			sb.content_margin_right = 12
			sb.content_margin_top = 10
			sb.content_margin_bottom = 10
			p.add_theme_stylebox_override("panel", sb)
		g.add_child(p)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 4)
		h.clip_contents = true
		p.add_child(h)
		var ic := TextureRect.new()
		ic.texture = Game.tex("res://assets/badges/%s.png" % k)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(32, 32)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if not has:
			ic.modulate = Color(0, 0, 0, 0.6)
		h.add_child(ic)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		v.custom_minimum_size = Vector2(138, 0)
		h.add_child(v)
		var t := Label.new()
		t.add_theme_font_size_override("font_size", 8)
		t.text = ("%s  %s" % [ld["insignia"], Game.ROMAN[lvl]]) if has else "???"
		t.add_theme_color_override("font_color", Color("ffd84a") if has else Color(1, 1, 1, 0.5))
		v.add_child(t)
		var d := Label.new()
		d.add_theme_font_size_override("font_size", 8)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(138, 0)
		if has:
			var txt: String = fx["efeito"] % fx["val"][lvl - 1]
			txt += "\n" + ("Próximo (%s): %d%%" % [Game.ROMAN[lvl + 1], fx["val"][lvl]] if lvl < 3 else "Nível máximo")
			if lvl < 3:
				txt += "\nRevanche: zona 10 de " + Game.REGIONS[r]["nome"]
			d.text = txt
		else:
			d.text = "Vença %s em %s." % [ld["nome"], Game.REGIONS[r]["nome"]] if r <= Game.badges else "Guardião ainda desconhecido."
		v.add_child(d)
		var b := Button.new()
		b.custom_minimum_size = Vector2(110, 16)
		b.add_theme_font_size_override("font_size", 8)
		if not has:
			b.text = "TRANCADA"
			b.disabled = true
		elif on:
			b.text = "TIRAR"
			b.pressed.connect(func():
				Game.badge_eq.erase(k)
				_build()
				info.text = "%s guardada." % ld["insignia"])
		else:
			b.text = "EQUIPAR"
			b.disabled = Game.badge_eq.size() >= slots
			if b.disabled:
				b.tooltip_text = "Tire uma insígnia primeiro, ou suba o Elo para abrir espaço."
			b.pressed.connect(func():
				Game.badge_eq.append(k)
				_build()
				info.text = "%s equipada!" % ld["insignia"])
		v.add_child(b)
	info.text = "Insígnias equipadas no Elo dão bônus. Volte à zona 10 de um mapa purificado: o guardião pede REVANCHE, e vencer sobe a insígnia até o III."


# ---------------------------------------------------------------- EQUIPE
var eq_sel := -1  # índice na reserva escolhido para trocar


func _build_equipe() -> void:
	var cap := Game.team_cap()
	if eq_sel >= Game.reserve.size():
		eq_sel = -1
	var h := Label.new()
	h.text = "EQUIPE  %d/%d" % [Game.team.size(), cap]
	h.add_theme_color_override("font_color", Color("ffd84a"))
	h.position = Vector2(16, 0)
	body.add_child(h)
	var h2 := Label.new()
	h2.text = "RESERVA  %d" % Game.reserve.size()
	h2.add_theme_color_override("font_color", Color("ffd84a"))
	h2.position = Vector2(336, 0)
	body.add_child(h2)
	# equipe: cartões grandes, o primeiro é o líder (luta primeiro)
	for i in cap:
		var y := 18.0 + i * 54.0
		if i >= Game.team.size():
			var vz := Panel.new()
			vz.position = Vector2(12, y)
			vz.size = Vector2(312, 50)
			vz.modulate = Color(1, 1, 1, 0.35)
			body.add_child(vz)
			var vl := Label.new()
			vl.text = "vaga livre: clique num Digialma da reserva"
			vl.position = Vector2(24, y + 17)
			vl.add_theme_font_size_override("font_size", 8)
			vl.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
			body.add_child(vl)
			continue
		_team_card(Game.team[i], i, Vector2(12, y))
	if cap < 5:
		var mv := Label.new()
		mv.text = "+ vagas: ELO > NOVA VAGA NA EQUIPE"
		mv.position = Vector2(16, 18 + cap * 54)
		mv.add_theme_font_size_override("font_size", 8)
		mv.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
		body.add_child(mv)
	# reserva: grade de fichas
	var sc := ScrollContainer.new()
	sc.position = Vector2(334, 18)
	sc.size = Vector2(296, 268)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(sc)
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 4)
	g.add_theme_constant_override("v_separation", 4)
	sc.add_child(g)
	for i in Game.reserve.size():
		g.add_child(_reserve_tile(Game.reserve[i], i))
	if Game.reserve.is_empty():
		var e := Label.new()
		e.text = "Ninguém na reserva ainda.\nCapture raros para ter mais parceiros."
		e.add_theme_font_size_override("font_size", 8)
		g.add_child(e)
	if eq_sel >= 0:
		info.text = "Agora clique num Digialma da EQUIPE para trocar de lugar com %s." % Game.mon_name(Game.reserve[eq_sel])
	else:
		info.text = "Clique na reserva para levar à equipe. O LÍDER (1º) luta primeiro."


func _mon_sprite(m: Dictionary, pos: Vector2, sc: float) -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = Game.monster_frames(m["id"])
	s.play("idle")
	s.centered = false
	s.offset = Game.foot_offset(m["id"])
	s.scale = Vector2(sc, sc)
	s.position = pos
	if m.get("desperto", false):
		s.modulate = Color(1.1, 1.05, 0.85)
	return s


func _team_card(m: Dictionary, i: int, pos: Vector2) -> void:
	var b := Button.new()
	b.position = pos
	b.size = Vector2(312, 50)
	b.focus_mode = Control.FOCUS_NONE
	if eq_sel >= 0:
		b.add_theme_stylebox_override("normal", Game.sb("slot_sel", 5))
		b.tooltip_text = "Trocar com %s" % Game.mon_name(Game.reserve[eq_sel])
	else:
		b.tooltip_text = "Mandar para a reserva" if Game.team.size() > 1 else "A equipe precisa de pelo menos 1"
	b.pressed.connect(func():
		if eq_sel >= 0:
			var r: Dictionary = Game.reserve[eq_sel]
			Game.reserve[eq_sel] = Game.team[i]
			Game.team[i] = r
			eq_sel = -1
		elif Game.team.size() > 1:
			Game.reserve.append(Game.team[i])
			Game.team.remove_at(i)
		Game.sfx("item")
		_build())
	body.add_child(b)
	var clip := Control.new()
	clip.position = pos + Vector2(4, 2)
	clip.size = Vector2(52, 46)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(clip)
	clip.add_child(_mon_sprite(m, Vector2(26, 44), 0.5))
	var nm := Label.new()
	nm.text = "%s  Nv%d" % [Game.mon_title(m), m["lv"]]
	nm.position = pos + Vector2(60, 4)
	nm.add_theme_font_size_override("font_size", 9)
	nm.add_theme_color_override("font_color", Game.rar_color(int(m.get("rar", 0))).lightened(0.2))
	body.add_child(nm)
	var ti := TextureRect.new()
	ti.texture = Game.tex("res://assets/ui/idle_tipo_%s.png" % Game.TYPE_SLUG.get(Game.MONSTERS[m["id"]]["tipo"], "normal"))
	ti.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ti.position = pos + Vector2(60, 18)
	ti.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(ti)
	var hp := ProgressBar.new()
	hp.show_percentage = false
	hp.max_value = Game.max_hp(m)
	hp.value = maxi(0, int(m["hp"]))
	hp.position = pos + Vector2(78, 22)
	hp.size = Vector2(150, 6)
	hp.modulate = Color("6fe08a") if int(m["hp"]) > 0 else Color("8a8aa0")
	hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(hp)
	var hl := Label.new()
	hl.text = ("%d/%d" % [maxi(0, int(m["hp"])), Game.max_hp(m)]) if int(m["hp"]) > 0 else "alma (Orbe)"
	hl.position = pos + Vector2(232, 17)
	hl.add_theme_font_size_override("font_size", 7)
	hl.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	body.add_child(hl)
	var xp := ProgressBar.new()
	xp.show_percentage = false
	xp.max_value = maxi(1, Game.xp_need(m))
	xp.value = int(m.get("xp", 0))
	xp.position = pos + Vector2(78, 32)
	xp.size = Vector2(150, 3)
	xp.modulate = Color("8ad8ff")
	xp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(xp)
	if i == 0:
		var lt := Label.new()
		lt.text = "LÍDER"
		lt.position = pos + Vector2(262, 32)
		lt.add_theme_font_size_override("font_size", 8)
		lt.add_theme_color_override("font_color", Color("ffd84a"))
		body.add_child(lt)
	else:
		var up := Button.new()
		up.text = "LÍDER"
		up.tooltip_text = "Colocar como líder (luta primeiro)"
		up.position = pos + Vector2(256, 30)
		up.custom_minimum_size = Vector2(50, 16)
		up.add_theme_font_size_override("font_size", 7)
		up.focus_mode = Control.FOCUS_NONE
		up.pressed.connect(func():
			var mm: Dictionary = Game.team[i]
			Game.team.remove_at(i)
			Game.team.insert(0, mm)
			Game.sfx("item")
			_build())
		body.add_child(up)


func _reserve_tile(m: Dictionary, i: int) -> Control:
	var b := Button.new()
	b.custom_minimum_size = Vector2(94, 76)
	b.focus_mode = Control.FOCUS_NONE
	if eq_sel == i:
		b.add_theme_stylebox_override("normal", Game.sb("slot_sel", 5))
	b.tooltip_text = "%s  Nv%d" % [Game.mon_title(m), m["lv"]]
	b.pressed.connect(func():
		if Game.team.size() < Game.team_cap():
			Game.team.append(Game.reserve[i])
			Game.reserve.remove_at(i)
			eq_sel = -1
		else:
			eq_sel = -1 if eq_sel == i else i
		Game.sfx("item")
		_build())
	var clip := Control.new()
	clip.position = Vector2(4, 2)
	clip.size = Vector2(86, 50)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(clip)
	clip.add_child(_mon_sprite(m, Vector2(43, 48), 0.5))
	var nm := Label.new()
	nm.text = Game.mon_name(m)
	nm.clip_text = true
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.position = Vector2(2, 50)
	nm.size = Vector2(90, 12)
	nm.add_theme_font_size_override("font_size", 7)
	nm.add_theme_color_override("font_color", Game.rar_color(int(m.get("rar", 0))).lightened(0.2))
	b.add_child(nm)
	var lv := Label.new()
	lv.text = "Nv%d" % m["lv"]
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.position = Vector2(2, 61)
	lv.size = Vector2(90, 12)
	lv.add_theme_font_size_override("font_size", 7)
	lv.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	b.add_child(lv)
	return b
