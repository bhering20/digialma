extends Control
## Batalha por turnos estilo GBA, com skills animadas, anel de acerto perfeito e escaneamento.
## Uso: var r = await battle.run(regiao, inimigos, lider)  -> "win" | "lose" | "run" | "caught"

signal choice_made(action: Dictionary)
signal done(result: String)

const FX = preload("res://scripts/fx.gd")
const Dialog = preload("res://scripts/dialog.gd")
const Ambient = preload("res://scripts/ambient.gd")

const E_FEET := Vector2(470, 196)
const P_FEET := Vector2(168, 270)

var region: Dictionary
var enemies: Array = []
var leader: Dictionary = {}
var e_i := 0
var p_i := 0
var world: Control
var p_spr: AnimatedSprite2D
var e_spr: AnimatedSprite2D
var p_mat: ShaderMaterial
var e_mat: ShaderMaterial
var e_box: PanelContainer
var p_box: PanelContainer
var e_name: Label
var e_hp: ProgressBar
var e_tag: Label
var p_name: Label
var p_hp: ProgressBar
var p_hp_l: Label
var p_xp: ProgressBar
var msg: Label
var grid: GridContainer
var dialog: Dialog
var fx_layer: Node2D
var shake := 0.0
var t := 0.0
var ring_active := false
var ring_pressed := false
var scan_mode := false
var lens_x := 320.0
var turn := 0
var ruido_used := false
var def_active := false
var def_kind := ""
var def_time := 0.0
var qte_active := false
var qte_key := ""
var qte_hit := false
var def_lock := 0.0
var def_now := false
var tdialog: Dialog
var DODGE_WIN := 0.22
var PARRY_WIN := 0.10
## Batalhas "intensas" (raros, líderes) usam todas as mecânicas; as comuns são rápidas.
var intense := false
var allow_defense := true
## Sincronia: enche com execução boa (perfeitos, esquivas, aparos). Cheia = Fusão de Alma.
var sync := 0.0
var sync_bar: ProgressBar
var bond_l: Label
var fusing := false
var energy := 1
var energy_l: Label


# ================================================================ montagem
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = Game.BASE
	theme = Game.make_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP


func _build() -> void:
	world = Control.new()
	world.set_anchors_preset(Control.PRESET_FULL_RECT)
	world.size = Game.BASE
	world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(world)
	var bg := TextureRect.new()
	bg.texture = Game.tex(region["bg"])
	bg.size = Vector2(660, 372)
	bg.position = Vector2(-10, -6)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = region["tint"]
	world.add_child(bg)
	var plats := Platforms.new()
	plats.region_name = region.get("plataforma", region["arena"])
	world.add_child(plats)
	var corrupt := leader.is_empty() and Game.region_corrupt(Game.REGIONS.find(region))
	if corrupt:
		var cm := Game.corrupt_mat()
		bg.material = cm
		plats.material = cm
	e_spr = _make_mon_sprite(enemies[e_i], false)
	e_spr.position = E_FEET
	world.add_child(e_spr)
	e_mat = e_spr.material
	p_spr = _make_mon_sprite(Game.team[p_i], true)
	p_spr.position = P_FEET
	world.add_child(p_spr)
	p_mat = p_spr.material
	var amb := Ambient.new()
	amb.kind = Ambient.kind_for(region)
	world.add_child(amb)
	amb.set_corrupted(corrupt)
	fx_layer = Node2D.new()
	world.add_child(fx_layer)
	_build_boxes()
	_build_panel()
	dialog = Dialog.new()
	add_child(dialog)


func _make_mon_sprite(m: Dictionary, player: bool) -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = Game.monster_frames(m["id"])
	s.play("idle")
	s.centered = false
	s.offset = Game.foot_offset(m["id"])
	s.scale = Vector2(2, 2)
	s.flip_h = player
	s.material = Game.sprite_mat()
	if not player and m.get("nefasto", false):
		(s.material as ShaderMaterial).set_shader_parameter("nefasto", 1.0)
	return s


func _info_box(pos: Vector2, w: float) -> PanelContainer:
	var b := PanelContainer.new()
	b.add_theme_stylebox_override("panel", Game.sb("panel_light", 8, Vector4(10, 6, 10, 6)))
	b.position = pos
	b.custom_minimum_size = Vector2(w, 0)
	add_child(b)
	return b


func _dark(l: Label) -> Label:
	l.add_theme_color_override("font_color", Color("2a1640"))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	return l


func _hp_bar(w: float) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(w, 7)
	return pb


func _build_boxes() -> void:
	e_box = _info_box(Vector2(16, 14), 220)
	var ev := VBoxContainer.new()
	ev.add_theme_constant_override("separation", 2)
	e_box.add_child(ev)
	var eh := HBoxContainer.new()
	ev.add_child(eh)
	e_name = _dark(Label.new())
	e_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eh.add_child(e_name)
	e_tag = Label.new()
	eh.add_child(e_tag)
	var ehh := HBoxContainer.new()
	ev.add_child(ehh)
	var hl := Label.new()
	hl.text = "HP"
	hl.add_theme_color_override("font_color", Color("e07030"))
	ehh.add_child(hl)
	e_hp = _hp_bar(170)
	e_hp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ehh.add_child(e_hp)
	p_box = _info_box(Vector2(400, 212), 224)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 2)
	p_box.add_child(pv)
	p_name = _dark(Label.new())
	pv.add_child(p_name)
	var phh := HBoxContainer.new()
	pv.add_child(phh)
	var hl2 := Label.new()
	hl2.text = "HP"
	hl2.add_theme_color_override("font_color", Color("e07030"))
	phh.add_child(hl2)
	p_hp = _hp_bar(130)
	p_hp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	phh.add_child(p_hp)
	p_hp_l = _dark(Label.new())
	phh.add_child(p_hp_l)
	var xh := HBoxContainer.new()
	pv.add_child(xh)
	var xl := Label.new()
	xl.text = "XP"
	xl.add_theme_color_override("font_color", Color("3b5bb5"))
	xh.add_child(xl)
	p_xp = _hp_bar(170)
	p_xp.custom_minimum_size.y = 4
	p_xp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var xf := StyleBoxFlat.new()
	xf.bg_color = Color("40a8f8")
	p_xp.add_theme_stylebox_override("fill", xf)
	xh.add_child(p_xp)
	var sh := HBoxContainer.new()
	pv.add_child(sh)
	var sl := Label.new()
	sl.text = "SINC"
	sl.add_theme_color_override("font_color", Color("c8901a"))
	sh.add_child(sl)
	sync_bar = _hp_bar(110)
	sync_bar.custom_minimum_size.y = 5
	sync_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sync_bar.max_value = 100
	sync_bar.value = sync
	var sf := StyleBoxFlat.new()
	sf.bg_color = Color("ffd84a")
	sync_bar.add_theme_stylebox_override("fill", sf)
	sh.add_child(sync_bar)
	bond_l = Label.new()
	bond_l.add_theme_font_size_override("font_size", 8)
	sh.add_child(bond_l)
	energy_l = Label.new()
	energy_l.add_theme_color_override("font_color", Color("58e0ff"))
	energy_l.add_theme_color_override("font_outline_color", Color("0c2a40"))
	energy_l.add_theme_constant_override("outline_size", 3)
	pv.add_child(energy_l)


func _build_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(4, 284)
	panel.custom_minimum_size = Vector2(632, 72)
	add_child(panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	panel.add_child(h)
	msg = Label.new()
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.custom_minimum_size = Vector2(250, 48)
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(msg)
	grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	h.add_child(grid)


func _refresh_boxes(animate := true) -> void:
	var e: Dictionary = enemies[e_i]
	var p: Dictionary = Game.team[p_i]
	e_name.text = "%s  Nv%d" % [Game.mon_title(e), e["lv"]]
	e_name.add_theme_color_override("font_color", Game.rar_color(int(e.get("rar", 0))))
	e_tag.text = "NEFASTO" if e.get("nefasto", false) else Game.MONSTERS[e["id"]]["tipo"].to_upper()
	e_tag.add_theme_color_override("font_color", Color("b050ff") if e.get("nefasto", false) else Game.TYPE_COLORS[Game.MONSTERS[e["id"]]["tipo"]])
	p_name.text = "%s  Nv%d" % [Game.mon_name(p), p["lv"]]
	_set_bar(e_hp, e["hp"], Game.max_hp(e), animate)
	_set_bar(p_hp, p["hp"], Game.max_hp(p), animate)
	p_hp_l.text = "%d/%d" % [maxi(p["hp"], 0), Game.max_hp(p)]
	p_xp.max_value = Game.xp_need(p)
	p_xp.value = p["xp"]
	if energy_l:
		var pips := ""
		for i in Game.ENERGY_MAX:
			pips += "■ " if i < energy else "□ "
		energy_l.text = "ENERGIA  " + pips
	if bond_l:
		bond_l.text = " FÚR %d  GUA %d" % [p.get("fur", 0), p.get("gua", 0)]
		bond_l.add_theme_color_override("font_color", Color("b8402a") if p.get("fur", 0) >= p.get("gua", 0) else Color("2a6ab8"))


func _set_bar(bar: ProgressBar, v: int, mx: int, animate: bool) -> void:
	bar.max_value = mx
	var ratio := float(v) / float(mx)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("58d080") if ratio >= 0.5 else (Color("e8c020") if ratio >= 0.2 else Color("e04040"))
	bar.add_theme_stylebox_override("fill", fill)
	if animate:
		create_tween().tween_property(bar, "value", float(maxi(v, 0)), 0.45).set_trans(Tween.TRANS_SINE)
	else:
		bar.value = maxi(v, 0)


# ================================================================ fluxo principal
func run(reg: Dictionary, enemy_list: Array, lead := {}) -> String:
	region = reg
	enemies = enemy_list
	leader = lead
	p_i = maxi(Game.first_alive(), 0)
	Game.battle_count += 1
	intense = not leader.is_empty() or (enemy_list[0].get("raro", false) and Game.battle_count >= 3)
	var amp := 1.6 if Game.options.get("janela_ampla", false) else 1.0
	DODGE_WIN = 0.22 * amp
	PARRY_WIN = 0.10 * amp
	# na primeira batalha o jogador só aprende a atacar
	allow_defense = Game.tutorial["esquiva"] or Game.battle_count >= 2
	var lead_m: Dictionary = Game.team[p_i]
	if Game.has_skill(lead_m, "f4"):
		energy += 1  # Árvore: Furor
	if Game.has_skill(lead_m, "v4"):
		sync = 25.0  # Árvore: Alma Gêmea
	_build()
	_refresh_boxes(false)
	await _intro()
	var result := await _loop()
	return result


func _intro() -> void:
	e_spr.position.x = 760
	p_spr.position.x = -120
	e_box.modulate.a = 0.0
	p_box.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(e_spr, "position:x", E_FEET.x, 0.55).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(p_spr, "position:x", P_FEET.x, 0.55).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	await tw.finished
	_burst(E_FEET + Vector2(0, -60), Color("b050ff") if enemies[e_i].get("nefasto", false) else Color.WHITE, 24)
	create_tween().tween_property(e_box, "modulate:a", 1.0, 0.2)
	create_tween().tween_property(p_box, "modulate:a", 1.0, 0.2)
	if leader.is_empty() and enemies[e_i].get("raro", false):
		_burst(E_FEET + Vector2(0, -70), Color("ffd84a"), 50, 160.0)
		_float_text(E_FEET + Vector2(0, -160), "RARO!", Color("ffd84a"), 22)
		var rr: int = int(enemies[e_i].get("rar", 0))
		await _say("Um Digialma %s apareceu: %s! Ele é arisco, escanear vai ser difícil!" % [Game.RARITY[rr]["nome"].to_upper() if rr >= 2 else "RARO", Game.mon_name(enemies[e_i])])
	elif leader.is_empty():
		await _say("Um %s NEFASTO apareceu! Ele está tomado pela escuridão..." % Game.mon_name(enemies[e_i]))
	else:
		await _say("%s chamou %s!" % [leader["nome"], Game.mon_name(enemies[e_i])])
	await _say("Vai, %s!" % Game.mon_name(Game.team[p_i]))
	if not Game.tutorial["ataque"] and _tips():
		Game.tutorial["ataque"] = true
		await _elo_talk([
			["elo", "Eu ajudo! Escolha LUTAR e um golpe."],
			["elo", "Um anel dourado vai fechar sobre o inimigo. Aperte (clique, toque ou espaço) quando ele encostar no círculo!"],
		])


func _loop() -> String:
	while true:
		turn += 1
		await _maybe_ruido_event()
		var a: Dictionary = await _player_choice()
		match a["type"]:
			"fusion":
				var kof := await _fusion()
				if kof:
					var rf := await _enemy_fainted()
					if rf != "":
						return rf
					continue
			"help":
				await _help()
				turn -= 1
				continue
			"run":
				await _say("Você fugiu em segurança.")
				return "run"
			"scan":
				var ok := await _scan()
				if ok:
					return "caught"
			"item":
				await _use_item(a["item"])
			"switch":
				await _switch_to(a["index"])
			"move":
				if Game.MOVES[a["move"]].has("cura"):
					await _heal_move(a["move"])
					var ko3 := await _enemy_turn()
					if enemies[e_i]["hp"] <= 0:
						var r4 := await _enemy_fainted()
						if r4 != "":
							return r4
					continue
				var mult := 1.0
				var perfect := false
				if Game.MOVES[a["move"]]["cd"] > 0:
					energy -= Game.move_cost(a["move"])
					_refresh_boxes()
					if not Game.tutorial["especial"]:
						Game.tutorial["especial"] = true
						await _elo_talk([["elo", "Golpe especial! Vão aparecer 4 setas. Aperte cada uma na ordem (setas do teclado ou toque nelas)."], ["elo", "Cada acerto deixa o golpe mais forte. Acertou as 4? SINCRONIA TOTAL!"]])
					mult = await _special_qte()
					perfect = mult >= 1.4
				var ko := false
				if Game.MOVES[a["move"]]["cd"] > 0:
					ko = await _do_move(true, a["move"], perfect, "", mult)
				else:
					ko = await _attack_combo(a["move"])
				if ko:
					var r := await _enemy_fainted()
					if r != "":
						return r
					continue
		# turno do inimigo
		var ko2 := await _enemy_turn()
		if enemies[e_i]["hp"] <= 0:
			var r3 := await _enemy_fainted()
			if r3 != "":
				return r3
			continue
		if ko2:
			var r2 := await _player_fainted()
			if r2 != "":
				return r2
	return "run"


func _say(text: String, wait := 0.9) -> void:
	_clear_grid()
	msg.text = text
	msg.visible_characters = 0
	var tw := create_tween()
	tw.tween_property(msg, "visible_characters", text.length(), text.length() * (0.018 if intense else 0.012))
	await tw.finished
	await get_tree().create_timer(wait * (1.0 if intense else 0.65)).timeout


func _clear_grid() -> void:
	for c in grid.get_children():
		c.queue_free()


func _btn(txt: String, cb: Callable, col := Color(0, 0, 0, 0), enabled := true) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(112, 22)
	b.disabled = not enabled
	if col.a > 0:
		b.add_theme_color_override("font_color", col.lightened(0.3))
	b.pressed.connect(cb)
	FX.juice_button(b)
	grid.add_child(b)
	return b


func _player_choice() -> Dictionary:
	# trava de segurança: nunca escolher ação com a câmera fora do lugar
	if cam_z > 1.001 or world.position != Vector2.ZERO:
		_cam_to(Vector2(320, 180), 1.0, 0.25)
	_show_main_menu()
	var a: Dictionary = await choice_made
	return a


func _show_main_menu() -> void:
	_clear_grid()
	msg.text = "O que %s vai fazer?" % Game.mon_name(Game.team[p_i])
	msg.visible_characters = -1
	var first := _btn("LUTAR", _show_moves)
	var can_scan: bool = leader.is_empty()
	_btn("ESCANEAR (%d)" % Game.elo_charges, func(): choice_made.emit({"type": "scan"}), Color("5cff9c"), can_scan)
	_btn("MOCHILA", _show_items)
	_btn("TROCAR", _show_switch, Color(0, 0, 0, 0), Game.team.size() > 1)
	_btn("FUGIR", func(): choice_made.emit({"type": "run"}), Color(0, 0, 0, 0), leader.is_empty())
	if sync >= 100.0:
		var fb := _btn("FUSÃO DE ALMA!", func(): choice_made.emit({"type": "fusion"}), Color("ffd84a"))
		fb.add_theme_color_override("font_color", Color("fff3a8"))
		var pulse := fb.create_tween().set_loops()
		pulse.tween_property(fb, "modulate", Color(1.4, 1.25, 0.7), 0.4)
		pulse.tween_property(fb, "modulate", Color.WHITE, 0.4)
	else:
		_btn("? AJUDA", func(): choice_made.emit({"type": "help"}), Color("ffd84a"))
	first.grab_focus.call_deferred()


func _show_moves() -> void:
	_clear_grid()
	var p: Dictionary = Game.team[p_i]
	var first: Button = null
	for mk in Game.moves_of(p):
		var mv: Dictionary = Game.MOVES[mk]
		var cost := Game.move_cost(mk)
		var label: String = mv["nome"] if cost == 0 else "%s  [%d EN]" % [mv["nome"], cost]
		var b := _btn(label, func(): choice_made.emit({"type": "move", "move": mk}), Game.TYPE_COLORS[mv["tipo"]], energy >= cost)
		b.tooltip_text = "%s  •  poder %d" % [mv["tipo"], mv["poder"]]
		if first == null:
			first = b
	_btn("VOLTAR", _show_main_menu)
	msg.text = "Golpes normais geram ENERGIA. Especiais gastam %d." % Game.ENERGY_COST
	first.grab_focus.call_deferred()


func _show_items() -> void:
	_clear_grid()
	var any := false
	for k in ["pocao", "super_pocao", "orbe_alma", "fruta", "chip_elo"]:
		if Game.inventory.get(k, 0) > 0:
			any = true
			_btn("%s x%d" % [Game.ITEMS[k]["nome"], Game.inventory[k]], func(): choice_made.emit({"type": "item", "item": k}))
	_btn("VOLTAR", _show_main_menu)
	msg.text = "Escolha um item." if any else "Sua mochila está vazia."


func _show_switch() -> void:
	_clear_grid()
	for i in Game.team.size():
		var m: Dictionary = Game.team[i]
		var ok: bool = i != p_i and m["hp"] > 0
		_btn("%s %d/%d" % [Game.mon_name(m), maxi(m["hp"], 0), Game.max_hp(m)], func(): choice_made.emit({"type": "switch", "index": i}), Color(0, 0, 0, 0), ok)
	_btn("VOLTAR", _show_main_menu)
	msg.text = "Trocar por quem?"


# ================================================================ golpes e efeitos
func _ring(dur := 1.0) -> bool:
	# anel que encolhe em volta do alvo: aperte quando ele encostar no círculo dourado
	ring_active = true
	ring_pressed = false
	var r := RingFx.new()
	r.position = E_FEET + Vector2(0, -70)
	fx_layer.add_child(r)
	var start := Time.get_ticks_msec()
	var perfect := false
	var ms := dur * 1000.0
	while Time.get_ticks_msec() - start < ms:
		r.progress = (Time.get_ticks_msec() - start) / ms
		if ring_pressed:
			perfect = absf(r.radius() - RingFx.TARGET) <= 7.0
			break
		await get_tree().process_frame
	ring_active = false
	r.finish(perfect)
	if perfect:
		_float_text(E_FEET + Vector2(0, -150), "PERFEITO!", Color("ffd84a"), 18)
	return perfect


func _do_move(from_player: bool, mk: String, perfect := false, defense := "", mult := 1.0, hit := 0, pre := false) -> bool:
	var mv: Dictionary = Game.MOVES[mk]
	var atk: Dictionary = Game.team[p_i] if from_player else enemies[e_i]
	var def: Dictionary = enemies[e_i] if from_player else Game.team[p_i]
	var a_spr := p_spr if from_player else e_spr
	var d_spr := e_spr if from_player else p_spr
	var d_mat := e_mat if from_player else p_mat
	var a_feet := P_FEET if from_player else E_FEET
	var d_feet := E_FEET if from_player else P_FEET
	var col: Color = Game.TYPE_COLORS[mv["tipo"]]
	var big: bool = mv["cd"] > 0 and hit == 0
	if big and not from_player:
		atk["cd"][mk] = mv["cd"] + 1
	if hit == 0:
		msg.text = "%s usou %s!" % [Game.mon_name(atk), mv["nome"]]
	msg.visible_characters = -1
	_clear_grid()
	var center := d_feet + Vector2(0, -70)
	if pre:
		# a animação já aconteceu dentro de _strike (o golpe foi o próprio aviso)
		if defense == "":
			_impact(center, mv, big)
		if cam_z > 1.001:
			_cam_to(center, 1.0, 0.4)
	else:
		a_spr.play("attack")
		a_spr.animation_finished.connect(func(): a_spr.play("idle"), CONNECT_ONE_SHOT)
		if big:
			await _big_move_intro(a_feet, col)
		if defense == "dodge" or defense == "parry":
			_defend_anim(defense)
		_squash(a_spr, -0.18 if mv["kind"] == "contato" else 0.14)
	if pre:
		pass
	elif mk == "erupcao":
		await _erupcao_fx(a_feet, d_feet)
		_impact(center, mv, true)
		_cam_to(d_feet + Vector2(0, -60), 1.0, 0.5)
	elif mv["kind"] == "contato":
		var back := a_spr.position
		var tw := create_tween()
		tw.tween_property(a_spr, "position", back.lerp(d_feet, 0.62), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw.finished
		_impact(center, mv, perfect or big)
		create_tween().tween_property(a_spr, "position", back, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		_burst(a_feet + Vector2(0, -80), col, 18, 60.0)
		var orb := Orb.new()
		orb.col = col
		orb.position = a_feet + Vector2(0, -80)
		fx_layer.add_child(orb)
		var tw2 := create_tween()
		tw2.tween_property(orb, "position", center, 0.3).set_trans(Tween.TRANS_SINE)
		await tw2.finished
		orb.queue_free()
		_impact(center, mv, perfect or big)
		if big:
			_cam_to(center, 1.0, 0.5)
	# dano
	var bm := 1.0
	if from_player and perfect:
		bm += minf(0.3, atk.get("fur", 0) * 0.02)  # Fúria: críticos mais fortes
	if from_player:
		bm += Game.skill_dmg(atk)  # Árvore: Garra Afiada / Fervor
		if perfect and Game.has_skill(atk, "f3"):
			bm += 0.1  # Árvore: Instinto
	if not from_player:
		bm -= Game.skill_def(def)  # Árvore: Couraça / Casca Dura
	if not from_player:
		bm -= minf(0.25, def.get("gua", 0) * 0.015)  # Guarda: leva menos dano
		if not allow_defense:
			bm *= 0.5  # primeira batalha: ainda não sabe se defender
	var dmg := int(round(_damage(atk, def, mv, perfect) * mult * bm))
	var eff := Game.effectiveness(mv["tipo"], Game.MONSTERS[def["id"]]["tipo"])
	if defense == "dodge":
		dmg = 0
		_float_text(d_feet + Vector2(0, -140), "DESVIOU!", Color("7affc1"), 18)
	elif defense == "parry":
		dmg = 0
		_float_text(d_feet + Vector2(0, -140), "APAROU!", Color("ffd84a"), 22)
		_burst(d_feet + Vector2(30, -70), Color("ffd84a"), 30, 200.0)
	if dmg > 0:
		def["hp"] -= dmg
		_hit_feedback(d_spr, d_mat, dmg, d_feet, perfect, big)
		if from_player and def.get("charge", 0) > 0:
			def["charge_dmg"] = def.get("charge_dmg", 0) + dmg
	_refresh_boxes()
	await get_tree().create_timer(0.55 if hit == 0 else 0.3).timeout
	if dmg <= 0 or hit > 0:
		pass
	elif eff > 1.0:
		await _say("É super eficaz!", 0.5)
	elif eff < 1.0:
		await _say("Não foi muito eficaz...", 0.5)
	# recarga de golpes fortes (uma vez por turno)
	if hit == 0:
		for k in atk["cd"].keys():
			atk["cd"][k] = maxi(0, atk["cd"][k] - 1)
	return def["hp"] <= 0


func _damage(atk: Dictionary, def: Dictionary, mv: Dictionary, perfect: bool) -> int:
	var base: float = mv["poder"] * Game.stat(atk, "atk") / maxf(0.5, Game.stat(def, "def")) * (0.6 + atk["lv"] * 0.09)
	var stab := 1.2 if mv["tipo"] == Game.MONSTERS[atk["id"]]["tipo"] else 1.0
	var eff := Game.effectiveness(mv["tipo"], Game.MONSTERS[def["id"]]["tipo"])
	return maxi(1, int(round(base * stab * eff * (1.5 if perfect else 1.0) * randf_range(0.88, 1.0))))


func _big_move_intro(feet: Vector2, col: Color) -> void:
	var dark := ColorRect.new()
	dark.color = Color(0.03, 0.01, 0.08, 0.0)
	dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark.size = Game.BASE
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(dark)
	world.move_child(dark, 2)
	var tw := create_tween()
	tw.tween_property(dark, "color:a", 0.6, 0.2)
	_cam_to(feet + Vector2(0, -60), 1.3, 0.35)
	for i in 3:
		_burst(feet + Vector2(0, -70), col, 16, 40.0 + i * 30.0, true)
		await get_tree().create_timer(0.18).timeout
	var tw2 := create_tween()
	tw2.tween_property(dark, "color:a", 0.0, 0.5).set_delay(0.4)
	tw2.tween_callback(dark.queue_free)


func _impact(at: Vector2, mv: Dictionary, strong: bool) -> void:
	var e := AnimatedSprite2D.new()
	e.sprite_frames = Game.fx_frames(mv["fx"])
	e.position = at
	if mv["tipo"] == "Psíquico":
		e.modulate = Color(0.8, 0.5, 1.0)
	elif mv["tipo"] == "Elétrico":
		e.modulate = Color(1.0, 0.95, 0.4)
	if strong:
		e.scale = Vector2(1.4, 1.4)
	fx_layer.add_child(e)
	e.play("play")
	e.animation_finished.connect(e.queue_free)
	var col: Color = Game.TYPE_COLORS[mv["tipo"]]
	_burst(at, col, 34 if strong else 22, 180.0 if strong else 120.0)
	_burst(at, Color.WHITE, 10, 90.0)
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.35 if strong else 0.18)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.size = Game.BASE
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	create_tween().tween_property(flash, "color:a", 0.0, 0.25).finished.connect(flash.queue_free)
	shake = 10.0 if strong else 6.0
	_hitstop(0.09 if strong else 0.06)


## Esticar e achatar: respiração parada + "mola" que reage a golpes e saltos.
func _squash(spr: AnimatedSprite2D, amount: float) -> void:
	if is_instance_valid(spr):
		spr.set_meta("sqv", spr.get_meta("sqv", 0.0) + amount * 14.0)


func _squash_step(spr: AnimatedSprite2D, delta: float, phase: float) -> void:
	if not is_instance_valid(spr) or spr.get_meta("noscale", false):
		return
	var sq: float = spr.get_meta("sq", 0.0)
	var v: float = spr.get_meta("sqv", 0.0)
	v += (-sq * 220.0 - v * 13.0) * delta
	sq = clampf(sq + v * delta, -0.35, 0.35)
	spr.set_meta("sq", sq)
	spr.set_meta("sqv", v)
	var b := sin(t * 2.2 + phase) * 0.022
	spr.scale = Vector2(2.0 * (1.0 + sq - b), 2.0 * (1.0 - sq + b))


func _hit_feedback(spr: AnimatedSprite2D, mat: ShaderMaterial, dmg: int, feet: Vector2, perfect: bool, big: bool) -> void:
	_squash(spr, 0.28 if (perfect or big) else 0.2)
	var tw := create_tween()
	tw.tween_method(func(v): mat.set_shader_parameter("flash", v), 1.0, 0.0, 0.3)
	var kb := 10.0 if spr == e_spr else -10.0
	var base := spr.position
	var tw2 := create_tween()
	tw2.tween_property(spr, "position:x", base.x + kb, 0.05)
	tw2.tween_property(spr, "position:x", base.x, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_float_text(feet + Vector2(randf_range(-10, 10), -130), str(dmg), Color("ffd84a") if (perfect or big) else Color.WHITE, 24 if (perfect or big) else 18)


func _hitstop(sec: float) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(sec, true, false, true).timeout
	Engine.time_scale = 1.0


func _burst(at: Vector2, col: Color, n: int, speed := 120.0, inward := false) -> void:
	var p := CPUParticles2D.new()
	p.position = at
	p.amount = n
	p.one_shot = true
	p.explosiveness = 0.95
	p.lifetime = 0.6
	p.spread = 180.0
	p.gravity = Vector2(0, 160)
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	var g := Gradient.new()
	g.set_color(0, col)
	g.set_color(1, Color(col, 0.0))
	p.color_ramp = g
	if inward:
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
		p.emission_sphere_radius = 70.0
		p.radial_accel_min = -400.0
		p.radial_accel_max = -300.0
		p.initial_velocity_max = 10.0
		p.gravity = Vector2.ZERO
	fx_layer.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


func _float_text(at: Vector2, txt: String, col: Color, size := 18) -> void:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", Game.title_font_for(txt))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color("2a1640"))
	l.add_theme_constant_override("outline_size", 6)
	l.position = at - Vector2(40, 0)
	l.size = Vector2(80, 30)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.pivot_offset = Vector2(40, 15)
	l.scale = Vector2(0.4, 0.4)
	add_child(l)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", at.y - 30, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.3).set_delay(0.6)
	tw.chain().tween_callback(l.queue_free)


# ================================================================ turnos
func _enemy_turn() -> bool:
	var e: Dictionary = enemies[e_i]
	var p: Dictionary = Game.team[p_i]
	var options: Array = []
	for mk in Game.moves_of(e):
		if e["cd"].get(mk, 0) == 0:
			options.append(mk)
	var pick: String = options[randi() % options.size()]
	for mk in options:
		if Game.effectiveness(Game.MOVES[mk]["tipo"], Game.MONSTERS[p["id"]]["tipo"]) > 1.0 and randf() < 0.6:
			pick = mk
	if e.get("stun", 0) > 0:
		e["stun"] -= 1
		await _say("%s está atordoado e não consegue atacar!" % Game.mon_name(e), 0.6)
		return false
	if e.get("charge", 0) > 0:
		e["charge"] -= 1
		if e["charge"] > 0:
			_burst(E_FEET + Vector2(0, -70), Color("b050ff"), 30, 80.0, true)
			await _say("O Ruído está crescendo... Dano causado: %d / %d" % [e.get("charge_dmg", 0), e["charge_need"]], 0.7)
			return false
		if e.get("charge_dmg", 0) >= e["charge_need"]:
			_burst(E_FEET + Vector2(0, -70), Color.WHITE, 40, 220.0)
			shake = 8.0
			e["stun"] = 1
			await _say("Você QUEBROU o Ruído! %s ficou atordoado!" % Game.mon_name(e), 0.8)
			return false
		pick = "ruido"
		await _say("O Ruído explode! PREPARE-SE!", 0.3)
	await get_tree().create_timer(0.2).timeout
	await _defense_lessons()
	var big: bool = Game.MOVES[pick]["cd"] > 0 or pick == "ruido"
	# combos do inimigo: comuns 1-2 golpes, raros 2-3, líderes 2-3. Golpes grandes são 1 só.
	var n := 1
	if not big and intense and Game.tutorial["aparo"]:
		n = randi_range(2, 3)
	if n > 1:
		_float_text(E_FEET + Vector2(110, -120), "COMBO x%d!" % n, Color("ff5070"), 16)
	var pat: Array = Game.PATTERNS.get(e["id"], [[1.0, false], [0.7, false]])
	if n > 1:
		n = pat.size()
	var parries := 0
	var ko := false
	if big:
		await _big_move_intro(E_FEET, Game.TYPE_COLORS[Game.MOVES[pick]["tipo"]])
		# volta a câmera antes do bote: o jogador precisa ver o próprio Digialma para defender
		_cam_to(Vector2(320, 180), 1.0, 0.25)
		await get_tree().create_timer(0.25).timeout
	for i in n:
		var step: Array = pat[i % pat.size()]
		var dur: float = step[0] * (0.9 if big else 1.0)
		var defense := await _strike(pick, dur, step[1], big)
		if defense == "parry":
			parries += 1
			_gain(22, "gua", 2)
			_energy(1)
		elif defense == "dodge":
			_gain(10, "gua", 1)
		ko = await _do_move(false, pick, false, defense, 1.0 if n == 1 else 0.6, i, true)
		if ko:
			break
	if not ko and parries == n and e["hp"] > 0:
		if n > 1:
			_float_text(P_FEET + Vector2(0, -170), "COMBO APARADO!", Color("ffd84a"), 18)
		await _counter(n > 1)
	return ko


func _enemy_fainted() -> String:
	var e: Dictionary = enemies[e_i]
	Game.gain_elo(4 + int(e.get("rar", 0)) * 2)
	await _faint(e_spr)
	await _say("%s foi derrotado!" % Game.mon_name(e), 0.5)
	await _gain_xp(e)
	e_i += 1
	if e_i >= enemies.size():
		if not leader.is_empty():
			await _say("Você venceu %s!" % leader["nome"])
		return "win"
	# próximo monstro do líder
	e_spr.queue_free()
	e_spr = _make_mon_sprite(enemies[e_i], false)
	e_spr.position = E_FEET + Vector2(200, 0)
	world.add_child(e_spr)
	world.move_child(e_spr, 2)
	e_mat = e_spr.material
	_refresh_boxes(false)
	await create_tween().tween_property(e_spr, "position", E_FEET, 0.4).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT).finished
	await _say("%s chamou %s!" % [leader["nome"], Game.mon_name(enemies[e_i])])
	return ""


func _player_fainted() -> String:
	await _faint(p_spr)
	await _say("%s desmaiou!" % Game.mon_name(Game.team[p_i]))
	var nxt := Game.first_alive()
	if nxt < 0:
		await _say("Sua equipe não aguenta mais... Vocês recuam para descansar.")
		return "lose"
	await _switch_to(nxt, true)
	return ""


func _faint(spr: AnimatedSprite2D) -> void:
	var mat := spr.material as ShaderMaterial
	var tw := create_tween().set_parallel(true)
	tw.tween_property(spr, "position:y", spr.position.y + 40, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(spr, "modulate:a", 0.0, 0.45)
	tw.tween_method(func(v): mat.set_shader_parameter("flash", v), 0.6, 0.0, 0.45)
	await tw.finished


func _gain_xp(e: Dictionary) -> void:
	var gain: int = e["lv"] * (14 if not leader.is_empty() else 10)
	for i in Game.team.size():
		var m: Dictionary = Game.team[i]
		if m["hp"] <= 0:
			continue
		var g: int = gain if i == p_i else gain / 2
		m["xp"] += int(g * (1.0 + Game.gear_bonus(m, "xp")))
		m["vinculo"] = mini(100, m["vinculo"] + 4)
		while m["xp"] >= Game.xp_need(m):
			m["xp"] -= Game.xp_need(m)
			Game.level_up(m)
			if i == p_i:
				_refresh_boxes()
				_burst(P_FEET + Vector2(0, -60), Color("ffd84a"), 26, 100.0)
				await _say("%s subiu para o nível %d! +1 Ponto de Alma." % [Game.mon_name(m), m["lv"]], 0.6)
	_refresh_boxes()
	await _say("%s ganhou %d de experiência." % [Game.mon_name(Game.team[p_i]), gain], 0.4)


func _switch_to(i: int, forced := false) -> void:
	if not forced:
		await _say("Volta, %s!" % Game.mon_name(Game.team[p_i]), 0.3)
		await create_tween().tween_property(p_spr, "position:x", -120.0, 0.3).finished
	p_i = i
	p_spr.queue_free()
	p_spr = _make_mon_sprite(Game.team[p_i], true)
	p_spr.position = Vector2(-120, P_FEET.y)
	world.add_child(p_spr)
	world.move_child(p_spr, 3)
	p_mat = p_spr.material
	_refresh_boxes(false)
	await create_tween().tween_property(p_spr, "position:x", P_FEET.x, 0.4).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT).finished
	await _say("Vai, %s!" % Game.mon_name(Game.team[p_i]), 0.4)


func _use_item(k: String) -> void:
	var p: Dictionary = Game.team[p_i]
	Game.inventory[k] -= 1
	if Game.inventory[k] <= 0:
		Game.inventory.erase(k)
	match k:
		"pocao":
			p["hp"] = mini(Game.max_hp(p), p["hp"] + 20)
		"super_pocao":
			p["hp"] = mini(Game.max_hp(p), p["hp"] + 60)
		"fruta":
			p["hp"] = mini(Game.max_hp(p), p["hp"] + 10)
			p["vinculo"] = mini(100, p["vinculo"] + 10)
		"chip_elo":
			Game.elo_charges += 3
		"orbe_alma":
			Game.inventory[k] = int(Game.inventory.get(k, 0)) + 1  # use_soul_orb desconta
			var ri := Game.use_soul_orb()
			if ri < 0:
				await _say("Ninguém virou alma. O Orbe foi guardado.", 0.6)
				return
			_refresh_boxes()
			await _say("%s voltou da forma de alma!" % Game.mon_name(Game.team[ri]), 0.7)
			return
	_burst(P_FEET + Vector2(0, -60), Color("7affc1"), 24, 80.0, true)
	_refresh_boxes()
	await _say("Você usou %s!" % Game.ITEMS[k]["nome"], 0.6)


# ================================================================ escaneamento (minijogo)
func _scan() -> bool:
	var e: Dictionary = enemies[e_i]
	var ratio := float(e["hp"]) / float(Game.max_hp(e))
	if Game.elo_charges <= 0:
		await _say("O Elo está sem energia! Use um Chip do Elo.", 0.6)
		return false
	if not Game.can_capture(e):
		await _say("O Elo (Nv %d) ainda é fraco para guardar um Digialma %s. Precisa de Elo Nv %d!" % [Game.elo_lv, Game.RARITY[int(e.get("rar", 0))]["nome"], Game.capture_lv(e)], 0.9)
		return false
	if ratio > 0.5:
		await _say("O Nefasto ainda está forte demais! Enfraqueça ele primeiro (menos da metade da vida).", 0.8)
		return false
	if not Game.tutorial["escanear"]:
		Game.tutorial["escanear"] = true
		await _elo_talk([["elo", "Vou purificar e guardar esse Digialma! Um feixe verde vai descer sobre ele."], ["elo", "Arraste a lente (mouse, toque ou setas) e mantenha em cima dele até a barra passar da marca."], ["elo", "Quanto mais fraco ele estiver, menos a barra precisa encher. Digialmas RAROS fogem mais rápido!"]])
	Game.elo_charges -= 1
	await _say("ELO, ESCANEAR! Mantenha a lente verde em cima dele! (mouse, toque ou setas)", 0.4)
	var ui := ScanUI.new()
	add_child(ui)
	scan_mode = true
	lens_x = E_FEET.x
	var raro: bool = e.get("raro", false)
	# raro: mais rápido e exigente, mas com mais tempo para compensar
	var need := (0.4 + ratio * 0.4) if raro else (0.25 + ratio * 0.45)
	var meter := 0.0
	var dur := 5.0 if raro else 4.2
	var j_min := 0.5 if raro else 0.8
	var j_max := 0.85 if raro else 1.3
	var j_range := 95.0 if raro else 65.0
	var follow := 0.06 if raro else 0.035
	var tol := 32.0 if raro else 38.0
	var drain := 0.2 if raro else 0.12
	var start := Time.get_ticks_msec()
	var jitter_t := 0.0
	var target_x := E_FEET.x
	while true:
		var el := (Time.get_ticks_msec() - start) / 1000.0
		if el >= dur:
			break
		var dt := get_process_delta_time()
		jitter_t -= dt
		if jitter_t <= 0.0:
			jitter_t = randf_range(j_min, j_max)
			target_x = E_FEET.x + randf_range(-j_range, j_range)
		e_spr.position.x = lerpf(e_spr.position.x, target_x, follow)
		if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
			lens_x -= 260.0 * dt
		if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
			lens_x += 260.0 * dt
		lens_x = clampf(lens_x, 300, 640)
		var on := absf(lens_x - e_spr.position.x) < tol
		meter = clampf(meter + (0.75 if on else -drain) * dt, 0.0, 1.0)
		var beam_y := lerpf(10.0, E_FEET.y, el / dur)
		ui.update(lens_x, beam_y, meter, need, on, el / dur)
		e_mat.set_shader_parameter("flash", 0.25 if on and int(el * 12) % 2 == 0 else 0.0)
		await get_tree().process_frame
	scan_mode = false
	ui.queue_free()
	e_mat.set_shader_parameter("flash", 0.0)
	await create_tween().tween_property(e_spr, "position:x", E_FEET.x, 0.2).finished
	if meter >= need:
		await _scan_success(e)
		return true
	await _say("O Nefasto escapou do feixe! (%d%% de %d%%)" % [int(meter * 100), int(need * 100)], 0.6)
	var tw := create_tween()
	tw.tween_method(func(v): e_mat.set_shader_parameter("flash", v), 0.8, 0.0, 0.3)
	return false


func _scan_success(e: Dictionary) -> void:
	Game.gain_elo(20 + int(e.get("rar", 0)) * 5)
	# o Nefasto é "digitalizado" de cima para baixo e sugado pelo Elo
	var elo_pos := Vector2(40, 250)
	var tw := create_tween()
	tw.tween_method(func(v):
		e_mat.set_shader_parameter("scan", v)
		if randf() < 0.6:
			var p := ColorRect.new()
			p.color = Color(0.4, 1.0, 0.6) if randf() < 0.7 else Color.WHITE
			p.size = Vector2(3, 3)
			p.position = Vector2(E_FEET.x + randf_range(-50, 50), lerpf(20, E_FEET.y, v))
			fx_layer.add_child(p)
			var pt := create_tween()
			pt.tween_property(p, "position", elo_pos, randf_range(0.4, 0.7)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			pt.tween_callback(p.queue_free)
	, 0.0, 1.1, 1.8)
	await tw.finished
	var elo := TextureRect.new()
	elo.texture = Game.tex("res://assets/items/elo_med.png")
	elo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	elo.size = Vector2(44, 48)
	elo.position = elo_pos - Vector2(22, 24)
	elo.pivot_offset = Vector2(22, 24)
	add_child(elo)
	var tw2 := create_tween()
	for i in 3:
		tw2.tween_property(elo, "rotation", 0.25, 0.08)
		tw2.tween_property(elo, "rotation", -0.25, 0.08)
	tw2.tween_property(elo, "rotation", 0.0, 0.08)
	await tw2.finished
	_burst(elo_pos, Color("5cff9c"), 40, 160.0)
	shake = 5.0
	e["nefasto"] = false
	e["hp"] = Game.max_hp(e)
	e["cd"] = {}
	var where := "entrou para a sua equipe" if Game.add_partner(e) == "equipe" else "foi para a Reserva"
	await _say("Nefasto purificado! %s %s!" % [Game.mon_name(e), where], 1.2)
	elo.queue_free()


func _process(delta: float) -> void:
	t += delta
	if world:
		if shake > 0.1:
			world.position = cam_off + Vector2(randf_range(-shake, shake), randf_range(-shake, shake)).round()
			shake *= 0.85
		else:
			world.position = cam_off
		if e_mat:
			e_mat.set_shader_parameter("t", t)
		_squash_step(e_spr, delta, 0.0)
		_squash_step(p_spr, delta, 1.7)


func _input(event: InputEvent) -> void:
	if def_active and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_def_press("dodge")
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_F and Game.tutorial["aparo"]:
			_def_press("parry")
			get_viewport().set_input_as_handled()
			return
	if qte_active and event is InputEventKey and event.pressed and not event.echo:
		var map := {KEY_UP: "up", KEY_W: "up", KEY_DOWN: "down", KEY_S: "down", KEY_LEFT: "left", KEY_A: "left", KEY_RIGHT: "right", KEY_D: "right"}
		if map.has(event.keycode):
			qte_hit = map[event.keycode] == qte_key
			qte_active = false
			get_viewport().set_input_as_handled()
			return
	if ring_active:
		if (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER]) or (event is InputEventMouseButton and event.pressed):
			ring_pressed = true
			get_viewport().set_input_as_handled()
	elif scan_mode and event is InputEventMouseMotion:
		lens_x = event.position.x


# ================================================================ defesa, especiais e eventos
## Telegrafia do ataque inimigo: um anel vermelho fecha sobre o seu monstro.
## ESPAÇO = desviar (janela larga) | F = aparar (janela curta, devolve um contra-ataque).
func _defense_qte(big: bool, dur_override := 0.0) -> String:
	var dur := 0.85 if big else 1.0
	if dur_override > 0.0:
		dur = dur_override
	var warn := Label.new()
	warn.text = "!"
	warn.add_theme_font_override("font", Game.font_title)
	warn.add_theme_font_size_override("font_size", 24)
	warn.add_theme_color_override("font_color", Color("ff5070"))
	warn.add_theme_color_override("font_outline_color", Color("2a1640"))
	warn.add_theme_constant_override("outline_size", 6)
	warn.position = E_FEET + Vector2(-8, -190)
	add_child(warn)
	e_mat.set_shader_parameter("flash_color", Color("ff3050"))
	var fl := create_tween()
	fl.tween_method(func(v): e_mat.set_shader_parameter("flash", v), 0.0, 0.6, dur * 0.5)
	fl.tween_method(func(v): e_mat.set_shader_parameter("flash", v), 0.6, 0.0, dur * 0.5)
	var ring := DefenseRing.new()
	ring.position = P_FEET + Vector2(0, -60)
	fx_layer.add_child(ring)
	var hint := _defense_buttons()
	# Árvore: Sentinela aumenta a janela de defesa
	var amp := (1.6 if Game.options.get("janela_ampla", false) else 1.0) * Game.skill_window(Game.team[p_i])
	DODGE_WIN = 0.22 * amp
	PARRY_WIN = 0.10 * amp
	def_kind = ""
	def_lock = 0.0
	def_active = true
	var start := Time.get_ticks_msec() / 1000.0
	def_time = start + dur  # momento do impacto
	while def_kind == "":
		var now := Time.get_ticks_msec() / 1000.0
		if now > def_time + DODGE_WIN:
			break
		ring.progress = clampf((now - start) / dur, 0.0, 1.0)
		def_now = absf(now - def_time) <= DODGE_WIN
		ring.now = def_now
		await get_tree().process_frame
	def_active = false
	def_now = false
	hint.queue_free()
	warn.queue_free()
	e_mat.set_shader_parameter("flash_color", Color.WHITE)
	ring.finish(def_kind != "")
	if def_kind == "":
		_float_text(P_FEET + Vector2(0, -150), "ATINGIDO", Color("ff8080"), 12)
	return def_kind


## O golpe do inimigo É o aviso: ele recua carregando, (às vezes finge) e avança.
## A janela de defesa é o instante exato em que o golpe encosta no seu Digialma.
func _strike(mk: String, dur: float, feint: bool, big: bool) -> String:
	var mv: Dictionary = Game.MOVES[mk]
	var col: Color = Game.TYPE_COLORS[mv["tipo"]]
	var home := E_FEET
	var contact: bool = mv["kind"] == "contato"
	var hit_pos := home.lerp(P_FEET, 0.62)
	if not allow_defense:
		# primeira batalha: o golpe só acontece
		await _strike_anim(mk, 0.7, false, contact, col, home, hit_pos)
		return ""
	msg.text = "%s vai atacar! Observe o ritmo..." % Game.mon_name(enemies[e_i])
	msg.visible_characters = -1
	var ring: DefenseRing = null
	if Game.battle_count <= 4 or Game.options.get("janela_ampla", false):
		ring = DefenseRing.new()
		ring.position = P_FEET + Vector2(0, -60)
		ring.modulate.a = 0.55
		fx_layer.add_child(ring)
	var hint := _defense_buttons()
	def_kind = ""
	def_lock = 0.0
	def_active = true
	var start := Time.get_ticks_msec() / 1000.0
	def_time = start + dur
	var anim_done := [false]
	var run_anim := func():
		await _strike_anim(mk, dur, feint, contact, col, home, hit_pos)
		anim_done[0] = true
	run_anim.call()
	while def_kind == "":
		var now := Time.get_ticks_msec() / 1000.0
		if now > def_time + DODGE_WIN:
			break
		if ring:
			ring.progress = clampf((now - start) / dur, 0.0, 1.0)
			def_now = absf(now - def_time) <= DODGE_WIN
			ring.now = def_now
		await get_tree().process_frame
	def_active = false
	def_now = false
	hint.queue_free()
	# espera o golpe "chegar" para a reação acontecer no contato
	while Time.get_ticks_msec() / 1000.0 < def_time:
		await get_tree().process_frame
	if ring:
		ring.finish(def_kind != "")
	match def_kind:
		"dodge":
			_defend_anim("dodge")
		"parry":
			_defend_anim("parry")
			_hitstop(0.08)
			shake = 5.0
			_burst(P_FEET + Vector2(30, -70), Color("fff3a8"), 26, 220.0)
			# o inimigo é empurrado pelo aparo
			create_tween().tween_property(e_spr, "position", hit_pos + Vector2(40, -6), 0.08)
		_:
			_float_text(P_FEET + Vector2(0, -150), "ATINGIDO", Color("ff8080"), 12)
	while not anim_done[0]:
		await get_tree().process_frame
	return def_kind


func _strike_anim(mk: String, dur: float, feint: bool, contact: bool, col: Color, home: Vector2, hit_pos: Vector2) -> void:
	var windup := maxf(0.12, dur - (0.14 if contact else 0.3))
	e_mat.set_shader_parameter("flash_color", col.lightened(0.3))
	# recua e carrega brilhando
	var back := home + Vector2(26, 4)
	var tw := create_tween().set_parallel(true)
	if feint:
		# finta: começa a avançar, para e volta a carregar
		var ft := create_tween()
		ft.tween_property(e_spr, "position", home.lerp(hit_pos, 0.18), windup * 0.28).set_trans(Tween.TRANS_QUAD)
		ft.tween_property(e_spr, "position", back + Vector2(8, 0), windup * 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		ft.tween_interval(windup * 0.37)
		_squash(e_spr, 0.12)
	else:
		tw.tween_property(e_spr, "position", back, windup).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v): e_mat.set_shader_parameter("flash", v), 0.0, 0.55, windup)
	if not feint:
		_squash(e_spr, 0.16)
	var charge := CPUParticles2D.new()
	charge.position = home + Vector2(0, -60)
	charge.amount = 18
	charge.lifetime = 0.4
	charge.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	charge.emission_sphere_radius = 30.0
	charge.gravity = Vector2.ZERO
	charge.radial_accel_min = -140.0
	charge.radial_accel_max = -100.0
	charge.scale_amount_min = 1.5
	charge.scale_amount_max = 2.5
	charge.color = col.lightened(0.2)
	fx_layer.add_child(charge)
	await get_tree().create_timer(windup).timeout
	charge.emitting = false
	charge.get_tree().create_timer(0.5).timeout.connect(charge.queue_free)
	e_mat.set_shader_parameter("flash", 0.0)
	e_spr.play("attack")
	e_spr.animation_finished.connect(func(): e_spr.play("idle"), CONNECT_ONE_SHOT)
	var rest := dur - windup
	if contact:
		_squash(e_spr, -0.2)
		await create_tween().tween_property(e_spr, "position", hit_pos, rest).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).finished
	else:
		var orb := Orb.new()
		orb.col = col
		orb.position = home + Vector2(-10, -80)
		fx_layer.add_child(orb)
		_burst(orb.position, col, 12, 60.0)
		await create_tween().tween_property(orb, "position", P_FEET + Vector2(0, -70), rest).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).finished
		orb.queue_free()
	await get_tree().create_timer(0.12).timeout
	e_mat.set_shader_parameter("flash_color", Color.WHITE)
	create_tween().tween_property(e_spr, "position", home, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Cada toque é avaliado na hora. Cedo demais = trava curtinha (0,3 s) e pode tentar de novo.
func _def_press(kind: String) -> void:
	if not def_active or def_kind != "":
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now < def_lock:
		return
	var d := now - def_time
	var win := PARRY_WIN if kind == "parry" else DODGE_WIN
	if absf(d) <= win:
		def_kind = kind
	elif kind == "parry" and absf(d) <= DODGE_WIN:
		def_kind = "dodge"  # errou o aparo por pouco: vira uma esquiva
	elif d < 0.0:
		def_lock = now + 0.3
		_float_text(P_FEET + Vector2(0, -150), "CEDO!", Color("ff8080"), 12)


func _defense_buttons() -> Control:
	var box := HBoxContainer.new()
	box.position = Vector2(170, 252)
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var opts := [["DESVIAR  [ESPAÇO]", "dodge"]]
	if Game.tutorial["aparo"]:
		opts.append(["APARAR  [F]", "parry"])
	for k in opts:
		var b := Button.new()
		b.text = k[0]
		b.custom_minimum_size = Vector2(140, 26)
		b.focus_mode = Control.FOCUS_NONE
		var kind: String = k[1]
		b.button_down.connect(func(): _def_press(kind))
		box.add_child(b)
	return box


func _defend_anim(kind: String) -> void:
	var base := p_spr.position
	var tw := create_tween()
	if kind == "dodge":
		tw.tween_property(p_spr, "position", base + Vector2(-60, -14), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.4)
		tw.tween_property(p_spr, "position", base, 0.2)
	else:
		tw.tween_property(p_spr, "position", base + Vector2(16, 0), 0.08)
		tw.tween_property(p_spr, "position", base, 0.15)


func _counter(full := false) -> void:
	var p: Dictionary = Game.team[p_i]
	await _say("Contra-ataque de %s!" % Game.mon_name(p), 0.1)
	var mk: String = Game.moves_of(p)[0]
	var mv: Dictionary = Game.MOVES[mk]
	p_spr.play("attack")
	p_spr.animation_finished.connect(func(): p_spr.play("idle"), CONNECT_ONE_SHOT)
	var back := p_spr.position
	await create_tween().tween_property(p_spr, "position", back.lerp(E_FEET, 0.6), 0.12).finished
	_impact(E_FEET + Vector2(0, -70), mv, true)
	create_tween().tween_property(p_spr, "position", back, 0.2)
	var dmg := int(round(_damage(p, enemies[e_i], mv, true) * (1.4 if full else 0.8)))
	enemies[e_i]["hp"] -= dmg
	_hit_feedback(e_spr, e_mat, dmg, E_FEET, true, true)
	_refresh_boxes()
	await get_tree().create_timer(0.6).timeout


func _elo_talk(lines: Array) -> void:
	if tdialog == null:
		tdialog = Dialog.new()
		add_child(tdialog)
	move_child(tdialog, -1)
	await tdialog.play(lines)


func _energy(n: int) -> void:
	var before := energy
	energy = clampi(energy + n, 0, Game.ENERGY_MAX)
	if energy > before:
		_float_text(Vector2(540, 300), "+%d ENERGIA" % (energy - before), Color("58e0ff"), 10)
	_refresh_boxes()


## Soma sincronia e vínculo (fur = Fúria, gua = Guarda) do Digialma em campo.
func _gain(amount: float, bond: String, pts: int) -> void:
	if fusing:
		return
	var before := sync
	if Game.has_skill(Game.team[p_i], "v2"):
		amount *= 1.15  # Árvore: Laço
	amount *= 1.0 + Game.gear_bonus(Game.team[p_i], "sinc")
	sync = minf(100.0, sync + amount)
	if sync_bar:
		create_tween().tween_property(sync_bar, "value", sync, 0.25)
	if bond != "" and pts > 0:
		var p: Dictionary = Game.team[p_i]
		p[bond] = p.get(bond, 0) + pts
		_refresh_boxes()
	if before < 100.0 and sync >= 100.0:
		_float_text(Vector2(512, 196), "SINCRONIA MÁXIMA!", Color("ffd84a"), 14)
		_burst(Vector2(512, 250), Color("ffd84a"), 24, 90.0)
		var tw := sync_bar.create_tween().set_loops(4)
		tw.tween_property(sync_bar, "modulate", Color(1.6, 1.4, 0.8), 0.15)
		tw.tween_property(sync_bar, "modulate", Color.WHITE, 0.15)


## FUSÃO DE ALMA: a criança vira luz e se funde ao Digialma por um golpe.
func _fusion() -> bool:
	fusing = true
	var p: Dictionary = Game.team[p_i]
	var e: Dictionary = enemies[e_i]
	_clear_grid()
	if not Game.tutorial["fusao"] and _tips():
		Game.tutorial["fusao"] = true
		await _elo_talk([["elo", "Vocês estão em sintonia total... Deixe sua alma entrar no Elo. FUSÃO!"]])
	msg.text = ""
	# escurece e aproxima
	var dark := ColorRect.new()
	dark.color = Color(0.02, 0.0, 0.06, 0.0)
	dark.size = Game.BASE
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(dark)
	world.move_child(dark, 2)
	create_tween().tween_property(dark, "color:a", 0.75, 0.4)
	_cam_to(P_FEET + Vector2(-20, -60), 1.35, 0.5)
	# a criança aparece atrás do parceiro
	var kid := AnimatedSprite2D.new()
	kid.sprite_frames = Game.char_frames(Game.player_char)
	kid.play("idle_right")
	kid.centered = false
	kid.offset = Vector2(-64, -128)
	kid.position = P_FEET + Vector2(-70, 4)
	kid.modulate.a = 0.0
	kid.material = Game.sprite_mat()
	world.add_child(kid)
	world.move_child(kid, p_spr.get_index())
	var kmat := kid.material as ShaderMaterial
	await create_tween().tween_property(kid, "modulate:a", 1.0, 0.35).finished
	var lbl := Label.new()
	Game.heading(lbl, "%s  +  %s" % [Game.player_name, Game.mon_name(p)], 14)
	lbl.add_theme_color_override("font_color", Color("fff3a8"))
	lbl.add_theme_color_override("font_outline_color", Color("2a1640"))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = Vector2(640, 20)
	lbl.position = Vector2(0, 92)
	add_child(lbl)
	# os dois brilham em pulsos cada vez mais rápidos
	kmat.set_shader_parameter("flash_color", Color("fff3a8"))
	p_mat.set_shader_parameter("flash_color", Color("fff3a8"))
	var d := 0.3
	for i in 5:
		kmat.set_shader_parameter("flash", 1.0)
		p_mat.set_shader_parameter("flash", 0.7)
		_burst(P_FEET + Vector2(-35, -60), Color("ffd84a"), 8, 60.0, true)
		await get_tree().create_timer(d * 0.5).timeout
		kmat.set_shader_parameter("flash", 0.3)
		p_mat.set_shader_parameter("flash", 0.0)
		await get_tree().create_timer(d * 0.5).timeout
		d *= 0.75
	# a criança vira luz e entra no parceiro
	kmat.set_shader_parameter("flash", 1.0)
	var fl := create_tween().set_parallel(true)
	fl.tween_property(kid, "position", P_FEET + Vector2(0, -10), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fl.tween_property(kid, "scale", Vector2(0.1, 0.1), 0.35)
	fl.tween_property(kid, "modulate:a", 0.0, 0.35)
	_burst(P_FEET + Vector2(0, -60), Color("fff3a8"), 40, 140.0, true)
	await fl.finished
	kid.queue_free()
	# clarão
	var white := ColorRect.new()
	white.color = Color(1, 1, 0.9, 1.0)
	white.size = Game.BASE
	white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(white)
	shake = 8.0
	p_spr.set_meta("noscale", true)
	p_spr.scale = Vector2(2.5, 2.5)
	p_mat.set_shader_parameter("flash", 0.35)
	var aura := CPUParticles2D.new()
	aura.position = Vector2(0, -30)
	aura.amount = 50
	aura.lifetime = 0.7
	aura.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	aura.emission_sphere_radius = 22.0
	aura.direction = Vector2(0, -1)
	aura.spread = 25.0
	aura.gravity = Vector2(0, -80)
	aura.initial_velocity_min = 10.0
	aura.initial_velocity_max = 40.0
	aura.scale_amount_min = 1.0
	aura.scale_amount_max = 2.0
	var g := Gradient.new()
	g.set_color(0, Color("fff3a8"))
	g.set_color(1, Color(1, 0.7, 0.2, 0.0))
	aura.color_ramp = g
	p_spr.add_child(aura)
	create_tween().tween_property(white, "color:a", 0.0, 0.5)
	_float_text(Vector2(320, 120), "FUSÃO DE ALMA!", Color("ffd84a"), 26)
	await get_tree().create_timer(0.8).timeout
	lbl.queue_free()
	# golpe fundido: avança e acerta com o melhor golpe, amplificado
	var best: String = Game.moves_of(p)[0]
	for mk in Game.moves_of(p):
		if Game.MOVES[mk]["poder"] > Game.MOVES[best]["poder"]:
			best = mk
	var mv: Dictionary = Game.MOVES[best]
	_cam_to(Vector2(320, 150), 1.0, 0.3)
	var back := p_spr.position
	p_spr.play("attack")
	var dash := create_tween()
	dash.tween_property(p_spr, "position", back + Vector2(-20, 6), 0.15)
	dash.tween_property(p_spr, "position", E_FEET + Vector2(-60, 10), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await dash.finished
	_impact(E_FEET + Vector2(0, -70), mv, true)
	_burst(E_FEET + Vector2(0, -70), Color("ffd84a"), 60, 260.0)
	Engine.time_scale = 0.25
	await get_tree().create_timer(0.3, true, false, true).timeout
	Engine.time_scale = 1.0
	var dmg := int(round(_damage(p, e, mv, true) * 2.6))
	e["hp"] -= dmg
	_hit_feedback(e_spr, e_mat, dmg, E_FEET, true, true)
	shake = 12.0
	_refresh_boxes()
	await create_tween().tween_property(p_spr, "position", back, 0.3).finished
	p_spr.play("idle")
	# volta ao normal
	aura.emitting = false
	var rv := create_tween().set_parallel(true)
	rv.tween_property(p_spr, "scale", Vector2(2, 2), 0.4)
	rv.tween_property(dark, "color:a", 0.0, 0.4)
	rv.tween_method(func(v): p_mat.set_shader_parameter("flash", v), 0.35, 0.0, 0.4)
	await rv.finished
	p_spr.set_meta("noscale", false)
	dark.queue_free()
	white.queue_free()
	aura.queue_free()
	sync = 0.0
	sync_bar.value = 0
	p["fur"] = p.get("fur", 0) + 1
	p["gua"] = p.get("gua", 0) + 1
	fusing = false
	_refresh_boxes()
	await _say("%s e %s lutaram como uma só alma! (%d de dano)" % [Game.player_name, Game.mon_name(p), dmg], 0.6)
	return e["hp"] <= 0


func _tips() -> bool:
	return Game.options.get("dicas", true)


## Lições de defesa espalhadas: esquiva na 2ª batalha, aparo na 3ª.
func _defense_lessons() -> void:
	if not allow_defense:
		return
	if not Game.tutorial["esquiva"]:
		Game.tutorial["esquiva"] = true
		if _tips():
			await _elo_talk([["elo", "Cuidado, ele vai atacar! Olhe para ELE: primeiro recua e brilha, carregando o golpe."], ["elo", "Aperte DESVIAR (espaço ou o botão) no instante em que o golpe ENCOSTAR em você. Treina comigo, bem devagar!"]])
			await _say("TREINO: espere ele avançar e aperte DESVIAR no contato!", 0.2)
			var r := await _strike(Game.moves_of(enemies[e_i])[0], 1.9, false, false)
			if r != "":
				_float_text(P_FEET + Vector2(0, -150), "BOA!", Color("7affc1"), 18)
			await get_tree().create_timer(0.5).timeout
		return
	if not Game.tutorial["aparo"] and Game.battle_count >= 3:
		Game.tutorial["aparo"] = true
		if _tips():
			await _elo_talk([["elo", "Novo truque: APARAR (F ou o botão). A janela é bem curta, bem no instante do verde."], ["elo", "Se acertar, você anula o golpe e CONTRA-ATACA na hora!"]])


func _help() -> void:
	await _elo_talk([
		["elo", "ATAQUE: aperte quando o anel dourado encostar no círculo do inimigo."],
		["elo", "DEFESA: observe o inimigo. Ele recua brilhando e avança: aperte no CONTATO. Cuidado com as fintas!"],
		["elo", "DESVIAR (espaço) é fácil. APARAR (F) é bem no instante, gera ENERGIA e, aparando tudo, contra-ataca."],
		["elo", "Cada espécie tem seu ritmo. Aprenda o de cada uma!"],
		["elo", "SINCRONIA: acertos perfeitos, esquivas e aparos enchem a barra dourada. Cheia, libera a FUSÃO DE ALMA!"],
		["elo", "ESPECIAIS: aperte as 4 setas na ordem. ESCANEAR: deixe ele com menos da metade da vida e segure a lente nele."],
	])


## Combo de ataque: uma sequência de anéis, cada vez mais rápidos.
## Cada acerto é um golpe; errar encerra o combo. Acertar todos = CRÍTICO no último.
## Golpe de suporte: Luz Vital cura o Digialma ativo.
func _heal_move(mk: String) -> void:
	var p: Dictionary = Game.team[p_i]
	energy -= Game.move_cost(mk)
	_clear_grid()
	msg.text = "%s usou %s!" % [Game.mon_name(p), Game.MOVES[mk]["nome"]]
	var amt := maxi(int(Game.max_hp(p) * Game.MOVES[mk]["cura"]), Game.heal_amount(p, p) * 3)
	p["hp"] = mini(Game.max_hp(p), int(p["hp"]) + amt)
	_burst(P_FEET + Vector2(0, -60), Color("6fe08a"), 30, 90.0, true)
	_float_text(P_FEET + Vector2(0, -120), "+%d" % amt, Color("6fe08a"))
	_refresh_boxes()
	await get_tree().create_timer(0.8).timeout


func _attack_combo(mk: String) -> bool:
	var p: Dictionary = Game.team[p_i]
	var n := 1
	if intense:
		n = 2 if p["lv"] < 8 else 3
		if not Game.tutorial["combo"] and _tips():
			Game.tutorial["combo"] = true
			await _elo_talk([["elo", "Esse é forte! Agora o ataque vira COMBO: vários anéis seguidos, cada um mais rápido."], ["elo", "Acerte todos e o último sai CRÍTICO. Errou um, o combo para ali."]])
	var durs := [1.0, 0.8, 0.65]
	_clear_grid()
	if n == 1:
		msg.text = "Aperte quando o anel encostar no círculo dourado!"
		var hit := await _ring(1.0)
		_energy(2 if hit else 1)
		if hit:
			_gain(12, "fur", 1)
		return await _do_move(true, mk, hit, "", 1.0 if hit else 0.75, 0)
	msg.text = "COMBO x%d! Aperte quando o anel encostar no círculo dourado." % n
	_float_text(E_FEET + Vector2(110, -120), "COMBO x%d" % n, Color("bff6ff"), 14)
	_energy(1)
	for i in n:
		var ok := await _ring(durs[i])
		if ok:
			_energy(1)
		if not ok:
			if i == 0:
				# errou o primeiro: ainda sai um golpe fraco
				return await _do_move(true, mk, false, "", 0.6, 0)
			_float_text(E_FEET + Vector2(0, -150), "COMBO x%d" % i, Color("bff6ff"), 14)
			return false
		var last := i == n - 1
		_gain(10, "fur", 1 if last else 0)
		if last:
			_float_text(E_FEET + Vector2(0, -190), "CRÍTICO!", Color("ff5070"), 22)
			shake = 6.0
			_gain(12, "fur", 1)
		var ko := await _do_move(true, mk, last, "", 0.55, i)
		if ko:
			return true
	return false


## Câmera da batalha: aproxima e enquadra um ponto (zoom 1 = normal).
var cam_f := Vector2(320, 180)
var cam_z := 1.0
var cam_off := Vector2.ZERO

func _cam_apply() -> void:
	# o ponto focado vai em direção ao centro da tela conforme o zoom aumenta
	var center := Game.BASE * 0.5
	var screen_pt := cam_f.lerp(center, clampf((cam_z - 1.0) * 2.0, 0.0, 0.6))
	var off := screen_pt - cam_f * cam_z
	# nunca mostrar a borda do fundo (660x372 em -10,-6)
	off.x = clampf(off.x, 640.0 - 650.0 * cam_z, 10.0 * cam_z)
	off.y = clampf(off.y, 360.0 - 366.0 * cam_z, 6.0 * cam_z)
	world.scale = Vector2(cam_z, cam_z)
	cam_off = off if cam_z > 1.001 else Vector2.ZERO
	world.position = cam_off


func _cam_to(focus: Vector2, zoom: float, t: float) -> void:
	var f0 := cam_f
	var z0 := cam_z
	var tw := create_tween()
	tw.tween_method(func(k: float):
		cam_f = f0.lerp(focus, k)
		cam_z = lerpf(z0, zoom, k)
		_cam_apply(), 0.0, 1.0, t).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


## Erupção: o chão racha do atacante até o alvo, gêiseres de lava sobem em sequência
## e o alvo explode em câmera lenta.
func _erupcao_fx(from: Vector2, to: Vector2) -> void:
	var tint := ColorRect.new()
	tint.color = Color(1.0, 0.25, 0.05, 0.0)
	tint.size = Game.BASE
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(tint)
	world.move_child(tint, 2)
	create_tween().tween_property(tint, "color:a", 0.28, 0.3)
	_cam_to(from.lerp(to, 0.5) + Vector2(0, -40), 1.15, 0.4)
	# rachadura
	var crack := Line2D.new()
	crack.width = 4.0
	crack.default_color = Color("ffb030")
	crack.begin_cap_mode = Line2D.LINE_CAP_ROUND
	fx_layer.add_child(crack)
	var glow := Line2D.new()
	glow.width = 14.0
	glow.default_color = Color(1, 0.35, 0.05, 0.45)
	fx_layer.add_child(glow)
	fx_layer.move_child(glow, crack.get_index())
	var steps := 14
	for i in steps + 1:
		var k := float(i) / steps
		var pt := from.lerp(to, k) + Vector2(randf_range(-6, 6), randf_range(-5, 5))
		crack.add_point(pt)
		glow.add_point(pt)
		shake = 2.0
		if i % 4 == 2:
			_geyser(pt)
		await get_tree().create_timer(0.025).timeout
	_geyser(to)
	_geyser(to + Vector2(-26, 4))
	_geyser(to + Vector2(26, 4))
	await get_tree().create_timer(0.15).timeout
	# câmera lenta no impacto
	_cam_to(to + Vector2(0, -60), 1.35, 0.12)
	Engine.time_scale = 0.3
	await get_tree().create_timer(0.35, true, false, true).timeout
	Engine.time_scale = 1.0
	shake = 10.0
	var tw := create_tween()
	tw.tween_property(tint, "color:a", 0.0, 0.8)
	tw.parallel().tween_property(crack, "modulate:a", 0.0, 1.0)
	tw.parallel().tween_property(glow, "modulate:a", 0.0, 1.0)
	tw.tween_callback(func():
		tint.queue_free()
		crack.queue_free()
		glow.queue_free())


func _geyser(at: Vector2) -> void:
	var g := CPUParticles2D.new()
	g.position = at
	g.amount = 70
	g.lifetime = 0.8
	g.one_shot = true
	g.explosiveness = 0.85
	g.direction = Vector2(0, -1)
	g.spread = 10.0
	g.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	g.emission_rect_extents = Vector2(6, 2)
	g.initial_velocity_min = 220.0
	g.initial_velocity_max = 360.0
	g.gravity = Vector2(0, 520)
	g.scale_amount_min = 4.0
	g.scale_amount_max = 9.0
	var gr := Gradient.new()
	gr.set_color(0, Color("ffd040"))
	gr.add_point(0.25, Color("ff5a10"))
	gr.add_point(0.7, Color("c01a08"))
	gr.set_color(gr.get_point_count() - 1, Color(0.3, 0.02, 0.0, 0.0))
	g.color_ramp = gr
	fx_layer.add_child(g)
	g.emitting = true
	g.finished.connect(g.queue_free)
	_burst(at, Color("ff5a1a"), 8, 60.0)


## Golpe especial: sequência de 4 setas. Cada acerto aumenta o poder.
func _special_qte() -> float:
	var arrows := ["up", "down", "left", "right"]
	var glyph := {"up": "▲", "down": "▼", "left": "◀", "right": "▶"}
	var box := HBoxContainer.new()
	box.position = Vector2(200, 120)
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var seq: Array = []
	var labels: Array = []
	for i in 4:
		var k: String = arrows[randi() % 4]
		seq.append(k)
		var b := Button.new()
		b.text = {"up": "CIMA", "down": "BAIXO", "left": "ESQ", "right": "DIR"}[k]
		b.custom_minimum_size = Vector2(52, 34)
		b.focus_mode = Control.FOCUS_NONE
		b.modulate = Color(1, 1, 1, 0.5)
		var kk := k
		b.button_down.connect(func():
			if qte_active:
				qte_hit = kk == qte_key
				qte_active = false)
		box.add_child(b)
		labels.append(b)
	var title := Label.new()
	title.text = "GOLPE ESPECIAL! Aperte as setas na ordem!"
	title.add_theme_color_override("font_color", Color("ffd84a"))
	title.add_theme_color_override("font_outline_color", Color("2a1640"))
	title.add_theme_constant_override("outline_size", 6)
	title.position = Vector2(170, 96)
	add_child(title)
	var hits := 0
	for i in 4:
		var b: Button = labels[i]
		b.modulate = Color.WHITE
		b.pivot_offset = Vector2(26, 17)
		b.scale = Vector2(1.25, 1.25)
		qte_key = seq[i]
		qte_hit = false
		qte_active = true
		var start := Time.get_ticks_msec()
		while qte_active and Time.get_ticks_msec() - start < 900:
			await get_tree().process_frame
		qte_active = false
		b.scale = Vector2.ONE
		if qte_hit:
			hits += 1
			b.add_theme_color_override("font_color", Color("5cff9c"))
			_burst(b.global_position + Vector2(26, 17), Color("5cff9c"), 10, 60.0)
		else:
			b.add_theme_color_override("font_color", Color("ff5070"))
	await get_tree().create_timer(0.25).timeout
	box.queue_free()
	title.queue_free()
	if hits == 4:
		_float_text(Vector2(320, 90), "PERFEITO!", Color("ffd84a"), 22)
		shake = 6.0
		_gain(20, "fur", 2)
	else:
		_gain(hits * 3, "", 0)
	return 0.8 + 0.15 * hits


## Evento: o Nefasto acumula Ruído. Cause dano suficiente em 2 turnos ou ele explode.
func _maybe_ruido_event() -> void:
	var e: Dictionary = enemies[e_i]
	if ruido_used or not intense or not e.get("nefasto", false) or turn < 2 or randf() > 0.5:
		return
	ruido_used = true
	e["charge"] = 3
	e["charge_dmg"] = 0
	e["charge_need"] = int(Game.max_hp(e) * 0.3)
	_burst(E_FEET + Vector2(0, -70), Color("b050ff"), 40, 90.0, true)
	shake = 4.0
	await _say("%s começou a acumular RUÍDO! Cause %d de dano em 2 turnos para quebrar!" % [Game.mon_name(e), e["charge_need"]], 1.0)


# ================================================================ classes de efeito
class Platforms extends Node2D:
	var region_name := ""

	func _draw() -> void:
		var pal := {"arena_plant": [Color("4f8a3a"), Color("79b84e"), Color("a6dc78")],
			"arena_water": [Color("c9a160"), Color("e8c88a"), Color("fff0c0")],
			"arean_fire": [Color("5a2a2a"), Color("8a3f30"), Color("c86a40")],
			"pantano": [Color("2a3a2a"), Color("44583a"), Color("6a8a4a")],
			"cobre": [Color("5a3a22"), Color("8a5a30"), Color("c8884a")],
			"cristal": [Color("6a5a8a"), Color("a090c8"), Color("d8d0f8")]}
		var c: Array = pal.get(region_name, pal["arena_plant"])
		for p in [[E_FEET, 92.0], [P_FEET, 104.0]]:
			_ell(p[0] + Vector2(0, 2), p[1] + 6, 16, c[0])
			_ell(p[0], p[1], 14, c[1])
			_ell(p[0] + Vector2(-8, -3), p[1] * 0.7, 7, c[2])
			_ell(p[0] + Vector2(0, 2), 34, 6, Color(0, 0, 0, 0.22))

	func _ell(cen: Vector2, rx: float, ry: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 28:
			var a := TAU * i / 28.0
			pts.append((cen + Vector2(cos(a) * rx, sin(a) * ry)).round())
		draw_colored_polygon(pts, col)


class Orb extends Node2D:
	var col := Color.WHITE
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 16 + sin(t * 30.0) * 2.0, Color(col, 0.25))
		draw_circle(Vector2.ZERO, 10, Color(col, 0.7))
		draw_circle(Vector2.ZERO, 5, Color.WHITE)


class RingFx extends Node2D:
	const TARGET := 22.0
	var progress := 0.0
	var result := -1

	func radius() -> float:
		return lerpf(80.0, 0.0, progress)

	func _process(_d: float) -> void:
		queue_redraw()

	func finish(perfect: bool) -> void:
		result = 1 if perfect else 0
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector2(1.5, 1.5) if perfect else Vector2(0.6, 0.6), 0.2)
		tw.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
		tw.tween_callback(queue_free)

	func _draw() -> void:
		var ok := absf(radius() - TARGET) <= 7.0
		draw_arc(Vector2.ZERO, TARGET, 0, TAU, 40, Color("ffd84a"), 3.0)
		draw_arc(Vector2.ZERO, radius(), 0, TAU, 48, Color("5cff9c") if ok else Color.WHITE, 3.0)
		if result == 1:
			draw_circle(Vector2.ZERO, TARGET, Color(1, 0.9, 0.4, 0.4))


class DefenseRing extends Node2D:
	var progress := 0.0
	var now := false

	func _process(_d: float) -> void:
		queue_redraw()

	func finish(ok: bool) -> void:
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector2(1.4, 1.4) if ok else Vector2(0.6, 0.6), 0.18)
		tw.parallel().tween_property(self, "modulate:a", 0.0, 0.22)
		tw.tween_callback(queue_free)

	func _draw() -> void:
		var r := lerpf(90.0, 26.0, progress)
		draw_arc(Vector2.ZERO, 26.0, 0, TAU, 40, Color("7affc1"), 5.0 if now else 3.0)
		draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color("ff5070"), 3.0)
		if now:
			draw_circle(Vector2.ZERO, 26.0, Color(0.5, 1, 0.75, 0.35))


class ScanUI extends Control:
	var lens := 0.0
	var beam := 0.0
	var meter := 0.0
	var need := 0.5
	var on := false
	var prog := 0.0

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		size = Game.BASE
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func update(l: float, b: float, m: float, n: float, o: bool, p: float) -> void:
		lens = l
		beam = b
		meter = m
		need = n
		on = o
		prog = p
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 640, 360), Color(0.0, 0.08, 0.04, 0.25))
		# feixe horizontal descendo
		draw_rect(Rect2(300, beam - 2, 340, 4), Color(0.4, 1.0, 0.6, 0.9))
		draw_rect(Rect2(300, beam - 10, 340, 20), Color(0.4, 1.0, 0.6, 0.18))
		# lente (colchetes) controlada pelo jogador
		var c := Color("5cff9c") if on else Color("ff6080")
		var x := lens
		for s in [-1, 1]:
			draw_rect(Rect2(x + s * 30 - 1, 20, 3, 180), c)
			draw_rect(Rect2(x + s * 30 - (6 if s > 0 else 0), 20, 8, 3), c)
			draw_rect(Rect2(x + s * 30 - (6 if s > 0 else 0), 197, 8, 3), c)
		# medidor
		var mx := 30.0
		var my := 70.0
		draw_rect(Rect2(mx - 2, my - 2, 24, 164), Color("120c24"))
		draw_rect(Rect2(mx, my, 20, 160), Color("231f4a"))
		draw_rect(Rect2(mx, my + 160 * (1.0 - meter), 20, 160 * meter), Color("5cff9c") if meter >= need else Color("3bd6c6"))
		draw_rect(Rect2(mx - 6, my + 160 * (1.0 - need) - 1, 32, 3), Color("ffd84a"))
		draw_string(Game.font, Vector2(mx - 12, my - 8), "SINCRONIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
		draw_rect(Rect2(20, 250, 120 * (1.0 - prog), 4), Color("ffd84a"))
