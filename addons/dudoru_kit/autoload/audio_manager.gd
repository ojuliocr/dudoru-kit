extends Node

## AudioManager do estúdio.
##
## Uso:
##   AudioManager.play_sfx(preload("res://assets/audio/click.ogg"))
##   AudioManager.play_music(preload("res://assets/audio/tema.ogg"))
##   AudioManager.stop_music()
##
## Os buses "Music" e "SFX" são usados se existirem no projeto
## (Audio → Buses). Se não existirem, o áudio vai para o bus "Master".

const SFX_POOL_SIZE := 8
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _music_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = _bus_or_master(MUSIC_BUS)
	add_child(_music_player)

	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = _bus_or_master(SFX_BUS)
		add_child(player)
		_sfx_players.append(player)


## Toca um efeito sonoro usando o primeiro player livre do pool.
## pitch_variation adiciona uma variação aleatória de tom (ex: 0.1 = ±10%).
## pitch_scale é o tom base (1.0 = original, 1.2 = mais agudo).
func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_variation: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null:
		push_warning("AudioManager.play_sfx: stream nulo.")
		return

	var player := _get_free_sfx_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale + randf_range(-pitch_variation, pitch_variation)
	player.play()


## Toca uma música em loop. Se outra música estiver tocando, faz fade entre elas.
func play_music(stream: AudioStream, fade_time: float = 0.5, volume_db: float = 0.0) -> void:
	if stream == null:
		push_warning("AudioManager.play_music: stream nulo.")
		return
	if _music_player.stream == stream and _music_player.playing:
		return

	_kill_music_tween()

	if _music_player.playing and fade_time > 0.0:
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", -40.0, fade_time * 0.5)
		_music_tween.tween_callback(_start_music.bind(stream, -40.0))
		_music_tween.tween_property(_music_player, "volume_db", volume_db, fade_time * 0.5)
	else:
		_start_music(stream, volume_db)


## Para a música com fade opcional.
func stop_music(fade_time: float = 0.5) -> void:
	_kill_music_tween()
	if not _music_player.playing:
		return
	if fade_time <= 0.0:
		_music_player.stop()
		return

	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", -40.0, fade_time)
	_music_tween.tween_callback(_music_player.stop)


func is_music_playing() -> bool:
	return _music_player.playing


func _start_music(stream: AudioStream, volume_db: float) -> void:
	_music_player.stream = stream
	_music_player.volume_db = volume_db
	if not _music_player.finished.is_connected(_on_music_finished):
		_music_player.finished.connect(_on_music_finished)
	_music_player.play()


func _on_music_finished() -> void:
	# Garante o loop mesmo se o arquivo não estiver marcado como loop no import.
	_music_player.play()


func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	# Todos ocupados: reaproveita o primeiro (o som mais antigo é cortado).
	return _sfx_players[0]


func _kill_music_tween() -> void:
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()


func _bus_or_master(bus_name: String) -> StringName:
	return StringName(bus_name) if AudioServer.get_bus_index(bus_name) != -1 else &"Master"
