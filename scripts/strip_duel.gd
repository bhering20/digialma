extends Node2D
## DUELO NA FAIXA: batalha completa dentro da faixa do idle, só com símbolos.
## Ataque: escolha o golpe (ícones) e clique quando o anel fechar no inimigo.
## Defesa: quando o anel fechar no seu Digialma, clique (no tempo = desvia,
## perfeito = apara e contra-ataca). Captura: LAÇO DE ALMA, um ritual de ritmo
## que só aparece com o inimigo enfraquecido.

const UI := "res://assets/ui/idle_%s.png"
const TYPE_ICON := {"Normal": "tipo_normal", "Fogo": "tipo_fogo", "Água": "tipo_agua", "Planta": "tipo_planta", "Voador": "tipo_voador", "Gelo": "tipo_gelo", "Psíquico": "tipo_psiquico", "Elétrico": "tipo_eletrico", "Inseto": "tipo_inseto"}
const SW := 640.0
const SH := 96.0
const GROUND := 80.0

var host  # idle.gd
var e: Dictionary
var lead: Dictionary
var m: AnimatedSprite2D
var mat: ShaderMaterial
var pet: AnimatedSprite2D
var energy := 1
var sync := 0.0
var laco_tries := 0
const MAX_TRIES := 2
var elo_gain := 0
var auto := false  # testes: joga sozinho
var auto_miss := false
## Desafio do Santuário: sem captura, vida continua entre os Digialmas do
## líder, e quem arruma o grupo no fim é a faixa.
var boss := false
var keep_hp := false
var restore := true
var enter_x := SW + 40.0

var e_bar: MiniBar
var p_bar: MiniBar
var s_bar: MiniBar
var pips: Pips
var catcher: Button
var clicked := false
var pick := {}
var saved := {}


func _ready() -> void:
	set_process_input(true)


func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_SPACE:
		clicked = true


# ---------------------------------------------------------------- fluxo
func run() -> String:
	lead = Game.team[0]
	if not keep_hp:
		lead["hp"] = Game.max_hp(lead)
	e["hp"] = Game.max_hp(e)
	if e.has("debug_hp"):
		e["hp"] = int(Game.max_hp(e) * e["debug_hp"])
	pet = host.pets[0]
	if pet.material == null:
		pet.material = Game.sprite_mat()
	await _setup()
	var result := ""
	while result == "":
		var act: Dictionary = await _choose()
		match act["t"]:
			"move":
				await _player_attack(act["mk"])
			"fusao":
				await _fusion()
			"laco":
				if await _laco():
					result = "caught"
					break
				if laco_tries >= MAX_TRIES:
					# duas falhas: ele escapa da luta
					result = "escaped"
					break
			"fugir":
				result = "run"
				break
		if e["hp"] <= 0:
			result = "win"
			break
		await get_tree().create_timer(0.35).timeout
		await _enemy_attack()
		if lead["hp"] <= 0:
			result = "lose"
	elo_gain += {"win": 12, "caught": 25, "escaped": 5, "run": 0, "lose": 3}.get(result, 0) + int(e.get("rar", 0)) * 2
	await _teardown(result)
	return result


func _setup() -> void:
	# guarda posições e abre espaço: o parceiro vai à frente, o resto recua
	for p in host.pets:
		saved[p] = p.position
	saved[host.kid] = host.kid.position
	create_tween().tween_property(host.kid, "position:x", 196.0, 0.4)
	for i in range(1, host.pets.size()):
		var t := create_tween()
		t.tween_property(host.pets[i], "position:x", 150.0 - i * 26.0, 0.4)
		t.parallel().tween_property(host.pets[i], "modulate:a", 0.45, 0.4)
	create_tween().tween_property(pet, "position:x", 262.0, 0.4)
	# o Nefasto chega
	m = AnimatedSprite2D.new()
	m.sprite_frames = Game.monster_frames(e["id"])
	m.play("idle")
	m.centered = false
	m.offset = Game.foot_offset(e["id"])
	m.material = Game.sprite_mat()
	mat = m.material as ShaderMaterial
	mat.set_shader_parameter("nefasto", 1.0)
	var bs := 0.5 if Game.FOOT[e["id"]] > 85 else 0.66
	m.scale = Vector2(bs, bs)
	m.flip_h = false
	m.position = Vector2(enter_x, GROUND)
	host.stage.add_child(m)
	var aura = Glow.new()
	aura.col = Game.rar_color(int(e.get("rar", 0)))
	host.stage.add_child(aura)
	m.tree_exiting.connect(aura.queue_free)
	var tw := create_tween()
	tw.tween_property(m, "position:x", 372.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	while tw.is_running():
		aura.position = m.position + Vector2(0, -18)
		await get_tree().process_frame
	aura.position = m.position + Vector2(0, -18)
	# rugido: tremida + "!"
	host._pop_text(m.position + Vector2(-2, -50), "!", Game.rar_color(int(e.get("rar", 0))))
	await _shake(3.0, 0.3)
	# barras
	e_bar = MiniBar.new()
	e_bar.col = Color("ff5a6a")
	e_bar.position = m.position + Vector2(-18, -50)
	host.add_child(e_bar)
	p_bar = MiniBar.new()
	p_bar.col = Color("6fe08a")
	p_bar.position = pet.position + Vector2(-18, -44)
	host.add_child(p_bar)
	s_bar = MiniBar.new()
	s_bar.col = Color("c070ff")
	s_bar.h = 2
	s_bar.ratio = 0.0
	s_bar.position = p_bar.position + Vector2(0, 5)
	host.add_child(s_bar)
	pips = Pips.new()
	pips.position = p_bar.position + Vector2(0, 9)
	host.add_child(pips)
	catcher = Button.new()
	catcher.flat = true
	catcher.focus_mode = Control.FOCUS_NONE
	catcher.size = Vector2(SW, SH)
	catcher.visible = false
	catcher.button_down.connect(func(): clicked = true)
	host.add_child(catcher)
	_bars()


func _teardown(result: String) -> void:
	for n in [e_bar, p_bar, s_bar, pips, catcher]:
		if is_instance_valid(n):
			n.queue_free()
	match result:
		"win":
			await host._purify_fx(m, mat)
		"caught":
			m.queue_free()
		"escaped":
			host._burst(m.position + Vector2(0, -20), Color("b050ff"), 12)
			await create_tween().tween_property(m, "position:y", m.position.y - 10, 0.12).set_trans(Tween.TRANS_QUAD).finished
			await create_tween().tween_property(m, "position:y", GROUND, 0.12).finished
			await create_tween().tween_property(m, "position:x", SW + 60.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).finished
			m.queue_free()
		_:
			# o Nefasto foge (ou você foge)
			await create_tween().tween_property(m, "position:x", SW + 60.0, 0.5).finished
			m.queue_free()
	if restore:
		for p in saved:
			if is_instance_valid(p):
				var t := create_tween()
				t.tween_property(p, "position", saved[p], 0.4)
				t.parallel().tween_property(p, "modulate:a", 1.0, 0.4)
		lead["hp"] = Game.max_hp(lead)
	await get_tree().create_timer(0.45).timeout


func _bars() -> void:
	e_bar.target = clampf(float(e["hp"]) / Game.max_hp(e), 0.0, 1.0)
	p_bar.target = clampf(float(lead["hp"]) / Game.max_hp(lead), 0.0, 1.0)
	s_bar.target = sync / 100.0
	pips.n = energy
	pips.full = sync >= 100.0


# ---------------------------------------------------------------- escolha
func _choose() -> Dictionary:
	pick = {}
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 2)
	host.add_child(bar)
	for mk in Game.moves_of(lead):
		var mv: Dictionary = Game.MOVES[mk]
		var cost := Game.move_cost(mk)
		var ic: String = "supremo" if mv.get("supremo", false) else ("especial" if mv["cd"] > 0 else "tipo_" + Game.TYPE_SLUG.get(mv["tipo"], "normal"))
		var b := _btn(ic, Game.TYPE_COLORS[mv["tipo"]], "%s (%s)" % [mv["nome"], mv["tipo"]])
		if cost > 0:
			b.text = str(cost)
		b.disabled = energy < cost
		if Game.effectiveness(mv["tipo"], Game.MONSTERS[e["id"]]["tipo"]) > 1.0:
			var mark := TextureRect.new()
			mark.texture = Game.tex(UI % "fraco")
			mark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			mark.scale = Vector2(0.6, 0.6)
			mark.position = Vector2(15, -5)
			mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(mark)
			b.tooltip_text += "  PONTO FRACO!"
			_pulse(b)
		var key: String = mk
		b.pressed.connect(func(): pick = {"t": "move", "mk": key})
		bar.add_child(b)
	if sync >= 100.0:
		var f := _btn("fusao", Color("ffd84a"), "Fusão de Alma")
		f.pressed.connect(func(): pick = {"t": "fusao"})
		bar.add_child(f)
		_pulse(f)
	var ratio := float(e["hp"]) / Game.max_hp(e)
	if ratio <= 0.35 and laco_tries < MAX_TRIES and not boss:
		var l := _btn("laco", Color("7affc1"), "Selo de Alma (capturar) — tentativas: %d" % (MAX_TRIES - laco_tries))
		if Game.can_capture(e):
			l.pressed.connect(func(): pick = {"t": "laco"})
			_pulse(l)
			# pontinhos com as tentativas restantes
			for i in MAX_TRIES - laco_tries:
				var dot := ColorRect.new()
				dot.color = Color("7affc1")
				dot.size = Vector2(2, 2)
				dot.position = Vector2(4 + i * 4, 15)
				dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
				l.add_child(dot)
		else:
			l.disabled = true
			l.tooltip_text = "Elo Nv %d necessário para capturar um %s (o seu é Nv %d)" % [Game.capture_lv(e), Game.RARITY[int(e.get("rar", 0))]["nome"], Game.elo_lv]
			var lock := TextureRect.new()
			lock.texture = Game.tex(UI % "cadeado")
			lock.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			lock.scale = Vector2(0.7, 0.7)
			lock.position = Vector2(13, 6)
			lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
			l.add_child(lock)
		bar.add_child(l)
	var r := _btn("fugir", Color(0.6, 0.6, 0.7), "Fugir")
	r.pressed.connect(func(): pick = {"t": "fugir"})
	bar.add_child(r)
	await get_tree().process_frame
	bar.position = Vector2(round(316.0 - bar.size.x * 0.5), 2)
	if auto:
		await get_tree().create_timer(0.5).timeout
		pick = _auto_pick()
	while pick.is_empty() and is_inside_tree():
		await get_tree().process_frame
	bar.queue_free()
	return pick


func _auto_pick() -> Dictionary:
	if sync >= 100.0:
		return {"t": "fusao"}
	if float(e["hp"]) / Game.max_hp(e) <= 0.35 and laco_tries < MAX_TRIES and Game.can_capture(e) and not boss:
		return {"t": "laco"}
	var best := ""
	for mk in Game.moves_of(lead):
		if Game.move_cost(mk) <= energy:
			if best == "" or Game.MOVES[mk]["poder"] > Game.MOVES[best]["poder"]:
				best = mk
	return {"t": "move", "mk": best}


func _btn(ic: String, col: Color, tip: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(22, 18)
	b.icon = Game.tex(UI % ic)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = tip
	b.add_theme_font_size_override("font_size", 8)
	b.add_theme_color_override("font_color", Color("ffd84a"))
	b.custom_minimum_size = Vector2(24, 20)
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		var base := Color(col.darkened(0.72), 0.92)
		sb.bg_color = {"normal": base, "hover": Color(col.darkened(0.5), 0.96), "pressed": Color(col.darkened(0.3), 0.96), "disabled": Color(0.08, 0.06, 0.1, 0.6)}[st]
		sb.set_corner_radius_all(7)
		sb.border_color = col.lightened(0.15) if st != "disabled" else Color(0.35, 0.33, 0.4)
		sb.set_border_width_all(1 if st != "hover" else 2)
		# brilho em cima: dá volume ao botão
		sb.shadow_color = Color(0, 0, 0, 0.5)
		sb.shadow_size = 1
		sb.shadow_offset = Vector2(0, 1)
		sb.border_width_top = 2 if st != "disabled" else 1
		sb.content_margin_left = 3
		sb.content_margin_right = 3
		b.add_theme_stylebox_override(st, sb)
	return b


func _pulse(c: Control) -> void:
	var t := c.create_tween().set_loops()
	t.tween_property(c, "modulate", Color(1.5, 1.4, 0.9), 0.35)
	t.tween_property(c, "modulate", Color.WHITE, 0.35)


# ---------------------------------------------------------------- anéis (QTE)
## Mostra um anel que fecha em "at". Retorna "perfect", "ok" ou "miss".
## Com feint, o anel finge que vai fechar, abre de novo e só então fecha.
func _ring(at: Vector2, dur: float, col: Color, tol_mult := 1.0, feint := false) -> String:
	var ring := RingQ.new()
	ring.col = col
	ring.position = at
	host.add_child(ring)
	catcher.visible = true
	clicked = false
	await get_tree().process_frame
	clicked = false
	var start := Time.get_ticks_msec()
	if feint:
		var fd := int(dur * 550)
		while Time.get_ticks_msec() - start < fd:
			var u := (Time.get_ticks_msec() - start) / float(fd)
			ring.k = 0.7 * sin(u * PI)
			if clicked:
				break
			await get_tree().process_frame
		if clicked:
			ring.queue_free()
			catcher.visible = false
			return "miss"
		start = Time.get_ticks_msec()
	var res := "miss"
	var perfect_w := 0.07 * tol_mult
	var ok_w := 0.17 * tol_mult
	while is_inside_tree():
		var k := (Time.get_ticks_msec() - start) / (dur * 1000.0)
		ring.k = k
		if auto and not auto_miss and absf(k - 1.0) < 0.02:
			clicked = true
		if clicked:
			var d := absf(k - 1.0)
			res = "perfect" if d <= perfect_w else ("ok" if d <= ok_w else "miss")
			break
		if k > 1.0 + ok_w:
			break
		await get_tree().process_frame
	ring.result(res)
	catcher.visible = false
	return res


func _tol() -> float:
	return (1.6 if Game.options.get("janela_ampla", false) else 1.0) * Game.skill_window(lead)


# ---------------------------------------------------------------- ataque
func _player_attack(mk: String) -> void:
	var mv: Dictionary = Game.MOVES[mk]
	energy -= Game.move_cost(mk)
	var col: Color = Game.TYPE_COLORS[mv["tipo"]]
	var rings := 3 if mv.get("supremo", false) else (2 if mv["cd"] > 0 else 1)
	_bars()
	var weak := Game.effectiveness(mv["tipo"], Game.MONSTERS[e["id"]]["tipo"]) > 1.0
	if weak:
		host._pop_icon(m.position + Vector2(0, -40), "fraco")
	for i in rings:
		var r := await _ring(m.position + Vector2(0, -20), 0.85 - i * 0.12, col, 1.6 if weak else 1.0)
		await _lunge(pet, m, col)
		if r == "miss":
			_float(m, "0", Color(0.7, 0.7, 0.8))
			continue
		var perfect := r == "perfect"
		if perfect:
			elo_gain += 1
		var dmg := Game.calc_damage(lead, e, mv, perfect)
		dmg = int(dmg * (1.0 + Game.skill_dmg(lead)) / rings * (1.3 if rings > 1 else 1.0))
		if perfect and Game.has_skill(lead, "f3"):
			dmg = int(dmg * 1.1)
		_hit(m, mat, maxi(1, dmg), col, perfect)
		if mv["cd"] == 0:
			energy = mini(Game.ENERGY_MAX, energy + (2 if perfect else 1))
		_sync(14.0 if perfect else 6.0)
		if e["hp"] <= 0:
			break
		await get_tree().create_timer(0.15).timeout
	_bars()


func _fusion() -> void:
	sync = 0.0
	_bars()
	var kid: AnimatedSprite2D = host.kid
	var kpos := kid.position
	var t := create_tween()
	t.tween_property(kid, "position", pet.position + Vector2(0, -6), 0.3).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(kid, "modulate:a", 0.0, 0.3)
	await t.finished
	var glow = Glow.new()
	glow.col = Color("ffd84a")
	glow.position = pet.position + Vector2(0, -20)
	host.stage.add_child(glow)
	var s0: float = pet.base
	await create_tween().tween_property(pet, "base", s0 * 1.5, 0.25).set_trans(Tween.TRANS_BACK).finished
	host._burst(pet.position + Vector2(0, -20), Color("ffd84a"), 20)
	var r := await _ring(m.position + Vector2(0, -20), 0.75, Color("ffd84a"))
	await _lunge(pet, m, Color("ffd84a"))
	var mk: String = Game.moves_of(lead)[0]
	var dmg := int(Game.calc_damage(lead, e, Game.MOVES[mk], r == "perfect") * 2.6 * (0.5 if r == "miss" else 1.0))
	_hit(m, mat, dmg, Color("ffd84a"), true)
	await _shake(4.0, 0.35)
	create_tween().tween_property(pet, "base", s0, 0.3)
	glow.queue_free()
	var t2 := create_tween()
	t2.tween_property(kid, "position", kpos, 0.3)
	t2.parallel().tween_property(kid, "modulate:a", 1.0, 0.3)
	_bars()


# ---------------------------------------------------------------- defesa
func _enemy_attack() -> void:
	var moves: Array = []
	for mk in Game.moves_of(e):
		if not Game.MOVES[mk].get("supremo", false):
			moves.append(mk)
	var mk: String = moves[randi() % moves.size()]
	var mv: Dictionary = Game.MOVES[mk]
	var big: bool = mv["cd"] > 0
	var col: Color = Game.TYPE_COLORS[mv["tipo"]]
	# carga: o Nefasto brilha na cor do golpe
	var ch := create_tween().set_loops(3)
	ch.tween_method(func(v): mat.set_shader_parameter("flash", v), 0.0, 0.6, 0.12)
	ch.tween_method(func(v): mat.set_shader_parameter("flash", v), 0.6, 0.0, 0.12)
	host._burst(m.position + Vector2(0, -20), col, 6)
	await get_tree().create_timer(0.35).timeout
	ch.kill()
	mat.set_shader_parameter("flash", 0.0)
	var feint: bool = int(e.get("rar", 0)) >= 3 and randf() < 0.25
	var r := await _ring(pet.position + Vector2(0, -16), 0.95 if not big else 1.1, Color("ff7a7a"), _tol(), feint)
	await _lunge(m, pet, col)
	match r:
		"perfect":
			elo_gain += 1
			# aparo: contra-ataque
			host._pop_icon(pet.position + Vector2(0, -34), "escudo")
			var dmg := int(Game.calc_damage(lead, e, Game.MOVES[Game.moves_of(lead)[0]], false) * 0.6)
			_hit(m, mat, maxi(1, dmg), Color("8fd4ff"), false)
			energy = mini(Game.ENERGY_MAX, energy + 1)
			_sync(12.0)
		"ok":
			host._pop_icon(pet.position + Vector2(0, -34), "desvio")
			create_tween().tween_property(pet, "position:x", pet.position.x - 10, 0.08).set_trans(Tween.TRANS_QUAD)
			await get_tree().create_timer(0.12).timeout
			create_tween().tween_property(pet, "position:x", 262.0, 0.15)
			_sync(5.0)
		_:
			var dmg := int(Game.calc_damage(e, lead, mv, false) * maxf(0.4, 1.0 - Game.skill_def(lead)) * (1.25 if big else 1.0))
			var pm: ShaderMaterial = pet.material as ShaderMaterial
			_hit(pet, pm, maxi(1, dmg), Color("ff5a6a"), false, true)
	_bars()


# ---------------------------------------------------------------- captura
## LAÇO DE ALMA: o Elo projeta um selo de runas sob o Nefasto. A cada anel
## acertado, uma esfera de alma trava no selo (Épico 3, Lendário 4). Selo
## completo: o Nefasto vira luz e é puxado para dentro do Elo. Errou: o selo
## se parte. Quanto mais fraco o inimigo, mais larga a janela.
func _laco() -> bool:
	var n := maxi(2, int(e.get("rar", 0)))
	var ratio := float(e["hp"]) / Game.max_hp(e)
	var tol := (1.0 + (0.35 - ratio) * 2.5) * (1.6 if Game.options.get("janela_ampla", false) else 1.0)
	var kid: AnimatedSprite2D = host.kid
	var from := kid.position + Vector2(6, -24)
	var center := m.position + Vector2(0, -18)
	# o Elo dispara uma centelha até o inimigo
	var spark := Spark.new()
	spark.position = from
	host.add_child(spark)
	var st := create_tween()
	st.tween_method(func(u: float): spark.position = from.lerp(center, u) + Vector2(0, -sin(u * PI) * 16.0), 0.0, 1.0, 0.35)
	await st.finished
	spark.queue_free()
	var seal := Seal.new()
	seal.n = n
	seal.position = Vector2(m.position.x, GROUND - 1)
	seal.center = Vector2(0, -18)
	host.stage.add_child(seal)
	await create_tween().tween_property(seal, "open", 1.0, 0.3).set_trans(Tween.TRANS_BACK).finished
	var ok := true
	auto_miss = e.has("debug_miss")
	for i in n:
		var r := await _ring(center, 0.72 - i * 0.06, Color("7affc1"), tol)
		if r == "miss":
			ok = false
			break
		seal.lock()
		host._burst(center, Color("7affc1"), 5)
		mat.set_shader_parameter("flash", 0.5)
		get_tree().create_timer(0.08).timeout.connect(func(): if is_instance_valid(m): mat.set_shader_parameter("flash", 0.0))
	if ok:
		seal.closed = true
		await _shake(2.0, 0.25)
		# vira luz e é puxado para o Elo
		var t := create_tween()
		t.tween_method(func(v): mat.set_shader_parameter("flash", v), 0.0, 1.0, 0.25)
		await t.finished
		var orb := Spark.new()
		orb.big = true
		orb.position = center
		host.add_child(orb)
		var t2 := create_tween()
		t2.tween_property(m, "scale", Vector2(0.05, 0.05), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		await t2.finished
		m.visible = false
		var t3 := create_tween()
		t3.tween_method(func(u: float): orb.position = center.lerp(from, u) + Vector2(0, -sin(u * PI) * 20.0), 0.0, 1.0, 0.5).set_trans(Tween.TRANS_SINE)
		await t3.finished
		orb.queue_free()
		host._sparkle(from)
		host._burst(from, Color("ffd84a"), 14)
		seal.queue_free()
		return true
	# o selo se parte
	laco_tries += 1
	seal.shatter()
	host._burst(center, Color("b050ff"), 14)
	await _shake(3.0, 0.25)
	await get_tree().create_timer(0.4).timeout
	seal.queue_free()
	return false


# ---------------------------------------------------------------- efeitos
func _lunge(who: Node2D, target: Node2D, col: Color) -> void:
	var home := who.position
	var dir := signf(target.position.x - who.position.x)
	if who is AnimatedSprite2D and (who as AnimatedSprite2D).sprite_frames.has_animation("attack"):
		(who as AnimatedSprite2D).play("attack")
		(who as AnimatedSprite2D).animation_finished.connect(func(): (who as AnimatedSprite2D).play("idle"), CONNECT_ONE_SHOT)
	await create_tween().tween_property(who, "position:x", target.position.x - dir * 26.0, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).finished
	host._burst(target.position + Vector2(0, -20), col, 5)
	create_tween().tween_property(who, "position", home, 0.18)


func _hit(spr: AnimatedSprite2D, smat: ShaderMaterial, dmg: int, col: Color, big: bool, on_player := false) -> void:
	if on_player:
		lead["hp"] = maxi(0, lead["hp"] - dmg)
	else:
		e["hp"] = maxi(0, e["hp"] - dmg)
	if smat:
		smat.set_shader_parameter("flash", 1.0)
		get_tree().create_timer(0.1).timeout.connect(func(): if is_instance_valid(spr): smat.set_shader_parameter("flash", 0.0))
	_float(spr, str(dmg), Color("ff9a9a") if on_player else (Color("ffd84a") if big else Color.WHITE))
	host._burst(spr.position + Vector2(0, -20), col, 10 if big else 6)
	if big:
		_shake(2.5, 0.15)
	_bars()


func _float(spr: Node2D, txt: String, col: Color) -> void:
	host._pop_text(spr.position + Vector2(-4, -44), txt, col)


func _sync(v: float) -> void:
	if Game.has_skill(lead, "v2"):
		v *= 1.15
	v *= 1.0 + Game.gear_bonus(lead, "sinc")
	sync = minf(100.0, sync + v)
	_bars()


func _shake(px: float, sec: float) -> void:
	var st: Node2D = host.stage
	var t := 0.0
	while t < sec and is_inside_tree():
		st.position = Vector2(randf_range(-px, px), randf_range(-px, px)) * (1.0 - t / sec)
		await get_tree().process_frame
		t += get_process_delta_time()
	st.position = Vector2.ZERO


# ---------------------------------------------------------------- peças visuais
class MiniBar extends Node2D:
	var ratio := 1.0
	var target := 1.0
	var col := Color.GREEN
	var w := 36.0
	var h := 3

	func _process(d: float) -> void:
		ratio = move_toward(ratio, target, d * 1.5)
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(-1, -1, w + 2, h + 2), Color("140a22"))
		draw_rect(Rect2(0, 0, w, h), Color(0.15, 0.1, 0.22))
		draw_rect(Rect2(0, 0, w * ratio, h), col)
		if target < ratio:
			draw_rect(Rect2(w * target, 0, w * (ratio - target), h), Color(1, 1, 1, 0.8))


class Pips extends Node2D:
	var n := 0
	var full := false
	var t := 0.0

	func _process(d: float) -> void:
		t += d
		queue_redraw()

	func _draw() -> void:
		for i in Game.ENERGY_MAX:
			var on := i < n
			draw_rect(Rect2(i * 6 - 1, -1, 5, 5), Color("140a22"))
			draw_rect(Rect2(i * 6, 0, 3, 3), Color("5ad0ff") if on else Color(0.2, 0.18, 0.3))
		if full:
			draw_circle(Vector2(34, 1), 2.0 + sin(t * 8.0), Color("ffd84a"))


class RingQ extends Node2D:
	var k := 0.0
	var col := Color("ffd84a")
	var done := ""
	var life := 0.0

	func _process(d: float) -> void:
		if done != "":
			life += d
			modulate.a = 1.0 - life / 0.35
			scale = Vector2.ONE * (1.0 + life * 1.5)
			if life > 0.35:
				queue_free()
		queue_redraw()

	func result(r: String) -> void:
		done = r
		col = {"perfect": Color("ffd84a"), "ok": Color("7affc1"), "miss": Color("ff5a6a")}[r]

	func _draw() -> void:
		var r := lerpf(40.0, 9.0, clampf(k, 0.0, 1.3))
		var near := absf(k - 1.0) < 0.12
		draw_arc(Vector2.ZERO, 9.0, 0, TAU, 24, Color(1, 1, 1, 0.9) if near else Color(col, 0.6), 2.0)
		if done == "":
			draw_arc(Vector2.ZERO, r, 0, TAU, 32, col, 2.0)
		else:
			draw_arc(Vector2.ZERO, 9.0, 0, TAU, 24, col, 3.0)


class Seal extends Node2D:
	var n := 3
	var locked := 0
	var open := 0.0
	var closed := false
	var broken := 0.0
	var t := 0.0
	var center := Vector2(0, -18)

	func _process(d: float) -> void:
		t += d
		if broken > 0.0:
			broken += d
			modulate.a = maxf(0.0, 1.0 - broken * 2.0)
		queue_redraw()

	func lock() -> void:
		locked += 1

	func shatter() -> void:
		broken = 0.001

	func _draw() -> void:
		var c := Color("7affc1") if not closed else Color("ffe9a8")
		var rx := 36.0 * open
		var ry := 9.0 * open
		# selo no chão: dois anéis elípticos e runas girando
		draw_set_transform(Vector2.ZERO, 0, Vector2(1, ry / maxf(rx, 0.01)))
		draw_circle(Vector2.ZERO, rx, Color(c, 0.12 + 0.05 * locked))
		draw_arc(Vector2.ZERO, rx, 0, TAU, 48, Color("140a22", 0.6), 4.0)
		draw_arc(Vector2.ZERO, rx, 0, TAU, 48, Color(c, 1.0), 2.0)
		draw_arc(Vector2.ZERO, rx * 0.7, 0, TAU, 40, Color(c, 0.7), 1.5)
		# arco que "carrega" conforme as esferas travam
		if locked > 0:
			draw_arc(Vector2.ZERO, rx * 0.85, -PI / 2, -PI / 2 + TAU * float(locked) / n, 40, Color(1, 1, 1, 0.9), 2.5)
		for i in 10:
			var a := t * 0.9 + i * TAU / 10.0
			var p := Vector2(cos(a), sin(a)) * rx * 0.85
			draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3, 3)), Color(c, 1.0))
		draw_set_transform(Vector2.ZERO)
		if closed:
			# coluna de luz
			draw_rect(Rect2(-rx * 0.5, -60, rx, 60), Color(1, 0.95, 0.7, 0.18 + 0.1 * sin(t * 20.0)))
		# esferas de alma: travadas ficam fixas e ligadas; as livres orbitam
		var pts: Array = []
		for i in n:
			var a: float
			var is_locked := i < locked
			if is_locked:
				a = -PI / 2 + i * TAU / n
			else:
				a = t * 3.0 + i * TAU / n
			var off := Vector2(cos(a) * 28.0, sin(a) * 12.0) * open
			if broken > 0.0:
				off *= 1.0 + broken * 6.0
			var p := center + off
			if is_locked:
				pts.append(p)
				draw_circle(p, 6.0, Color(c, 0.3))
				draw_circle(p, 3.5, Color("140a22"))
				draw_circle(p, 2.5, Color(1, 1, 1))
			else:
				draw_circle(p, 3.0, Color("140a22", 0.7))
				draw_circle(p, 2.0, Color(c, 0.75))
		for i in pts.size():
			if pts.size() > 1 and (i < pts.size() - 1 or closed):
				draw_line(pts[i], pts[(i + 1) % pts.size()], Color("140a22", 0.6), 3.0)
				draw_line(pts[i], pts[(i + 1) % pts.size()], Color(c, 1.0), 1.5)


class Spark extends Node2D:
	var big := false
	var t := 0.0

	func _process(d: float) -> void:
		t += d
		queue_redraw()

	func _draw() -> void:
		var r := 5.0 if big else 3.0
		draw_circle(Vector2.ZERO, r * 2.2, Color(1, 0.95, 0.6, 0.18))
		draw_circle(Vector2.ZERO, r, Color("ffe9a8"))
		draw_circle(Vector2.ZERO, r * 0.5, Color.WHITE)
		for i in 4:
			var a := t * 9.0 + i * PI / 2
			draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * r * 2.4, Color(1, 1, 1, 0.6), 1.0)


class Glow extends Node2D:
	var col := Color(1, 0.85, 0.3)

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		for i in 6:
			draw_circle(Vector2.ZERO, 34.0 - i * 5.0, Color(col, 0.07 + i * 0.03))
