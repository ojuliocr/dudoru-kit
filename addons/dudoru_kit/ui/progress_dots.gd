class_name ProgressDots
extends PanelContainer
## Barra de progresso em bolinhas: uma bolinha por fase. O fundo estica sozinho conforme
## a quantidade de bolinhas. Se o painel não tiver um estilo próprio (tema ou override),
## usa o quadro padrão do kit; para outra arte, troque `frame` ou defina o estilo do painel.

@export var steps := 12:
	set(v):
		v = maxi(v, 1)
		if v == steps:
			return
		steps = v
		if is_node_ready():
			_build()
@export var dot_full: Texture2D = preload("res://addons/dudoru_kit/assets/progress_dot_full.png")
@export var dot_empty: Texture2D = preload("res://addons/dudoru_kit/assets/progress_dot_empty.png")
@export var frame: Texture2D = preload("res://addons/dudoru_kit/assets/progress_frame.png")
@export var dot_size := 26.0
@export var separation := 6

var _dots: Array[TextureRect] = []
var _done := 0
var _box: HBoxContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_default_frame()
	_box = HBoxContainer.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_box)
	_build()


## done = quantas fases já foram feitas. Com animate, as bolinhas que acabaram de
## encher dão um pop.
func set_progress(done: int, animate := true) -> void:
	done = clampi(done, 0, steps)
	for i in _dots.size():
		var filled := i < done
		_dots[i].texture = dot_full if filled else dot_empty
		if animate and filled and i >= _done:
			_pop(_dots[i])
	_done = done


func _apply_default_frame() -> void:
	if frame == null or has_theme_stylebox_override("panel"):
		return
	var box := StyleBoxTexture.new()
	box.texture = frame
	box.texture_margin_left = 22
	box.texture_margin_right = 22
	box.content_margin_top = (frame.get_height() - dot_size) / 2.0
	box.content_margin_bottom = (frame.get_height() - dot_size) / 2.0
	add_theme_stylebox_override("panel", box)


func _build() -> void:
	for d in _dots:
		d.queue_free()
	_dots.clear()
	_box.add_theme_constant_override("separation", separation)
	for i in steps:
		var d := TextureRect.new()
		d.custom_minimum_size = Vector2.ONE * dot_size
		d.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		d.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		d.pivot_offset = Vector2.ONE * dot_size / 2
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_box.add_child(d)
		_dots.append(d)
	set_progress(_done, false)


func _pop(d: TextureRect) -> void:
	d.scale = Vector2.ONE * 0.6
	var tw := d.create_tween()
	tw.tween_property(d, "scale", Vector2.ONE * 1.2, 0.14).set_ease(Tween.EASE_OUT)
	tw.tween_property(d, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
