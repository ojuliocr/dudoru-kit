class_name SpeakButton
extends TextureButton
## Botão de leitura em voz alta (TTS da LoL). A arte é de cada jogo: coloque as
## texturas normal/hover/pressed no Inspector. O comportamento é sempre o mesmo:
## só aparece onde existe leitura (LoL.has_tts) e lê a chave de texto em `key`.

const HOVER_SCALE := 1.08
const PRESS_SCALE := 0.9

## Chave do texto que será lido (a mesma usada em T.t). Pode trocar a qualquer momento.
@export var key := "":
	set(v):
		key = v
		_update_visibility()

var _tween: Tween


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	pivot_offset = size / 2.0
	pressed.connect(_on_pressed)
	mouse_entered.connect(_scale_to.bind(HOVER_SCALE))
	mouse_exited.connect(_scale_to.bind(1.0))
	hide()
	if not LoL.is_initialized:
		await LoL.initialized
	_update_visibility()


func _update_visibility() -> void:
	if not is_node_ready():
		return
	visible = LoL.is_initialized and LoL.has_tts() and key != ""


func _on_pressed() -> void:
	Sfx.play("click")
	LoL.speak(key)
	_scale_to(PRESS_SCALE, 0.06)
	_tween.tween_property(self, "scale", Vector2.ONE * (HOVER_SCALE if is_hovered() else 1.0), 0.12)


func _scale_to(target: float, time := 0.12) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE * target, time)
