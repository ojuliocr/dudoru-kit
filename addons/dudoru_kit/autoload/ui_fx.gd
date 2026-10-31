extends Node
## Autoload "UiFx": todo botão (BaseButton) do jogo ganha um pulinho ao ser apertado,
## sem precisar de script. Afunda ao apertar e volta passando um pouco do tamanho.
##
## Pra desligar num botão: Inspector → Metadata → no_bounce (bool) = true,
## ou no código: botao.set_meta("no_bounce", true).
## Pickable e SpeakButton ficam de fora porque já têm animação própria.

const PRESS_SCALE := 0.92
const POP_SCALE := 1.08


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is BaseButton and not (node is Pickable or node is SpeakButton):
		node.button_down.connect(_on_down.bind(node))
		node.button_up.connect(_on_up.bind(node))


func _on_down(b: BaseButton) -> void:
	if b.disabled or b.get_meta("no_bounce", false):
		return
	b.set_meta("_fx_down", true)
	var tw := _new_tween(b)
	tw.tween_property(b, "scale", Vector2.ONE * PRESS_SCALE, 0.06).set_ease(Tween.EASE_OUT)


## Se o botão afundou, ele sempre volta, mesmo que o jogo o tenha desabilitado
## (ou ligado no_bounce) no pressed, que chega antes do button_up.
func _on_up(b: BaseButton) -> void:
	if not b.get_meta("_fx_down", false):
		return
	b.set_meta("_fx_down", false)
	var tw := _new_tween(b)
	tw.tween_property(b, "scale", Vector2.ONE * POP_SCALE, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _new_tween(b: BaseButton) -> Tween:
	if b.has_meta("_fx_tween"):
		var old: Tween = b.get_meta("_fx_tween")
		if old and old.is_valid():
			old.kill()
	b.pivot_offset = b.size / 2
	var tw := b.create_tween()
	b.set_meta("_fx_tween", tw)
	return tw
