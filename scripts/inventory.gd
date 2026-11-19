extends Control
## Mochila: abas, grade de itens e painel de detalhes com ícone grande animado.

signal closed

const FX = preload("res://scripts/fx.gd")

var panel: PanelContainer
var tabs: Array = []
var grid: GridContainer
var tab := 0
var selected := ""
var big_icon: TextureRect
var shine: ColorRect
var name_l: Label
var cat_l: Label
var desc_l: Label
var qty_l: Label
var use_btn: Button
var toast: Label
var t := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = Game.BASE
	panel = PanelContainer.new()
	panel.position = Vector2(30, 24)
	panel.size = Vector2(580, 312)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	# cabeçalho
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	v.add_child(head)
	var title := Label.new()
	title.text = "MOCHILA"
	title.add_theme_font_override("font", Game.font_title)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("ffd84a"))
	title.custom_minimum_size = Vector2(140, 0)
	head.add_child(title)
	for i in Game.ITEM_TABS.size():
		var b := Button.new()
		b.text = Game.ITEM_TABS[i].to_upper()
		b.custom_minimum_size = Vector2(90, 20)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func(): _set_tab(i))
		head.add_child(b)
		tabs.append(b)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	var hint := Label.new()
	hint.text = "Q / E  trocar aba"
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	head.add_child(hint)
	# corpo
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	v.add_child(body)
	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", Game.sb("slot", 5, Vector4(8, 8, 8, 8)))
	left.custom_minimum_size = Vector2(300, 250)
	body.add_child(left)
	grid = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	left.add_child(grid)
	# detalhe
	var det := PanelContainer.new()
	det.add_theme_stylebox_override("panel", Game.sb("panel_light", 8, Vector4(12, 10, 12, 10)))
	det.custom_minimum_size = Vector2(240, 250)
	body.add_child(det)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 4)
	det.add_child(dv)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(216, 84)
	dv.add_child(stage)
	var plate := ColorRect.new()
	plate.color = Color(0.2, 0.15, 0.4, 0.15)
	plate.position = Vector2(68, 70)
	plate.size = Vector2(80, 6)
	stage.add_child(plate)
	big_icon = TextureRect.new()
	big_icon.size = Vector2(64, 64)
	big_icon.position = Vector2(76, 4)
	big_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	big_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stage.add_child(big_icon)
	shine = ColorRect.new()
	shine.color = Color(1, 1, 1, 0.0)
	shine.size = Vector2(6, 64)
	shine.position = Vector2(76, 4)
	stage.add_child(shine)
	name_l = Label.new()
	name_l.add_theme_font_override("font", Game.font_title)
	name_l.add_theme_font_size_override("font_size", 8)
	name_l.add_theme_color_override("font_color", Color("2a1640"))
	name_l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dv.add_child(name_l)
	cat_l = Label.new()
	cat_l.add_theme_color_override("font_color", Color("3b5bb5"))
	cat_l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	cat_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dv.add_child(cat_l)
	desc_l = Label.new()
	desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_l.custom_minimum_size = Vector2(216, 48)
	desc_l.add_theme_color_override("font_color", Color("3a2a50"))
	desc_l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	dv.add_child(desc_l)
	qty_l = Label.new()
	qty_l.add_theme_color_override("font_color", Color("b0602a"))
	qty_l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	qty_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dv.add_child(qty_l)
	var bh := HBoxContainer.new()
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	bh.add_theme_constant_override("separation", 6)
	use_btn = Button.new()
	use_btn.text = "USAR"
	use_btn.custom_minimum_size = Vector2(80, 22)
	use_btn.pressed.connect(_use)
	FX.juice_button(use_btn)
	var close_btn := Button.new()
	close_btn.text = "FECHAR"
	close_btn.custom_minimum_size = Vector2(80, 22)
	close_btn.pressed.connect(request_close)
	FX.juice_button(close_btn)
	bh.add_child(use_btn)
	bh.add_child(close_btn)
	dv.add_child(bh)
	toast = Label.new()
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.size = Vector2(640, 12)
	toast.position = Vector2(0, 340)
	toast.add_theme_color_override("font_color", Color("bff6ff"))
	toast.modulate.a = 0.0
	add_child(toast)
	_set_tab(0)
	# entrada
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.2)


func _set_tab(i: int) -> void:
	tab = i
	for k in tabs.size():
		var on: bool = k == i
		var b: Button = tabs[k]
		b.add_theme_stylebox_override("normal", Game.sb("tab_on" if on else "tab", 5, Vector4(8, 4, 8, 4)))
		b.add_theme_stylebox_override("hover", Game.sb("tab_on" if on else "slot_sel", 5, Vector4(8, 4, 8, 4)))
		b.add_theme_color_override("font_color", Color("2a1640") if on else Color("fff6e8"))
		b.add_theme_color_override("font_hover_color", Color("2a1640") if on else Color("fff1a8"))
		b.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0) if on else Color(0.04, 0.02, 0.1, 0.9))
	for c in grid.get_children():
		c.queue_free()
	var keys := []
	for k in Game.ITEMS:
		if Game.ITEMS[k]["cat"] == i and Game.inventory.get(k, 0) > 0:
			keys.append(k)
	for slot_i in 24:
		var b := Button.new()
		b.custom_minimum_size = Vector2(42, 42)
		b.add_theme_stylebox_override("normal", Game.sb("slot", 5))
		b.add_theme_stylebox_override("hover", Game.sb("slot_sel", 5))
		b.add_theme_stylebox_override("focus", Game.sb("slot_sel", 5))
		b.add_theme_stylebox_override("pressed", Game.sb("slot_sel", 5))
		if slot_i < keys.size():
			var key: String = keys[slot_i]
			var ic := TextureRect.new()
			ic.texture = Game.tex("res://assets/items/%s.png" % key)
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.size = Vector2(32, 32)
			ic.position = Vector2(5, 4)
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(ic)
			var q := Label.new()
			q.text = "x%d" % Game.inventory[key]
			q.position = Vector2(20, 28)
			q.size = Vector2(20, 10)
			q.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			b.add_child(q)
			b.focus_entered.connect(func(): _select(key, b))
			b.mouse_entered.connect(func(): b.grab_focus())
			b.pressed.connect(_use)
		else:
			b.disabled = true
			b.add_theme_stylebox_override("disabled", Game.sb("slot", 5))
			b.modulate = Color(1, 1, 1, 0.5)
		grid.add_child(b)
	if keys.size() > 0:
		await get_tree().process_frame
		(grid.get_child(0) as Button).grab_focus()
	else:
		_select("", null)


func _select(key: String, b: Button) -> void:
	selected = key
	if key == "":
		big_icon.texture = null
		name_l.text = "VAZIO"
		cat_l.text = ""
		desc_l.text = "Nenhum item nesta aba ainda."
		qty_l.text = ""
		use_btn.disabled = true
		return
	var it: Dictionary = Game.ITEMS[key]
	big_icon.texture = Game.tex("res://assets/items/%s.png" % key)
	Game.heading(name_l, it["nome"].to_upper(), 8)
	cat_l.text = Game.ITEM_TABS[it["cat"]]
	desc_l.text = it["desc"]
	qty_l.text = "Você tem: x%d" % Game.inventory.get(key, 0)
	use_btn.disabled = it["cat"] == 2
	# animação de troca + brilho
	big_icon.scale = Vector2(0.6, 0.6)
	big_icon.pivot_offset = Vector2(32, 32)
	var tw := create_tween()
	tw.tween_property(big_icon, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	shine.color.a = 0.7
	shine.position.x = 70
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(shine, "position:x", 146.0, 0.35)
	tw2.tween_property(shine, "color:a", 0.0, 0.35)


func _use() -> void:
	if selected == "" or Game.ITEMS[selected]["cat"] == 2:
		return
	Game.inventory[selected] -= 1
	_show_toast("Você usou %s!" % Game.ITEMS[selected]["nome"])
	var keep := selected
	if Game.inventory[selected] <= 0:
		Game.inventory.erase(selected)
	_set_tab(tab)
	if Game.inventory.has(keep):
		for b in grid.get_children():
			pass


func _show_toast(msg: String) -> void:
	toast.text = msg
	toast.modulate.a = 1.0
	toast.position.y = 342
	var tw := create_tween().set_parallel(true)
	tw.tween_property(toast, "position:y", 334.0, 0.3)
	tw.tween_property(toast, "modulate:a", 0.0, 1.4).set_delay(0.8)


func request_close() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2(0.85, 0.85), 0.15)
	tw.tween_property(panel, "modulate:a", 0.0, 0.15)
	await tw.finished
	closed.emit()


func _process(delta: float) -> void:
	t += delta
	big_icon.position.y = 4 + round(sin(t * 3.0) * 3.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			_set_tab(posmod(tab - 1, tabs.size()))
		elif event.keycode == KEY_E:
			_set_tab(posmod(tab + 1, tabs.size()))
