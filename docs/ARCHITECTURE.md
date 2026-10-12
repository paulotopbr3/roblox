# Arquitetura e decisões

## Árvore no Studio

```text
ReplicatedStorage/UniverseMiner
  Config, Balance, Economy, Progression, Art, Models (ModuleScripts)
  Remotes/Action, Update (RemoteEvents, criados em runtime)
ServerScriptService/UniverseMiner
  Main (Script)
  Data, Game, Map, Commerce, Rankings, Content, Gear (ModuleScripts)
StarterPlayer/StarterPlayerScripts/UniverseMiner/Main (LocalScript), UI, Visuals (ModuleScripts)
Workspace/UniverseMap (gerado em runtime)
PlayerGui/UniverseMinerUI (gerado no cliente)
```

`Action` aceita intenções: Mine, Sell, Tool, World, Hatch, Rebirth, AutoMine, Equip, DeletePet, EquipBest, Quest, Code, Setting, Purchase, Rankings e Sync. `Update` entrega State, Notice, Reward, MineFX, Celebration, Hatch, Global e Rankings. Valores arbitrários do cliente nunca determinam recompensas; distância, mundo, HP, cooldown, slots, saldo e propriedade são verificados no servidor. O limitador permite burst de 35 chamadas e reposição de 20/s por jogador. Não há RemoteFunction que bloqueie o cliente.

## Economia

Cristais têm HP individual compartilhado entre jogadores, 7% de chance de serem raros (4x HP, 8x recompensa), cinco segundos de respawn e recompensa para quem dá o último golpe. Não há recompensa dupla: a transição de HP para zero não faz yield. Cristais dão valor à mochila; vender converte esse valor em Coins. O servidor valida capacidade antes de causar dano. A venda manual é acessível gratuitamente; Auto Sell automatiza a mesma ação. Infinite Backpack remove o limite de 30 cristais.

Multiplicadores de pets são **aditivos** dentro de cada atributo; rebirth, ferramenta, passe, boost e evento são multiplicativos. Gems compradas têm quantidade fixa e não são multiplicadas por passes. Rebirth reinicia Coins, mochila, ferramenta e mundos; pets, Gems, missões, boosts e histórico são preservados. Custo cresce em 1,65x, com limite numérico; multiplicador cresce em +0,5x por rebirth. O limite de números é 1e150, portanto “infinito” significa sem limite configurado de rebirths, dentro da precisão finita dos doubles.

Ovos têm probabilidades base Common 60%, Uncommon 25%, Rare 10%, Epic 4%, Legendary 0,85%, Mythical 0,14%, Secret 0,01%. Luck multiplica os pesos Rare ou superiores e renormaliza a distribuição; a UI mostra as chances com os boosts atuais. Créditos de ovos substituem o custo em Coins de aberturas futuras; 10/100 ovos não são abertos imediatamente. Limite normal: 400 pets; compras de pet e direito de Exclusive Pets nunca são descartados por inventário cheio e podem exceder esse limite. Aberturas adicionais ficam bloqueadas até liberar espaço. Pets comprados podem ser excluídos após confirmação; isso não restaura o produto.

Instant Rebirth elimina a confirmação extra; não elimina o custo nem os resets. Teleport All Worlds dispensa custo e sequência de desbloqueio, mas mantém requisitos de rebirth dos mundos avançados. Extra Pet Slots concede +3; Magnet aumenta alcance de 24 para 55 studs. VIP permite a área AFK de 3x; Premium AFK dobra os ganhos AFK. Auto Mine seleciona um cristal próximo no servidor. Não há auto hatch gratuito ou pago escondido.

## Persistência e compras

Perfil `u:<UserId>` no DataStore configurado. UpdateAsync faz aquisição de sessão com token único e lease de 240 s, renovado a cada autosave de 60 s. Sessões em outro servidor bloqueiam o login até liberação/expiração. Mutações param se a sessão não conseguir salvar por 200 s. Se outro servidor tomou a sessão, o jogador é desconectado. Saída e BindToClose tentam salvar e liberar; serviços Roblox indisponíveis podem perder progresso desde o último save, por isso teste desconexões e shutdown antes de publicar.

Gamepasses são consultados no Marketplace no login e depois de compra; não se confia na flag salva. Recibos de developer products são processados apenas no servidor. Grant e marca de PurchaseId são uma operação de memória sem yield e vão no **mesmo** UpdateAsync do perfil. PurchaseGranted só retorna após persistência confirmada. Em falha, NotProcessedYet deixa o Roblox reenviar; a marca impede grant duplicado. Nunca conceder usando PromptProductPurchaseFinished. Em sessão temporária, recibos não são confirmados.

Histórico de recibos e códigos é mantido para evitar replay. Monitore tamanho dos perfis, uso de DataStore e throttling antes de grande escala; o limite Roblox por entrada exige projeto de migração/arquivamento durável antes que contas com muitas compras atinjam esse limite. Esta versão não limpa recibos antigos de maneira insegura. Não altere o nome do DataStore de produção sem migração.

Rankings usam quatro OrderedDataStores, escrevem após saves e têm cache de leitura de 180 s. Coins e Pets são totais históricos, Gems é saldo atual. Números grandes são codificados como log10 × 1.000.000 para caber em inteiros, com pequena aproximação na exibição; empates por quantização são possíveis. Falha de ranking não deve bloquear o perfil. Não existe reset automático de ranking nesta versão.

Missões usam dias UTC. Eventos são derivados de timestamp UTC: 15 minutos a cada duas horas, alternando Coins, Luck, Gems e Exclusive. Não dependem de timer de um servidor específico. Minerar durante evento também concede Gems; Exclusive tem chance de 0,2% de pet de evento por cristal. Mensagens Mythical/Secret usam MessagingService quando disponível e sempre aparecem no servidor local.

## Desempenho e arte

280 cristais, 14 titãs e 14 ilhas ancoradas, sem física por frame; scheduler compartilhado de 0,15 s, cooldown autoritativo. Interface recebe status a cada dois segundos e atualizações após ações. Inventário só é reenviado quando UIDs ou equipamento mudam. Pets são cosméticos locais (até 9) e não criam física; outros jogadores não veem esses seguidores nesta versão. Partículas e luzes têm vida curta e são removidas por Debris. A UI usa Activated, raycast de mouse/toque e atalhos de gamepad, com menu rolável. Verifique telas pequenas e safe areas nos emuladores.

Modelos de cristais, picareta e pets são gerados como geometria básica. As 104 espécies de pets têm identidades e multiplicadores próprios, usam corpos geométricos com olhos, orelhas, asas/coroas por raridade e cores por mundo/variante. Upgrades mudam estatísticas e a cor/material da picareta; o modelo visual básico é compartilhado. O projeto não promete métricas de retenção ou receita: ajuste balanceamento com testes reais, sem ocultar chances e com confirmação oficial de compras.

## Conteúdo, migração e interface Cosmic Horizons

`Content` recebe a API de `Game` por inicialização explícita, evitando dependência circular. `Progression` contém operações puras usadas pelo servidor: custo de upgrade, capacidade, streak, seleção de fusão e potência das variantes. Campos novos são adicionados ao perfil v1; pets antigos recebem Tier=0 e descobertas são reconstruídas do inventário. Rebirth mantém upgrades, conquistas e coleção.

Fusão seleciona três UIDs correspondentes e desequipados, verifica Gems antes de mutar, consome os três e cria uma variante. Golden multiplica os BÔNUS do pet em 2,5; Cosmic em 6,25. O multiplicador total continua aditivo entre pets. A fusão não usa sorte e não cria uma nova espécie no atlas. Cada primeira descoberta e conquista pode ser resgatada uma vez. Presentes de sessão usam relógio do servidor; reconectar reinicia o cronômetro dessa sessão. Presente diário usa dia UTC, streak de sete dias e reset de sequência quando se perde um dia.

Titãs têm 100x HP, não ocupam mochila e guardam contribuição de dano no servidor até a morte. Somente jogadores conectados com perfil gravável recebem Coins proporcionais à contribuição e Gems (mínimo de cinco antes do multiplicador). Não se paga novamente após HP zero. Ao respawn, contribuições são zeradas. Combos são contados por cristal destruído em até oito segundos e limitados a 20, aumentando Coins até 50%.

Mochila pode chegar a 180 espaços por upgrades gratuitos. Até +3 slots gratuitos de Gems se acumulam com os +3 do passe, totalizando nove pets. O cliente pagina inventário em 24 itens; HUD, menus e prompts usam palavras e benefícios claros. `Sync` sempre envia inventário completo, mesmo quando o primeiro snapshot chegou antes do listener do cliente.

`tools/bake_map.py` executa o gerador real com construtores de geometria simulados e exporta a cena para o place. Confere 14 mundos, 294 cristais/titãs e importa o XML pelo leitor nativo do Rojo para validar o formato. Esse preview não executa física nem prova renderização no Roblox. O servidor destrói apenas `Workspace.UniverseMap` e reconstrói o mapa em Play para registrar prompts, atributos e HP.

## Geometria, ferramentas e apresentação

`Art` produz especificações puras (tamanhos, poses, cores) para ferramentas, pets e landmarks. `Models` instancia essas especificações; os mesmos dados alimentam equipamento, expositores e retratos. Gear cria um Tool Roblox com Handle direto e peças unidas por WeldConstraint, com CanBeDropped=false. Atualizações não duplicam a ferramenta. O servidor mantém índice/dano/cooldown autoritativos; a animação usa toolanim=Slash do Animate padrão Roblox. A UI oculta o Backpack padrão e oferece navegação própria.

Viewports são estáticos nas galerias. Os seguidores mantêm um corpo ancorado e peças unidas; closing/desequip remove o Model inteiro. Avatares do ranking usam rbxthumb com o ID real retornado pelo OrderedDataStore. Config de imagem 2D é opcional e aceita somente assets publicados/autorizados pelo criador.

Top Global: SurfaceGui na praça e menu compartilham Cache/Available do servidor. Score histórico usa UpdateAsync(max(old,novo)); Gems usa SetAsync do saldo atual. API indisponível deixa entradas anteriores em cache e marca como indisponível. Sem entradas, exibe traços e texto de status. Nenhum ranking local se apresenta como global.

A referência solicitada foi interpretada como clareza visual de praça, vitrines e galerias; o link específico de “Roube um Ovo” não foi fornecido nesta atualização. Os modelos/cores desta versão são originais e mantêm o loop de mineração.
