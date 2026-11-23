extends Node
## Autoload "Game": estado do jogo, dados, recursos visuais compartilhados e transições.

const MP := "res://assets/packs/scarloxy_mpwsp01/"
const GP := "res://assets/packs/scarloxy_graphics/"
const UI := "res://assets/ui/"
const BASE := Vector2(640, 360)

const GAME_TITLE := "DIGIALMA"
const GAME_SUBTITLE := "monstrinhos que vivem com você"

# --- Personagens jogáveis (sprites do pacote, 4x4 quadros de 128px: baixo, esquerda, direita, cima)
const CHARACTERS := {
	"player": {"nome": "Léo", "titulo": "Treinador", "cor": Color("3bd6c6")},
	"young_girl": {"nome": "Lia", "titulo": "Treinadora", "cor": Color("ff7ab8")},
}
# Guardiões dos santuários (resto dos personagens do pacote)
const LEADERS := ["fire_boss", "grass_boss", "water_boss", "blond", "hat_girl", "purple_girl", "straw", "young_guy"]

# --- Monstros (id = número do sprite no pacote MPWSP01). Nomes e falas nossos.
# hp/atk/def: multiplicadores de status. evo: [id da evolução, nível]. moves: golpes por nível.
var MONSTERS := {
	7: {"nome": "Brasito", "tipo": "Fogo", "cor": Color("ff7a3d"), "hp": 1.0, "atk": 1.05, "def": 0.95, "evo": [8, 8], "evo_guarda": 17, "moves": ["investida", "brasa"], "jeito": "esquentadinho"},
	8: {"nome": "Tatubrasa", "tipo": "Fogo", "cor": Color("ff7a3d"), "hp": 1.2, "atk": 1.25, "def": 1.15, "evo": [9, 14], "moves": ["investida", "brasa", "erupcao"], "jeito": "teimoso", "ramo": "furia"},
	9: {"nome": "Vulcatatu", "tipo": "Fogo", "cor": Color("ff7a3d"), "hp": 1.45, "atk": 1.5, "def": 1.35, "evo": [], "moves": ["investida", "brasa", "erupcao"], "jeito": "orgulhoso", "ramo": "furia"},
	# ramo GUARDA do Brasito: nasce de quem luta aparando e esquivando
	17: {"nome": "Tatumuro", "tipo": "Fogo", "cor": Color("6aa8ff"), "hp": 1.35, "atk": 1.0, "def": 1.5, "evo": [18, 14], "moves": ["investida", "brasa", "erupcao"], "jeito": "paciente", "ramo": "guarda"},
	18: {"nome": "Muralhatu", "tipo": "Fogo", "cor": Color("6aa8ff"), "hp": 1.7, "atk": 1.2, "def": 1.8, "evo": [], "moves": ["investida", "brasa", "erupcao"], "jeito": "inabalável", "ramo": "guarda"},
	12: {"nome": "Marolim", "tipo": "Água", "cor": Color("4fa8ff"), "hp": 1.05, "atk": 0.95, "def": 1.0, "evo": [13, 8], "moves": ["investida", "jato"], "jeito": "preguiçoso"},
	13: {"nome": "Ondelfim", "tipo": "Água", "cor": Color("4fa8ff"), "hp": 1.25, "atk": 1.15, "def": 1.2, "evo": [14, 14], "moves": ["investida", "jato", "tsunami"], "jeito": "brincalhão"},
	14: {"nome": "Maremoto", "tipo": "Água", "cor": Color("4fa8ff"), "hp": 1.5, "atk": 1.4, "def": 1.4, "evo": [], "moves": ["investida", "jato", "tsunami"], "jeito": "sereno"},
	1: {"nome": "Brotito", "tipo": "Planta", "cor": Color("5cc95c"), "hp": 1.1, "atk": 0.95, "def": 1.05, "evo": [2, 8], "moves": ["investida", "folha"], "jeito": "tímido"},
	2: {"nome": "Folhagato", "tipo": "Planta", "cor": Color("5cc95c"), "hp": 1.3, "atk": 1.15, "def": 1.2, "evo": [3, 14], "moves": ["investida", "folha", "floresta"], "jeito": "curioso"},
	3: {"nome": "Leofolha", "tipo": "Planta", "cor": Color("5cc95c"), "hp": 1.55, "atk": 1.4, "def": 1.4, "evo": [], "moves": ["investida", "folha", "floresta"], "jeito": "protetor"},
	4: {"nome": "Capivolt", "tipo": "Normal", "cor": Color("c8a070"), "hp": 1.2, "atk": 0.9, "def": 1.1, "evo": [], "moves": ["investida", "arranhao"], "jeito": "tranquilo"},
	5: {"nome": "Piuí", "tipo": "Voador", "cor": Color("e0a0c0"), "hp": 0.9, "atk": 1.0, "def": 0.85, "evo": [], "moves": ["investida", "rajada"], "jeito": "agitado"},
	6: {"nome": "Cervogelo", "tipo": "Gelo", "cor": Color("9ae0ff"), "hp": 1.15, "atk": 1.1, "def": 1.05, "evo": [], "moves": ["investida", "geada"], "jeito": "elegante"},
	10: {"nome": "Sonhinho", "tipo": "Psíquico", "cor": Color("a070e0"), "hp": 1.0, "atk": 1.05, "def": 0.95, "evo": [], "moves": ["investida", "mente"], "jeito": "sonolento"},
	11: {"nome": "Serpentrão", "tipo": "Elétrico", "cor": Color("ffd84a"), "hp": 1.05, "atk": 1.15, "def": 0.95, "evo": [], "moves": ["investida", "choque"], "jeito": "nervoso"},
	15: {"nome": "Larvinha", "tipo": "Inseto", "cor": Color("a0e070"), "hp": 0.95, "atk": 0.9, "def": 1.0, "evo": [16, 7], "moves": ["investida", "picada"], "jeito": "faminto"},
	16: {"nome": "Libelúmen", "tipo": "Inseto", "cor": Color("a0e070"), "hp": 1.15, "atk": 1.15, "def": 1.0, "evo": [], "moves": ["investida", "picada", "rajada"], "jeito": "veloz"},
}

# Linha do "pé" de cada sprite dentro do quadro de 96px (para encostar no chão/plataforma)
var FOOT := {1: 68, 2: 74, 3: 89, 4: 72, 5: 78, 6: 81, 7: 71, 8: 78, 9: 93, 10: 70, 11: 73, 12: 67, 13: 76, 14: 91, 15: 63, 16: 75, 17: 78, 18: 93}
## Ritmo de ataque de cada espécie: [tempo até o impacto, é finta?].
## Comuns usam só o 1º golpe (a "assinatura"); raros e líderes fazem o padrão inteiro.
const PATTERNS := {
	1: [[1.1, false], [0.8, false]], 2: [[1.1, false], [0.8, false], [0.8, false]], 3: [[1.2, false], [0.7, false], [1.3, true]],
	4: [[1.15, false], [1.15, false], [0.5, false]],
	5: [[0.6, false], [0.5, false], [0.5, false]],
	6: [[1.0, false], [0.6, false], [1.3, true]],
	7: [[1.0, false], [0.75, false]], 8: [[1.0, false], [0.75, false], [0.75, false]], 9: [[1.2, true], [0.7, false], [0.7, false]],
	10: [[1.35, true], [1.35, true]],
	11: [[1.5, true], [0.6, false]],
	12: [[0.9, false], [1.25, true]], 13: [[0.9, false], [1.25, true], [0.6, false]], 14: [[1.3, true], [0.9, false], [0.6, false]],
	15: [[0.95, false], [0.95, false]],
	16: [[0.55, false], [0.85, true], [0.45, false]],
	17: [[1.1, false], [1.1, false]], 18: [[1.3, true], [1.0, false], [0.8, false]],
}
## Golpes especiais custam Energia (ataques normais e aparos geram).
const ENERGY_COST := 3
const ENERGY_MAX := 5
const TYPE_SPECIAL := {"Pedra": "avalanche", "Metal": "martelo", "Sombra": "eclipse", "Luz": "aurora", "Veneno": "nevoa_toxica", "Som": "sinfonia", "Cristal": "prisma", "Normal": "impacto", "Voador": "furacao", "Gelo": "nevasca", "Psíquico": "pesadelo", "Elétrico": "trovao", "Inseto": "enxame", "Fogo": "erupcao", "Água": "tsunami", "Planta": "floresta", "Fumaça": "nuvem_negra", "Ácido": "corrosao", "Vácuo": "colapso", "Plasma": "arco_voltaico", "Gravidade": "orbita", "Glitch": "tela_azul", "Tempo": "rebobinar", "Espelho": "prisma_cego"}
const TYPE_SUPREME := {"Pedra": "terremoto", "Metal": "forja", "Sombra": "noite_eterna", "Luz": "sol_nascente", "Veneno": "praga", "Som": "estrondo", "Cristal": "caleidoscopio", "Fogo": "supernova", "Água": "abismo", "Planta": "ancestral", "Normal": "impacto_final", "Voador": "ceu_partido", "Gelo": "zero_absoluto", "Psíquico": "sonho_eterno", "Elétrico": "tempestade", "Inseto": "colmeia", "Fumaça": "cinza_eterna", "Ácido": "chuva_acida", "Vácuo": "nada_absoluto", "Plasma": "tempestade_solar", "Gravidade": "buraco_negro", "Glitch": "falha_total", "Tempo": "parada_temporal", "Espelho": "mil_espelhos"}

## ÁRVORE DE ALMA: cada Digialma ganha 1 Ponto de Alma (PA) por nível.
## Teia de 15 nós: CENTELHA no centro, FÚRIA à esquerda, GUARDA à direita,
## VÍNCULO embaixo. "pos" é a posição relativa ao centro na tela da árvore.
const SOUL_TREE := {
	"a1": {"nome": "CENTELHA", "ramo": "raiz", "custo": 1, "req": "", "chave": true, "pos": Vector2(0, 0), "desc": "Libera o golpe especial do Digialma."},
	"f1": {"nome": "GARRA AFIADA", "ramo": "furia", "custo": 1, "req": "a1", "pos": Vector2(-58, -26), "desc": "+6% de dano."},
	"f2": {"nome": "FERVOR", "ramo": "furia", "custo": 1, "req": "f1", "pos": Vector2(-104, -62), "desc": "+6% de dano."},
	"f3": {"nome": "INSTINTO", "ramo": "furia", "custo": 1, "req": "f1", "pos": Vector2(-112, -2), "desc": "Combos perfeitos causam +10% de dano."},
	"f4": {"nome": "FUROR", "ramo": "furia", "custo": 2, "req": "f2", "pos": Vector2(-156, -40), "desc": "Começa as batalhas com +1 de Energia."},
	"f5": {"nome": "GOLPE SUPREMO", "ramo": "furia", "custo": 3, "req": "f4", "chave": true, "pos": Vector2(-196, -2), "desc": "Libera o Golpe Supremo do tipo (custa 5 de Energia)."},
	"g1": {"nome": "COURAÇA", "ramo": "guarda", "custo": 1, "req": "a1", "pos": Vector2(58, -26), "desc": "Recebe 6% menos dano."},
	"g2": {"nome": "CASCA DURA", "ramo": "guarda", "custo": 1, "req": "g1", "pos": Vector2(104, -62), "desc": "Recebe 6% menos dano."},
	"g3": {"nome": "VIGOR", "ramo": "guarda", "custo": 1, "req": "g1", "pos": Vector2(112, -2), "desc": "+10% de vida máxima."},
	"g4": {"nome": "REFLEXO", "ramo": "guarda", "custo": 2, "req": "g2", "pos": Vector2(156, -40), "desc": "Janela de esquiva/aparo 15% maior."},
	"g5": {"nome": "SENTINELA", "ramo": "guarda", "custo": 3, "req": "g4", "chave": true, "pos": Vector2(196, -2), "desc": "Janela 25% maior. No idle, desvia de tudo."},
	"v1": {"nome": "FARO DE ALMA", "ramo": "vinculo", "custo": 1, "req": "a1", "pos": Vector2(0, 46), "desc": "+20% de XP no idle."},
	"v2": {"nome": "LAÇO", "ramo": "vinculo", "custo": 1, "req": "v1", "pos": Vector2(-40, 82), "desc": "Sincronia sobe 15% mais rápido."},
	"v3": {"nome": "COLETA", "ramo": "vinculo", "custo": 1, "req": "v1", "pos": Vector2(40, 82), "desc": "+20% de bits no idle."},
	"v4": {"nome": "ALMA GÊMEA", "ramo": "vinculo", "custo": 3, "req": "v2", "chave": true, "pos": Vector2(0, 112), "desc": "Começa as batalhas com 25 de Sincronia."},
}


## Bônus somados da árvore de um Digialma.
func skill_dmg(m: Dictionary) -> float:
	return (0.06 if has_skill(m, "f1") else 0.0) + (0.06 if has_skill(m, "f2") else 0.0) + gear_bonus(m, "dano")


func skill_def(m: Dictionary) -> float:
	return (0.06 if has_skill(m, "g1") else 0.0) + (0.06 if has_skill(m, "g2") else 0.0) + gear_bonus(m, "defesa")


func skill_window(m: Dictionary) -> float:
	return (1.15 if has_skill(m, "g4") else 1.0) * (1.25 if has_skill(m, "g5") else 1.0) * (1.0 + gear_bonus(m, "janela"))


## UPGRADES DO ELO: comprados com bits (o idle é a principal fonte de bits).
const ELO_UPGRADES := {
	"auto": {"nome": "PURIFICAÇÃO AUTOMÁTICA", "custos": [300, 900], "req": "", "desc": ["No idle, 15% dos Nefastos purificados se juntam a você sozinhos.", "Sobe para 30%."]},
	"chamado": {"nome": "CHAMADO PERSISTENTE", "custos": [600], "req": "auto", "desc": ["Se você perder o chamado de um RARO no idle, o Elo tenta sozinho (50%)."]},
	"vaga": {"nome": "NOVA VAGA NA EQUIPE", "custos": [400, 1000], "req": "", "desc": ["Equipe de 2 para 3 Digialmas.", "Equipe de 3 para 4 Digialmas."]},
	"faro": {"nome": "FARO DE EXPLORADOR", "custos": [250, 700], "req": "", "desc": ["No idle, encontros 25% mais frequentes.", "Encontros 45% mais frequentes."]},
	"bolsa": {"nome": "BOLSA DE BITS", "custos": [350, 900], "req": "", "desc": ["+50% de bits ganhos.", "+100% de bits ganhos."]},
}
var elo_up := {}

## INSÍGNIAS: cada guardião vencido dá uma insígnia com um efeito. O Elo tem
## espaços para equipá-las (1, +1 no Elo 6, +1 no Elo 12) e cada uma sobe de
## nível (I a III) vencendo a REVANCHE do guardião na zona 10 do mapa purificado.
const BADGE_FX := {
	"raiz": {"nome": "Raiz", "efeito": "Suportes curam +%d%%", "val": [15, 30, 50]},
	"onda": {"nome": "Onda", "efeito": "+%d%% na captura automática de raros", "val": [5, 10, 15]},
	"brasa": {"nome": "Brasa", "efeito": "+%d%% de chance de crítico no idle", "val": [5, 9, 14]},
	"nevoa": {"nome": "Névoa", "efeito": "Raros aparecem +%d%% mais", "val": [25, 50, 80]},
	"cobre": {"nome": "Engrenagem", "efeito": "+%d%% de bits ganhos", "val": [15, 30, 50]},
	"prisma": {"nome": "Prisma", "efeito": "+%d%% de XP para a equipe", "val": [15, 30, 50]},
}
const BADGE_SLOT_ELO := [1, 6, 12]  # nível do Elo que abre cada espaço
const ROMAN := ["", "I", "II", "III"]
var badge_lv := {}  # insígnia -> nível (1 a 3)
var badge_eq := []  # insígnias equipadas no Elo


func badge_owned() -> Array:
	var r: Array = []
	for i in mini(badges, REGIONS.size()):
		r.append(REGIONS[i]["lider"]["badge"])
	return r


func badge_level(k: String) -> int:
	return int(badge_lv.get(k, 1)) if badge_owned().has(k) else 0


func badge_slots() -> int:
	var n := 0
	for need in BADGE_SLOT_ELO:
		if elo_lv >= need:
			n += 1
	return n


## Bônus da insígnia (0 se ela não estiver equipada).
func badge_bonus(k: String) -> float:
	if not badge_eq.has(k) or badge_level(k) <= 0:
		return 0.0
	return BADGE_FX[k]["val"][badge_level(k) - 1] / 100.0


## Arruma os espaços: tira o que não vale mais e preenche espaços vazios.
func badge_autoequip() -> void:
	var owned := badge_owned()
	badge_eq = badge_eq.filter(func(k): return owned.has(k))
	while badge_eq.size() > badge_slots():
		badge_eq.pop_back()
	for k in owned:
		if badge_eq.size() < badge_slots() and not badge_eq.has(k):
			badge_eq.append(k)

## Sprites próprios (fora do pacote)

## Sprites próprios (fora do pacote): ramos de evolução recoloridos.
const CUSTOM_SPRITES := {17: "res://assets/monsters/sprite17_%s.png", 18: "res://assets/monsters/sprite18_%s.png"}
## Animações novas (geradas com IA e tratadas em pixel art): substituem/acrescentam às do pacote.
const EXTRA_ANIMS := {9: {"walk": "res://assets/monsters/sprite9_walk.png", "attack": "res://assets/monsters/sprite9_attack2.png"},
	4: {"walk": "res://assets/monsters/sprite4_walk.png"}, 5: {"walk": "res://assets/monsters/sprite5_walk.png"}, 6: {"walk": "res://assets/monsters/sprite6_walk.png"},
	10: {"walk": "res://assets/monsters/sprite10_walk.png"}, 11: {"walk": "res://assets/monsters/sprite11_walk.png"},
	15: {"walk": "res://assets/monsters/sprite15_walk.png"}, 16: {"walk": "res://assets/monsters/sprite16_walk.png"}}


func foot_offset(id: int) -> Vector2:
	return Vector2(-48, -FOOT.get(id, 90) - 2)


# --- Golpes. fx = efeito do pacote (graphics/attacks); kind: "contato" (o monstro avança) ou "projetil".
const MOVES := {
	"investida": {"nome": "Investida", "tipo": "Normal", "poder": 9, "fx": "scratch", "kind": "contato", "cd": 0},
	"arranhao": {"nome": "Arranhão", "tipo": "Normal", "poder": 12, "fx": "scratch", "kind": "contato", "cd": 0},
	"brasa": {"nome": "Brasa", "tipo": "Fogo", "poder": 13, "fx": "fire", "kind": "projetil", "cd": 0},
	"erupcao": {"nome": "Erupção", "tipo": "Fogo", "poder": 24, "fx": "explosion", "kind": "projetil", "cd": 2},
	"jato": {"nome": "Jato d'Água", "tipo": "Água", "poder": 13, "fx": "splash", "kind": "projetil", "cd": 0},
	"tsunami": {"nome": "Tsunami", "tipo": "Água", "poder": 24, "fx": "splash", "kind": "projetil", "cd": 2},
	"folha": {"nome": "Folha Navalha", "tipo": "Planta", "poder": 13, "fx": "green", "kind": "projetil", "cd": 0},
	"floresta": {"nome": "Fúria da Mata", "tipo": "Planta", "poder": 24, "fx": "green", "kind": "projetil", "cd": 2},
	"rajada": {"nome": "Rajada", "tipo": "Voador", "poder": 12, "fx": "scratch", "kind": "projetil", "cd": 0},
	"geada": {"nome": "Geada", "tipo": "Gelo", "poder": 13, "fx": "ice", "kind": "projetil", "cd": 0},
	"mente": {"nome": "Onda Mental", "tipo": "Psíquico", "poder": 13, "fx": "explosion", "kind": "projetil", "cd": 0},
	"choque": {"nome": "Choque", "tipo": "Elétrico", "poder": 13, "fx": "explosion", "kind": "projetil", "cd": 0},
	# golpe de SUPORTE: cura em vez de ferir (gasta energia como um especial)
	"luz_vital": {"nome": "Luz Vital", "tipo": "Normal", "poder": 0, "cura": 0.35, "fx": "green", "kind": "projetil", "cd": 2},
	# especiais de tipo (liberados pelo nó CENTELHA para quem não tem especial próprio)
	"impacto": {"nome": "Impacto Brutal", "tipo": "Normal", "poder": 22, "fx": "scratch", "kind": "contato", "cd": 2},
	"furacao": {"nome": "Furacão", "tipo": "Voador", "poder": 22, "fx": "scratch", "kind": "projetil", "cd": 2},
	"nevasca": {"nome": "Nevasca", "tipo": "Gelo", "poder": 22, "fx": "ice", "kind": "projetil", "cd": 2},
	"pesadelo": {"nome": "Pesadelo", "tipo": "Psíquico", "poder": 22, "fx": "explosion", "kind": "projetil", "cd": 2},
	"trovao": {"nome": "Trovão", "tipo": "Elétrico", "poder": 22, "fx": "explosion", "kind": "projetil", "cd": 2},
	"enxame": {"nome": "Enxame", "tipo": "Inseto", "poder": 22, "fx": "green", "kind": "projetil", "cd": 2},
	# golpes supremos (ramo FÚRIA da Árvore de Alma) — custam 5 de Energia
	"supernova": {"nome": "Supernova", "tipo": "Fogo", "poder": 34, "fx": "explosion", "kind": "projetil", "cd": 3, "supremo": true},
	"abismo": {"nome": "Maré Abissal", "tipo": "Água", "poder": 34, "fx": "splash", "kind": "projetil", "cd": 3, "supremo": true},
	"ancestral": {"nome": "Floresta Ancestral", "tipo": "Planta", "poder": 34, "fx": "green", "kind": "projetil", "cd": 3, "supremo": true},
	"impacto_final": {"nome": "Impacto Final", "tipo": "Normal", "poder": 32, "fx": "scratch", "kind": "contato", "cd": 3, "supremo": true},
	"ceu_partido": {"nome": "Céu Partido", "tipo": "Voador", "poder": 32, "fx": "scratch", "kind": "projetil", "cd": 3, "supremo": true},
	"zero_absoluto": {"nome": "Zero Absoluto", "tipo": "Gelo", "poder": 32, "fx": "ice", "kind": "projetil", "cd": 3, "supremo": true},
	"sonho_eterno": {"nome": "Sonho Eterno", "tipo": "Psíquico", "poder": 32, "fx": "explosion", "kind": "projetil", "cd": 3, "supremo": true},
	"tempestade": {"nome": "Tempestade", "tipo": "Elétrico", "poder": 32, "fx": "explosion", "kind": "projetil", "cd": 3, "supremo": true},
	"colmeia": {"nome": "Colmeia Real", "tipo": "Inseto", "poder": 32, "fx": "green", "kind": "projetil", "cd": 3, "supremo": true},
	"ruido": {"nome": "Explosão de Ruído", "tipo": "Normal", "poder": 26, "fx": "explosion", "kind": "projetil", "cd": 0},
	"picada": {"nome": "Picada", "tipo": "Inseto", "poder": 12, "fx": "scratch", "kind": "contato", "cd": 0},
	# NOVOS ELEMENTOS (mid/end game): básico, especial e supremo
	# ELEMENTOS DO MID GAME: básico, especial e supremo
	"fuligem": {"nome": "Fuligem", "tipo": "Fumaça", "poder": 13, "fx": "explosion", "kind": "projetil", "cd": 0},
	"nuvem_negra": {"nome": "Nuvem Negra", "tipo": "Fumaça", "poder": 22, "fx": "explosion", "kind": "projetil", "cd": 2},
	"cinza_eterna": {"nome": "Cinza Eterna", "tipo": "Fumaça", "poder": 32, "fx": "explosion", "kind": "projetil", "cd": 3, "supremo": true},
	"respingo": {"nome": "Respingo Ácido", "tipo": "Ácido", "poder": 13, "fx": "splash", "kind": "projetil", "cd": 0},
	"corrosao": {"nome": "Corrosão", "tipo": "Ácido", "poder": 22, "fx": "green", "kind": "projetil", "cd": 2},
	"chuva_acida": {"nome": "Chuva Ácida", "tipo": "Ácido", "poder": 32, "fx": "splash", "kind": "projetil", "cd": 3, "supremo": true},
	"sopro_vazio": {"nome": "Sopro do Vazio", "tipo": "Vácuo", "poder": 13, "fx": "scratch", "kind": "projetil", "cd": 0},
	"colapso": {"nome": "Colapso", "tipo": "Vácuo", "poder": 22, "fx": "explosion", "kind": "projetil", "cd": 2},
	"nada_absoluto": {"nome": "Nada Absoluto", "tipo": "Vácuo", "poder": 32, "fx": "explosion", "kind": "projetil", "cd": 3, "supremo": true},
	"ionizar": {"nome": "Ionizar", "tipo": "Plasma", "poder": 13, "fx": "explosion", "kind": "projetil", "cd": 0},
	"arco_voltaico": {"nome": "Arco Voltaico", "tipo": "Plasma", "poder": 22, "fx": "explosion", "kind": "projetil", "cd": 2},
	"tempestade_solar": {"nome": "Tempestade Solar", "tipo": "Plasma", "poder": 32, "fx": "fire", "kind": "projetil", "cd": 3, "supremo": true},
	"peso_subito": {"nome": "Peso Súbito", "tipo": "Gravidade", "poder": 13, "fx": "explosion", "kind": "contato", "cd": 0},
	"orbita": {"nome": "Órbita Esmagadora", "tipo": "Gravidade", "poder": 22, "fx": "explosion", "kind": "projetil", "cd": 2},
	"buraco_negro": {"nome": "Buraco Negro", "tipo": "Gravidade", "poder": 32, "fx": "explosion", "kind": "projetil", "cd": 3, "supremo": true},
	"bug": {"nome": "Bug", "tipo": "Glitch", "poder": 13, "fx": "scratch", "kind": "contato", "cd": 0},
	"tela_azul": {"nome": "Tela Azul", "tipo": "Glitch", "poder": 22, "fx": "ice", "kind": "projetil", "cd": 2},
	"falha_total": {"nome": "Falha Total", "tipo": "Glitch", "poder": 32, "fx": "explosion", "kind": "projetil", "cd": 3, "supremo": true},
	"tique_taque": {"nome": "Tique-Taque", "tipo": "Tempo", "poder": 13, "fx": "scratch", "kind": "contato", "cd": 0},
	"rebobinar": {"nome": "Rebobinar", "tipo": "Tempo", "poder": 22, "fx": "ice", "kind": "projetil", "cd": 2},
	"parada_temporal": {"nome": "Parada Temporal", "tipo": "Tempo", "poder": 32, "fx": "ice", "kind": "projetil", "cd": 3, "supremo": true},
	"reflexo": {"nome": "Reflexo", "tipo": "Espelho", "poder": 13, "fx": "ice", "kind": "projetil", "cd": 0},
	"prisma_cego": {"nome": "Prisma Cego", "tipo": "Espelho", "poder": 22, "fx": "ice", "kind": "projetil", "cd": 2},
	"mil_espelhos": {"nome": "Mil Espelhos", "tipo": "Espelho", "poder": 32, "fx": "ice", "kind": "projetil", "cd": 3, "supremo": true},
	"pedrada": {"nome": "Pedrada", "tipo": "Pedra", "poder": 13, "fx": "explosion", "kind": "projetil", "cd": 0},
	"avalanche": {"nome": "Avalanche", "tipo": "Pedra", "poder": 22, "fx": "explosion", "kind": "projetil", "cd": 2},
	"terremoto": {"nome": "Terremoto", "tipo": "Pedra", "poder": 32, "fx": "explosion", "kind": "projetil", "cd": 3, "supremo": true},
	"lamina": {"nome": "Lâmina de Aço", "tipo": "Metal", "poder": 13, "fx": "scratch", "kind": "contato", "cd": 0},
	"martelo": {"nome": "Martelo de Ferro", "tipo": "Metal", "poder": 22, "fx": "scratch", "kind": "contato", "cd": 2},
	"forja": {"nome": "Forja Divina", "tipo": "Metal", "poder": 32, "fx": "explosion", "kind": "contato", "cd": 3, "supremo": true},
	"sombra": {"nome": "Garra Sombria", "tipo": "Sombra", "poder": 13, "fx": "scratch", "kind": "contato", "cd": 0},
	"eclipse": {"nome": "Eclipse", "tipo": "Sombra", "poder": 22, "fx": "explosion", "kind": "projetil", "cd": 2},
	"noite_eterna": {"nome": "Noite Eterna", "tipo": "Sombra", "poder": 32, "fx": "explosion", "kind": "projetil", "cd": 3, "supremo": true},
	"raio_luz": {"nome": "Raio de Luz", "tipo": "Luz", "poder": 13, "fx": "explosion", "kind": "projetil", "cd": 0},
	"aurora": {"nome": "Aurora", "tipo": "Luz", "poder": 22, "fx": "explosion", "kind": "projetil", "cd": 2},
	"sol_nascente": {"nome": "Sol Nascente", "tipo": "Luz", "poder": 32, "fx": "explosion", "kind": "projetil", "cd": 3, "supremo": true},
	"toxina": {"nome": "Toxina", "tipo": "Veneno", "poder": 13, "fx": "green", "kind": "projetil", "cd": 0},
	"nevoa_toxica": {"nome": "Névoa Tóxica", "tipo": "Veneno", "poder": 22, "fx": "green", "kind": "projetil", "cd": 2},
	"praga": {"nome": "Praga Ancestral", "tipo": "Veneno", "poder": 32, "fx": "green", "kind": "projetil", "cd": 3, "supremo": true},
	"grito": {"nome": "Grito Sônico", "tipo": "Som", "poder": 13, "fx": "explosion", "kind": "projetil", "cd": 0},
	"sinfonia": {"nome": "Sinfonia", "tipo": "Som", "poder": 22, "fx": "explosion", "kind": "projetil", "cd": 2},
	"estrondo": {"nome": "Estrondo Final", "tipo": "Som", "poder": 32, "fx": "explosion", "kind": "projetil", "cd": 3, "supremo": true},
	"estilhaco": {"nome": "Estilhaço", "tipo": "Cristal", "poder": 13, "fx": "ice", "kind": "projetil", "cd": 0},
	"prisma": {"nome": "Prisma", "tipo": "Cristal", "poder": 22, "fx": "ice", "kind": "projetil", "cd": 2},
	"caleidoscopio": {"nome": "Caleidoscópio", "tipo": "Cristal", "poder": 32, "fx": "ice", "kind": "projetil", "cd": 3, "supremo": true},
	# golpes de ELEMENTOS HÍBRIDOS (nascem da Fusão de Essência)
	"h_vapor": {"nome": "Vapor Escaldante", "tipo": "Vapor", "poder": 20, "fx": "splash", "kind": "projetil", "cd": 0},
	"h_plasma": {"nome": "Raio de Plasma", "tipo": "Plasma", "poder": 20, "fx": "explosion", "kind": "projetil", "cd": 0},
	"h_tormenta": {"nome": "Chuva Elétrica", "tipo": "Tormenta", "poder": 20, "fx": "explosion", "kind": "projetil", "cd": 0},
	"h_pantano": {"nome": "Lama Viva", "tipo": "Pântano", "poder": 20, "fx": "splash", "kind": "projetil", "cd": 0},
	"h_nevasca": {"nome": "Nevasca Alada", "tipo": "Nevasca", "poder": 20, "fx": "ice", "kind": "projetil", "cd": 0},
	"h_bioluz": {"nome": "Raiz Condutora", "tipo": "Bioluz", "poder": 20, "fx": "green", "kind": "projetil", "cd": 0},
	"h_fatuo": {"nome": "Chama Fantasma", "tipo": "Fogo-fátuo", "poder": 20, "fx": "explosion", "kind": "projetil", "cd": 0},
	"h_geleira": {"nome": "Lança de Gelo", "tipo": "Geleira", "poder": 20, "fx": "ice", "kind": "contato", "cd": 0},
	"h_astral": {"nome": "Queda Astral", "tipo": "Astral", "poder": 20, "fx": "explosion", "kind": "projetil", "cd": 0},
}
const TYPE_COLORS := {"Normal": Color("e8e0d0"), "Fogo": Color("ff7a3d"), "Água": Color("4fa8ff"), "Planta": Color("5cc95c"),
	"Voador": Color("e0a0c0"), "Gelo": Color("9ae0ff"), "Psíquico": Color("c080ff"), "Elétrico": Color("ffd84a"), "Inseto": Color("a0e070"),
	"Vapor": Color("f4c0d0"), "Plasma": Color("ff5ad8"), "Tormenta": Color("7a8aff"), "Pântano": Color("8a9a4a"), "Nevasca": Color("d8f4ff"),
	"Bioluz": Color("6affb8"), "Fogo-fátuo": Color("5ad8ff"), "Geleira": Color("6ac8e8"), "Astral": Color("b8a0ff"),
	"Pedra": Color("b89a6a"), "Metal": Color("a8b8c8"), "Sombra": Color("6a4a9a"), "Luz": Color("fff0a0"), "Veneno": Color("b060d0"), "Som": Color("ff9ac8"), "Cristal": Color("8af0f0"),
	"Fumaça": Color("a8a0b0"), "Ácido": Color("c8f04a"), "Vácuo": Color("7a6ad8"), "Gravidade": Color("c89a6a"), "Glitch": Color("3af0d0"), "Tempo": Color("e8c870"), "Espelho": Color("e8ecff")}

## ELEMENTOS HÍBRIDOS: a Fusão de Essência entre dois tipos que combinam
## cria um elemento novo (Água + Fogo = Vapor). Cada um tem golpe próprio e
## explora fraquezas que nenhum dos pais cobria sozinho. Nunca é "fraco".
const HYBRIDS := {
	"Vapor": {"de": ["Fogo", "Água"], "golpe": "h_vapor", "fortes": ["Fogo", "Gelo", "Planta", "Inseto"], "desc": "água fervendo"},
	"Plasma": {"de": ["Fogo", "Elétrico"], "golpe": "h_plasma", "fortes": ["Metal", "Vácuo", "Gelo"], "desc": "fogo eletrizado"},
	"Tormenta": {"de": ["Água", "Elétrico"], "golpe": "h_tormenta", "fortes": ["Fogo", "Água", "Voador"], "desc": "tempestade viva"},
	"Pântano": {"de": ["Água", "Planta"], "golpe": "h_pantano", "fortes": ["Fogo", "Elétrico", "Água"], "desc": "lama que respira"},
	"Nevasca": {"de": ["Gelo", "Voador"], "golpe": "h_nevasca", "fortes": ["Planta", "Voador", "Inseto"], "desc": "vento congelante"},
	"Bioluz": {"de": ["Planta", "Elétrico"], "golpe": "h_bioluz", "fortes": ["Água", "Voador", "Psíquico"], "desc": "seiva que brilha"},
	"Fogo-fátuo": {"de": ["Fogo", "Psíquico"], "golpe": "h_fatuo", "fortes": ["Psíquico", "Planta", "Inseto"], "desc": "chama fantasma"},
	"Geleira": {"de": ["Água", "Gelo"], "golpe": "h_geleira", "fortes": ["Fogo", "Planta", "Voador"], "desc": "gelo milenar"},
	"Astral": {"de": ["Psíquico", "Voador"], "golpe": "h_astral", "fortes": ["Psíquico", "Inseto", "Normal"], "desc": "céu estrelado"},
}
const TYPE_SLUG := {"Normal": "normal", "Fogo": "fogo", "Água": "agua", "Planta": "planta", "Voador": "voador", "Gelo": "gelo", "Psíquico": "psiquico", "Elétrico": "eletrico", "Inseto": "inseto",
	"Vapor": "vapor", "Plasma": "plasma", "Tormenta": "tormenta", "Pântano": "pantano", "Nevasca": "nevasca", "Bioluz": "bioluz", "Fogo-fátuo": "fatuo", "Geleira": "geleira", "Astral": "astral",
	"Pedra": "pedra", "Metal": "metal", "Sombra": "sombra", "Luz": "luz", "Veneno": "veneno", "Som": "som", "Cristal": "cristal",
	"Fumaça": "fumaca", "Ácido": "acido", "Vácuo": "vacuo", "Gravidade": "gravidade", "Glitch": "glitch", "Tempo": "tempo", "Espelho": "espelho"}


func hybrid_of(a: String, b: String) -> String:
	for k in HYBRIDS:
		var de: Array = HYBRIDS[k]["de"]
		if de.has(a) and de.has(b) and a != b:
			return k
	return ""


func strong_vs(tp: String) -> Array:
	return HYBRIDS[tp]["fortes"] if HYBRIDS.has(tp) else STRONG.get(tp, [])


## Golpe que a essência dá (híbrido ou o básico do tipo).
func essence_move(ess: String) -> String:
	return HYBRIDS[ess]["golpe"] if HYBRIDS.has(ess) else TYPE_BASIC[ess]
const STRONG := {"Fogo": ["Planta", "Gelo", "Inseto", "Metal"], "Água": ["Fogo", "Pedra", "Ácido", "Glitch"], "Planta": ["Água", "Pedra"], "Elétrico": ["Água", "Voador", "Metal"],
	"Gelo": ["Planta", "Voador"], "Voador": ["Planta", "Inseto", "Fumaça"], "Inseto": ["Planta", "Psíquico"], "Psíquico": ["Veneno", "Gravidade"],
	# novos elementos
	"Pedra": ["Fogo", "Voador", "Gelo", "Inseto"], "Metal": ["Gelo", "Pedra", "Cristal", "Espelho"], "Sombra": ["Psíquico", "Som"],
	"Luz": ["Sombra", "Veneno"], "Veneno": ["Planta", "Inseto"], "Som": ["Cristal", "Voador", "Espelho", "Glitch"], "Cristal": ["Sombra", "Elétrico"],
	# elementos do mid game
	"Fumaça": ["Planta", "Inseto", "Espelho"], "Ácido": ["Metal", "Pedra", "Planta"], "Vácuo": ["Fumaça", "Som", "Fogo"],
	"Plasma": ["Metal", "Vácuo", "Gelo"], "Gravidade": ["Voador", "Vácuo", "Plasma"], "Glitch": ["Elétrico", "Metal", "Tempo"],
	"Tempo": ["Gravidade", "Psíquico", "Ácido"], "Espelho": ["Plasma", "Luz", "Psíquico"]}

# --- MAPAS E ZONAS DO IDLE (estilo Taskbar Hero)
## Cada região é um mapa com 10 zonas. Os Nefastos não param de vir; cada
## zona é mais forte. Se o grupo inteiro cair, volta uma zona. Na zona 10
## completa aparece o Santuário (o boss do mapa). Os elementos de cada mapa
## pressionam o inicial: o Fogo sobra na Floresta, sofre na Costa (Água) e
## precisa de parceiros de outros tipos para seguir.
const ZONES := 10
const ZONE_LV := [4, 21, 37, 55, 73, 91]  # nível mínimo na zona 1 de cada mapa
const ZONE_STEP := 2.0          # níveis a mais por zona
const ZONE_POOLS := [
	# Floresta: Planta/Inseto/Voador (bom para Fogo); no fim, a Água começa a aparecer
	[[15, 1, 5, 4], [15, 16, 1, 2, 5], [16, 2, 3, 5, 12, 154]],
	# Costa: Água/Elétrico (castiga o Fogo)
	[[12, 5, 15, 4], [12, 11, 13, 5], [13, 11, 14, 6, 170]],
	# Monte Brasa: Fogo/Gelo/Psíquico
	[[7, 5, 11, 10], [8, 6, 10, 11], [8, 9, 6, 17, 18, 162, 166]],
	# --- MID GAME ---
	# Pântano Sombrio: Ácido/Fumaça/Som (o Sonhinho e o Serpentrão evoluídos vivem aqui)
	[[111, 101, 136, 166], [111, 112, 102, 137, 101], [112, 113, 102, 103, 137, 138]],
	# Ruínas de Cobre: Metal/Glitch/Plasma
	[[106, 131, 121, 154], [106, 107, 131, 132, 122], [107, 108, 132, 133, 122, 123]],
	# Deserto de Cristal: Vácuo/Gravidade/Tempo/Espelho
	[[116, 126, 141, 146], [117, 127, 142, 147, 116], [118, 128, 143, 148, 117, 127]],
]
const ZONE_RAROS := [[10, 16], [6, 10, 16], [6, 16, 10, 158], [167, 171, 138], [155, 151, 133], [163, 159, 148]]
## Captura automática de raros no idle (quando você não clica a tempo).
## AUTO_RARE_BASE é a chance base; auto_rare_bonus fica pronto para itens
## futuros (ex.: um item que aumenta a chance).
const AUTO_RARE_BASE := 0.08
var auto_rare_bonus := 0.0
var zone := {}       # mapa -> zona atual
var zone_max := {}   # mapa -> maior zona liberada
var zone_kills := {} # mapa -> purificações na zona atual
var zone_auto := true
var all_purified := false


func zone_of(r: int) -> int:
	return int(zone.get(r, 1))


func zone_need(z: int) -> int:
	return 15 + z * 3


func zone_levels(r: int, z: int) -> Vector2i:
	var lo: int = ZONE_LV[r] + int((z - 1) * ZONE_STEP)
	return Vector2i(lo, lo + 2)


func zone_pool(r: int, z: int) -> Array:
	return ZONE_POOLS[r][0 if z <= 3 else (1 if z <= 7 else 2)]


func auto_rare_chance() -> float:
	return AUTO_RARE_BASE + auto_rare_bonus + (0.42 if elo_level("chamado") > 0 else 0.0) + badge_bonus("onda")


# --- Regiões da fatia jogável
const REGIONS := [
	{"nome": "Floresta Sussurrante", "bg": "res://assets/packs/scarloxy_mpwsp01/backgrounds/background1.png", "tint": Color(1, 1, 1),
		"arena": "arena_plant", "selvagens": [15, 5, 4, 1], "raros": [10], "nv": [3, 5],
		"lider": {"nome": "Silvana", "sprite": "grass_boss", "time": [[15, 10, 1], [1, 11, 2], [2, 13, 2]], "insignia": "Insígnia Raiz", "badge": "raiz", "ginasio": "Santuário Raiz"},
		"props": {"big": ["green_tree", "green_tree_bushy", "green_tree_small", "green_tree"], "small": ["p:flores", "p:cogumelo", "p:pedrinha", "p:flores", "p:pedra"], "front": ["grass", "p:pedra", "grass", "p:flores"]}, "chao": "terra", "prop_tint": Color(1, 1, 1),
		"piso": [Color("2f5a2a"), Color("3d7234"), Color("8fd45a")]},
	{"nome": "Costa Cristalina", "bg": "res://assets/packs/scarloxy_mpwsp01/backgrounds/background2.png", "tint": Color(1, 1, 1),
		"arena": "arena_water", "selvagens": [12, 5, 11, 15], "raros": [6, 10], "nv": [7, 9],
		"lider": {"nome": "Maré", "sprite": "water_boss", "time": [[11, 16, 2], [13, 17, 2], [14, 19, 3]], "insignia": "Insígnia Onda", "badge": "onda", "ginasio": "Santuário Maré Alta"},
		"props": {"big": ["palm", "palm_alt", "palm_small"], "small": ["p:concha", "p:estrela", "p:pedrinha", "p:concha"], "front": ["grass", "p:pedra", "p:estrela"]}, "chao": "areia", "prop_tint": Color(1, 1, 1),
		"piso": [Color("1f3f6a"), Color("2a5a8f"), Color("7fd0ff")]},
	{"nome": "Monte Brasa", "bg": "res://assets/backgrounds/vulcao.png", "tint": Color(1, 1, 1),
		"arena": "arean_fire", "selvagens": [7, 11, 8, 5], "raros": [6, 16], "nv": [11, 13],
		"lider": {"nome": "Ígneo", "sprite": "fire_boss", "time": [[6, 22, 2], [8, 23, 3], [9, 25, 3]], "insignia": "Insígnia Brasa", "badge": "brasa", "ginasio": "Santuário Cratera"},
		"props": {"big": ["ruin_pillar", "ruin_pillar_broke", "ruin_pillar_broke_alt", "p:cristal"], "small": ["p:fenda", "p:pedrinha", "p:pedra"], "front": ["p:cristal", "p:pedra", "p:pedrinha"]}, "chao": "basalto", "prop_tint": Color(0.62, 0.42, 0.44),
		"piso": [Color("4a1a14"), Color("6a2a1a"), Color("ff8a3d")]},
	# --- MID GAME ---
	{"nome": "Pântano Sombrio", "bg": "res://assets/backgrounds/pantano.png", "tint": Color(1, 1, 1),
		"arena": "arena_pantano", "plataforma": "pantano", "selvagens": [111, 101, 136, 166], "raros": [167, 171], "nv": [57, 59],
		"lider": {"nome": "Brumária", "sprite": "purple_girl", "time": [[103, 72, 2], [113, 73, 3], [138, 75, 3]], "insignia": "Insígnia Névoa", "badge": "nevoa", "ginasio": "Santuário Lodo Fundo"},
		"props": {"big": ["teal_tree", "teal_tree_bushy", "p:junco", "teal_tree_small", "p:junco"], "small": ["p:bolha", "p:cogumelo", "p:junco", "p:pedrinha", "p:bolha"], "front": ["p:junco", "grass", "p:bolha"]}, "chao": "lodo", "prop_tint": Color(0.62, 0.6, 0.72),
		"piso": [Color("1e2a22"), Color("2e3f30"), Color("b8e05a")]},
	{"nome": "Ruínas de Cobre", "bg": "res://assets/backgrounds/ruinas.png", "tint": Color(1, 1, 1),
		"arena": "arena_cobre", "plataforma": "cobre", "selvagens": [106, 131, 121, 154], "raros": [155, 151], "nv": [75, 77],
		"lider": {"nome": "Bronzo", "sprite": "young_guy", "time": [[108, 90, 2], [133, 91, 3], [123, 93, 3]], "insignia": "Insígnia Engrenagem", "badge": "cobre", "ginasio": "Santuário Engrenagem Mestra"},
		"props": {"big": ["ruin_pillar", "ruin_pillar_broke", "p:engrenagem", "ruin_gate", "ruin_pillar_broke_alt"], "small": ["p:cabo", "p:engrenagem", "p:pedrinha", "p:cabo"], "front": ["p:pedra", "p:engrenagem", "p:cabo"]}, "chao": "cobre", "prop_tint": Color(1.0, 0.78, 0.55),
		"piso": [Color("3a2418"), Color("6a3f22"), Color("ffb060")]},
	{"nome": "Deserto de Cristal", "bg": "res://assets/backgrounds/deserto.png", "tint": Color(1, 1, 1),
		"arena": "arena_cristal", "plataforma": "cristal", "selvagens": [116, 126, 141, 146], "raros": [163, 159], "nv": [93, 95],
		"lider": {"nome": "Lúmina", "sprite": "hat_girl", "time": [[128, 108, 3], [143, 109, 3], [148, 111, 4]], "insignia": "Insígnia Prisma", "badge": "prisma", "ginasio": "Santuário Ampulheta"},
		"props": {"big": ["p:obelisco", "p:cristal", "icerock1", "p:espelho", "icerock2"], "small": ["p:cristal", "p:pedrinha", "p:espelho", "p:cristal"], "front": ["icerock2", "p:cristal", "p:pedrinha"]}, "chao": "cristal", "prop_tint": Color(0.92, 0.82, 1.0),
		"piso": [Color("3a2a4a"), Color("6a4a7a"), Color("bff6ff")]},
]

# --- Falas da história. Cada fala: [quem, texto]. "" = narrador, "elo" = o aparelho.
const STORY := {
	"intro": [["", "Naquela noite, uma luz verde riscou o céu e caiu bem no seu quintal."],
		["", "No meio da grama, um aparelho pequeno piscava. Na tela, uma palavra: ELO."],
		["elo", "...vínculo detectado... sincronizando com %NOME%..."],
		["elo", "Os monstros desta terra estão perdendo seus vínculos. Sem vínculo, eles viram NEFASTOS."],
		["elo", "Os guardiões dos santuários protegem cada região... mas algo está sussurrando para eles."],
		["elo", "Escolha um parceiro. Juntos, vamos libertar os Nefastos."]],
	"lider0_antes": [["Silvana", "Minha floresta anda tão barulhenta... uma voz não para de sussurrar."], ["Silvana", "Mostre que esse vínculo é real!"]],
	"lider0_depois": [["Silvana", "...O sussurro parou. Obrigada."], ["Silvana", "Antes, eu vi uma sombra perto do lago. Ela olhou para o seu Elo... como se o conhecesse."]],
	"lider1_antes": [["Maré", "Vínculos? Vínculos te deixam fraco. A sombra me ensinou isso."], ["Maré", "Meus monstros obedecem. É o bastante."]],
	"lider1_depois": [["Maré", "Eu... o que eu disse? Desculpa, Ondelfim..."], ["elo", "Sinal estranho detectado no Monte Brasa. A sombra está mais forte."]],
	"lider2_antes": [["Ígneo", "...ELO... ESSE APARELHO... ELE NÃO DEVIA TER VOLTADO..."], ["Ígneo", "A SOMBRA DISSE PARA EU APAGAR SUA CHAMA!"]],
	"lider2_depois": [["Ígneo", "Minha cabeça... A sombra usava minha voz."], ["", "Ao longe, uma silhueta enorme observa. O Elo vibra, quente, como se chorasse."],
		["???", "...Então ele te escolheu. Nos vemos no fim, pequeno treinador."],
		["elo", "Três mundos purificados! O Cristal do Despertar acordou... e uma rota nova se abriu: o Pântano Sombrio."]],
	"lider3_antes": [["Brumária", "A névoa me contou um segredo: o seu Elo já teve outro dono."], ["Brumária", "Vamos ver se ele ainda te obedece... ou se só lembra dele."]],
	"lider3_depois": [["Brumária", "A névoa clareou. Desculpe, eu ouvia aquela voz o tempo todo."], ["Brumária", "Nas Ruínas de Cobre há máquinas que conversam com Elos. Talvez as respostas estejam lá."]],
	"lider4_antes": [["Bronzo", "Engrenagens não sentem nada. Por isso nunca quebram."], ["Bronzo", "A sombra me deu um propósito: desligar todos os Elos. Começando pelo seu!"]],
	"lider4_depois": [["Bronzo", "Os registros das ruínas... o primeiro Elo foi construído aqui, há muito tempo."], ["elo", "...memória recuperada: Deserto de Cristal. Origem do sinal da sombra."]],
	"lider5_antes": [["Lúmina", "Cada cristal deste deserto reflete um tempo diferente. Em todos eles, você perde."], ["Lúmina", "Mas reflexos mentem. Mostre o verdadeiro!"]],
	"lider5_depois": [["Lúmina", "Nos reflexos eu vi a sombra... Ela carrega um Elo igualzinho ao seu."],
		["???", "Seis mundos. Você chegou longe, pequeno treinador. Agora venha me encontrar."], ["", "FIM DO MID GAME. O end game chega numa próxima atualização!"]],
}

# --- Itens
const ITEMS := {
	"pocao": {"nome": "Poção", "cat": 0, "desc": "Um frasco com essência de coração. Recupera 20 de vida de um Digialma."},
	"super_pocao": {"nome": "Super Poção", "cat": 0, "desc": "Fórmula estrelada e reforçada: recupera 60 de vida."},
	"fruta": {"nome": "Fruta Doce", "cat": 0, "desc": "Brilha ao sol e é suculenta. Deixa o Digialma feliz e aumenta o vínculo."},
	"doce": {"nome": "Doce Raro", "cat": 0, "desc": "Um doce brilhante e misterioso. Sobe 1 nível na hora."},
	"orbe_alma": {"nome": "Orbe de Alma", "cat": 0, "desc": "Traz de volta um Digialma que virou alma-nuvem (caído), com metade da vida. É o ÚNICO jeito de reviver: descansar e curar não funcionam em almas. No idle: clique na nuvenzinha. Cai de Nefastos (raro) e dos Santuários."},
	"cristal_despertar": {"nome": "Cristal do Despertar", "cat": 1, "desc": "Pedra dourada que pulsa como um coração. Faz uma forma FINAL no Nv 55 DESPERTAR (+25% em tudo, aura dourada e, em muitas linhas, uma forma nova), mas só depois de purificar os 3 primeiros mundos. Vem dos Santuários do Monte Brasa em diante e, raramente, dos mapas já purificados."},
	"chip_elo": {"nome": "Chip do Elo", "cat": 1, "desc": "Recarrega 3 cargas do seu Elo para escanear Digialmas."},
	"ovo": {"nome": "Ovo Misterioso", "cat": 1, "desc": "Está quentinho... Choca conforme você dá passos."},
	"mapa": {"nome": "Mapa da Região", "cat": 2, "desc": "Mostra as rotas, santuários e áreas secretas da região."},
	"bits": {"nome": "Moeda Bit", "cat": 2, "desc": "Moeda antiga com um coração digital. Dizem que guarda memórias de outros Elos."},
}
const ITEM_TABS := ["Itens", "Elo", "Especiais"]
## Ícone (assets/ui/idle_*.png) de cada item na Mochila.
const ITEM_ICON := {"pocao": "cura", "super_pocao": "cura", "orbe_alma": "orbe", "fruta": "coracao", "doce": "nivel", "chip_elo": "laco", "cristal_despertar": "gema", "ovo": "alma", "mapa": "mapa", "bits": "bits"}

# --- Raridade (vale para Digialmas e para Amuletos)
const RARITY := [
	{"nome": "Comum", "cor": Color("d8d4e0"), "mult": 1.0, "peso": 60},
	{"nome": "Incomum", "cor": Color("6fe08a"), "mult": 1.06, "peso": 25},
	{"nome": "Raro", "cor": Color("5aa8ff"), "mult": 1.12, "peso": 10},
	{"nome": "Épico", "cor": Color("c070ff"), "mult": 1.2, "peso": 4},
	{"nome": "Lendário", "cor": Color("ffc23a"), "mult": 1.3, "peso": 1},
]

# --- Amuletos de Alma: equipados nos Digialmas. O valor cresce com a raridade.
const GEAR := {
	"presa": {"nome": "Presa", "bonus": "dano", "valor": 0.06, "desc": "+%d%% de dano"},
	"escama": {"nome": "Escama", "bonus": "defesa", "valor": 0.05, "desc": "-%d%% de dano recebido"},
	"coracao": {"nome": "Coração", "bonus": "vida", "valor": 0.08, "desc": "+%d%% de vida máxima"},
	"pena": {"nome": "Pena", "bonus": "janela", "valor": 0.08, "desc": "+%d%% na janela de esquiva/aparo"},
	"trevo": {"nome": "Trevo", "bonus": "xp", "valor": 0.1, "desc": "+%d%% de XP"},
	"moeda": {"nome": "Moeda", "bonus": "bits", "valor": 0.1, "desc": "+%d%% de bits no idle"},
	"cristal": {"nome": "Cristal", "bonus": "sinc", "valor": 0.08, "desc": "+%d%% de Sincronia"},
}
var gear: Array = []  # [{"uid", "base", "rar"}]
var gear_uid := 0
## Raros encontrados no idle que pedem para ser jogados.
var duel_queue: Array = []
var idle_prog := {}
var return_to := ""

# --- Estado do jogador
var player_char := "player"
var player_name := "Léo"
var bits := 1250
var badges := 0
var play_time := 0.0
var inventory := {"pocao": 5, "super_pocao": 2, "orbe_alma": 3, "fruta": 8, "doce": 1, "chip_elo": 3, "ovo": 1, "mapa": 1, "bits": 12}
var team: Array = []
var reserve: Array = []
var region_unlocked := 1
var region := 0
var elo_charges := 6
var debug_species := -1  # só para testes: força a espécie dos encontros
var tutorial := {"idle": false, "batalha": false, "especial": false, "escanear": false, "ataque": false, "esquiva": false, "aparo": false, "combo": false, "fusao": false}
var battle_count := 0
var seen := {}
var intro_done := false
var options := {"sons_idle": true, "alerta_som": true, "fullscreen": false, "musica": 80, "efeitos": 90, "janela_ampla": false, "dicas": true, "painel": 1.25, "jogo_compacto": true, "duelo_faixa": true}
const PANEL_SIZES := [1.0, 1.25, 1.5, 2.0]


## Está rodando dentro do painel do idle (outra janela)?
func in_panel(n: Node) -> bool:
	return n.get_window() != get_tree().root

# --- Recursos compartilhados
var font: Font
var font_title: Font
var _tex := {}
var _frames := {}
var _fade: ColorRect
var _fade_mat: ShaderMaterial
var busy := false

const SCAN_SHADER := """
shader_type canvas_item;
uniform float progress = 0.0;
uniform bool reveal = false;
uniform vec4 cover : source_color = vec4(0.07, 0.05, 0.14, 1.0);
uniform vec4 beam : source_color = vec4(0.35, 1.0, 0.6, 1.0);
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 cell = floor(UV * vec2(160.0, 90.0));
	float line = progress * 1.25 - 0.1;
	float n = hash(cell) * 0.12;
	float above = step(UV.y + n, line);
	float covered = reveal ? 1.0 - above : above;
	float d = UV.y - line;
	float glow = smoothstep(0.035, 0.0, abs(d));
	float trail = smoothstep(0.12, 0.0, -d) * step(d, 0.0) * 0.35;
	vec4 col = cover;
	col.rgb = mix(col.rgb, beam.rgb, glow + trail * (1.0 - covered));
	col.a = max(covered, max(glow, trail * 0.6));
	COLOR = col;
}
"""


# ---------------------------------------------------------------- SAVE
const VERSION := "0.6"
const TEST_BUILD := true  # mostra "TESTE: MID GAME" no título (tirar no lançamento)
const SAVE_PATH := "user://digialma_save.dat"
const SAVE_KEYS := ["all_purified", "zone", "zone_max", "zone_kills", "zone_auto", "auto_rare_bonus", "elo_up", "gear", "gear_uid", "duel_queue", "idle_prog", "player_char", "player_name", "bits", "badges", "play_time", "inventory", "team", "reserve", "region_unlocked", "region", "elo_charges", "tutorial", "battle_count", "seen", "intro_done", "options", "cristais", "elo_lv", "elo_xp", "dex_caught", "badge_lv", "badge_eq", "dex_premios"]
var last_seen := 0  # quando o jogo foi salvo pela última vez (para o progresso offline)
var _save_t := 0.0
var _testing := false


# ---------------------------------------------------------------- SONS
## Efeitos curtos e suaves (sintetizados, originais). Volume baixo e com
## intervalo mínimo por som, para o idle não ficar irritante.
var _sfx_pool: Array = []
var _sfx_last := {}


func sfx(name: String, db := 0.0, cooldown := 0.25) -> void:
	if not options.get("sons_idle", true) or _testing:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_sfx_last.get(name, -99.0)) < cooldown:
		return
	_sfx_last[name] = now
	var p: AudioStreamPlayer = null
	for q in _sfx_pool:
		if not q.playing:
			p = q
			break
	if p == null:
		if _sfx_pool.size() >= 6:
			return
		p = AudioStreamPlayer.new()
		add_child(p)
		_sfx_pool.append(p)
	p.stream = load("res://assets/sfx/%s.wav" % name)
	p.volume_db = linear_to_db(maxf(0.01, options.get("efeitos", 90) / 100.0)) - 10.0 + db
	p.play()


func save_game() -> void:
	if _testing or team.is_empty():
		return
	var d := {"versao": VERSION, "quando": int(Time.get_unix_time_from_system())}
	for k in SAVE_KEYS:
		d[k] = get(k)
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_var(d)
		f.close()


func load_game() -> bool:
	if _testing or not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var d = f.get_var()
	f.close()
	if typeof(d) != TYPE_DICTIONARY:
		return false
	for k in SAVE_KEYS:
		if d.has(k):
			var cur = get(k)
			# dicionários novos ganham as chaves que o save antigo não tinha
			if typeof(cur) == TYPE_DICTIONARY and typeof(d[k]) == TYPE_DICTIONARY:
				var merged: Dictionary = cur.duplicate()
				merged.merge(d[k], true)
				set(k, merged)
			else:
				set(k, d[k])
	last_seen = int(d.get("quando", 0))
	# saves de antes do mid game: quem já venceu o Monte Brasa ganha o Pântano
	region_unlocked = maxi(region_unlocked, mini(badges + 1, REGIONS.size()))
	for r in range(1, mini(badges + 1, REGIONS.size())):
		if int(zone_max.get(r, 0)) < 1:
			zone_max[r] = 1
	for m in team + reserve:
		dex_register(m)
	badge_autoequip()
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func quit_game() -> void:
	save_game()
	get_tree().quit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# testes: "--shot=x" na linha de comando ou num arquivo res://_shot.txt (não versionado)
	var args := OS.get_cmdline_user_args()
	if FileAccess.file_exists("res://_shot.txt"):
		args.append(FileAccess.get_file_as_string("res://_shot.txt").strip_edges())
	for a in args:
		if a.begins_with("--shot"):
			_testing = true
	_load_roster()
	_load_mid()
	_load_dex_text()
	load_game()
	font = load("res://assets/fonts/PixeloidSans.ttf")
	font_title = load("res://assets/fonts/dogicapixelbold.otf")

	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = SCAN_SHADER
	_fade_mat = ShaderMaterial.new()
	_fade_mat.shader = sh
	_fade.material = _fade_mat
	_fade_mat.set_shader_parameter("progress", 0.0)
	layer.add_child(_fade)
	_fade.visible = false
	for a in args:
		if a == "--shot=all":
			_debug_shots("all")
		elif a == "--shot=slice":
			_debug_slice()
		elif a == "--shot=evo":
			_debug_evo()
		elif a == "--shot=v6":
			_debug_v6()
		elif a == "--shot=v7":
			_debug_v7()
		elif a == "--shot=v8":
			_debug_v8()
		elif a == "--shot=v9":
			_debug_v9()
		elif a == "--shot=v10":
			_debug_v10()
		elif a == "--shot=v11":
			_debug_v11()
		elif a == "--shot=v12":
			_debug_v12()
		elif a == "--shot=v13":
			_debug_v13()
		elif a == "--shot=v14":
			_debug_v14()
		elif a == "--shot=v15":
			_debug_v15()
		elif a == "--shot=v16":
			_debug_v16()
		elif a == "--shot=v17":
			_debug_v17()
		elif a == "--shot=v17p":
			badges = 1
			_debug_v17()
		elif a == "--shot=v18":
			_debug_v18()
		elif a == "--shot=v17d":
			_debug_v17d()
		elif a == "--shot=v21":
			_debug_v21()
		elif a == "--shot=v22":
			_debug_v22()
		elif a == "--shot=v23":
			_debug_v23()
		elif a == "--shot=v24":
			_debug_v24()
		elif a == "--shot=v25":
			_debug_v25()
		elif a == "--shot=v26":
			_debug_v26()
		elif a == "--shot=v27":
			_debug_v27()
		elif a == "--shot=v28":
			_debug_v28()
		elif a == "--shot=v29":
			_debug_v29()
		elif a == "--shot=v30":
			_debug_v30()
		elif a == "--shot=v31":
			_debug_v31()
		elif a == "--shot=chk":
			_debug_chk()
		elif a == "--shot=mid":
			_debug_mid()
		elif a == "--shot=sim":
			_debug_sim()
		elif a == "--shot=v20":
			_debug_v20()
		elif a == "--shot=v19":
			_debug_v19()


## Só para testes: percorre as telas e salva prints em /tmp/shots.
func _debug_shots(which: String) -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/shots")
	var snap := func(n: String):
		await get_tree().create_timer(0.9, true).timeout
		get_viewport().get_texture().get_image().save_png("/tmp/shots/%s.png" % n)
	await get_tree().create_timer(1.6).timeout
	await snap.call("1_titulo")
	var title = get_tree().current_scene
	title._show_menu()
	await snap.call("2_menu")
	title._on_new()
	await snap.call("3_personagem")
	title._choose("young_girl")
	await snap.call("3b_personagem_menina")
	title._back_to_menu()
	title._on_options()
	await snap.call("4_opcoes")
	title._start_game()
	await get_tree().create_timer(2.0).timeout
	await snap.call("5_acampamento")
	var field = get_tree().current_scene
	field.pause_menu.open()
	await snap.call("6_pausa")
	field.pause_menu._open_sub("mochila")
	await snap.call("7_mochila")
	field.pause_menu.sub._set_tab(1)
	await snap.call("7b_mochila_elo")
	field.pause_menu.sub.request_close()
	await get_tree().create_timer(0.5, true).timeout
	field.pause_menu._open_sub("equipe")
	await snap.call("8_equipe")
	get_tree().quit()


func _process(delta: float) -> void:
	_save_t += delta
	if _save_t >= 20.0:
		_save_t = 0.0
		save_game()
	if not get_tree().paused:
		play_time += delta


# ---------------------------------------------------------------- transição "escaneamento"
func change_scene(path: String) -> void:
	if busy:
		return
	busy = true
	_fade.visible = true
	_fade_mat.set_shader_parameter("reveal", false)
	var tw := create_tween()
	tw.tween_method(func(v): _fade_mat.set_shader_parameter("progress", v), 0.0, 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	await tw.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	_fade_mat.set_shader_parameter("reveal", true)
	var tw2 := create_tween()
	tw2.tween_method(func(v): _fade_mat.set_shader_parameter("progress", v), 0.0, 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	await tw2.finished
	_fade.visible = false
	busy = false


# ---------------------------------------------------------------- texturas e animações
func tex(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load(path)
	return _tex[path]


## Animação "parado" (4 quadros 96x96) ou "ataque" de um monstro do pacote.
func monster_frames(id: int) -> SpriteFrames:
	var key := "m%d" % id
	if _frames.has(key):
		return _frames[key]
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var extra: Dictionary = EXTRA_ANIMS.get(id, {})
	for anim in ["idle", "attack", "walk"]:
		var path: String
		if extra.has(anim):
			path = extra[anim]
		elif MID_ART.has(id):
			path = "res://assets/monsters/n%d_%s.png" % [id, anim]
		elif ROSTER_ART.has(id):
			var want := "res://assets/monsters/d%d_%s.png" % [id, anim]
			path = want if ResourceLoader.exists(want) else "res://assets/monsters/d%d_idle.png" % id
		else:
			var base_anim: String = "idle" if anim == "walk" else anim
			path = (CUSTOM_SPRITES[id] % base_anim) if CUSTOM_SPRITES.has(id) else MP + "sprites/sprite%d_%s.png" % [id, base_anim]
		var t: Texture2D = tex(path)
		sf.add_animation(anim)
		sf.set_animation_speed(anim, {"idle": 6.0, "attack": 10.0, "walk": 9.0}[anim])
		sf.set_animation_loop(anim, anim != "attack")
		var n := int(t.get_width() / 96)
		for f in n:
			var at := AtlasTexture.new()
			at.atlas = t
			at.region = Rect2(f * 96, 0, 96, 96)
			sf.add_frame(anim, at)
	_frames[key] = sf
	return sf


## Personagem: animações down/left/right/up (andando) e idle_* (primeiro quadro).
func char_frames(name: String) -> SpriteFrames:
	var key := "c" + name
	if _frames.has(key):
		return _frames[key]
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var t: Texture2D = tex(GP + "characters/%s.png" % name)
	var dirs := ["down", "left", "right", "up"]
	for r in 4:
		sf.add_animation(dirs[r])
		sf.set_animation_speed(dirs[r], 7.0)
		sf.add_animation("idle_" + dirs[r])
		for f in 4:
			var at := AtlasTexture.new()
			at.atlas = t
			at.region = Rect2(f * 128, r * 128, 128, 128)
			sf.add_frame(dirs[r], at)
			if f == 0:
				sf.add_frame("idle_" + dirs[r], at)
	_frames[key] = sf
	return sf


func menu_icon(id: int) -> Texture2D:
	if MID_ART.has(id):
		return tex("res://assets/monsters/menun%d.png" % id)
	if ROSTER_ART.has(id):
		return tex("res://assets/monsters/menud%d.png" % id)
	if CUSTOM_SPRITES.has(id):
		return tex("res://assets/monsters/menusprite%d.png" % id)
	return tex(MP + "menu sprites/menusprite%d.png" % id)


# ---------------------------------------------------------------- estilo da interface
func sb(name: String, margin := 6, content := Vector4(8, 6, 8, 6)) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = tex(UI + name + ".png")
	s.texture_margin_left = margin
	s.texture_margin_right = margin
	s.texture_margin_top = margin
	s.texture_margin_bottom = margin
	s.content_margin_left = content.x
	s.content_margin_top = content.y
	s.content_margin_right = content.z
	s.content_margin_bottom = content.w
	return s


func make_theme() -> Theme:
	var th := Theme.new()
	th.default_font = font
	th.default_font_size = 9
	for t in ["Label", "Button", "LineEdit", "CheckButton"]:
		th.set_color("font_color", t, Color("fff6e8"))
		th.set_color("font_shadow_color", t, Color(0.04, 0.02, 0.1, 0.9))
		th.set_constant("shadow_offset_x", t, 1)
		th.set_constant("shadow_offset_y", t, 1)
	th.set_color("font_hover_color", "Button", Color("fff1a8"))
	th.set_color("font_focus_color", "Button", Color("fff1a8"))
	th.set_color("font_pressed_color", "Button", Color("ffffff"))
	th.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.35))
	th.set_stylebox("normal", "Button", sb("btn", 5, Vector4(10, 5, 10, 5)))
	th.set_stylebox("hover", "Button", sb("btn_hover", 5, Vector4(10, 5, 10, 5)))
	th.set_stylebox("focus", "Button", sb("btn_hover", 5, Vector4(10, 5, 10, 5)))
	th.set_stylebox("pressed", "Button", sb("btn_pressed", 5, Vector4(10, 6, 10, 4)))
	th.set_stylebox("disabled", "Button", sb("btn_disabled", 5, Vector4(10, 5, 10, 5)))
	th.set_stylebox("normal", "LineEdit", sb("slot", 5, Vector4(8, 4, 8, 4)))
	th.set_stylebox("focus", "LineEdit", sb("slot_sel", 5, Vector4(8, 4, 8, 4)))
	th.set_stylebox("panel", "PanelContainer", sb("panel", 8, Vector4(12, 10, 12, 10)))
	th.set_stylebox("background", "ProgressBar", sb("bar_bg", 3, Vector4(0, 0, 0, 0)))
	th.set_color("font_color", "ProgressBar", Color(0, 0, 0, 0))
	return th


## A fonte de título (dogica) desenha mal Ç/Ã/Õ: textos com acento usam a Pixeloid.
func title_font_for(txt: String) -> Font:
	for ch in txt:
		if ch.unicode_at(0) > 127:
			return font
	return font_title


func heading(l: Label, txt: String, size := 16) -> void:
	l.text = txt
	var f := title_font_for(txt)
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", size if f == font_title else (18 if size >= 16 else 9))


# ---------------------------------------------------------------- monstros e batalha
func new_monster(id: int, lv: int, rar := 0) -> Dictionary:
	var m := {"id": id, "lv": lv, "xp": 0, "vinculo": 30, "hp": 1, "cd": {}, "rar": rar}
	m["hp"] = max_hp(m)
	seen[id] = true
	return m


## Para qual forma este Digialma evolui: o vínculo decide o ramo.
func evo_target(m: Dictionary) -> int:
	var d: Dictionary = MONSTERS[m["id"]]
	if d.has("evo_guarda") and m.get("gua", 0) > m.get("fur", 0):
		return d["evo_guarda"]
	return d["evo"][0]


func max_hp(m: Dictionary) -> int:
	return int((20.0 + m["lv"] * 4.5) * MONSTERS[m["id"]]["hp"] * (1.1 if has_skill(m, "g3") else 1.0) * rar_mult(m) * res_mult(m) * (1.0 + gear_bonus(m, "vida")))


func stat(m: Dictionary, k: String) -> float:
	return (0.6 + m["lv"] * 0.09) * MONSTERS[m["id"]][k] * rar_mult(m) * res_mult(m)


# ---------------------------------------------------------------- FUSÕES
## RESSONÂNCIA: "queima" um Digialma da mesma família no outro: +5% de
## atributos por nível (até 5). A raridade e o nível NÃO mudam.
## ESSÊNCIA: funde uma EVOLUÇÃO de outro tipo: o alvo ganha um 2º elemento
## (golpe daquele tipo) e enxerga os pontos fracos que ele explora.
const RES_MAX := 5
const RES_COST := 1
const ESS_COST := 2
const TYPE_BASIC := {"Pedra": "pedrada", "Metal": "lamina", "Sombra": "sombra", "Luz": "raio_luz", "Veneno": "toxina", "Som": "grito", "Cristal": "estilhaco", "Normal": "arranhao", "Fogo": "brasa", "Água": "jato", "Planta": "folha", "Voador": "rajada", "Gelo": "geada", "Psíquico": "mente", "Elétrico": "choque", "Inseto": "picada", "Fumaça": "fuligem", "Ácido": "respingo", "Vácuo": "sopro_vazio", "Plasma": "ionizar", "Gravidade": "peso_subito", "Glitch": "bug", "Tempo": "tique_taque", "Espelho": "reflexo"}
var cristais := 0

# ---------------------------------------------------------------- NÍVEL DO ELO
## O Elo ganha XP purificando, vencendo, acertando anéis e capturando.
## Capturar exige Elo forte o bastante para a raridade do Digialma.
const CAPTURE_LV := {2: 2, 3: 4, 4: 6}
var elo_lv := 1
var elo_xp := 0


func elo_need() -> int:
	return 30 + elo_lv * 25


func capture_lv(m: Dictionary) -> int:
	return int(CAPTURE_LV.get(int(m.get("rar", 0)), 1))


func can_capture(m: Dictionary) -> bool:
	return elo_lv >= capture_lv(m)


## Retorna true se o Elo subiu de nível.
func gain_elo(n: int) -> bool:
	elo_xp += n
	var up := false
	while elo_xp >= elo_need():
		elo_xp -= elo_need()
		elo_lv += 1
		up = true
	return up


func res_mult(m: Dictionary) -> float:
	return 1.0 + 0.05 * int(m.get("res", 0))


func is_evolved(id: int) -> bool:
	for k in MONSTERS:
		if _succ(MONSTERS[k]).has(id):
			return true
	return false


func _line_root(id: int) -> int:
	var cur := id
	var changed := true
	while changed:
		changed = false
		for k in MONSTERS:
			if _succ(MONSTERS[k]).has(cur):
				cur = k
				changed = true
				break
	return cur


## Mesma família evolutiva conta como "igual" (Brasito + Tatubrasa ressoam).
func can_resonate(a: Dictionary, b: Dictionary) -> String:
	if a == b:
		return "Escolha outro Digialma."
	if _line_root(a["id"]) != _line_root(b["id"]):
		return "Só ressoa com a mesma espécie (ou da mesma família)."
	if int(a.get("res", 0)) >= RES_MAX:
		return "Ressonância no máximo."
	if cristais < RES_COST:
		return "Precisa de %d Cristal de Ressonância." % RES_COST
	return ""


func can_essence(a: Dictionary, b: Dictionary) -> String:
	if a == b:
		return "Escolha outro Digialma."
	if MONSTERS[b["id"]]["tipo"] == MONSTERS[a["id"]]["tipo"]:
		return "A essência precisa ser de OUTRO tipo."
	if not is_evolved(b["id"]):
		return "Só uma forma EVOLUÍDA tem essência forte o bastante."
	if cristais < ESS_COST:
		return "Precisa de %d Cristais de Ressonância." % ESS_COST
	return ""


func _consume(b: Dictionary) -> void:
	for uid in b.get("eq", []):
		pass
	b["eq"] = []
	team.erase(b)
	reserve.erase(b)


func resonate(a: Dictionary, b: Dictionary) -> void:
	cristais -= RES_COST
	a["res"] = int(a.get("res", 0)) + 1
	_consume(b)
	a["hp"] = max_hp(a)


## Resultado da essência: híbrido se os tipos combinam, senão o tipo do doador.
func essence_result(a: Dictionary, b: Dictionary) -> String:
	var h := hybrid_of(MONSTERS[a["id"]]["tipo"], MONSTERS[b["id"]]["tipo"])
	return h if h != "" else MONSTERS[b["id"]]["tipo"]


func fuse_essence(a: Dictionary, b: Dictionary) -> void:
	cristais -= ESS_COST
	a["essencia"] = essence_result(a, b)
	_consume(b)
	a["hp"] = max_hp(a)


## Tipos com que o Digialma ataca (o seu + a essência).
func attack_types(m: Dictionary) -> Array:
	var t: Array = [MONSTERS[m["id"]]["tipo"]]
	if m.has("essencia") and not t.has(m["essencia"]):
		t.append(m["essencia"])
	return t


## Ponto fraco: algum tipo do atacante é forte contra o defensor?
func weak_point(atk: Dictionary, def: Dictionary) -> String:
	for tp in attack_types(atk):
		if effectiveness(tp, MONSTERS[def["id"]]["tipo"]) > 1.0:
			return tp
	return ""


# ---------------------------------------------------------------- raridade e amuletos
## Mesma fórmula da batalha completa (usada no duelo da faixa).
func calc_damage(atk: Dictionary, def: Dictionary, mv: Dictionary, perfect: bool) -> int:
	var base: float = mv["poder"] * stat(atk, "atk") / maxf(0.5, stat(def, "def")) * (0.6 + atk["lv"] * 0.09)
	var stab := 1.2 if mv["tipo"] == MONSTERS[atk["id"]]["tipo"] else 1.0
	var eff := effectiveness(mv["tipo"], MONSTERS[def["id"]]["tipo"])
	return maxi(1, int(round(base * stab * eff * (1.5 if perfect else 1.0) * randf_range(0.88, 1.0))))


func rar_mult(m: Dictionary) -> float:
	return RARITY[int(m.get("rar", 0))]["mult"] * (AWAKEN_MULT if m.get("desperto", false) else 1.0)


# ---------------------------------------------------------------- ELENCO NOVO
## data/roster_plano.json tem as 100+ espécies planejadas. Quem já tem arte
## ("arte": true e o sprite em assets/monsters/d<id>_idle.png) entra no jogo.
var ROSTER_ART := {}
var ROSTER := []


func _load_roster() -> void:
	var f := FileAccess.open("res://data/roster_plano.json", FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	ROSTER = d.get("especies", [])
	var by_id := {}
	for e in ROSTER:
		by_id[int(e["id"])] = e
	for e in ROSTER:
		var id := int(e["id"])
		if not e.get("arte", false) or not ResourceLoader.exists("res://assets/monsters/d%d_idle.png" % id):
			continue
		ROSTER_ART[id] = true
		var st := int(e.get("estagio", 1))
		var k: float = [1.0, 1.25, 1.5][clampi(st - 1, 0, 2)] * (1.15 if e.get("lenda", false) else 1.0)
		var tipo: String = e["tipo"]
		var moves: Array = ["investida", TYPE_BASIC.get(tipo, "arranhao")]
		if st >= 2 or e.get("lenda", false):
			moves.append(TYPE_SPECIAL.get(tipo, "impacto"))
		var evo: Array = []
		for o in ROSTER:
			if o.get("evo_de") != null and int(o["evo_de"]) == id:
				evo = [int(o["id"]), int(o["evo_nv"])]
		MONSTERS[id] = {"nome": e["nome"], "tipo": tipo, "cor": TYPE_COLORS.get(tipo, Color.WHITE), "hp": k, "atk": k, "def": k,
			"evo": evo, "moves": moves, "jeito": e.get("conceito", ""), "lenda": e.get("lenda", false)}
		FOOT[id] = int(e.get("pe", 80))
		if e.get("papel", "") == "suporte":
			SUPPORT[id] = 0.08
	# evoluções só valem se a forma seguinte também tem arte
	for id in ROSTER_ART:
		var ev: Array = MONSTERS[id]["evo"]
		if ev.size() > 0 and not ROSTER_ART.has(ev[0]):
			MONSTERS[id]["evo"] = []


## ESPÉCIES DO MID GAME (data/especies_mid.json): as 10 linhas dos elementos
## novos e as formas novas das espécies antigas. Cada linha tem 5 formas:
## 1, 2, 3, D (Despertar: a forma 3 com o Cristal do Despertar) e A (Ascensão,
## guardada para o end game). Sprites: assets/monsters/n<id>_<anim>.png.
var MID_ART := {}


func _load_mid() -> void:
	var f := FileAccess.open("res://data/especies_mid.json", FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	for e in d.get("especies", []):
		var id := int(e["id"])
		var tipo: String = e["tipo"]
		var k: float = e["k"]
		var pf: Array = e["perf"]
		var forma: String = e["forma"]
		var moves: Array = ["investida", TYPE_BASIC.get(tipo, "arranhao")]
		if forma != "1":
			moves.append(TYPE_SPECIAL.get(tipo, "impacto"))
		var evo: Array = []
		if e.has("evo"):
			evo = [int(e["evo"][0]), int(e["evo"][1])]
		var md := {"nome": e["nome"], "tipo": tipo, "cor": TYPE_COLORS.get(tipo, Color.WHITE), "hp": k * float(pf[0]), "atk": k * float(pf[1]),
			"def": k * float(pf[2]), "evo": evo, "moves": moves, "jeito": e["jeito"], "forma": forma}
		if e.has("desperta"):
			md["desperta"] = int(e["desperta"])
		if e.has("ascende"):
			md["ascende"] = int(e["ascende"])
		MONSTERS[id] = md
		MID_ART[id] = true
		FOOT[id] = 88
	# as espécies antigas agora evoluem para as formas novas
	var eb: Dictionary = d.get("evo_base", {})
	for k in eb:
		MONSTERS[int(k)]["evo"] = [int(eb[k][0]), int(eb[k][1])]


## Próximas formas de uma espécie (evolução, ramo guarda, Despertar e Ascensão).
func _succ(d: Dictionary) -> Array:
	var r: Array = []
	if d["evo"].size() > 0:
		r.append(int(d["evo"][0]))
	for key in ["evo_guarda", "desperta", "ascende"]:
		if d.has(key):
			r.append(int(d[key]))
	return r


# ---------------------------------------------------------------- DESPERTAR
## A 4ª forma: só depois de purificar os 3 mundos. A forma FINAL de uma linha,
## no Nv 55, com um Cristal do Despertar, desperta: +25% em tudo, aura dourada
## e nome novo. (A 5ª forma, Ascensão, fica para o fim do jogo.)
const AWAKEN_LV := 55
const AWAKEN_MULT := 1.25


func can_awaken(m: Dictionary) -> bool:
	return all_purified and not m.get("desperto", false) and MONSTERS[m["id"]]["evo"].is_empty() \
		and int(m["lv"]) >= AWAKEN_LV and int(inventory.get("cristal_despertar", 0)) > 0


func awaken(m: Dictionary) -> void:
	inventory["cristal_despertar"] = int(inventory.get("cristal_despertar", 0)) - 1
	if inventory["cristal_despertar"] <= 0:
		inventory.erase("cristal_despertar")
	m["desperto"] = true
	# linhas com forma D desenhada: o Digialma vira a forma desperta
	if MONSTERS[m["id"]].has("desperta"):
		m["id"] = int(MONSTERS[m["id"]]["desperta"])
	m["hp"] = max_hp(m)
	m["pa"] = int(m.get("pa", 0)) + 5
	dex_register(m)


## Ordem da Digidex: linha por linha.
func dex_order() -> Array:
	# linha por linha: cada espécie antiga vem junto com as formas novas dela
	var order: Array = []
	for b in [7, 1, 12, 15, 4, 5, 6, 10, 11]:
		for x in evo_line(b):
			if MONSTERS.has(x) and not order.has(x):
				order.append(x)
	var rest: Array = []
	for k in MONSTERS:
		if not order.has(k):
			rest.append(k)
	rest.sort()
	return order + rest


# ---------------------------------------------------------------- COLEÇÃO
## Digidex como coleção: texto de cada Digialma, marcos com prêmio e o
## segredo final (Ygdralma), que aparece só para quem capturar TODOS.
const SECRET_ID := 200
const SECRET_NOME := "Ygdralma"
const DEX_MARCOS := [
	{"pct": 10, "itens": {"orbe_alma": 3}, "bits": 300, "desc": "3 Orbes de Alma + 300 bits"},
	{"pct": 25, "itens": {"super_pocao": 2}, "cristais": 2, "desc": "2 Cristais de Ressonância + 2 Super Poções"},
	{"pct": 50, "itens": {"cristal_despertar": 1}, "bits": 1500, "desc": "1 Cristal do Despertar + 1500 bits"},
	{"pct": 75, "itens": {"cristal_despertar": 2}, "cristais": 5, "desc": "2 Cristais do Despertar + 5 Cristais de Ressonância"},
	{"pct": 100, "desc": "??? (um segredo guardado pela árvore das almas)"},
]
var DEX_TEXT := {}
var dex_premios := []  # marcos (pct) já resgatados


func _load_dex_text() -> void:
	var f := FileAccess.open("res://data/dex_textos.json", FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) == TYPE_DICTIONARY:
		for k in d.get("textos", {}):
			DEX_TEXT[int(k)] = d["textos"][k]


func dex_caught_count() -> int:
	var n := 0
	for id in dex_order():
		if dex_caught.has(id):
			n += 1
	return n


func dex_pct() -> int:
	return int(floor(100.0 * dex_caught_count() / maxf(1.0, dex_order().size())))


func dex_complete() -> bool:
	return dex_caught_count() >= dex_order().size()


## Todas as formas da linha já foram capturadas?
func line_complete(id: int) -> bool:
	for x in evo_line(id):
		if not dex_caught.has(x):
			return false
	return true


## Resgata o prêmio de um marco. Devolve true se deu certo.
func claim_dex_marco(pct: int) -> bool:
	if dex_premios.has(pct) or dex_pct() < pct:
		return false
	for m in DEX_MARCOS:
		if int(m["pct"]) != pct:
			continue
		for k in m.get("itens", {}):
			inventory[k] = int(inventory.get(k, 0)) + int(m["itens"][k])
		bits += int(m.get("bits", 0))
		cristais += int(m.get("cristais", 0))
		dex_premios.append(pct)
		return true
	return false


func dex_marcos_prontos() -> int:
	var n := 0
	for m in DEX_MARCOS:
		if int(m["pct"]) < 100 and dex_pct() >= int(m["pct"]) and not dex_premios.has(int(m["pct"])):
			n += 1
	return n


func rar_color(r: int) -> Color:
	return RARITY[r]["cor"]


## Sorteia uma raridade. "bonus" empurra para cima (raros, duelos...).
func roll_rarity(bonus := 0) -> int:
	var tot := 0
	for r in RARITY:
		tot += r["peso"]
	var x := randi() % tot
	var r := 0
	for i in RARITY.size():
		x -= RARITY[i]["peso"]
		if x < 0:
			r = i
			break
	return mini(r + bonus, RARITY.size() - 1)


## Nome com a raridade, ex: "Brasito (Raro)". Comum fica só o nome.
func mon_title(m: Dictionary) -> String:
	var r := int(m.get("rar", 0))
	return mon_name(m) + (" (%s)" % RARITY[r]["nome"] if r > 0 else "")


func new_gear(base: String, rar: int) -> Dictionary:
	gear_uid += 1
	var g := {"uid": gear_uid, "base": base, "rar": rar}
	gear.append(g)
	return g


func random_gear(bonus := 0) -> Dictionary:
	var keys := GEAR.keys()
	return new_gear(keys[randi() % keys.size()], roll_rarity(bonus))


func gear_value(g: Dictionary) -> float:
	return GEAR[g["base"]]["valor"] * (1.0 + g["rar"] * 0.6)


func gear_name(g: Dictionary) -> String:
	return "%s %s" % [GEAR[g["base"]]["nome"], RARITY[g["rar"]]["nome"]]


func gear_desc(g: Dictionary) -> String:
	return GEAR[g["base"]]["desc"] % roundi(gear_value(g) * 100.0)


func gear_by_uid(uid: int) -> Dictionary:
	for g in gear:
		if g["uid"] == uid:
			return g
	return {}


func gear_slots(m: Dictionary) -> int:
	return 2 if int(m["lv"]) >= 20 else 1


## Quem está usando este amuleto (ou {}).
func gear_owner(uid: int) -> Dictionary:
	for m in team + reserve:
		if m.get("eq", []).has(uid):
			return m
	return {}


func gear_bonus(m: Dictionary, kind: String) -> float:
	var tot := 0.0
	for uid in m.get("eq", []):
		var g := gear_by_uid(uid)
		if not g.is_empty() and GEAR[g["base"]]["bonus"] == kind:
			tot += gear_value(g)
	return tot


func equip(m: Dictionary, uid: int) -> void:
	var prev := gear_owner(uid)
	if not prev.is_empty():
		prev["eq"].erase(uid)
	if not m.has("eq"):
		m["eq"] = []
	if m["eq"].size() >= gear_slots(m):
		m["eq"].remove_at(0)
	m["eq"].append(uid)


## Junta 3 amuletos iguais (mesmo tipo e raridade, sem dono) em 1 da raridade acima.
func fuse_gear() -> int:
	var made := 0
	var again := true
	while again:
		again = false
		var groups := {}
		for g in gear:
			if g["rar"] >= RARITY.size() - 1 or not gear_owner(g["uid"]).is_empty():
				continue
			var k := "%s_%d" % [g["base"], g["rar"]]
			if not groups.has(k):
				groups[k] = []
			groups[k].append(g)
		for k in groups:
			if groups[k].size() >= 3:
				var base: String = groups[k][0]["base"]
				var rar: int = groups[k][0]["rar"]
				for i in 3:
					gear.erase(groups[k][i])
				new_gear(base, rar + 1)
				made += 1
				again = true
				break
	return made


## Curva quadrática: o nível do santuário exige tempo de verdade.
func xp_need(m: Dictionary) -> int:
	return 20 + int(m["lv"]) * int(m["lv"]) * 4


## SUPORTES: Digialmas que cuidam do time. Valor = fração da vida curada.
## No idle curam sozinhos durante as lutas; nas batalhas ganham o golpe Luz Vital.
var SUPPORT := {10: 0.10, 5: 0.08, 16: 0.09, 12: 0.06, 13: 0.07, 14: 0.08}


func is_support(m: Dictionary) -> bool:
	return SUPPORT.has(int(m["id"]))


func heal_amount(healer: Dictionary, target: Dictionary) -> int:
	var k: float = SUPPORT.get(int(healer["id"]), 0.0) * (1.0 + int(healer["lv"]) * 0.01) * rar_mult(healer) * (1.0 + badge_bonus("raiz"))
	return maxi(1, int(max_hp(target) * k))


func moves_of(m: Dictionary) -> Array:
	var base: Array = MONSTERS[m["id"]]["moves"]
	if not m.has("tree"):
		return base  # inimigos usam tudo
	var tipo: String = MONSTERS[m["id"]]["tipo"]
	var res: Array = []
	var special := ""
	for mk in base:
		if MOVES[mk]["cd"] > 0:
			special = mk
		else:
			res.append(mk)
	if m["tree"].has("a1"):
		res.append(special if special != "" else TYPE_SPECIAL[tipo])
	if m.has("essencia"):
		var em: String = essence_move(m["essencia"])
		if not res.has(em):
			res.insert(mini(res.size(), 2), em)
	if m["tree"].has("f5"):
		res.append(TYPE_SUPREME[tipo])
	if is_support(m):
		res.append("luz_vital")
	return res


func move_cost(mk: String) -> int:
	if MOVES[mk].get("supremo", false):
		return ENERGY_MAX
	return ENERGY_COST if MOVES[mk]["cd"] > 0 else 0


func has_skill(m: Dictionary, node: String) -> bool:
	return m.has("tree") and m["tree"].has(node)


## Transforma um Digialma em parceiro do jogador (ganha Árvore de Alma).
func make_partner(m: Dictionary) -> Dictionary:
	if not m.has("tree"):
		m["tree"] = {}
		m["pa"] = 1 + maxi(0, (int(m["lv"]) - 5) / 2)
	m["nefasto"] = false
	m["raro"] = false
	return m


## Coloca um Digialma purificado na equipe (se houver vaga) ou na reserva.
# ---------------------------------------------------------------- DIGIDEX
## Por espécie: as raridades que você já teve. Ver = encontrou; ter = capturou.
var dex_caught := {}


func dex_register(m: Dictionary) -> void:
	var id := int(m["id"])
	seen[id] = true
	var arr: Array = dex_caught.get(id, [])
	var r := int(m.get("rar", 0))
	if not arr.has(r):
		arr.append(r)
		arr.sort()
	dex_caught[id] = arr


## Raridades em que a espécie pode aparecer. Formas finais não nascem Comuns;
## lendas só Épicas ou Lendárias.
func rar_options(id: int) -> Array:
	var d: Dictionary = MONSTERS[id]
	if d.get("lenda", false):
		return [3, 4]
	var is_final: bool = d["evo"].is_empty() and _has_pre(id)
	return [1, 2, 3, 4] if is_final else [0, 1, 2, 3, 4]


func _has_pre(id: int) -> bool:
	for k in MONSTERS:
		if _succ(MONSTERS[k]).has(id):
			return true
	return false


## Linha evolutiva completa (da forma base até as finais), em ordem.
func evo_line(id: int) -> Array:
	var root := id
	var guard := 0
	while guard < 8:
		guard += 1
		var found := -1
		for k in MONSTERS:
			if _succ(MONSTERS[k]).has(root):
				found = k
				break
		if found < 0:
			break
		root = found
	var line: Array = [root]
	var i := 0
	while i < line.size():
		for nx in _succ(MONSTERS[line[i]]):
			if not line.has(nx):
				line.append(nx)
		i += 1
	return line


func add_partner(m: Dictionary) -> String:
	make_partner(m)
	dex_register(m)
	if team.size() < team_cap():
		team.append(m)
		return "equipe"
	reserve.append(m)
	return "reserva"


func team_cap() -> int:
	return 2 + int(elo_up.get("vaga", 0))


func elo_level(k: String) -> int:
	return int(elo_up.get(k, 0))


## Sobe de nível e dá Ponto de Alma.
func level_up(m: Dictionary) -> void:
	var old_max := max_hp(m)
	m["lv"] += 1
	if int(m["hp"]) > 0:  # subir de nível não levanta quem está desmaiado
		m["hp"] = mini(m["hp"] + max_hp(m) - old_max, max_hp(m))
	if m.has("tree"):
		m["pa"] = m.get("pa", 0) + 1


func effectiveness(move_type: String, def_type: String) -> float:
	if HYBRIDS.has(move_type):
		return 1.5 if def_type in HYBRIDS[move_type]["fortes"] else 1.0
	if def_type in STRONG.get(move_type, []):
		return 1.5
	if move_type in STRONG.get(def_type, []):
		return 0.67
	return 1.0


func mon_name(m: Dictionary) -> String:
	var d: Dictionary = MONSTERS[m["id"]]
	return d["nome"] + (" Desperto" if m.get("desperto", false) and d.get("forma", "") != "D" else "")


func first_alive() -> int:
	for i in team.size():
		if team[i]["hp"] > 0:
			return i
	return -1


## Cura o time. Quem caiu (alma-nuvem) só volta com revive=true ou Orbe de Alma.
func heal_team(frac := 1.0, revive := false) -> void:
	for m in team:
		if int(m["hp"]) <= 0 and not revive:
			continue
		m["hp"] = mini(max_hp(m), maxi(0, int(m["hp"])) + int(max_hp(m) * frac))
		if m["hp"] <= 0 and frac > 0:
			m["hp"] = 1


## Usa um Orbe de Alma no primeiro Digialma caído. Retorna o índice ou -1.
func use_soul_orb() -> int:
	if int(inventory.get("orbe_alma", 0)) <= 0:
		return -1
	for i in team.size():
		if int(team[i]["hp"]) <= 0:
			inventory["orbe_alma"] = int(inventory["orbe_alma"]) - 1
			if inventory["orbe_alma"] <= 0:
				inventory.erase("orbe_alma")
			team[i]["hp"] = maxi(1, int(max_hp(team[i]) * 0.5))
			return i
	return -1


func new_game(starter: int) -> void:
	team = [make_partner(new_monster(starter, 5, 1))]
	dex_caught = {}
	dex_register(team[0])
	reserve = []
	elo_up = {}
	gear = []
	zone = {}
	zone_max = {}
	zone_kills = {}
	zone_auto = true
	cristais = 1
	elo_lv = 1
	elo_xp = 0
	duel_queue = []
	idle_prog = {}
	# presente inicial: dois amuletos simples
	equip(team[0], new_gear("presa", 0)["uid"])
	new_gear("coracao", 0)
	region_unlocked = 1
	badges = 0
	badge_lv = {}
	badge_eq = []
	dex_premios = []
	elo_charges = 6
	intro_done = true
	inventory = {"pocao": 5, "super_pocao": 1, "orbe_alma": 3, "fruta": 3, "chip_elo": 2, "ovo": 1, "mapa": 1}
	bits = 300
	play_time = 0.0


func play_time_text() -> String:
	var s := int(play_time)
	return "%02d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]


func set_fullscreen(on: bool) -> void:
	options["fullscreen"] = on
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)


## Efeito de ataque do pacote (graphics/attacks: 4 quadros de 192px).
func fx_frames(name: String) -> SpriteFrames:
	var key := "fx" + name
	if _frames.has(key):
		return _frames[key]
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("play")
	sf.set_animation_speed("play", 14.0)
	sf.set_animation_loop("play", false)
	var t: Texture2D = tex(GP + "attacks/%s.png" % name)
	for f in int(t.get_width() / 192):
		var at := AtlasTexture.new()
		at.atlas = t
		at.region = Rect2(f * 192, 0, 192, 192)
		sf.add_frame("play", at)
	_frames[key] = sf
	return sf


const SPRITE_SHADER := """
shader_type canvas_item;
uniform float flash = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform float nefasto = 0.0;
uniform float scan = 0.0;
uniform float silhouette = 0.0;
uniform float t = 0.0;
// cor do vértice (com o modulate); o COLOR do fragmento já vem multiplicado
// pela textura, então multiplicar de novo escurecia tudo
varying vec4 vcol;
void vertex() { vcol = COLOR; }
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = UV;
	vec4 c = texture(TEXTURE, uv);
	if (nefasto > 0.0) {
		float g = dot(c.rgb, vec3(0.3, 0.59, 0.11));
		vec3 tint = vec3(0.35 + g * 0.5, 0.18 + g * 0.35, 0.5 + g * 0.6);
		// pulsação lenta e suave da corrupção (sem piscar)
		float pulse = 0.65 + 0.1 * sin(t * 2.0);
		c.rgb = mix(c.rgb, tint, pulse * nefasto);
		if (c.r > 0.9 && c.g > 0.9 && c.b > 0.9) { c.rgb = mix(c.rgb, vec3(1.0, 0.25, 0.4), nefasto); }
	}
	if (scan > 0.0) {
		float cell = hash(floor(UV * vec2(400.0, 48.0)));
		float edge = scan - cell * 0.12;
		if (UV.y < edge) { c.a = 0.0; }
		else if (UV.y < scan + 0.04) { c.rgb = mix(c.rgb, vec3(0.4, 1.0, 0.6), 0.85); }
	}
	c.rgb = mix(c.rgb, vec3(1.0), silhouette);
	c.rgb = mix(c.rgb, flash_color.rgb, flash);
	COLOR = c * vcol;
}
"""


## Corrupção: tira a cor e puxa para o roxo. "raio" abre uma onda de cor a partir do centro
## (usada no momento em que a região é purificada).
const CORRUPT_SHADER := """
shader_type canvas_item;
uniform float corrupt = 1.0;
uniform float raio = 0.0;
uniform vec2 centro = vec2(0.5, 0.62);
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float g = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	vec3 roxo = vec3(g * 0.78, g * 0.66, g * 0.98) * 0.82 + vec3(0.05, 0.02, 0.08);
	float d = distance(SCREEN_UV * vec2(1.78, 1.0), centro * vec2(1.78, 1.0));
	float k = corrupt * smoothstep(raio - 0.08, raio, d);
	c.rgb = mix(c.rgb, roxo, k);
	COLOR = c;
}
"""


func region_corrupt(i: int) -> bool:
	return badges <= i


func corrupt_mat() -> ShaderMaterial:
	var sh: Shader
	if _tex.has("__corrupt_shader"):
		sh = _tex["__corrupt_shader"]
	else:
		sh = Shader.new()
		sh.code = CORRUPT_SHADER
		_tex["__corrupt_shader"] = sh
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


func sprite_mat() -> ShaderMaterial:
	var sh: Shader
	if _tex.has("__sprite_shader"):
		sh = _tex["__sprite_shader"]
	else:
		sh = Shader.new()
		sh.code = SPRITE_SHADER
		_tex["__sprite_shader"] = sh
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


func _debug_slice() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/shots")
	var snap := func(n: String, wait := 0.0):
		if wait > 0.0:
			await get_tree().create_timer(wait, true).timeout
		get_viewport().get_texture().get_image().save_png("/tmp/shots/%s.png" % n)
		print("[shot] ", n)
	await get_tree().create_timer(1.0).timeout
	await snap.call("s01_titulo")
	get_tree().change_scene_to_file("res://scenes/intro.tscn")
	await snap.call("s02_intro_queda", 1.6)
	await snap.call("s03_intro_dialogo", 1.6)
	var intro = get_tree().current_scene
	for i in 6:
		intro.dialog.typing = false
		intro.dialog._advance()
		await get_tree().create_timer(0.1).timeout
	await snap.call("s04_parceiro", 1.0)
	new_game(7)
	team[0]["lv"] = 7
	team[0]["xp"] = 85
	team.append(new_monster(12, 6))
	get_tree().change_scene_to_file("res://scenes/map.tscn")
	await snap.call("s05_mapa", 1.0)
	region = 0
	get_tree().change_scene_to_file("res://scenes/route.tscn")
	await snap.call("s06_rota_banner", 0.7)
	await snap.call("s07_rota_andando", 1.6)
	var route = get_tree().current_scene
	await get_tree().create_timer(3.4).timeout
	var battle = null
	for c in route.get_children():
		if c.get_script() == preload("res://scripts/battle.gd"):
			battle = c
	if battle == null:
		print("sem batalha"); get_tree().quit(); return
	await snap.call("s08_batalha_intro", 0.1)
	await get_tree().create_timer(3.5).timeout
	await snap.call("s09_batalha_menu")
	battle._show_moves()
	await snap.call("s10_golpes", 0.3)
	battle.choice_made.emit({"type": "move", "move": "brasa"})
	await snap.call("s11_anel", 0.45)
	battle.ring_pressed = true
	await snap.call("s12_projetil", 0.5)
	await snap.call("s13_impacto", 0.12)
	await get_tree().create_timer(4.0).timeout
	await snap.call("s14_turno")
	battle.enemies[battle.e_i]["hp"] = 2
	battle._refresh_boxes(false)
	await get_tree().create_timer(4.0).timeout
	battle.choice_made.emit({"type": "scan"})
	await get_tree().create_timer(2.6).timeout
	for i in 120:
		battle.lens_x = battle.e_spr.position.x
		if i == 60:
			await snap.call("s15_escaneando")
		await get_tree().process_frame
	await snap.call("s16_purificando", 1.0)
	await get_tree().create_timer(5.0).timeout
	var Evo = preload("res://scripts/evolution.gd")
	var ev = Evo.new()
	route.add_child(ev)
	ev.run(team[0])
	await snap.call("s17_evolucao_brilho", 3.0)
	await snap.call("s18_evolucao_pisca", 1.5)
	await snap.call("s19_evolucao_final", 2.2)
	get_tree().quit()


func _debug_evo() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/shots")
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	team[0]["lv"] = 8
	get_tree().change_scene_to_file("res://scenes/map.tscn")
	await get_tree().create_timer(0.5).timeout
	var ev = preload("res://scripts/evolution.gd").new()
	get_tree().current_scene.add_child(ev)
	ev.run(team[0])
	for k in [1.0, 2.6, 3.6, 4.6, 5.6, 6.6]:
		await get_tree().create_timer(k - (0.0 if k == 1.0 else 0.0), true).timeout
		get_viewport().get_texture().get_image().save_png("/tmp/shots/evo_%s.png" % str(k))
	get_tree().quit()


func _debug_v6() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/shots")
	var snap := func(n: String, wait := 0.0):
		if wait > 0.0:
			await get_tree().create_timer(wait, true).timeout
		get_viewport().get_texture().get_image().save_png("/tmp/shots/%s.png" % n)
		print("[shot] ", n)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	team.append(new_monster(12, 6))
	for r in [2, 1, 0]:
		region = r
		get_tree().change_scene_to_file("res://scenes/route.tscn")
		await snap.call("v_rota%d" % r, 3.0)
	var route = get_tree().current_scene
	await get_tree().create_timer(3.5).timeout
	var battle = null
	for c in route.get_children():
		if c.get_script() == preload("res://scripts/battle.gd"):
			battle = c
	if battle:
		while battle.tdialog == null:
			await get_tree().process_frame
		await snap.call("v_tutorial", 0.8)
		for i in 10:
			battle.tdialog._advance()
			await get_tree().create_timer(0.05).timeout
		await snap.call("v_tutorial_treino", 2.6)
		while battle.tdialog.visible == false:
			await get_tree().process_frame
		for i in 4:
			battle.tdialog._advance()
			await get_tree().create_timer(0.05).timeout
		await get_tree().create_timer(4.0).timeout
		battle._defense_qte(false)
		await snap.call("v_defesa", 0.6)
		await get_tree().create_timer(1.0).timeout
		battle._special_qte()
		await snap.call("v_especial", 0.4)
		await get_tree().create_timer(4.0).timeout
	var H = preload("res://scripts/route.gd").GymHall.new()
	H.piso = REGIONS[0]["piso"]
	H.size = BASE
	route.add_child(H)
	await snap.call("v_ginasio", 0.5)
	route._badge_scene(REGIONS[0]["lider"])
	await snap.call("v_insignia", 1.2)
	get_tree().quit()


func _debug_v7() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/shots")
	get_tree().create_timer(70.0, true, false, true).timeout.connect(get_tree().quit)
	var snap := func(n: String, wait := 0.0):
		if wait > 0.0:
			await get_tree().create_timer(wait, true, false, true).timeout
		get_viewport().get_texture().get_image().save_png("/tmp/shots/%s.png" % n)
		print("[shot] ", n)
	await get_tree().create_timer(0.5).timeout
	new_game(8)
	team[0]["lv"] = 10
	tutorial = {"batalha": true, "especial": true, "escanear": true, "ataque": true, "esquiva": true, "aparo": true, "combo": true, "fusao": true}
	region = 0
	get_tree().change_scene_to_file("res://scenes/route.tscn")
	await get_tree().create_timer(1.0).timeout
	var route = get_tree().current_scene
	var battle = null
	while battle == null:
		for c in route.get_children():
			if c.get_script() == preload("res://scripts/battle.gd"):
				battle = c
		await get_tree().process_frame
	while not battle.msg.text.contains("vai fazer"):
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	battle.choice_made.emit({"type": "move", "move": "investida"})
	await snap.call("w_combo_anel1", 0.6)
	battle.ring_pressed = true
	await snap.call("w_combo_golpe1", 0.25)
	await get_tree().create_timer(0.5).timeout
	await snap.call("w_combo_anel2", 0.4)
	battle.ring_pressed = true
	await get_tree().create_timer(2.5).timeout
	await snap.call("w_inimigo", 0.5)
	while not battle.msg.text.contains("vai fazer"):
		await get_tree().process_frame
	battle.enemies[battle.e_i]["hp"] = 999
	battle.enemies[battle.e_i]["cd"] = {}
	battle.choice_made.emit({"type": "move", "move": "erupcao"})
	await get_tree().create_timer(0.3).timeout
	# setas: aperta certo
	for i in 4:
		await get_tree().create_timer(0.15).timeout
		battle.qte_hit = true
		battle.qte_active = false
	await snap.call("w_erup_zoom", 0.45)
	await snap.call("w_erup_racha", 0.35)
	await snap.call("w_erup_lava", 0.25)
	await snap.call("w_erup_impacto", 0.35)
	await snap.call("w_erup_fim", 1.0)
	get_tree().quit()


func _debug_v8() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/shots")
	get_tree().create_timer(60.0, true, false, true).timeout.connect(get_tree().quit)
	var snap := func(n: String, wait := 0.0):
		if wait > 0.0:
			await get_tree().create_timer(wait, true, false, true).timeout
		get_viewport().get_texture().get_image().save_png("/tmp/shots/%s.png" % n)
		print("[shot] ", n)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	team[0]["id"] = 9
	team[0]["lv"] = 15
	team.append(new_monster(13, 12))
	tutorial = {"batalha": true, "especial": true, "escanear": true, "ataque": true, "esquiva": true, "aparo": true, "combo": true, "fusao": true}
	for r in [2, 0]:
		region = r
		get_tree().change_scene_to_file("res://scenes/route.tscn")
		await snap.call("x_rota%d" % r, 3.2)
		var route = get_tree().current_scene
		var battle = null
		while battle == null:
			for c in route.get_children():
				if c.get_script() == preload("res://scripts/battle.gd"):
					battle = c
			await get_tree().process_frame
		while not battle.msg.text.contains("vai fazer"):
			await get_tree().process_frame
		await snap.call("x_batalha%d" % r, 0.4)
	var inv = preload("res://scripts/inventory.gd").new()
	get_tree().current_scene.add_child(inv)
	await snap.call("x_mochila", 1.0)
	get_tree().quit()


func _debug_v9() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/shots")
	get_tree().create_timer(30.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/intro.tscn")
	for i in 3:
		await get_tree().create_timer(1.6).timeout
		get_viewport().get_texture().get_image().save_png("/tmp/shots/intro_%d.png" % i)
	get_tree().quit()


func _debug_v10() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/amb")
	get_tree().create_timer(40.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	team.append(new_monster(12, 6))
	tutorial = {"batalha": true, "especial": true, "escanear": true, "ataque": true, "esquiva": true, "aparo": true, "combo": true, "fusao": true}
	region = int(OS.get_environment("REG")) if OS.get_environment("REG") != "" else 0
	if OS.get_environment("SP") != "":
		debug_species = int(OS.get_environment("SP"))
	get_tree().change_scene_to_file("res://scenes/route.tscn")
	await get_tree().create_timer(float(OS.get_environment("DELAY")) if OS.get_environment("DELAY") != "" else 4.6).timeout
	for i in 90:
		await get_tree().create_timer(0.05).timeout
		get_viewport().get_texture().get_image().save_png("/tmp/amb/f%03d.png" % i)
	get_tree().quit()


func _debug_v11() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/fus")
	get_tree().create_timer(60.0, true, false, true).timeout.connect(get_tree().quit)
	var snap := func(n: String):
		get_viewport().get_texture().get_image().save_png("/tmp/fus/%s.png" % n)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	team[0]["lv"] = 7
	tutorial = {"batalha": true, "especial": true, "escanear": true, "ataque": true, "esquiva": true, "aparo": true, "combo": true, "fusao": false}
	battle_count = 5
	region = 0
	get_tree().change_scene_to_file("res://scenes/route.tscn")
	await get_tree().create_timer(1.0).timeout
	var route = get_tree().current_scene
	var battle = null
	while battle == null:
		for c in route.get_children():
			if c.get_script() == preload("res://scripts/battle.gd"):
				battle = c
		await get_tree().process_frame
	while not battle.msg.text.contains("vai fazer"):
		await get_tree().process_frame
	battle._gain(100, "gua", 6)
	await get_tree().create_timer(0.6).timeout
	battle._show_main_menu()
	await get_tree().create_timer(0.3).timeout
	snap.call("menu")
	battle.enemies[battle.e_i]["hp"] = 999
	battle.choice_made.emit({"type": "fusion"})
	await get_tree().create_timer(0.5).timeout
	if battle.tdialog:
		for i in 3:
			battle.tdialog._advance()
			await get_tree().create_timer(0.05).timeout
	for i in 75:
		await get_tree().create_timer(0.07, true, false, true).timeout
		snap.call("f%03d" % i)
	# evolução pelo ramo Guarda
	var m: Dictionary = team[0]
	m["lv"] = 8
	m["gua"] = 12
	m["fur"] = 3
	var ev = preload("res://scripts/evolution.gd").new()
	route.add_child(ev)
	ev.run(m)
	for i in 40:
		await get_tree().create_timer(0.15).timeout
		snap.call("e%03d" % i)
	get_tree().quit()


func _debug_v12() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/st")
	get_tree().create_timer(70.0, true, false, true).timeout.connect(get_tree().quit)
	var snap := func(n: String):
		get_viewport().get_texture().get_image().save_png("/tmp/st/%s.png" % n)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	team[0]["lv"] = 7
	tutorial = {"batalha": true, "especial": true, "escanear": true, "ataque": true, "esquiva": true, "aparo": true, "combo": true, "fusao": true}
	battle_count = 6
	region = 0
	debug_species = 11
	get_tree().change_scene_to_file("res://scenes/route.tscn")
	await get_tree().create_timer(1.0).timeout
	var route = get_tree().current_scene
	var battle = null
	while battle == null:
		for c in route.get_children():
			if c.get_script() == preload("res://scripts/battle.gd"):
				battle = c
		await get_tree().process_frame
	battle.intense = true
	while not battle.msg.text.contains("vai fazer"):
		await get_tree().process_frame
	battle.choice_made.emit({"type": "move", "move": "investida"})
	for i in 130:
		await get_tree().create_timer(0.05, true, false, true).timeout
		snap.call("s%03d" % i)
	# onda de purificação
	battle.queue_free()
	route._purify()
	for i in 60:
		await get_tree().create_timer(0.06, true, false, true).timeout
		snap.call("p%03d" % i)
	get_tree().quit()


func _debug_v13() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/nv")
	get_tree().create_timer(40.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.5).timeout
	new_game(12)
	region = 0
	get_tree().change_scene_to_file("res://scenes/route.tscn")
	for i in 36:
		await get_tree().create_timer(1.0).timeout
		get_viewport().get_texture().get_image().save_png("/tmp/nv/n%02d.png" % i)
		var route = get_tree().current_scene
		for c in route.get_children():
			if c.get_script() == preload("res://scripts/battle.gd"):
				if c.tdialog and c.tdialog.visible:
					c.tdialog._advance()
				if c.msg.text.contains("vai fazer"):
					c.choice_made.emit({"type": "move", "move": "investida"})
	get_tree().quit()


func _debug_v14() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/dr")
	get_tree().create_timer(40.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	team.append(new_monster(12, 6))
	region = 0
	debug_species = -2
	get_tree().change_scene_to_file("res://scenes/route.tscn")
	await get_tree().create_timer(9.0).timeout
	for i in 110:
		await get_tree().create_timer(0.06).timeout
		get_viewport().get_texture().get_image().save_png("/tmp/dr/d%03d.png" % i)
	get_tree().quit()


func _debug_v15() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/cam")
	get_tree().create_timer(60.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	team[0]["lv"] = 7
	tutorial = {"batalha": true, "especial": true, "escanear": true, "ataque": true, "esquiva": true, "aparo": true, "combo": true, "fusao": true}
	battle_count = 6
	region = 0
	debug_species = 3
	get_tree().change_scene_to_file("res://scenes/route.tscn")
	await get_tree().create_timer(1.0).timeout
	var route = get_tree().current_scene
	var battle = null
	while battle == null:
		for c in route.get_children():
			if c.get_script() == preload("res://scripts/battle.gd"):
				battle = c
		await get_tree().process_frame
	while not battle.msg.text.contains("vai fazer"):
		await get_tree().process_frame
	# só deixa o especial disponível para o inimigo
	var e: Dictionary = battle.enemies[0]
	e["hp"] = 999
	for k in ["investida", "arranhao", "folha"]:
		e["cd"][k] = 99
	battle.choice_made.emit({"type": "move", "move": "investida"})
	for i in 120:
		await get_tree().create_timer(0.06).timeout
		e["cd"]["investida"] = 99
		e["cd"]["arranhao"] = 99
		e["cd"]["folha"] = 99
		e["cd"]["floresta"] = 0
		get_viewport().get_texture().get_image().save_png("/tmp/cam/c%03d.png" % i)
	print("CAM_Z ", battle.cam_z, " POS ", battle.world.position)
	get_tree().quit()


func _debug_v16() -> void:
	get_tree().create_timer(30.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	tutorial = {"batalha": true, "especial": true, "escanear": true, "ataque": true, "esquiva": true, "aparo": true, "combo": true, "fusao": true}
	region = 0
	get_tree().change_scene_to_file("res://scenes/route.tscn")
	await get_tree().create_timer(float(OS.get_environment("WHEN"))).timeout
	var route = get_tree().current_scene
	print("antes: ", route.name)
	route.back_btn.pressed.emit()
	await get_tree().create_timer(6.0).timeout
	print("depois: ", get_tree().current_scene.name, " ", get_tree().current_scene.scene_file_path)
	get_viewport().get_texture().get_image().save_png("/tmp/leave_%s.png" % OS.get_environment("WHEN"))
	get_tree().quit()


func _debug_v17() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/idle")
	get_tree().create_timer(80.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.5).timeout
	var keep_b := badges
	new_game(7)
	badges = keep_b
	add_partner(new_monster(12, 6))
	elo_up = {"auto": 2, "faro": 2, "bolsa": 1}
	team[0]["tree"] = {"a1": true, "g1": true, "g2": true, "g4": true, "g5": true, "v1": true, "v3": true}
	region = 0
	get_tree().change_scene_to_file("res://scenes/idle.tscn")
	await get_tree().create_timer(1.0).timeout
	var idle = get_tree().current_scene
	print("WIN ", get_window().size, " ", get_window().content_scale_size)
	for i in 110:
		await get_tree().create_timer(0.5).timeout
		# clica sozinho no raro, para testar
		if idle.rare_answer == "" and idle.rare_waiting:
			idle.rare_answer = "clicou"
		get_viewport().get_texture().get_image().save_png("/tmp/idle/i%03d.png" % i)
	print("LOG ", idle.log_l.text, " P ", idle.purified, " prog ", idle.progress)
	get_tree().quit()


func _debug_v18() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/arv")
	get_tree().create_timer(30.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	team[0]["lv"] = 9
	team[0]["pa"] = 9
	add_partner(new_monster(12, 6))
	add_partner(new_monster(5, 4))
	bits = 1500
	get_tree().change_scene_to_file("res://scenes/arvores.tscn")
	await get_tree().create_timer(1.0).timeout
	var sc = get_tree().current_scene
	for k in ["a1", "f1", "f2", "f3", "g1", "v1"]:
		sc._buy_node(team[0], k)
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/arv/alma.png")
	print("MOVES ", moves_of(team[0]))
	sc.tab = "elo"
	sc._build()
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/arv/elo.png")
	sc.tab = "equipe"
	sc._build()
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/arv/equipe.png")
	get_tree().quit()


func _debug_v19() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/v19")
	get_tree().create_timer(40.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	team[0]["lv"] = 21
	add_partner(new_monster(12, 6, 3))
	for i in 14:
		random_gear(i % 3)
	for i in 3:
		new_gear("trevo", 1)
	equip(team[0], gear[3]["uid"])
	get_tree().change_scene_to_file("res://scenes/arvores.tscn")
	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/v19/itens.png")
	var sc = get_tree().current_scene
	print("FUSE ", fuse_gear(), " gear ", gear.size())
	sc.sel = 1
	sc._build()
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/v19/itens2.png")
	duel_queue.append(new_monster(5, 8, 4))
	duel_queue[0]["nefasto"] = true
	duel_queue[0]["raro"] = true
	get_tree().change_scene_to_file("res://scenes/duelo.tscn")
	await get_tree().create_timer(1.2).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/v19/duelo1.png")
	await get_tree().create_timer(4.0).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/v19/duelo2.png")
	get_tree().quit()


func _debug_v17d() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/v17d")
	get_tree().create_timer(20.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	badges = 1
	region = 0
	get_tree().change_scene_to_file("res://scenes/idle.tscn")
	await get_tree().create_timer(1.0).timeout
	var idle = get_tree().current_scene
	idle.walking = false
	idle._duel_call(new_monster(4, 8, 4))
	for i in 5:
		await get_tree().create_timer(0.7).timeout
		get_viewport().get_texture().get_image().save_png("/tmp/v17d/d%d.png" % i)
	idle.purified = 12
	idle.bits_gained = 184
	idle.items_found = 2
	idle.captured = 1
	idle.progress = 42.0
	idle._refresh()
	idle.sanct_ready = true
	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/v17d/hover.png")
	get_tree().quit()


func _debug_v20() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/v20")
	get_tree().create_timer(40.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	badges = 1
	get_tree().change_scene_to_file("res://scenes/idle.tscn")
	await get_tree().create_timer(1.5).timeout
	var idle = get_tree().current_scene
	idle._open_bag()
	await get_tree().create_timer(1.5).timeout
	print("PANEL ", idle.panel_win.size, " pos ", idle.panel_win.position, " strip ", get_window().position, " embedded ", idle.panel_win.is_embedded())
	idle.panel_win.get_texture().get_image().save_png("/tmp/v20/bag.png")
	get_viewport().get_texture().get_image().save_png("/tmp/v20/strip.png")
	duel_queue.append(new_monster(5, 8, 4))
	duel_queue[0]["nefasto"] = true
	duel_queue[0]["raro"] = true
	idle._open_duel()
	await get_tree().create_timer(6.0).timeout
	idle.panel_win.get_texture().get_image().save_png("/tmp/v20/duel.png")
	idle.panel_win.queue_free()
	await get_tree().create_timer(0.5).timeout
	print("STRIP OK ", idle.is_inside_tree(), " walking ", idle.walking)
	get_tree().quit()


func _debug_v21() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/v21")
	get_tree().create_timer(60.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	badges = 1
	team[0]["lv"] = 10
	team[0]["tree"] = {"a1": true}
	team[0]["hp"] = max_hp(team[0])
	debug_species = -9
	var en := new_monster(5, 9, 4)
	en["debug_hp"] = 0.3
	var mode := OS.get_environment("DUELO")
	if mode == "escapa":
		elo_lv = 6
		en["debug_miss"] = true
	elif mode == "trancado":
		elo_lv = 1
	else:
		elo_lv = 6
	en["nefasto"] = true
	en["raro"] = true
	duel_queue.append(en)
	get_tree().change_scene_to_file("res://scenes/idle.tscn")
	await get_tree().create_timer(1.2).timeout
	var idle = get_tree().current_scene
	idle._open_duel()
	for i in 120:
		await get_tree().create_timer(0.15).timeout
		get_viewport().get_texture().get_image().save_png("/tmp/v21/d%03d.png" % i)
		if not idle.dueling and i > 20:
			break
	print("FIM party=", team.size() + reserve.size(), " gear=", gear.size())
	get_tree().quit()


func _debug_v22() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/v22")
	get_tree().create_timer(30.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	cristais = 5
	team[0]["lv"] = 14
	team[0]["id"] = 8
	add_partner(new_monster(7, 6, 3))
	add_partner(new_monster(13, 15, 1))
	add_partner(new_monster(16, 12, 0))
	get_tree().change_scene_to_file("res://scenes/arvores.tscn")
	await get_tree().create_timer(1.0).timeout
	var sc = get_tree().current_scene
	sc.tab = "fusao"
	sc.fpick = 1
	sc._build()
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/v22/res.png")
	sc._do_fuse(team[0], _all_mons()[1])
	await get_tree().create_timer(1.2).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/v22/res2.png")
	sc.fmode = "ess"
	sc.sel = 0
	sc.fpick = _all_mons().find(_find_id(13))
	sc._build()
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/v22/ess.png")
	sc._do_fuse(team[0], _find_id(13))
	await get_tree().create_timer(1.2).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/v22/ess2.png")
	print("RES ", team[0].get("res"), " RAR ", team[0]["rar"], " ESS ", team[0].get("essencia"), " MOVES ", moves_of(team[0]), " CRIS ", cristais)
	get_tree().quit()


func _all_mons() -> Array:
	return team + reserve


func _find_id(id: int) -> Dictionary:
	for m in team + reserve:
		if m["id"] == id:
			return m
	return {}


func _debug_v23() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/v23")
	get_tree().create_timer(120.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	var rr := int(OS.get_environment("REG")) if OS.get_environment("REG") != "" else 0
	team[0]["id"] = 9
	team[0]["lv"] = 75
	team[0]["tree"] = {"a1": true}
	team[0]["hp"] = max_hp(team[0])
	debug_species = -9
	tutorial["idle"] = true
	for k in 3:
		tutorial["mapa%d" % k] = true
	badges = rr
	region = rr
	zone[rr] = ZONES
	zone_max[rr] = ZONES
	zone_kills[rr] = zone_need(ZONES)
	get_tree().change_scene_to_file("res://scenes/idle.tscn")
	await get_tree().create_timer(8.0).timeout
	var idle = get_tree().current_scene
	get_viewport().get_texture().get_image().save_png("/tmp/v23/a_chegou.png")
	idle.want_sanct = true
	for i in 200:
		await get_tree().create_timer(0.4).timeout
		get_viewport().get_texture().get_image().save_png("/tmp/v23/s%03d.png" % i)
		if badges >= rr + 1 and i > 10:
			await get_tree().create_timer(2.0).timeout
			get_viewport().get_texture().get_image().save_png("/tmp/v23/z_fim.png")
			break
	await get_tree().create_timer(3.0).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/v23/z_regiao2.png")
	print("FIM badges=", badges, " region=", region, " todos=", all_purified)
	get_tree().quit()


func _debug_v24() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/v24")
	get_tree().create_timer(60.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	team[0]["lv"] = 7
	get_tree().change_scene_to_file("res://scenes/idle.tscn")
	await get_tree().create_timer(1.5).timeout
	var idle = get_tree().current_scene
	idle._give_xp(400)
	for i in 30:
		await get_tree().create_timer(0.5).timeout
		if is_instance_valid(idle.panel_win):
			idle.panel_win.get_texture().get_image().save_png("/tmp/v24/p%02d.png" % i)
		get_viewport().get_texture().get_image().save_png("/tmp/v24/s%02d.png" % i)
	print("FIM id=", team[0]["id"], " pa=", team[0].get("pa"))
	get_tree().quit()


func _debug_v25() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/v25")
	get_tree().create_timer(30.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	tutorial["idle"] = false
	_testing = false
	team[0]["lv"] = 9
	cristais = 7
	save_game()
	team = []
	cristais = 0
	print("LOAD ", load_game(), " lv=", team[0]["lv"], " cristais=", cristais)
	last_seen -= 3 * 3600
	_testing = true
	get_tree().change_scene_to_file("res://scenes/idle.tscn")
	await get_tree().create_timer(3.0).timeout
	var idle = get_tree().current_scene
	if is_instance_valid(idle.panel_win):
		idle.panel_win.get_texture().get_image().save_png("/tmp/v25/help.png")
		idle.panel_win.queue_free()
	await get_tree().create_timer(4.0).timeout
	if is_instance_valid(idle.panel_win):
		idle.panel_win.get_texture().get_image().save_png("/tmp/v25/evo.png")
	get_viewport().get_texture().get_image().save_png("/tmp/v25/strip.png")
	print("DEPOIS lv=", team[0]["lv"], " id=", team[0]["id"], " bits=", bits, " prog=", idle.progress)
	get_tree().quit()


func _debug_v26() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/v26")
	get_tree().create_timer(100.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	tutorial["idle"] = true
	var mode := OS.get_environment("ZONA")
	if mode == "derrota":
		# Brasito Nv 8 na Costa, zona 4 (Água castiga Fogo)
		badges = 1
		region = 1
		team[0]["lv"] = 8
		zone[1] = 4
		zone_max[1] = 4
	else:
		team[0]["lv"] = 9
		zone[0] = 1
		zone_kills[0] = 12
	team[0]["hp"] = max_hp(team[0])
	get_tree().change_scene_to_file("res://scenes/idle.tscn")
	for i in 90:
		await get_tree().create_timer(1.0).timeout
		if i % 10 == 0:
			get_viewport().get_texture().get_image().save_png("/tmp/v26/%s_%02d.png" % [mode, i])
		if i % 5 == 0:
			print("t=", i, " zona=", zone.get(region, 1), " kills=", zone_kills.get(region, 0), " hp=", team[0]["hp"], "/", max_hp(team[0]), " lv=", team[0]["lv"])
	get_tree().quit()


## Simulação de balanceamento: jogador novo, tempo acelerado.
func _debug_v27() -> void:
	get_tree().create_timer(175.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.3).timeout
	new_game(7)
	tutorial["idle"] = true
	tutorial["mapa0"] = true
	get_tree().change_scene_to_file("res://scenes/idle.tscn")
	await get_tree().create_timer(1.0).timeout
	Engine.time_scale = 30.0
	var gt := 0.0
	for i in 2000:
		await get_tree().create_timer(6.0).timeout  # 6s de jogo
		gt += 6.0
		var mins := gt / 60.0
		if i % 30 == 0:
			var lvs: Array = []
			for m in team:
				lvs.append(m["lv"])
			print("SIM %5.1f min | zona %d-%d kills %d/%d | max %d | niveis %s | badges %d" % [mins, region + 1, zone_of(region), int(zone_kills.get(region, 0)), zone_need(zone_of(region)), int(zone_max.get(region, 1)), str(lvs), badges])


func _debug_v28() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/v28")
	get_tree().create_timer(40.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	tutorial["idle"] = true
	team[0] = new_monster(9, 30)
	team[0]["hp"] = max_hp(team[0])
	get_tree().change_scene_to_file("res://scenes/idle.tscn")
	for i in 60:
		await get_tree().create_timer(0.25).timeout
		get_viewport().get_texture().get_image().save_png("/tmp/v28/%02d.png" % i)


func _debug_v29() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/v29")
	get_tree().create_timer(60.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	tutorial["idle"] = true
	team[0] = make_partner(new_monster(9, 30, 2))
	add_partner(new_monster(10, 26, 1))
	elo_up["vaga"] = 1
	add_partner(new_monster(13, 24, 3))
	team[2]["hp"] = 0
	dex_register(team[0])
	seen[12] = true
	seen[6] = true
	zone[0] = 4
	zone_max[0] = 6
	get_tree().change_scene_to_file("res://scenes/idle.tscn")
	await get_tree().create_timer(3.0).timeout
	var idle = get_tree().current_scene
	get_viewport().get_texture().get_image().save_png("/tmp/v29/strip_alma.png")
	var mode := OS.get_environment("PAINEL")
	for sc in ["digidex", "mapa_idle", "arvores"]:
		if mode != "" and sc != mode:
			continue
		if sc == "arvores":
			return_to = "tab:" + OS.get_environment("ABA")
		idle._open_panel("res://scenes/%s.tscn" % sc)
		await get_tree().create_timer(1.5).timeout
		if sc == "arvores" and OS.get_environment("AJUDA") == "1":
			var a = idle.panel_win.get_child(0)
			a._fusion_help()
			await get_tree().create_timer(0.5).timeout
		idle.panel_win.get_texture().get_image().save_png("/tmp/v29/%s%s.png" % [sc, OS.get_environment("ABA")])
	await get_tree().create_timer(4.0).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/v29/strip_late.png")
	get_tree().quit()


func _debug_v30() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/v30")
	get_tree().create_timer(200.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	tutorial["idle"] = true
	team[0]["lv"] = 8
	add_partner(new_monster(10, 8, 0))
	team[1]["lv"] = 8
	inventory["orbe_alma"] = 0
	zone[0] = 6
	zone_max[0] = 6
	team[0]["hp"] = max_hp(team[0])
	team[1]["hp"] = max_hp(team[1])
	duel_queue.append(new_monster(6, 9, 3))
	get_tree().change_scene_to_file("res://scenes/idle.tscn")
	Engine.time_scale = 6.0
	var souls_seen := false
	for i in 120:
		await get_tree().create_timer(1.0 * 6.0).timeout
		var hp := []
		for m in team:
			hp.append(m["hp"])
		var idle = get_tree().current_scene
		var soul_flags := []
		if idle and "pets" in idle:
			for p in idle.pets:
				soul_flags.append(p.soul)
				if p.soul:
					souls_seen = true
		if i % 4 == 0:
			print("t=", i, " zona=", zone.get(0, 1), " hp=", hp, " almas=", soul_flags)
		if souls_seen and i % 4 == 0:
			get_viewport().get_texture().get_image().save_png("/tmp/v30/%03d.png" % i)
		if i == 30 and idle:
			idle._open_duel()
	get_tree().quit()


## Simulação de equilíbrio: em cada mapa (zonas 1, 5 e 10), um time típico
## daquele ponto (3 Digialmas Raros do próprio mapa, na forma que o nível
## permite; no mid game o líder está Desperto) enfrenta inimigos seguidos sem
## curar. Mede quantas lutas aguenta e quantos golpes leva para vencer.
func _debug_sim() -> void:
	var out := []
	for r in REGIONS.size():
		for z in [1, 5, 10]:
			var lv: int = zone_levels(r, z).x
			var cands: Array = []
			for id in ZONE_POOLS[r][2] + ZONE_POOLS[r][1]:
				var cur: int = id
				while MONSTERS[cur]["evo"].size() > 0 and int(MONSTERS[cur]["evo"][1]) <= lv:
					cur = int(MONSTERS[cur]["evo"][0])
				if not cands.has(cur):
					cands.append(cur)
			cands.sort_custom(func(a1, b1): return MONSTERS[a1]["atk"] + MONSTERS[a1]["hp"] > MONSTERS[b1]["atk"] + MONSTERS[b1]["hp"])
			var wins_tot := 0
			var hits_tot := 0
			var fights := 0
			for trial in 40:
				var tm: Array = []
				for i in mini(3, cands.size()):
					var m := new_monster(cands[i], lv, 2)
					if r >= 3 and i == 0:
						m["desperto"] = true
						if MONSTERS[m["id"]].has("desperta"):
							m["id"] = int(MONSTERS[m["id"]]["desperta"])
					m["hp"] = max_hp(m)
					tm.append(m)
				var wins := 0
				while wins < 30:
					var pool := zone_pool(r, z)
					var e := new_monster(pool[randi() % pool.size()], randi_range(zone_levels(r, z).x, zone_levels(r, z).y), roll_rarity(0))
					e["hp"] = max_hp(e)
					var turn := 0
					var alive := true
					while e["hp"] > 0:
						var li := -1
						for i in tm.size():
							if tm[i]["hp"] > 0:
								li = i
								break
						if li < 0:
							alive = false
							break
						var lm: Dictionary = tm[li]
						var mvs: Array = MONSTERS[lm["id"]]["moves"]
						var mk: String = mvs[mvs.size() - 1] if turn % 3 == 0 and mvs.size() > 2 else mvs[mini(1, mvs.size() - 1)]
						e["hp"] -= calc_damage(lm, e, MOVES[mk], randf() < 0.12)
						turn += 1
						hits_tot += 1
						if e["hp"] <= 0:
							break
						var emv: Array = MONSTERS[e["id"]]["moves"]
						lm["hp"] -= int(calc_damage(e, lm, MOVES[emv[mini(1, emv.size() - 1)]], false) * 0.55)
					if not alive:
						break
					wins += 1
				wins_tot += wins
				fights += wins
			out.append("%s z%d Nv%d time=%s | lutas seguidas=%.1f | golpes por vitória=%.1f" % [REGIONS[r]["nome"], z, lv, str(cands.slice(0, 3).map(func(x): return MONSTERS[x]["nome"])), wins_tot / 40.0, hits_tot / maxf(1.0, fights)])
	for l in out:
		print("SIM ", l)
	var f := FileAccess.open("res://_mid/sim.txt", FileAccess.WRITE)
	if f:
		f.store_string("\n".join(out))
	get_tree().quit()


## Save de teste: depois do Monte Brasa, entrando no Pântano Sombrio.
func start_test_mid() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path("user://save_antes_do_teste.json"))
	new_game(7)
	tutorial["idle"] = true
	badges = 3
	all_purified = true
	region_unlocked = 4
	region = 3
	for r in 3:
		zone[r] = 10
		zone_max[r] = 10
	zone[3] = 1
	zone_max[3] = 1
	elo_lv = 8
	bits = 6000
	cristais = 6
	team = []
	for pair in [[9, 57], [163, 55], [171, 55], [167, 55]]:
		var m := make_partner(new_monster(pair[0], pair[1], 2))
		if team.is_empty():
			m["desperto"] = true
		m["hp"] = max_hp(m)
		if team.size() < team_cap():
			team.append(m)
		else:
			reserve.append(m)
		dex_register(m)
	inventory["cristal_despertar"] = 2
	inventory["orbe_alma"] = 8
	inventory["super_pocao"] = 4
	badge_autoequip()
	save_game()


## Teste do mid game: confere dados/sprites das espécies novas e tira fotos
## do idle nos 3 mapas novos, do Mapa do Mundo e do Despertar com forma nova.
func _debug_mid() -> void:
	var dir := ProjectSettings.globalize_path("res://_mid")
	DirAccess.make_dir_recursive_absolute(dir)
	get_tree().create_timer(150.0, true, false, true).timeout.connect(get_tree().quit)
	var snap := func(n: String):
		get_viewport().get_texture().get_image().save_png(dir + "/%s.png" % n)
	var bad := 0
	for id in MID_ART:
		var d: Dictionary = MONSTERS[id]
		var sf := monster_frames(id)
		for an in ["idle", "walk", "attack"]:
			if sf.get_frame_count(an) != 6:
				print("ERRO frames ", id, " ", an, " ", sf.get_frame_count(an)); bad += 1
		if menu_icon(id) == null:
			print("ERRO menu ", id); bad += 1
		for mk in d["moves"]:
			if not MOVES.has(mk):
				print("ERRO golpe ", id, " ", mk); bad += 1
		if not TYPE_COLORS.has(d["tipo"]) or not TYPE_SUPREME.has(d["tipo"]) or (not STRONG.has(d["tipo"]) and d["tipo"] != "Normal"):
			print("ERRO tipo ", id, " ", d["tipo"]); bad += 1
		if not ResourceLoader.exists("res://assets/ui/idle_tipo_%s.png" % TYPE_SLUG.get(d["tipo"], "?")):
			print("ERRO icone tipo ", d["tipo"]); bad += 1
	for r in REGIONS.size():
		for tier in ZONE_POOLS[r]:
			for id in tier:
				if not MONSTERS.has(id):
					print("ERRO pool ", r, " ", id); bad += 1
		for pth in [REGIONS[r]["bg"], "res://assets/badges/%s.png" % REGIONS[r]["lider"]["badge"], GP + "objects/%s.png" % REGIONS[r]["arena"]]:
			if not ResourceLoader.exists(pth):
				print("ERRO arquivo ", pth); bad += 1
		for kind in ["big", "small", "front"]:
			for n in REGIONS[r]["props"][kind]:
				var pp: String = ("res://assets/props/" + n.substr(2) if n.begins_with("p:") else GP + "objects/" + n) + ".png"
				if not ResourceLoader.exists(pp):
					print("ERRO prop ", pp); bad += 1
	print("MID checagem: ", MID_ART.size(), " espécies, erros=", bad, " linha Capivolt=", evo_line(4), " linha Fuligim=", evo_line(101))
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	tutorial["idle"] = true
	badges = 3
	all_purified = true
	region_unlocked = 4
	team[0] = new_monster(103, 72, 2)
	make_partner(team[0])
	add_partner(new_monster(155, 70, 1))
	add_partner(new_monster(167, 70, 3))
	for m in team:
		m["hp"] = max_hp(m)
	badges = 6  # fotos com os mapas já purificados (cores reais)
	for r in [3, 4, 5]:
		region = r
		zone[r] = 4
		zone_max[r] = 4
		get_tree().change_scene_to_file("res://scenes/idle.tscn")
		await get_tree().create_timer(4.0).timeout
		snap.call("idle_%d" % r)
	get_tree().unload_current_scene()
	await get_tree().process_frame
	var w := get_window()
	w.content_scale_size = Vector2i(640, 360)
	w.size = Vector2i(1280, 720)
	w.transparent = false
	get_viewport().transparent_bg = false
	badges = 4  # Pântano purificado; Ruínas abertas
	region = 4
	await get_tree().create_timer(0.4).timeout
	var mp = load("res://scripts/mapa_idle.gd").new()
	get_tree().root.add_child(mp)
	await get_tree().create_timer(0.6).timeout
	snap.call("mapa")
	mp.queue_free()
	# fundo de batalha de cada mapa novo
	for r in [3, 4, 5]:
		var bgs := TextureRect.new()
		bgs.texture = tex(REGIONS[r]["bg"])
		get_tree().root.add_child(bgs)
		var amb = load("res://scripts/ambient.gd").new()
		amb.kind = load("res://scripts/ambient.gd").kind_for(REGIONS[r])
		get_tree().root.add_child(amb)
		await get_tree().create_timer(1.5).timeout
		snap.call("bg_%d" % r)
		bgs.queue_free()
		amb.queue_free()
		# insígnias: aba do menu e revanche
	badges = 4
	elo_lv = 7
	badge_eq = []
	badge_autoequip()
	print("insignias: donas=", badge_owned(), " espacos=", badge_slots(), " equipadas=", badge_eq, " bonus raiz=", badge_bonus("raiz"))
	return_to = "tab:insignias"
	var menu = load("res://scenes/arvores.tscn").instantiate() if ResourceLoader.exists("res://scenes/arvores.tscn") else null
	if menu:
		get_tree().root.add_child(menu)
		await get_tree().create_timer(0.8).timeout
		snap.call("insignias")
		menu.queue_free()
	return_to = ""
	# Digidex: coleção, prêmios, segredo e "além da evolução"
	for x in [101, 102, 103, 151, 4, 154, 155]:
		dex_register(new_monster(x, 30, 2))
	print("dex: ", dex_caught_count(), "/", dex_order().size(), " pct=", dex_pct(), " prontos=", dex_marcos_prontos(), " ordem[0..12]=", dex_order().slice(0, 12))
	var dx = load("res://scenes/digidex.tscn").instantiate()
	get_tree().root.add_child(dx)
	await get_tree().create_timer(0.5).timeout
	dx._select(103)
	await get_tree().create_timer(0.5).timeout
	snap.call("dex_linha")
	dx._select(4)
	await get_tree().create_timer(0.5).timeout
	snap.call("dex_capivolt")
	dx._select_secret()
	await get_tree().create_timer(1.0).timeout
	snap.call("dex_segredo")
	dx._show_premios()
	await get_tree().create_timer(0.5).timeout
	snap.call("dex_premios")
	dx.queue_free()
	var di = load("res://scenes/despertar_info.tscn").instantiate()
	di.overlay = true
	get_tree().root.add_child(di)
	await get_tree().create_timer(0.5).timeout
	snap.call("alem_da_evolucao")
	di.queue_free()
	# revanche na Floresta (purificada): duelo automático
	debug_species = -9
	region = 0
	zone[0] = 10
	zone_max[0] = 10
	get_tree().change_scene_to_file("res://scenes/idle.tscn")
	await get_tree().create_timer(3.0).timeout
	var idl = get_tree().current_scene
	idl.revanche = true
	idl._sanctuary_ready()
	await get_tree().create_timer(6.0).timeout
	snap.call("revanche_porta")
	idl.want_sanct = true
	for i in 40:
		await get_tree().create_timer(1.0).timeout
		if int(badge_lv.get("raiz", 1)) > 1:
			break
	await get_tree().create_timer(3.0).timeout
	snap.call("revanche_fim")
	print("revanche: raiz nivel=", badge_level("raiz"))
	debug_species = -1
	get_tree().unload_current_scene()
	await get_tree().process_frame
	# Despertar: Chaminéus Nv 72 + Cristal -> Brumath
	inventory["cristal_despertar"] = 1
	print("pode despertar=", can_awaken(team[0]))
	var ev = preload("res://scripts/evolution.gd").new()
	get_tree().root.add_child(ev)
	ev.run_awaken(team[0])
	for i in 14:
		await get_tree().create_timer(0.8).timeout
		snap.call("desp_%02d" % i)
	print("depois: id=", team[0]["id"], " nome=", mon_name(team[0]))
	print("MID FIM ", dir)
	get_tree().quit()


func _debug_chk() -> void:
	await get_tree().process_frame
	for f in DirAccess.open("res://scripts").get_files():
		if f.ends_with(".gd"):
			var sc = load("res://scripts/" + f)
			print("CHK ", f, " ", "OK" if sc != null and sc.can_instantiate() else "FALHOU")
	get_tree().quit()


func _debug_v31() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/v31")
	get_tree().create_timer(60.0, true, false, true).timeout.connect(get_tree().quit)
	await get_tree().create_timer(0.5).timeout
	new_game(7)
	tutorial["idle"] = true
	for i in 3:
		tutorial["mapa%d" % i] = true
	team[0] = make_partner(new_monster(9, 54, 3))
	team[0]["xp"] = xp_need(team[0]) - 1
	badges = 3
	all_purified = true
	region = 2
	inventory["cristal_despertar"] = 1
	get_tree().change_scene_to_file("res://scenes/idle.tscn")
	for i in 40:
		await get_tree().create_timer(0.5).timeout
		var idle = get_tree().current_scene
		if idle and "panel_win" in idle and is_instance_valid(idle.panel_win):
			idle.panel_win.get_texture().get_image().save_png("/tmp/v31/p%02d.png" % i)
		if i == 3 and idle:
			idle._give_xp(5)
	print("desperto=", team[0].get("desperto", false), " nome=", mon_name(team[0]))
	get_viewport().get_texture().get_image().save_png("/tmp/v31/strip.png")
	get_tree().quit()
