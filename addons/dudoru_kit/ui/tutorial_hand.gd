class_name TutorialHand
extends Control
## Mãozinha do tutorial. Dois gestos em loop:
## play_drag(): aperta, leva num arco e solta (arrastar um item).
## play_tap(): desce e toca um botão, mostrando os risquinhos de clique.
## Sem textura desenha um placeholder. As texturas padrão ficam no kit; troque
## `texture` e `tap_texture` no Inspector para usar outra arte (mesmo tamanho nas duas).

@export var texture: Texture2D = preload("res://addons/dudoru_kit/assets/tutorial_hand.png")
## Versão com os risquinhos de clique (usada no toque).
@export var tap_texture: Texture2D = preload("res://addons/dudoru_kit/assets/tutorial_hand_tap.png")
## Tamanho da textura na tela, em px (as duas texturas têm o mesmo tamanho).
@export var hand_size := 128.0
## Duração de um ciclo completo do gesto, em segundos.
@export var cycle := 2.0
## Altura do arco do arrasto, em px.
@export var arc := 60.0
## No toque: quanto a mão fica afastada do botão antes de tocar, em px.
@export var tap_lift := 26.0
## No toque: giro da mão em graus (em volta da ponta do dedo). Com 135 o pulso fica
## pra esquerda, então a mão não sai pela borda quando o botão está no canto da tela.
@export var tap_rotation := 135.0

## Ponta do dedo em pixels da textura. As duas texturas (normal e de clique) têm
## o mesmo tamanho e a mão no mesmo lugar, então a ponta é a mesma.
const TIP_PX := Vector2(53.8, 33.3)
const TEX_WIDTH := 186.0
## Direção da ponta do dedo para o pulso, na textura (usada pra afastar a mão no toque).
const WRIST_DIR := Vector2(0.455, 0.89)
const INK := Color("3a2230")
const SKIN := Color("fffaf2")

enum Mode { DRAG, TAP }

var _mode := Mode.DRAG
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _t := 0.0
var _tapping := false  # true enquanto mostra a textura de clique


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()
	set_process(false)


func _ready() -> void:
	_apply_texture(false)


## Coordenadas globais: de onde pega e onde solta.
func play_drag(from_global: Vector2, to_global: Vector2) -> void:
	_mode = Mode.DRAG
	rotation = 0.0
	_from = from_global
	_to = to_global
	_start()


## Coordenadas globais: onde o dedo toca (centro do botão).
func play_tap(target_global: Vector2) -> void:
	_mode = Mode.TAP
	rotation_degrees = tap_rotation
	_to = target_global
	_start()


func stop() -> void:
	hide()
	set_process(false)


func _start() -> void:
	_t = 0.0
	_apply_texture(false)
	show()
	set_process(true)


func _process(delta: float) -> void:
	_t = fmod(_t + delta / cycle, 1.0)
	if _mode == Mode.DRAG:
		_process_drag()
	else:
		_process_tap()


func _process_drag() -> void:
	# 0–15%: aperta parada · 15–70%: leva · 70–85%: solta no alvo · 85–100%: some
	var p := clampf((_t - 0.15) / 0.55, 0.0, 1.0)
	p = p * p * (3.0 - 2.0 * p)
	var pos := _from.lerp(_to, p) - Vector2(0, sin(p * PI) * arc)
	global_position = pos - _tip()
	scale = Vector2.ONE * (0.9 if _t > 0.1 and _t < 0.75 else 1.0)
	modulate.a = 1.0 if _t < 0.85 else (1.0 - _t) / 0.15


func _process_tap() -> void:
	# 0–35%: aparece e desce · 35–60%: toca (risquinhos) · 60–85%: sobe · 85–100%: some
	var lift: float
	if _t < 0.35:
		lift = 1.0 - smoothstep(0.0, 0.35, _t)
	elif _t < 0.6:
		lift = 0.0
	else:
		lift = smoothstep(0.6, 0.85, _t)
	var tap_now := _t >= 0.35 and _t < 0.6 and tap_texture != null
	if tap_now != _tapping:
		_apply_texture(tap_now)
	global_position = _to + WRIST_DIR.rotated(rotation) * lift * tap_lift - _tip()
	scale = Vector2.ONE  # sem encolher no toque: a troca de textura fica no lugar
	modulate.a = minf(1.0, _t / 0.1) if _t < 0.85 else (1.0 - _t) / 0.15


func _apply_texture(tap: bool) -> void:
	_tapping = tap and tap_texture != null
	var tex := _current_texture()
	var s := hand_size / TEX_WIDTH
	size = tex.get_size() * s if tex else Vector2(64, 64)
	pivot_offset = _tip()
	queue_redraw()


func _current_texture() -> Texture2D:
	return tap_texture if _tapping else texture


## Ponta do dedo em coordenadas locais.
func _tip() -> Vector2:
	if not _current_texture():
		return Vector2(22, 6)
	return TIP_PX * hand_size / TEX_WIDTH


func _draw() -> void:
	var tex := _current_texture()
	if tex:
		draw_texture_rect(tex, Rect2(Vector2.ZERO, size), false)
		return
	# placeholder: dedo indicador + palma
	draw_rect(Rect2(16, 4, 12, 30), SKIN)
	draw_circle(Vector2(22, 6), 6, SKIN)
	draw_rect(Rect2(12, 28, 36, 26), SKIN)
	draw_circle(Vector2(30, 52), 14, SKIN)
	draw_arc(Vector2(22, 6), 6, PI, TAU, 10, INK, 3)
	draw_line(Vector2(16, 6), Vector2(16, 30), INK, 3)
	draw_line(Vector2(28, 6), Vector2(28, 26), INK, 3)
	draw_arc(Vector2(30, 46), 18, 0.2, PI - 0.2, 16, INK, 3)
