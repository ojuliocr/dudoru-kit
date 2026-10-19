# dudoru-kit

Addon do Godot com sistemas reaproveitáveis entre os jogos do estúdio.

## O que tem

| Sistema | Autoload | Descrição |
|---|---|---|
| AudioManager | `AudioManager` | Pool de efeitos sonoros e música em loop com fade |

## Como usar num jogo

1. Copie a pasta `addons/dudoru_kit` para a pasta `addons/` do jogo.
2. No Godot: **Project → Project Settings → Plugins** → ative **Dudoru Kit**.
3. O autoload `AudioManager` é registrado automaticamente.
4. (Opcional) Crie os buses `Music` e `SFX` em **Audio → Buses** pra controlar volume separado.

```gdscript
AudioManager.play_sfx(preload("res://assets/audio/click.ogg"), 0.0, 0.1)
AudioManager.play_music(preload("res://assets/audio/tema.ogg"))
AudioManager.stop_music(1.0)
```

## Atualizando o kit nos jogos

Por enquanto, **copiar a pasta** é o método oficial: simples e sem dependência entre repos.
Quando houver 3 ou mais jogos usando o kit, vale migrar para `git submodule`.

Ao mudar o kit:
1. Suba a versão em `addons/dudoru_kit/plugin.cfg` (`version="0.2.0"`).
2. Faça commit e crie uma tag (`v0.2.0`).
3. Nos jogos que precisarem da mudança, copie a pasta de novo.

## Ideias para próximos sistemas

- Transição de cena com fade
- Save/load simples em JSON (`user://`)
- Botão com som e animação padrão
