class_name TitleScreen
extends Control
## Tela de título: logo entra com pop e flutua; espera a LoL (idioma e save) e mostra Novo jogo / Continuar.
##
## Nós esperados (Access as Unique Name):
##   %TitleLogo       TextureRect fora de container. Brilho opcional: ShaderMaterial com logo_shine.gdshader
##   %TitleButtons    container com os dois botões
##   %NewGameButton   Button
##   %ContinueButton  Button
## Textos: chaves "title.new_game" e "title.continue".

signal play_pressed(continue_game: bool)

const FADE_TIME := 0.3

const FLOAT_AMOUNT := 6.0
const FLOAT_PERIOD := 3.0

const SHINE_SWEEP := 0.8
const SHINE_INTERVAL := 3.2

const BUTTON_STAGGER := 0.12
const BUTTON_TIME := 0.3
const PRESS_WAIT := 0.3   # duração do pulinho do botão (UiFx) antes de sair do título

@onready var logo: TextureRect = %TitleLogo
@onready var new_button: Button = %NewGameButton
@onready var continue_button: Button = %ContinueButton
@onready var buttons: Control = %TitleButtons

var _logo_base_y := 0.0
var _float_time := 0.0
var _floating := false
var _shine_tween: Tween
var _starting := false


func _ready() -> void:
	buttons.hide()
	new_button.pressed.connect(_on_pressed.bind(false))
	continue_button.pressed.connect(_on_pressed.bind(true))
	_logo_base_y = logo.position.y
	var logo_in := _pop_logo()
	if not LoL.is_initialized:
		await LoL.initialized
	new_button.text = T.t("title.new_game")
	continue_button.text = T.t("title.continue")
	continue_button.visible = LoL.has_saved_game()
	if logo_in.is_running():
		await logo_in.finished
	_show_buttons()


func _process(delta: float) -> void:
	if not _floating:
		return
	_float_time += delta
	logo.position.y = _logo_base_y - sin(_float_time * TAU / FLOAT_PERIOD) * FLOAT_AMOUNT


func _pop_logo() -> Tween:
	logo.pivot_offset = logo.size / 2.0
	logo.scale = Vector2.ZERO
	logo.rotation = deg_to_rad(-6.0)
	logo.modulate.a = 0.0

	var tw := create_tween()
	tw.tween_property(logo, "scale", Vector2.ONE * 1.12, 0.33).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(logo, "rotation", deg_to_rad(2.0), 0.33).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(logo, "modulate:a", 1.0, 0.2)
	tw.tween_property(logo, "scale", Vector2.ONE * 0.96, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(logo, "rotation", 0.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(logo, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_start_idle)
	return tw


func _start_idle() -> void:
	_floating = true
	if not logo.material is ShaderMaterial:
		return
	_shine_tween = create_tween().set_loops()
	_shine_tween.tween_interval(0.4)
	_shine_tween.tween_method(_set_shine, -0.2, 1.2, SHINE_SWEEP)
	_shine_tween.tween_interval(SHINE_INTERVAL - 0.4)


func _set_shine(value: float) -> void:
	(logo.material as ShaderMaterial).set_shader_parameter("progress", value)


func _show_buttons() -> void:
	buttons.show()
	# Espera o container posicionar os botões para o pivô ficar certo.
	await get_tree().process_frame
	var i := 0
	for b: Button in [new_button, continue_button]:
		if not b.visible:
			continue
		b.pivot_offset = b.size / 2.0
		b.scale = Vector2.ONE * 0.85
		b.modulate.a = 0.0
		var tw := create_tween().set_parallel()
		tw.tween_property(b, "scale", Vector2.ONE, BUTTON_TIME).set_delay(i * BUTTON_STAGGER).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(b, "modulate:a", 1.0, BUTTON_TIME * 0.6).set_delay(i * BUTTON_STAGGER)
		i += 1


func _on_pressed(continue_game: bool) -> void:
	if _starting:
		return
	_starting = true
	Sfx.play("click")
	# Dá tempo do pulinho do UiFx terminar antes de esconder os botões.
	await get_tree().create_timer(PRESS_WAIT).timeout
	buttons.hide()
	play_pressed.emit(continue_game)


func hide_title() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, FADE_TIME)
	await tw.finished
	_floating = false
	if _shine_tween:
		_shine_tween.kill()
	hide()
