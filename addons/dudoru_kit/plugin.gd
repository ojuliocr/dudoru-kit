@tool
extends EditorPlugin

# Registra os autoloads do kit quando o plugin é ativado
# (Project → Project Settings → Plugins → Dudoru Kit → Enable)
# e remove quando é desativado.

const AUTOLOADS := {
	"AudioManager": "res://addons/dudoru_kit/scripts/audio_manager.gd",
}


func _enable_plugin() -> void:
	for autoload_name in AUTOLOADS:
		add_autoload_singleton(autoload_name, AUTOLOADS[autoload_name])


func _disable_plugin() -> void:
	for autoload_name in AUTOLOADS:
		remove_autoload_singleton(autoload_name)
