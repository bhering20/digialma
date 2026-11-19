extends Control
## Caixa de diálogo com retrato, nome e texto letra por letra. Uso: await dialog.play(linhas)

signal finished

const PORTRAITS := {"Silvana": "grass_boss", "Maré": "water_boss", "Ígneo": "fire_boss"}

var box: PanelContainer
var portrait_box: PanelContainer
var portrait_holder: Control
var name_l: Label
var text_l: Label
var arrow: Label
var lines: Array = []
var idx := 0
var typing := false
var t := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = Game.BASE
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	box = PanelContainer.new()
	box.position = Vector2(20, 262)
	box.custom_minimum_size = Vector2(600, 84)
	add_child(box)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	box.add_child(h)
	portrait_box = PanelContainer.new()
	portrait_box.add_theme_stylebox_override("panel", Game.sb("slot", 5, Vector4(2, 2, 2, 2)))
	portrait_box.custom_minimum_size = Vector2(64, 62)
	h.add_child(portrait_box)
	portrait_holder = Control.new()
	portrait_holder.clip_contents = true
	portrait_box.add_child(portrait_holder)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	name_l = Label.new()
	name_l.add_theme_color_override("font_color", Color("ffd84a"))
	v.add_child(name_l)
	text_l = Label.new()
	text_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_l.custom_minimum_size = Vector2(480, 44)
	v.add_child(text_l)
	arrow = Label.new()
	arrow.text = "▼"
	arrow.add_theme_color_override("font_color", Color("ffd84a"))
	arrow.position = Vector2(596, 330)
	add_child(arrow)
	visible = false


func play(new_lines: Array) -> void:
	lines = new_lines
	idx = 0
	visible = true
	box.modulate.a = 0.0
	box.position.y = 280
	var tw := create_tween().set_parallel(true)
	tw.tween_property(box, "modulate:a", 1.0, 0.15)
	tw.tween_property(box, "position:y", 262.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_show_line()
	await finished


func _show_line() -> void:
	var who: String = lines[idx][0]
	var txt: String = String(lines[idx][1]).replace("%NOME%", Game.player_name)
	for c in portrait_holder.get_children():
		c.queue_free()
	portrait_box.visible = who != ""
	name_l.text = "ELO" if who == "elo" else who
	if who == "elo":
		var ic := TextureRect.new()
		ic.texture = Game.tex("res://assets/items/elo_med.png")
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.size = Vector2(44, 48)
		ic.position = Vector2(8, 6)
		portrait_holder.add_child(ic)
	elif PORTRAITS.has(who):
		var s := AnimatedSprite2D.new()
		s.sprite_frames = Game.char_frames(PORTRAITS[who])
		s.play("idle_down")
		s.position = Vector2(30, 52)
		portrait_holder.add_child(s)
	elif who == "???":
		var s := AnimatedSprite2D.new()
		s.sprite_frames = Game.monster_frames(9)
		s.play("idle")
		s.modulate = Color(0.05, 0.0, 0.1)
		s.position = Vector2(30, 30)
		s.scale = Vector2(0.7, 0.7)
		portrait_holder.add_child(s)
	text_l.text = txt
	text_l.visible_characters = 0
	typing = true
	var tw := create_tween()
	tw.tween_property(text_l, "visible_characters", txt.length(), txt.length() * 0.022)
	tw.finished.connect(func(): typing = false)


func _advance() -> void:
	if typing:
		typing = false
		text_l.visible_characters = -1
		return
	idx += 1
	if idx >= lines.size():
		visible = false
		finished.emit()
	else:
		_show_line()


func _process(delta: float) -> void:
	t += delta
	arrow.visible = visible and not typing
	arrow.position.y = 330 + round(sin(t * 6.0) * 2.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE)):
		_advance()
		get_viewport().set_input_as_handled()
