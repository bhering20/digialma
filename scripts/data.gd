extends RefCounted
## Dados do jogo: elementos, espécies, formas e regras de evolução.

const STAGE_NAMES := ["Bebê", "Novato", "Campeão", "Digialma"]
const STAGE_MULT := [1.0, 1.8, 3.2, 6.0]

# Nível em que cada evolução automática acontece.
const LV_ROOKIE := 5
const LV_CHAMP := 15
# Digialma (fusão com a criança) é manual: exige nível, vínculo e fragmentos.
const LV_ALMA := 30
const BOND_ALMA := 80
const FRAG_ALMA := 10
# Vínculo >= isto no momento de virar Campeão => caminho da Luz; abaixo => Sombra.
const BOND_LUZ := 50

const ELEMENTS := {
	"fogo":   {"name": "Fogo",   "main": "ff7a3d", "accent": "ffd34d", "strong": ["planta"]},
	"agua":   {"name": "Água",   "main": "4aa8ff", "accent": "bff0ff", "strong": ["fogo"]},
	"planta": {"name": "Planta", "main": "5cc95c", "accent": "c9f27a", "strong": ["agua"]},
	"raio":   {"name": "Raio",   "main": "ffd23f", "accent": "ffffff", "strong": ["agua"]},
}

const SPECIES := {
	"brasinha": {"element": "fogo", "forms": {
		"baby": "Brasinha", "rookie": "Fagulho",
		"champ_luz": "Labarex", "champ_sombra": "Cinzorn",
		"alma_luz": "Solaris", "alma_sombra": "Infernyx"}},
	"gotinha": {"element": "agua", "forms": {
		"baby": "Gotinha", "rookie": "Marolim",
		"champ_luz": "Aquarion", "champ_sombra": "Abissal",
		"alma_luz": "Tsunamon", "alma_sombra": "Leviatrix"}},
	"brotinho": {"element": "planta", "forms": {
		"baby": "Brotinho", "rookie": "Ramalho",
		"champ_luz": "Florescer", "champ_sombra": "Espinhal",
		"alma_luz": "Gaiaflor", "alma_sombra": "Raizmorta"}},
	"faisquinho": {"element": "raio", "forms": {
		"baby": "Faísquinho", "rookie": "Choquito",
		"champ_luz": "Voltaris", "champ_sombra": "Estatik",
		"alma_luz": "Trovarca", "alma_sombra": "Apagão"}},
}

# Crianças parceiras: a ordem bate com os arquivos assets/art/t_<i>.png e m_*_alma_*_<i>.png
const TAMER_NAMES := ["Léo", "Bia", "Davi", "Nina", "Theo", "Lara", "Caio", "Malu"]


static func stage_of(form: String) -> int:
	if form == "baby":
		return 0
	if form == "rookie":
		return 1
	if form.begins_with("champ"):
		return 2
	return 3


static func path_of(form: String) -> String:
	if form.ends_with("luz"):
		return "luz"
	if form.ends_with("sombra"):
		return "sombra"
	return ""


static func form_name(species: String, form: String) -> String:
	return SPECIES[species]["forms"][form]


static func element_of(species: String) -> String:
	return SPECIES[species]["element"]


static func advantage(att_el: String, def_el: String) -> float:
	if def_el in ELEMENTS[att_el]["strong"]:
		return 1.5
	if att_el in ELEMENTS[def_el]["strong"]:
		return 0.75
	return 1.0


static func xp_needed(level: int) -> int:
	return int(45.0 * pow(level, 1.7))
