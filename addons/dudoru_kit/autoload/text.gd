extends Node
## Textos do jogo, lidos de data/texts/<idioma>.json.
## Uso: T.t("order.want", {"pizza": "Marguerita"})
## A Legends of Learning exige os textos em JSON separado (en.json é o oficial).

const TEXTS_DIR := "res://data/texts/"
const FALLBACK := "en"

var language := FALLBACK
var _texts: Dictionary = {}
var _fallback: Dictionary = {}


func _ready() -> void:
	_fallback = _load(FALLBACK)
	var os_lang := OS.get_locale_language()
	set_language(os_lang if FileAccess.file_exists(TEXTS_DIR + os_lang + ".json") else FALLBACK)


func set_language(lang: String) -> void:
	language = lang
	_texts = _load(lang)


## Usado pela LoL: troca todos os textos pelos que a plataforma mandou.
func load_dict(texts: Dictionary) -> void:
	_texts = texts


func t(key: String, params: Dictionary = {}) -> String:
	var text: String = _texts.get(key, _fallback.get(key, key))
	return text.format(params) if not params.is_empty() else text


func _load(lang: String) -> Dictionary:
	var path := TEXTS_DIR + lang + ".json"
	if not FileAccess.file_exists(path):
		push_warning("Arquivo de texto não encontrado: " + path)
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary:
		return data
	push_error("JSON inválido: " + path)
	return {}
