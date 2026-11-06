class_name ProgressTrail
extends Control
## Progresso das fases numa trilha reta: bolinhas sobre uma linha que vai se enchendo.
## Feitas = verdes, a atual = anel amarelo, as que faltam = apagadas.
## A largura é a do nó (Inspector): as bolinhas se espalham nela, seja qual for o número de fases.
## Mesma interface do ProgressDots: `steps` e `set_progress(feitas)`.

@export var steps := 10:
	set(v):
		steps = maxi(v, 1)
		queue_redraw()

@export_group("Tamanhos")
@export var dot_radius := 9.0
@export var line_width := 6.0
@export var padding := 24.0          # espaço entre a borda do quadro e a primeira/última bolinha
@export var show_frame := true

@export_group("Cores")
@export var frame_color := Color("fdf3df")
@export var ink := Color("3a2230")
@export var done_color := Color("b3d25a")
@export var current_ring := Color("f2c23d")
@export var empty_color := Color("e6d4b0")

const FILL_TIME := 0.45

var _done := 0
var _shown := 0.0         # quanto da linha está cheio (em bolinhas); animado
var _pop: Array[float] = []
var _tween: Tween
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


## done = quantas fases já foram feitas. A bolinha seguinte vira a atual.
func set_progress(done: int, animate := true) -> void:
	done = clampi(done, 0, steps)
	if _tween:
		_tween.kill()
	if animate and done > _done:
		_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_tween.tween_method(_set_shown, _shown, float(done), FILL_TIME)
	else:
		_set_shown(float(done))
	_done = done


func _set_shown(v: float) -> void:
	# a bolinha que a linha acabou de alcançar dá um pop
	var before := int(floor(_shown))
	_shown = v
	var now := int(floor(v))
	if _pop.size() != steps:
		_pop.resize(steps)
		_pop.fill(1.0)
	for i in range(before, mini(now, steps)):
		var k := i
		var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_method(func(s: float) -> void: _pop[k] = s; queue_redraw(), 0.6, 1.0, 0.3)
	queue_redraw()


func _process(delta: float) -> void:
	if _done < steps and is_visible_in_tree():
		_t += delta
		queue_redraw()


func _x(i: int) -> float:
	if steps == 1:
		return size.x / 2.0
	return padding + (size.x - padding * 2.0) * float(i) / (steps - 1)


func _draw() -> void:
	var cy := size.y / 2.0
	if show_frame:
		var sb := StyleBoxFlat.new()
		sb.bg_color = frame_color
		sb.border_color = ink
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(int(size.y / 2.0))
		sb.shadow_color = Color(ink, 0.25)
		sb.shadow_offset = Vector2(0, 4)
		sb.anti_aliasing = true
		draw_style_box(sb, Rect2(Vector2.ZERO, size))
	# trilha vazia e a parte cheia
	draw_line(Vector2(_x(0), cy), Vector2(_x(steps - 1), cy), empty_color, line_width, true)
	var reach := clampf(_shown, 0.0, steps - 1.0)
	var x_reach := lerpf(_x(int(floor(reach))), _x(mini(int(floor(reach)) + 1, steps - 1)), reach - floor(reach))
	if _shown > 0.0:
		draw_line(Vector2(_x(0), cy), Vector2(x_reach, cy), ink, line_width, true)
	# bolinhas
	for i in steps:
		var c := Vector2(_x(i), cy)
		var s: float = _pop[i] if i < _pop.size() else 1.0
		if i < _done:
			draw_circle(c, dot_radius * s, done_color)
			draw_arc(c, dot_radius * s, 0, TAU, 24, ink, 2.5, true)
		elif i == _done:
			var r := dot_radius * 1.15 * (1.0 + sin(_t * 4.0) * 0.06)
			draw_arc(c, r + 4.0, 0, TAU, 28, current_ring, 4.0, true)
			draw_circle(c, r, frame_color)
			draw_arc(c, r, 0, TAU, 24, ink, 2.5, true)
		else:
			draw_circle(c, dot_radius, empty_color)
