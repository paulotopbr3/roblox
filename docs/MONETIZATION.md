# Configurar uma loja funcional

1. Publique uma experiência privada no Roblox Studio: File → Publish to Roblox.
2. No [Creator Dashboard](https://create.roblox.com/dashboard/creations/experiences), abra essa experiência e cadastre os passes e developer products. Escolha preços e imagens próprios. IDs não são preços.
3. Copie cada ID para `C.Passes.<nome>` ou `C.Products.<nome>.Id` em `src/shared/Config.luau`. Os IDs devem pertencer à experiência e estar disponíveis para venda. Cada ID de produto deve ser único.
4. Gere o place novamente com `python3 tools/check.py` e publique a versão atualizada na MESMA experiência. O gamepass é consultado no login e ao concluir uma compra. O preço é consultado no Marketplace; o valor mostrado é referência, e o prompt oficial determina o preço final, inclusive ajustes regionais.
5. Execute os testes de compra no ambiente privado, incluindo recibo repetido, salvamento indisponível, produto desconhecido e reentrada. Nunca confirme um recibo cujo perfil ainda não foi salvo.

A UI separa passes permanentes e produtos repetíveis; usa categorias Progressão, Pets e Conforto; mostra benefícios e estado adquirido; ofertas com ID zero ficam desativadas. Não inventa preços, descontos, promoções ou contadores de escassez. Saldo baixo nunca abre um prompt de compra automaticamente. A ação de comprar é sempre explícita, seguida da confirmação oficial do Roblox.

## IDs dos passes

| Chave | Benefício |
|---|---|
| DoubleCoins | 2x Coins ganhas |
| DoubleLuck | 2x pesos de raridades Rare ou superiores, com normalização |
| DoubleGems | 2x Gems ganhas; não altera pacotes comprados |
| AutoMine | Mineração automática próxima, com botão para desligar |
| AutoSell | Venda automática; venda manual continua gratuita |
| InfiniteBackpack | Remove limite de cristais da mochila |
| VIP | Lounge AFK VIP 3x |
| FastHatch | Cooldown de ovo de 3 s para 1 s |
| TripleHatch | 3 ovos por ação, pagando cada abertura |
| TeleportAllWorlds | Dispensa Coins e sequência; mantém requisito de rebirth |
| ExtraPetSlots | +3 slots, acumuláveis com até +3 slots conquistados com Gems |
| Magnet | Alcance de mineração de 24 para 55 studs |
| ExclusivePets | Royal Star uma vez, com direito persistido |
| InstantRebirth | Pula confirmação extra; mantém custo e resets |
| PremiumAFK | 2x recompensas AFK |

Produtos: Gems50/500/5000, Luck15/30, Coins15/30, Eggs10/100 e WeeklyPet. Créditos de ovos são usados no pedestal, substituem Coins e têm chances exibidas antes da abertura; não representam um pet específico. WeeklyPet entrega diretamente Weekly Supernova. Boosts usam tempo real, inclusive offline.

Para trocar a oferta semanal, crie outro produto com ID distinto e mantenha as antigas configurações para processar recibos pendentes. Não reatribua um ID existente a um benefício diferente.

## Crescimento e apresentação

O jogo já inclui convite oficial de amigos no Guia (quando permitido pelo Roblox), titãs cooperativos, coleção, tutorial, presentes, missões e conquistas. Prepare ícone e thumbnails com capturas reais da versão final no Studio, descrição clara e imagens dos benefícios na loja. Teste a experiência privada com jogadores antes de abrir ao público; acompanhe início do tutorial, primeiras vendas/upgrades, tempo para o segundo mundo, abandono e desempenho. Nenhum sistema garante público, diversão ou receita.
