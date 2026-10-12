# Crystal Isles

- 56 modelos de picaretas: ferramentas reais na mão, troca imediata ao comprar/renascer, golpe usando a animação padrão Roblox e galerias de previews.
- 104 retratos de pets com sete silhuetas (Sprite/Fox/Golem/Dragon/Phoenix/Titan/Oracle), paletas de bioma e variantes. ViewportFrame renderiza as imagens, com opção de asset 2D próprio.
- Miniaturas dos 14 mundos usam os mesmos modelos dos landmarks do mapa: cabana, árvore gigante, pirâmide, navio, casa de doces, vulcão, foguete, núcleo astral, santuário Void, templo, skyline Cyber, gelo, relógio e castelo.
- Loja de picaretas com expositores 3D e pedestais de pets junto aos ovos. Jardins, dunas, lagoas, lava e pavimentos enriquecem os biomas.
- Interface clara, seis atalhos principais, abas, galerias em grid, retrato do pet selecionado e detalhes de ajuda recolhíveis. Sem recriar galerias a cada snapshot quando os dados relevantes não mudam.
- Quatro painéis TOP GLOBAL na praça inicial e tabela no menu com posições, avatares e totais. Nome de usuário consultado uma vez por servidor. Falha de API conserva o último resultado e sinaliza indisponibilidade.
- Validação de 17 menus reais com serviços simulados; todas as geometrias e importação XML verificadas. DataStore, controles, viewport/iluminação e física ainda exigem teste real no Studio.

# Cosmic Horizons

- 14 mundos (novos: Cyber, Frost, Clockwork e Dream), 56 picaretas, 104 espécies de pets e variantes Normal/Golden/Cosmic.
- Ilhas flutuantes com cenários próprios, trilhas, portais, pedestais, lojas, lounge AFK e interação E / X / toque.
- Mapa incluído no arquivo Studio para preview em edição; reconstruído pelo servidor para iniciar HP, prompts e respawns.
- Tutorial de cinco etapas, pet gratuito Orbit Buddy, próximo objetivo e marcador visual.
- Mineração ao segurar o botão, highlight de alvo e combo com até +50% Coins.
- Um titã cooperativo por mundo, recompensa por contribuição e respawn de três minutos.
- Gems Lab: dano, Coins, mochila e slots permanentes conquistáveis no jogo.
- Fusão determinística de três pets iguais: Golden (bônus 2,5x) e Cosmic (bônus 6,25x), com custo e confirmação.
- Atlas de coleção com primeira descoberta, 16 conquistas, presentes de tempo de exploração e ciclo diário de sete dias.
- Loja de passes/produtos com categorias, benefícios, status adquirido e preços consultados no Roblox; ofertas não configuradas desativadas.
- UI adaptativa com cards, barras, inventário paginado, preview 3D dos pets em ovos e modo de movimento reduzido.
- Convite oficial de amigos, mantendo envio como ação explícita do jogador.
- Perfil v1 migrado por adição de campos, sem reset; proteção da sincronização inicial quando o cliente conecta após o primeiro snapshot.
- Compilação de 15 arquivos Luau, 33 verificações automáticas com APIs simuladas, exportação da geometria real do mapa e validação de importação pelo Rojo.

Validação de motor Roblox, física, câmera, interface nos dispositivos, DataStore real e Marketplace continua obrigatória no Studio. Os testes não garantem desempenho ou ausência de problemas de gameplay em produção.
