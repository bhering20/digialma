extends Control
## Equipe: lista dos monstrinhos com vida e nível, e o selecionado em destaque animado.

signal closed

const FX = preload("res://scripts/fx.gd")

var panel: PanelContainer
var big: AnimatedSprite2D
var name_l: Label
var info_l: Label
var t := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = Game.BASE
	panel = PanelContainer.new()
	panel.position = Vector2(40, 30)
	panel.size = Vector2(560, 300)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	var title := Label.new()
	title.text = "EQUIPE"
	title.add_theme_font_override("font", Game.font_title)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("ffd84a"))
	v.add_child(title)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	v.add_child(body)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	body.add_child(list)
	var first: Button = null
	for i in Game.team.size():
		var m: Dictionary = Game.team[i]
		var data: Dictionary = Game.MONSTERS[m["id"]]
		var b := Button.new()
		b.custom_minimum_size = Vector2(290, 58)
		b.add_theme_stylebox_override("normal", Game.sb("slot", 5))
		b.add_theme_stylebox_override("hover", Game.sb("slot_sel", 5))
		b.add_theme_stylebox_override("focus", Game.sb("slot_sel", 5))
		b.add_theme_stylebox_override("pressed", Game.sb("slot_sel", 5))
		var ic := TextureRect.new()
		ic.texture = Game.menu_icon(m["id"])
		ic.position = Vector2(8, 13)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(ic)
		var nm := Label.new()
		nm.text = data["nome"]
		nm.position = Vector2(48, 8)
		b.add_child(nm)
		var tag := Label.new()
		tag.text = data["tipo"].to_upper()
		tag.position = Vector2(150, 8)
		tag.add_theme_color_override("font_color", data["cor"])
		b.add_child(tag)
		var bd := Label.new()
		bd.text = "FÚRIA %d · GUARDA %d" % [m.get("fur", 0), m.get("gua", 0)]
		bd.position = Vector2(70, 40)
		bd.add_theme_font_size_override("font_size", 8)
		bd.add_theme_color_override("font_color", Color("ff8a5a") if m.get("fur", 0) >= m.get("gua", 0) else Color("8ac4ff"))
		b.add_child(bd)
		var lv := Label.new()
		lv.text = "Nv %d" % m["lv"]
		lv.position = Vector2(240, 8)
		b.add_child(lv)
		var mx := Game.max_hp(m)
		var hp_ratio := float(m["hp"]) / float(mx)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.position = Vector2(70, 28)
		bar.size = Vector2(150, 8)
		bar.max_value = mx
		bar.value = m["hp"]
		var col := Color("58d080") if hp_ratio >= 0.5 else (Color("e8c020") if hp_ratio >= 0.2 else Color("e04040"))
		var fill := StyleBoxFlat.new()
		fill.bg_color = col
		fill.set_corner_radius_all(2)
		bar.add_theme_stylebox_override("fill", fill)
		b.add_child(bar)
		var hpl := Label.new()
		hpl.text = "HP"
		hpl.position = Vector2(50, 26)
		hpl.add_theme_color_override("font_color", Color("ffb36b"))
		b.add_child(hpl)
		var hpn := Label.new()
		hpn.text = "%d/%d" % [m["hp"], mx]
		hpn.position = Vector2(228, 26)
		b.add_child(hpn)
		b.focus_entered.connect(func(): _select(i))
		b.mouse_entered.connect(func(): b.grab_focus())
		list.add_child(b)
		if first == null:
			first = b
	var det := PanelContainer.new()
	det.add_theme_stylebox_override("panel", Game.sb("panel_light", 8, Vector4(10, 8, 10, 8)))
	det.custom_minimum_size = Vector2(220, 190)
	body.add_child(det)
	var dv := VBoxContainer.new()
	det.add_child(dv)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(200, 110)
	dv.add_child(stage)
	var plate := ColorRect.new()
	plate.color = Color(0.25, 0.5, 0.25, 0.35)
	plate.position = Vector2(56, 100)
	plate.size = Vector2(88, 8)
	stage.add_child(plate)
	big = AnimatedSprite2D.new()
	big.centered = false
	big.offset = Vector2(-48, -96)
	big.position = Vector2(100, 106)
	big.flip_h = true
	stage.add_child(big)
	name_l = Label.new()
	name_l.add_theme_font_override("font", Game.font_title)
	name_l.add_theme_font_size_override("font_size", 8)
	name_l.add_theme_color_override("font_color", Color("2a1640"))
	name_l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dv.add_child(name_l)
	info_l = Label.new()
	info_l.add_theme_color_override("font_color", Color("3a2a50"))
	info_l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	info_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dv.add_child(info_l)
	var close_btn := Button.new()
	close_btn.text = "VOLTAR"
	close_btn.custom_minimum_size = Vector2(100, 22)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(request_close)
	FX.juice_button(close_btn)
	v.add_child(close_btn)
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.2)
	await get_tree().process_frame
	first.grab_focus()
	FX.cascade_in(list.get_children(), Vector2(0, 10), 0.06)


func _select(i: int) -> void:
	var m: Dictionary = Game.team[i]
	var data: Dictionary = Game.MONSTERS[m["id"]]
	big.sprite_frames = Game.monster_frames(m["id"])
	big.play("attack")
	big.animation_finished.connect(func(): big.play("idle"), CONNECT_ONE_SHOT)
	Game.heading(name_l, data["nome"].to_upper(), 8)
	info_l.text = "Tipo %s  -  Nível %d" % [data["tipo"], m["lv"]]


func request_close() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2(0.85, 0.85), 0.15)
	tw.tween_property(panel, "modulate:a", 0.0, 0.15)
	await tw.finished
	closed.emit()
