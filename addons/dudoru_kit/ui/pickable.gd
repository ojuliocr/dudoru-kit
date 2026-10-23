class_name Pickable
extends TextureButton
## Objeto clicável: cresce no hover, afunda no clique e brilha (shader) quando
## selecionado. Pode ter uma legenda.

enum Caption { NONE, BELOW, PILL_BOTTOM, PILL_TOP }

const SELECT_SHADER := preload("res://addons/dudoru_kit/shaders/pickable_select.gdshader")
const ANIM_TIME := 0.15
const HOVER_SCALE := 1.04
const PRESS_SCALE := 0.9

@export var id := ""
@export var caption_style := Caption.NONE
@export var caption_size := 16
@export var caption_ink := Color("3a2230")
@export var caption_paper := Color("fff8ec")
## Som tocado no clique (nome do arquivo em assets/audio/sfx, sem extensão). Vazio = sem som.
@export var sound := "click"
## Balanço contínuo bem sutil, em graus (0 = parado). Ex.: comanda pendurada.
@export var idle_sway := 0.0
@export var idle_period := 2.6
## Gira e cresce a partir do topo, como algo pendurado.
@export var hang_from_top := false

var caption := "":
	set(v):
		caption = v
		_caption_layer.queue_redraw()

var selected := false:
	set(v):
		if v == selected:
			return
		selected = v
		# tween_method: o Tween não enxerga "shader_parameter/..." como propriedade.
		create_tween().tween_method(_set_amount, _mat.get_shader_parameter("amount"), 1.0 if v else 0.0, ANIM_TIME)

var _hovered := false
var _base_scale := Vector2.ONE  # escala que você deixou no editor
var _base_rotation := 0.0       # ângulo que você deixou no editor
var _idle_time := 0.0
var _scale_tween: Tween
var _mat := ShaderMaterial.new()
var _pill := StyleBoxFlat.new()
# A legenda fica num filho para não passar pelo shader do sprite.
var _caption_layer := Control.new()


func _ready() -> void:
	_base_scale = scale
	_base_rotation = rotation
	_set_pivot_keep_place(Vector2(size.x / 2, 0) if hang_from_top else size / 2)
	focus_mode = Control.FOCUS_NONE
	_mat.shader = SELECT_SHADER
	_mat.set_shader_parameter("amount", 0.0)
	material = _mat
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	button_down.connect(_on_press)
	pressed.connect(func(): Sfx.play(sound))

	_pill.bg_color = caption_paper
	_pill.border_color = caption_ink
	_pill.set_border_width_all(2)
	_pill.set_corner_radius_all(caption_size)

	_caption_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption_layer.size = size
	add_child(_caption_layer)
	_caption_layer.draw.connect(_draw_caption)
	set_process(idle_sway > 0.0)


## Troca o pivô sem o objeto "pular" de lugar (importa quando ele está girado no editor).
func _set_pivot_keep_place(new_pivot: Vector2) -> void:
	var rs := Transform2D(rotation, scale, 0.0, Vector2.ZERO)
	position += (pivot_offset - rs * pivot_offset) - (new_pivot - rs * new_pivot)
	pivot_offset = new_pivot


func set_enabled(on: bool) -> void:
	disabled = not on
	modulate = Color.WHITE if on else Color(0.8, 0.8, 0.8, 0.7)
	if not on:
		_hovered = false
		_scale_to(_rest_scale())


## Chama a atenção para o objeto (ex.: clicou na pizza sem escolher sabor).
func pulse() -> void:
	_scale_tween_new()
	_scale_tween.tween_property(self, "scale", _base_scale * 1.12, 0.1)
	_scale_tween.tween_property(self, "scale", _rest_scale(), 0.15)


func shake() -> void:
	var tw := create_tween()
	for angle in [0.15, -0.12, 0.07, 0.0]:
		tw.tween_property(self, "rotation", _base_rotation + angle, 0.06)


## Balanço idle: seno contínuo, sem paradas no meio do movimento.
func _process(delta: float) -> void:
	_idle_time += delta
	rotation = _base_rotation + deg_to_rad(idle_sway) * sin(_idle_time * TAU / idle_period)


func _on_hover(on: bool) -> void:
	_hovered = on and not disabled
	_scale_to(_rest_scale())


func _on_press() -> void:
	_scale_tween_new()
	_scale_tween.tween_property(self, "scale", _base_scale * PRESS_SCALE, 0.08)
	_scale_tween.tween_property(self, "scale", _rest_scale(), 0.14)


func _rest_scale() -> Vector2:
	return _base_scale * (HOVER_SCALE if _hovered else 1.0)


func _scale_to(target: Vector2) -> void:
	_scale_tween_new()
	_scale_tween.tween_property(self, "scale", target, ANIM_TIME)


## Uma animação de escala por vez, para hover, clique e pulso não brigarem.
func _scale_tween_new() -> void:
	if _scale_tween:
		_scale_tween.kill()
	_scale_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _set_amount(value: float) -> void:
	_mat.set_shader_parameter("amount", value)


func _draw_caption() -> void:
	if caption == "" or caption_style == Caption.NONE:
		return
	var font := get_theme_default_font()
	var text_w := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, caption_size).x
	var baseline_shift := (font.get_ascent(caption_size) - font.get_descent(caption_size)) / 2
	if caption_style == Caption.BELOW:
		_caption_layer.draw_string(font, Vector2(0, size.y + caption_size), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, caption_size, caption_ink)
		return
	var h := caption_size + 12.0
	var w := maxf(text_w + 24, h + 8)
	var cy := size.y - 4 if caption_style == Caption.PILL_BOTTOM else -h / 2 - 6
	_caption_layer.draw_style_box(_pill, Rect2(size.x / 2 - w / 2, cy - h / 2, w, h))
	_caption_layer.draw_string(font, Vector2(size.x / 2 - text_w / 2, cy + baseline_shift), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, caption_size, caption_ink)
