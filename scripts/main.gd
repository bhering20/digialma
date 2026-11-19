extends Node2D
## Digialma — protótipo v0.3 (pixel art estilo GBA)
## Idle RPG na barra de tarefas: monstrinhos virtuais lutam sozinhos,
## você cuida deles (comida, limpeza, carinho) e o vínculo decide a evolução.

const Data = preload("res://scripts/data.gd")

const STRIP_H := 92
const PANEL_H := 156
const ARENA_W := 440
const SAVE_PATH := "user://save.json"
const OFFLINE_CAP := 8 * 3600
const SLOT_X := [212, 144, 76]
const ENEMIES_PER_WAVE := 6
const EGG_NEED := 40
const ART := "res://assets/art/"

# Tudo é desenhado em resolução "GBA" (metade da tela) e ampliado 2x.
const PX := 2
const C_INK := Color("383848")
const C_PINK := Color("f878a8")
const C_GOLD := Color("f8d030")
const C_BOX := Color("f8f8f8")
const C_BORDER := Color("4a5880")

var party: Array = []
var reserve: Array = []
var enemies: Array = []
var shots: Array = []
var floaters: Array = []
var sparks: Array = []
var poops: Array = []
var stars: Array = []
var bits := 0
var food := 5
var fragments := 0
var wave := 1
var best_wave := 1
var kills_in_wave := 0
var spawned_in_wave := 0
var egg_progress := 0
var dex := {}
var upg := {"treino": 0, "vitalidade": 0}

var scroll := 0.0
var spawn_timer := 1.0
var hunger_timer := 0.0
var poop_timer := 120.0
var save_timer := 0.0
var ui_timer := 0.0
var anim_t := 0.0
var toast_time := 0.0
var expanded := false
var headless := false
var strip_w := 1280
var screen_rect := Rect2i(0, 0, 1280, 720)
var tex_cache := {}
var rng := RandomNumberGenerator.new()
var drag_from := Vector2i.ZERO
var dragging := false
var font: Font
var font_reg: Font
var sim := false
var sim_t := 0.0

# UI
var ui: Control
var hud_box: PanelContainer
var hud_label: Label
var egg_bar: ProgressBar
var toast_box: PanelContainer
var toast_label: Label
var panel: PanelContainer
var cards: Array = []
var shop_label: Label
var btn_treino: Button
var btn_vital: Button
var btn_food: Button
var btn_swap: Button
var btn_panel: Button
var btn_quit: Button
var btn_feed: Button


# ------------------------------------------------------------------ ciclo
func _ready() -> void:
	rng.randomize()
	headless = DisplayServer.get_name() == "headless"
	get_tree().auto_accept_quit = false
	for i in 40:
		stars.append(Vector3(rng.randf_range(0, 1), rng.randf_range(0.08, 0.6), rng.randf_range(0, TAU)))
	if not headless:
		screen_rect = DisplayServer.screen_get_usable_rect()
	strip_w = int(screen_rect.size.x / PX)
	_build_ui()
	if not _load_game():
		_new_game()
	_apply_window()
	_refresh_ui()
	var args := OS.get_cmdline_user_args()
	sim = "--sim" in args
	if "--shot" in args:
		_debug_shot("--panel" in args)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_game()
		get_tree().quit()


func _process(delta: float) -> void:
	anim_t += delta
	_tick_care(delta)
	_tick_combat(delta)
	_tick_fx(delta)
	save_timer += delta
	if save_timer > 30.0:
		save_timer = 0.0
		_save_game()
	ui_timer += delta
	if ui_timer > 0.25:
		ui_timer = 0.0
		_refresh_ui()
	queue_redraw()
	if sim:
		_sim_step(delta)


# ------------------------------------------------------------------ jogo novo / save
func _new_game() -> void:
	party = [_make_monster("brasinha")]
	_toast("Bem-vindo, Tamer! Clique no seu Digi para dar comida.")


func _make_monster(species: String) -> Dictionary:
	var tid := rng.randi() % Data.TAMER_NAMES.size()
	var m := {
		"species": species, "form": "baby", "level": 1, "xp": 0,
		"hp": 1.0, "hunger": 80.0, "bond": 10.0, "cd": rng.randf() * 0.8,
		"ko": false, "hit": 0.0, "lunge": 0.0, "flash": 0.0,
		"tamer_id": tid, "tamer": Data.TAMER_NAMES[tid],
	}
	m["hp"] = _max_hp(m)
	dex[species + ":baby"] = true
	return m


func _save_game() -> void:
	var data := {
		"party": party, "reserve": reserve, "bits": bits, "food": food,
		"fragments": fragments, "wave": wave, "best_wave": best_wave,
		"egg": egg_progress, "dex": dex, "upg": upg,
		"time": Time.get_unix_time_from_system(), "version": 2,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func _load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) != TYPE_DICTIONARY or not data.has("party"):
		return false
	party = data["party"]
	reserve = data.get("reserve", [])
	for m in party + reserve:
		m["level"] = int(m["level"])
		m["xp"] = int(m["xp"])
		m["ko"] = false
		m["hit"] = 0.0
		m["lunge"] = 0.0
		m["flash"] = 0.0
		m["cd"] = 0.5
		# saves da v0.1 não tinham tamer_id
		var idx := Data.TAMER_NAMES.find(m.get("tamer", ""))
		m["tamer_id"] = int(m.get("tamer_id", max(idx, 0)))
		m["tamer"] = Data.TAMER_NAMES[m["tamer_id"]]
	bits = int(data.get("bits", 0))
	food = int(data.get("food", 5))
	fragments = int(data.get("fragments", 0))
	wave = int(data.get("wave", 1))
	best_wave = int(data.get("best_wave", wave))
	egg_progress = int(data.get("egg", 0))
	dex = data.get("dex", {})
	var u = data.get("upg", {})
	upg["treino"] = int(u.get("treino", 0))
	upg["vitalidade"] = int(u.get("vitalidade", 0))
	_offline_progress(Time.get_unix_time_from_system() - float(data.get("time", 0)))
	return true


## Progresso enquanto o jogo estava fechado (limite de 8h, sem punição de fome).
func _offline_progress(elapsed: float) -> void:
	elapsed = clampf(elapsed, 0.0, OFFLINE_CAP)
	if elapsed < 60.0:
		return
	var kills := int(elapsed / 8.0)
	var got_bits := int(kills * _bits_per_kill() * 0.5)
	var got_xp := int(kills * _xp_per_kill() * 0.4)
	bits += got_bits
	for m in party:
		_give_xp(m, got_xp / max(1, party.size()))
		m["hunger"] = maxf(30.0, m["hunger"] - elapsed / 60.0)
		m["hp"] = _max_hp(m)
	_toast("Enquanto você estava fora (%d min): +%d Bits e +%d XP!" % [int(elapsed / 60.0), got_bits, got_xp])


# ------------------------------------------------------------------ status
func _stage(m: Dictionary) -> int:
	return Data.stage_of(m["form"])


func _max_hp(m: Dictionary) -> float:
	var hp: float = (30.0 + m["level"] * 6.0) * Data.STAGE_MULT[_stage(m)]
	hp *= 1.0 + 0.1 * upg["vitalidade"]
	if Data.path_of(m["form"]) == "luz":
		hp *= 1.2
	return hp


func _atk(m: Dictionary) -> float:
	var a: float = (5.0 + m["level"] * 1.2) * Data.STAGE_MULT[_stage(m)]
	a *= 1.0 + 0.1 * upg["treino"]
	if Data.path_of(m["form"]) == "sombra":
		a *= 1.25
	if m["hunger"] < 30.0:
		a *= 0.6
	a *= 1.0 + m["bond"] / 500.0
	return a


func _bits_per_kill() -> float:
	return 2.0 * pow(1.1, wave - 1)


func _xp_per_kill() -> float:
	return 4.0 * pow(wave, 1.15)


func _enemy_hp(boss: bool) -> float:
	return 18.0 * pow(1.13, wave - 1) * (8.0 if boss else 1.0)


func _enemy_atk(boss: bool) -> float:
	return 2.5 * pow(1.11, wave - 1) * (2.0 if boss else 1.0)


func _upg_cost(key: String) -> int:
	return int(50.0 * pow(1.55, upg[key]))


func _food_cost() -> int:
	return 10 + wave


func _name(m: Dictionary) -> String:
	return Data.form_name(m["species"], m["form"])


# ------------------------------------------------------------------ cuidado (tamagotchi)
func _tick_care(delta: float) -> void:
	hunger_timer += delta
	if hunger_timer >= 30.0:
		hunger_timer = 0.0
		for m in party:
			m["hunger"] = maxf(0.0, m["hunger"] - 1.0)
			if m["hunger"] <= 0.0:
				m["bond"] = maxf(0.0, m["bond"] - 0.5)
		if poops.size() > 0:
			for m in party:
				m["bond"] = maxf(0.0, m["bond"] - 0.2 * poops.size())
	poop_timer -= delta
	if poop_timer <= 0.0:
		poop_timer = rng.randf_range(90.0, 180.0)
		if poops.size() < 3 and party.size() > 0:
			poops.append({"x": rng.randf_range(16.0, 190.0), "t": 0.0})


func _feed(m: Dictionary) -> void:
	if food <= 0:
		_toast("Sem comida! Compre no Painel ou derrote Glitches.")
		return
	if m["hunger"] >= 95.0:
		_float_text(_slot_pos(party.find(m)) + Vector2(0, -64), "cheio!", Color("bff0ff"))
		return
	food -= 1
	m["hunger"] = minf(100.0, m["hunger"] + 35.0)
	m["bond"] = minf(100.0, m["bond"] + 2.0)
	var p := _slot_pos(party.find(m)) + Vector2(0, -40)
	_float_text(p + Vector2(0, -14), "+vínculo", C_PINK)
	_burst(p, C_PINK, 8)


func _clean(i: int) -> void:
	var p: Dictionary = poops[i]
	poops.remove_at(i)
	for m in party:
		m["bond"] = minf(100.0, m["bond"] + 1.0)
	var pos := Vector2(p["x"], _ground_y() - 8)
	_float_text(pos + Vector2(0, -12), "limpinho!", Color("bff0ff"))
	_burst(pos, Color("bff0ff"), 10)


# ------------------------------------------------------------------ combate
func _tick_combat(delta: float) -> void:
	if party.is_empty():
		return
	var front_x: float = SLOT_X[0]
	if enemies.is_empty():
		scroll += 24.0 * delta
	spawn_timer -= delta
	var boss_wave := wave % 10 == 0
	var to_spawn := 1 if boss_wave else ENEMIES_PER_WAVE
	if spawn_timer <= 0.0 and spawned_in_wave < to_spawn and enemies.size() < 3:
		spawn_timer = rng.randf_range(1.2, 2.2)
		spawned_in_wave += 1
		var els := Data.ELEMENTS.keys()
		var el: String = els[rng.randi() % els.size()]
		var hp := _enemy_hp(boss_wave)
		enemies.append({
			"x": float(ARENA_W) - 10.0, "hp": hp, "max": hp, "atk": _enemy_atk(boss_wave),
			"el": el, "boss": boss_wave, "cd": 1.0, "hit": 0.0, "lunge": 0.0, "ph": rng.randf() * TAU,
		})
	for i in enemies.size():
		var e: Dictionary = enemies[i]
		var stop_x := front_x + 42.0 + i * 40.0
		if e["x"] > stop_x:
			e["x"] = maxf(stop_x, e["x"] - 26.0 * delta)
		e["hit"] = maxf(0.0, e["hit"] - delta)
		e["lunge"] = maxf(0.0, e["lunge"] - delta * 3.0)
	for idx in party.size():
		var m: Dictionary = party[idx]
		m["hit"] = maxf(0.0, m["hit"] - delta)
		m["lunge"] = maxf(0.0, m["lunge"] - delta * 3.0)
		m["flash"] = maxf(0.0, m["flash"] - delta)
		if m["ko"] or enemies.is_empty():
			continue
		m["cd"] -= delta
		if m["cd"] <= 0.0:
			m["cd"] = 1.2 - _stage(m) * 0.12
			var target: Dictionary = enemies[0]
			if target["x"] > ARENA_W - 10:
				continue
			var el := Data.element_of(m["species"])
			var dmg := _atk(m) * Data.advantage(el, target["el"]) * rng.randf_range(0.9, 1.1)
			var crit: bool = rng.randf() < 0.05 + m["bond"] / 1000.0
			if crit:
				dmg *= 2.0
			m["lunge"] = 1.0
			shots.append({
				"pos": _slot_pos(idx) + Vector2(18, -30), "target": target, "dmg": dmg,
				"color": Color(Data.ELEMENTS[el]["main"]), "crit": crit, "trail": [],
			})
	if not enemies.is_empty():
		var e: Dictionary = enemies[0]
		if e["x"] <= front_x + 44.0:
			e["cd"] -= delta
			if e["cd"] <= 0.0:
				e["cd"] = 1.5
				e["lunge"] = 1.0
				var victim = _first_alive()
				if victim != null:
					victim["hp"] -= e["atk"]
					victim["hit"] = 0.25
					var vp := _slot_pos(party.find(victim))
					_float_text(vp + Vector2(0, -60), str(int(e["atk"])), Color("ff5070"))
					_burst(vp + Vector2(10, -26), Color("ff5070"), 5)
					if victim["hp"] <= 0.0:
						victim["hp"] = 0.0
						victim["ko"] = true
						if _first_alive() == null:
							_party_wiped()
	for s in shots.duplicate():
		var t: Dictionary = s["target"]
		var tp := Vector2(t["x"], _ground_y() - 22)
		s["trail"].push_front(s["pos"])
		if s["trail"].size() > 4:
			s["trail"].pop_back()
		s["pos"] = s["pos"].move_toward(tp, 320.0 * delta)
		if s["pos"].distance_to(tp) < 4.0 or not enemies.has(t):
			shots.erase(s)
			if enemies.has(t):
				t["hp"] -= s["dmg"]
				t["hit"] = 0.15
				_burst(tp, s["color"], 10 if s["crit"] else 5)
				_float_text(tp + Vector2(0, -26), ("CRÍTICO! " if s["crit"] else "") + str(int(s["dmg"])),
					C_GOLD if s["crit"] else Color.WHITE)
				if t["hp"] <= 0.0:
					_enemy_killed(t)


func _first_alive():
	for m in party:
		if not m["ko"]:
			return m
	return null


func _enemy_killed(e: Dictionary) -> void:
	enemies.erase(e)
	kills_in_wave += 1
	var pos := Vector2(e["x"], _ground_y() - 20)
	_burst(pos, Color(Data.ELEMENTS[e["el"]]["main"]), 16)
	var b := int(ceil(_bits_per_kill() * (5.0 if e["boss"] else 1.0)))
	bits += b
	_float_text(pos + Vector2(0, -28), "+%d Bits" % b, Color("7affc1"))
	var alive := party.filter(func(m): return not m["ko"])
	var xp := int(ceil(_xp_per_kill() * (5.0 if e["boss"] else 1.0) / max(1, alive.size())))
	for m in alive:
		_give_xp(m, xp)
		if m["hunger"] > 50.0:
			m["bond"] = minf(100.0, m["bond"] + 0.04)
	if rng.randf() < 0.08:
		food += 1
		_float_text(pos + Vector2(0, -38), "+comida", Color("ffb36b"))
	if e["boss"] or rng.randf() < 0.04:
		var n := 3 if e["boss"] else 1
		fragments += n
		_float_text(pos + Vector2(0, -48), "+%d fragmento" % n, Color("c49bff"))
	egg_progress += 1
	if egg_progress >= EGG_NEED:
		egg_progress = 0
		_hatch_egg()
	var need := 1 if wave % 10 == 0 else ENEMIES_PER_WAVE
	if kills_in_wave >= need:
		_next_wave()


func _next_wave() -> void:
	wave += 1
	best_wave = max(best_wave, wave)
	kills_in_wave = 0
	spawned_in_wave = 0
	spawn_timer = 1.5
	for m in party:
		if m["ko"]:
			m["ko"] = false
			m["hp"] = _max_hp(m) * 0.3
		else:
			m["hp"] = minf(_max_hp(m), m["hp"] + _max_hp(m) * 0.3)
	if wave % 10 == 0:
		_toast("Onda %d — um CHEFE GLITCH apareceu!" % wave)


func _party_wiped() -> void:
	var back := maxi(1, wave - 3)
	_toast("Recuar! Voltando para a onda %d para treinar." % back)
	wave = back
	kills_in_wave = 0
	spawned_in_wave = 0
	enemies.clear()
	shots.clear()
	spawn_timer = 2.0
	for m in party:
		m["ko"] = false
		m["hp"] = _max_hp(m)


func _give_xp(m: Dictionary, amount: int) -> void:
	m["xp"] += amount
	while m["xp"] >= Data.xp_needed(m["level"]):
		m["xp"] -= Data.xp_needed(m["level"])
		m["level"] += 1
		m["hp"] = _max_hp(m)
		_check_evolution(m)


func _check_evolution(m: Dictionary) -> void:
	var before: String = m["form"]
	if m["form"] == "baby" and m["level"] >= Data.LV_ROOKIE:
		m["form"] = "rookie"
	elif m["form"] == "rookie" and m["level"] >= Data.LV_CHAMP:
		m["form"] = "champ_luz" if m["bond"] >= Data.BOND_LUZ else "champ_sombra"
	if m["form"] != before:
		m["hp"] = _max_hp(m)
		m["flash"] = 1.2
		dex[m["species"] + ":" + m["form"]] = true
		var path_txt := ""
		if Data.path_of(m["form"]) == "sombra":
			path_txt = " (caminho da Sombra... cuide mais do vínculo!)"
		elif Data.path_of(m["form"]) == "luz":
			path_txt = " (caminho da Luz!)"
		_toast("%s evoluiu para %s!%s" % [Data.form_name(m["species"], before), _name(m), path_txt])


func _can_alma(m: Dictionary) -> bool:
	return _stage(m) == 2 and m["level"] >= Data.LV_ALMA and m["bond"] >= Data.BOND_ALMA and fragments >= Data.FRAG_ALMA


func _do_alma(m: Dictionary) -> void:
	if not _can_alma(m):
		return
	fragments -= Data.FRAG_ALMA
	var champ := _name(m)
	m["form"] = "alma_" + Data.path_of(m["form"])
	m["hp"] = _max_hp(m)
	m["flash"] = 2.0
	dex[m["species"] + ":" + m["form"]] = true
	var p := _slot_pos(party.find(m)) + Vector2(0, -30)
	_burst(p, C_GOLD, 30)
	_toast("DIGIALMA! %s e %s se fundiram em %s!" % [m["tamer"], champ, _name(m)])


func _hatch_egg() -> void:
	var options := Data.SPECIES.keys()
	var sp: String = options[rng.randi() % options.size()]
	var m := _make_monster(sp)
	_burst(Vector2(ARENA_W + 30, _ground_y() - 16), Color("c49bff"), 18)
	if party.size() < 3:
		party.append(m)
		_toast("Um ovo chocou! %s (parceiro de %s) entrou na equipe!" % [_name(m), m["tamer"]])
	else:
		reserve.append(m)
		_toast("Um ovo chocou! %s foi para a Reserva." % _name(m))


func _swap_reserve() -> void:
	if reserve.is_empty() or party.is_empty():
		return
	var out = party.pop_back()
	party.append(reserve.pop_front())
	reserve.append(out)


# ------------------------------------------------------------------ efeitos
func _float_text(p: Vector2, txt: String, c: Color) -> void:
	floaters.append({"pos": p, "txt": txt, "c": c, "t": 1.1})


func _burst(p: Vector2, c: Color, n: int) -> void:
	for i in n:
		var a := rng.randf() * TAU
		var v := Vector2(cos(a), sin(a)) * rng.randf_range(20, 70)
		sparks.append({"pos": p, "vel": v, "c": c, "t": rng.randf_range(0.4, 0.8), "r": float(rng.randi_range(1, 2))})


func _toast(t: String) -> void:
	toast_time = 6.0
	if toast_label:
		toast_label.text = t
	if headless:
		print("[toast] ", t)


func _tick_fx(delta: float) -> void:
	for f in floaters.duplicate():
		f["t"] -= delta
		f["pos"].y -= 16.0 * delta
		if f["t"] <= 0.0:
			floaters.erase(f)
	for s in sparks.duplicate():
		s["t"] -= delta
		s["pos"] += s["vel"] * delta
		s["vel"] *= 0.92
		if s["t"] <= 0.0:
			sparks.erase(s)
	for p in poops:
		p["t"] += delta
	toast_time = maxf(0.0, toast_time - delta)


# ------------------------------------------------------------------ desenho (estilo tela de batalha GBA)
func _strip_y() -> float:
	return float(PANEL_H if expanded else 0)


func _ground_y() -> float:
	return _strip_y() + STRIP_H - 9.0


func _slot_pos(i: int) -> Vector2:
	return Vector2(SLOT_X[clampi(i, 0, 2)], _ground_y())


func _tex(file: String) -> Texture2D:
	if not tex_cache.has(file):
		tex_cache[file] = load(ART + file + ".png")
	return tex_cache[file]


func _monster_tex(m: Dictionary) -> Texture2D:
	var f := "m_%s_%s" % [m["species"], m["form"]]
	if _stage(m) == 3:
		f += "_%d" % m["tamer_id"]
	return _tex(f)


## Desenha a textura pelo pé (centro de baixo), sempre em pixel inteiro.
func _sprite(tex: Texture2D, foot: Vector2, mod := Color.WHITE) -> void:
	if tex == null:
		return
	var sz := tex.get_size()
	draw_texture(tex, (foot - Vector2(sz.x * 0.5, sz.y - 1)).round(), mod)


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append((c + Vector2(cos(a) * rx, sin(a) * ry)).round())
	draw_colored_polygon(pts, col)


func _platform(c: Vector2, rx: float) -> void:
	_ellipse(c + Vector2(0, 1), rx + 2, 7, Color("70a850"))
	_ellipse(c, rx, 6, Color("98d070"))
	_ellipse(c + Vector2(-3, -1), rx * 0.7, 3, Color("b8e890"))


func _twinkle(p: Vector2, r: float, col: Color) -> void:
	p = p.round()
	draw_rect(Rect2(p.x - r, p.y, r * 2 + 1, 1), col)
	draw_rect(Rect2(p.x, p.y - r, 1, r * 2 + 1), col)


func _text(p: Vector2, txt: String, size: int, col: Color, bold := true) -> void:
	var f := font if bold else font_reg
	var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := (p - Vector2(w * 0.5, 0)).round()
	draw_string_outline(f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, Color(C_INK, col.a))
	draw_string(f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## Barra de HP estilo GBA: verde > amarelo > vermelho.
func _hp_bar(x: float, y: float, w: float, ratio: float) -> void:
	x = round(x)
	y = round(y)
	draw_rect(Rect2(x - 1, y - 1, w + 2, 5), Color("404040"))
	draw_rect(Rect2(x, y, w, 3), Color("505868"))
	var col := Color("58d080")
	var top := Color("70f8a8")
	if ratio < 0.2:
		col = Color("c83838"); top = Color("f85838")
	elif ratio < 0.5:
		col = Color("c8a808"); top = Color("f8e038")
	var fw: float = round(w * clampf(ratio, 0, 1))
	draw_rect(Rect2(x, y, fw, 3), col)
	draw_rect(Rect2(x, y, fw, 1), top)


func _draw() -> void:
	var sy := _strip_y()
	var gy := _ground_y()
	# Fundo verde claro com listras (como o fundo de batalha do GBA)
	draw_rect(Rect2(0, sy, strip_w, STRIP_H), Color("c8e8a8"))
	for y in range(int(sy) + 2, int(sy + STRIP_H), 4):
		draw_rect(Rect2(0, y, strip_w, 1), Color("d8f0c0"))
	# Nuvens ao fundo
	for i in 6:
		var cx: float = fmod(i * 173.0 - scroll * 0.2 + 2000.0, ARENA_W + 60.0) - 30.0
		var cy := sy + 8.0 + (i % 3) * 7.0
		_ellipse(Vector2(cx, cy), 14, 4, Color("e8f8e0"))
		_ellipse(Vector2(cx + 8, cy - 2), 9, 4, Color("f8fff0"))
	# Morros ao longe
	var pts := PackedVector2Array([Vector2(0, gy - 4)])
	for x in range(0, ARENA_W + 140, 8):
		pts.append(Vector2(x, round(gy - 16 - 6 * sin((x + scroll * 0.4) * 0.03) - 3 * sin((x + scroll * 0.4) * 0.071))))
	pts.append(Vector2(ARENA_W + 140, gy - 4))
	draw_colored_polygon(pts, Color("a8d888"))
	# Grama
	draw_rect(Rect2(0, gy - 6, strip_w, sy + STRIP_H - gy + 6), Color("88c060"))
	draw_rect(Rect2(0, gy - 6, strip_w, 1), Color("b0e080"))
	var off := fmod(scroll, 24.0)
	for i in range(int(strip_w / 24.0) + 2):
		var x: float = round(i * 24.0 - off)
		draw_rect(Rect2(x, gy - 2, 1, 2), Color("68a048"))
		draw_rect(Rect2(x + 1, gy - 3, 1, 3), Color("68a048"))
		draw_rect(Rect2(x + 9, gy + 4, 2, 1), Color("68a048"))
	draw_rect(Rect2(0, sy, strip_w, 1), C_INK)
	# Plataformas
	for i in party.size():
		_platform(_slot_pos(i), 22)
	for e in enemies:
		_platform(Vector2(e["x"], gy), 26 if e["boss"] else 20)
	# Cocô
	for p in poops:
		var hop: float = 1.0 if int(p["t"] * 3.0) % 2 == 0 else 0.0
		_sprite(_tex("poop"), Vector2(p["x"], gy - hop))
	var walking := enemies.is_empty()
	var step := int(anim_t * 6.0)
	# Crianças + Digis
	for i in party.size():
		var m: Dictionary = party[i]
		var pos := _slot_pos(i)
		var mod := Color(1, 1, 1, 0.35) if m["ko"] else Color.WHITE
		if m["hit"] > 0.0 and int(m["hit"] * 20) % 2 == 0:
			mod = Color(1, 1, 1, 0.2)
		if m["flash"] > 0.0:
			var fl: float = m["flash"]
			mod = Color(1 + fl * 2, 1 + fl * 2, 1 + fl * 2)
			_ellipse(pos + Vector2(0, -28), 34.0 * fl, 30.0 * fl, Color(1, 1, 0.85, 0.35 * fl))
		var hop := 0.0
		if walking and not m["ko"]:
			hop = [0.0, 1.0, 2.0, 1.0][(step + i) % 4]
		elif int(anim_t * 2.0 + i) % 2 == 0:
			hop = 1.0
		var lunge: float = round(m["lunge"] * 6.0)
		if _stage(m) < 3:
			var th := float((step + i + 1) % 2) if walking else 0.0
			_sprite(_tex("t_%d" % m["tamer_id"]), pos + Vector2(-30, -th), mod)
		_sprite(_monster_tex(m), pos + Vector2(lunge, -hop), mod)
		_hp_bar(pos.x - 14, sy + 4, 28, m["hp"] / _max_hp(m))
		draw_rect(Rect2(round(pos.x - 14), sy + 8, round(28 * m["hunger"] / 100.0), 1), Color("f8a040"))
		if m["hunger"] < 30.0 and int(anim_t * 2) % 2 == 0:
			_text(pos + Vector2(26, -44), "fome!", 10, Color("f8a040"))
		if _can_alma(m):
			_text(pos + Vector2(0, -60 + (int(anim_t * 4) % 2)), "DIGIALMA!", 10, C_GOLD)
		if _stage(m) == 3:
			for k in 3:
				var a := anim_t * 1.5 + k * TAU / 3.0
				_twinkle(pos + Vector2(cos(a) * 28, -30 + sin(a) * 16), 2, Color("fff8b0"))
	# Inimigos
	for e in enemies:
		var tex := _tex("g_%s%s" % [e["el"], "_boss" if e["boss"] else ""])
		var fy := float(int(anim_t * 3.0 + e["ph"]) % 2) * 2.0
		var emod := Color.WHITE
		if e["hit"] > 0.0:
			emod = Color(2.5, 2.5, 2.5)
		var ex: float = e["x"] - round(e["lunge"] * 8.0)
		_sprite(tex, Vector2(ex, gy - 2 - fy), emod)
		_hp_bar(ex - (20 if e["boss"] else 14), sy + 4, 40 if e["boss"] else 28, e["hp"] / e["max"])
	# Projéteis
	for s in shots:
		var col: Color = s["color"]
		var trail: Array = s["trail"]
		for k in trail.size():
			draw_rect(Rect2((trail[k] as Vector2).round() - Vector2(1, 1), Vector2(2, 2)), Color(col, 0.6 - k * 0.12))
		_ellipse(s["pos"], 4 if s["crit"] else 3, 4 if s["crit"] else 3, col.darkened(0.3))
		_ellipse(s["pos"], 2 if s["crit"] else 1.5, 2 if s["crit"] else 1.5, Color.WHITE)
	# Ovo
	var eg := Vector2(ARENA_W + 30, gy)
	_platform(eg, 14)
	var near := egg_progress > EGG_NEED * 0.75
	var shake := float([0, 1, 0, -1][int(anim_t * 8) % 4]) if near else 0.0
	_sprite(_tex("egg"), eg + Vector2(shake, -1))
	# Faíscas e textos
	for s in sparks:
		var c: Color = s["c"]
		c.a = clampf(s["t"] * 2.0, 0, 1)
		_twinkle(s["pos"], s["r"], c)
	for f in floaters:
		var c: Color = f["c"]
		c.a = clampf(f["t"] * 1.5, 0, 1)
		_text(f["pos"], f["txt"], 10, c)


# ------------------------------------------------------------------ entrada
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = event.position
		var gy := _ground_y()
		for i in poops.size():
			if p.distance_to(Vector2(poops[i]["x"], gy - 6)) < 12.0:
				_clean(i)
				return
		for i in party.size():
			var sp := _slot_pos(i)
			if Rect2(sp.x - 24, sp.y - 56, 48, 56).has_point(p):
				_feed(party[i])
				return
		if not headless:
			dragging = true
			drag_from = DisplayServer.mouse_get_position() - get_window().position
	elif event is InputEventMouseButton and not event.pressed:
		dragging = false
	elif event is InputEventMouseMotion and dragging and not headless:
		var np := DisplayServer.mouse_get_position() - drag_from
		get_window().position = Vector2i(get_window().position.x, np.y)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_save_game()
		get_tree().quit()


# ------------------------------------------------------------------ UI (caixas estilo GBA)
func _sb(bg: Color, border := C_BORDER, bw := 2, radius := 3, mh := 5, mv := 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = false
	sb.content_margin_left = mh
	sb.content_margin_right = mh
	sb.content_margin_top = mv
	sb.content_margin_bottom = mv
	return sb


func _make_theme() -> Theme:
	var th := Theme.new()
	th.default_font = font_reg
	th.default_font_size = 10
	for t in ["Label", "Button"]:
		th.set_color("font_color", t, C_INK)
		th.set_color("font_shadow_color", t, Color("d0d0c8"))
		th.set_constant("shadow_offset_x", t, 1)
		th.set_constant("shadow_offset_y", t, 1)
		th.set_constant("outline_size", t, 0)
	th.set_color("font_hover_color", "Button", C_INK)
	th.set_color("font_pressed_color", "Button", C_INK)
	th.set_color("font_disabled_color", "Button", Color("a0a0a0"))
	th.set_stylebox("normal", "Button", _sb(C_BOX))
	th.set_stylebox("hover", "Button", _sb(Color("fff4b8"), Color("e07030")))
	th.set_stylebox("pressed", "Button", _sb(Color("f8d860"), Color("e07030")))
	th.set_stylebox("disabled", "Button", _sb(Color("e0e0d8"), Color("a0a8b8")))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_stylebox("background", "ProgressBar", _sb(Color("505868"), Color("404040"), 1, 0, 0, 0))
	th.set_color("font_color", "ProgressBar", Color(0, 0, 0, 0))
	return th


func _bar(col: Color) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.custom_minimum_size = Vector2(80, 5)
	pb.show_percentage = false
	pb.add_theme_stylebox_override("fill", _sb(col, col, 0, 0, 0, 0))
	return pb


## Caixa de diálogo com borda dupla (escura por fora, azul clara por dentro).
func _dialog_box() -> Array:
	var outer := PanelContainer.new()
	outer.add_theme_stylebox_override("panel", _sb(Color("404858"), Color("404858"), 0, 4, 1, 1))
	var inner := PanelContainer.new()
	inner.add_theme_stylebox_override("panel", _sb(C_BOX, Color("90b0d8"), 2, 3, 6, 2))
	outer.add_child(inner)
	return [outer, inner]


func _build_ui() -> void:
	font = load("res://assets/fonts/pixelify-sans-latin-700-normal.woff2")
	font_reg = load("res://assets/fonts/pixelify-sans-latin-400-normal.woff2")
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = _make_theme()
	layer.add_child(ui)

	# Caixa de status (como a caixa de nome/Lv/HP da batalha)
	hud_box = PanelContainer.new()
	hud_box.add_theme_stylebox_override("panel", _sb(Color("f8f8d8"), Color("404040"), 2, 4, 6, 3))
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 0)
	hud_label = Label.new()
	hv.add_child(hud_label)
	var eh := HBoxContainer.new()
	var el := Label.new()
	el.text = "OVO"
	el.add_theme_font_override("font", font)
	el.add_theme_font_size_override("font_size", 8)
	el.add_theme_color_override("font_color", Color("e07030"))
	eh.add_child(el)
	egg_bar = _bar(Color("b088f8"))
	egg_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	eh.add_child(egg_bar)
	hv.add_child(eh)
	hud_box.add_child(hv)
	hud_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hud_box)

	var tb := _dialog_box()
	toast_box = tb[0]
	toast_label = Label.new()
	tb[1].add_child(toast_label)
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(toast_box)

	btn_panel = _mk_button("PAINEL", func():
		expanded = not expanded
		_apply_window())
	btn_quit = _mk_button("X", func():
		_save_game()
		get_tree().quit())
	btn_feed = _mk_button("ALIMENTAR", func():
		for m in party:
			_feed(m))
	for b in [btn_panel, btn_quit, btn_feed]:
		ui.add_child(b)

	# Painel (inspirado na tela de equipe do GBA)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _sb(Color("6890c8"), Color("384870"), 2, 4, 6, 6))
	ui.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	for i in 3:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _sb(Color("f8f8f0"), Color("384870"), 2, 6, 4, 3))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 4)
		card.add_child(hb)
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(72, 72)
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hb.add_child(portrait)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 0)
		hb.add_child(vb)
		var title := Label.new()
		title.add_theme_font_override("font", font)
		title.add_theme_font_size_override("font_size", 12)
		vb.add_child(title)
		var sub := Label.new()
		sub.add_theme_font_size_override("font_size", 8)
		sub.add_theme_color_override("font_color", Color("6870a0"))
		vb.add_child(sub)
		var bars := {}
		for b in [["HP", Color("58d080")], ["FOME", Color("f8a040")], ["VÍNC.", C_PINK], ["EXP", Color("40a8f8")]]:
			var bl := HBoxContainer.new()
			bl.add_theme_constant_override("separation", 3)
			var lb := Label.new()
			lb.text = b[0]
			lb.custom_minimum_size = Vector2(30, 0)
			lb.add_theme_font_override("font", font)
			lb.add_theme_font_size_override("font_size", 8)
			lb.add_theme_color_override("font_color", Color("e07030"))
			bl.add_child(lb)
			var pb := _bar(b[1])
			pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			bl.add_child(pb)
			vb.add_child(bl)
			bars[b[0]] = pb
		var hint := Label.new()
		hint.add_theme_font_size_override("font_size", 8)
		vb.add_child(hint)
		var bh := HBoxContainer.new()
		bh.add_theme_constant_override("separation", 3)
		var bf := _mk_button("ALIMENTAR", func():
			if i < party.size():
				_feed(party[i]))
		var ba := _mk_button("DIGIALMA", func():
			if i < party.size():
				_do_alma(party[i]))
		bh.add_child(bf)
		bh.add_child(ba)
		vb.add_child(bh)
		row.add_child(card)
		cards.append({"box": card, "portrait": portrait, "title": title, "sub": sub, "bars": bars, "hint": hint, "alma": ba})
	var shop_box := PanelContainer.new()
	shop_box.add_theme_stylebox_override("panel", _sb(Color("f8f8f0"), Color("384870"), 2, 6, 5, 3))
	var shop := VBoxContainer.new()
	shop.add_theme_constant_override("separation", 2)
	shop_box.add_child(shop)
	shop_label = Label.new()
	shop_label.add_theme_font_override("font", font)
	shop_label.add_theme_font_size_override("font_size", 12)
	shop.add_child(shop_label)
	btn_treino = _mk_button("", func(): _buy("treino"))
	btn_vital = _mk_button("", func(): _buy("vitalidade"))
	btn_food = _mk_button("", func():
		if bits >= _food_cost():
			bits -= _food_cost()
			food += 1)
	btn_swap = _mk_button("TROCAR 3º COM A RESERVA", _swap_reserve)
	for b in [btn_treino, btn_vital, btn_food, btn_swap]:
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		shop.add_child(b)
	row.add_child(shop_box)


func _mk_button(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", 8)
	b.pressed.connect(cb)
	return b


func _buy(key: String) -> void:
	var c := _upg_cost(key)
	if bits >= c:
		bits -= c
		upg[key] += 1
		for m in party:
			m["hp"] = minf(m["hp"], _max_hp(m))


func _apply_window() -> void:
	var h := STRIP_H + (PANEL_H if expanded else 0)
	var win := get_window()
	if not headless:
		win.size = Vector2i(strip_w * PX, h * PX)
		win.position = Vector2i(screen_rect.position.x, screen_rect.end.y - h * PX)
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	win.content_scale_size = Vector2i(strip_w, h)
	var sy := _strip_y()
	hud_box.position = Vector2(ARENA_W + 60, sy + 14)
	toast_box.position = Vector2(236, sy + 14)
	btn_panel.position = Vector2(strip_w - 80, sy + 8)
	btn_quit.position = Vector2(strip_w - 22, sy + 8)
	btn_feed.position = Vector2(strip_w - 80, sy + 30)
	panel.visible = expanded
	panel.position = Vector2(4, 4)
	panel.size = Vector2(min(strip_w - 8, 900), PANEL_H - 8)


func _refresh_ui() -> void:
	hud_label.text = "ONDA %d   recorde %d\nBits %d  Comida %d  Fragm. %d\nReserva %d   Dex %d/24" % [
		wave, best_wave, bits, food, fragments, reserve.size(), dex.size()]
	egg_bar.max_value = EGG_NEED
	egg_bar.value = egg_progress
	toast_box.visible = toast_time > 0.0 and toast_label.text != ""
	if not expanded:
		return
	for i in 3:
		var c: Dictionary = cards[i]
		c["box"].visible = i < party.size()
		if i >= party.size():
			continue
		var m: Dictionary = party[i]
		c["portrait"].texture = _monster_tex(m)
		c["title"].text = "%s  Nv%d" % [_name(m), m["level"]]
		var path := Data.path_of(m["form"])
		c["sub"].text = "%s / %s / %s%s" % [Data.STAGE_NAMES[_stage(m)],
			Data.ELEMENTS[Data.element_of(m["species"])]["name"], m["tamer"],
			(" / " + path.capitalize()) if path != "" else ""]
		var bars: Dictionary = c["bars"]
		var ratio: float = m["hp"] / _max_hp(m)
		var hp_col := Color("58d080") if ratio >= 0.5 else (Color("e8c020") if ratio >= 0.2 else Color("e04040"))
		bars["HP"].add_theme_stylebox_override("fill", _sb(hp_col, hp_col, 0, 0, 0, 0))
		bars["HP"].max_value = _max_hp(m)
		bars["HP"].value = m["hp"]
		bars["FOME"].value = m["hunger"]
		bars["VÍNC."].value = m["bond"]
		bars["EXP"].max_value = Data.xp_needed(m["level"])
		bars["EXP"].value = m["xp"]
		var nxt := ""
		match m["form"]:
			"baby":
				nxt = "Evolui no Nv %d" % Data.LV_ROOKIE
			"rookie":
				nxt = "Nv %d: vínculo %d+ = Luz" % [Data.LV_CHAMP, Data.BOND_LUZ]
			"champ_luz", "champ_sombra":
				nxt = "Digialma: Nv%d, vínc.%d, %d frag." % [Data.LV_ALMA, Data.BOND_ALMA, Data.FRAG_ALMA]
			_:
				nxt = "Fundido com %s!" % m["tamer"]
		c["hint"].text = "ATQ %d  %s" % [int(_atk(m)), nxt]
		c["alma"].disabled = not _can_alma(m)
		c["alma"].visible = _stage(m) >= 2
	shop_label.text = "LOJA   %d Bits" % bits
	btn_treino.text = "Treino +10%% ATQ (Nv%d)  %d" % [upg["treino"], _upg_cost("treino")]
	btn_vital.text = "Vitalidade +10%% HP (Nv%d)  %d" % [upg["vitalidade"], _upg_cost("vitalidade")]
	btn_food.text = "Comprar comida  %d" % _food_cost()
	btn_treino.disabled = bits < _upg_cost("treino")
	btn_vital.disabled = bits < _upg_cost("vitalidade")
	btn_food.disabled = bits < _food_cost()
	btn_swap.disabled = reserve.is_empty()


# ------------------------------------------------------------------ testes
func _sim_step(delta: float) -> void:
	sim_t += delta
	if fmod(sim_t, 300.0) < delta:
		var lv := []
		for m in party:
			lv.append("%s Nv%d fome%d vinc%d" % [_name(m), m["level"], m["hunger"], m["bond"]])
		print("[sim %dmin] onda %d bits %d frag %d food %d | %s" % [int(sim_t / 60), wave, bits, fragments, food, ", ".join(lv)])
		for m in party:
			if m["hunger"] < 60:
				_feed(m)
		while poops.size() > 0:
			_clean(0)
		for k in ["treino", "vitalidade", "treino"]:
			_buy(k)
		for m in party:
			_do_alma(m)


func _debug_shot(with_panel: bool) -> void:
	party = [_make_monster("brasinha"), _make_monster("gotinha"), _make_monster("brotinho")]
	party[0]["form"] = "alma_luz"; party[0]["level"] = 32; party[0]["bond"] = 92.0
	party[1]["form"] = "champ_sombra"; party[1]["level"] = 18; party[1]["bond"] = 35.0
	party[2]["form"] = "rookie"; party[2]["level"] = 7; party[2]["hunger"] = 20.0; party[2]["bond"] = 55.0
	for m in party:
		m["hp"] = _max_hp(m) * 0.8
	party[1]["hp"] = _max_hp(party[1]) * 0.35
	poops.append({"x": 30.0, "t": 0.0})
	wave = 12; bits = 1234; food = 4; fragments = 6; egg_progress = 25; best_wave = 14
	reserve = []
	expanded = with_panel
	_apply_window()
	_toast("Ramalho está com fome! Clique nele para dar comida.")
	await get_tree().create_timer(5.0).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/shot.png")
	get_tree().quit()
