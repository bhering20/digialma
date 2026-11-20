extends Control
## MAPA DO MUNDO (estilo TBH): cada mapa é uma ilha com 10 zonas ligadas por
## uma trilha. Enquanto o Santuário (zona 10) não é vencido, a ilha fica coberta
## pela névoa roxa da corrupção; ao purificar, a cor volta. Clique numa zona já
## liberada para viajar até ela. Os mundos seguintes aparecem como "???".

const UI := "res://assets/ui/idle_%s.png"
const ISLAND_COL := [Color("4fa85a"), Color("3f8fd8"), Color("d8643a")]
const CENTERS := [Vector2(118, 200), Vector2(318, 168), Vector2(516, 206)]
const FUTURE := [["Mid game", Vector2(230, 300)], ["End game", Vector2(440, 304)]]

var t := 0.0
var nodes := []  # [{pos, r, z}]
var hover := {}
var tip: Label


func _ready() -> void:
	theme = Game.make_theme()
	size = Game.BASE
	mouse_filter = Control.MOUSE_FILTER_STOP
	var title := Label.new()
	Game.heading(title, "MAPA DO MUNDO", 16)
	title.add_theme_color_override("font_color", Color("ffd84a"))
	title.position = Vector2(16, 10)
	add_child(title)
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
	tip = Label.new()
	tip.position = Vector2(16, 336)
	tip.size = Vector2(608, 18)
	tip.add_theme_font_size_override("font_size", 9)
	tip.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	tip.text = "Clique numa zona liberada para viajar. Zona 10 = Santuário: vença o guardião para purificar a ilha."
	add_child(tip)
	_build_nodes()


func _build_nodes() -> void:
	nodes.clear()
	for r in Game.REGIONS.size():
		var c: Vector2 = CENTERS[r]
		for z in range(1, Game.ZONES + 1):
			# trilha em espiral, de fora para dentro, terminando no santuário
			var k := float(z - 1) / (Game.ZONES - 1)
			var a := -2.6 + k * 4.6 + r * 0.7
			var rad := 62.0 - k * 46.0
			nodes.append({"pos": c + Vector2(cos(a) * rad, sin(a) * rad * 0.62), "r": r, "z": z})


func _process(d: float) -> void:
	t += d
	queue_redraw()


func _state(r: int, z: int) -> int:
	# 0 trancada · 1 liberada · 2 vencida · 3 você está aqui
	if r > mini(Game.badges, Game.REGIONS.size() - 1):
		return 0
	if r == Game.region and z == Game.zone_of(r):
		return 3
	if not Game.region_corrupt(r) or z < int(Game.zone_max.get(r, 0)):
		return 2
	if z <= int(Game.zone_max.get(r, 0 if r > 0 else 1)):
		return 1
	return 0


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		hover = {}
		for n in nodes:
			if (n["pos"] as Vector2).distance_to(e.position) < 8.0:
				hover = n
				break
		_update_tip()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and not hover.is_empty():
		var st := _state(hover["r"], hover["z"])
		if st == 0:
			return
		var host := get_tree().current_scene
		if host and host.has_method("travel_to"):
			host.travel_to(hover["r"], hover["z"])
			if Game.in_panel(self) and is_instance_valid(get_window()):
				get_window().queue_free()


func _update_tip() -> void:
	if hover.is_empty():
		tip.text = "Clique numa zona liberada para viajar. Zona 10 = Santuário: vença o guardião para purificar a ilha."
		return
	var r: int = hover["r"]
	var z: int = hover["z"]
	var lv := Game.zone_levels(r, z)
	var st := _state(r, z)
	var name: String = Game.REGIONS[r]["nome"]
	var what := "Santuário de %s" % Game.REGIONS[r]["lider"]["nome"] if z == Game.ZONES else "Zona %d-%d" % [r + 1, z]
	tip.text = "%s · %s · Nefastos Nv %d-%d · %s" % [name, what, lv.x, lv.y, ["trancada", "liberada", "vencida", "você está aqui"][st]]


func _draw() -> void:
	# mar/vazio com estrelas
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.03, 0.1, 0.98))
	for i in 60:
		var p := Vector2(fmod(i * 97.3, 640.0), fmod(i * 53.7 + 30.0, 330.0) + 30.0)
		draw_rect(Rect2(p, Vector2(1, 1)), Color(1, 1, 1, 0.15 + 0.15 * sin(t * 1.5 + i)))
	# pontes entre as ilhas
	for r in Game.REGIONS.size() - 1:
		var a: Vector2 = CENTERS[r] + Vector2(60, -6)
		var b: Vector2 = CENTERS[r + 1] + Vector2(-64, 4)
		var open := Game.badges > r
		_dashed(a, b, Color(1, 0.9, 0.6, 0.6) if open else Color(1, 1, 1, 0.15))
	# ilhas
	for r in Game.REGIONS.size():
		_island(r)
	# mundos futuros
	for f in FUTURE:
		_ghost_island(f[1], f[0])
	# trilha + zonas
	for r in Game.REGIONS.size():
		var prev := Vector2.INF
		for n in nodes:
			if n["r"] != r:
				continue
			if prev != Vector2.INF:
				var st := _state(r, n["z"])
				draw_line(prev, n["pos"], Color(1, 0.95, 0.75, 0.55) if st > 0 else Color(1, 1, 1, 0.12), 2.0)
			prev = n["pos"]
	var f := get_theme_font("font", "Label")
	for n in nodes:
		var p: Vector2 = n["pos"]
		var st := _state(n["r"], n["z"])
		var sanct: bool = n["z"] == Game.ZONES
		var rad := 7.0 if sanct else 5.0
		var col: Color = [Color(0.25, 0.22, 0.32), Color("e8e4f0"), Color("6fe08a"), Color("ffd84a")][st]
		if st == 3:
			var pulse := 0.5 + 0.5 * sin(t * 4.0)
			draw_circle(p, rad + 3.0 + pulse * 2.0, Color(1, 0.85, 0.3, 0.25))
		draw_circle(p, rad + 1.0, Color("140a22"))
		draw_circle(p, rad, col)
		if sanct:
			var ic := Game.tex(UI % "santuario")
			draw_texture(ic, p - Vector2(7, 7), Color.WHITE if st > 0 else Color(0.4, 0.4, 0.5))
		elif st > 0:
			draw_string(f, p + Vector2(-3, 3), str(n["z"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("140a22"))
		if hover == n:
			draw_arc(p, rad + 3.0, 0, TAU, 24, Color.WHITE, 1.0)
	# você está aqui: o treinador em cima da zona atual
	for n in nodes:
		if _state(n["r"], n["z"]) == 3:
			var kt := Game.tex(UI % "laco")
			draw_texture(kt, n["pos"] + Vector2(-7, -22 + sin(t * 3.0) * 2.0))


func _island(r: int) -> void:
	var c: Vector2 = CENTERS[r]
	var locked := r > mini(Game.badges, Game.REGIONS.size() - 1)
	var corrupt := Game.region_corrupt(r)
	var base: Color = ISLAND_COL[r]
	if corrupt:
		base = base.lerp(Color("5a3a7a"), 0.55)
	if locked:
		base = Color(0.16, 0.14, 0.22)
	var pts := PackedVector2Array()
	for i in 36:
		var a := TAU * i / 36.0
		var wob := 1.0 + 0.12 * sin(a * 3.0 + r * 2.0) + 0.06 * sin(a * 7.0 + r)
		pts.append(c + Vector2(cos(a) * 82.0, sin(a) * 56.0) * wob)
	# sombra e borda
	var sh := PackedVector2Array()
	for p in pts:
		sh.append(p + Vector2(0, 6))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.4))
	draw_colored_polygon(pts, base.darkened(0.25))
	var inner := PackedVector2Array()
	for p in pts:
		inner.append(c + (p - c) * 0.9 + Vector2(0, -2))
	draw_colored_polygon(inner, base)
	# névoa da corrupção girando
	if corrupt and not locked:
		for i in 9:
			var a := t * 0.25 + i * TAU / 9.0
			var fp := c + Vector2(cos(a) * 46.0, sin(a) * 28.0)
			draw_circle(fp, 20.0 + 4.0 * sin(t + i), Color(0.55, 0.2, 0.8, 0.12))
	var f := get_theme_font("font", "Label")
	var nm: String = Game.REGIONS[r]["nome"] if not locked else "???"
	draw_string(f, c + Vector2(-60, -66), nm, HORIZONTAL_ALIGNMENT_CENTER, 120, 9, Color.WHITE if not locked else Color(1, 1, 1, 0.4))
	var status := "TRANCADO" if locked else ("CORROMPIDO" if corrupt else "PURIFICADO")
	var scol := Color(1, 1, 1, 0.35) if locked else (Color("c070ff") if corrupt else Color("6fe08a"))
	draw_string(f, c + Vector2(-60, 70), status, HORIZONTAL_ALIGNMENT_CENTER, 120, 7, scol)
	if not corrupt and not locked:
		var b := Game.tex("res://assets/badges/%s.png" % Game.REGIONS[r]["lider"]["badge"])
		draw_texture_rect(b, Rect2(c + Vector2(48, -62), Vector2(20, 20)), false)


func _ghost_island(c: Vector2, label: String) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * 44.0, sin(a) * 14.0) * (1.0 + 0.1 * sin(a * 4.0)))
	draw_colored_polygon(pts, Color(0.2, 0.16, 0.3, 0.6))
	var f := get_theme_font("font", "Label")
	draw_string(f, c + Vector2(-44, 4), "??? · " + label, HORIZONTAL_ALIGNMENT_CENTER, 88, 7, Color(1, 1, 1, 0.35))


func _dashed(a: Vector2, b: Vector2, col: Color) -> void:
	var n := int(a.distance_to(b) / 6.0)
	for i in n:
		if i % 2 == 0:
			draw_line(a.lerp(b, float(i) / n), a.lerp(b, float(i + 1) / n), col, 2.0)
