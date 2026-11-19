extends Control
## DUELO: um Digialma Épico/Lendário achado no idle pediu para ser jogado.
## Abre a batalha completa e, no fim, volta para a faixa do idle.

const Battle = preload("res://scripts/battle.gd")


func _ready() -> void:
	theme = Game.make_theme()
	size = Game.BASE
	if Game.duel_queue.is_empty():
		_back.call_deferred()
		return
	_run()


func _run() -> void:
	var e: Dictionary = Game.duel_queue.pop_front()
	var reg: Dictionary = Game.REGIONS[Game.region]
	var col := Game.rar_color(int(e.get("rar", 0)))
	# abertura: faixa colorida da raridade + nome
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.01, 0.08)
	dim.size = Game.BASE
	add_child(dim)
	var band := ColorRect.new()
	band.color = Color(col, 0.85)
	band.size = Vector2(640, 0)
	band.position = Vector2(0, 180)
	add_child(band)
	var l := Label.new()
	Game.heading(l, "CHAMADO DO ELO", 16)
	l.add_theme_color_override("font_color", Color("1a0f2a"))
	l.size = Vector2(640, 20)
	l.position = Vector2(0, 150)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.modulate.a = 0.0
	add_child(l)
	var l2 := Label.new()
	l2.text = "%s  %s  ·  Nv %d" % [Game.mon_name(e).to_upper(), Game.RARITY[e["rar"]]["nome"].to_upper(), e["lv"]]
	l2.add_theme_color_override("font_color", Color("1a0f2a"))
	l2.size = Vector2(640, 20)
	l2.position = Vector2(0, 178)
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l2.modulate.a = 0.0
	add_child(l2)
	var tw := create_tween()
	tw.tween_property(band, "size:y", 64.0, 0.25)
	tw.parallel().tween_property(band, "position:y", 148.0, 0.25)
	tw.tween_property(l, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(l2, "modulate:a", 1.0, 0.2)
	tw.tween_interval(1.3)
	await tw.finished
	band.queue_free()
	l.queue_free()
	l2.queue_free()
	var b := Battle.new()
	add_child(b)
	var r: String = await b.run(reg, [e])
	await create_tween().tween_property(b, "modulate:a", 0.0, 0.3).finished
	b.queue_free()
	# recompensa
	var msg := ""
	if r == "win" or r == "caught":
		var g := Game.random_gear(2 if e["rar"] >= 4 else 1)
		Game.bits += 60 * (e["rar"] + 1)
		Game.cristais += 1 + (1 if e["rar"] >= 4 else 0)
		msg = "Recompensa: %s (%s)  +%d bits" % [Game.gear_name(g), Game.gear_desc(g), 60 * (e["rar"] + 1)]
		if r == "caught":
			msg = "%s entrou para o seu grupo!\n" % Game.mon_title(e) + msg
		_reward(msg, Game.rar_color(g["rar"]), g)
	else:
		_reward("%s escapou... Outros raros vão aparecer no idle." % Game.mon_name(e), Color("ff9a9a"), {})
	Game.heal_team(1.0)
	await get_tree().create_timer(3.2).timeout
	_back()


func _reward(txt: String, col: Color, g: Dictionary) -> void:
	if not g.is_empty():
		var ic := TextureRect.new()
		ic.texture = Game.tex("res://assets/gear/%s.png" % g["base"])
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.size = Vector2(72, 72)
		ic.position = Vector2(284, 110)
		ic.pivot_offset = Vector2(36, 36)
		ic.scale = Vector2(0.2, 0.2)
		add_child(ic)
		create_tween().tween_property(ic, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var l := Label.new()
	l.text = txt
	l.add_theme_color_override("font_color", col)
	l.size = Vector2(600, 40)
	l.position = Vector2(20, 200)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(l)


func _back() -> void:
	Game.return_to = ""
	if Game.in_panel(self):
		get_window().queue_free()
	else:
		Game.change_scene("res://scenes/idle.tscn")
