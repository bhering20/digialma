# Digialma

Jogo de monstrinhos em **Godot 4** com um modo **idle** que roda numa faixa
transparente no canto da tela (estilo *Taskbar Hero*), e um modo completo com
batalhas de ritmo inspiradas em *Clair Obscur*.

> Repositório **privado**: contém pacotes de arte de terceiros (Scarloxy e
> `scarloxy_graphics`) cujas licenças não permitem redistribuição pública.

## Como abrir
1. Instale o Godot **4.3 ou mais novo** (renderizador *Compatibility*).
2. No Godot, *Importar* → selecione `project.godot`.
3. Aperte **F5**. Na tela inicial: **MODO IDLE** ou **NOVO JOGO**.

## O que tem
- **Modo idle (faixa):** o grupo explora e purifica sozinho, salva sozinho e
  continua offline (até 8h). Duelos de raros ali mesmo na faixa, Selo de Alma
  para capturar, Santuário no fim do caminho, evolução numa janelinha.
- **Progressão:** raridade (Comum → Lendário), Árvore de Alma (15 nós),
  Árvore do Elo, nível do Elo (exigido para capturar), amuletos,
  Ressonância, Essência e **elementos híbridos** (Fogo + Água = Vapor...).
- **Modo completo:** mapa com 3 regiões, rotas com emboscadas, batalhas com
  esquiva/aparo/combos, Fusão de Alma e Santuários.

## Estrutura
| Pasta | Conteúdo |
|---|---|
| `scripts/` | Todo o código (GDScript). `game.gd` é o autoload com dados e estado. |
| `scenes/` | Cenas (a interface é montada em código). |
| `assets/` | Arte: `monsters/`, `ui/`, `gear/`, `props/`, `badges/`, `packs/` (terceiros). |
| `tools/` | Utilitários de desenvolvimento. |

Arquivos principais: `idle.gd` (faixa), `strip_duel.gd` (duelo na faixa),
`battle.gd` (batalha completa), `arvores.gd` (menu: itens, alma, fusão, elo,
equipe), `route.gd` (rotas e santuários).

## Exportar (Windows)
*Projeto → Exportar* → preset **Windows Desktop** (gera um `.exe` único em
`build/`). Precisa dos *export templates* da sua versão do Godot.

## Save
`%APPDATA%\Godot\app_userdata\Digialma\digialma_save.dat`

## Status
Versão de teste **0.1** (modo idle). Ainda sem som.
