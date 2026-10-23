extends Control
## Dica do tutorial: balão pequeno com texto e botão de leitura (TTS).
## Vai pro lado do objeto que a criança precisa usar, sem cobrir esse objeto.

const MARGIN := 16.0      # distância entre a dica e o objeto
const SCREEN_PAD := 12.0  # distância mínima da borda da tela
const MOVE_TIME := 0.25

@onready var label: Label = %HintLabel
@onready var speak_button: SpeakButton = %HintSpeakButton

var _key := ""
var _base_scale := Vector2.ONE
var _move_tween: Tween


func _ready() -> void:
	_base_scale = scale
	hide()


## target: retângulo (em coordenadas globais) do que a criança deve usar.
## sides: lados preferidos, em ordem: "below", "above", "left", "right".
func show_key(key: String, target: Rect2, sides: Array) -> void:
	if key == _key and visible:
		return
	var first_show := not visible
	_key = key
	label.text = T.t(key)
	speak_button.key = key
	show()
	# Recalcula o tamanho com o texto novo antes de posicionar.
	reset_size()
	size = get_combined_minimum_size()
	pivot_offset = size / 2
	var dest := _best_position(target, sides)
	if _move_tween:
		_move_tween.kill()
	if first_show:
		global_position = dest
	else:
		_move_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_move_tween.tween_property(self, "global_position", dest, MOVE_TIME)
	scale = _base_scale * 0.85
	create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) \
		.tween_property(self, "scale", _base_scale, 0.2)


func close() -> void:
	if not visible:
		return
	_key = ""
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		hide()
		modulate.a = 1.0)


## Primeiro lado em que a dica cabe inteira na tela; se nenhum couber, usa o primeiro
## e empurra pra dentro da tela.
func _best_position(target: Rect2, sides: Array) -> Vector2:
	var screen := get_viewport_rect().grow(-SCREEN_PAD)
	var s := size * _base_scale
	for side in sides:
		var p := _side_position(target, side, s)
		if screen.encloses(Rect2(p, s)):
			return p
	var fallback := _side_position(target, sides[0], s)
	return fallback.clamp(screen.position, screen.end - s)


func _side_position(target: Rect2, side: String, s: Vector2) -> Vector2:
	var c := target.get_center()
	match side:
		"above":
			return Vector2(c.x - s.x / 2, target.position.y - MARGIN - s.y)
		"left":
			return Vector2(target.position.x - MARGIN - s.x, c.y - s.y / 2)
		"right":
			return Vector2(target.end.x + MARGIN, c.y - s.y / 2)
		_:
			return Vector2(c.x - s.x / 2, target.end.y + MARGIN)
