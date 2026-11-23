extends Control
## Cartão "ALÉM DA EVOLUÇÃO": explica Despertar (4ª forma), Ascensão (5ª) e o
## segredo da Digidex, sem contar quem vira o quê. Abre sozinho quando os 3
## primeiros mundos são purificados e pelo botão ? da Digidex.

const UI := "res://assets/ui/idle_%s.png"
var overlay := false  # true = aberto por cima da Digidex (fecha só ele)
const ROWS := [
	["nivel", "EVOLUÇÃO", "Digialmas evoluem sozinhos ao subir de nível: 1ª, 2ª e 3ª forma. A Digidex mostra o nível de cada passo."],
	["despertar", "DESPERTAR · 4ª forma", "Depois de purificar os 3 primeiros mundos, um Digialma na forma FINAL e no Nv 55 pode despertar com um Cristal do Despertar (Santuários e zonas 8 a 10 de mapas purificados). Fica 25% mais forte, ganha aura dourada e muitas linhas mudam de forma."],
	["ascensao", "ASCENSÃO · 5ª forma", "Ninguém sabe ao certo. Dizem que almas despertas, no fim da jornada, podem ascender a algo além... Procure as silhuetas com estrela na Digidex."],
	["arvore", "O SEGREDO DA DIGIDEX", "Capturar Digialmas dá prêmios a cada marco da coleção. E dizem que uma árvore antiga guarda todas as almas... e só aparece para quem conhecer cada uma delas."],
]


func _ready() -> void:
	theme = Game.make_theme()
	size = Game.BASE
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.03, 0.11, 0.98)
	bg.size = Game.BASE
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	var t := Label.new()
	Game.heading(t, "ALÉM DA EVOLUÇÃO", 16)
	t.add_theme_color_override("font_color", Color("ffd84a"))
	t.position = Vector2(20, 12)
	add_child(t)
	var y := 46.0
	for r in ROWS:
		var ic := TextureRect.new()
		ic.texture = Game.tex(UI % r[0])
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.scale = Vector2(2, 2)
		ic.position = Vector2(24, y + 4)
		add_child(ic)
		var h := Label.new()
		h.text = r[1]
		h.position = Vector2(64, y)
		h.add_theme_font_size_override("font_size", 10)
		h.add_theme_color_override("font_color", Color("ffd84a") if r[0] != "ascensao" else Color("d8b8ff"))
		add_child(h)
		var l := Label.new()
		l.text = r[2]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.position = Vector2(64, y + 14)
		l.size = Vector2(556, 44)
		l.add_theme_font_size_override("font_size", 8)
		add_child(l)
		y += 64.0
	var ok := Button.new()
	ok.text = "ENTENDI!"
	ok.position = Vector2(510, 318)
	ok.custom_minimum_size = Vector2(110, 28)
	ok.pressed.connect(func():
		if overlay or not Game.in_panel(self):
			queue_free()
		else:
			get_window().queue_free())
	add_child(ok)
