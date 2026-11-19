extends Node2D
## Partículas de ambiente desenhadas à mão, por região:
##  floresta: vaga-lumes, folhas caindo e raios de sol
##  costa: brilhos no ar, bolhas e brisa
##  vulcao: brasas subindo, cinzas caindo e pulsos de calor

var kind := "floresta"
var t := 0.0
var rng := RandomNumberGenerator.new()
var parts: Array = []
var parts2: Array = []
var area := Rect2(0, 0, 640, 360)
## Partículas de corrupção sobrepostas (glitches, cinza roxa, faixas de interferência).
var corrupted := false
var cparts: Array = []
var glitch_t := 0.0
var glitch_y := 0.0
var glitch_on := 0.0


static func kind_for(region: Dictionary) -> String:
	match region.get("arena", ""):
		"arena_water":
			return "costa"
		"arean_fire":
			return "vulcao"
	return "floresta"


func _ready() -> void:
	rng.randomize()
	z_index = 5
	match kind:
		"floresta":
			for i in 26:
				parts.append({"p": _rand_pt(120, 330), "ph": rng.randf() * TAU, "s": rng.randf_range(0.5, 1.2)})
			for i in 12:
				parts2.append({"p": Vector2(rng.randf_range(0, 640), rng.randf_range(-360, 0)), "ph": rng.randf() * TAU, "v": rng.randf_range(14, 26),
					"c": [Color("8fd45a"), Color("ffc24a"), Color("ff8a5a")][i % 3]})
		"costa":
			for i in 22:
				parts.append({"p": _rand_pt(20, 200), "ph": rng.randf() * TAU, "s": rng.randf_range(0.6, 1.4)})
			for i in 14:
				parts2.append({"p": _rand_pt(200, 380), "ph": rng.randf() * TAU, "v": rng.randf_range(8, 18), "r": rng.randf_range(1.5, 3.5)})
		"vulcao":
			for i in 40:
				parts.append({"p": _rand_pt(0, 360), "ph": rng.randf() * TAU, "v": rng.randf_range(18, 45), "life": rng.randf()})
			for i in 18:
				parts2.append({"p": _rand_pt(-40, 360), "ph": rng.randf() * TAU, "v": rng.randf_range(6, 14)})


func set_corrupted(on: bool) -> void:
	corrupted = on
	cparts.clear()
	if on:
		for i in 46:
			cparts.append({"p": _rand_pt(-20, 360), "v": rng.randf_range(6, 18), "ph": rng.randf() * TAU, "s": rng.randi_range(1, 3), "q": rng.randf() < 0.3})


func _rand_pt(y0: float, y1: float) -> Vector2:
	return Vector2(rng.randf_range(0, 640), rng.randf_range(y0, y1))


func _process(delta: float) -> void:
	t += delta
	if corrupted:
		for c in cparts:
			c["p"].y -= c["v"] * delta
			c["p"].x += sin(t * 1.1 + c["ph"]) * 6.0 * delta
			if c["p"].y < -10:
				c["p"] = _rand_pt(360, 380)
		glitch_t -= delta
		if glitch_t <= 0.0:
			glitch_t = rng.randf_range(1.2, 3.5)
			glitch_y = rng.randf_range(40, 320)
			glitch_on = 0.12
	match kind:
		"floresta":
			for l in parts2:
				l["p"].y += l["v"] * delta
				l["p"].x += sin(t * 1.3 + l["ph"]) * 14.0 * delta - 6.0 * delta
				if l["p"].y > 370:
					l["p"] = Vector2(rng.randf_range(0, 700), -10)
		"costa":
			for b in parts2:
				b["p"].y -= b["v"] * delta
				b["p"].x += sin(t * 2.0 + b["ph"]) * 10.0 * delta
				if b["p"].y < 150:
					b["p"] = _rand_pt(360, 380)
		"vulcao":
			for e in parts:
				e["p"].y -= e["v"] * delta
				e["p"].x += sin(t * 1.7 + e["ph"]) * 16.0 * delta + 4.0 * delta
				e["life"] += delta * 0.35
				if e["p"].y < -8 or e["life"] > 1.0:
					e["p"] = _rand_pt(240, 380)
					e["life"] = 0.0
			for a in parts2:
				a["p"].y += a["v"] * delta
				a["p"].x += sin(t + a["ph"]) * 8.0 * delta - 5.0 * delta
				if a["p"].y > 370:
					a["p"] = Vector2(rng.randf_range(0, 680), -10)
	queue_redraw()


func _draw() -> void:
	if corrupted:
		_draw_corruption()
		# na região corrompida, só restam poucos brilhos da natureza
		if kind == "floresta":
			return
	match kind:
		"floresta":
			for i in 4:
				var a := 0.045 + 0.03 * sin(t * 0.7 + i)
				var x0 := 380.0 + i * 70.0
				draw_colored_polygon(PackedVector2Array([Vector2(x0, -10), Vector2(x0 + 30, -10), Vector2(x0 - 140, 380), Vector2(x0 - 210, 380)]), Color(1, 0.95, 0.7, a))
			for f in parts:
				var p: Vector2 = f["p"] + Vector2(sin(t * f["s"] + f["ph"]) * 12.0, cos(t * f["s"] * 1.3 + f["ph"]) * 8.0)
				var a := 0.5 + 0.5 * sin(t * 3.0 + f["ph"])
				draw_circle(p.round(), 3.0, Color(1, 0.95, 0.5, a * 0.25))
				draw_rect(Rect2(p.round(), Vector2(1, 1)), Color(1, 1, 0.8, a))
			for l in parts2:
				var p: Vector2 = (l["p"] as Vector2).round()
				var flip := int(t * 4.0 + l["ph"]) % 2 == 0
				draw_rect(Rect2(p, Vector2(3 if flip else 2, 2)), l["c"])
				draw_rect(Rect2(p + Vector2(1, 2), Vector2(1, 1)), (l["c"] as Color).darkened(0.3))
		"costa":
			for i in 3:
				var a := 0.04 + 0.025 * sin(t * 0.6 + i * 2.0)
				var x0 := 120.0 + i * 160.0
				draw_colored_polygon(PackedVector2Array([Vector2(x0, -10), Vector2(x0 + 40, -10), Vector2(x0 + 140, 380), Vector2(x0 + 60, 380)]), Color(0.85, 0.97, 1.0, a))
			for s in parts:
				var a := maxf(0.0, sin(t * 2.5 * s["s"] + s["ph"]))
				if a > 0.6:
					var p: Vector2 = (s["p"] as Vector2).round()
					var k := 2.0 if a > 0.9 else 1.0
					draw_rect(Rect2(p - Vector2(k, 0), Vector2(k * 2 + 1, 1)), Color(1, 1, 1, a))
					draw_rect(Rect2(p - Vector2(0, k), Vector2(1, k * 2 + 1)), Color(1, 1, 1, a))
			for b in parts2:
				var p: Vector2 = (b["p"] as Vector2).round()
				draw_arc(p, b["r"], 0, TAU, 10, Color(0.85, 0.97, 1.0, 0.55), 1.0)
				draw_rect(Rect2(p + Vector2(-1, -1), Vector2(1, 1)), Color(1, 1, 1, 0.8))
		"vulcao":
			# pulso de calor no chão
			var heat := 0.05 + 0.04 * sin(t * 1.4)
			draw_rect(Rect2(0, 250, 640, 110), Color(1, 0.35, 0.1, heat))
			for a in parts2:
				var p: Vector2 = (a["p"] as Vector2).round()
				draw_rect(Rect2(p, Vector2(2, 1)), Color(0.55, 0.5, 0.55, 0.7))
			for e in parts:
				var p: Vector2 = (e["p"] as Vector2).round()
				var fl := 0.6 + 0.4 * sin(t * 12.0 + e["ph"])
				var life: float = e["life"]
				var col := Color("ffe08a").lerp(Color("ff4a1a"), life)
				col.a = (1.0 - life) * fl
				draw_circle(p, 2.5, Color(col, col.a * 0.25))
				draw_rect(Rect2(p, Vector2(1, 1) if life > 0.5 else Vector2(2, 2)), col)


func _draw_corruption() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.12, 0.02, 0.18, 0.12 + 0.03 * sin(t * 0.8)))
	for c in cparts:
		var p: Vector2 = (c["p"] as Vector2).round()
		var fl := 0.5 + 0.5 * sin(t * 4.0 + c["ph"])
		if c["q"]:
			# quadradinho de glitch (pisca entre roxo e ciano)
			var col := Color("b050ff") if int(t * 6.0 + c["ph"] * 3.0) % 3 != 0 else Color("4ff0ff")
			col.a = 0.35 + 0.4 * fl
			draw_rect(Rect2(p, Vector2(c["s"] + 1, c["s"] + 1)), col)
		else:
			draw_rect(Rect2(p, Vector2(c["s"], 1)), Color(0.45, 0.3, 0.55, 0.5 * fl))
	if glitch_on > 0.0:
		glitch_on -= get_process_delta_time()
		draw_rect(Rect2(0, glitch_y, 640, 3), Color(0.7, 0.3, 1.0, 0.25))
		draw_rect(Rect2(rng.randf_range(0, 500), glitch_y + 5, rng.randf_range(40, 140), 2), Color(0.3, 1.0, 1.0, 0.3))
