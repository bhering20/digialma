extends Control
## Cartão "como jogar" do modo idle (abre no painel na primeira vez e pelo "?").

const UI := "res://assets/ui/idle_%s.png"
const ROWS := [
	["purif", "Seu grupo explora e purifica Nefastos sozinho. Deixe a faixa rodando enquanto usa o PC. Mesmo fechado, ele continua (até 8h)."],
	["santuario", "Encha o caminho até o Santuário e desafie o líder. Ele é forte: suba de nível, capture e funda Digialmas antes."],
	["lutar", "Espadas pulsando = um Digialma raro quer lutar. Clique nelas para o duelo começar ali mesmo, na faixa."],
	["tipo_fogo", "No duelo, escolha o golpe e clique (ou Espaço) quando o anel fechar no inimigo. Anel vermelho no seu Digialma: clique na hora para desviar."],
	["laco", "Inimigo fraco? Use o Selo de Alma para capturar. Só 2 tentativas, e o Elo precisa ter nível para a raridade dele."],
	["bolsa", "Bolsa: amuletos, Árvore de Alma, fusões (Ressonância e Essência) e equipe."],
]


func _ready() -> void:
	theme = Game.make_theme()
	size = Game.BASE
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.03, 0.11, 0.97)
	bg.size = Game.BASE
	add_child(bg)
	var t := Label.new()
	Game.heading(t, "DIGIALMA · MODO IDLE", 14)
	t.add_theme_color_override("font_color", Color("ffd84a"))
	t.position = Vector2(20, 12)
	add_child(t)
	var v := Label.new()
	v.text = "versão de teste %s" % Game.VERSION
	v.add_theme_font_size_override("font_size", 8)
	v.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	v.position = Vector2(470, 18)
	add_child(v)
	var y := 44.0
	for r in ROWS:
		var ic := TextureRect.new()
		ic.texture = Game.tex(UI % r[0])
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.scale = Vector2(2, 2)
		ic.position = Vector2(24, y + 2)
		add_child(ic)
		var l := Label.new()
		l.text = r[1]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.position = Vector2(64, y)
		l.size = Vector2(556, 40)
		l.add_theme_font_size_override("font_size", 9)
		add_child(l)
		y += 42.0
	var tip := Label.new()
	tip.text = "Arraste a faixa para onde quiser. Passe o mouse nela para ver os botões. O progresso salva sozinho."
	tip.add_theme_font_size_override("font_size", 8)
	tip.add_theme_color_override("font_color", Color("7affc1"))
	tip.position = Vector2(24, 300)
	tip.size = Vector2(450, 30)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(tip)
	var ok := Button.new()
	ok.text = "ENTENDI!"
	ok.position = Vector2(500, 312)
	ok.custom_minimum_size = Vector2(110, 30)
	ok.pressed.connect(func():
		if Game.in_panel(self):
			get_window().queue_free()
		else:
			queue_free())
	add_child(ok)
