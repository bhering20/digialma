extends Control
## Acampamento (cena de teste): treinador + equipe, HUD e menu de pausa.

const FX = preload("res://scripts/fx.gd")
const Title = preload("res://scripts/title.gd")
const PauseMenu = preload("res://scripts/pause_menu.gd")

var pause_menu: CanvasLayer
var trainer: AnimatedSprite2D
var t := 0.0
var walk_dir := 1.0


func _ready() -> void:
	theme = Game.make_theme()
	var bg := TextureRect.new()
	bg.texture = Game.tex(Game.GP + "backgrounds/forest.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	add_child(Title.FxLayer.new())
	# equipe
	var spots := [Vector2(390, 318), Vector2(470, 328), Vector2(548, 316)]
	for i in Game.team.size():
		var sh := ColorRect.new()
		sh.color = Color(0, 0, 0, 0.2)
		sh.size = Vector2(48, 5)
		sh.position = spots[i] + Vector2(-24, -5)
		sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sh)
		var s := AnimatedSprite2D.new()
		s.sprite_frames = Game.monster_frames(Game.team[i]["id"])
		s.play("idle")
		s.frame = i
		s.centered = false
		s.offset = Vector2(-48, -96)
		s.position = spots[i]
		add_child(s)
	trainer = AnimatedSprite2D.new()
	trainer.sprite_frames = Game.char_frames(Game.player_char)
	trainer.play("right")
	trainer.centered = false
	trainer.offset = Vector2(-64, -128)
	trainer.position = Vector2(200, 334)
	add_child(trainer)
	var vig := ColorRect.new()
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.size = Game.BASE
	vig.material = FX.shader_mat(FX.VIGNETTE_SHADER)
	vig.material.set_shader_parameter("strength", 0.4)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vig)
	_build_hud()
	pause_menu = PauseMenu.new()
	add_child(pause_menu)


func _build_hud() -> void:
	var chip := PanelContainer.new()
	chip.position = Vector2(8, 8)
	add_child(chip)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	chip.add_child(h)
	var icon := TextureRect.new()
	icon.texture = Game.tex("res://assets/items/bits.png")
	icon.custom_minimum_size = Vector2(16, 16)
	h.add_child(icon)
	var l := Label.new()
	l.text = "%s   %d Bits" % [Game.player_name, Game.bits]
	h.add_child(l)
	var menu_btn := Button.new()
	menu_btn.text = "MENU  [ESC]"
	menu_btn.position = Vector2(540, 10)
	menu_btn.custom_minimum_size = Vector2(92, 22)
	menu_btn.focus_mode = Control.FOCUS_NONE
	menu_btn.pressed.connect(func(): pause_menu.open())
	add_child(menu_btn)
	var hint := Label.new()
	hint.text = "ESC: menu    I: mochila    E: equipe"
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(640, 12)
	hint.position = Vector2(0, 344)
	add_child(hint)


func _process(delta: float) -> void:
	t += delta
	# o treinador passeia pelo acampamento
	trainer.position.x += walk_dir * 28.0 * delta
	if trainer.position.x > 320:
		walk_dir = -1.0
		trainer.play("left")
	elif trainer.position.x < 90:
		walk_dir = 1.0
		trainer.play("right")


func _unhandled_input(event: InputEvent) -> void:
	if pause_menu.is_open:
		return
	if event.is_action_pressed("ui_cancel"):
		pause_menu.open()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			pause_menu.open("mochila")
		elif event.keycode == KEY_E:
			pause_menu.open("equipe")
