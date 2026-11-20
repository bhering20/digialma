extends Control
## Rota de uma região: caminhada com cenário passando, 3 encontros com Nefastos,
## chegada ao santuário (entrada pela porta) e duelo com o guardião no salão.

const FX = preload("res://scripts/fx.gd")
const Dialog = preload("res://scripts/dialog.gd")
const Battle = preload("res://scripts/battle.gd")
const Evolution = preload("res://scripts/evolution.gd")
const Ambient = preload("res://scripts/ambient.gd")
const OBJ := "res://assets/packs/scarloxy_graphics/objects/"
const GROUND_Y := 322.0
const WALK_SPEED := 46.0

var reg: Dictionary
var walking := false
var kid: AnimatedSprite2D
var pets: Array = []
var props: Array = []
var stage: Node2D
var dialog: Dialog
var dots: Array = []
var t := 0.0
var rng := RandomNumberGenerator.new()
## Sair para o mapa só acontece em pontos seguros (para nenhuma animação ficar rodando no vazio).
var want_leave := false
var leaving := false
var back_btn: Button
var cmat: ShaderMaterial  # material compartilhado da corrupção
var amb_node: Node2D


## Monstro que segue o treinador: anda com pulinhos (esticando no ar, achatando
## ao tocar o chão), levanta poeira e "respira" parado.
class Pet extends AnimatedSprite2D:
	var walking := false
	var t := 0.0
	var phase := 0.0
	var foot := Vector2.ZERO
	var last_hop := 1.0
	var shadow: Shadow
	var base := 1.0
	## Alma-nuvem: o Digialma caiu e virou uma nuvenzinha de alma com a silhueta
	## e as cores dele. Só volta com um Orbe de Alma.
	var soul := false
	var soul_col := Color.WHITE
	var cloud: SoulCloud
	var aura: AwakenAura

	## Despertos andam com uma aura dourada.
	func set_awakened(on: bool) -> void:
		if on and not is_instance_valid(aura):
			aura = AwakenAura.new()
			aura.show_behind_parent = true
			add_child(aura)
		elif not on and is_instance_valid(aura):
			aura.queue_free()

	func _ready() -> void:
		shadow = Shadow.new()
		shadow.w = 15.0
		shadow.show_behind_parent = true
		add_child(shadow)

	func set_soul(on: bool, col := Color.WHITE) -> void:
		if on == soul:
			return
		soul = on
		soul_col = col
		if material == null or not (material is ShaderMaterial):
			material = Game.sprite_mat()
		if on:
			(material as ShaderMaterial).set_shader_parameter("silhouette", 0.55)
			modulate = Color(col.lightened(0.35), 0.72)
			cloud = SoulCloud.new()
			cloud.col = col
			cloud.show_behind_parent = true
			add_child(cloud)
		else:
			(material as ShaderMaterial).set_shader_parameter("silhouette", 0.0)
			modulate = Color.WHITE
			if is_instance_valid(cloud):
				cloud.queue_free()

	func _process(delta: float) -> void:
		t += delta
		if soul:
			speed_scale = 0.4
			offset = foot - Vector2(0, 9.0 + round(sin(t * 1.8 + phase) * 3.0))
			scale = base * Vector2(0.86, 0.86)
			rotation = sin(t * 1.3 + phase) * 0.04
			shadow.k = 0.55
			modulate = Color(soul_col.lightened(0.35), minf(modulate.a, 0.72))
			if is_instance_valid(aura):
				aura.visible = false
			if is_instance_valid(cloud):
				cloud.position = (offset + Vector2(sprite_frames.get_frame_texture(animation, 0).get_width() * 0.5, sprite_frames.get_frame_texture(animation, 0).get_height() * 0.62)) if sprite_frames else Vector2.ZERO
			return
		if is_instance_valid(aura) and sprite_frames:
			aura.visible = true
			var tx := sprite_frames.get_frame_texture(animation, 0)
			aura.position = offset + Vector2(tx.get_width() * 0.5, tx.get_height() * 0.7)
		if walking:
			speed_scale = 1.8
			var ph := t * 9.0 + phase
			var hop: float = absf(sin(ph))
			var ground := 1.0 - hop
			offset = foot - Vector2(0, round(hop * 6.0))
			scale = base * Vector2(1.0 + 0.14 * ground * ground - 0.05 * hop, 1.0 - 0.14 * ground * ground + 0.08 * hop)
			rotation = sin(ph) * 0.05
			shadow.k = 1.0 - hop * 0.4
			if hop < 0.2 and last_hop >= 0.2 and get_parent():
				var d := Dust.new()
				d.position = position + Vector2(-6, 0)
				get_parent().add_child(d)
			last_hop = hop
		else:
			speed_scale = 1.0
			offset = foot
			var b := sin(t * 2.4 + phase) * 0.03
			scale = base * Vector2(1.0 - b, 1.0 + b)
			rotation = 0.0
			shadow.k = 1.0


class Shadow extends Node2D:
	var w := 15.0
	var h := 3.0
	var k := 1.0

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var pts := PackedVector2Array()
		for i in 20:
			var a := TAU * i / 20.0
			pts.append(Vector2(cos(a) * w * k, 1.0 + sin(a) * h * k).round())
		draw_colored_polygon(pts, Color(0, 0, 0, 0.22))


## Nuvem de alma: fumacinhas suaves na cor do Digialma, subindo devagar.
class SoulCloud extends Node2D:
	var col := Color.WHITE
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var base_c := col.lightened(0.45)
		for i in 7:
			var a := TAU * i / 7.0 + t * 0.7
			var r := 14.0 + 3.0 * sin(t * 1.6 + i)
			var p := Vector2(cos(a) * r, sin(a) * r * 0.45 + 6.0)
			draw_circle(p.round(), 9.0 + 2.0 * sin(t * 2.0 + i * 1.7), Color(base_c, 0.22))
		for i in 4:
			var k := fmod(t * 0.35 + i * 0.25, 1.0)
			var p := Vector2(sin(t + i * 2.3) * 10.0, 4.0 - k * 34.0)
			draw_circle(p.round(), 2.5 * (1.0 - k) + 0.5, Color(base_c.lightened(0.3), 0.5 * (1.0 - k)))


## Aura do Despertar: chamas douradas subindo e um halo pulsando.
class AwakenAura extends Node2D:
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(t * 3.0)
		draw_circle(Vector2.ZERO, 26.0 + pulse * 3.0, Color(1.0, 0.82, 0.3, 0.08))
		draw_circle(Vector2.ZERO, 18.0 + pulse * 2.0, Color(1.0, 0.9, 0.5, 0.08))
		for i in 6:
			var k := fmod(t * 0.6 + i / 6.0, 1.0)
			var x := sin(i * 2.1 + t * 1.5) * 16.0
			draw_circle(Vector2(x, 10.0 - k * 46.0).round(), 2.5 * (1.0 - k) + 0.5, Color(1.0, 0.85 - k * 0.3, 0.3, 0.7 * (1.0 - k)))


## Nuvenzinha de poeira quando o pé toca o chão.
class Dust extends Node2D:
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		if t > 0.45:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var a := 1.0 - t / 0.45
		for i in 3:
			var p := Vector2(-4.0 - i * 4.0 - t * 18.0, -2.0 - t * 10.0 * (i % 2))
			draw_circle(p.round(), 1.5 + t * 6.0, Color(1, 0.97, 0.88, 0.5 * a))


func _ready() -> void:
	rng.randomize()
	theme = Game.make_theme()
	reg = Game.REGIONS[Game.region]
	var bg := TextureRect.new()
	bg.texture = Game.tex(reg["bg"])
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = reg["tint"]
	add_child(bg)
	if Game.region_corrupt(Game.region):
		cmat = Game.corrupt_mat()
		bg.material = cmat
	road = Road.new()
	road.kind = reg.get("chao", "terra")
	road.material = cmat
	add_child(road)
	stage = Node2D.new()
	stage.y_sort_enabled = true
	add_child(stage)
	_init_scenery()
	_spawn_team()
	var amb := Ambient.new()
	amb.kind = Ambient.kind_for(reg)
	add_child(amb)
	amb.set_corrupted(cmat != null)
	amb_node = amb
	var vig := ColorRect.new()
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.size = Game.BASE
	vig.material = FX.shader_mat(FX.VIGNETTE_SHADER)
	vig.material.set_shader_parameter("strength", 0.35)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vig)
	_progress_bar()
	var back := Button.new()
	back_btn = back
	back.text = "MAPA"
	back.position = Vector2(566, 10)
	back.custom_minimum_size = Vector2(64, 22)
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(func():
		want_leave = true
		back.text = "SAINDO..."
		back.disabled = true)
	add_child(back)
	dialog = Dialog.new()
	add_child(dialog)
	_run()


# ---------------------------------------------------------------- cenário
## Faixas de cenário: cada uma com altura, velocidade (paralaxe) e espaçamento próprios.
## Nada fica solto no meio do campo: árvores ao fundo, detalhes na beira da trilha,
## arbustos em primeiro plano.
const LANES := [
	{"tipo": "big", "y": [212, 222], "vel": 0.5, "gap": [34, 120], "tom": Color(0.68, 0.74, 0.86), "pula": 0.25},
	{"tipo": "big", "y": [240, 262], "vel": 0.72, "gap": [40, 170], "tom": Color(0.86, 0.9, 0.96), "pula": 0.3},
	{"tipo": "small", "y": [297, 300], "vel": 1.0, "gap": [70, 150], "tom": Color.WHITE},
	{"tipo": "small", "y": [350, 353], "vel": 1.0, "gap": [80, 170], "tom": Color.WHITE},
	{"tipo": "front", "y": [378, 386], "vel": 1.3, "gap": [150, 260], "tom": Color.WHITE},
]
var lane_next: Array = []
var road: Road


func _init_scenery() -> void:
	for i in LANES.size():
		lane_next.append(-40.0 + rng.randf_range(0, 40))
	_fill_lanes()


func _fill_lanes() -> void:
	for i in LANES.size():
		var L: Dictionary = LANES[i]
		while lane_next[i] < 720.0:
			# "pula" cria clareiras: às vezes não planta nada naquele ponto
			if rng.randf() >= float(L.get("pula", 0.0)):
				_spawn_prop(i, lane_next[i])
				# às vezes um par juntinho (moita/bosque)
				if L["tipo"] == "big" and rng.randf() < 0.3:
					_spawn_prop(i, lane_next[i] + rng.randf_range(16, 26))
			lane_next[i] += rng.randf_range(L["gap"][0], L["gap"][1])


func _spawn_prop(lane: int, x: float) -> void:
	var L: Dictionary = LANES[lane]
	var names: Array = reg["props"][L["tipo"]]
	var n: String = names[rng.randi() % names.size()]
	var s := Sprite2D.new()
	var custom := n.begins_with("p:")
	s.texture = Game.tex(("res://assets/props/" + n.substr(2) if custom else OBJ + n) + ".png")
	s.centered = false
	s.offset = Vector2(-s.texture.get_width() * 0.5, -s.texture.get_height())
	s.scale = Vector2(0.5, 0.5)
	s.position = Vector2(round(x), round(rng.randf_range(L["y"][0], L["y"][1])))
	s.modulate = (Color.WHITE if custom else reg["prop_tint"] as Color) * (L["tom"] as Color)
	if custom and n.contains("pedr") and reg.get("chao", "") == "basalto":
		s.modulate *= Color(0.55, 0.45, 0.55)  # pedras de basalto escuro
	s.set_meta("speed", L["vel"])
	s.set_meta("fx", s.position.x)
	s.material = cmat
	# sombra no chão (em coordenadas da textura, por isso o dobro)
	var sh := Shadow.new()
	sh.w = s.texture.get_width() * 0.42
	sh.h = 6.0 if s.texture.get_width() > 80 else 4.0
	sh.show_behind_parent = true
	s.add_child(sh)
	stage.add_child(s)
	props.append(s)


## Trilha que rola sob os pés na mesma velocidade da caminhada.
class Road extends Node2D:
	var scroll := 0.0
	var kind := "terra"
	var width := 656.0
	const TOP := 301.0
	const BOT := 344.0
	var pal := {}

	func _ready() -> void:
		pal = {
			"terra": {"base": Color("caa66a"), "esc": Color("a9844f"), "cla": Color("e2c78f"), "borda": Color("6f9e34"), "tufo": Color("4f7f26")},
			"areia": {"base": Color("e9c47e"), "esc": Color("cfa25f"), "cla": Color("f8e2ab"), "borda": Color("d9b06a"), "tufo": Color("bfe7f0")},
			"basalto": {"base": Color("5a4248"), "esc": Color("3d2b31"), "cla": Color("7a5c62"), "borda": Color("3a262c"), "tufo": Color("ff7a2a")},
		}[kind]

	func _h(k: int) -> int:
		var v := (k * 73856093) ^ (k * 19349663 >> 3)
		return absi(v) % 100000

	func _edge(wx: float, base: float) -> float:
		return base + round(sin(wx * 0.045) * 2.0 + sin(wx * 0.017 + 1.3) * 2.0)

	func _draw() -> void:
		var sc := floorf(scroll)
		# corpo da trilha com bordas onduladas presas ao "mundo" (andam junto)
		var top := PackedVector2Array()
		var bot := PackedVector2Array()
		for x in range(-8, int(width), 8):
			var wx := x + sc
			top.append(Vector2(x, _edge(wx, TOP)))
			bot.append(Vector2(x, _edge(wx + 400.0, BOT)))
		var poly := top.duplicate()
		for i in range(bot.size() - 1, -1, -1):
			poly.append(bot[i])
		draw_colored_polygon(poly, pal["base"])
		# bordas mais escuras (dá a ideia de rebaixo / terra pisada)
		for i in top.size() - 1:
			draw_line(top[i], top[i + 1], pal["esc"], 2.0)
			draw_line(bot[i] + Vector2(0, -1), bot[i + 1] + Vector2(0, -1), pal["cla"], 2.0)
			draw_line(bot[i] + Vector2(0, 1), bot[i + 1] + Vector2(0, 1), pal["borda"], 2.0)
		# trilhos de passos (duas faixas tracejadas que se movem)
		for lane_y in [313.0, 331.0]:
			var k0 := int(floorf((sc - 40.0) / 20.0))
			for k in range(k0, k0 + int(width / 20.0) + 4):
				var x := k * 20.0 - sc
				if _h(k + int(lane_y)) % 3 != 0:
					draw_rect(Rect2(Vector2(round(x), lane_y), Vector2(10 + _h(k) % 6, 2)), pal["esc"])
		# pedrinhas, rachaduras e tufos presos ao chão
		var c0 := int(floorf((sc - 30.0) / 13.0))
		for k in range(c0, c0 + int(width / 13.0) + 4):
			var h := _h(k)
			var x: float = roundf(k * 13.0 - sc + h % 9)
			if h % 4 == 0:
				var y := TOP + 6.0 + float((h / 7) % 34)
				var big := h % 3 == 0
				draw_rect(Rect2(Vector2(x, y), Vector2(3 if big else 2, 2)), pal["esc"])
				draw_rect(Rect2(Vector2(x, y - 1), Vector2(2 if big else 1, 1)), pal["cla"])
			if h % 5 == 1:
				# tufo na beira de cima e de baixo
				var yt := _edge(x + sc, TOP)
				_tuft(Vector2(x, yt), pal["tufo"])
			if h % 6 == 2:
				var yb := _edge(x + sc + 400.0, BOT)
				_tuft(Vector2(x + 4, yb + 2), pal["tufo"])
			if kind == "basalto" and h % 17 == 3:
				var y2 := TOP + 10.0 + float(h % 24)
				draw_line(Vector2(x, y2), Vector2(x + 6, y2 + 2), Color("ff6a2a"), 1.0)
				draw_line(Vector2(x + 6, y2 + 2), Vector2(x + 11, y2), Color("ffc04a"), 1.0)

	func _tuft(p: Vector2, col: Color) -> void:
		if kind == "areia":
			draw_rect(Rect2(p + Vector2(0, -1), Vector2(3, 1)), Color(1, 1, 1, 0.55))
			return
		draw_rect(Rect2(p + Vector2(0, -3), Vector2(1, 3)), col)
		draw_rect(Rect2(p + Vector2(2, -4), Vector2(1, 4)), col)
		draw_rect(Rect2(p + Vector2(4, -2), Vector2(1, 2)), col)


func _spawn_team() -> void:
	for p in pets:
		p.queue_free()
	pets.clear()
	for i in Game.team.size():
		var pet := Pet.new()
		pet.sprite_frames = Game.monster_frames(Game.team[i]["id"])
		pet.play("idle")
		pet.centered = false
		pet.foot = Game.foot_offset(Game.team[i]["id"])
		pet.offset = pet.foot
		pet.flip_h = true
		pet.phase = i * 1.3
		# formas evoluídas grandes ficam menores no mapa para não engolir a tela
		pet.base = 0.72 if Game.FOOT.get(Game.team[i]["id"], 80) > 85 else 1.0
		pet.walking = walking
		pet.position = Vector2(250 - i * 62, GROUND_Y)
		stage.add_child(pet)
		pets.append(pet)
		if int(Game.team[i]["hp"]) <= 0:
			pet.set_soul.call_deferred(true, Game.MONSTERS[Game.team[i]["id"]]["cor"])
	if kid == null:
		kid = AnimatedSprite2D.new()
		kid.sprite_frames = Game.char_frames(Game.player_char)
		kid.play("idle_right")
		kid.centered = false
		kid.offset = Vector2(-64, -128)
		kid.scale = Vector2(0.5, 0.5)
		kid.position = Vector2(300, GROUND_Y + 2)
		stage.add_child(kid)
		var ks := Shadow.new()
		ks.w = 26.0
		ks.show_behind_parent = true
		kid.add_child(ks)


func _process(delta: float) -> void:
	t += delta
	if not walking:
		return
	road.scroll += WALK_SPEED * delta
	road.queue_redraw()
	for p in props.duplicate():
		var s := p as Sprite2D
		var pos: float = s.get_meta("fx", s.position.x) - WALK_SPEED * float(s.get_meta("speed")) * delta
		s.set_meta("fx", pos)
		s.position.x = round(pos)
		if pos < -90:
			props.erase(s)
			s.queue_free()
	for i in LANES.size():
		lane_next[i] -= WALK_SPEED * float(LANES[i]["vel"]) * delta
	_fill_lanes()


func _set_walking(on: bool) -> void:
	walking = on
	kid.play("right" if on else "idle_right")
	for p in pets:
		p.walking = on


func _walk(sec: float) -> void:
	_set_walking(true)
	var end := Time.get_ticks_msec() + int(sec * 1000.0)
	while Time.get_ticks_msec() < end and not want_leave:
		await get_tree().process_frame
	_set_walking(false)


## Ponto seguro: se o jogador pediu para sair, sai agora e avisa quem chamou para parar.
func _bail() -> bool:
	if want_leave and not leaving:
		leaving = true
		_set_walking(false)
		Game.change_scene("res://scenes/map.tscn")
	return want_leave


# ---------------------------------------------------------------- fluxo
func _run() -> void:
	if Game.debug_species == -2:  # só testes: vai direto ao santuário
		await _arrive_gym()
		return
	await _show_banner(reg["nome"].to_upper())
	for i in 3:
		var lv := rng.randi_range(reg["nv"][0], reg["nv"][1])
		var sp: int = reg["selvagens"][rng.randi() % reg["selvagens"].size()]
		# raros só depois que o jogador já aprendeu o básico (3ª batalha em diante)
		var raro := Game.battle_count >= 2 and rng.randf() < 0.2
		if raro:
			sp = reg["raros"][rng.randi() % reg["raros"].size()]
			lv += 1
		if Game.debug_species > 0:
			sp = Game.debug_species
		var e := Game.new_monster(sp, lv, Game.roll_rarity(1 if raro else 0))
		e["nefasto"] = true
		e["raro"] = raro
		await _walk(0.4)
		if _bail():
			return
		await _ambush(e)
		if _bail():
			return
		var r := await _battle([e])
		if r == "lose":
			await _lost()
			return
		if r == "win":
			Game.elo_charges += 1
		_mark(i)
		await _after_battle()
		if _bail():
			return
	await _arrive_gym()


func _arrive_gym() -> void:
	var ld: Dictionary = reg["lider"]
	# o santuário entra pela direita junto com o cenário
	var gym := Sprite2D.new()
	gym.texture = Game.tex(OBJ + reg["arena"] + ".png")
	gym.centered = false
	gym.offset = Vector2(-224, -440)
	gym.scale = Vector2(0.68, 0.68)
	gym.position = Vector2(860, GROUND_Y - 6)
	gym.set_meta("speed", 1.0)
	gym.material = cmat
	var door := SanctuaryDoor.new()
	door.glow = reg["piso"][2]
	door.use_parent_material = true  # segue a corrupção do prédio
	gym.add_child(door)
	stage.add_child(gym)
	_set_walking(true)
	while gym.position.x > 470:
		if _bail():
			return
		var nx: float = gym.get_meta("fx", gym.position.x) - WALK_SPEED * get_process_delta_time()
		gym.set_meta("fx", nx)
		gym.position.x = round(nx)
		await get_tree().process_frame
	_set_walking(false)
	back_btn.visible = false  # dentro do santuário não dá para sair
	await _show_banner(ld["ginasio"].to_upper())
	# o grupo vai até a frente da porta
	kid.play("right")
	_set_walking(true)
	var walk := create_tween().set_parallel(true)
	walk.tween_property(kid, "position:x", gym.position.x - 2, 1.4)
	for i in pets.size():
		walk.tween_property(pets[i], "position:x", gym.position.x - 34 - i * 22, 1.4)
	await walk.finished
	_set_walking(false)
	kid.play("idle_up")
	await get_tree().create_timer(0.3).timeout
	# a porta se abre (as folhas deslizam para dentro das paredes) e sai luz
	_shake(1.5)
	await create_tween().tween_property(door, "open", 1.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT).finished
	await get_tree().create_timer(0.25).timeout
	# entram: sobem um passo e somem na escuridão do salão
	kid.play("up")
	var tw := create_tween().set_parallel(true)
	tw.tween_property(kid, "position:y", gym.position.y + 2, 0.6)
	tw.tween_property(kid, "scale", Vector2(0.44, 0.44), 0.6)
	tw.tween_property(kid, "modulate", Color(0.15, 0.1, 0.25, 0.0), 0.6).set_delay(0.15)
	for i in pets.size():
		pets[i].walking = true
		tw.tween_property(pets[i], "position", Vector2(gym.position.x - 4, gym.position.y + 2), 0.75).set_delay(0.25 + i * 0.15)
		tw.tween_property(pets[i], "modulate", Color(0.15, 0.1, 0.25, 0.0), 0.5).set_delay(0.5 + i * 0.15)
	await tw.finished
	await create_tween().tween_property(door, "open", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).finished
	_shake(1.0)
	kid.scale = Vector2(0.5, 0.5)
	var fade := ColorRect.new()
	fade.color = Color(0.03, 0.01, 0.08, 0.0)
	fade.size = Game.BASE
	add_child(fade)
	await create_tween().tween_property(fade, "color:a", 1.0, 0.5).finished
	await _gym_hall(ld)
	fade.queue_free()


## Porta dupla do santuário, desenhada sobre a porta de vidro do prédio
## (coordenadas da textura 448x448 com origem em (224, 440)).
class SanctuaryDoor extends Node2D:
	var open := 0.0:
		set(v):
			open = v
			queue_redraw()
	var glow := Color("8fd45a")
	var t := 0.0
	const R := Rect2(-31, -83, 62, 87)

	func _process(delta: float) -> void:
		t += delta
		if open > 0.0:
			queue_redraw()

	func _draw() -> void:
		if open <= 0.0:
			return
		# interior escuro com luz vindo do fundo
		draw_rect(R, Color("120a1e"))
		var a := open * (0.55 + 0.1 * sin(t * 3.0))
		draw_rect(Rect2(R.position.x + 6, R.position.y + 30, R.size.x - 12, R.size.y - 30), Color(glow, a * 0.5))
		draw_rect(Rect2(R.position.x + 16, R.position.y + 44, R.size.x - 32, R.size.y - 44), Color(1, 1, 0.85, a * 0.6))
		# folhas deslizando para dentro das paredes (cada uma some na sua borda)
		var half := R.size.x / 2.0
		var w := half * (1.0 - open)
		if w > 0.5:
			_leaf(Rect2(R.position.x, R.position.y, w, R.size.y))
			_leaf(Rect2(R.end.x - w, R.position.y, w, R.size.y))
		# feixe de luz saindo pela porta
		var pts := PackedVector2Array([Vector2(R.position.x + half * (1.0 - open), R.end.y), Vector2(R.end.x - half * (1.0 - open), R.end.y), Vector2(R.end.x + 30 * open, R.end.y + 40), Vector2(R.position.x - 30 * open, R.end.y + 40)])
		draw_colored_polygon(pts, Color(1, 1, 0.8, 0.18 * open))

	func _leaf(r: Rect2) -> void:
		draw_rect(r, Color("1e78d8"))
		draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 6), Color("4ab0ff"))
		draw_rect(Rect2(r.position.x, r.end.y - 10, r.size.x, 6), Color("7fe0ff"))
		draw_rect(Rect2(r.position.x + 2, r.position.y + 12, minf(6.0, r.size.x - 2), r.size.y - 28), Color(1, 1, 1, 0.25))


func _gym_hall(ld: Dictionary) -> void:
	var hall := GymHall.new()
	hall.piso = reg["piso"]
	hall.size = Game.BASE
	add_child(hall)
	move_child(dialog, -1)
	var leader := AnimatedSprite2D.new()
	leader.sprite_frames = Game.char_frames(ld["sprite"])
	leader.play("idle_down")
	leader.position = Vector2(320, 150)
	hall.add_child(leader)
	var me := AnimatedSprite2D.new()
	me.sprite_frames = Game.char_frames(Game.player_char)
	me.play("up")
	me.position = Vector2(320, 400)
	hall.add_child(me)
	await create_tween().tween_property(me, "position:y", 268.0, 1.6).finished
	me.play("idle_up")
	await dialog.play(Game.STORY["lider%d_antes" % Game.region])
	var team: Array = []
	for pair in ld["time"]:
		var m := Game.new_monster(pair[0], pair[1], pair[2] if pair.size() > 2 else 0)
		m["nefasto"] = Game.region >= 1
		team.append(m)
	var r := await _battle(team, ld)
	if r == "lose":
		hall.queue_free()
		await _lost()
		return
	_mark(3)
	if Game.badges <= Game.region:
		Game.badges = Game.region + 1
		Game.region_unlocked = mini(3, Game.region + 2)
		Game.elo_charges += 2
	await _after_battle()
	await _badge_scene(ld)
	if cmat:
		hall.queue_free()
		await _purify()
	await dialog.play(Game.STORY["lider%d_depois" % Game.region])
	Game.heal_team(1.0, true)  # o santuário purificado devolve as almas
	Game.change_scene("res://scenes/map.tscn" if Game.region < 2 else "res://scenes/title.tscn")


## Salão do santuário: piso em perspectiva, pilares, tochas e holofote no guardião.
class GymHall extends Control:
	var piso: Array = []
	var t := 0.0
	var flames: Array = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		for x in [70.0, 570.0]:
			var p := Sprite2D.new()
			p.texture = Game.tex(OBJ + "ruin_pillar.png")
			p.position = Vector2(x, 210)
			p.modulate = (piso[2] as Color).lerp(Color.WHITE, 0.55)
			add_child(p)
			var f := CPUParticles2D.new()
			f.position = Vector2(x, 112)
			f.amount = 30
			f.lifetime = 0.8
			f.direction = Vector2(0, -1)
			f.spread = 20.0
			f.gravity = Vector2(0, -60)
			f.initial_velocity_min = 20.0
			f.initial_velocity_max = 50.0
			f.scale_amount_min = 3.0
			f.scale_amount_max = 6.0
			var g := Gradient.new()
			g.set_color(0, Color("fff1a8"))
			g.set_color(1, Color(piso[2], 0.0))
			f.color_ramp = g
			add_child(f)

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 640, 360), (piso[0] as Color).darkened(0.6))
		draw_rect(Rect2(0, 0, 640, 120), (piso[0] as Color).darkened(0.75))
		# piso em perspectiva com faixas
		var horizon := 120.0
		for i in 14:
			var y0 := horizon + pow(i / 14.0, 1.6) * 240.0
			var y1 := horizon + pow((i + 1) / 14.0, 1.6) * 240.0
			var c: Color = piso[0] if i % 2 == 0 else piso[1]
			draw_rect(Rect2(0, y0, 640, y1 - y0 + 1), c)
		for k in range(-8, 9):
			var bx := 320.0 + k * 60.0
			draw_line(Vector2(320 + k * 14.0, horizon), Vector2(bx * 1.0 + k * 40.0, 360), Color(piso[2], 0.18), 1.0)
		# tapete central
		draw_colored_polygon(PackedVector2Array([Vector2(300, 150), Vector2(340, 150), Vector2(420, 360), Vector2(220, 360)]), Color(piso[2], 0.25))
		# holofote no líder
		var a := 0.16 + 0.04 * sin(t * 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(300, 0), Vector2(340, 0), Vector2(380, 190), Vector2(260, 190)]), Color(1, 1, 0.85, a))
		draw_circle(Vector2(320, 186), 34, Color(1, 1, 0.85, a * 0.9))


# ---------------------------------------------------------------- interface
func _progress_bar() -> void:
	var p := PanelContainer.new()
	p.position = Vector2(8, 8)
	add_child(p)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	p.add_child(h)
	var l := Label.new()
	l.text = reg["nome"].to_upper()
	l.add_theme_color_override("font_color", Color("ffd84a"))
	h.add_child(l)
	for i in 4:
		var d := PanelContainer.new()
		d.add_theme_stylebox_override("panel", Game.sb("slot", 5, Vector4(2, 2, 2, 2)))
		d.custom_minimum_size = Vector2(18, 18)
		var ic := TextureRect.new()
		ic.texture = Game.tex("res://assets/badges/%s.png" % reg["lider"]["badge"]) if i == 3 else Game.tex(Game.GP + "ui/star.png")
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(12, 12)
		ic.modulate = Color(1, 1, 1, 0.25)
		d.add_child(ic)
		h.add_child(d)
		dots.append(ic)


func _mark(i: int) -> void:
	var ic: TextureRect = dots[i]
	ic.modulate = Color.WHITE
	ic.pivot_offset = Vector2(6, 6)
	ic.scale = Vector2(2, 2)
	create_tween().tween_property(ic, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)


func _show_banner(text: String) -> void:
	var banner := PanelContainer.new()
	banner.position = Vector2(-400, 120)
	banner.custom_minimum_size = Vector2(360, 0)
	add_child(banner)
	var l := Label.new()
	Game.heading(l, text, 16)
	l.add_theme_color_override("font_color", Color("ffd84a"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(l)
	var tw := create_tween()
	tw.tween_property(banner, "position:x", 140.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.2)
	tw.tween_property(banner, "position:x", 700.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tw.finished
	banner.queue_free()


# ---------------------------------------------------------------- emboscada
## A moita entra pela trilha, balança, o "!" aparece e o Nefasto salta dela
## investindo contra o grupo. Só então começa a batalha.
func _ambush(e: Dictionary) -> void:
	var style := _style(e)
	var kind: String = reg.get("chao", "terra")
	var spot := Vector2(452, GROUND_Y + 6)
	var land := Vector2(392, GROUND_Y)
	# esconderijo de acordo com o jeito de aparecer
	var hide: Node2D = null
	match style:
		"voo", "zigue", "sonho":
			hide = null
		"agua":
			hide = Puddle.new()
		"subsolo", "subsolo_raio":
			hide = Mound.new()
			(hide as Mound).kind = kind
		_:
			hide = _bush(kind)
	if hide:
		hide.material = cmat
		hide.position = Vector2(670, spot.y)
		hide.set_meta("fx", hide.position.x)
		stage.add_child(hide)
		_set_walking(true)
		while hide.position.x > spot.x:
			if want_leave:
				hide.queue_free()
				return
			var nx: float = hide.get_meta("fx") - WALK_SPEED * get_process_delta_time()
			hide.set_meta("fx", nx)
			hide.position.x = round(nx)
			await get_tree().process_frame
		_set_walking(false)
	else:
		await _walk(1.0)
		if want_leave:
			return
	await get_tree().create_timer(0.25).timeout
	# o aviso: cada um denuncia que está ali de um jeito
	var ground_sh: Shadow = null
	match style:
		"voo", "zigue":
			ground_sh = Shadow.new()
			ground_sh.w = 4.0
			ground_sh.position = land
			stage.add_child(ground_sh)
			var g := create_tween()
			g.tween_property(ground_sh, "w", 14.0, 0.7)
			await g.finished
		"sonho":
			for k in 2:
				_ring(land + Vector2(0, -22), Color("c58cff"))
				await get_tree().create_timer(0.35).timeout
		"agua":
			for k in 2:
				_puff(hide.position + Vector2(0, -2), Color("bfefff"), 8, 40.0)
				await get_tree().create_timer(0.35).timeout
		"subsolo", "subsolo_raio":
			for k in 2:
				_wiggle(hide, 0.08 if k == 0 else 0.16)
				_puff(hide.position, _dirt(kind), 8, 50.0)
				if style == "subsolo_raio":
					_puff(hide.position + Vector2(0, -6), Color("fff36a"), 6, 90.0)
				_shake(1.5 if k == 0 else 3.0)
				await get_tree().create_timer(0.4).timeout
		"gelo":
			var tw := create_tween()
			tw.tween_property(hide, "modulate", Color(0.7, 0.9, 1.3), 0.5)
			_puff(hide.position + Vector2(0, -14), Color("e8f8ff"), 14, 30.0)
			_wiggle(hide, 0.06)
			await get_tree().create_timer(0.6).timeout
		"fogo":
			for k in 2:
				_puff(hide.position + Vector2(0, -20), Color("6a5a62"), 10, 35.0, -30.0)
				_puff(hide.position + Vector2(0, -16), Color("ff8a3d"), 6, 60.0)
				_wiggle(hide, 0.07 if k == 0 else 0.14)
				await get_tree().create_timer(0.4).timeout
		_:
			for k in 2:
				_wiggle(hide, 0.06 if k == 0 else 0.13)
				_leaves(hide.position + Vector2(0, -18), kind)
				await get_tree().create_timer(0.45 if k == 0 else 0.2).timeout
	_exclaim()
	var kb := kid.position
	var hop := create_tween()
	hop.tween_property(kid, "position", kb + Vector2(-8, -6), 0.1)
	hop.tween_property(kid, "position", kb + Vector2(-10, 0), 0.1)
	# o Digialma
	var m := AnimatedSprite2D.new()
	m.sprite_frames = Game.monster_frames(e["id"])
	m.play("idle")
	m.centered = false
	m.offset = Game.foot_offset(e["id"])
	m.material = Game.sprite_mat()
	(m.material as ShaderMaterial).set_shader_parameter("nefasto", 1.0)
	var bs := 0.72 if Game.FOOT.get(e["id"], 80) > 85 else 1.0
	m.z_index = 2
	var ms := Shadow.new()
	ms.w = 14.0
	ms.show_behind_parent = true
	m.add_child(ms)
	stage.add_child(m)
	await _entrance(style, m, ms, bs, hide, land, kind)
	if ground_sh:
		ground_sh.queue_free()
	# aterrissagem comum
	ms.position = Vector2.ZERO
	m.position = land
	for side in [1, -1]:
		var d := Dust.new()
		d.position = land + Vector2(4 * side, 0)
		d.scale = Vector2(side, 1)
		stage.add_child(d)
	var sq := create_tween()
	sq.tween_property(m, "scale", Vector2(bs * 1.3, bs * 0.72), 0.07)
	sq.tween_property(m, "scale", Vector2(bs, bs), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if e.get("raro", false):
		_sparkle(land + Vector2(0, -30))
	await get_tree().create_timer(0.35).timeout
	if style == "preguica":
		# a capivara encara... e só então se irrita
		await get_tree().create_timer(0.6).timeout
	# rosna e investe
	var mat := m.material as ShaderMaterial
	mat.set_shader_parameter("flash_color", Color("ff3050"))
	var fl := create_tween()
	fl.tween_method(func(v): mat.set_shader_parameter("flash", v), 0.0, 0.8, 0.15)
	fl.tween_method(func(v): mat.set_shader_parameter("flash", v), 0.8, 0.0, 0.15)
	m.play("attack")
	await fl.finished
	var lunge := create_tween()
	lunge.tween_property(m, "position:x", kid.position.x + 26, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await lunge.finished
	_shake(6.0)
	await get_tree().create_timer(0.12).timeout
	if hide:
		hide.queue_free()
	m.queue_free()
	kid.position = kb


static func _style(e: Dictionary) -> String:
	match int(e["id"]):
		1, 2, 3:
			return "folhas"
		4:
			return "preguica"
		5:
			return "voo"
		16:
			return "zigue"
		6:
			return "gelo"
		7, 8, 9:
			return "fogo"
		10:
			return "sonho"
		11:
			return "subsolo_raio"
		15:
			return "subsolo"
		12, 13, 14:
			return "agua"
	return "salto"


func _entrance(style: String, m: AnimatedSprite2D, ms: Shadow, bs: float, hide: Node2D, land: Vector2, kind: String) -> void:
	match style:
		"voo", "zigue":
			var from := land + Vector2(190, -200)
			m.position = from
			m.scale = Vector2(bs, bs)
			var zig := style == "zigue"
			if zig:
				var trail := _trail(m, Color("bff6ff"))
				trail.emitting = true
			var tw := create_tween()
			tw.tween_method(func(k: float):
				var p := from.lerp(land, k)
				if zig:
					p.y += sin(k * TAU * 2.0) * 26.0 * (1.0 - k)
				m.position = p.round()
				m.rotation = (0.0 if zig else -0.5 * (1.0 - k))
				ms.position = Vector2(0, land.y - m.position.y), 0.0, 1.0, 0.9 if zig else 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN if not zig else Tween.EASE_IN_OUT)
			await tw.finished
			m.rotation = 0.0
		"sonho":
			m.position = land + Vector2(0, -10)
			m.scale = Vector2(bs * 0.6, bs * 0.6)
			m.modulate = Color(1, 1, 1, 0)
			_ring(land + Vector2(0, -22), Color("e3c2ff"))
			var tw := create_tween().set_parallel(true)
			tw.tween_property(m, "modulate:a", 1.0, 0.8)
			tw.tween_property(m, "scale", Vector2(bs, bs), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(m, "position:y", land.y - 4, 0.8)
			await tw.finished
		"subsolo", "subsolo_raio":
			m.position = hide.position + Vector2(0, -4)
			m.scale = Vector2(bs * 1.1, 0.05)
			_puff(hide.position, _dirt(kind), 22, 90.0)
			if style == "subsolo_raio":
				_puff(hide.position + Vector2(0, -10), Color("fff36a"), 16, 140.0)
			_shake(4.0)
			var up := create_tween()
			up.tween_property(m, "scale", Vector2(bs * 0.9, bs * 1.15), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			await up.finished
			await _arc(m, ms, m.position, land, 22.0, 0.3, bs)
		"preguica":
			m.position = hide.position + Vector2(4, -2)
			m.scale = Vector2(bs, bs)
			_wiggle(hide, 0.05)
			_leaves(hide.position + Vector2(0, -14), kind, 5)
			m.play("idle")
			m.speed_scale = 0.6
			var from := hide.position + Vector2(4, -2)
			var walk := create_tween()
			walk.tween_method(func(k: float):
				m.position = from.lerp(land, k).round() + Vector2(0, -round(absf(sin(k * PI * 4.0)) * 2.0)), 0.0, 1.0, 1.4)
			await walk.finished
			m.speed_scale = 1.0
		_:
			var from := hide.position + Vector2(0, -6)
			m.position = from
			m.scale = Vector2(bs * 0.3, bs * 0.3)
			match style:
				"folhas":
					_leaves(hide.position + Vector2(0, -20), kind, 40)
				"fogo":
					_puff(hide.position + Vector2(0, -16), Color("ff8a3d"), 24, 110.0)
					_puff(hide.position + Vector2(0, -20), Color("5a4a52"), 14, 50.0, -40.0)
					_trail(m, Color("ff8a3d")).emitting = true
				"gelo":
					_puff(hide.position + Vector2(0, -16), Color("d8f4ff"), 26, 130.0)
					_trail(m, Color("e8f8ff")).emitting = true
				"agua":
					_puff(hide.position + Vector2(0, -2), Color("7fd3ff"), 26, 120.0)
					_trail(m, Color("bfefff")).emitting = true
				_:
					_leaves(hide.position + Vector2(0, -20), kind, 26)
			if hide is Sprite2D:
				_wiggle(hide, 0.2)
			var spin := style == "folhas"
			await _arc(m, ms, from, land, 46.0, 0.42, bs, spin)


## Salto em arco com sombra presa ao chão.
func _arc(m: AnimatedSprite2D, ms: Shadow, from: Vector2, to: Vector2, height: float, dur: float, bs: float, spin := false) -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(k: float):
		var base := from.lerp(to, k)
		m.position = (base + Vector2(0, -sin(k * PI) * height)).round()
		ms.position = Vector2(0, base.y - m.position.y)
		if spin:
			m.rotation = -TAU * k, 0.0, 1.0, dur).set_trans(Tween.TRANS_SINE)
	tw.tween_property(m, "scale", Vector2(bs * 0.9, bs * 1.15), dur * 0.7)
	await tw.finished
	m.rotation = 0.0


func _bush(kind: String) -> Sprite2D:
	var b := Sprite2D.new()
	var rock := kind == "basalto"
	b.texture = Game.tex("res://assets/props/pedra.png" if rock else OBJ + "grass.png")
	b.centered = false
	b.offset = Vector2(-b.texture.get_width() * 0.5, -b.texture.get_height())
	var sc := 0.95 if rock else 0.85
	b.scale = Vector2(sc, sc)
	if rock:
		b.modulate = Color(0.55, 0.45, 0.55)
	var sh := Shadow.new()
	sh.w = b.texture.get_width() * 0.42
	sh.h = 5.0
	sh.show_behind_parent = true
	b.add_child(sh)
	return b


func _wiggle(n: Node2D, amp: float) -> void:
	var tw := create_tween()
	for j in 4:
		tw.tween_property(n, "rotation", amp if j % 2 == 0 else -amp, 0.06)
	tw.tween_property(n, "rotation", 0.0, 0.06)


func _dirt(kind: String) -> Color:
	return {"terra": Color("a9844f"), "areia": Color("e9c47e"), "basalto": Color("5a4248")}.get(kind, Color("a9844f"))


func _puff(at: Vector2, col: Color, n: int, vel: float, grav := 220.0) -> void:
	var p := CPUParticles2D.new()
	p.position = at
	p.amount = n
	p.one_shot = true
	p.explosiveness = 0.9
	p.lifetime = 0.7
	p.direction = Vector2(0, -1)
	p.spread = 60.0
	p.initial_velocity_min = vel * 0.5
	p.initial_velocity_max = vel
	p.gravity = Vector2(0, grav)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 3.0
	p.color = col
	p.z_index = 3
	stage.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func _trail(m: Node2D, col: Color) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = Vector2(0, -16)
	p.amount = 30
	p.lifetime = 0.45
	p.spread = 180.0
	p.initial_velocity_min = 5.0
	p.initial_velocity_max = 20.0
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.local_coords = false
	var g := Gradient.new()
	g.set_color(0, col)
	g.set_color(1, Color(col, 0.0))
	p.color_ramp = g
	p.show_behind_parent = true
	m.add_child(p)
	return p


func _ring(at: Vector2, col: Color) -> void:
	var r := RingFx.new()
	r.position = at
	r.col = col
	r.z_index = 3
	stage.add_child(r)


class RingFx extends Node2D:
	var t := 0.0
	var col := Color.WHITE

	func _process(delta: float) -> void:
		t += delta
		if t > 0.8:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := t / 0.8
		draw_arc(Vector2.ZERO, 6.0 + k * 34.0, 0, TAU, 32, Color(col, 1.0 - k), 2.0)
		draw_arc(Vector2.ZERO, 3.0 + k * 20.0, 0, TAU, 24, Color(col, (1.0 - k) * 0.6), 1.0)


class Puddle extends Node2D:
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		_ell(Vector2(0, -1), 22, 6, Color("2f6fa8"))
		_ell(Vector2(0, -2), 19, 4.5, Color("4fa8e8"))
		_ell(Vector2(-6 + sin(t * 2.0) * 2.0, -3), 6, 1.5, Color("bfefff"))
		var k := fmod(t, 1.2) / 1.2
		draw_arc(Vector2(4, -2), 3.0 + k * 10.0, 0, TAU, 20, Color(1, 1, 1, 0.6 * (1.0 - k)), 1.0)

	func _ell(c: Vector2, rx: float, ry: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24.0
			pts.append((c + Vector2(cos(a) * rx, sin(a) * ry)).round())
		draw_colored_polygon(pts, col)


class Mound extends Node2D:
	var kind := "terra"

	func _draw() -> void:
		var base: Color = {"terra": Color("a9844f"), "areia": Color("d9b06a"), "basalto": Color("3d2b31")}.get(kind, Color("a9844f"))
		var pts := PackedVector2Array()
		for i in 13:
			var a := PI * i / 12.0
			pts.append(Vector2(cos(a) * 16.0, -sin(a) * 7.0).round())
		draw_colored_polygon(pts, base)
		draw_rect(Rect2(-8, -6, 5, 2), base.lightened(0.25))
		draw_rect(Rect2(3, -4, 6, 1), base.darkened(0.3))
		draw_rect(Rect2(-14, -1, 28, 2), base.darkened(0.25))


func _leaves(at: Vector2, kind: String, n := 10) -> void:
	var p := CPUParticles2D.new()
	p.position = at
	p.amount = n
	p.one_shot = true
	p.explosiveness = 0.9
	p.lifetime = 0.8
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 90.0
	p.gravity = Vector2(0, 160)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 3.0
	p.color = {"terra": Color("6fae3c"), "areia": Color("8fcf5a"), "basalto": Color("8a7a86")}.get(kind, Color("6fae3c"))
	p.z_index = 3
	stage.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func _sparkle(at: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.position = at
	p.amount = 24
	p.one_shot = true
	p.explosiveness = 0.8
	p.lifetime = 0.9
	p.spread = 180.0
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 80.0
	p.gravity = Vector2(0, -20)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color = Color("ffd84a")
	p.z_index = 4
	stage.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func _shake(amount: float) -> void:
	var tw := create_tween()
	for i in 6:
		var o := Vector2(rng.randf_range(-amount, amount), rng.randf_range(-amount, amount)).round()
		tw.tween_callback(func():
			stage.position = o
			road.position = o)
		tw.tween_interval(0.03)
		amount *= 0.75
	tw.tween_callback(func():
		stage.position = Vector2.ZERO
		road.position = Vector2.ZERO)


func _exclaim() -> void:
	var l := Label.new()
	l.text = "!"
	l.add_theme_font_override("font", Game.font_title)
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Color("ff5070"))
	l.add_theme_color_override("font_outline_color", Color("2a1640"))
	l.add_theme_constant_override("outline_size", 6)
	l.position = kid.position + Vector2(-8, -84)
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y - 10, 0.12)
	tw.tween_property(l, "position:y", l.position.y, 0.12)
	await get_tree().create_timer(0.6).timeout
	l.queue_free()


func _battle(enemies: Array, leader := {}) -> String:
	back_btn.visible = false
	var fl := ColorRect.new()
	fl.size = Game.BASE
	fl.color = Color(1, 1, 1, 0)
	add_child(fl)
	for i in 3:
		fl.color.a = 0.8
		await get_tree().create_timer(0.07).timeout
		fl.color.a = 0.0
		await get_tree().create_timer(0.07).timeout
	var b := Battle.new()
	add_child(b)
	fl.queue_free()
	var r: String = await b.run(reg, enemies, leader)
	await create_tween().tween_property(b, "modulate:a", 0.0, 0.3).finished
	b.queue_free()
	back_btn.visible = leader.is_empty()
	return r


func _after_battle() -> void:
	Game.heal_team(0.25)
	for m in Game.team:
		var evo: Array = Game.MONSTERS[m["id"]]["evo"]
		if evo.size() > 0 and m["lv"] >= evo[1]:
			var ev := Evolution.new()
			add_child(ev)
			await ev.run(m)
	_spawn_team()


func _badge_scene(ld: Dictionary) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.01, 0.08, 0.75)
	dim.size = Game.BASE
	add_child(dim)
	var rays := Evolution.Rays.new()
	rays.position = Vector2(320, 148)
	rays.col = Color("ffd84a")
	rays.power = 0.8
	add_child(rays)
	var badge := TextureRect.new()
	badge.texture = Game.tex("res://assets/badges/%s.png" % ld["badge"])
	badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge.size = Vector2(128, 128)
	badge.position = Vector2(256, 84)
	badge.pivot_offset = Vector2(64, 64)
	badge.scale = Vector2(0.1, 0.1)
	add_child(badge)
	var l := Label.new()
	l.text = "Você conquistou a %s!" % ld["insignia"]
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color("ffd84a"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(640, 20)
	l.position = Vector2(0, 232)
	add_child(l)
	var tw := create_tween()
	tw.tween_property(badge, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(badge, "rotation", TAU, 0.6)
	var p := CPUParticles2D.new()
	p.position = Vector2(320, 148)
	p.amount = 70
	p.one_shot = true
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 240.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = Color("ffd84a")
	add_child(p)
	p.emitting = true
	await get_tree().create_timer(2.8).timeout
	for n in [dim, rays, badge, l, p]:
		n.queue_free()


## A cor volta: uma onda de luz sai do santuário e devolve a vida à região.
func _purify() -> void:
	kid.modulate = Color.WHITE
	kid.scale = Vector2(0.5, 0.5)
	kid.position = Vector2(300, GROUND_Y + 2)
	kid.play("idle_right")
	for i in pets.size():
		pets[i].modulate = Color.WHITE
		pets[i].walking = false
		pets[i].position = Vector2(250 - i * 62, GROUND_Y)
	var door: ColorRect = null
	for c in get_children():
		if c is ColorRect and (c as ColorRect).color.a > 0.9 and c.size == Game.BASE:
			door = c
	if door:
		await create_tween().tween_property(door, "color:a", 0.0, 0.5).finished
	await get_tree().create_timer(0.4).timeout
	var flash := CPUParticles2D.new()
	flash.position = Vector2(320, 220)
	flash.amount = 90
	flash.one_shot = true
	flash.explosiveness = 1.0
	flash.spread = 180.0
	flash.initial_velocity_min = 80.0
	flash.initial_velocity_max = 320.0
	flash.gravity = Vector2.ZERO
	flash.scale_amount_min = 2.0
	flash.scale_amount_max = 4.0
	flash.color = Color("fff3a8")
	add_child(flash)
	flash.emitting = true
	_shake(3.0)
	amb_node.set_corrupted(false)
	var tw := create_tween()
	tw.tween_method(func(r): cmat.set_shader_parameter("raio", r), 0.0, 1.6, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	cmat.set_shader_parameter("corrupt", 0.0)
	var fem: bool = not String(reg["nome"]).begins_with("Monte")
	await _show_banner("%s %s!" % [reg["nome"].to_upper(), "PURIFICADA" if fem else "PURIFICADO"])


func _lost() -> void:
	Game.heal_team(0.3, true)
	await dialog.play([["", "Todos viraram almas... O Elo puxou o grupo de volta ao mapa, ainda fraco."]])
	Game.change_scene("res://scenes/map.tscn")
