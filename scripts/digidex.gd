extends Control
## DIGIDEX: todos os Digialmas que você já encontrou.
## ? = nunca visto · sombra = visto · colorido = capturado (com as raridades que já teve).
## Clicar mostra a linha evolutiva e, se você já capturou um, as raridades possíveis.

const UI := "res://assets/ui/idle_%s.png"
var grid: GridContainer
var detail: Control
var sel := -1
var t := 0.0
var premios_btn: Button


func _ready() -> void:
	theme = Game.make_theme()
	size = Game.BASE
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.03, 0.11, 0.97)
	bg.size = Game.BASE
	add_child(bg)
	var title := Label.new()
	Game.heading(title, "DIGIDEX", 16)
	title.add_theme_color_override("font_color", Color("ffd84a"))
	title.position = Vector2(16, 10)
	add_child(title)
	var order := Game.dex_order()
	var n_seen := 0
	var n_caught := 0
	for id in order:
		if Game.seen.has(id):
			n_seen += 1
		if Game.dex_caught.has(id):
			n_caught += 1
	var cnt := Label.new()
	cnt.text = "Capturados %d/%d (%d%%)  ·  Vistos %d" % [n_caught, order.size(), Game.dex_pct(), n_seen]
	cnt.add_theme_font_size_override("font_size", 9)
	cnt.add_theme_color_override("font_color", Color("7affc1"))
	cnt.position = Vector2(112, 18)
	add_child(cnt)
	premios_btn = Button.new()
	premios_btn.position = Vector2(366, 10)
	premios_btn.custom_minimum_size = Vector2(96, 22)
	premios_btn.add_theme_font_size_override("font_size", 8)
	premios_btn.tooltip_text = "Prêmios por completar a coleção"
	premios_btn.pressed.connect(_show_premios)
	add_child(premios_btn)
	_refresh_premios_btn()
	var info := Button.new()
	info.text = "? FORMAS"
	info.position = Vector2(468, 10)
	info.custom_minimum_size = Vector2(86, 22)
	info.add_theme_font_size_override("font_size", 8)
	info.tooltip_text = "Evolução, Despertar (4ª forma) e Ascensão (5ª forma)"
	info.pressed.connect(func():
		var c = load("res://scenes/despertar_info.tscn").instantiate()
		c.overlay = true
		add_child(c))
	add_child(info)
	var close := Button.new()
	close.text = "FECHAR" if Game.in_panel(self) else "VOLTAR"
	close.position = Vector2(560, 10)
	close.custom_minimum_size = Vector2(70, 22)
	close.pressed.connect(func():
		if Game.in_panel(self):
			get_window().queue_free()
		else:
			Game.change_scene("res://scenes/map.tscn"))
	add_child(close)
	var sc := ScrollContainer.new()
	sc.position = Vector2(12, 44)
	sc.size = Vector2(300, 304)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)
	grid = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	sc.add_child(grid)
	for i in order.size():
		var c := Card.new()
		c.id = order[i]
		c.num = i + 1
		c.pressed_cb = _select
		grid.add_child(c)
	# o segredo: sempre no fim, trocando de silhueta
	var sc2 := SecretCard.new()
	sc2.num = order.size() + 1
	sc2.pressed_cb = _select_secret
	grid.add_child(sc2)
	detail = Control.new()
	detail.position = Vector2(322, 44)
	detail.size = Vector2(306, 304)
	add_child(detail)
	# abre no primeiro capturado
	for id in order:
		if Game.dex_caught.has(id):
			_select(id)
			break
	if sel < 0:
		_hint("Encontre e capture Digialmas para preencher a Digidex.")


func _process(d: float) -> void:
	t += d


func _hint(txt: String) -> void:
	var l := Label.new()
	l.text = txt
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size = Vector2(300, 60)
	l.position = Vector2(4, 120)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 9)
	detail.add_child(l)


func _refresh_premios_btn() -> void:
	var n := Game.dex_marcos_prontos()
	premios_btn.text = "PRÊMIOS (%d)" % n if n > 0 else "PRÊMIOS"
	premios_btn.modulate = Color("ffd84a") if n > 0 else Color.WHITE


## Marcos da coleção: cada um dá um prêmio para resgatar.
func _show_premios() -> void:
	var ov := Control.new()
	ov.size = Game.BASE
	add_child(ov)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.03, 0.11, 0.98)
	bg.size = Game.BASE
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	ov.add_child(bg)
	var tl := Label.new()
	Game.heading(tl, "PRÊMIOS DA COLEÇÃO", 14)
	tl.add_theme_color_override("font_color", Color("ffd84a"))
	tl.position = Vector2(20, 12)
	ov.add_child(tl)
	var pr := Label.new()
	pr.text = "Você capturou %d de %d Digialmas (%d%%)." % [Game.dex_caught_count(), Game.dex_order().size(), Game.dex_pct()]
	pr.add_theme_font_size_override("font_size", 9)
	pr.add_theme_color_override("font_color", Color("7affc1"))
	pr.position = Vector2(20, 36)
	ov.add_child(pr)
	var y := 60.0
	for m in Game.DEX_MARCOS:
		var pct: int = m["pct"]
		var done: bool = Game.dex_premios.has(pct)
		var ready: bool = Game.dex_pct() >= pct and not done and pct < 100
		var row := ColorRect.new()
		row.color = Color(1, 0.85, 0.3, 0.14) if ready else Color(1, 1, 1, 0.05)
		row.position = Vector2(20, y)
		row.size = Vector2(600, 42)
		ov.add_child(row)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.max_value = pct
		bar.value = mini(Game.dex_pct(), pct)
		bar.position = Vector2(30, y + 28)
		bar.size = Vector2(300, 6)
		ov.add_child(bar)
		var h := Label.new()
		h.text = "%d%% DA DIGIDEX" % pct
		h.position = Vector2(30, y + 4)
		h.add_theme_font_size_override("font_size", 10)
		h.add_theme_color_override("font_color", Color("ffd84a"))
		ov.add_child(h)
		var d := Label.new()
		d.text = m["desc"]
		d.position = Vector2(170, y + 6)
		d.add_theme_font_size_override("font_size", 8)
		ov.add_child(d)
		var b := Button.new()
		b.position = Vector2(500, y + 8)
		b.custom_minimum_size = Vector2(110, 24)
		b.add_theme_font_size_override("font_size", 8)
		if pct == 100:
			b.text = "SEGREDO"
			b.disabled = true
		elif done:
			b.text = "RESGATADO"
			b.disabled = true
		elif ready:
			b.text = "RESGATAR"
			b.pressed.connect(func():
				if Game.claim_dex_marco(pct):
					Game.sfx("item")
					Game.save_game()
					ov.queue_free()
					_refresh_premios_btn()
					_show_premios())
		else:
			b.text = "FALTA %d%%" % (pct - Game.dex_pct())
			b.disabled = true
		ov.add_child(b)
		y += 50.0
	var ok := Button.new()
	ok.text = "VOLTAR"
	ok.position = Vector2(510, 318)
	ok.custom_minimum_size = Vector2(110, 28)
	ok.pressed.connect(ov.queue_free)
	ov.add_child(ok)


func _select_secret() -> void:
	sel = -2
	for c in grid.get_children():
		c.selected = c is SecretCard
		c.queue_redraw()
	for ch in detail.get_children():
		ch.queue_free()
	var panel := ColorRect.new()
	panel.color = Color(1, 1, 1, 0.05)
	panel.size = detail.size
	detail.add_child(panel)
	var done := Game.dex_complete()
	var q := Label.new()
	q.text = "#%03d  %s" % [Game.dex_order().size() + 1, Game.SECRET_NOME if done else "???"]
	q.position = Vector2(12, 8)
	q.add_theme_font_size_override("font_size", 13)
	q.add_theme_color_override("font_color", Color("b8ffb0"))
	detail.add_child(q)
	var big := SecretCard.new()
	big.big = true
	big.position = Vector2(170, 40)
	detail.add_child(big)
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.position = Vector2(12, 40)
	l.size = Vector2(150, 160)
	l.add_theme_font_size_override("font_size", 8)
	if done:
		l.text = Game.DEX_TEXT.get(Game.SECRET_ID, "") + "\n\nA árvore despertou. Ela vai se revelar no fim da jornada."
	else:
		l.text = "Uma silhueta que nunca fica igual. Dizem que ela guarda a alma de todos os Digialmas.\n\nCapture TODOS, com todas as formas, para revelar."
	detail.add_child(l)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = Game.dex_order().size()
	bar.value = Game.dex_caught_count()
	bar.position = Vector2(12, 228)
	bar.size = Vector2(282, 8)
	detail.add_child(bar)
	var bl := Label.new()
	bl.text = "Coleção: %d / %d" % [Game.dex_caught_count(), Game.dex_order().size()]
	bl.position = Vector2(12, 240)
	bl.add_theme_font_size_override("font_size", 8)
	bl.add_theme_color_override("font_color", Color("7affc1"))
	detail.add_child(bl)


func _select(id: int) -> void:
	sel = id
	for c in grid.get_children():
		c.selected = (not c is SecretCard) and c.id == id
		c.queue_redraw()
	for ch in detail.get_children():
		ch.queue_free()
	var d: Dictionary = Game.MONSTERS[id]
	var num: int = Game.dex_order().find(id) + 1
	var seen: bool = Game.seen.has(id)
	var caught: bool = Game.dex_caught.has(id)
	var panel := ColorRect.new()
	panel.color = Color(1, 1, 1, 0.05)
	panel.size = detail.size
	detail.add_child(panel)
	if not seen:
		var q := Label.new()
		q.text = "#%03d  ???" % num
		q.position = Vector2(12, 10)
		q.add_theme_font_size_override("font_size", 12)
		detail.add_child(q)
		_hint("Ainda não encontrado. Explore novas zonas e mapas.")
		return
	var name_l := Label.new()
	name_l.text = "#%03d  %s" % [num, d["nome"]]
	name_l.position = Vector2(12, 8)
	name_l.add_theme_font_size_override("font_size", 13)
	name_l.add_theme_color_override("font_color", d["cor"].lightened(0.3))
	detail.add_child(name_l)
	# tipo + papel
	var ty := HBoxContainer.new()
	ty.position = Vector2(12, 28)
	ty.add_theme_constant_override("separation", 4)
	detail.add_child(ty)
	var ti := TextureRect.new()
	ti.texture = Game.tex(UI % ("tipo_" + Game.TYPE_SLUG.get(d["tipo"], "normal")))
	ti.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ti.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ty.add_child(ti)
	var tl := Label.new()
	tl.text = d["tipo"] + ("   ·   SUPORTE (cura o time)" if Game.SUPPORT.has(id) else "")
	tl.add_theme_font_size_override("font_size", 9)
	tl.add_theme_color_override("font_color", Game.TYPE_COLORS.get(d["tipo"], Color.WHITE))
	ty.add_child(tl)
	# sprite grande (sombra se só foi visto)
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = Game.monster_frames(id)
	spr.play("idle")
	spr.centered = false
	spr.offset = Game.foot_offset(id)
	spr.scale = Vector2(1.3, 1.3)
	spr.position = Vector2(262, 186)
	spr.material = Game.sprite_mat()
	if not caught:
		(spr.material as ShaderMaterial).set_shader_parameter("silhouette", 1.0)
		spr.modulate = Color(0.25, 0.22, 0.35)
	detail.add_child(spr)
	var jeito := Label.new()
	jeito.text = "Jeito: %s" % d.get("jeito", "?") if caught else "Visto, mas nunca capturado."
	jeito.position = Vector2(12, 46)
	jeito.size = Vector2(160, 30)
	jeito.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	jeito.add_theme_font_size_override("font_size", 8)
	jeito.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	detail.add_child(jeito)
	# linha evolutiva
	var ll := Label.new()
	ll.text = "LINHA EVOLUTIVA" + ("  ·  COMPLETA!" if Game.line_complete(id) else "")
	ll.position = Vector2(12, 78)
	ll.add_theme_font_size_override("font_size", 8)
	ll.add_theme_color_override("font_color", Color("ffd84a"))
	detail.add_child(ll)
	var line := Game.evo_line(id)
	# árvore: cada forma numa coluna pelo estágio; ramos vão para a linha de baixo
	var pos := {}
	var rows := [0]
	var lay := func(f: Callable, n: int, depth: int, row: int) -> void:
		pos[n] = Vector2(12.0 + depth * 38.0, 88.0 + row * 40.0)
		var first := true
		for c in Game._succ(Game.MONSTERS[n]):
			if not line.has(c) or pos.has(c):
				continue
			var crow := row
			if not first:
				rows[0] += 1
				crow = rows[0]
			first = false
			f.call(f, c, depth + 1, crow)
	lay.call(lay, line[0], 0, 0)
	for lid in line:
		if not pos.has(lid):
			rows[0] += 1
			pos[lid] = Vector2(12.0, 88.0 + rows[0] * 40.0)
	# ligações dos ramos
	for lid in line:
		for c in Game._succ(Game.MONSTERS[lid]):
			if pos.has(c) and pos[c].y > pos[lid].y:
				var ln := Line2D.new()
				ln.width = 1.0
				ln.default_color = Color(1, 0.85, 0.4, 0.5)
				ln.points = PackedVector2Array([pos[lid] + Vector2(16, 34), pos[lid] + Vector2(16, pos[c].y - pos[lid].y + 16), pos[c] + Vector2(-2, 16)])
				detail.add_child(ln)
				var ou := Label.new()
				ou.text = "ou"
				ou.position = pos[lid] + Vector2(2, 44)
				ou.add_theme_font_size_override("font_size", 7)
				ou.add_theme_color_override("font_color", Color(1, 0.85, 0.4, 0.8))
				detail.add_child(ou)
	for lid in line:
		var x: float = pos[lid].x
		var y: float = pos[lid].y
		var r := TextureRect.new()
		r.texture = Game.menu_icon(lid)
		r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		r.position = Vector2(x, y)
		if Game.seen.has(lid):
			r.tooltip_text = Game.MONSTERS[lid]["nome"]
		if int(Game.MONSTERS[line[0]].get("evo_guarda", -1)) == lid or _is_guard_child(lid):
			r.tooltip_text = (r.tooltip_text + "\n" if r.tooltip_text != "" else "") + "Ramo da GUARDA: nasce de quem foi criado mais na defesa."
		if not Game.seen.has(lid):
			r.modulate = Color(0, 0, 0, 0.6)
		elif not Game.dex_caught.has(lid):
			r.modulate = Color(0.35, 0.32, 0.45)
		if lid == id:
			var hl := ColorRect.new()
			hl.color = Color(1, 0.85, 0.3, 0.25)
			hl.position = Vector2(x - 2, y - 2)
			hl.size = Vector2(36, 36)
			detail.add_child(hl)
		detail.add_child(r)
		var lv: int = _evo_lv_into(lid)
		var fm: String = Game.MONSTERS[lid].get("forma", "")
		if fm == "D" or fm == "A":
			var mk := TextureRect.new()
			mk.texture = Game.tex(UI % ("despertar" if fm == "D" else "ascensao"))
			mk.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			mk.position = Vector2(x + 9, y + 32)
			mk.tooltip_text = "Despertar (4ª forma)" if fm == "D" else "Ascensão (5ª forma)"
			mk.mouse_filter = Control.MOUSE_FILTER_PASS
			detail.add_child(mk)
		elif lv > 0:
			var lvl := Label.new()
			lvl.text = "Nv%d" % lv
			lvl.position = Vector2(x + 2, y + 31)
			lvl.add_theme_font_size_override("font_size", 8)
			lvl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
			detail.add_child(lvl)
	var aw := Label.new()
	aw.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var has_d := false
	for lid in line:
		if Game.MONSTERS[lid].get("forma", "") == "D":
			has_d = true
	if has_d:
		aw.text = "Sol = DESPERTAR (Nv %d + Cristal). Estrela = ASCENSÃO. Veja ? FORMAS." % Game.AWAKEN_LV
	else:
		aw.text = "Forma final pode DESPERTAR depois de purificar os 3 mundos (Nv %d). Veja ? FORMAS." % Game.AWAKEN_LV
	aw.position = Vector2(12, 136 + rows[0] * 40)
	if rows[0] > 0:
		aw.text = "Forma final pode DESPERTAR (Nv %d)." % Game.AWAKEN_LV
	aw.size = Vector2(170, 40)
	aw.custom_minimum_size = Vector2(170, 0)
	aw.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aw.add_theme_font_size_override("font_size", 7)
	aw.add_theme_color_override("font_color", Color("ffcf6a"))
	detail.add_child(aw)
	# raridades
	var rl := Label.new()
	rl.text = "RARIDADES"
	rl.position = Vector2(12, 196)
	rl.add_theme_font_size_override("font_size", 8)
	rl.add_theme_color_override("font_color", Color("ffd84a"))
	detail.add_child(rl)
	if not caught:
		var h := Label.new()
		h.text = "Capture ao menos um %s para descobrir em quais raridades ele pode aparecer." % d["nome"]
		h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h.position = Vector2(12, 212)
		h.size = Vector2(282, 40)
		h.add_theme_font_size_override("font_size", 8)
		detail.add_child(h)
		return
	var opts := Game.rar_options(id)
	var had: Array = Game.dex_caught.get(id, [])
	for r in 5:
		var chip := Chip.new()
		chip.rar = r
		chip.possible = opts.has(r)
		chip.owned = had.has(r)
		chip.position = Vector2(12 + r * 57, 212)
		detail.add_child(chip)
	rl.tooltip_text = "Cheio = você já teve. Contorno = pode aparecer. Apagado = não existe. Raridade maior = atributos maiores (Comum x1,0 até Lendário x1,3)."
	rl.mouse_filter = Control.MOUSE_FILTER_PASS
	var leg := Label.new()
	leg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	leg.text = Game.DEX_TEXT.get(id, "Cheio = você já teve. Contorno = pode aparecer. Apagado = não existe.")
	leg.position = Vector2(12, 244)
	leg.size = Vector2(286, 50)
	leg.custom_minimum_size = Vector2(286, 0)
	leg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	leg.add_theme_font_size_override("font_size", 8)
	leg.add_theme_color_override("font_color", Color("e8e0ff"))
	detail.add_child(leg)


## Forma que vem depois do ramo da Guarda (ex.: Muralhatu, depois de Tatumuro).
func _is_guard_child(id: int) -> bool:
	for k in Game.MONSTERS:
		var g := int(Game.MONSTERS[k].get("evo_guarda", -1))
		if g >= 0 and Game.MONSTERS[g]["evo"].size() > 0 and int(Game.MONSTERS[g]["evo"][0]) == id:
			return true
	return false


func _evo_lv_into(id: int) -> int:
	for k in Game.MONSTERS:
		var d: Dictionary = Game.MONSTERS[k]
		var e: Array = d["evo"]
		if e.size() > 0 and int(e[0]) == id:
			return int(e[1])
		if int(d.get("evo_guarda", -1)) == id:
			return int(e[1]) if e.size() > 1 else 0
	return 0


class Card extends Control:
	var id := 0
	var num := 0
	var selected := false
	var pressed_cb: Callable
	var icon: Texture2D

	func _ready() -> void:
		custom_minimum_size = Vector2(44, 44)
		mouse_filter = Control.MOUSE_FILTER_STOP
		icon = Game.menu_icon(id)
		var seen: bool = Game.seen.has(id)
		tooltip_text = ("#%03d %s" % [num, Game.MONSTERS[id]["nome"]]) if seen else "#%03d ???" % num

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			pressed_cb.call(id)

	func _draw() -> void:
		var seen: bool = Game.seen.has(id)
		var caught: bool = Game.dex_caught.has(id)
		var bgc := Color(1, 1, 1, 0.06)
		if caught:
			bgc = Color(Game.MONSTERS[id]["cor"], 0.18)
		draw_rect(Rect2(Vector2.ZERO, size), bgc)
		draw_rect(Rect2(Vector2.ZERO, size), Color("ffd84a") if selected else Color(1, 1, 1, 0.15), false, 1.0)
		var f := get_theme_font("font", "Label")
		draw_string(f, Vector2(3, 9), "%03d" % num, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 1, 1, 0.5))
		if not seen:
			draw_string(f, Vector2(17, 30), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.35))
			return
		var mod := Color.WHITE if caught else Color(0.12, 0.1, 0.2, 0.9)
		draw_texture(icon, Vector2(6, 8), mod)
		if caught:
			var had: Array = Game.dex_caught.get(id, [])
			for i in had.size():
				draw_rect(Rect2(Vector2(4 + i * 5, 39), Vector2(3, 3)), Game.rar_color(int(had[i])))
			if Game.line_complete(id):
				draw_colored_polygon(PackedVector2Array([Vector2(size.x - 9, 0), Vector2(size.x, 0), Vector2(size.x, 9)]), Color("ffd84a"))


## O segredo da Digidex: a silhueta vai trocando entre as de todos os Digialmas.
class SecretCard extends Control:
	var id := -1
	var num := 0
	var selected := false
	var big := false
	var pressed_cb: Callable
	var icons: Array = []
	var tt := 0.0

	func _ready() -> void:
		custom_minimum_size = Vector2(120, 120) if big else Vector2(44, 44)
		mouse_filter = Control.MOUSE_FILTER_IGNORE if big else Control.MOUSE_FILTER_STOP
		tooltip_text = "#%03d ???" % num
		for k in Game.dex_order():
			icons.append(Game.menu_icon(k))
		icons.shuffle()

	func _process(d: float) -> void:
		tt += d
		queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if not big and e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			pressed_cb.call()

	func _draw() -> void:
		var sc := 3.4 if big else 1.0
		if not big:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 0.9, 0.4, 0.06 + 0.04 * sin(tt * 2.0)))
			draw_rect(Rect2(Vector2.ZERO, size), Color("ffd84a") if selected else Color(0.6, 1, 0.6, 0.35), false, 1.0)
			draw_string(get_theme_font("font", "Label"), Vector2(3, 9), "%03d" % num, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.7, 1, 0.7, 0.6))
		if icons.is_empty():
			return
		# troca de silhueta a cada 1,2 s, com um "borrão" na passagem
		var per := 1.2
		var i := int(tt / per) % icons.size()
		var f := fmod(tt, per) / per
		var a := clampf(minf(f, 1.0 - f) * 6.0, 0.0, 1.0)
		var tex: Texture2D = icons[i]
		var pos := (size - Vector2(32, 32) * sc) * 0.5 + (Vector2(0, 2) if not big else Vector2.ZERO)
		for k in 3:
			var jit := Vector2(sin(tt * 9.0 + k * 2.0), cos(tt * 7.0 + k)) * (1.0 - a) * 2.0 * sc
			draw_texture_rect(tex, Rect2(pos + jit, Vector2(32, 32) * sc), false, Color(0.06, 0.05, 0.12, (0.9 if k == 0 else 0.25) * maxf(a, 0.3)))


class Chip extends Control:
	var rar := 0
	var possible := true
	var owned := false

	func _ready() -> void:
		custom_minimum_size = Vector2(54, 24)
		size = Vector2(54, 24)
		tooltip_text = Game.RARITY[rar]["nome"] + (" (você já teve)" if owned else (" (pode aparecer)" if possible else " (não existe)"))
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _draw() -> void:
		var c: Color = Game.rar_color(rar)
		var f := get_theme_font("font", "Label")
		if not possible:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.04))
			draw_string(f, Vector2(4, 15), Game.RARITY[rar]["nome"], HORIZONTAL_ALIGNMENT_LEFT, 48, 7, Color(1, 1, 1, 0.2))
			return
		if owned:
			draw_rect(Rect2(Vector2.ZERO, size), Color(c, 0.85))
			draw_string(f, Vector2(4, 15), Game.RARITY[rar]["nome"], HORIZONTAL_ALIGNMENT_LEFT, 48, 7, Color("140a22"))
		else:
			draw_rect(Rect2(Vector2.ZERO, size), Color(c, 0.12))
			draw_rect(Rect2(Vector2.ZERO, size), c, false, 1.0)
			draw_string(f, Vector2(4, 15), Game.RARITY[rar]["nome"], HORIZONTAL_ALIGNMENT_LEFT, 48, 7, c)
