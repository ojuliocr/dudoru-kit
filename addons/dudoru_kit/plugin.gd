@tool
extends EditorPlugin

# Ao ativar o plugin (Project Settings → Plugins → Dudoru Kit), registra os autoloads
# do kit na ordem certa, a opção de teste do TTS e o tema padrão (Baloo 2, 28). Ao desativar, remove os autoloads.
# O autoload do jogo (Game) deve vir depois destes na lista de Globals.

const BASE := "res://addons/dudoru_kit/autoload/"
const AUTOLOADS := [
	["T", BASE + "text.gd"],
	["AudioManager", BASE + "audio_manager.gd"],
	["Sfx", BASE + "sfx.gd"],
	["LoL", BASE + "lol.gd"],
	["UiFx", BASE + "ui_fx.gd"],
]
const FORCE_TTS_SETTING := "dudoru/force_tts_buttons"
const THEME_SETTING := "gui/theme/custom"
const THEME_PATH := "res://addons/dudoru_kit/theme/dudoru_theme.tres"


func _enable_plugin() -> void:
	for entry in AUTOLOADS:
		add_autoload_singleton(entry[0], entry[1])
	if not ProjectSettings.has_setting(FORCE_TTS_SETTING):
		ProjectSettings.set_setting(FORCE_TTS_SETTING, false)
	ProjectSettings.set_initial_value(FORCE_TTS_SETTING, false)
	ProjectSettings.add_property_info({"name": FORCE_TTS_SETTING, "type": TYPE_BOOL})
	if str(ProjectSettings.get_setting(THEME_SETTING, "")) == "":
		ProjectSettings.set_setting(THEME_SETTING, THEME_PATH)
	ProjectSettings.save()


func _disable_plugin() -> void:
	for entry in AUTOLOADS:
		remove_autoload_singleton(entry[0])
