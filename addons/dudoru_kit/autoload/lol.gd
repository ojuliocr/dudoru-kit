extends Node
## Autoload "LoL": integração com a Legends of Learning (registre depois de T).
##
## Na LoL o jogo roda dentro de um iframe e conversa com a página por postMessage.
## Fora da LoL (editor, itch) ninguém responde: depois de START_TIMEOUT segundos o
## jogo segue sozinho, com os textos locais e o save em user://.
##
## Uso:
##   await LoL.initialized    -> idioma e save carregados
##   LoL.saved_state          -> Dictionary do save ou {} se não houver
##   LoL.has_saved_game()     -> true se existe partida em andamento
##   LoL.submit_progress(atual, maximo)
##   LoL.save_state({...})
##   LoL.complete()
##   LoL.speak("chave.do.texto")

signal initialized
signal paused_changed(is_paused: bool)

## Quanto esperar a LoL responder quando o jogo está dentro de um iframe (LoL ou itch).
const START_TIMEOUT := 1.5
const OFFLINE_SAVE := "user://save.json"
## Convenção de save: todo jogo guarda "progress" (quantas etapas já fez) no Dictionary.
const PROGRESS_KEY := "progress"
## Project Settings → dudoru/force_tts_buttons: mostra os botões de leitura fora da LoL
## pra testar. Só vale em build de debug (editor); a build de release nunca força.
const FORCE_TTS_SETTING := "dudoru/force_tts_buttons"

var is_initialized := false
var in_lol := false
var saved_state: Dictionary = {}
var _completed := false  # depois do complete, progresso não é mais enviado (não pode diminuir)
var _force_tts := false

var _js_callback  # precisa ficar guardado, senão o Godot descarta o callback
var _got_start := false
var _got_language := false
var _got_state := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_force_tts = OS.is_debug_build() and bool(ProjectSettings.get_setting(FORCE_TTS_SETTING, false))
	# Fora do navegador (editor) ou fora de um iframe não existe LoL: segue na hora.
	if not OS.has_feature("web") or not _in_iframe():
		_on_start_timeout.call_deferred()
		return
	_listen()
	_send("gameIsReady", {"aspectRatio": "16:9", "resolution": "1280x720"})
	get_tree().create_timer(START_TIMEOUT, true, false, true).timeout.connect(_on_start_timeout)


## Progresso absoluto (nunca pode diminuir). A LoL exige pelo menos 8 envios por partida.
func submit_progress(current: int, maximum: int, score: int = -1) -> void:
	if _completed:
		return
	var payload := {"currentProgress": current, "maximumProgress": maximum}
	if score >= 0:
		payload["score"] = score
	_send("progress", payload)


func complete() -> void:
	_completed = true
	_send("complete", {})


func save_state(data: Dictionary) -> void:
	saved_state = data
	if in_lol:
		_send("saveState", {"data": data})
	else:
		var f := FileAccess.open(OFFLINE_SAVE, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(data))


func clear_state() -> void:
	save_state({})


func has_saved_game() -> bool:
	return int(saved_state.get(PROGRESS_KEY, 0)) > 0


## Os botões de leitura só fazem sentido onde alguém lê: na LoL (ou forçado pra teste).
func has_tts() -> bool:
	return in_lol or _force_tts


## Texto pra fala: a LoL lê o texto da chave no idioma atual.
func speak(key: String) -> void:
	_send("speakText", {"key": key})


# --- JavaScript ---------------------------------------------------------------

func _in_iframe() -> bool:
	return bool(JavaScriptBridge.eval("window.self !== window.top", true))


func _listen() -> void:
	_js_callback = JavaScriptBridge.create_callback(_on_js_message)
	var window = JavaScriptBridge.get_interface("window")
	window.__lolToGodot = _js_callback
	# Repassa pro Godot só as mensagens da LoL, já como texto JSON.
	JavaScriptBridge.eval("""
		window.addEventListener('message', function (e) {
			var d = e.data || {};
			if (!d.messageName || !window.__lolToGodot) return;
			window.__lolToGodot(JSON.stringify({ name: d.messageName, payload: d.payload }));
		});
	""", true)


func _send(message: String, payload: Dictionary) -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("parent.postMessage({ message: %s, payload: %s }, '*');" % [
		JSON.stringify(message), JSON.stringify(JSON.stringify(payload))], true)


func _on_js_message(args: Array) -> void:
	var msg = JSON.parse_string(str(args[0]))
	if not msg is Dictionary:
		return
	var payload = msg.get("payload")
	if payload is String:
		var parsed = JSON.parse_string(payload)
		if parsed != null:
			payload = parsed
	match str(msg.get("name", "")):
		"start":
			in_lol = true
			_got_start = true
			if payload is Dictionary and payload.has("languageCode"):
				T.set_language(str(payload.languageCode))
			_send("loadState", {})
		"language":
			in_lol = true
			_apply_language(payload)
		"loadState":
			_apply_state(payload)
		"pause":
			_set_paused(true)
		"resume":
			_set_paused(false)
	_check_ready()


func _apply_language(payload) -> void:
	if not payload is Dictionary:
		return
	# Aceita {"en": {...}} ou o dicionário do idioma direto.
	var texts: Dictionary = payload.get(T.language, payload)
	T.load_dict(texts)
	_got_language = true


func _apply_state(payload) -> void:
	_got_state = true
	if payload is Dictionary:
		var data = payload.get("data", payload)
		if data is String:
			data = JSON.parse_string(data)
		if data is Dictionary:
			saved_state = data


func _set_paused(on: bool) -> void:
	get_tree().paused = on
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), on)
	paused_changed.emit(on)


func _check_ready() -> void:
	if is_initialized or not (_got_start and _got_language and _got_state):
		return
	_finish_ready()


func _on_start_timeout() -> void:
	if is_initialized:
		return
	if in_lol:
		# A LoL respondeu mas faltou algo (ex.: loadState): segue com o que tem.
		_finish_ready()
		return
	# Fora da LoL: save local.
	if FileAccess.file_exists(OFFLINE_SAVE):
		var data = JSON.parse_string(FileAccess.get_file_as_string(OFFLINE_SAVE))
		if data is Dictionary:
			saved_state = data
	_finish_ready()


func _finish_ready() -> void:
	is_initialized = true
	initialized.emit()
