# Monte um pote de gorjetas na sua própria conta Stripe

> Três chamadas de API dão-lhe uma página alojada de preço livre com Apple Pay e Google Pay, sem servidor nenhum. Aqui está a montagem completa: a chave restrita, as permissões, como ler as gorjetas sem webhook e as contas das taxas que ninguém imprime.

Canonical: https://live.tips/pt/blog/monte-um-pote-de-gorjetas-na-sua-propria-conta-stripe/
Published: 2026-07-11
Language: pt
Tags: Stripe, open source, how-to, API, fees

---

Quer um pote de gorjetas. Não quer entregar a uma plataforma 5 % da noite de um músico
de rua, e é perfeitamente capaz de falar com uma API. A pergunta, portanto, não é *em que
pote de gorjetas me inscrevo*, mas *quanto tenho realmente de construir*.

Menos do que pensa. Na Stripe, a resposta prática são três chamadas de API: sem servidor,
sem backend, sem endpoint de webhook. O resto deste artigo é essa montagem — mais as duas
coisas que toda a gente erra.

## O truque é um Price de preço livre

A Stripe tem um modo de preço em que é o fã que escreve o valor. Chama-se
[pay what you want](https://docs.stripe.com/payments/checkout/pay-what-you-want) e é a
funcionalidade inteira. Cria um Product, prende-lhe um Price com
`custom_unit_amount[enabled]=true` e pendura por cima um
[Payment Link](https://docs.stripe.com/payment-links/create).

```sh
# 1. a coisa que está a "vender"
curl https://api.stripe.com/v1/products \
  -u "$RK:" \
  -d name="Tips — Mira" \
  -d "metadata[managed_by]"=my-tip-jar

# 2. o preço que o fã escolhe
curl https://api.stripe.com/v1/prices \
  -u "$RK:" \
  -d product=prod_... \
  -d currency=eur \
  -d "custom_unit_amount[enabled]"=true \
  -d "custom_unit_amount[preset]"=500 \
  -d "custom_unit_amount[minimum]"=200

# 3. a página
curl https://api.stripe.com/v1/payment_links \
  -u "$RK:" \
  -d "line_items[0][price]"=price_... \
  -d "line_items[0][quantity]"=1 \
  -d submit_type=pay
```

A terceira chamada devolve uma `url`. Essa URL *é* o seu pote de gorjetas. É uma página
alojada pela Stripe: cumpre PCI sem que tenha de pensar nisso, está localizada e mostra
Apple Pay ou Google Pay a qualquer fã cujo telemóvel os tenha configurados — os
[métodos de pagamento dinâmicos](https://docs.stripe.com/payments/payment-methods/dynamic-payment-methods)
decidem isso por si, consoante o dispositivo e o país. Não escreveu qualquer frontend.

Codifique a URL como código QR com a biblioteca que quiser — é apenas uma string —,
imprima-o, cole-o no estojo. O código nunca expira e não aponta para nenhum servidor seu,
porque não tem nenhum.

Dois parâmetros que vale a pena conhecer:

- **`custom_unit_amount[preset]`** é o valor com que a página abre. `500` significa que o
  fã vê já 5,00 € preenchidos e pode alterá-los. Este número faz mais pela sua gorjeta
  média do que qualquer outra coisa na página.
- **`custom_unit_amount[minimum]`** é um piso. Defina-o. A razão está na secção das taxas,
  e não é um erro de arredondamento.

Também pode recolher um nome e uma mensagem. Os Payment Links aceitam até três
`custom_fields` — é assim que consegue o "de quem foi aquilo?" sem construir um formulário:

```sh
  -d "custom_fields[0][key]"=nickname \
  -d "custom_fields[0][type]"=text \
  -d "custom_fields[0][label][type]"=custom \
  -d "custom_fields[0][label][custom]"="O seu nome ou alcunha" \
  -d "custom_fields[0][optional]"=true
```

A Stripe tem [requisitos para aceitar gorjetas e donativos](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations) —
leia-os uma vez. O preço livre também não se combina com outros line items, descontos ou
pagamentos recorrentes. Para um pote de gorjetas, nada disso incomoda.

Vale a pena acertar nesta distinção. A Stripe di-lo assim: uma gorjeta é dada por um bem
ou serviço já prestado, ao passo que um donativo tem de estar ligado a um fim de
beneficência. Tocaste o set; a gorjeta paga-o. É também por isso que a chamada acima envia
`submit_type=pay` e não `donate` — `donate` alojaria o teu link em `donate.stripe.com` e
imprimiria *Doar* no botão. É outro ramo, e um que a Stripe analisa com muito mais rigor.

## A chave: parta do princípio de que vai vazar, e torne isso aborrecido

Não ponha uma chave secreta (`sk_live_…`) num dispositivo que fica em cima de um palco. Use
uma [chave restrita](https://docs.stripe.com/keys/restricted-api-keys) (`rk_live_…`): escolhe
uma permissão por recurso, e tudo o que não escolher fica em **None**.

Para a montagem acima, a lista completa são cinco linhas:

| Recurso | Permissão | Para que serve |
| --- | --- | --- |
| Products | Write | criar o Product |
| Prices | Write | criar o Price de preço livre |
| Payment Links | Write | criar o link |
| Checkout Sessions | Read | ver as gorjetas que entraram |
| Events | Read | o feed em direto (secção seguinte) |

Tudo o resto — Balance, Payouts, Refunds, Customers, PaymentIntents, todo o Connect — fica
em **None**.

Agora faça o exercício que torna isto tudo digno de nota. O seu tablet desaparece da mesa de
merchandising à uma da manhã. O que pode o ladrão fazer com a chave que está no keychain? Ler
o seu histórico de gorjetas e criar mais links de gorjeta na sua conta. É todo o raio da
explosão. Não vê o seu saldo, não pode desencadear uma transferência, não pode emitir um
reembolso para um cartão que controle, não pode ler uma lista de clientes. Revoga a chave a
partir do telemóvel no táxi para casa e o dispositivo apaga-se. Nada do seu dinheiro se mexeu.

Essa assimetria — acesso de escrita ao pote, zero acesso ao dinheiro — é a única razão pela
qual um desenho sem servidor, com a sua própria chave, se defende. É também por isso que
"Login with Stripe" não é a resposta aqui: OAuth exige um servidor do programador da app para
guardar o seu token, e um servidor é exatamente aquilo que não estamos a construir.

(Uma esquisitice com que vai esbarrar: a permissão *Prices* chama-se internamente `plan_write`,
por isso a mensagem de erro da Stripe nomeia um scope que no dashboard não aparece com esse
nome. É Prices.)

## Ler as gorjetas sem webhook

É aqui que a maioria dos tutoriais para ou pega num webhook — e é aqui que um palco é
verdadeiramente diferente de uma aplicação web.

Um webhook é um pedido HTTP de entrada. Um tablet atrás de um pé de microfone não pode receber
nenhum. Está na wi-fi de convidados de uma sala, atrás de NAT, sem endereço público, sem
certificado TLS — e não tem nada que ter isso. Se seguir a via do webhook, tem de montar um
servidor para apanhar os eventos e um socket para os empurrar para o dispositivo: um backend,
um encargo operacional e um sítio onde passam a viver os nomes dos seus fãs. Acabou de
reconstruir a plataforma que queria evitar.

Portanto puxe, em vez de ser empurrado. O endpoint
[List all events](https://docs.stripe.com/api/events/list) da Stripe é público, documentado, e
devolve os eventos do mais recente para o mais antigo:

```sh
curl -G https://api.stripe.com/v1/events \
  -u "$RK:" \
  -d "types[]"=checkout.session.completed \
  -d "types[]"=checkout.session.async_payment_succeeded \
  -d ending_before=evt_O_ULTIMO_QUE_VI \
  -d limit=100
```

`ending_before` é o desenho todo. Guarde o id do evento mais recente que processou; cada sondagem
pede tudo o que for estritamente mais novo, e avança o cursor. Sem timestamps, sem desvio de
relógio, sem desduplicar por valor. Na primeira sondagem de um set, peça `limit=1` sem cursor para
se ancorar no que já existe, e assim não repetir as gorjetas desta manhã durante a passagem de som.

Depois filtre o que volta. Ambos os tipos de evento podem disparar para um único pagamento, por
isso desduplique pelo id da Checkout Session. Verifique `payment_status == "paid"` — uma sessão
concluída não é necessariamente uma sessão paga. E verifique que `payment_link` corresponde ao
*seu* link, porque `/v1/events` abrange a conta toda e entregar-lhe-á de bom grado o tráfego de
tudo o resto que essa conta Stripe faça.

Seja honesto quanto aos compromissos, porque são reais:

- **A Stripe recomenda webhooks.** O polling não é o caminho abençoado; é um endpoint documentado
  usado deliberadamente. Diga-o no seu README e siga em frente.
- **Os eventos recuam 30 dias.** [Palavras da Stripe](https://docs.stripe.com/api/events/list):
  *"List events, going back up to 30 days."* Isto é um feed em direto, não o seu livro-razão. O
  seu livro-razão são as Checkout Sessions — e o verdadeiro é o dashboard da Stripe.
- **Atenção à quota de leitura.** Toda a gente olha para o limite por segundo
  ([rate limits](https://docs.stripe.com/rate-limits): 100 req/s em live) e ninguém olha para o
  outro: a Stripe aloca cerca de **500 pedidos de leitura por transação** numa janela móvel de 30
  dias, com um piso de 10 000 leituras por mês. Sondando de 4 em 4 segundos, um set de três horas
  são ~2 700 leituras. Quatro concertos longos num mês e está no piso. As gorjetas compram-lhe
  folga à medida que chegam — mas se sondar de segundo a segundo porque parecia mais ágil, vai
  encontrar o teto. Quatro segundos não é um número preguiçoso; é *o* número.

É esta a forma honesta da coisa: o polling custa-lhe uns milhares de GET e poupa-lhe um backend
inteiro.

## As contas das taxas, feitas como deve ser

Uma plataforma que anuncia 0 % não é grátis, e isto também não é. A taxa de processamento da própria
Stripe aplica-se a todas as gorjetas, e a Stripe cobra-lha diretamente. Hoje, segundo os
[preços em euros da Stripe](https://stripe.com/ie/pricing), um cartão padrão do EEE custa
**1,5 % + 0,25 €**. Cartões premium do EEE: 1,9 % + 0,25 €; cartões britânicos: 2,5 % + 0,25 €; e
tudo o resto: 3,25 % + 0,25 €, mais 2 % se for preciso converter moeda. (Nos EUA é 2,9 % + 0,30 $,
o que é pior exatamente pela razão que se segue.)

O problema não é a percentagem. São os vinte e cinco cêntimos.

| Gorjeta | A Stripe leva | O artista fica com | Corte efetivo |
| --- | --- | --- | --- |
| 2 € | 0,28 € | 1,72 € | **14,0 %** |
| 5 € | 0,33 € | 4,67 € | 6,5 % |
| 10 € | 0,40 € | 9,60 € | 4,0 % |
| 20 € | 0,55 € | 19,45 € | 2,8 % |
| 50 € | 1,00 € | 49,00 € | 2,0 % |

Uma taxa fixa é uma percentagem disfarçada e, em dinheiro pequeno, o disfarce cai. Os mesmos 0,25 €
que são invisíveis numa gorjeta de 50 € comem um oitavo de uma de 2 €. As gorjetas são pequenas por
natureza — é isso que as torna gorjetas — por isso não é um caso extremo: é o caso mediano.

É por isso que define `custom_unit_amount[minimum]`. Algures perto dos 2 €, a transação deixa de
valer a pena; uma gorjeta de 0,50 € por cartão chegaria como 0,24 € e custaria à Stripe mais a
mover do que aquilo que vale. Escolha o seu piso deliberadamente, em vez de o descobrir na primeira
transferência.

E repare no que isto faz à comparação com que começou. Uma plataforma que cobra 0 % por cima da
Stripe está a cobrar-lhe 0 % por cima **disto**. O 0 % deles é real — e é 0 % daquilo que o
processador deixou. A via dos cartões de ninguém é grátis: a afirmação honesta é "nenhum corte além
do do processador", e quem afirmar mais está a mentir ou não está a usar cartões.

## O que tem agora, e o que não tem

Três chamadas de API e um código QR, e um pote de gorjetas a sério: alojado, conforme PCI, Apple Pay,
Google Pay, gorjetas a aterrar no seu próprio saldo Stripe, no seu próprio calendário de
transferências, e sem servidor pelo caminho. Para muita gente, isso é genuinamente o fim do projeto,
e pode perfeitamente parar aqui e publicar.

O que não tem é um palco. Tem uma página de pagamento. Entre uma coisa e outra estão as aborrecidas:
o ciclo de sondagem com o seu cursor e o seu backoff, um ecrã que o público consiga ver com o
objetivo e a última mensagem, um sítio para a chave que não seja `localStorage`, um bloqueio para que
um desconhecido não mexa no tablet entre sets, e a camada das mil pequenas decisões sobre o que
acontece quando a wi-fi da sala cai a meio do set.

É isso que é o [live.tips](https://github.com/mekedron/live.tips) — exatamente esta arquitetura,
acabada, com licença MIT. A chave restrita com aquelas cinco permissões, o ciclo de cursor sobre
`/v1/events`, a criação de Product/Price/Payment Link — tudo a correr no dispositivo do artista,
contra a conta dele. Não há servidor live.tips no caminho da Stripe nem saldo live.tips em lado
nenhum, coisa que escrevemos à parte em
[como o live.tips lida com o dinheiro](https://live.tips/pt/blog/como-a-live-tips-lida-com-o-dinheiro/).

Leia o código, leve as peças que quiser, ou simplesmente use-o. A ideia deste artigo é que a
arquitetura não é um segredo nem é difícil: **a Stripe aloja o seu pote de gorjetas de graça, e uma
chave restrita mais um ciclo de sondagem é tudo o que se interpõe entre um artista e o seu próprio
dinheiro.** Preferimos que saiba isso a que se inscreva onde quer que seja.
