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
##   LoL.speak("chave.do.texto")   -> voz da LoL; fora dela, voz do navegador

signal initialized
signal paused_changed(is_paused: bool)
## Fala começou / terminou (os botões de leitura usam pra trocar o ícone).
signal speech_started(key: String)
signal speech_finished(key: String)

## Quanto esperar a LoL responder quando o jogo está dentro de um iframe (LoL ou itch).
const START_TIMEOUT := 1.5
const OFFLINE_SAVE := "user://save.json"
## Convenção de save: todo jogo guarda "progress" (quantas etapas já fez) no Dictionary.
const PROGRESS_KEY := "progress"
## Project Settings → dudoru/force_tts_buttons: mostra os botões de leitura fora da LoL
## pra testar. Só vale em build de debug (editor); a build de release nunca força.
const FORCE_TTS_SETTING := "dudoru/force_tts_buttons"
## Voz do navegador (fora da LoL): idioma do jogo → código da voz, e velocidade (1 = normal).
const BROWSER_VOICES := {"pt": "pt-BR", "en": "en-US", "es": "es-ES"}
const BROWSER_RATE := 0.9
## Na LoL (e no editor) não dá pra saber quando a fala acaba: estima pelo tamanho do texto.
const SPEECH_CHARS_PER_SEC := 11.0
const SPEECH_MIN_TIME := 1.0

var is_initialized := false
var in_lol := false
var saved_state: Dictionary = {}
var _completed := false  # depois do complete, progresso não é mais enviado (não pode diminuir)
var _force_tts := false
var _browser_tts := false   # navegador com speechSynthesis; só usado fora da LoL

var _js_callback  # precisa ficar guardado, senão o Godot descarta o callback
var _tts_end_callback
var _speech_id := 0
var _speech_key := ""
var _got_start := false
var _got_language := false
var _got_state := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# rodando pelo editor os botões de leitura sempre aparecem, pra dar pra ver o layout
	_force_tts = OS.has_feature("editor") or \
		(OS.is_debug_build() and bool(ProjectSettings.get_setting(FORCE_TTS_SETTING, false)))
	if OS.has_feature("web"):
		_browser_tts = bool(JavaScriptBridge.eval("'speechSynthesis' in window", true))
		# algumas vozes só carregam depois do primeiro pedido
		JavaScriptBridge.eval("window.speechSynthesis && window.speechSynthesis.getVoices();", true)
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


## Os botões de leitura aparecem onde alguém lê: na LoL, no navegador com voz (itch, site)
## ou forçado pra teste.
func has_tts() -> bool:
	return in_lol or _browser_tts or _force_tts


## Lê o texto da chave no idioma atual. Na LoL, a voz é da plataforma (obrigatório lá);
## fora dela, usa a voz do navegador (Web Speech API), que varia de aparelho pra aparelho.
## Uma fala nova interrompe a anterior.
func speak(key: String) -> void:
	var text := T.t(key)
	if _speech_key != "":
		speech_finished.emit(_speech_key)
	_speech_id += 1
	_speech_key = key
	var id := _speech_id
	_duck(true)
	speech_started.emit(key)
	var estimate := maxf(SPEECH_MIN_TIME, text.length() / SPEECH_CHARS_PER_SEC)
	if in_lol:
		_send("speakText", {"key": key})
	elif _browser_tts:
		_speak_browser(text, id)
		estimate *= 3.0   # o fim de verdade vem do navegador; o timer é só uma rede de segurança
	elif _force_tts:
		print("[fala] ", text)   # no editor não há voz: mostra no Output o que seria lido
	get_tree().create_timer(estimate, true, false, true).timeout.connect(_end_speech.bind(id))


func _end_speech(id: int) -> void:
	if id != _speech_id or _speech_key == "":
		return
	var key := _speech_key
	_speech_key = ""
	_duck(false)
	speech_finished.emit(key)


## Música mais baixa enquanto a voz fala, pra não brigarem.
func _duck(on: bool) -> void:
	var am := get_node_or_null("/root/AudioManager")
	if am:
		am.duck_music(on)


func _speak_browser(text: String, id: int) -> void:
	if _tts_end_callback == null:
		_tts_end_callback = JavaScriptBridge.create_callback(_on_browser_speech_end)
		JavaScriptBridge.get_interface("window").__dudoruTtsEnd = _tts_end_callback
	var lang: String = BROWSER_VOICES.get(T.language, T.language)
	JavaScriptBridge.eval("""
		(function (text, lang, rate, id) {
			var s = window.speechSynthesis;
			if (!s) return;
			s.cancel();
			var u = new SpeechSynthesisUtterance(text);
			u.lang = lang;
			u.rate = rate;
			var all = s.getVoices();
			var voice = all.find(function (v) { return v.lang && v.lang.toLowerCase() === lang.toLowerCase(); })
				|| all.find(function (v) { return v.lang && v.lang.toLowerCase().indexOf(lang.slice(0, 2).toLowerCase()) === 0; });
			if (voice) u.voice = voice;
			u.onend = u.onerror = function () { if (window.__dudoruTtsEnd) window.__dudoruTtsEnd(id); };
			s.speak(u);
		})(%s, %s, %s, %d);
	""" % [JSON.stringify(text), JSON.stringify(lang), BROWSER_RATE, id], true)


func _on_browser_speech_end(args: Array) -> void:
	_end_speech(int(args[0]))


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
