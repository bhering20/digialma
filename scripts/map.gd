extends Control
## Mapa das regiões: 3 regiões com santuários, bloqueio por insígnia, acesso ao menu (ESC).

const FX = preload("res://scripts/fx.gd")
const PauseMenu = preload("res://scripts/pause_menu.gd")

var pause_menu: CanvasLayer
var t := 0.0
var path_line: PathLine


class PathLine extends Node2D:
	var t := 0.0
	var pts := [Vector2(118, 200), Vector2(320, 170), Vector2(522, 200)]
	var unlocked := 1

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		for i in pts.size() - 1:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var open := i + 1 < unlocked
			for k in 20:
				var f := (k + fmod(t * 3.0, 1.0)) / 20.0
				var p := a.lerp(b, f)
				draw_rect(Rect2(p.round() - Vector2(2, 2), Vector2(4, 4)), Color("ffd84a") if open else Color(1, 1, 1, 0.25))


func _ready() -> void:
	theme = Game.make_theme()
	var bg := TextureRect.new()
	bg.texture = Game.tex(Game.GP + "backgrounds/forest.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.45, 0.42, 0.65)
	add_child(bg)
	var amb = preload("res://scripts/ambient.gd").new()
	amb.kind = "floresta"
	add_child(amb)
	var title := Label.new()
	Game.heading(title, "MAPA DA REGIÃO", 16)
	title.add_theme_color_override("font_color", Color("ffd84a"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(640, 24)
	title.position = Vector2(0, 46)
	add_child(title)
	path_line = PathLine.new()
	path_line.unlocked = Game.region_unlocked
	add_child(path_line)
	# mapa antigo (modo rota): só os 3 primeiros mundos
	for i in mini(Game.REGIONS.size(), 3):
		_region_card(i)
	_hud()
	pause_menu = PauseMenu.new()
	add_child(pause_menu)


func _region_card(i: int) -> void:
	var r: Dictionary = Game.REGIONS[i]
	var locked: bool = i >= Game.region_unlocked
	var done: bool = i < Game.badges
	var c := Button.new()
	c.custom_minimum_size = Vector2(170, 190)
	c.size = Vector2(170, 190)
	c.position = Vector2(33 + i * 202, 92 + (0 if i == 1 else 18))
	for st in ["normal", "disabled"]:
		c.add_theme_stylebox_override(st, Game.sb("panel", 8))
	for st in ["hover", "focus", "pressed"]:
		c.add_theme_stylebox_override(st, Game.sb("slot_sel", 5))
	c.disabled = locked
	add_child(c)
	var thumb := TextureRect.new()
	thumb.texture = Game.tex(r["bg"])
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumb.size = Vector2(154, 70)
	thumb.position = Vector2(8, 8)
	thumb.modulate = r["tint"] if not locked else Color(0.25, 0.25, 0.3)
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not locked and not done:
		thumb.material = Game.corrupt_mat()  # ainda corrompida
	c.add_child(thumb)
	var gym := TextureRect.new()
	gym.texture = Game.tex(Game.GP + "objects/%s.png" % r["arena"])
	gym.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gym.size = Vector2(64, 64)
	gym.position = Vector2(53, 48)
	gym.modulate = Color.WHITE if not locked else Color(0.2, 0.2, 0.25)
	gym.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(gym)
	var nl := Label.new()
	nl.text = r["nome"]
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.position = Vector2(0, 118)
	nl.size = Vector2(170, 12)
	c.add_child(nl)
	var sl := Label.new()
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sl.position = Vector2(0, 134)
	sl.size = Vector2(170, 24)
	sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if locked:
		sl.text = "BLOQUEADO\nPurifique o santuário anterior"
		sl.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	elif done:
		var bi := TextureRect.new()
		bi.texture = Game.tex("res://assets/badges/%s.png" % r["lider"]["badge"])
		bi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bi.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bi.position = Vector2(128, 6)
		bi.size = Vector2(36, 36)
		c.add_child(bi)
		sl.text = "%s\nconquistada!" % r["lider"]["insignia"]
		sl.add_theme_color_override("font_color", Color("ffd84a"))
	else:
		var top_lv := 0
		for pr in r["lider"]["time"]:
			top_lv = maxi(top_lv, pr[1])
		sl.text = "Líder: %s\nNefastos Nv %d-%d\nSantuário: Nv %d+" % [r["lider"]["nome"], r["nv"][0], r["nv"][1], top_lv - 2]
		sl.add_theme_color_override("font_color", Color("bff6ff"))
	c.add_child(sl)
	if not locked:
		var go := Label.new()
		go.text = "EXPLORAR" if not done else "TREINAR"
		go.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		go.position = Vector2(0, 166)
		go.size = Vector2(170, 12)
		go.add_theme_color_override("font_color", Color("5cff9c"))
		c.add_child(go)
	c.pressed.connect(func():
		Game.region = i
		Game.change_scene("res://scenes/route.tscn"))
	c.mouse_entered.connect(func(): if not locked: c.grab_focus())
	FX.juice_button(c)
	if i == mini(Game.region_unlocked - 1, 2):
		c.grab_focus.call_deferred()


func _hud() -> void:
	var chip := PanelContainer.new()
	chip.position = Vector2(8, 8)
	add_child(chip)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	chip.add_child(h)
	for m in Game.team:
		var ic := TextureRect.new()
		ic.texture = Game.menu_icon(m["id"])
		h.add_child(ic)
	var l := Label.new()
	l.text = "%s   Insígnias %d/3   Elo %d" % [Game.player_name, Game.badges, Game.elo_charges]
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	var menu_btn := Button.new()
	menu_btn.text = "MENU  [ESC]"
	menu_btn.position = Vector2(540, 12)
	menu_btn.custom_minimum_size = Vector2(92, 22)
	menu_btn.focus_mode = Control.FOCUS_NONE
	menu_btn.pressed.connect(func(): pause_menu.open())
	add_child(menu_btn)
	var idle_btn := Button.new()
	idle_btn.text = "MODO IDLE"
	idle_btn.tooltip_text = "Seu time explora sozinho numa faixa na barra de tarefas."
	idle_btn.position = Vector2(440, 12)
	idle_btn.custom_minimum_size = Vector2(92, 22)
	idle_btn.focus_mode = Control.FOCUS_NONE
	idle_btn.add_theme_color_override("font_color", Color("ffd84a"))
	idle_btn.pressed.connect(func():
		Game.region = mini(Game.badges, Game.REGIONS.size() - 1)
		Game.change_scene("res://scenes/idle.tscn"))
	add_child(idle_btn)
	var tree_btn := Button.new()
	tree_btn.text = "ÁRVORES"
	tree_btn.tooltip_text = "Árvore de Alma, melhorias do Elo e Equipe."
	tree_btn.position = Vector2(340, 12)
	tree_btn.custom_minimum_size = Vector2(92, 22)
	tree_btn.focus_mode = Control.FOCUS_NONE
	tree_btn.add_theme_color_override("font_color", Color("8af0c0"))
	tree_btn.pressed.connect(func(): Game.change_scene("res://scenes/arvores.tscn"))
	add_child(tree_btn)
	var dex_btn := Button.new()
	dex_btn.text = "DIGIDEX"
	dex_btn.tooltip_text = "Todos os Digialmas que você já encontrou e suas raridades."
	dex_btn.position = Vector2(540, 40)
	dex_btn.custom_minimum_size = Vector2(92, 22)
	dex_btn.focus_mode = Control.FOCUS_NONE
	dex_btn.add_theme_color_override("font_color", Color("9ab8ff"))
	dex_btn.pressed.connect(func(): Game.change_scene("res://scenes/digidex.tscn"))
	add_child(dex_btn)
	var hint := Label.new()
	hint.text = "Escolha uma região. Cada rota tem 3 Nefastos e um santuário corrompido."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(640, 12)
	hint.position = Vector2(0, 334)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	add_child(hint)


func _unhandled_input(event: InputEvent) -> void:
	if not pause_menu.is_open and event.is_action_pressed("ui_cancel"):
		pause_menu.open()
