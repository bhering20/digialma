extends CanvasLayer
## Menu de pausa: fundo desfocado, cartão do treinador, menu lateral e telas de Mochila/Equipe.

const FX = preload("res://scripts/fx.gd")
const Inventory = preload("res://scripts/inventory.gd")
const TeamView = preload("res://scripts/team_view.gd")

var is_open := false
var root: Control
var blur: ColorRect
var card: PanelContainer
var menu: PanelContainer
var menu_box: VBoxContainer
var hand: TextureRect
var sub: Control = null
var t := 0.0
var time_label: Label


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.size = Game.BASE
	root.theme = Game.make_theme()
	root.visible = false
	add_child(root)
	blur = ColorRect.new()
	blur.set_anchors_preset(Control.PRESET_FULL_RECT)
	blur.size = Game.BASE
	blur.material = FX.shader_mat(FX.BLUR_SHADER)
	root.add_child(blur)
	_build_card()
	_build_menu()
	hand = TextureRect.new()
	hand.texture = Game.tex(Game.GP + "ui/hand.png")
	hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hand)


func _build_card() -> void:
	card = PanelContainer.new()
	card.position = Vector2(16, 40)
	card.custom_minimum_size = Vector2(250, 280)
	root.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)
	var title := Label.new()
	Game.heading(title, "CARTÃO DE TREINADOR", 8)
	title.add_theme_color_override("font_color", Color("ffd84a"))
	v.add_child(title)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	v.add_child(top)
	var portrait := PanelContainer.new()
	portrait.add_theme_stylebox_override("panel", Game.sb("slot", 5))
	portrait.custom_minimum_size = Vector2(84, 100)
	top.add_child(portrait)
	var holder := Control.new()
	portrait.add_child(holder)
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = Game.char_frames(Game.player_char)
	spr.play("down")
	spr.position = Vector2(34, 40)
	spr.scale = Vector2(0.75, 0.75)
	holder.add_child(spr)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 3)
	top.add_child(info)
	var nm := Label.new()
	Game.heading(nm, Game.player_name.to_upper(), 16)
	info.add_child(nm)
	for line in [["ID", "#%05d" % (hash(Game.player_name) % 99999)], ["BITS", str(Game.bits)], ["DEX", "%d / %d" % [Game.seen.size(), Game.MONSTERS.size()]]]:
		var l := Label.new()
		l.text = "%s   %s" % line
		info.add_child(l)
	time_label = Label.new()
	info.add_child(time_label)
	var bt := Label.new()
	bt.text = "INSÍGNIAS"
	bt.add_theme_color_override("font_color", Color("ffd84a"))
	v.add_child(bt)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	v.add_child(grid)
	for i in 8:
		var s := PanelContainer.new()
		s.add_theme_stylebox_override("panel", Game.sb("slot_sel" if i < Game.badges else "slot", 5))
		s.custom_minimum_size = Vector2(52, 30)
		var st := TextureRect.new()
		if i < Game.REGIONS.size():
			st.texture = Game.tex("res://assets/badges/%s.png" % Game.REGIONS[i]["lider"]["badge"])
			st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			st.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			st.modulate = Color(0, 0, 0, 0.35) if i >= Game.badges else Color.WHITE
		else:
			st.texture = Game.tex(Game.GP + "ui/star.png")
			st.modulate = Color(1, 1, 1, 0.15)
			st.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		s.add_child(st)
		grid.add_child(s)


func _build_menu() -> void:
	menu = PanelContainer.new()
	menu.position = Vector2(470, 40)
	menu.custom_minimum_size = Vector2(150, 280)
	root.add_child(menu)
	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 6)
	menu.add_child(menu_box)
	var title := Label.new()
	title.text = "MENU"
	title.add_theme_font_override("font", Game.font_title)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("ffd84a"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_box.add_child(title)
	var items := [["CONTINUAR", close], ["EQUIPE", func(): _open_sub("equipe")], ["MOCHILA", func(): _open_sub("mochila")],
		["DEX", null], ["OPÇÕES", func(): Game.set_fullscreen(not Game.options["fullscreen"])], ["MENU INICIAL", func(): Game.change_scene("res://scenes/title.tscn")]]
	for it in items:
		var b := Button.new()
		b.text = it[0] if it[1] != null else it[0] + "  (em breve)"
		b.custom_minimum_size = Vector2(126, 24)
		b.disabled = it[1] == null
		if it[1] != null:
			b.pressed.connect(it[1])
		FX.juice_button(b)
		menu_box.add_child(b)


func open(direct := "") -> void:
	if is_open:
		return
	is_open = true
	get_tree().paused = true
	root.visible = true
	var mat := blur.material as ShaderMaterial
	mat.set_shader_parameter("amount", 0.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(v): mat.set_shader_parameter("amount", v), 0.0, 1.0, 0.25)
	if direct != "":
		card.visible = false
		menu.visible = false
		_open_sub(direct)
		return
	_slide_panels_in()


func _slide_panels_in() -> void:
	card.visible = true
	menu.visible = true
	card.position.x = -270
	menu.position.x = 660
	var tw := create_tween().set_parallel(true)
	tw.tween_property(card, "position:x", 16.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(menu, "position:x", 470.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	FX.cascade_in(menu_box.get_children().slice(1), Vector2(0, 10), 0.05)
	(menu_box.get_child(1) as Button).grab_focus()


func close() -> void:
	if sub:
		sub.queue_free()
		sub = null
	var tw := create_tween().set_parallel(true)
	tw.tween_property(card, "position:x", -270.0, 0.2)
	tw.tween_property(menu, "position:x", 660.0, 0.2)
	var mat := blur.material as ShaderMaterial
	tw.tween_method(func(v): mat.set_shader_parameter("amount", v), 1.0, 0.0, 0.2)
	await tw.finished
	root.visible = false
	is_open = false
	get_tree().paused = false


func _open_sub(which: String) -> void:
	card.visible = false
	menu.visible = false
	sub = Inventory.new() if which == "mochila" else TeamView.new()
	sub.closed.connect(_close_sub)
	root.add_child(sub)
	root.move_child(hand, -1)


func _close_sub() -> void:
	if sub:
		sub.queue_free()
		sub = null
	_slide_panels_in()


func _process(delta: float) -> void:
	if not is_open:
		return
	t += delta
	time_label.text = "TEMPO   " + Game.play_time_text()
	var f := root.get_viewport().gui_get_focus_owner()
	if f is Button and f.is_visible_in_tree() and sub == null:
		hand.visible = true
		var r: Rect2 = f.get_global_rect()
		var target := Vector2(r.position.x - 30 + sin(t * 8.0) * 2.0, r.position.y + r.size.y * 0.5 - 16)
		hand.position = hand.position.lerp(target, 0.4) if hand.position.distance_to(target) < 100 else target
	else:
		hand.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if sub:
			sub.request_close()
		else:
			close()
