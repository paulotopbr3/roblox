# Universe Miner Simulator

Implementação Roblox em Luau com mapa procedural e interface gerada por scripts. Inclui 14 mundos, 56 picaretas, 98 pets de ovos + 6 especiais, mochila e venda, rebirths, missões diárias, AFK/VIP, eventos, códigos, rankings, DataStore e integração Marketplace.

## Abrir e jogar

1. Abra `UniverseMiner.rbxlx` no **Roblox Studio** (Windows/macOS). O arquivo é gerado pelo build e não versionado; execute o passo abaixo se não estiver disponível.
2. Pressione **Play**. O mapa já é visível no editor; os sistemas e a interface iniciam em Play. Ande até os cristais e clique/toque neles, ou segure **MINERAR** / R2.
3. Venda a mochila pelo botão **Vender** / Y ou pelo pedestal de venda. Compre a próxima ferramenta em **Picaretas**, upgrades permanentes em **Gems Lab**, mundos em **Mundos** e ovos em **Ovos**, perto do pedestal amarelo.
4. Siga o **Guia**, equipe pets em **Pets**, resgate **Presentes**, registre a **Coleção** e complete **Missões**. Os códigos são `WELCOME`, `UNIVERSE` e `COSMIC`.

## Desenvolver

Com [Rojo 7.5.1](https://rojo.space/docs/v7/getting-started/installation/) instalado:

```sh
rojo build default.project.json -o UniverseMiner.rbxlx
# Alternativa: rojo serve e plugin Rojo no Studio para sincronização
```

No ambiente Linux, `bash tools/bootstrap.sh` prepara Rojo 7.5.1 e Luau 0.695 fora do checkout; depois execute `python3 tools/check.py`. O bootstrap preserva TLS, verifica o SHA-256 do pacote Rojo e o commit do Luau. Não instala o Roblox Studio: o motor não roda neste ambiente Linux.

## Configurar e publicar

- Publique primeiro uma experiência **privada de teste**. Para testar persistência no Studio, habilite *Game Settings → Security → Enable Studio Access to API Services* nela. Use nome de DataStore distinto da produção.
- Em `src/shared/Config.luau`, coloque os IDs reais dos 15 gamepasses e 10 developer products da experiência. IDs zero desativam as ofertas; preços aparecem na confirmação oficial do Roblox.
- Configure os IDs de áudio autorizado em `SoundIds` e `MusicId`; os efeitos usam um som curto incluído no Roblox como fallback. Música é opcional e fica desativada sem ID.
- Atualize `Products.WeeklyPet.Pet` para trocar a oferta semanal; a configuração atual oferece Weekly Supernova. Não remova IDs de produtos com recibos pendentes.
- Execute o [roteiro de testes no Studio](docs/TESTING.md) antes de liberar o jogo.

Sem DataStore disponível, **somente no Studio** é permitida uma sessão temporária, indicada na tela. Em produção, falha de carregamento impede a entrada para proteger dados. O ambiente Linux validou compilação, 33 verificações da economia, inicialização e gameplay com APIs simuladas, compilação e build do place com geometria exportada e importada pelo Rojo; motor Roblox, controles, persistência e pagamentos ainda exigem validação no Studio.

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `src/shared` | Catálogos, fórmulas e operações puras de economia |
| `src/server` | Mapa, mineração, persistência, compras e rankings |
| `src/client` | UI responsiva, controles, pets e efeitos locais |
| `tests` | Testes executáveis no Luau CLI |
| `tools` | Instalação e validação reproduzíveis |
| `docs` | Arquitetura, configuração e testes de lançamento |

Todos os RemoteEvents são criados pelo servidor. O cliente envia intenções; o servidor calcula dano, recompensas, sorte, custos e inventário. Arte e mapa são procedurais; modelos finais, trilha sonora, ícone e thumbnails podem ser adicionados sem substituir a arquitetura.

## Baixar pelo GitHub

No repositório, use **Code → Download ZIP**, extraia e abra `UniverseMiner.rbxlx` no Roblox Studio. A versão anterior do README foi preservada em `docs/README-anterior.txt`.

## Se o mapa não aparecer

Baixe o ZIP atualizado, extraia em uma pasta nova e abra `UniverseMiner.rbxlx`; clique em **Play (F5)**. O novo arquivo contém um preview do mapa em edição; HP, interação e menus iniciam em Play. A inicialização tolera DataStore indisponível em arquivos ainda não publicados no Studio, usando dados temporários. Se aparecer um aviso de falha, abra **View → Output** e copie a primeira mensagem vermelha para diagnóstico.

## Novidades Cosmic Horizons

[Todas as novidades](docs/CHANGELOG.md): titãs cooperativos, combos, pet inicial, tutorial, presentes diários, 16 conquistas, fusão Golden/Cosmic, coleção, Gems Lab e loja redesenhada. O guia de [monetização](docs/MONETIZATION.md) explica como cadastrar IDs e preços reais.

Para gerar também o preview do mapa em edição, use `python3 tools/check.py`. O build direto do Rojo mantém os scripts que geram o mapa durante Play.
