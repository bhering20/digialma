extends Control
## Cartão "como jogar" do modo idle (abre no painel na primeira vez e pelo "?").

const UI := "res://assets/ui/idle_%s.png"
const ROWS := [
	["purif", "Seu grupo explora e purifica Nefastos sozinho. Deixe a faixa rodando enquanto usa o PC. Mesmo fechado, ele continua (até 8h)."],
	["santuario", "Cada mapa tem 10 zonas, cada vez mais fortes (1-1, 1-2...). Se o grupo todo cair, volta uma zona. Na zona 10, o Santuário: vença o guardião para purificar o mapa e ganhar a insígnia (equipe no Elo; a revanche sobe o nível dela)."],
	["mapa", "Mapa do Mundo: veja as ilhas, o que já foi purificado e clique numa zona liberada para viajar. < > e o botão de setas circulares também mudam de zona."],
	["alma", "Digialma caído vira ALMA-NUVEM e não luta. Só volta com um Orbe de Alma: clique na nuvenzinha. Suportes (ícone +) curam o time durante as lutas."],
	["lutar", "Espadas pulsando = um Digialma raro quer lutar. No duelo, clique quando o anel fechar no inimigo; anel vermelho em você = clique para desviar."],
	["laco", "Inimigo fraco? Use o Selo de Alma para capturar. Só 2 tentativas, e o Elo precisa ter nível para a raridade dele."],
	["dex", "Digidex: todos os Digialmas que você já viu. Capturou um? Veja em quais raridades ele existe e quais você já teve."],
	["bolsa", "Bolsa: amuletos, Mochila (para que serve cada item), Árvore de Alma, Fusões e equipe. Fusão sobe atributos, mas NUNCA muda a raridade."],
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
	var y := 38.0
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
		y += 29.0
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
