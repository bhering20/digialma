# Digialma — protótipo v0.3 (Godot 4.3+) — pixel art estilo GBA

Idle RPG de monstrinhos virtuais que vive numa faixa em cima da barra de tarefas,
no estilo de TBH: Task Bar Hero, mas com pets estilo Digimon/Tamagotchi.

## Como abrir
1. Extraia esta pasta (ex.: `Área de Trabalho/digialma`).
2. Abra a Godot 4.3 ou mais nova → **Importar** → selecione `project.godot`.
3. Aperte **F5**. O jogo aparece como uma faixa transparente em cima da barra de tarefas.
   - **Clique no Digi** = alimentar · **clique no cocô** = limpar · **Painel** = status e loja
   - **Arraste o fundo da faixa** para subir/descer · **Esc** ou **X** = salvar e sair

## Loop do jogo (o que já funciona)
- Até 3 Digis andam e lutam sozinhos contra "Glitches" (bugs digitais), onda após onda.
  A cada 10 ondas vem um chefe. Se a equipe cair, recua 3 ondas (como no TBH).
- Cada Digi tem uma **criança parceira** que anda atrás dele.
- **Cuidado de pet:** fome cai com o tempo, cocô aparece e precisa ser limpo.
  Alimentar e limpar aumentam o **Vínculo** (que também dá crítico e ataque).
- **Evolução ramificada:** Bebê (Nv 1) → Novato (Nv 5) → Campeão (Nv 15).
  Ao virar Campeão: vínculo ≥ 50 → **caminho da Luz** (asas, mais vida);
  vínculo baixo → **caminho da Sombra** (espinhos, olhos vermelhos, mais ataque).
- **DIGIALMA:** Campeão Nv 30 + vínculo 80 + 10 fragmentos → a criança se funde
  com o monstro (forma máxima com o lenço da criança e coroa). É um botão, um momento épico.
- **Ovos:** a cada 40 vitórias choca um ovo aleatório (4 espécies × 6 formas = 24 no Dex).
- Elementos: Fogo > Planta > Água > Fogo; Raio > Água.
- Loja com Bits: Treino (+ataque), Vitalidade (+vida), comida.
- **Progresso offline** (até 8h, sem punir a fome) e save automático a cada 30s.

## Visual (v0.3) — estilo GBA
- Tudo é desenhado em meia resolução e ampliado 2x (pixel perfeito).
- Sprites 72x72 com contorno colorido e paleta limitada (`assets/art/`).
- Tela de batalha: fundo verde listrado, nuvens, morros, grama, plataformas ovais,
  barras de HP verde/amarelo/vermelho, caixa de diálogo com borda dupla, fonte Pixelify Sans (OFL).
- `tools/gen_art.py` + `tools/build_pixel.py` geram os sprites (Python + rsvg-convert).
  Para trocar por sprites desenhados à mão, basta substituir os PNGs com os mesmos nomes.

## Arquivos
- `scripts/main.gd` — jogo inteiro (combate, cuidado, evolução, save, UI, janela)
- `scripts/data.gd` — espécies, nomes das formas, elementos e regras (fácil de balancear)

## Por que esse jogo tem espaço no mercado
- TBH explodiu em 2026 (centenas de milhares de jogadores simultâneos), mas as reviews ficaram
  "Mistas" por coleta de dados obrigatória, banimentos, bots, classes pagas e time-gating pesado.
- "Desktop companion" virou tag oficial na Steam (Bongo Cat, Rusty's Retirement, Tiny Pasture...).
- Ninguém juntou bem as duas coisas: **RPG idle de barra de tarefas + bichinho virtual com vínculo**.

### O que o Digialma traz que falta no TBH
| Falta no TBH | No Digialma |
|---|---|
| Heróis sem personalidade | Pets com fome, humor, vínculo e criança parceira |
| Evolução = só números | Evolução ramificada que depende de como você cuidou |
| Classes pagas / sensação de pay-to-win | Tudo se ganha jogando; monetização só cosmética (ideia) |
| Coleta de dados e anti-cheat agressivo | Offline, sem conta, sem telemetria |
| Pouca razão para "olhar" o jogo | Interações rápidas de 5 segundos (alimentar, limpar, Digialma) |

## Próximos passos sugeridos
1. Sprite sheets com animação quadro a quadro (ou modelos 3D do Tripo renderizados em estilo anime).
2. Sons (chiptune) e efeito especial na Digialma.
3. Mais espécies, mapas/biomas e chefes únicos.
4. Itens equipáveis e "Digichips" (modificadores tipo runas do TBH).
5. Interação social sem economia real: trocar ovos/visitar amigos via Steam.
6. Contar teclado/mouse como "energia" (tendência Bongo Cat) — exige plugin nativo.
7. Exportar para Windows (.exe) e preparar página na Steam.
