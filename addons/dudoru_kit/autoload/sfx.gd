extends Node
## Autoload "Sfx": toca sons pelo nome. Registre depois do AudioManager.
##
##   Sfx.play("bell")       -> res://assets/audio/sfx/bell.ogg (ou .wav)
##   Sfx.play("hop", 0.0, 1.2) -> mesmo som, com tom 20% mais agudo
##   Sfx.music("theme")     -> res://assets/audio/music/theme.ogg
##
## Se o arquivo ainda não existir, não faz nada: dá pra deixar tudo ligado
## no código e ir colocando os sons na pasta aos poucos.
##
## Ajuste por jogo (ex.: no _ready do autoload Game):
##   Sfx.pitch["slice"] = 0.12
##   Sfx.volume["blip"] = -6.0

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const EXTENSIONS := ["ogg", "wav", "mp3"]

## Variação de tom por som (sons repetidos variam mais para não soarem mecânicos).
var pitch := {
	"click": 0.06,
	"blip": 0.15,
}

## Ajuste de volume por som, em dB, caso algum arquivo fique alto ou baixo demais.
var volume := {
	"blip": -6.0,
}

var _cache := {}  # nome -> AudioStream (ou null se não existe)


func play(sound: String, volume_db := 0.0, pitch_scale := 1.0) -> void:
	if sound == "":
		return
	var stream := _find(SFX_DIR, sound)
	if stream and _has_manager():
		AudioManager.play_sfx(stream, volume_db + volume.get(sound, 0.0), pitch.get(sound, 0.0), pitch_scale)


func music(track: String, fade_time := 0.8) -> void:
	var stream := _find(MUSIC_DIR, track)
	if stream and _has_manager():
		AudioManager.play_music(stream, fade_time)


func _find(dir: String, sound: String) -> AudioStream:
	var key := dir + sound
	if not _cache.has(key):
		_cache[key] = null
		for ext in EXTENSIONS:
			var path := "%s%s.%s" % [dir, sound, ext]
			if ResourceLoader.exists(path):
				_cache[key] = load(path)
				break
	return _cache[key]


func _has_manager() -> bool:
	if has_node("/root/AudioManager"):
		return true
	push_warning("Sfx: autoload AudioManager não encontrado (ative o plugin Dudoru Kit).")
	return false
