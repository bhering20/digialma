extends Control
## NOVA JORNADA (começo do Modo Idle): 1) quem é você (Léo ou Lia + nome);
## 2) escolha do parceiro (Brotito, Brasito ou Marolim). Depois, a faixa.

const T = preload("res://scripts/title.gd")
const STARTERS := [
	{"id": 1, "forte": "Forte contra Água e Pedra", "frase": "Tímido, mas cresce forte e protege quem ama."},
	{"id": 7, "forte": "Forte contra Planta, Gelo e Inseto", "frase": "Esquentadinho e corajoso. Bate primeiro, pergunta depois."},
	{"id": 12, "forte": "Forte contra Fogo e Pedra", "frase": "Preguiçoso e calmo, mas aguenta qualquer tempestade."},
]
var step := 1
var who := "player"
var starter := 7
var root_step: Control
var name_edit: LineEdit
var spr_by_key := {}
var peds := {}
var t := 0.0


func _ready() -> void:
	theme = Game.make_theme()
	size = Game.BASE
	var bg := TextureRect.new()
	bg.texture = Game.tex("res://assets/backgrounds/titulo.png")
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.size = Game.BASE
	bg.modulate = Color(0.55, 0.5, 0.7)
	add_child(bg)
	add_child(T.FxLayer.new())
	who = Game.player_char if Game.CHARACTERS.has(Game.player_char) else "player"
	_build_step()


func _process(d: float) -> void:
	t += d


func _clear() -> void:
	if is_instance_valid(root_step):
		root_step.queue_free()
	root_step = Control.new()
	root_step.size = Game.BASE
	add_child(root_step)
	spr_by_key = {}
	peds = {}


func _title(txt: String, sub: String) -> void:
	var h := Label.new()
	Game.heading(h, txt, 16)
	h.add_theme_color_override("font_color", Color("ffd84a"))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.size = Vector2(640, 24)
	h.position = Vector2(0, 16)
	root_step.add_child(h)
	var s := Label.new()
	s.text = sub
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.size = Vector2(640, 16)
	s.position = Vector2(0, 42)
	s.add_theme_font_size_override("font_size", 9)
	s.add_theme_color_override("font_color", Color("e8e0ff"))
	root_step.add_child(s)
	var dots := Label.new()
	dots.text = ("●  ○" if step == 1 else "○  ●")
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dots.size = Vector2(640, 12)
	dots.position = Vector2(0, 58)
	dots.add_theme_font_size_override("font_size", 8)
	dots.add_theme_color_override("font_color", Color(1, 0.85, 0.4, 0.8))
	root_step.add_child(dots)


func _pedestal(key, pos: Vector2, col: Color, cb: Callable) -> void:
	var p := Pedestal.new()
	p.position = pos
	p.col = col
	root_step.add_child(p)
	peds[key] = p
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.position = pos - Vector2(60, 150)
	b.size = Vector2(120, 170)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(cb)
	root_step.add_child(b)


func _build_step() -> void:
	_clear()
	if step == 1:
		_title("QUEM É VOCÊ?", "Os Digialmas escolhem com quem caminhar. Primeiro, conte quem você é.")
		var xs := {"player": 220.0, "young_girl": 420.0}
		for key in ["player", "young_girl"]:
			var info: Dictionary = Game.CHARACTERS[key]
			_pedestal(key, Vector2(xs[key], 262), info["cor"], func(): _pick_who(key))
			var s := AnimatedSprite2D.new()
			s.sprite_frames = Game.char_frames(key)
			s.play("idle_down")
			s.centered = false
			s.offset = Vector2(-64, -128)
			s.position = Vector2(xs[key], 266)
			root_step.add_child(s)
			spr_by_key[key] = s
			var lb := Label.new()
			lb.text = "%s\n%s" % [info["nome"], info["titulo"]]
			lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lb.size = Vector2(120, 30)
			lb.position = Vector2(xs[key] - 60, 278)
			lb.add_theme_font_size_override("font_size", 9)
			root_step.add_child(lb)
		var nh := HBoxContainer.new()
		nh.position = Vector2(200, 318)
		nh.add_theme_constant_override("separation", 6)
		var nl := Label.new()
		nl.text = "SEU NOME:"
		nl.add_theme_font_size_override("font_size", 9)
		nh.add_child(nl)
		name_edit = LineEdit.new()
		name_edit.custom_minimum_size = Vector2(150, 22)
		name_edit.max_length = 12
		name_edit.text = Game.player_name if Game.player_name != "" else Game.CHARACTERS[who]["nome"]
		nh.add_child(name_edit)
		root_step.add_child(nh)
		_buttons("VOLTAR", func(): Game.change_scene("res://scenes/title.tscn"), "PRÓXIMO", func():
			Game.player_char = who
			Game.player_name = name_edit.text.strip_edges() if name_edit.text.strip_edges() != "" else Game.CHARACTERS[who]["nome"]
			step = 2
			_build_step())
		_pick_who(who)
	else:
		_title("ESCOLHA SEU PARCEIRO", "Ele vai caminhar com %s pela faixa, purificar Nefastos e crescer junto." % Game.player_name)
		var i := 0
		for st in STARTERS:
			var id: int = st["id"]
			var d: Dictionary = Game.MONSTERS[id]
			var x := 160.0 + i * 160.0
			_pedestal(id, Vector2(x, 236), d["cor"], func(): _pick_starter(id))
			var s := AnimatedSprite2D.new()
			s.sprite_frames = Game.monster_frames(id)
			s.play("idle")
			s.centered = false
			s.offset = Game.foot_offset(id)
			s.scale = Vector2(2, 2)
			s.position = Vector2(x, 240)
			root_step.add_child(s)
			spr_by_key[id] = s
			var card := VBoxContainer.new()
			card.position = Vector2(x - 74, 248)
			card.custom_minimum_size = Vector2(148, 0)
			card.add_theme_constant_override("separation", 1)
			root_step.add_child(card)
			var nm := Label.new()
			nm.text = d["nome"]
			nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nm.add_theme_font_size_override("font_size", 11)
			nm.add_theme_color_override("font_color", (d["cor"] as Color).lightened(0.35))
			card.add_child(nm)
			var th := HBoxContainer.new()
			th.alignment = BoxContainer.ALIGNMENT_CENTER
			th.add_theme_constant_override("separation", 3)
			var ti := TextureRect.new()
			ti.texture = Game.tex("res://assets/ui/idle_tipo_%s.png" % Game.TYPE_SLUG.get(d["tipo"], "normal"))
			ti.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			th.add_child(ti)
			var tl := Label.new()
			tl.text = "%s · %s" % [d["tipo"], d["jeito"]]
			tl.add_theme_font_size_override("font_size", 8)
			th.add_child(tl)
			card.add_child(th)
			for line in [st["frase"], st["forte"]]:
				var l := Label.new()
				l.text = line
				l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				l.custom_minimum_size = Vector2(148, 0)
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				l.add_theme_font_size_override("font_size", 7)
				l.add_theme_color_override("font_color", Color(1, 1, 1, 0.75) if line == st["frase"] else Color("7affc1"))
				card.add_child(l)
			i += 1
		_buttons("VOLTAR", func():
			step = 1
			_build_step(), "COMEÇAR!", _start)
		_pick_starter(starter)


func _buttons(a: String, fa: Callable, b: String, fb: Callable) -> void:
	var back := Button.new()
	back.text = a
	back.position = Vector2(20, 324)
	back.custom_minimum_size = Vector2(100, 26)
	back.pressed.connect(fa)
	root_step.add_child(back)
	var go := Button.new()
	go.text = b
	go.position = Vector2(500, 324)
	go.custom_minimum_size = Vector2(120, 26)
	go.pressed.connect(fb)
	root_step.add_child(go)
	go.grab_focus.call_deferred()


func _pick_who(key: String) -> void:
	who = key
	Game.sfx("item")
	if name_edit and (name_edit.text == "" or name_edit.text in ["Léo", "Lia"]):
		name_edit.text = Game.CHARACTERS[key]["nome"]
	for k in spr_by_key:
		var on: bool = k == key
		(spr_by_key[k] as AnimatedSprite2D).play("down" if on else "idle_down")
		(spr_by_key[k] as AnimatedSprite2D).modulate = Color.WHITE if on else Color(0.45, 0.42, 0.6)
		peds[k].on = on


func _pick_starter(id: int) -> void:
	starter = id
	Game.sfx("item")
	for k in spr_by_key:
		var on: bool = k == id
		var s: AnimatedSprite2D = spr_by_key[k]
		s.modulate = Color.WHITE if on else Color(0.4, 0.38, 0.55)
		peds[k].on = on
		if on:
			var y0 := 240.0
			var tw := s.create_tween()
			tw.tween_property(s, "position:y", y0 - 14.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(s, "position:y", y0, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _start() -> void:
	Game.new_game(starter)
	Game.player_char = who
	Game.region = 0
	Game.sfx("captura")
	Game.save_game()
	Game.change_scene("res://scenes/idle.tscn")


## Círculo de alma no chão, que brilha embaixo do escolhido.
class Pedestal extends Node2D:
	var col := Color.WHITE
	var on := false
	var t := 0.0

	func _process(d: float) -> void:
		t += d
		queue_redraw()

	func _draw() -> void:
		var k := 1.0 if on else 0.35
		var pul := 0.5 + 0.5 * sin(t * 3.0)
		for i in 3:
			var w := 52.0 - i * 12.0
			_ellipse(Vector2.ZERO, Vector2(w, w * 0.28), Color(col, (0.08 + 0.06 * i) * k * (0.7 + 0.3 * pul)), true)
		_ellipse(Vector2.ZERO, Vector2(46, 13), Color(col.lightened(0.4), 0.8 * k), false)
		_ellipse(Vector2.ZERO, Vector2(34, 9), Color(col.lightened(0.6), 0.5 * k * pul), false)
		if on:
			for i in 6:
				var a := t * 0.8 + i * TAU / 6.0
				var p := Vector2(cos(a) * 46.0, sin(a) * 13.0) - Vector2(0, fmod(t * 20.0 + i * 13.0, 60.0))
				draw_rect(Rect2(p.round(), Vector2(1, 2)), Color(col.lightened(0.6), 0.8))

	func _ellipse(c: Vector2, r: Vector2, color: Color, fill: bool) -> void:
		var pts := PackedVector2Array()
		for i in 33:
			var a := i * TAU / 32.0
			pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
		if fill:
			draw_colored_polygon(pts, color)
		else:
			draw_polyline(pts, color, 1.0)
