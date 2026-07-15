---
title: Política de Privacidade
description: O live.tips não tem cookies, não tem análises nem rastreio, e funciona sem conta nenhuma. Se optar por iniciar sessão, aqui fica exatamente o que é guardado, onde, por quem e durante quanto tempo.
updated: 2026-07-15
updated_label: Última atualização em 15 de julho de 2026
---

O live.tips é um frasco de gorjetas open source para artistas. É gerido por **Nikita Rabykin**,
um programador individual, não uma empresa. Se alguma coisa aqui em baixo lhe interessar,
escreva para **[contact@live.tips](mailto:contact@live.tips)** — esse endereço chega a uma pessoa.

Esta política é honesta quanto às partes aborrecidas. Preferimos dizer «guardamos o seu
nome durante o tempo que mantiver a banda» a afirmar que não guardamos nada e estar errados.

## A versão curta

- **A conta é opcional.** A app funciona sem conta nenhuma, e isso continua a ser a
  predefinição. Se quiser as suas bandas e o seu histórico num segundo dispositivo, pode
  iniciar sessão — e então parte disso fica guardado num servidor, e mais do que antes. O
  que é o quê está explicado em baixo.
- **Sem cookies.** Nem um, em lado nenhum.
- **Sem análises, sem rastreio, sem publicidade, sem scripts de terceiros** neste site.
- **Nunca tocamos no seu dinheiro.** As gorjetas vão diretamente do fã para a conta
  Stripe, Revolut, MobilePay ou Monzo do próprio artista. Nunca há qualquer saldo live.tips.
- **Sem conta, a app comunica apenas com o Stripe** — com nenhum servidor live.tips. Se
  iniciar sessão, isso muda: a sua chave Stripe passa para o nosso servidor e a Stripe
  comunica-nos as suas gorjetas, para que as possamos colocar nos seus outros dispositivos.
  Esse é o custo honesto de iniciar sessão, e está exposto por completo em baixo.
- **As notificações push são novas, opcionais e apenas para contas com sessão iniciada.**
  Nada é enviado para um dispositivo que nunca as ativou, e um dispositivo sem conta nunca
  recebe nenhuma.
- Os servidores que mantemos estão na Firebase, da Google. Só existem se um artista ativar
  o Revolut, o MobilePay ou o Monzo — ou se iniciar sessão.

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

## A app tem dois modos, e a diferença entre eles é toda a história

Tudo o que se segue depende de uma pergunta: **iniciou sessão?**

### Modo um — sem conta. Continua a ser a predefinição, continua igual.

A app corre **no dispositivo do próprio artista**, e tudo o que sabe vive aí:

- A **chave restrita do Stripe** é guardada no porta-chaves do dispositivo (Keychain do
  iOS/macOS, Keystore do Android) e só é enviada para `api.stripe.com`.
- O **histórico de gorjetas, o histórico de sessões, a meta, a lista de pedidos de música e
  as definições da app** são guardados no armazenamento local do dispositivo. Isto inclui os
  nomes e as mensagens que os fãs juntam às suas gorjetas.
- Desinstalar a app apaga tudo isso. Não há cópia de segurança na nuvem do nosso lado,
  porque, neste modo, não há nuvem nenhuma do nosso lado.

**Nunca recebemos nada disto.** A app não traz nenhum SDK de análise, nenhum relator de
falhas e nenhum código publicitário — nenhum, nem sequer desativados. (As notificações push
existem, mas são uma funcionalidade de sessão iniciada e estão desligadas até que as ative —
ver *Modo dois*. Um dispositivo sem conta nunca recebe nenhuma.)

Dois esclarecimentos, para que a afirmação «não comunica com ninguém» continue exatamente
verdadeira:

- A app procura as **taxas de câmbio** uma vez por dia em APIs públicas de taxas
  (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). São simples pedidos de
  uma lista pública de taxas. Não transportam qualquer informação sobre si, sobre o artista
  ou sobre qualquer gorjeta — mas, como qualquer pedido web, revelam o seu endereço IP a
  esses serviços.
- Se usar a **versão para navegador** da app, o seu navegador transfere-a do nosso
  alojamento estático (ver *Este site*, acima).

### Modo dois — iniciou sessão. Então alguns dados saem do dispositivo, de propósito.

Iniciar sessão é um ato deliberado. Nada inicia sessão por si, e nada na app deixa de
funcionar se nunca o fizer. Inicia sessão porque quer um segundo dispositivo: o telemóvel no
bolso e o tablet em palco a mostrarem a mesma noite, as mesmas bandas, o mesmo histórico.

Isso só funciona se um servidor os guardar. **Por isso guarda, e esse é o custo honesto do
segundo dispositivo.**

O servidor é a **Firebase**, que é a Google. Há três formas de ter uma conta:

- **Iniciar sessão com a Apple** ou **Iniciar sessão com a Google** — o Firebase Auth recebe
  aquilo que o fornecedor entregar: um id de utilizador (uid) e, normalmente, um endereço de
  e-mail e um nome. (Com a Apple pode esconder o seu e-mail; a Apple dá-nos então um endereço
  de reencaminhamento em vez dele, e entrega o seu nome apenas na primeiríssima vez que inicia
  sessão.)
- **Uma conta de convidado** — uma conta anónima sem e-mail e sem nome. Sincroniza e pode ser
  revogada, mas não há nada com que a recuperar se perder o dispositivo. É um uid e mais
  nada. Uma conta de convidado não pode usar a custódia da chave Stripe do lado do servidor
  nem as notificações push descritas em baixo, porque ambas precisam de uma conta que lhe
  possamos devolver.

Assim que inicia sessão, a conta ganha o seu próprio canto privado na base de dados **Cloud
Firestore** da Google, em `users/<your uid>/`. As regras de segurança atribuem esse canto a
esse uid **e a mais ninguém** — nenhuma outra conta o consegue ler, adivinhação de URLs
incluída. Lá dentro:

| O quê | Porque está lá |
| --- | --- |
| As suas **bandas** — nomes, definições do frasco de gorjetas e dos métodos de pagamento, texto do cartaz, metas, e a sua **lista de pedidos de música** | para que uma banda exista em todos os dispositivos em que iniciar sessão |
| As **definições da app**, incluindo as suas preferências de notificações | para que um dispositivo que acrescente já esteja configurado |
| Os **registos de sessões e o histórico de gorjetas** — incluindo **os nomes e as mensagens que os fãs juntam às suas gorjetas**, e qualquer **música que um fã tenha pedido** | porque esse histórico é exatamente aquilo que pediu para ver no outro dispositivo |
| A **sessão ao vivo** que está a decorrer neste momento | para que um segundo ecrã possa juntar-se ao concerto de hoje |
| Os seus **dispositivos** — o nome que cada um se dá a si próprio («iPhone do Nikita»), a sua plataforma e modelo, o seu idioma de interface, quando foi visto pela primeira e pela última vez, e (se ativou as notificações) um **token push** | para que Definições → Segurança os possa listar, para que uma notificação chegue ao dispositivo certo no idioma certo, e para que possa revogar um |
| Um pequeno **documento de perfil** — o nome de conta que escolheu, e qual o fornecedor que usou | para que o seletor de contas o possa identificar |
| Um **feed do sino** — uma lista limitada das gorjetas e pedidos de música recentes que chegaram enquanto não estava a decorrer nenhum concerto | para que possa pôr-se a par do que perdeu |

Agora a parte importante, sem rodeios: **sem conta, o nome e a mensagem de um fã nunca saem
do dispositivo do artista. Com conta, ficam guardados nos servidores da Google sob o uid do
artista, como parte do histórico sincronizado desse mesmo artista** e — como explicam as duas
secções seguintes — **é agora o nosso servidor que os escreve lá.** Nenhuma outra conta os
consegue ler, nós não olhamos para eles e nada é deduzido a partir deles — mas estão lá, e
ficam lá durante o tempo que a banda existir, e deve saber disso antes de iniciar sessão.

Terminar a sessão devolve o dispositivo ao modo local. Não apaga os dados da conta — ver
*Apagar coisas*, mais abaixo.

#### A sua chave Stripe, quando inicia sessão, passa para o nosso servidor

Esta é a maior mudança, e a que mais vale a pena ler.

**Sem conta, a sua chave restrita do Stripe nunca sai do seu dispositivo.** Isso é o Modo
um, e continua igual.

**Quando inicia sessão, ela sai — para nós.** A chave é cifrada (uma chave AES-256 por
segredo, ela própria envolvida pela Cloud KMS da Google) e guardada do lado do servidor num
sítio que **ninguém consegue voltar a ler — nem outra conta, nem sequer você.** Só é aberta
dentro das nossas Cloud Functions, usada para falar com a Stripe em seu nome, e nunca mais
entregue a um dispositivo.

Como a chave passa agora a viver connosco, **a Stripe comunica as suas gorjetas diretamente
ao nosso servidor**: registamos um webhook na sua própria conta Stripe, e a Stripe avisa esse
webhook de cada vez que uma gorjeta é paga. A nossa função escreve a gorjeta no histórico da
sua conta (ver em baixo). A sua app deixa de consultar a Stripe no caso de uma conta com
sessão iniciada; chega à Stripe apenas através de uma lista estreita e fixa de operações no
nosso servidor (criar o seu link de gorjetas, gerar um link de pedido de música e reler as
suas próprias gorjetas para reconciliação).

Portanto, dito sem eufemismos: **para uma conta com sessão iniciada há agora um servidor
live.tips no caminho entre a Stripe e o seu histórico.** Continuamos a nunca tocar no
dinheiro — uma gorjeta por cartão é criada na sua conta Stripe, é liquidada no seu saldo
Stripe e é paga segundo o seu calendário Stripe, exatamente como antes. O que mudou foi o
caminho dos *dados*, não o caminho do *dinheiro*. Se nunca iniciar sessão, nada disto se
aplica e a app continua a comunicar diretamente com `api.stripe.com` e com mais ninguém.

#### Acrescentar um dispositivo por código QR

Para acrescentar um dispositivo, mostra um código QR a partir de um dispositivo onde já tem
sessão iniciada. O código é aleatório, **de uso único, e expira em dois minutos**, e o
dispositivo novo não recebe nada até que toque em *confirmar* no antigo. Enquanto esse
aperto de mão está aberto, guardamos o código, o nome que o dispositivo novo se deu a si
próprio e a sua plataforma — e o registo é apagado quando expira. Um código QR fotografado
não serve de nada sem o seu toque de confirmação.

## Pedidos de música

Uma banda pode ativar os **pedidos de música**: os fãs escolhem então uma música da lista do
artista e, opcionalmente, pagam para a fazer subir na fila. Um pedido é apenas uma gorjeta
que também transporta **qual a música** que foi pedida — por isso o mesmo nome e mensagem que
um fã pode juntar a uma gorjeta aplicam-se também aqui, e é guardado e conservado exatamente
como qualquer outra gorjeta (em baixo). A fila pública que um fã vê mostra apenas **os totais
por música** — quanto uma música angariou e em que posição está — e não transporta **nenhum
nome de fã**. Sem conta, toda a lista de pedidos de música e o seu histórico vivem apenas no
dispositivo.

## Notificações push

Quando tem sessão iniciada, a app pode enviar-lhe uma **notificação push** — mas apenas se a
ativar, por dispositivo, e apenas depois de o sistema operativo do seu dispositivo conceder
permissão. Existe para uma só coisa: uma gorjeta ou um pedido de música que chega **enquanto
não está a decorrer um concerto**, para que fique a saber da gorjeta que de outra forma teria
perdido. Uma gorjeta que chega enquanto o seu palco está ao vivo não envia nada — já a está a
ver.

- Para entregar uma notificação push, o **Firebase Cloud Messaging (FCM)** da Google precisa
  de um **token push** do dispositivo. Guardamos esse token, e o idioma de interface do
  dispositivo, no registo do próprio dispositivo sob a sua conta, e é apagado no momento em
  que desativa as notificações, revoga o dispositivo ou termina a sessão. Os tokens mortos
  são removidos automaticamente.
- A própria notificação diz o que chegou — um valor, e o nome de um fã ou o título de uma
  música, se o deixaram. A mesma lista curta é mantida no **feed do sino** da sua conta,
  limitada às cem entradas mais recentes, para que possa percorrer o que chegou enquanto
  estava ausente.
- Na web, entregar uma notificação push exige um pequeno **service worker** na raiz do site e
  o SDK de mensagens da Firebase, que o seu navegador transfere da Google (`gstatic.com`) da
  primeira vez. A notificação push web é depois transportada pelo próprio serviço de push do
  seu navegador (no caso do Chrome, é o da Google). Nada disto é carregado a não ser que
  tenha ativado as notificações.
- **Uma conta de convidado e um dispositivo sem conta não recebem notificações**, porque uma
  notificação push precisa de uma conta a que possamos entregar e de um token que escolheu
  dar.

## Onde tudo isto vive fisicamente

O Firebase Auth, a Cloud Firestore, as nossas Cloud Functions e a chave da Cloud KMS que
envolve o seu segredo do Stripe correm todos na **União Europeia** — a base de dados na
multirregião `eur3` da Google, as funções e o key ring em `europe-west1`. A Google atua como
nosso subcontratante ao abrigo dos
[termos de privacidade e segurança da Firebase](https://firebase.google.com/support/privacy)
e da sua própria [política de privacidade](https://policies.google.com/privacy). Como
qualquer grande fornecedor, a Google pode envolver infraestrutura fora da UE para suporte e
segurança; isso é regido por esses termos, não por nós. As notificações push, uma vez
entregues ao Firebase Cloud Messaging e ao serviço de push do seu navegador ou telemóvel,
viajam pela infraestrutura dessas empresas até chegarem ao seu dispositivo.

## Stripe

Quando um fã paga com cartão, está na página de pagamento da **Stripe**, não na nossa. A
Stripe recolhe e trata os dados de pagamento como responsável pelo tratamento independente,
ao abrigo da [Política de Privacidade da Stripe](https://stripe.com/privacy). Nunca vemos
números de cartão.

A forma como as suas gorjetas lhe chegam depende do modo:

- **Sem conta**, a app do artista lê as suas próprias gorjetas no Stripe usando a chave
  restrita do próprio artista — diretamente do dispositivo para `api.stripe.com`. **Não há
  nenhum servidor live.tips nesse caminho.**
- **Com sessão iniciada**, a chave vive no nosso servidor (cifrada, como acima), e a Stripe
  comunica cada gorjeta ao nosso webhook, que a escreve no histórico Firestore do próprio
  artista. **Neste modo há um servidor live.tips no caminho** — para os dados da gorjeta,
  nunca para o dinheiro. O nome e a mensagem de um fã, se tiver deixado algum, viajam com a
  gorjeta para o histórico do próprio artista e param aí.

## O relé — apenas se o Revolut, o MobilePay ou o Monzo estiverem ativados

As configurações apenas com Stripe nunca tocam nisto.

O Revolut, o MobilePay e o Monzo não oferecem qualquer forma de uma app confirmar que um
pagamento aconteceu, por isso essas gorjetas passam por um pequeno relé open source que
mantemos na **Firebase** — Cloud Functions e Firestore em `europe-west1`, com a página de
gorjetas do fã servida a partir de **`tip.live.tips/t/<id>`**. Nunca toca no dinheiro. Aqui
está tudo o que ele trata.

### O que o artista guarda

Criar uma página de gorjetas guarda o **nome público do artista, a sua mensagem pública, a
sua moeda e os identificadores de pagamento que escolheu publicar** (o seu link de pagamento
Stripe, o nome de utilizador Revolut, o Box ID do MobilePay, o nome de utilizador Monzo) e,
se os pedidos de música estiverem ativados, **a sua lista pública de músicas e os respetivos
preços por música**. Tudo isto é informação que o artista está deliberadamente a publicar
para os fãs, de qualquer forma.

- **Conservação: uma página de gorjetas sem conta por trás é apagada automaticamente após 90
  dias de inatividade.** Uma página de gorjetas que pertence a uma conta com sessão iniciada
  vive tanto tempo quanto a banda a que pertence.
- O artista pode apagá-la **imediatamente** a partir da app, a qualquer momento.
- Não é recolhido aqui qualquer endereço de e-mail, palavra-passe, nome legal ou dados
  bancários.
- O segredo da página é guardado **apenas como hash**. Não lhe conseguiríamos dizer o segredo
  se nos perguntasse; só conseguimos verificar um.

### O que um fã envia

O formulário de gorjeta pede um **valor** e, opcionalmente, um **nome** e uma **mensagem** —
e, para um pedido de música, qual a música. É esse o formulário todo. Sem e-mail, sem número
de telefone, sem conta.

Para onde vai esse texto escrito pelo fã, e durante quanto tempo, depende de o artista ter ou
não sessão iniciada:

- **Se a página de gorjetas não tiver conta por trás**, a gorjeta é escrita numa **fila de
  entrega** — um único documento que existe para ser entregue ao ecrã do artista. Quando o
  ecrã mostra a gorjeta, **o dispositivo do artista apaga esse documento.** A eliminação *é* a
  confirmação de receção. Se o ecrã do artista estiver offline — telemóvel bloqueado, sem
  rede — a gorjeta **espera nessa fila durante um máximo de uma hora**, para não se perder
  pura e simplesmente, e passa no momento em que o ecrã se voltar a ligar. Se ninguém se
  voltar a ligar, é **apagada sem ser vista**, varrida de acordo com um horário. Para um
  artista sem conta, **essa fila é o único sítio onde texto escrito por um fã é alguma vez
  guardado no nosso servidor, e uma hora é o seu limite absoluto.**
- **Se a página de gorjetas pertencer a uma conta com sessão iniciada**, não há fila. O nosso
  servidor escreve a gorjeta **diretamente no histórico do próprio artista** sob o seu uid —
  na sessão de hoje se estiver a decorrer um concerto, ou no arquivo da própria banda se não.
  Aí fica **durante o tempo que a banda existir**; é o histórico do próprio artista, e é para
  isso que iniciou sessão. Este é o mesmo histórico em que o webhook da Stripe escreve, acima.
- O seu nome e a sua mensagem também são colocados na **nota de pagamento** que abre no
  Revolut, no MobilePay ou no Monzo — é assim que o artista sabe quem deu a gorjeta. Essas
  empresas tratam depois esses dados ao abrigo das suas próprias políticas de privacidade.
- O relé não guarda **nenhum registo de gorjetas entre artistas**. Não pode mostrar-lhe a si,
  a nós nem a mais ninguém uma lista de quem deu gorjeta a quem entre artistas.

### Endereços IP e combate ao abuso

Um formulário aberto para o qual qualquer pessoa pode submeter precisa de alguma proteção
contra bots, por isso:

- O seu endereço IP é enviado para a **Cloudflare Turnstile** — uma verificação anti-bot que
  corre na página de gorjetas — para confirmar que não é um bot. A Turnstile é um produto da
  Cloudflare e é usada em vez de um CAPTCHA que o traça. A Turnstile e o nosso DNS são as
  únicas coisas que a Cloudflare ainda faz por nós; o relé em si corre agora na Firebase.
  Consulte a [Política de Privacidade da Cloudflare](https://www.cloudflare.com/privacypolicy/).
- O seu IP é também usado para **limitar o número de pedidos** — enviar uma gorjeta, criar
  uma página de gorjetas, usar um código para acrescentar um dispositivo. O que guardamos
  para isso é um **hash criptográfico do IP com sal**, nunca o IP em si, durante cerca de
  **duas horas**, e depois é apagado. O sal é um segredo do servidor: sem ele, o código
  recusa-se a guardar seja o que for, em vez de manter um hash que pudesse ser revertido.
- Os **registos operacionais da Google** guardam os detalhes técnicos dos pedidos ao relé —
  URL, tempos, estado — durante alguns dias. O nosso código não regista deliberadamente
  nenhum nome, nenhuma mensagem, nenhum segredo e nenhum cabeçalho. A Google atua como nosso
  subcontratante.

### Contadores

O relé conta **quantas gorjetas** uma dada página de gorjetas retransmitiu, para podermos
detetar abusos e saber se a coisa é sequer usada. É um número. Não contém dados de fãs.

## Quem trata o quê

| Quem | O que recebe | Porquê |
| --- | --- | --- |
| **Google (Firebase)** | As contas, os dados sincronizados de um artista com sessão iniciada, a chave Stripe cifrada, o relé, os tokens push e a sua entrega, os registos do servidor | A conta opcional, o relé opcional e as notificações push |
| **Google Cloud KMS** | A chave que envolve o segredo do Stripe de um artista com sessão iniciada (nunca o segredo em claro) | Manter a chave Stripe guardada ilegível em repouso |
| **Stripe** | Os dados de pagamento do fã, como responsável pelo tratamento independente; e, para um artista com sessão iniciada, os eventos de gorjeta enviados ao nosso webhook | Gorjetas por cartão |
| **Cloudflare** | O IP do fã, para a verificação Turnstile na página de gorjetas. E o nosso DNS. | Manter os bots longe do formulário de gorjeta |
| **GitHub** | O IP e o user-agent de quem carrega este site | Alojar o site |
| **O seu navegador / serviço de push do telemóvel** (por exemplo, o da Google no caso do Chrome) | Um token push e o conteúdo da notificação, se ativou as notificações | Entregar as notificações push |
| **Revolut / MobilePay / Monzo** | O que quer que o fã faça na app deles, nota de pagamento incluída | Esses métodos de pagamento |

Não vendemos nada a ninguém, e não há mais ninguém nessa lista.

## Fundamento jurídico, se precisar de um (RGPD)

- Manter uma conta que pediu, sincronizar os seus próprios dados para os seus próprios
  dispositivos, guardar a sua chave Stripe para que as suas gorjetas cheguem ao seu histórico,
  manter o relé a funcionar para um artista que o ativou, entregar a gorjeta de um fã ao ecrã
  a que se destinava, e enviar uma notificação push que ativou: **execução de um serviço que
  solicitou**.
- Limitação de pedidos, Turnstile, quotas por IP com hash e revogação de dispositivos:
  **interesse legítimo** em impedir que um serviço gratuito e aberto seja destruído por bots
  e fraude, e em manter as contas dos artistas seguras.
- Registos do servidor: **interesse legítimo** em operar e proteger o serviço.

## Apagar coisas

Isto conta mais do que qualquer promessa que pudéssemos fazer a respeito, por isso aqui fica
exatamente o que existe hoje — incluindo o que não existe.

- **Sem conta**: desinstale a app. É tudo, desapareceu.
- **Uma banda**: remover uma banda na app apaga os dados dessa banda na nuvem — as suas
  definições, as suas chaves, as suas sessões, o seu histórico de gorjetas — juntamente com a
  cópia que está no dispositivo.
- **Uma página de gorjetas**: apague-a ou volte a gerá-la na app e é limpa do relé de
  imediato, incluindo quaisquer gorjetas pendentes.
- **Notificações push**: desative-as num dispositivo e o seu token push é apagado. O feed do
  sino é limpo com a banda ou com a conta.
- **Um dispositivo**: Definições → Segurança lista os seus dispositivos. Pode revogar um, ou
  terminar a sessão em todo o lado — o que termina a sessão de todos os outros dispositivos
  imediatamente, não a prazo.
- **A sua conta inteira, num toque: a app ainda não tem esse botão.** Preferimos admiti-lo a
  fingir o contrário. Até que exista, escreva para
  **[contact@live.tips](mailto:contact@live.tips)** e apagaremos a conta e tudo o que estiver
  debaixo dela, à mão. Entretanto, já pode apagar todas as bandas, o que remove tudo o que
  tem substância — incluindo a chave Stripe guardada — e deixa uma conta vazia para trás.

## Os seus direitos

Pode pedir-nos uma cópia, a correção ou a eliminação de tudo o que tenhamos sobre si, e
pode apresentar queixa à autoridade nacional de proteção de dados do seu país. Escreva para
**[contact@live.tips](mailto:contact@live.tips)**.

Na prática, a maior parte disso já está nas suas mãos: um artista pode apagar uma página de
gorjetas ou uma banda na app instantaneamente, as gorjetas de fãs não entregues numa página
sem conta evaporam-se dentro de uma hora e, se nunca iniciar sessão, nada disso esteve alguma
vez em lado nenhum a não ser no seu próprio dispositivo.

## Crianças

O live.tips não se dirige a crianças e não tratamos conscientemente os seus dados.

## Alterações

Atualizaremos esta página quando o software mudar. Como todo o projeto é open source,
**todas as versões anteriores desta política estão no histórico público do git** — pode ver
exatamente o que mudou e quando.

## Idioma

Esta política é publicada em todos os idiomas que o site suporta, por conveniência. Se uma
tradução e a versão em inglês divergirem, **a versão em inglês é a que conta**.
</content>
</invoke>
