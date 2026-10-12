# Validação antes do lançamento

## Verificado no Linux

`python3 tools/check.py` compila 19 arquivos Luau (17 de runtime + 2 testes), executa 12 testes e monta o `.rbxlx`. Os testes exercitam os módulos efetivamente utilizados pelo servidor: catálogo, limites de progressão, fronteiras e distribuição de raridade, créditos/capacidade dos ovos, recibos repetidos, quantidade fixa de Gems, extensão dos boosts, slots e IDs. Além disso, cinco verificações executam os módulos reais de Data/Rankings e o bootstrap com serviços simulados que recusam acesso ao DataStore: ausência de aquisição no carregamento, fallback temporário no Studio, recusa segura em produção, rankings não fatais e chegada à geração do mapa. Isso não executa as APIs do motor Roblox.

## Roblox Studio — execução obrigatória

Use uma experiência privada separada, DataStore `UniverseMiner_test_v1`, IDs de teste e **Test → Start** com dois jogadores. Abra Output e verifique que nenhum erro de script aparece. Não execute testes destrutivos contra dados de produção.

1. **Entrada e mapa:** confirmar as 14 ilhas, 280 cristais e 14 titãs, ovo, venda e AFK; jogador nasce em Starter e respawn volta ao mundo selecionado. UI aparece depois de carregar.
2. **Mineração:** clicar/toque/R2 a menos de 24 studs causa dano; longe não causa. Dois jogadores atacando o mesmo cristal recebem uma única recompensa ao destruir; HP zera e reaparece após 5 s. Raro paga 8x. Nenhum saldo muda ao enviar IDs inexistentes, NaN ou mundo diferente.
3. **Mochila:** após 30 destruições, não causa mais dano até vender. Botão e plataforma SELL convertem o valor apenas uma vez. Auto Sell vende automaticamente; Infinite Backpack permite continuar depois de 30. Compare o saldo esperado no painel.
4. **Ferramentas e mundos:** testar compra com saldo insuficiente/suficiente; upgrade reduz cooldown e aumenta dano. Mundos comuns exigem sequência e Coins; Void/Heaven exigem 2/4 rebirths. Passe TeleportAllWorlds ainda exige esses rebirths. Saldo nunca fica negativo com cliques rápidos.
5. **Ovos/pets:** longe do ovo não abre; perto desconta Coins, respeita cooldown e capacidade. Abra 1 e 3 com/sem o passe; créditos substituem Coins e não criam aberturas extras. Equipar/desequipar muda multiplicadores, Equip Best escolhe os maiores. Excluir equipado é recusado, excluir desequipado exige confirmação na UI. Veja probabilidades com Luck ativa. Teste Legendary/Mythical/Secret em cópia local de desenvolvimento com pesos temporariamente controlados e restaure a configuração antes de publicar.
6. **Rebirth:** saldo insuficiente recusa; saldo suficiente reinicia apenas Coins, mochila, tool, worlds. Preserva pets/Gems/configurações; aumenta Rebirths e multiplicador e concede Gems. Repetir confirma custo maior. InstantRebirth pula só confirmação.
7. **Missões/códigos:** cumprir e resgatar cada missão; repetir não duplica. Verificar reset em dia UTC seguinte em teste controlado. WELCOME e UNIVERSE só resgatam uma vez e continuam usados após relogin. Missão com pet e inventário cheio não marca como resgatada.
8. **AFK/eventos:** ficar nas zonas por 30 s; VIP sem passe não recebe bônus. Fora da zona não recebe. PremiumAFK dobra. Reduza EventPeriod/Duration apenas na experiência de teste para conferir Coins/Luck/Gems/Exclusive, countdown e sincronização entre dois servidores; depois restaure.
9. **Salvamento:** habilitar APIs na experiência de teste e conferir aviso temporário ausente. Ganhar Coins/Gems/pets, comprar ferramenta/mundo, alterar settings, sair e reentrar. Verificar retenção. Testar perfil aberto em outro servidor, falha de save e encerramento de servidor. Com API indisponível no Studio deve avisar temporário; em produção deve recusar entrada, nunca substituir perfil por vazio.
10. **Compras:** configure IDs reais de teste, conferindo título/preço no prompt. Use o fluxo de teste suportado pelo Roblox para ProcessReceipt, verifique entrega e persistência. Simule repetição do MESMO PurchaseId e falha de save entre grant e confirmação em ambiente de teste: entrega uma vez e só confirma após save. Produto desconhecido retorna NotProcessedYet; usuário offline aguarda. Verifique ExclusivePets uma vez após cada relogin.
11. **Rankings/anúncios:** com DataStore habilitado, duas contas geram entradas; compare totais/saldo e cache de até 180 s. MessagingService anuncia pet raríssimo em outro servidor; se indisponível, anúncio local continua funcionando.
12. **Dispositivos/performance:** emulador de celular em retrato/paisagem, tablet, PC e gamepad. Navegar todas as telas, scroll de 400 pets, campo de código, confirmação de rebirth e exclusão; R2/Y/X/B. Testar safe areas e legibilidade. Effects OFF remove efeitos e sons; Music OFF silencia áudio configurado. Use MicroProfiler/Stats com vários clientes e confirme limpeza de efeitos e respawns.

## Publicação

Somente depois dos testes acima: IDs e áudio autorizados, chances conferidas, configuração de produção separada, ícone/thumbnails/descrição, classificação de conteúdo e privacidade da experiência revisadas no Creator Dashboard. O repositório não publica a experiência nem cria produtos automaticamente.

## Novos testes Cosmic Horizons no Studio

- Ver o mapa em edição e iniciar Play; conferir que não existem duas cópias de UniverseMap. E/X/toque abre menu das estações. Cristais, vitrine e decoração devem aparecer com as cores corretas.
- Novo perfil recebe Orbit Buddy uma vez, mais o guia. Resgatar cinco etapas sem pular/repetir recompensa. Testar cliente lento conectando após o primeiro snapshot.
- Gems Lab cobra custo correto, limita níveis, aumenta dano/Coins/mochila/slots e preserva tudo após rebirth e relogin.
- Fusão consome somente três pets iguais desequipados; saldo insuficiente não consome; excluir e fundir pedem confirmação. Golden/Cosmic aumentam os bônus corretos e aparecem no preview do ovo/seguidores. Pet de produção antigo permanece Normal.
- Presente diário somente uma vez por dia UTC, continuidade e reset de streak, dia sete com Aurora Guardian, inventário cheio. Presente de sessão somente após tempo real do servidor, sem replay.
- Atlas concede Gems uma vez por espécie, conserva descoberta após excluir/fundir; fontes de pets especiais devem estar claras. Conquistas não resetam no rebirth.
- Dois jogadores derrotam titã; conferir proporção dos Coins, Gems mínimos, pagamento único, jogador desconectado sem grant e contribuições zeradas após respawn. Mochila cheia não bloqueia titã. Combo expira em oito segundos e nunca ultrapassa +50%.
- Loja com IDs reais: confirmar preços de referência, preço final oficial, benefícios, passes adquiridos, categoria e produto repetível. IDs zero desativam o botão; cancelar compra não concede nada. Não pressionar jogador a comprar quando está sem Coins/Gems.
- Emuladores em retrato/paisagem, com nove pets, inventário cheio/paginado, diferentes tamanhos de tela e controle. Conferir contraste, marcador de tutorial, Highlight, viewport de ovo e ReducedMotion. Convites dependem de experiência publicada e elegibilidade Roblox.

Os testes automáticos agora incluem 12 de economia, cinco de inicialização e 16 de gameplay com serviços simulados. A exportação/importação de mapa verifica estrutura/serialização. Nenhum deles substitui a execução no motor Roblox.

## Verificações Crystal Isles

Automatizadas: cinco testes de arte percorrem as 56 picaretas, 104 espécies × três variantes e 14 landmarks. O harness do mapa executa Gear.update real para conferir Handle, transferência de peças, re-equip, ausência de duplicatas e upgrade. Executa ainda quatro tabelas com dez posições cada e verifica estados de indisponibilidade. O harness de interface constrói os 17 menus REAIS com instâncias/serviços substituídos, confirma ViewportFrames, avatares e execução do resize mobile. Quatro checks de ranking validam ordem, encode, caches e proteção de scores históricos contra gravações atrasadas. Esses testes não renderizam pixels nem simulam física do Roblox.

No Studio:

1. Novo perfil nasce segurando Wood Pickaxe. Comprar a próxima ferramenta muda corpo, nome e cor imediatamente. Rebirth equipa Wood novamente. R6/R15, morte/respawn e diferentes rigs devem manter um Handle e uma ferramenta. Confirmar golpe/alcance, hotbar padrão oculto e botões sem sobreposição.
2. Conferir todas as imagens de pets: olho, orelha/asa, cores, variantes, silhouette da coleção não descoberta e thumbnail dos sete pets de cada ovo. Nenhuma peça do pet fica perdida ao trocar equipamento ou fechar viewport. Testar opcionais C.PetImages/ToolImages/WorldImages com assets autorizados e sem eles.
3. Galerias em duas colunas no celular e quatro no desktop: textos, nomes longos, espaços, foco de gamepad e rolagem. Na orientação horizontal, verificar altura útil dos menus e ausência de menus ocultos pela navegação.
4. Abrir Mais → Top Global e navegar quatro categorias. Com DataStore habilitado, comparar tabela de menu com painéis na praça, verificar score atualizado e avatar. Sem API, nenhum jogador fictício deve aparecer. Após falha, verificar indicação de resultado antigo. Coins/Pets são históricos e Gems são saldo.
5. Passear nos 14 mundos: landmarks não bloqueiam trajetos de mineração; portais, vitrines, lagoas e jardim apresentam cores corretas. Map preview em edição não duplica o mapa ao iniciar. Confirmar que só depósitos vivos entram no raycast.
6. MicroProfiler e estatísticas de render com seis/nove pets, 24 retratos e várias contas. Conferir quedas de FPS, latência e memória após abrir/fechar galerias muitas vezes. Ajustar density de cenário e viewports conforme dispositivos reais.
