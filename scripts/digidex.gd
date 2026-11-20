extends Control
## DIGIDEX: todos os Digialmas que você já encontrou.
## ? = nunca visto · sombra = visto · colorido = capturado (com as raridades que já teve).
## Clicar mostra a linha evolutiva e, se você já capturou um, as raridades possíveis.

const UI := "res://assets/ui/idle_%s.png"
var grid: GridContainer
var detail: Control
var sel := -1
var t := 0.0


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
	cnt.text = "Vistos %d   ·   Capturados %d   ·   Total %d" % [n_seen, n_caught, order.size()]
	cnt.add_theme_font_size_override("font_size", 9)
	cnt.add_theme_color_override("font_color", Color("7affc1"))
	cnt.position = Vector2(130, 18)
	add_child(cnt)
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


func _select(id: int) -> void:
	sel = id
	for c in grid.get_children():
		c.selected = c.id == id
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
	ll.text = "LINHA EVOLUTIVA"
	ll.position = Vector2(12, 78)
	ll.add_theme_font_size_override("font_size", 8)
	ll.add_theme_color_override("font_color", Color("ffd84a"))
	detail.add_child(ll)
	var line := Game.evo_line(id)
	var x := 12.0
	for lid in line:
		var r := TextureRect.new()
		r.texture = Game.menu_icon(lid)
		r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		r.position = Vector2(x, 92)
		if not Game.seen.has(lid):
			r.modulate = Color(0, 0, 0, 0.6)
		elif not Game.dex_caught.has(lid):
			r.modulate = Color(0.35, 0.32, 0.45)
		if lid == id:
			var hl := ColorRect.new()
			hl.color = Color(1, 0.85, 0.3, 0.25)
			hl.position = Vector2(x - 2, 90)
			hl.size = Vector2(36, 36)
			detail.add_child(hl)
		detail.add_child(r)
		var lv: int = _evo_lv_into(lid)
		if lv > 0:
			var lvl := Label.new()
			lvl.text = "Nv%d" % lv
			lvl.position = Vector2(x + 2, 124)
			lvl.add_theme_font_size_override("font_size", 8)
			lvl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
			detail.add_child(lvl)
		x += 38.0
	var aw := Label.new()
	aw.text = "Forma final pode DESPERTAR depois de purificar os 3 mundos (Nv %d)." % Game.AWAKEN_LV
	aw.position = Vector2(12, 136)
	aw.size = Vector2(150, 40)
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
	var leg := Label.new()
	leg.text = "Cheio = você já teve. Contorno = pode aparecer. Apagado = não existe.\nRaridade maior = atributos maiores (Comum x1,0 até Lendário x1,3)."
	leg.position = Vector2(12, 244)
	leg.size = Vector2(286, 50)
	leg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	leg.add_theme_font_size_override("font_size", 7)
	leg.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	detail.add_child(leg)


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
