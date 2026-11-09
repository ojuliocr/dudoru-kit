class_name SpeakButton
extends TextureButton
## Botão de leitura em voz alta. A arte é de cada jogo: texturas normal/hover no Inspector
## e, opcional, `speaking_frames` (ex.: alto-falante sem onda, com 1 e com 2), que ficam em loop
## enquanto a fala toca, inclusive quando a fala vem do código (LoL.speak). Ao terminar, volta
## para a textura normal.
## Só aparece onde existe leitura (LoL.has_tts) e lê a chave de texto em `key`.

const HOVER_SCALE := 1.08
const PRESS_SCALE := 0.9

## Chave do texto que será lido (a mesma usada em T.t). Pode trocar a qualquer momento.
@export var key := "":
	set(v):
		key = v
		_update_visibility()
## Quadros da animação enquanto fala, em loop. Vazio = não anima.
@export var speaking_frames: Array[Texture2D] = []
## Tempo de cada quadro.
@export var frame_time := 0.22

var _tween: Tween
var _idle_normal: Texture2D
var _idle_hover: Texture2D
var _speaking := false
var _frame := 0
var _frame_clock := 0.0


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	pivot_offset = size / 2.0
	_idle_normal = texture_normal
	_idle_hover = texture_hover
	pressed.connect(_on_pressed)
	mouse_entered.connect(_scale_to.bind(HOVER_SCALE))
	mouse_exited.connect(_scale_to.bind(1.0))
	resized.connect(_on_resized)
	LoL.speech_started.connect(_on_speech_started)
	LoL.speech_finished.connect(_on_speech_finished)
	set_process(false)
	hide()
	if not LoL.is_initialized:
		await LoL.initialized
	_update_visibility()


func _update_visibility() -> void:
	if not is_node_ready():
		return
	visible = LoL.is_initialized and LoL.has_tts() and key != ""


func _on_resized() -> void:
	pivot_offset = size / 2.0


func _on_pressed() -> void:
	Sfx.play("click")
	LoL.speak(key)
	_scale_to(PRESS_SCALE, 0.06)
	_tween.tween_property(self, "scale", Vector2.ONE * (HOVER_SCALE if is_hovered() else 1.0), 0.12)


func _on_speech_started(k: String) -> void:
	if k == key:
		_set_speaking(true)


## Só existe uma fala por vez: qualquer fim de fala desliga o ícone se ele estava ligado.
func _on_speech_finished(_k: String) -> void:
	if _speaking:
		_set_speaking(false)


func _set_speaking(on: bool) -> void:
	_speaking = on
	if speaking_frames.is_empty():
		return
	set_process(on)
	if on:
		_frame = 0
		_frame_clock = 0.0
		_show_frame(speaking_frames[0])
	else:
		texture_normal = _idle_normal
		if _idle_hover:
			texture_hover = _idle_hover


func _process(delta: float) -> void:
	_frame_clock += delta
	if _frame_clock < frame_time:
		return
	_frame_clock -= frame_time
	_frame = (_frame + 1) % speaking_frames.size()
	_show_frame(speaking_frames[_frame])


func _show_frame(tex: Texture2D) -> void:
	texture_normal = tex
	if _idle_hover:
		texture_hover = tex


func _scale_to(target: float, time := 0.12) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE * target, time)
