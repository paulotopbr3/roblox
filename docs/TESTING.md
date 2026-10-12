# Validação antes do lançamento

## Verificado no Linux

`python3 tools/check.py` compila 11 arquivos Luau (10 de runtime + 1 teste), executa 12 testes e monta o `.rbxlx`. Os testes exercitam os módulos efetivamente utilizados pelo servidor: catálogo, limites de progressão, fronteiras e distribuição de raridade, créditos/capacidade dos ovos, recibos repetidos, quantidade fixa de Gems, extensão dos boosts, slots e IDs. Isso não executa as APIs do motor Roblox.

## Roblox Studio — execução obrigatória

Use uma experiência privada separada, DataStore `UniverseMiner_test_v1`, IDs de teste e **Test → Start** com dois jogadores. Abra Output e verifique que nenhum erro de script aparece. Não execute testes destrutivos contra dados de produção.

1. **Entrada e mapa:** confirmar as 10 ilhas, 200 cristais, ovo, venda e AFK; jogador nasce em Starter e respawn volta ao mundo selecionado. UI aparece depois de carregar.
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
