# Dudoru Kit

Base comum dos jogos do estúdio Dudoru: o que todo jogo precisa e não muda de um pro outro. O visual (tema, botões, fontes, arte) fica em cada jogo.

**Versão:** 0.2.0 · **Godot:** 4.7.2 (Compatibility)

## O que tem

```
addons/dudoru_kit/
├── autoload/
│   ├── text.gd           T       textos de data/texts/<idioma>.json
│   ├── audio_manager.gd  AudioManager   players de música e efeitos
│   ├── sfx.gd            Sfx     toca som pelo nome do arquivo
│   └── lol.gd            LoL     integração Legends of Learning + save local
├── ui/
│   ├── title_screen.gd   TitleScreen   logo com pop/flutuar/brilho, Novo jogo/Continuar
│   ├── tutorial_hint.gd  dica do tutorial que se posiciona ao lado do alvo
│   ├── pickable.gd       Pickable      objeto clicável com brilho de seleção
│   └── speak_button.gd   SpeakButton   botão de leitura (TTS); arte vem do jogo
└── shaders/
    ├── pickable_select.gdshader
    ├── logo_shine.gdshader
    └── saturation.gdshader
```

Ao ativar o plugin (**Project Settings → Plugins → Dudoru Kit**), os autoloads entram nesta ordem: `T`, `AudioManager`, `Sfx`, `LoL`. O autoload do jogo (`Game`) vem depois deles.

## Convenções que todo jogo segue

- **Textos:** `res://data/texts/en.json` (oficial pra LoL) e `pt.json`. Chaves obrigatórias: `title.new_game`, `title.continue`.
- **Sons:** `res://assets/audio/sfx/<nome>.ogg` e `res://assets/audio/music/<nome>.ogg`. O kit usa `click`. Ajuste de tom/volume por jogo: `Sfx.pitch["nome"] = 0.1`, `Sfx.volume["nome"] = -6.0`.
- **Save:** o Dictionary salvo com `LoL.save_state()` sempre tem `"progress"` (etapas concluídas). É isso que decide se o botão Continuar aparece.
- **Progresso LoL:** `LoL.submit_progress(atual, maximo)` pelo menos 8 vezes por partida, nunca diminuindo. No fim: `LoL.clear_state()` e `LoL.complete()`.
- **TTS:** todo texto que aparece na tela tem uma chave que a LoL consegue ler. Use `SpeakButton` com `key` = a chave.
- **Teste de TTS fora da LoL:** Project Settings → `dudoru/force_tts_buttons` = true. Só vale rodando no editor (build de debug); a build de release ignora.

## Template web (export enxuto)

O workflow **Build Web Template** compila o export template Web sem 3D/física/threads e publica em **Releases** como `web-<versão>/web_nothreads_release.zip`. Os jogos baixam dali; o zip não é commitado em nenhum repo.

Rodar de novo só quando mudar a versão do Godot (troque `GODOT_VERSION` no workflow).

## Atualizar o kit num jogo

Nunca edite `addons/dudoru_kit` dentro de um jogo. Corrija aqui, suba a versão em `plugin.cfg`, e rode `tools/sync-kit.ps1` no jogo.

## Histórico

- **0.2.0:** LoL, textos, Sfx, tela de título, dica de tutorial, Pickable, SpeakButton e shaders vindos do Slice by Slice. Template web publicado como Release. Opção `dudoru/force_tts_buttons` substitui a constante `FORCE_TTS_BUTTONS`.
- **0.1.0:** AudioManager.
