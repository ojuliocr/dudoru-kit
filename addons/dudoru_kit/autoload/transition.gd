extends CanvasLayer
## Autoload "Transition": escurece a tela entre uma tela e outra (fade), por cima de tudo.
##
## Uso:
##   await Transition.cover()     -> escurece
##   ...troca as telas...
##   await Transition.reveal()    -> clareia
##   Transition.cover_instant()   -> já começa escuro (chame no _ready da cena principal
##                                   e depois reveal() quando a primeira tela estiver pronta)
## Enquanto a tela está coberta, os cliques ficam bloqueados.
## Cor e tempo podem ser trocados por jogo, ex.: Transition.duration = 0.4

var duration := 0.6
var color := Color("12070d")

var _rect: ColorRect
var _tween: Tween
var _amount := 0.0


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	_set_amount(0.0)


func cover() -> void:
	var lol := get_node_or_null("/root/LoL")
	if lol:
		lol.stop_speaking()   # a fala não continua por cima da tela nova
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	await _run(1.0)


func reveal() -> void:
	await _run(0.0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func cover_instant() -> void:
	if _tween:
		_tween.kill()
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_amount(1.0)


func is_covered() -> bool:
	return _amount >= 1.0


func _run(to: float) -> void:
	if _tween:
		_tween.kill()
	if duration <= 0.0:
		_set_amount(to)
		return
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_set_amount, _amount, to, duration * absf(to - _amount))
	await _tween.finished


func _set_amount(v: float) -> void:
	_amount = v
	_rect.color = Color(color, color.a * v)
	_rect.visible = v > 0.0
