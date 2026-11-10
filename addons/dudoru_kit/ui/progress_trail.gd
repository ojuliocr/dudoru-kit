class_name ProgressTrail
extends Control
## Progresso das fases numa trilha reta: bolinhas sobre uma linha que vai se enchendo.
## Feitas = verdes, a atual = anel amarelo, as que faltam = apagadas.
## A largura é a do nó (Inspector): as bolinhas se espalham nela, seja qual for o número de fases.
## Mesma interface do ProgressDots: `steps` e `set_progress(feitas)`.

@export var steps := 10:
	set(v):
		steps = maxi(v, 1)
		_done = mini(_done, steps)
		_shown = minf(_shown, float(steps))
		queue_redraw()

@export_group("Tamanhos")
@export var dot_radius := 9.0
@export var line_width := 6.0
@export var ring_width := 4.0         # anel amarelo da fase atual, colado no contorno dela
@export var padding := 24.0          # espaço entre a borda do quadro e a primeira/última bolinha
@export var show_frame := true

@export_group("Cores")
@export var frame_color := Color("e7e1d8")
@export var ink := Color("3a2230")
@export var done_color := Color("b3d25a")
@export var current_ring := Color("f2c23d")
@export var empty_color := Color("c3a996")

const FILL_TIME := 0.45   # a linha enchendo até a nova fase atual
const RING_TIME := 0.3    # o anel da fase atual crescendo
const OUTLINE := 2.5      # contorno das bolinhas

var _done := 0
var _shown := 0.0         # até qual bolinha a linha chega (animado)
var _ring := 1.0          # 0..1, o anel da atual crescendo
var _line_tween: Tween
var _ring_tween: Tween
var _frame_box: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


## done = quantas fases já foram feitas. A bolinha seguinte vira a atual.
## A feita fica verde na hora, a linha enche até a próxima e o anel amarelo só aparece
## quando a linha chega nela.
func set_progress(done: int, animate := true) -> void:
	done = clampi(done, 0, steps)
	var forward := done > _done   # voltar (jogar de novo) não anima
	_done = done
	if _line_tween:
		_line_tween.kill()
	if _ring_tween:
		_ring_tween.kill()
	if animate and forward:
		_line_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_line_tween.tween_method(_set_shown, _shown, float(done), FILL_TIME)
		_ring = 0.0
		_ring_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_ring_tween.tween_interval(FILL_TIME * 0.6)   # a curva da linha já está quase no fim aqui
		_ring_tween.tween_method(_set_ring, 0.0, 1.0, RING_TIME)
	else:
		_shown = float(done)
		_ring = 1.0
	queue_redraw()


func _set_shown(v: float) -> void:
	_shown = v
	queue_redraw()


func _set_ring(v: float) -> void:
	_ring = v
	queue_redraw()


func _x(i: int) -> float:
	if steps == 1:
		return size.x / 2.0
	return padding + (size.x - padding * 2.0) * float(i) / (steps - 1)


func _draw() -> void:
	var cy := size.y / 2.0
	if show_frame:
		draw_style_box(_frame(), Rect2(Vector2.ZERO, size))
	# trilha vazia e a parte cheia (até o centro da bolinha atual)
	draw_line(Vector2(_x(0), cy), Vector2(_x(steps - 1), cy), empty_color, line_width, true)
	var reach := clampf(_shown, 0.0, steps - 1.0)
	var i0 := int(floor(reach))
	var x_reach := lerpf(_x(i0), _x(mini(i0 + 1, steps - 1)), reach - i0)
	if reach > 0.0:
		draw_line(Vector2(_x(0), cy), Vector2(x_reach, cy), ink, line_width, true)
	# bolinhas: círculos cheios empilhados (anel, contorno, recheio), sem costura entre eles
	for i in steps:
		var c := Vector2(_x(i), cy)
		if i < _done:
			_dot(c, dot_radius, done_color, 0.0)
		elif i == _done and _ring > 0.0:
			_dot(c, dot_radius * (1.0 + 0.15 * _ring), frame_color, ring_width * maxf(_ring, 0.0))
		else:
			draw_circle(c, dot_radius, empty_color, true, -1.0, true)


## Bolinha com contorno e, se ring > 0, anel amarelo colado por fora do contorno.
func _dot(c: Vector2, r: float, fill: Color, ring: float) -> void:
	var edge := r + OUTLINE / 2.0
	if ring > 0.0:
		draw_circle(c, edge + ring, current_ring, true, -1.0, true)
	draw_circle(c, edge, ink, true, -1.0, true)
	draw_circle(c, r - OUTLINE / 2.0, fill, true, -1.0, true)


func _frame() -> StyleBoxFlat:
	if _frame_box == null:
		_frame_box = StyleBoxFlat.new()
		_frame_box.set_border_width_all(3)
		_frame_box.shadow_size = 1
		_frame_box.shadow_offset = Vector2(0, 4)
		_frame_box.anti_aliasing = true
	_frame_box.bg_color = frame_color
	_frame_box.border_color = ink
	_frame_box.shadow_color = Color(ink, 0.25)
	_frame_box.set_corner_radius_all(int(size.y / 2.0))
	return _frame_box
