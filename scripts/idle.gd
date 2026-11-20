extends Control
## MODO IDLE (estilo barra de tarefas): uma faixa fina, sem borda e sempre por cima,
## encostada na barra de tarefas. O time explora e purifica Nefastos sozinho;
## quando aparece um RARO, o Elo chama o jogador para um momento ativo.

const R = preload("res://scripts/route.gd")
const OBJ := "res://assets/packs/scarloxy_graphics/objects/"
const W := 640.0
const H := 96.0
const GROUND := 80.0
const SPEED := 40.0
## Opacidade da faixa: discreta parada, opaca com o mouse em cima.
const ALPHA_IDLE := 0.82
const ALPHA_HOVER := 1.0
## Largura da "névoa" nas pontas da faixa (o cenário some aos poucos).
const FADE := 70.0

var reg: Dictionary
var rng := RandomNumberGenerator.new()
var road: GroundStrip
var stage: Node2D
var kid: AnimatedSprite2D
var pets: Array = []
var props: Array = []
var next_prop := 0.0
var walking := true
var cmat: ShaderMaterial
var log_l: Label
var stats_l: Label
var prog: ProgressBar
var call_btn: Button
var sanct_ready := false
var purified := 0
var bits_gained := 0
var xp_gained := 0
var captured := 0
var progress := 0.0
var t := 0.0
var rare_waiting := false
var rare_answer := ""
var bg: TextureRect
var hud: Array = []
var alpha := ALPHA_IDLE
var dragging := false
var items_found := 0
var want_duel := false
var want_sanct := false
var pending_evo: Array = []
var approaching := false
var hold_evo := false
var amb2: MapAmbient
var sfx: AudioStreamPlayer
var zone_l: Label
var hp_bars: Array = []
const MiniBar = preload("res://scripts/strip_duel.gd").MiniBar
var my_region := 0
var gym: Sprite2D
var leader_spr: AnimatedSprite2D
var sanct_btn: Button
var dueling := false
var duel_btn: Button
## Quanto o caminho do idle anda por purificação (bem mais longo que jogando).
## Dano que o grupo leva no idle (o idle é mais leve que o duelo)
const IDLE_TAKEN := 0.55
const FAINT := Color(0.35, 0.35, 0.45, 0.55)
const STEP_MIN := 0.8
const STEP_MAX := 1.3
var drag_off := Vector2i.ZERO


func _ready() -> void:
	rng.randomize()
	if Game.team.is_empty():
		Game.new_game(7)
	theme = Game.make_theme()
	reg = Game.REGIONS[Game.region]
	_to_strip_window()
	size = Vector2(W, H)
	# sem fundo: a janela é transparente e só o chão "flutua" sobre a sua tela
	mouse_filter = Control.MOUSE_FILTER_STOP
	if Game.region_corrupt(Game.region):
		cmat = Game.corrupt_mat()
	road = GroundStrip.new()
	road.kind = reg.get("chao", "terra")
	road.width = W
	road.ground = GROUND
	road.material = cmat
	add_child(road)
	amb2 = MapAmbient.new()
	amb2.kind = ["floresta", "costa", "vulcao"][mini(Game.region, 2)]
	amb2.corrupted = cmat != null
	amb2.ground = GROUND
	add_child(amb2)
	stage = Node2D.new()
	stage.y_sort_enabled = true
	add_child(stage)
	while next_prop < W + 60:
		_spawn_prop(next_prop)
		next_prop += rng.randf_range(40, 110)
	_spawn_party()
	my_region = Game.region
	if Game.zone_max.get(my_region, 0) < 1:
		Game.zone_max[my_region] = 1
	_sync_progress()
	sfx = AudioStreamPlayer.new()
	add_child(sfx)
	_build_hud()
	_offline_gains()
	_heal_party(1.0)
	if progress >= 100.0 and Game.zone_of(my_region) >= Game.ZONES and Game.badges <= my_region:
		_sanctuary_ready.call_deferred()
	_log("%s começou a explorar %s." % [Game.mon_name(Game.team[0]), reg["nome"]])
	if not Game.tutorial.get("mapa%d" % my_region, false):
		Game.tutorial["mapa%d" % my_region] = true
		_map_intro.call_deferred()
	if not Game.tutorial.get("idle", false):
		Game.tutorial["idle"] = true
		hold_evo = true
		_show_help.call_deferred()
	_loop()


## Enquanto o jogo esteve fechado, o grupo continuou explorando (40% do ritmo,
## até 8 horas). Ao voltar, os ganhos aparecem em símbolos sobre o grupo.
func _offline_gains() -> void:
	if Game.last_seen <= 0:
		return
	var away := int(Time.get_unix_time_from_system()) - Game.last_seen
	Game.last_seen = 0
	if away < 120:
		return
	var mins := minf(away, 8 * 3600) / 60.0
	var n := int(mins * 0.6)  # ~15% do ritmo ativo
	if n <= 0:
		return
	var lv: int = int((reg["nv"][0] + reg["nv"][1]) / 2)
	var xp := n * (6 + lv * 2)
	var b := int(n * 14 * [1.0, 1.5, 2.0][Game.elo_level("bolsa")])
	Game.bits += b
	bits_gained += b
	purified += n
	var zk: int = Game.zone_kills.get(my_region, 0)
	Game.zone_kills[my_region] = mini(Game.zone_need(Game.zone_of(my_region)), zk + n)
	_sync_progress()
	var cr := int(n * 0.05)
	Game.cristais += cr
	Game.gain_elo(n * 2)
	_give_xp(xp)
	_refresh()
	_welcome.call_deferred(n, b, cr)
	print("[idle] offline: %d min, %d purificações" % [int(mins), n])


func _welcome(n: int, b: int, cr: int) -> void:
	await get_tree().create_timer(0.8).timeout
	var at := kid.position + Vector2(0, -50)
	_sparkle(at)
	_pop_icon(at + Vector2(-24, 6), "purif")
	_pop_text(at + Vector2(-16, 0), str(n), Color("7affc1"))
	await get_tree().create_timer(0.5).timeout
	_pop_icon(at + Vector2(10, 6), "bits")
	_pop_text(at + Vector2(18, 0), str(b), Color("ffd84a"))
	if cr > 0:
		await get_tree().create_timer(0.5).timeout
		_pop_icon(at + Vector2(44, 6), "res")
		_pop_text(at + Vector2(52, 0), str(cr), Color("7affe0"))


func _show_help() -> void:
	await _open_panel("res://scenes/como_jogar.tscn")
	hold_evo = false


# ---------------------------------------------------------------- janela
func _to_strip_window() -> void:
	var w := get_window()
	Game.options["fullscreen"] = false
	# sair da tela cheia / maximizado primeiro: nesses estados o Windows ignora o tamanho novo
	if w.mode != Window.MODE_WINDOWED:
		w.mode = Window.MODE_WINDOWED
		for i in 8:
			await get_tree().process_frame
	w.content_scale_size = Vector2i(int(W), int(H))
	w.borderless = true
	w.always_on_top = true
	w.unresizable = false
	# fundo transparente: só o que é desenhado aparece
	w.transparent = true
	get_viewport().transparent_bg = true
	_place_strip(w)
	await get_tree().create_timer(0.35).timeout
	if is_inside_tree():
		_place_strip(w)
		print("[idle] janela modo=%d tamanho=%s posição=%s" % [w.mode, w.size, w.position])


func _place_strip(w: Window) -> void:
	var usable := DisplayServer.screen_get_usable_rect(w.current_screen)
	var sz := Vector2i(int(W), int(H))
	w.size = sz
	if Game.options.has("idle_pos"):
		w.position = Game.options["idle_pos"]
	else:
		w.position = usable.position + Vector2i(usable.size.x - sz.x - 12, usable.size.y - sz.y - 6)


## Volta a janela principal para o jogo completo. Com "jogo_compacto",
## ela fica pequena, encaixada no canto da tela (estilo TBH), em vez de 1280x720.
static func restore_window(w: Window) -> void:
	w.always_on_top = false
	w.transparent = false
	w.get_viewport().transparent_bg = false
	w.content_scale_size = Vector2i(640, 360)
	var usable := DisplayServer.screen_get_usable_rect(w.current_screen)
	if Game.options.get("jogo_compacto", true):
		w.borderless = false
		w.size = panel_size(w)
		w.position = usable.position + Vector2i(usable.size.x - w.size.x - 12, usable.size.y - w.size.y - 40)
	else:
		w.borderless = false
		w.size = Vector2i(1280, 720)
		w.position = usable.position + (usable.size - w.size) / 2


static func panel_size(w: Window) -> Vector2i:
	var usable := DisplayServer.screen_get_usable_rect(w.current_screen)
	var k: float = Game.options.get("painel", 1.25)
	var sz := Vector2(640, 360) * k
	var fit := minf(1.0, minf((usable.size.x - 40) / sz.x, (usable.size.y - 140) / sz.y))
	return Vector2i(sz * fit)


## Arrastar a faixa: segure em qualquer parte vazia e mova.
func _gui_input(event: InputEvent) -> void:
	if dueling:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _try_revive_at(event.position):
			return
		if event.pressed:
			dragging = true
			drag_off = DisplayServer.mouse_get_position() - get_window().position
		else:
			dragging = false
			Game.options["idle_pos"] = get_window().position
	elif event is InputEventMouseMotion and dragging:
		get_window().position = DisplayServer.mouse_get_position() - drag_off
		_dock_panel()


## Clicar numa alma-nuvem gasta 1 Orbe de Alma e traz o Digialma de volta.
func _try_revive_at(p: Vector2) -> bool:
	for i in mini(pets.size(), Game.team.size()):
		var pet = pets[i]
		if not pet.soul:
			continue
		if absf(p.x - pet.position.x) < 16.0 and p.y > pet.position.y - 44.0 and p.y < pet.position.y + 4.0:
			var m: Dictionary = Game.team[i]
			if int(Game.inventory.get("orbe_alma", 0)) <= 0:
				_pop_icon(pet.position + Vector2(0, -44), "cadeado")
				_log("Sem Orbe de Alma: %s continua como alma." % Game.mon_name(m), Color("c8b8ff"))
				return true
			Game.inventory["orbe_alma"] = int(Game.inventory["orbe_alma"]) - 1
			_revive(i, 0.5)
			return true
	return false


func _revive(i: int, frac: float) -> void:
	var m: Dictionary = Game.team[i]
	m["hp"] = maxi(1, int(Game.max_hp(m) * frac))
	if i < pets.size():
		var pet = pets[i]
		pet.set_soul(false)
		pet.play("walk" if walking else "idle")
		_sparkle(pet.position + Vector2(0, -24))
		_burst(pet.position + Vector2(0, -20), Color("9effd8"), 18)
		_pop_icon(pet.position + Vector2(0, -44), "coracao")
	Game.sfx("evolucao", -6.0)
	_log("%s voltou da forma de alma!" % Game.mon_name(m), Color("9effd8"))
	_refresh()


func _open_full() -> void:
	restore_window(get_window())
	Game.change_scene("res://scenes/map.tscn")


func _open_bag() -> void:
	_open_panel("res://scenes/arvores.tscn")


func _open_duel() -> void:
	if Game.duel_queue.is_empty() or dueling or _lead_idx() < 0:
		return
	if Game.options.get("duelo_faixa", true):
		want_duel = true  # começa assim que o encontro atual terminar
		duel_btn.visible = false
	else:
		_open_panel("res://scenes/duelo.tscn")


func _elo_xp(n: int) -> void:
	if Game.gain_elo(n):
		# o Elo subiu de nível: brilho dourado no personagem
		_pop_icon(kid.position + Vector2(0, -46), "laco")
		_burst(kid.position + Vector2(0, -24), Color("7affc1"), 14)
		_sparkle(kid.position + Vector2(0, -30))
	_refresh()


## O duelo acontece aqui mesmo, na faixa.
func _strip_duel(e: Dictionary) -> void:
	dueling = true
	_set_walking(false)
	_refresh()
	var d = load("res://scripts/strip_duel.gd").new()
	d.host = self
	d.e = e
	d.auto = Game.debug_species == -9
	add_child(d)
	var r: String = await d.run()
	_elo_xp(d.elo_gain)
	d.queue_free()
	if r == "win" or r == "caught":
		var g := Game.random_gear(2 if e["rar"] >= 4 else 1)
		var b: int = 60 * (e["rar"] + 1)
		Game.cristais += 1 + (1 if e["rar"] >= 4 else 0)
		_pop_icon(Vector2(372, GROUND - 46), "res")
		Game.bits += b
		bits_gained += b
		items_found += 1
		purified += 1
		_give_xp(20 + e["lv"] * 4)
		_drop_fx(Vector2(372, GROUND - 20), g)
		if r == "caught":
			e["hp"] = Game.max_hp(e)
			Game.add_partner(e)
			captured += 1
			_pop_icon(kid.position + Vector2(0, -44), "coracao")
			Game.sfx("captura")
		Game.sfx("captura")
	print("[duelo] resultado=", r)
	dueling = false
	_refresh()


## PAINEL: outra janela, encaixada em cima da faixa (como no TBH).
## A faixa continua rodando enquanto o painel está aberto.
var panel_win: Window


func _open_panel(path: String) -> void:
	var w := await _make_panel()
	w.add_child(load(path).instantiate())
	w.grab_focus()


func _make_panel(content := Vector2i(640, 360), win_size := Vector2i.ZERO) -> Window:
	if is_instance_valid(panel_win):
		panel_win.queue_free()
		await get_tree().process_frame
	var w := Window.new()
	w.title = "Digialma"
	w.borderless = true
	w.always_on_top = true
	w.transient = false
	w.unresizable = true
	w.content_scale_size = content
	w.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	w.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	w.size = panel_size(get_window()) if win_size == Vector2i.ZERO else win_size
	w.close_requested.connect(w.queue_free)
	w.tree_exited.connect(_refresh)
	panel_win = w
	add_child(w)
	_dock_panel()
	return w


func _dock_panel() -> void:
	if not is_instance_valid(panel_win):
		return
	var me := get_window()
	var usable := DisplayServer.screen_get_usable_rect(me.current_screen)
	var pos := Vector2i(me.position.x + me.size.x - panel_win.size.x, me.position.y - panel_win.size.y - 4)
	if panel_win.size.x < 400:  # janelinha (evolução): em cima do Digialma
		pos.x = me.position.x + int(240.0 * me.size.x / W) - panel_win.size.x / 2
	pos.x = clampi(pos.x, usable.position.x, usable.end.x - panel_win.size.x)
	if pos.y < usable.position.y:  # faixa no topo: painel abre embaixo
		pos.y = me.position.y + me.size.y + 4
	panel_win.position = pos


# ---------------------------------------------------------------- interface
const UI := "res://assets/ui/idle_%s.png"
var cnt := {}


## Sem texto na faixa: só símbolos (e números).
func _build_hud() -> void:
	var v := VBoxContainer.new()
	v.position = Vector2(FADE * 0.5, 2)
	v.add_theme_constant_override("separation", 1)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	hud.append(v)
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", 3)
	ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(ph)
	ph.mouse_filter = Control.MOUSE_FILTER_PASS
	var prev := _pill("<", 14)
	prev.custom_minimum_size = Vector2(14, 13)
	prev.tooltip_text = "Zona anterior (para farmar)"
	prev.pressed.connect(func(): _step_zone(-1))
	ph.add_child(prev)
	zone_l = Label.new()
	zone_l.custom_minimum_size = Vector2(28, 0)
	zone_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_outline(zone_l, Color("ffd84a"))
	zone_l.mouse_filter = Control.MOUSE_FILTER_PASS
	ph.add_child(zone_l)
	var nxt := _pill(">", 14)
	nxt.custom_minimum_size = Vector2(14, 13)
	nxt.tooltip_text = "Próxima zona liberada"
	nxt.pressed.connect(func(): _step_zone(1))
	ph.add_child(nxt)
	var auto := _icon_btn("auto", "Avançar sozinho para a próxima zona (desligado: fica farmando aqui)")
	auto.custom_minimum_size = Vector2(18, 13)
	auto.modulate = Color.WHITE if Game.zone_auto else Color(0.5, 0.5, 0.55)
	auto.pressed.connect(func():
		Game.zone_auto = not Game.zone_auto
		auto.modulate = Color.WHITE if Game.zone_auto else Color(0.5, 0.5, 0.55))
	ph.add_child(auto)
	var shrine := _ico("santuario")
	shrine.tooltip_text = "Zona 10 completa = %s" % reg["lider"]["ginasio"]
	shrine.mouse_filter = Control.MOUSE_FILTER_PASS
	prog = ProgressBar.new()
	prog.show_percentage = false
	prog.custom_minimum_size = Vector2(70, 5)
	prog.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prog.max_value = 100
	var f := StyleBoxFlat.new()
	f.bg_color = Color("c070ff")
	f.set_corner_radius_all(2)
	prog.add_theme_stylebox_override("fill", f)
	var bgs := StyleBoxFlat.new()
	bgs.bg_color = Color(0.08, 0.04, 0.15, 0.7)
	bgs.set_corner_radius_all(2)
	bgs.border_color = Color("140a22")
	bgs.set_border_width_all(1)
	prog.add_theme_stylebox_override("background", bgs)
	ph.add_child(prog)
	ph.add_child(shrine)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(row)
	for k in [["laco", "Nível do Elo (capturar raros exige nível)"], ["purif", "Purificados"], ["bits", "Bits ganhos"], ["gema", "Amuletos achados"], ["coracao", "Novos parceiros"], ["orbe", "Orbes de Alma: clique numa alma-nuvem para reviver o Digialma"]]:
		var ic := _ico(k[0])
		ic.tooltip_text = k[1]
		ic.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(ic)
		var n := Label.new()
		n.custom_minimum_size = Vector2(22, 0)
		_outline(n, Color.WHITE)
		row.add_child(n)
		cnt[k[0]] = n
	stats_l = Label.new()  # mantido só para compatibilidade
	log_l = Label.new()
	log_l.visible = false
	add_child(log_l)
	var bx := HBoxContainer.new()
	bx.position = Vector2(W - FADE * 0.5 - 158, 2)
	bx.add_theme_constant_override("separation", 3)
	add_child(bx)
	hud.append(bx)
	var snd := _icon_btn("som" if Game.options.get("sons_idle", true) else "mudo", "Sons do idle (os alertas de raro e santuário têm opção própria)")
	snd.pressed.connect(func():
		Game.options["sons_idle"] = not Game.options.get("sons_idle", true)
		snd.icon = Game.tex(UI % ("som" if Game.options["sons_idle"] else "mudo")))
	bx.add_child(snd)
	var help := _pill("?", 20)
	help.custom_minimum_size = Vector2(20, 18)
	help.tooltip_text = "Como jogar"
	help.pressed.connect(_show_help)
	bx.add_child(help)
	var mp := _icon_btn("mapa", "Mapa: mundos, zonas e o que já foi purificado")
	mp.pressed.connect(func(): _open_panel("res://scenes/mapa_idle.tscn"))
	bx.add_child(mp)
	var dx := _icon_btn("dex", "Digidex: todos os Digialmas que você já encontrou")
	dx.pressed.connect(func(): _open_panel("res://scenes/digidex.tscn"))
	bx.add_child(dx)
	var bag := _icon_btn("bolsa", "Bolsa: itens, amuletos, Árvore de Alma e equipe")
	bag.pressed.connect(_open_bag)
	bx.add_child(bag)
	call_btn = _icon_btn("jogar", "Abrir o jogo completo")
	call_btn.pressed.connect(_open_full)
	bx.add_child(call_btn)
	var close := _icon_btn("fechar", "Fechar")
	close.pressed.connect(func(): Game.quit_game())
	bx.add_child(close)
	# LUTAR fica visível mesmo sem o mouse: um raro está esperando você
	duel_btn = _icon_btn("lutar", "Um Digialma raro quer lutar com você")
	duel_btn.position = Vector2(W * 0.5 - 12, 1)
	duel_btn.custom_minimum_size = Vector2(26, 20)
	duel_btn.add_theme_color_override("font_color", Color("ffd84a"))
	duel_btn.add_theme_font_size_override("font_size", 8)
	duel_btn.pressed.connect(_open_duel)
	add_child(duel_btn)
	var dtw := duel_btn.create_tween().set_loops()
	dtw.tween_property(duel_btn, "scale", Vector2(1.15, 1.15), 0.45)
	dtw.parallel().tween_property(duel_btn, "modulate", Color(1.5, 1.25, 0.7), 0.45)
	dtw.tween_property(duel_btn, "scale", Vector2.ONE, 0.45)
	dtw.parallel().tween_property(duel_btn, "modulate", Color.WHITE, 0.45)
	duel_btn.pivot_offset = Vector2(13, 10)
	_refresh()


func _ico(n: String) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Game.tex(UI % n)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	t.custom_minimum_size = Vector2(14, 14)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _icon_btn(n: String, tip: String) -> Button:
	var b := _pill("", 20)
	b.custom_minimum_size = Vector2(20, 18)
	b.icon = Game.tex(UI % n)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.tooltip_text = tip
	return b


## Símbolo que sobe e some (no lugar de palavras).
func _pop_icon(at: Vector2, n: String) -> void:
	var s := Sprite2D.new()
	s.texture = Game.tex(UI % n)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = at
	s.scale = Vector2(0.4, 0.4)
	add_child(s)
	var tw := create_tween()
	tw.tween_property(s, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(s, "position:y", at.y - 12, 0.7)
	tw.tween_property(s, "modulate:a", 0.0, 0.3)
	tw.tween_callback(s.queue_free)


func _outline(l: Label, col: Color) -> void:
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color("140a22"))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _pill(txt: String, w: float) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(w, 13)
	b.add_theme_font_size_override("font_size", 8)
	b.focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = {"normal": Color(0.1, 0.05, 0.2, 0.75), "hover": Color(0.3, 0.15, 0.5, 0.9), "pressed": Color(0.5, 0.3, 0.8, 0.9)}[st]
		sb.set_corner_radius_all(6)
		sb.border_color = Color(1, 0.85, 0.3, 0.6)
		sb.set_border_width_all(1)
		sb.content_margin_left = 4
		sb.content_margin_right = 4
		b.add_theme_stylebox_override(st, sb)
	return b


func _refresh() -> void:
	if cnt.has("purif"):
		cnt["laco"].text = "%d" % Game.elo_lv
		cnt["laco"].tooltip_text = "Elo Nv %d  (%d/%d XP)" % [Game.elo_lv, Game.elo_xp, Game.elo_need()]
		cnt["purif"].text = str(purified)
		cnt["bits"].text = str(bits_gained)
		cnt["gema"].text = str(items_found)
		cnt["coracao"].text = str(captured)
		cnt["orbe"].text = str(int(Game.inventory.get("orbe_alma", 0)))
	_sync_progress()
	prog.value = progress
	var z := Game.zone_of(my_region)
	prog.tooltip_text = "Zona %d-%d: %d/%d purificações" % [my_region + 1, z, int(Game.zone_kills.get(my_region, 0)), Game.zone_need(z)]
	if zone_l:
		zone_l.text = "%d-%d" % [my_region + 1, z]
		zone_l.tooltip_text = "Mapa %d, zona %d de %d (Nefastos Nv %d-%d)" % [my_region + 1, z, Game.ZONES, Game.zone_levels(my_region, z).x, Game.zone_levels(my_region, z).y]
	if is_instance_valid(sanct_btn):
		sanct_btn.visible = sanct_ready and not dueling and not want_sanct and is_instance_valid(leader_spr)
	if duel_btn:
		duel_btn.visible = not Game.duel_queue.is_empty() and not dueling and not want_duel
		duel_btn.text = str(Game.duel_queue.size()) if Game.duel_queue.size() > 1 else ""


func _log(txt: String, col := Color(1, 1, 1)) -> void:
	log_l.text = txt
	log_l.add_theme_color_override("font_color", col)
	log_l.modulate.a = 0.0
	create_tween().tween_property(log_l, "modulate:a", 1.0, 0.25)


# ---------------------------------------------------------------- cenário e grupo
func _spawn_prop(x: float) -> void:
	var names: Array = reg["props"]["big"] if rng.randf() < 0.55 else reg["props"]["small"]
	var n: String = names[rng.randi() % names.size()]
	var custom := n.begins_with("p:")
	var s := Sprite2D.new()
	s.texture = Game.tex(("res://assets/props/" + n.substr(2) if custom else OBJ + n) + ".png")
	s.centered = false
	s.offset = Vector2(-s.texture.get_width() * 0.5, -s.texture.get_height())
	var big: bool = s.texture.get_height() > 120
	s.scale = Vector2(0.26, 0.26) if big else Vector2(0.4, 0.4)
	# árvores atrás da trilha, detalhes pequenos na beira da grama
	s.position = Vector2(round(x), GROUND - (13 if big else 9) + rng.randf_range(-1, 1))
	s.modulate = (Color.WHITE if custom else reg["prop_tint"] as Color) * (Color(0.85, 0.88, 0.95) if big else Color.WHITE)
	s.material = cmat
	s.set_meta("fx", s.position.x)
	s.set_meta("spd", 0.75 if big else 1.0)
	stage.add_child(s)
	props.append(s)


func _spawn_party() -> void:
	for i in Game.team.size():
		var pet = R.Pet.new()
		var m: Dictionary = Game.team[i]
		pet.sprite_frames = Game.monster_frames(m["id"])
		pet.play("walk" if walking else "idle")
		pet.centered = false
		pet.foot = Game.foot_offset(m["id"])
		pet.offset = pet.foot
		pet.flip_h = true
		pet.phase = i * 1.3
		if m.get("desperto", false):
			pet.set_awakened.call_deferred(true)
		pet.base = 0.45 if Game.FOOT.get(m["id"], 80) > 85 else 0.58
		pet.walking = true
		pet.position = Vector2(240 - i * 38, GROUND)
		stage.add_child(pet)
		pets.append(pet)
		var hb = MiniBar.new()
		hb.col = Color("6fe08a")
		hb.w = 20.0
		hb.h = 2
		add_child(hb)
		hp_bars.append(hb)
	kid = AnimatedSprite2D.new()
	kid.sprite_frames = Game.char_frames(Game.player_char)
	kid.play("right")
	kid.centered = false
	kid.offset = Vector2(-64, -128)
	kid.scale = Vector2(0.3, 0.3)
	kid.position = Vector2(274, GROUND + 1)
	stage.add_child(kid)


func _set_walking(on: bool) -> void:
	walking = on
	kid.play("right" if on else "idle_right")
	for p in pets:
		p.walking = on
		if p.animation != "attack":
			p.play("walk" if on else "idle")


func _process(delta: float) -> void:
	t += delta
	var w := get_window()
	var mp := DisplayServer.mouse_get_position()
	var over := Rect2i(w.position, w.size).has_point(mp)
	alpha = lerpf(alpha, ALPHA_HOVER if (over or rare_waiting or sanct_ready or dueling) else ALPHA_IDLE, minf(1.0, delta * 6.0))
	road.modulate.a = alpha
	for p in props:
		var px: float = (p as Sprite2D).position.x
		(p as Sprite2D).self_modulate.a = alpha * clampf(minf(px, W - px) / FADE, 0.0, 1.0)
	# o painel só aparece com o mouse em cima: parado, é só o cenário
	var hud_a := clampf((alpha - ALPHA_IDLE) / (ALPHA_HOVER - ALPHA_IDLE), 0.0, 1.0)
	if dueling:
		hud_a = 0.0
	for h in hud:
		h.modulate.a = hud_a
		h.visible = hud_a > 0.02
	for i in hp_bars.size():
		if i < pets.size() and i < Game.team.size():
			var hb = hp_bars[i]
			hb.position = pets[i].position + Vector2(-10, -40 if Game.FOOT.get(Game.team[i]["id"], 80) > 85 else -36)
			hb.target = clampf(float(Game.team[i]["hp"]) / Game.max_hp(Game.team[i]), 0.0, 1.0)
			hb.visible = not dueling and (hb.target < 0.999 or hud_a > 0.05)
			# aparência segue a vida: caído = alma-nuvem; vivo = normal
			var fainted: bool = int(Game.team[i]["hp"]) <= 0
			pets[i].set_soul(fainted, Game.MONSTERS[Game.team[i]["id"]]["cor"])
	if not walking:
		if amb2:
			amb2.drift = 0.0
		return
	road.scroll += SPEED * delta
	amb2.drift = SPEED * 0.6
	road.queue_redraw()
	for p in props.duplicate():
		var s := p as Sprite2D
		var x: float = s.get_meta("fx") - SPEED * float(s.get_meta("spd")) * delta
		s.set_meta("fx", x)
		s.position.x = round(x)
		if x < -60:
			props.erase(s)
			s.queue_free()
	next_prop -= SPEED * delta
	while next_prop < W + 60:
		_spawn_prop(next_prop)
		next_prop += rng.randf_range(40, 110)


# ---------------------------------------------------------------- ciclo idle
func _loop() -> void:
	while is_inside_tree():
		_set_walking(not sanct_ready or approaching)
		var faro: float = [1.0, 0.75, 0.55][Game.elo_level("faro")]
		var wait_s := rng.randf_range(2.5, 5.0) * faro
		var waited := 0.0
		while waited < wait_s and not want_duel and not want_sanct and (pending_evo.is_empty() or hold_evo or is_instance_valid(panel_win)) and is_inside_tree():
			await get_tree().process_frame
			waited += get_process_delta_time()
		if not is_inside_tree():
			return
		if not pending_evo.is_empty() and not hold_evo and not is_instance_valid(panel_win):
			await _do_evolutions()
			continue
		if want_sanct and is_instance_valid(leader_spr) and not approaching:
			want_sanct = false
			await _sanctuary_challenge()
			continue
		if want_duel:
			want_duel = false
			if not Game.duel_queue.is_empty():
				await _strip_duel(Game.duel_queue.pop_front())
			continue
		if sanct_ready:
			continue
		var z := Game.zone_of(my_region)
		var raro := rng.randf() < 0.06
		var pool: Array = Game.ZONE_RAROS[my_region] if raro else Game.zone_pool(my_region, z)
		var sp: int = pool[rng.randi() % pool.size()]
		var lv := Game.zone_levels(my_region, z)
		var rr := Game.roll_rarity(1 if raro else 0)
		if rng.randf() < z * 0.015:
			rr = mini(rr + 1, 4)  # zonas altas: Nefastos mais raros
		var e := Game.new_monster(sp, rng.randi_range(lv.x, lv.y), rr)
		e["nefasto"] = true
		e["raro"] = raro
		# Épico/Lendário: pede para ser jogado (batalha completa)
		if e["rar"] >= 3 and (raro or rng.randf() < 0.4) and Game.duel_queue.size() < 3:
			await _duel_call(e)
		else:
			await _encounter(e, raro or e["rar"] >= 3)


func _encounter(e: Dictionary, raro: bool) -> void:
	_set_walking(false)
	var m := AnimatedSprite2D.new()
	m.sprite_frames = Game.monster_frames(e["id"])
	m.play("idle")
	m.centered = false
	m.offset = Game.foot_offset(e["id"])
	m.material = Game.sprite_mat()
	var mat := m.material as ShaderMaterial
	mat.set_shader_parameter("nefasto", 1.0)
	var bs := 0.45 if Game.FOOT.get(e["id"], 80) > 85 else 0.58
	m.scale = Vector2(bs, bs)
	m.position = Vector2(W + 40, GROUND)
	stage.add_child(m)
	await create_tween().tween_property(m, "position:x", 340.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).finished
	var rar: int = e.get("rar", 0)
	var aura: Glow = null
	if rar >= 1:
		aura = Glow.new()
		aura.col = Game.rar_color(rar)
		aura.position = m.position + Vector2(0, -16)
		aura.scale = Vector2(0.6, 0.6) if rar < 2 else Vector2.ONE
		stage.add_child(aura)
		m.tree_exiting.connect(aura.queue_free)
	if raro and Game.can_capture(e):
		await _rare_call(e, m, mat)
		return
	if raro:
		# Elo fraco demais: não dá para guardar, só purificar
		_pop_icon(kid.position + Vector2(0, -44), "cadeado")
	_log("Um %s Nefasto apareceu!" % Game.mon_title(e), Game.rar_color(rar) if rar > 0 else Color("d8b8ff"))
	# batalha automática de verdade: atributos, tipos e vida
	if not await _fight(e, m, mat):
		await _defeat(m)
		return
	var mpos := m.position
	_elo_xp(2 + rar)
	Game.sfx("purificar%d" % rng.randi_range(0, 2), -4.0, 1.2)
	await _purify_fx(m, mat)
	var xp: int = 6 + e["lv"] * 2
	var b := int(rng.randi_range(8, 20) * [1.0, 1.5, 2.0][Game.elo_level("bolsa")] * (1.2 if Game.has_skill(Game.team[0], "v3") else 1.0) * (1.0 + Game.gear_bonus(Game.team[0], "bits")))
	purified += 1
	xp_gained += xp
	bits_gained += b
	Game.bits += b
	Game.zone_kills[my_region] = int(Game.zone_kills.get(my_region, 0)) + 1
	_heal_party(0.12)
	_give_xp(xp)
	_log("%s foi purificado! +%d XP  +%d bits" % [Game.mon_name(e), xp, b], Color("aef7c8"))
	# chance de amuleto (raridade do Nefasto ajuda)
	if rng.randf() < 0.12 + rar * 0.06:
		var g := Game.random_gear(1 if rar >= 2 else 0)
		items_found += 1
		await get_tree().create_timer(1.0).timeout
		_drop_fx(mpos + Vector2(0, -20), g)
		Game.sfx("item")
		_log("Achou um amuleto: %s! (%s)" % [Game.gear_name(g), Game.gear_desc(g)], Game.rar_color(g["rar"]))
	# Cristal de Ressonância (para fusões)
	if rng.randf() < 0.05 + rar * 0.03:
		Game.cristais += 1
		_pop_icon(mpos + Vector2(0, -30), "res")
		Game.sfx("cristal")
	# Orbe de Alma (o único jeito de reviver quem virou alma)
	if rng.randf() < 0.025 + rar * 0.015:
		Game.inventory["orbe_alma"] = int(Game.inventory.get("orbe_alma", 0)) + 1
		_pop_icon(mpos + Vector2(6, -34), "orbe")
		Game.sfx("item")
		_log("Achou um Orbe de Alma!", Color("9effe8"))
	# Cristal do Despertar: só nos mapas já purificados, zonas altas
	if Game.all_purified and Game.zone_of(my_region) >= 8 and rng.randf() < 0.012:
		Game.inventory["cristal_despertar"] = int(Game.inventory.get("cristal_despertar", 0)) + 1
		_pop_icon(mpos + Vector2(-6, -34), "gema")
		Game.sfx("vitoria", -6.0)
		_log("Um CRISTAL DO DESPERTAR!", Color("ffd25a"))
		for mm in Game.team:
			_check_evo(mm)
	var auto_ch: float = [0.0, 0.15, 0.3][Game.elo_level("auto")]
	if rng.randf() < auto_ch:
		e["hp"] = Game.max_hp(e)
		var where := Game.add_partner(e)
		captured += 1
		await get_tree().create_timer(1.2).timeout
		_log("Purificação Automática: %s quis ficar com você! (%s)" % [Game.mon_name(e), where], Color("ffd84a"))
		_pop_icon(kid.position + Vector2(0, -44), "coracao")
		Game.sfx("captura")
	_refresh()
	await _check_zone()


# ---------------------------------------------------------------- zonas
func _sync_progress() -> void:
	var z := Game.zone_of(my_region)
	progress = clampf(float(Game.zone_kills.get(my_region, 0)) / Game.zone_need(z) * 100.0, 0.0, 100.0)


## Terminou a zona: avança (se o automático estiver ligado) ou, na zona 10,
## o Santuário aparece.
func _check_zone() -> void:
	var z := Game.zone_of(my_region)
	if int(Game.zone_kills.get(my_region, 0)) < Game.zone_need(z):
		return
	if z >= Game.ZONES:
		if Game.badges > my_region:
			# mapa já purificado: a zona 10 vira farm (com um baú de bits)
			Game.zone_kills[my_region] = 0
			var bonus := 40 * (my_region + 1)
			Game.bits += bonus
			bits_gained += bonus
			_pop_icon(kid.position + Vector2(0, -44), "bits")
			_pop_text(kid.position + Vector2(8, -50), str(bonus), Color("ffd84a"))
			Game.sfx("item")
			_refresh()
		elif not sanct_ready:
			await _sanctuary_ready()
		return
	Game.zone_max[my_region] = maxi(int(Game.zone_max.get(my_region, 1)), z + 1)
	if Game.zone_auto:
		Game.zone[my_region] = z + 1
		Game.zone_kills[my_region] = 0
		_heal_party(1.0)
		_sparkle(kid.position + Vector2(0, -30))
		_pop_text(kid.position + Vector2(-6, -50), "%d-%d" % [my_region + 1, z + 1], Color("ffd84a"))
		Game.sfx("zona")
	else:
		Game.zone_kills[my_region] = 0  # farmando: repete a zona
	_refresh()


## Setas: anda pelas zonas liberadas, inclusive de mapas já purificados.
func _step_zone(d: int) -> void:
	if dueling or sanct_ready and d > 0:
		return
	var r := my_region
	var z := Game.zone_of(r) + d
	if z < 1:
		if r == 0:
			return
		r -= 1
		z = int(Game.zone_max.get(r, Game.ZONES))
	elif z > int(Game.zone_max.get(r, 1)):
		if r + 1 <= mini(Game.badges, Game.REGIONS.size() - 1):
			r += 1
			z = 1
		else:
			return
	Game.zone[r] = z
	Game.zone_kills[r] = 0
	if r != my_region:
		Game.region = r
		Game.change_scene("res://scenes/idle.tscn")
		return
	_refresh()


## Viagem pelo Mapa do Mundo: vai direto para uma zona já liberada.
func travel_to(r: int, z: int) -> void:
	if dueling:
		return
	z = clampi(z, 1, maxi(1, int(Game.zone_max.get(r, 1))) if Game.region_corrupt(r) else Game.ZONES)
	Game.zone[r] = z
	Game.zone_kills[r] = 0
	if r != my_region:
		Game.region = r
		Game.change_scene("res://scenes/idle.tscn")
		return
	_sparkle(kid.position + Vector2(0, -30))
	_pop_text(kid.position + Vector2(-6, -50), "%d-%d" % [r + 1, z], Color("ffd84a"))
	_refresh()


func _lead_idx() -> int:
	for i in mini(Game.team.size(), pets.size()):
		if int(Game.team[i]["hp"]) > 0:
			return i
	return -1


func _heal_party(frac: float, revive := false) -> void:
	for i in Game.team.size():
		var m: Dictionary = Game.team[i]
		if int(m["hp"]) <= 0 and not revive:
			continue
		m["hp"] = mini(Game.max_hp(m), int(m["hp"]) + int(Game.max_hp(m) * frac))
		if i < pets.size():
			pets[i].set_soul(false)
			pets[i].modulate = Color.WHITE


## Melhor golpe básico contra o Nefasto (tipo, STAB e poder).
func _best_move(m: Dictionary, e: Dictionary) -> String:
	var best := ""
	var score := -1.0
	var et: String = Game.MONSTERS[e["id"]]["tipo"]
	for mk in Game.moves_of(m):
		var mv: Dictionary = Game.MOVES[mk]
		if mv["cd"] > 0:
			continue
		var sc: float = mv["poder"] * Game.effectiveness(mv["tipo"], et) * (1.2 if mv["tipo"] == Game.MONSTERS[m["id"]]["tipo"] else 1.0)
		if sc > score:
			score = sc
			best = mk
	return best if best != "" else Game.moves_of(m)[0]


## Luta automática. Retorna false se o grupo inteiro cair.
func _fight(e: Dictionary, m: AnimatedSprite2D, mat: ShaderMaterial) -> bool:
	e["hp"] = Game.max_hp(e)
	var ebar = MiniBar.new()
	ebar.col = Color("ff5a6a")
	ebar.w = 28.0
	ebar.position = m.position + Vector2(-14, -44)
	add_child(ebar)
	var et: String = Game.MONSTERS[e["id"]]["tipo"]
	while is_inside_tree():
		var li := _lead_idx()
		if li < 0:
			ebar.queue_free()
			return false
		var lm: Dictionary = Game.team[li]
		var pet = pets[li]
		# ataque do parceiro
		var mk := _best_move(lm, e)
		var mv: Dictionary = Game.MOVES[mk]
		var crit := rng.randf() < 0.12
		var dmg := int(Game.calc_damage(lm, e, mv, crit) * (1.0 + Game.skill_dmg(lm)))
		var home: Vector2 = pet.position
		pet.play("attack")
		pet.animation_finished.connect(func(): pet.play("walk" if walking else "idle"), CONNECT_ONE_SHOT)
		await create_tween().tween_property(pet, "position:x", m.position.x - 30, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).finished
		mat.set_shader_parameter("flash", 1.0)
		var eff := Game.effectiveness(mv["tipo"], et)
		_pop_text(m.position + Vector2(0, -40), str(dmg), Color("ffd84a") if eff > 1.0 or crit else (Color(0.7, 0.7, 0.75) if eff < 1.0 else Color.WHITE))
		if eff > 1.0:
			_pop_icon(m.position + Vector2(10, -30), "fraco")
		_burst(m.position + Vector2(0, -24), Game.TYPE_COLORS.get(mv["tipo"], Color("fff3a8")), 8)
		create_tween().tween_property(pet, "position", home, 0.22)
		e["hp"] = maxi(0, int(e["hp"]) - dmg)
		ebar.target = float(e["hp"]) / Game.max_hp(e)
		await get_tree().create_timer(0.12).timeout
		mat.set_shader_parameter("flash", 0.0)
		if e["hp"] <= 0:
			await get_tree().create_timer(0.25).timeout
			ebar.queue_free()
			return true
		await get_tree().create_timer(0.35).timeout
		# o Nefasto revida
		var emoves: Array = []
		for k in Game.moves_of(e):
			if not Game.MOVES[k].get("supremo", false):
				emoves.append(k)
		var emv: Dictionary = Game.MOVES[emoves[rng.randi() % emoves.size()]]
		var back := m.position
		await create_tween().tween_property(m, "position:x", pet.position.x + 26, 0.14).finished
		var dodge: bool = Game.has_skill(lm, "g5") or rng.randf() < 0.18 + Game.gear_bonus(lm, "janela")
		if dodge:
			_pop_icon(pet.position + Vector2(0, -34), "desvio")
		else:
			var d2 := maxi(1, int(Game.calc_damage(e, lm, emv, false) * IDLE_TAKEN * maxf(0.4, 1.0 - Game.skill_def(lm))))
			lm["hp"] = maxi(0, int(lm["hp"]) - d2)
			_pop_text(pet.position + Vector2(0, -34), str(d2), Color("ff9a9a"))
			pet.modulate = Color(1.6, 0.6, 0.6)
			get_tree().create_timer(0.12).timeout.connect(func(): if is_instance_valid(pet) and not pet.soul: pet.modulate = Color.WHITE)
			if lm["hp"] <= 0:
				_burst(pet.position + Vector2(0, -20), Color(0.6, 0.6, 0.7), 10)
		create_tween().tween_property(m, "position", back, 0.22)
		await _support_heal()
		await get_tree().create_timer(0.4).timeout
	return false


## Suportes vivos cuidam do time: às vezes curam quem está mais ferido.
func _support_heal() -> void:
	for si in mini(Game.team.size(), pets.size()):
		var h: Dictionary = Game.team[si]
		if int(h["hp"]) <= 0 or not Game.is_support(h) or rng.randf() > 0.4:
			continue
		var best := -1
		var worst := 0.95
		for ti in mini(Game.team.size(), pets.size()):
			var t: Dictionary = Game.team[ti]
			if int(t["hp"]) <= 0:
				continue
			var f := float(t["hp"]) / Game.max_hp(t)
			if f < worst:
				worst = f
				best = ti
		if best < 0:
			return
		var tm: Dictionary = Game.team[best]
		var amt := Game.heal_amount(h, tm)
		tm["hp"] = mini(Game.max_hp(tm), int(tm["hp"]) + amt)
		_pop_icon(pets[si].position + Vector2(0, -38), "cura")
		_pop_text(pets[best].position + Vector2(0, -34), "+%d" % amt, Color("6fe08a"))
		_burst(pets[best].position + Vector2(0, -20), Color("6fe08a"), 8)
		await get_tree().create_timer(0.2).timeout


## O grupo inteiro caiu: o Nefasto vence, todos voltam uma zona e se recuperam.
func _defeat(m: AnimatedSprite2D) -> void:
	Game.sfx("derrota")
	_pop_icon(kid.position + Vector2(0, -44), "fugir")
	_burst(kid.position + Vector2(0, -20), Color("b050ff"), 16)
	await create_tween().tween_property(m, "position:x", W + 60, 0.6).finished
	m.queue_free()
	var z := Game.zone_of(my_region)
	Game.zone[my_region] = maxi(1, z - 1)
	Game.zone_kills[my_region] = 0
	# o Elo puxa as almas de volta só quando o grupo INTEIRO cai (fracos)
	for i in Game.team.size():
		_revive(i, 0.3)
	print("[idle] derrota: zona %d -> %d" % [z, Game.zone_of(my_region)])
	_refresh()


func _alert(name: String) -> void:
	if not Game.options.get("alerta_som", true):
		return
	sfx.stream = load("res://assets/sfx/%s.wav" % name)
	sfx.volume_db = linear_to_db(maxf(0.01, Game.options.get("efeitos", 90) / 100.0)) - 8.0
	sfx.play()


## Abertura de mapa novo: a insígnia do mapa (apagada enquanto corrompido)
## surge sobre o grupo, com o número da zona.
func _map_intro() -> void:
	await get_tree().create_timer(1.2).timeout
	var b := Sprite2D.new()
	b.texture = Game.tex("res://assets/badges/%s.png" % reg["lider"]["badge"])
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.position = Vector2(W * 0.5, 40)
	b.scale = Vector2(0.05, 0.05)
	b.modulate = Color(0.55, 0.4, 0.75, 0.0) if cmat else Color(1, 1, 1, 0.0)
	add_child(b)
	var tw := create_tween()
	tw.tween_property(b, "scale", Vector2(0.45, 0.45), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(b, "modulate:a", 1.0, 0.4)
	await tw.finished
	_pop_text(Vector2(W * 0.5 - 8, 30), "%d-%d" % [my_region + 1, Game.zone_of(my_region)], Color("ffd84a"))
	Game.sfx("zona")
	await get_tree().create_timer(1.6).timeout
	await create_tween().tween_property(b, "modulate:a", 0.0, 0.5).finished
	b.queue_free()


## Os 3 mapas purificados: as três insígnias giram sobre o grupo.
## O idle continua (farm infinito) até o meio do jogo chegar num update.
func _finale() -> void:
	Game.sfx("vitoria")
	var bs: Array = []
	for i in Game.REGIONS.size():
		var b := Sprite2D.new()
		b.texture = Game.tex("res://assets/badges/%s.png" % Game.REGIONS[i]["lider"]["badge"])
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		b.scale = Vector2(0.35, 0.35)
		add_child(b)
		bs.append(b)
	var t0 := 0.0
	while t0 < 4.0 and is_inside_tree():
		t0 += get_process_delta_time()
		for i in bs.size():
			var a := t0 * 2.0 + i * TAU / bs.size()
			bs[i].position = kid.position + Vector2(cos(a) * 34.0, -40.0 + sin(a) * 10.0)
		if int(t0 * 10) % 7 == 0:
			_burst(kid.position + Vector2(randf_range(-60, 60), -30), Color("ffd84a"), 4)
		await get_tree().process_frame
	for b in bs:
		b.queue_free()


## Épico/Lendário: o Digialma desafia e fica esperando numa fila (até 3).
func _duel_call(e: Dictionary) -> void:
	_set_walking(false)
	var m := AnimatedSprite2D.new()
	m.sprite_frames = Game.monster_frames(e["id"])
	m.play("idle")
	m.centered = false
	m.offset = Game.foot_offset(e["id"])
	m.material = Game.sprite_mat()
	(m.material as ShaderMaterial).set_shader_parameter("nefasto", 1.0)
	var bs := 0.45 if Game.FOOT.get(e["id"], 80) > 85 else 0.58
	m.scale = Vector2(bs, bs)
	m.position = Vector2(W + 40, GROUND)
	stage.add_child(m)
	var aura := Glow.new()
	aura.col = Game.rar_color(e["rar"])
	stage.add_child(aura)
	var tw := create_tween()
	tw.tween_property(m, "position:x", 340.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	while tw.is_running():
		aura.position = m.position + Vector2(0, -18)
		await get_tree().process_frame
	aura.position = m.position + Vector2(0, -18)
	_sparkle(m.position + Vector2(0, -26))
	_pop_text(m.position + Vector2(0, -44), "!", Game.rar_color(e["rar"]))
	Game.duel_queue.append(e)
	DisplayServer.window_request_attention()
	_alert("alerta_raro")
	_log("UM %s %s! Ele quer lutar com você: clique em LUTAR!" % [Game.mon_name(e).to_upper(), Game.RARITY[e["rar"]]["nome"].to_upper()], Game.rar_color(e["rar"]))
	_refresh()
	await get_tree().create_timer(2.6).timeout
	# ele se afasta e espera (a fila guarda o desafio)
	await create_tween().tween_property(m, "position:x", W + 60, 0.7).finished
	aura.queue_free()
	m.queue_free()


func _drop_fx(at: Vector2, g: Dictionary) -> void:
	var ic := Sprite2D.new()
	ic.texture = Game.tex("res://assets/gear/%s.png" % g["base"])
	ic.scale = Vector2(0.5, 0.5)
	ic.position = at
	add_child(ic)
	var gl := Glow.new()
	gl.col = Game.rar_color(g["rar"])
	gl.scale = Vector2(0.45, 0.45)
	ic.add_child(gl)
	var tw := create_tween()
	tw.tween_property(ic, "position:y", at.y - 18, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ic, "position:y", at.y - 10, 0.25).set_trans(Tween.TRANS_BOUNCE)
	tw.tween_interval(0.6)
	tw.tween_property(ic, "position", Vector2(W - FADE * 0.5 - 100, 8), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(ic, "modulate:a", 0.0, 0.5)
	tw.tween_callback(ic.queue_free)


## Momento ativo: o Elo chama. Se o jogador clicar a tempo, entra num mini anel de purificação.
func _rare_call(e: Dictionary, m: AnimatedSprite2D, mat: ShaderMaterial) -> void:
	_sparkle(m.position + Vector2(0, -26))
	_log("O ELO ESTÁ CHAMANDO! Um %s RARO apareceu. Clique nele!" % Game.mon_name(e), Color("ffd84a"))
	var flash := Glow.new()
	flash.position = m.position + Vector2(0, -18)
	flash.modulate.a = 0.0
	stage.add_child(flash)
	var pulse := flash.create_tween().set_loops()
	pulse.tween_property(flash, "modulate:a", 0.9, 0.35)
	pulse.tween_property(flash, "modulate:a", 0.2, 0.35)
	# tenta chamar atenção do sistema (pisca na barra de tarefas)
	DisplayServer.window_request_attention()
	_alert("alerta_raro")
	rare_waiting = true
	var hit := Button.new()
	hit.flat = true
	hit.position = m.position + Vector2(-34, -58)
	hit.size = Vector2(68, 64)
	add_child(hit)
	rare_answer = ""
	hit.pressed.connect(func(): rare_answer = "clicou")
	var waited := 0.0
	while rare_answer == "" and waited < 9.0 and is_inside_tree():
		await get_tree().process_frame
		waited += get_process_delta_time()
	pulse.kill()
	flash.queue_free()
	hit.queue_free()
	rare_waiting = false
	if rare_answer == "" and rng.randf() < Game.auto_rare_chance():
		await _purify_fx(m, mat)
		captured += 1
		e["hp"] = Game.max_hp(e)
		_log("Captura automática: o Elo purificou %s sozinho! (%s)" % [Game.mon_name(e), Game.add_partner(e)], Color("ffd84a"))
		_pop_icon(kid.position + Vector2(0, -44), "coracao")
		Game.sfx("captura")
		_refresh()
		return
	if rare_answer == "":
		_log("%s fugiu... O Elo vai avisar no próximo." % Game.mon_name(e), Color("ff9a9a"))
		await create_tween().tween_property(m, "position:x", W + 60, 0.6).finished
		m.queue_free()
		return
	# mini anel: aperte quando encostar
	_log("Clique quando o anel encostar no %s!" % Game.mon_name(e), Color("ffd84a"))
	var ring := MiniRing.new()
	ring.position = m.position + Vector2(0, -26)
	add_child(ring)
	var hit2 := Button.new()
	hit2.flat = true
	hit2.size = Vector2(W, H)
	add_child(hit2)
	var pressed := [false]
	hit2.pressed.connect(func(): pressed[0] = true)
	var start := Time.get_ticks_msec()
	var ok := false
	while Time.get_ticks_msec() - start < 1400 and is_inside_tree():
		ring.k = (Time.get_ticks_msec() - start) / 1100.0
		if pressed[0]:
			ok = absf(ring.k - 1.0) < 0.16
			break
		await get_tree().process_frame
	ring.queue_free()
	hit2.queue_free()
	if ok:
		await _purify_fx(m, mat)
		captured += 1
		e["hp"] = Game.max_hp(e)
		var where := Game.add_partner(e)
		_elo_xp(15)
		_log("PERFEITO! %s foi purificado e quis ficar com você! (%s)" % [Game.mon_name(e), where], Color("ffd84a"))
		_pop_icon(kid.position + Vector2(0, -44), "coracao")
		Game.sfx("captura")
		_sparkle(m.position + Vector2(0, -26))
		_refresh()
	else:
		_log("Quase! %s escapou." % Game.mon_name(e), Color("ff9a9a"))
		await create_tween().tween_property(m, "position:x", W + 60, 0.5).finished
		m.queue_free()


## O caminho acabou: o Santuário surge na faixa, o grupo chega até a porta
## e o desafio contra o líder acontece aqui mesmo (mecânica do duelo).
func _sanctuary_ready() -> void:
	if sanct_ready:
		return
	sanct_ready = true
	DisplayServer.window_request_attention()
	_alert("alerta_santuario")
	var ld: Dictionary = reg["lider"]
	gym = Sprite2D.new()
	gym.texture = Game.tex(OBJ + reg["arena"] + ".png")
	gym.centered = false
	gym.offset = Vector2(-224, -440)
	gym.scale = Vector2(0.17, 0.17)
	gym.position = Vector2(W + 60, GROUND + 2)
	gym.material = cmat
	gym.z_index = -1
	stage.add_child(gym)
	approaching = true
	_set_walking(true)
	while gym.position.x > 500 and is_inside_tree():
		gym.position.x -= SPEED * get_process_delta_time()
		await get_tree().process_frame
	approaching = false
	_set_walking(false)
	# o líder espera na porta
	leader_spr = AnimatedSprite2D.new()
	leader_spr.sprite_frames = Game.char_frames(ld["sprite"])
	leader_spr.play("idle_left")
	leader_spr.centered = false
	leader_spr.offset = Vector2(-64, -128)
	leader_spr.scale = Vector2(0.3, 0.3)
	leader_spr.position = Vector2(gym.position.x - 44, GROUND + 1)
	leader_spr.modulate.a = 0.0
	stage.add_child(leader_spr)
	create_tween().tween_property(leader_spr, "modulate:a", 1.0, 0.4)
	_pop_icon(gym.position + Vector2(0, -70), "santuario")
	sanct_btn = _icon_btn("santuario", "Desafiar %s no %s (equipe Nv %d+)" % [ld["nome"], ld["ginasio"], _rec_lv() ])
	sanct_btn.position = Vector2(W * 0.5 - 12, 1)
	sanct_btn.custom_minimum_size = Vector2(26, 20)
	sanct_btn.pivot_offset = Vector2(13, 10)
	sanct_btn.pressed.connect(func():
		if not dueling:
			want_sanct = true
			sanct_btn.visible = false)
	add_child(sanct_btn)
	var tw := sanct_btn.create_tween().set_loops()
	tw.tween_property(sanct_btn, "scale", Vector2(1.15, 1.15), 0.45)
	tw.parallel().tween_property(sanct_btn, "modulate", Color(1.5, 1.25, 0.7), 0.45)
	tw.tween_property(sanct_btn, "scale", Vector2.ONE, 0.45)
	tw.parallel().tween_property(sanct_btn, "modulate", Color.WHITE, 0.45)
	_refresh()


func _rec_lv() -> int:
	var top := 0
	for pr in reg["lider"]["time"]:
		top = maxi(top, pr[1])
	return Game.zone_levels(my_region, Game.ZONES).y + 1


func _sanctuary_challenge() -> void:
	var ld: Dictionary = reg["lider"]
	dueling = true
	_refresh()
	var saved := {}
	for p in pets:
		saved[p] = p.position
	saved[kid] = kid.position
	var lead: Dictionary = Game.team[maxi(0, _lead_idx())]
	lead["hp"] = Game.max_hp(lead)
	var energy := 1
	var sync := 0.0
	var won := true
	_pop_text(leader_spr.position + Vector2(-2, -40), "!", Color("ffd84a"))
	await get_tree().create_timer(0.5).timeout
	var boss_off := [1, 2, 4]
	for bi in ld["time"].size():
		var pair: Array = ld["time"][bi]
		var blv: int = Game.zone_levels(my_region, Game.ZONES).y - 1 + boss_off[mini(bi, 2)]
		var e := Game.new_monster(pair[0], blv, pair[2] if pair.size() > 2 else 0)
		e["nefasto"] = Game.region_corrupt(Game.region)
		var d = load("res://scripts/strip_duel.gd").new()
		d.host = self
		d.e = e
		d.boss = true
		d.keep_hp = true
		d.restore = false
		d.enter_x = gym.position.x - 8.0
		d.energy = energy
		d.sync = sync
		d.auto = Game.debug_species == -9
		add_child(d)
		var r: String = await d.run()
		energy = d.energy
		sync = d.sync
		_elo_xp(d.elo_gain)
		d.queue_free()
		if r != "win":
			won = false
			break
		_give_xp(10 + e["lv"] * 3)
		# fôlego entre um e outro
		lead["hp"] = mini(Game.max_hp(lead), lead["hp"] + int(Game.max_hp(lead) * 0.35))
		await get_tree().create_timer(0.4).timeout
	for p in saved:
		if is_instance_valid(p):
			var t := create_tween()
			t.tween_property(p, "position", saved[p], 0.4)
			t.parallel().tween_property(p, "modulate:a", 1.0, 0.4)
	lead["hp"] = Game.max_hp(lead)
	await get_tree().create_timer(0.5).timeout
	print("[santuario] venceu=", won)
	if won:
		await _sanctuary_win()
	else:
		# o líder ri e espera: precisa upar
		_pop_text(leader_spr.position + Vector2(-6, -40), "?", Color("ff9a9a"))
		_pop_icon(kid.position + Vector2(0, -44), "nivel")
		sanct_btn.visible = true
	dueling = false
	_refresh()


func _sanctuary_win() -> void:
	Game.sfx("vitoria")
	var ld: Dictionary = reg["lider"]
	var was := Game.region
	Game.badges = maxi(Game.badges, was + 1)
	Game.region_unlocked = mini(3, was + 2)
	Game.elo_charges += 2
	_elo_xp(50)
	Game.inventory["orbe_alma"] = int(Game.inventory.get("orbe_alma", 0)) + 2
	if was == 2:
		Game.inventory["cristal_despertar"] = int(Game.inventory.get("cristal_despertar", 0)) + 1
	# santuário purificado devolve as almas
	_heal_party(1.0, true)
	# insígnia sobe brilhando sobre o personagem
	var badge := Sprite2D.new()
	badge.texture = Game.tex("res://assets/badges/%s.png" % ld["badge"])
	badge.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	badge.position = kid.position + Vector2(0, -20)
	badge.scale = Vector2(0.1, 0.1)
	add_child(badge)
	var gl := Glow.new()
	gl.col = Color("ffd84a")
	badge.add_child(gl)
	var tw := create_tween()
	tw.tween_property(badge, "position:y", kid.position.y - 52, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(badge, "scale", Vector2(0.5, 0.5), 0.6).set_trans(Tween.TRANS_BACK)
	await tw.finished
	_sparkle(badge.position)
	# a região é purificada: a cor volta
	if cmat:
		_burst(Vector2(W * 0.5, GROUND - 20), Color("fff3a8"), 30)
		for i in 5:
			_burst(Vector2(FADE + i * (W - FADE * 2) / 4.0, GROUND - 10), Color("fff3a8"), 10)
		road.material = null
		gym.material = null
		amb2.corrupted = false
		for p in props:
			(p as CanvasItem).material = null
		cmat = null
	_pop_icon(leader_spr.position + Vector2(0, -36), "coracao")
	await get_tree().create_timer(2.4).timeout
	badge.queue_free()
	# próximo mapa (o idle segue para lá). O mapa purificado continua
	# disponível para farmar (setas de zona).
	Game.zone_kills[was] = 0
	if was < Game.REGIONS.size() - 1:
		Game.region = was + 1
		Game.zone[was + 1] = 1
		Game.zone_kills[was + 1] = 0
		Game.zone_max[was + 1] = maxi(1, int(Game.zone_max.get(was + 1, 1)))
		Game.change_scene("res://scenes/idle.tscn")
	else:
		Game.all_purified = true
		await _finale()
		sanct_ready = false
		gym.queue_free()
		leader_spr.queue_free()
		sanct_btn.queue_free()


## Evolução no idle: abre uma janelinha (o painel) com a cena da evolução.
func _check_evo(m: Dictionary) -> void:
	var evo: Array = Game.MONSTERS[m["id"]]["evo"]
	if ((evo.size() > 0 and m["lv"] >= evo[1]) or Game.can_awaken(m)) and not pending_evo.has(m):
		pending_evo.append(m)


func _do_evolutions() -> void:
	_set_walking(false)
	Game.sfx("evolucao")
	while not pending_evo.is_empty():
		var m: Dictionary = pending_evo.pop_front()
		var i := Game.team.find(m)
		if i >= 0 and i < pets.size():
			_sparkle(pets[i].position + Vector2(0, -24))
			_burst(pets[i].position + Vector2(0, -20), Game.MONSTERS[m["id"]]["cor"], 16)
		await get_tree().create_timer(0.5).timeout
		if Game.MONSTERS[m["id"]]["evo"].is_empty():
			await _do_awaken(m, i)
			continue
		# janelinha pequena, sem roubar o foco (aparece sem você pedir)
		var w := await _make_panel(Vector2i(320, 180), Vector2i(288, 162))
		# janela transparente: nunca aparece o cinza padrão antes do 1º quadro
		w.transparent_bg = true
		w.transparent = true
		w.unfocusable = true
		_dock_panel()
		var ev = preload("res://scripts/evolution.gd").new()
		ev.compact = true
		w.add_child(ev)
		await ev.run(m)
		if is_instance_valid(w):
			w.queue_free()
		# evoluir vale muito: +2 Pontos de Alma
		m["pa"] = int(m.get("pa", 0)) + 2
		if i >= 0 and i < pets.size():
			var pet = pets[i]
			pet.sprite_frames = Game.monster_frames(m["id"])
			pet.play("walk" if walking else "idle")
			pet.foot = Game.foot_offset(m["id"])
			pet.offset = pet.foot
			pet.base = 0.45 if Game.FOOT.get(m["id"], 80) > 85 else 0.58
			_burst(pet.position + Vector2(0, -20), Color("ffd84a"), 20)
			_pop_icon(pet.position + Vector2(0, -40), "nivel")
		_check_evo(m)
	_refresh()


## DESPERTAR: momento raro e grandioso, então abre o painel grande.
func _do_awaken(m: Dictionary, i: int) -> void:
	if not Game.can_awaken(m):
		return
	var w := await _make_panel()
	w.transparent_bg = true
	w.transparent = true
	var ev = preload("res://scripts/evolution.gd").new()
	w.add_child(ev)
	await ev.run_awaken(m)
	if is_instance_valid(w):
		w.queue_free()
	if i >= 0 and i < pets.size():
		pets[i].set_awakened(true)
		_burst(pets[i].position + Vector2(0, -20), Color("ffd25a"), 30)
		_sparkle(pets[i].position + Vector2(0, -30))
	_log("%s DESPERTOU!" % Game.MONSTERS[m["id"]]["nome"], Color("ffd25a"))


func _give_xp(xp: int) -> void:
	for i in Game.team.size():
		var m: Dictionary = Game.team[i]
		var lv0: int = m["lv"]
		m["xp"] += int(xp * (1.2 if Game.has_skill(m, "v1") else 1.0) * (1.0 + Game.gear_bonus(m, "xp")))
		while m["xp"] >= Game.xp_need(m):
			m["xp"] -= Game.xp_need(m)
			Game.level_up(m)
			_log("%s subiu para o Nv %d! +1 Ponto de Alma" % [Game.mon_name(m), m["lv"]], Color("8fd4ff"))
		if m["lv"] > lv0 and i < pets.size():
			_pop_icon(pets[i].position + Vector2(0, -36), "nivel")
			Game.sfx("nivel", 0.0, 1.0)
		_check_evo(m)


# ---------------------------------------------------------------- efeitos
func _purify_fx(m: AnimatedSprite2D, mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("flash_color", Color("fff3a8"))
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(v): mat.set_shader_parameter("nefasto", 1.0 - v), 0.0, 1.0, 0.5)
	tw.tween_method(func(v): mat.set_shader_parameter("flash", v), 0.0, 1.0, 0.5)
	await tw.finished
	_burst(m.position + Vector2(0, -24), Color("b8ffd8"), 22)
	await create_tween().tween_property(m, "modulate:a", 0.0, 0.3).finished
	m.queue_free()


func _pop_text(at: Vector2, txt: String, col: Color) -> void:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color("1a0f2a"))
	l.add_theme_constant_override("outline_size", 4)
	l.position = at
	add_child(l)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", at.y - 14, 0.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tw.chain().tween_callback(l.queue_free)


func _burst(at: Vector2, col: Color, n: int) -> void:
	var p := CPUParticles2D.new()
	p.position = at
	p.amount = n
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.5
	p.spread = 180.0
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 70.0
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = col
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func _sparkle(at: Vector2) -> void:
	_burst(at, Color("ffd84a"), 20)


class MiniRing extends Node2D:
	var k := 0.0

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var r := lerpf(44.0, 12.0, clampf(k, 0.0, 1.2))
		var near := absf(k - 1.0) < 0.16
		draw_arc(Vector2.ZERO, 12.0, 0, TAU, 24, Color("7affc1") if near else Color("ffd84a"), 2.0)
		draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color("ffd84a"), 2.0)


## Aura dourada atrás do raro (no lugar de piscar a janela inteira).
class Glow extends Node2D:
	var col := Color(1, 0.85, 0.3)

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		for i in 6:
			var r := 34.0 - i * 5.0
			draw_circle(Vector2.ZERO, r, Color(col, 0.07 + i * 0.03))


## Chão recortado que flutua sobre a área de trabalho: grama irregular em cima,
## trilha no meio e um torrão de terra com raízes embaixo. As pontas somem.
class GroundStrip extends Node2D:
	var scroll := 0.0
	var kind := "terra"
	var width := 640.0
	var ground := 80.0
	var pal := {}

	func _ready() -> void:
		pal = {
			"terra": {"grama": Color("6fae3a"), "grama2": Color("8cc94a"), "tufo": Color("4f8a26"), "trilha": Color("caa66a"), "trilha2": Color("a9844f"), "terra": Color("6b4a32"), "terra2": Color("4a3122"), "raiz": Color("3a2618")},
			"areia": {"grama": Color("f0d699"), "grama2": Color("fbe9bd"), "tufo": Color("7cc6a8"), "trilha": Color("e2bd78"), "trilha2": Color("c9a160"), "terra": Color("b88a52"), "terra2": Color("8e683c"), "raiz": Color("6e4f2c")},
			"basalto": {"grama": Color("4a3a40"), "grama2": Color("6a545a"), "tufo": Color("ff7a2a"), "trilha": Color("5a4248"), "trilha2": Color("3d2b31"), "terra": Color("2e2024"), "terra2": Color("1e1417"), "raiz": Color("ff5a1a")},
		}[kind]

	func _h(k: int) -> int:
		var v := (k * 73856093) ^ (k * 19349663 >> 3)
		return absi(v) % 100000

	func _fade(x: float) -> float:
		return clampf(minf(x, width - x) / 70.0, 0.0, 1.0)

	func _band(y0: Callable, y1: Callable, col: Color, step := 4.0) -> void:
		var x := 0.0
		while x < width:
			var x2 := minf(x + step, width)
			var a := Color(col, col.a * _fade(x))
			var b := Color(col, col.a * _fade(x2))
			draw_polygon(PackedVector2Array([Vector2(x, y0.call(x)), Vector2(x2, y0.call(x2)), Vector2(x2, y1.call(x2)), Vector2(x, y1.call(x))]), PackedColorArray([a, b, b, a]))
			x = x2

	func _draw() -> void:
		var sc := floorf(scroll)
		var g := ground
		var top := func(x: float) -> float: return g - 12.0 + round(sin((x + sc) * 0.05) * 1.5 + sin((x + sc) * 0.013) * 1.5)
		var p0 := func(x: float) -> float: return g - 5.0 + round(sin((x + sc) * 0.04 + 2.0) * 1.0)
		var p1 := func(x: float) -> float: return g + 6.0 + round(sin((x + sc) * 0.035 + 0.5) * 1.0)
		var gb := func(x: float) -> float: return g + 9.0
		var bot := func(x: float) -> float:
			var k := int(floorf((x + sc) / 6.0))
			return g + 13.0 + float(_h(k) % 3)
		# torrão de terra embaixo (borda inferior serrilhada)
		_band(gb, bot, pal["terra"])
		_band(func(x): return bot.call(x) - 2.0, bot, pal["terra2"])
		# grama de cima e de baixo
		_band(top, p0, pal["grama"])
		_band(top, func(x): return top.call(x) + 2.0, pal["grama2"])
		_band(p1, gb, pal["grama"])
		# trilha
		_band(p0, p1, pal["trilha"])
		_band(p0, func(x): return p0.call(x) + 1.0, pal["trilha2"])
		# tufos, pedrinhas e raízes presos ao mundo
		var c0 := int(floorf((sc - 20.0) / 9.0))
		for k in range(c0, c0 + int(width / 9.0) + 4):
			var h := _h(k)
			var x: float = roundf(k * 9.0 - sc + h % 5)
			var f := _fade(x)
			if f <= 0.0:
				continue
			if h % 3 == 0:
				var yt: float = top.call(x)
				var c: Color = Color(pal["tufo"], f)
				draw_rect(Rect2(x, yt - 2, 1, 2), c)
				draw_rect(Rect2(x + 2, yt - 3, 1, 3), c)
				draw_rect(Rect2(x + 4, yt - 1, 1, 1), c)
			if h % 7 == 2:
				draw_rect(Rect2(x, p0.call(x) + 3.0 + float(h % 6), 2, 1), Color(pal["trilha2"], f))
			if h % 11 == 4:
				var yb: float = bot.call(x)
				var len := 2 + h % 4
				draw_rect(Rect2(x, yb - 1, 1, len), Color(pal["raiz"], f * 0.9))


## Partículas leves do mapa (não distraem): vagalumes e folhas na Floresta,
## brilhos e bolhas na Costa, brasas e cinzas no Monte Brasa. Corrompido:
## esporos roxos subindo devagar.
class MapAmbient extends Node2D:
	var kind := "floresta"
	var corrupted := false
	var ground := 80.0
	var drift := 0.0
	var ps: Array = []
	var t := 0.0

	func _ready() -> void:
		for i in 16:
			ps.append(_new(randf_range(0, 640)))

	func _new(x: float) -> Dictionary:
		return {"x": x, "y": randf_range(16, ground - 6), "ph": randf() * TAU, "sp": randf_range(0.5, 1.2), "k": randi() % 2}

	func _process(d: float) -> void:
		t += d
		for p in ps:
			p["x"] -= drift * d * p["sp"]
			if corrupted:
				p["y"] -= 4.0 * d * p["sp"]
			else:
				match kind:
					"floresta":
						p["x"] += sin(t * 0.8 + p["ph"]) * 6.0 * d
						p["y"] += (cos(t * 0.7 + p["ph"]) * 4.0 + (8.0 if p["k"] == 1 else 0.0)) * d
					"costa":
						p["y"] -= (6.0 if p["k"] == 1 else 0.0) * d
					"vulcao":
						p["y"] -= (10.0 if p["k"] == 0 else -5.0) * d * p["sp"]
						p["x"] += sin(t + p["ph"]) * 5.0 * d
			if p["x"] < -10 or p["y"] < 10 or p["y"] > ground + 2:
				var n := _new(650.0 if drift > 0.0 else randf_range(0, 640))
				p.merge(n, true)
		queue_redraw()

	func _draw() -> void:
		for p in ps:
			var x: float = p["x"]
			var fa := clampf(minf(x, 640.0 - x) / 70.0, 0.0, 1.0)
			var tw := 0.5 + 0.5 * sin(t * 3.0 + p["ph"])
			var pos := Vector2(round(x), round(p["y"]))
			if corrupted:
				draw_rect(Rect2(pos, Vector2(1, 1)), Color(0.75, 0.4, 1.0, 0.55 * fa * (0.5 + tw * 0.5)))
				continue
			match kind:
				"floresta":
					if p["k"] == 0:
						draw_circle(pos, 1.6, Color(0.85, 1.0, 0.4, 0.18 * fa * tw))
						draw_rect(Rect2(pos, Vector2(1, 1)), Color(0.95, 1.0, 0.6, 0.85 * fa * tw))
					else:
						draw_rect(Rect2(pos, Vector2(2, 1)), Color(0.45, 0.75, 0.3, 0.6 * fa))
				"costa":
					if p["k"] == 0:
						draw_rect(Rect2(pos, Vector2(1, 1)), Color(1, 1, 1, 0.8 * fa * tw * tw))
					else:
						draw_arc(pos, 1.5, 0, TAU, 8, Color(0.7, 0.9, 1.0, 0.45 * fa), 1.0)
				"vulcao":
					if p["k"] == 0:
						draw_rect(Rect2(pos, Vector2(1, 1)), Color(1.0, 0.55 + 0.3 * tw, 0.2, 0.85 * fa))
					else:
						draw_rect(Rect2(pos, Vector2(1, 1)), Color(0.5, 0.45, 0.45, 0.5 * fa))
