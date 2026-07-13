---
title: Política de Privacidade
description: O live.tips não tem contas, não tem cookies, não tem análises nem rastreio. Aqui fica a lista curta do que é efetivamente tratado, por quem e durante quanto tempo.
updated: 2026-07-13
updated_label: Última atualização em 13 de julho de 2026
---

O live.tips é um frasco de gorjetas open source para artistas. É gerido por **Nikita Rabykin**,
um programador individual, não uma empresa. Se alguma coisa aqui em baixo lhe interessar,
escreva para **[contact@live.tips](mailto:contact@live.tips)** — esse endereço chega a uma pessoa.

Esta política é honesta quanto às partes aborrecidas. Preferimos dizer «guardamos o seu
nome durante um máximo de uma hora» a afirmar que não guardamos nada e estar errados.

## A versão curta

- **Sem contas.** Não há nada para registar.
- **Sem cookies.** Nem um, em lado nenhum.
- **Sem análises, sem rastreio, sem publicidade, sem scripts de terceiros** neste site.
- **Nunca tocamos no seu dinheiro.** As gorjetas vão diretamente do fã para a conta
  Stripe, Revolut, MobilePay ou Monzo do próprio artista. Não estamos nesse caminho.
- **Na configuração predefinida, a app comunica apenas com o Stripe** — com nenhum
  servidor live.tips.
- O único servidor que sequer mantemos é um pequeno relé, e só existe se um artista
  ativar o Revolut, o MobilePay ou o Monzo.

## Este site

O site é estático e está alojado no **GitHub Pages**. Enquanto alojamento, o GitHub recebe
o endereço IP e o user-agent do navegador de todas as pessoas que carregam uma página —
isto é o registo comum de um servidor web, acontece antes de qualquer código nosso correr
e não o podemos desligar. O GitHub trata esses dados ao abrigo da sua própria
[declaração de privacidade](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement).
Não lemos esses registos e o GitHub não nos os mostra.

Para além disso, as páginas que está a ler não carregam **nada de mais ninguém**: as
fontes, os ícones e as imagens são servidos pelo próprio live.tips. Não há Google
Analytics, não há gestor de etiquetas, não há píxel, não há widget incorporado.

O site guarda **dois valores no `localStorage` do seu navegador**, ambos definidos por si,
ambos legíveis apenas por este site, e nenhum deles é alguma vez enviado seja para onde for:

| Chave | O que memoriza |
| --- | --- |
| `lt-landing-theme` | se escolheu cores claras, escuras ou automáticas |
| `lt-langbar-dismissed` | que fechou o banner «também disponível no seu idioma» |

Limpar o armazenamento do navegador apaga-os. Não são cookies, não são partilhados e não
identificam ninguém.

## A app

A app live.tips corre **no dispositivo do próprio artista**. Tudo o que sabe vive aí:

- A **chave restrita do Stripe** é guardada no porta-chaves do dispositivo (Keychain do
  iOS/macOS, Keystore do Android) e só é enviada para `api.stripe.com`.
- O **histórico de gorjetas, o histórico de sessões, a meta e as definições da app** são
  guardados no armazenamento local do dispositivo. Isto inclui os nomes e as mensagens que
  os fãs juntam às suas gorjetas.
- Desinstalar a app apaga tudo isso. Não há cópia de segurança na nuvem do nosso lado,
  porque não há nuvem nenhuma do nosso lado.

**Nunca recebemos nada disto.** A app não traz nenhum SDK de análise, nenhum relator de
falhas, nenhuma notificação push e nenhum código publicitário — nenhum, nem sequer
desativados.

Dois esclarecimentos, para que a afirmação «não comunica com ninguém» continue exatamente
verdadeira:

- A app procura as **taxas de câmbio** uma vez por dia em APIs públicas de taxas
  (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). São simples pedidos de
  uma lista pública de taxas. Não transportam qualquer informação sobre si, sobre o artista
  ou sobre qualquer gorjeta — mas, como qualquer pedido web, revelam o seu endereço IP a
  esses serviços.
- Se usar a **versão para navegador** da app, o seu navegador transfere-a do nosso
  alojamento estático (ver *Este site*, acima).

## Stripe

Quando um fã paga com cartão, está na página de pagamento da **Stripe**, não na nossa. A
Stripe recolhe e trata os dados de pagamento como responsável pelo tratamento independente,
ao abrigo da [Política de Privacidade da Stripe](https://stripe.com/privacy). Nunca vemos
números de cartão e não temos acesso à conta Stripe do artista.

A app do artista lê as suas próprias gorjetas no Stripe usando a chave restrita do próprio
artista. O nome e a mensagem de um fã, se tiver deixado algum, viajam da Stripe para o
dispositivo do artista e param aí.

## O relé — apenas se o Revolut, o MobilePay ou o Monzo estiverem ativados

As configurações apenas com Stripe nunca tocam nisto e podem parar de ler aqui.

O Revolut, o MobilePay e o Monzo não oferecem qualquer forma de uma app confirmar que um
pagamento aconteceu, por isso essas gorjetas passam por um pequeno relé open source que
mantemos na **Cloudflare**, em `api.live.tips`. Nunca toca no dinheiro. Aqui está tudo o
que ele trata.

### O que o artista guarda

Criar uma página de gorjetas guarda o **nome público do artista, a sua mensagem pública, a
sua moeda e os identificadores de pagamento que escolheu publicar** (o seu link de pagamento
Stripe, o nome de utilizador Revolut, o Box ID do MobilePay, o nome de utilizador Monzo).
Tudo isto é informação que o artista está deliberadamente a publicar para os fãs, de
qualquer forma.

- **Conservação: apagado automaticamente após 90 dias de inatividade.**
- O artista pode apagá-la **imediatamente** a partir da app, a qualquer momento.
- Nunca é recolhido qualquer endereço de e-mail, palavra-passe, nome legal ou dados
  bancários.

### O que um fã envia

O formulário de gorjeta pede um **valor** e, opcionalmente, um **nome** e uma **mensagem**.
É esse o formulário todo. Sem e-mail, sem número de telefone, sem conta.

- Se o ecrã do artista estiver **online**, a gorjeta é passada diretamente para ele e
  **nunca é escrita em disco**.
- Se o ecrã do artista estiver **offline** — telemóvel bloqueado, sem rede — a gorjeta é
  **guardada durante um máximo de uma hora** para não se perder pura e simplesmente, e é
  depois entregue no momento em que o ecrã se voltar a ligar. Se ninguém se voltar a ligar,
  é **apagada sem ser vista**. Este é o único texto escrito por um fã que o relé alguma vez
  guarda, e uma hora é o seu limite absoluto.
- O seu nome e a sua mensagem também são colocados na **nota de pagamento** que abre no
  Revolut, no MobilePay ou no Monzo — é assim que o artista sabe quem deu a gorjeta. Essas
  empresas tratam depois esses dados ao abrigo das suas próprias políticas de privacidade.
- O relé não guarda **nenhum histórico de gorjetas**. Não pode mostrar-lhe a si, a nós nem
  a mais ninguém uma lista de quem deu gorjeta a quem.

### Endereços IP e combate ao abuso

Um formulário aberto para o qual qualquer pessoa pode submeter precisa de alguma proteção
contra bots, por isso:

- O seu endereço IP é usado para **limitar o número de pedidos** e é enviado para a
  **Cloudflare Turnstile** (uma verificação anti-bot que corre na página de gorjetas) para
  confirmar que não é um bot. A Turnstile é um produto da Cloudflare e é usada em vez de um
  CAPTCHA que o traça.
- Para impedir que alguém crie milhares de páginas de gorjetas, é guardado um **hash
  criptográfico do IP** de quem cria uma, durante cerca de **duas horas**, e depois é
  descartado.
- Os **registos operacionais da Cloudflare** guardam os detalhes técnicos dos pedidos ao
  relé — URL, tempos, estado — durante alguns dias. Não contêm nomes nem mensagens de fãs.
  A Cloudflare atua como nosso subcontratante; consulte a
  [Política de Privacidade da Cloudflare](https://www.cloudflare.com/privacypolicy/).

### Contadores

O relé conta **quantas gorjetas** uma dada página de gorjetas retransmitiu, para podermos
detetar abusos e saber se a coisa é sequer usada. É um número. Não contém dados de fãs.

## Fundamento jurídico, se precisar de um (RGPD)

- Manter o relé a funcionar para um artista que o ativou, e entregar a gorjeta de um fã ao
  ecrã a que se destinava: **execução de um serviço que solicitou**.
- Limitação de pedidos, Turnstile e quotas por IP com hash: **interesse legítimo** em
  impedir que um serviço gratuito e aberto seja destruído por bots e fraude.
- Registos do servidor: **interesse legítimo** em operar e proteger o serviço.

## Os seus direitos

Pode pedir-nos uma cópia, a correção ou a eliminação de tudo o que tenhamos sobre si, e
pode apresentar queixa à autoridade nacional de proteção de dados do seu país. Escreva para
**[contact@live.tips](mailto:contact@live.tips)**.

Na prática, a maior parte disso já está nas suas mãos: os artistas podem apagar a sua página
de gorjetas na app instantaneamente, as gorjetas dos fãs evaporam-se dentro de uma hora, e
tudo o resto vive no seu próprio dispositivo.

## Crianças

O live.tips não se dirige a crianças e não tratamos conscientemente os seus dados.

## Alterações

Atualizaremos esta página quando o software mudar. Como todo o projeto é open source,
**todas as versões anteriores desta política estão no histórico público do git** — pode ver
exatamente o que mudou e quando.

## Idioma

Esta política é publicada em todos os idiomas que o site suporta, por conveniência. Se uma
tradução e a versão em inglês divergirem, **a versão em inglês é a que conta**.
