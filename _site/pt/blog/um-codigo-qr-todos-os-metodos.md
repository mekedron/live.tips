# Um código QR, todos os métodos de pagamento

> A maioria das ferramentas de gorjetas dá-te um código por cada fornecedor de pagamento. Cola três à haste do microfone e vê as pessoas desistirem. Aqui está porque a live.tips se fica por um.

Canonical: https://live.tips/pt/blog/um-codigo-qr-todos-os-metodos/
Published: 2026-07-09
Language: pt
Tags: QR codes, Revolut, MobilePay, Stripe

---

Passa por atuações de rua suficientes e começas a reparar na fita-cola. Um código
Revolut no estojo da guitarra. Um código MobilePay no amplificador. Talvez um do
PayPal, a enrolar nos cantos, de uma digressão de há dois verões.

Cada um desses códigos é uma pequena aposta em que alguém no público usa
exatamente aquela app. Juntos são uma parede de trabalhos de casa, apresentada a
uma pessoa que já parou de andar, já pegou no telemóvel e tem talvez oito
segundos de boa vontade antes de o amigo dizer *anda lá*.

## O problema é a bifurcação, não a app

Os fornecedores de pagamento são regionais. A Revolut viaja bem pela Europa. A
MobilePay é como finlandeses e dinamarqueses pagam uns aos outros. A Swish é dona
da Suécia. Um músico de rua em Helsínquia a tocar para uma praça cheia de
turistas precisa mesmo de mais do que um — essa parte não é um erro.

O erro é fazer o público resolvê-lo. Um fã que digitaliza um código MobilePay sem
ter a MobilePay instalada não vai à procura dos teus outros códigos. Guarda o
telemóvel. Não perdeste a gorjeta porque não quisessem dar; perdeste-a porque
lhes entregaste uma decisão de encaminhamento exatamente no momento em que se
sentiam generosos.

## O que fazemos em vez disso

A live.tips dá-te um código QR, e ele nunca muda. Liga a Stripe, a Revolut e a
MobilePay em conjunto, e esse mesmo código abre uma página de gorjetas que lista
todos os métodos que aceitas. O fã escolhe o que já tem. Ninguém digitaliza nada
duas vezes.

Se só quiseres pagamentos por cartão, nunca verás a lista — a página combinada só
aparece assim que ativas um segundo método. Um código, uma página, e a página
adapta-se a ti em vez de se adaptar ao fornecedor.

Há também um benefício mais silencioso. O código no teu estojo é agora um objeto
permanente. Podes imprimi-lo uma vez, plastificá-lo, colá-lo na tampa, e ele
continua a funcionar quando acrescentares a Revolut na próxima primavera ou
deixares a MobilePay depois de te mudares. O teu equipamento de palco deixa de
ser uma função da tua pilha de pagamentos.

## Para onde vai realmente o dinheiro

Vale a pena dizê-lo claramente, porque «uma página para todos os métodos» é
exatamente a frase que uma plataforma usa mesmo antes de explicar a sua taxa: as
gorjetas por cartão vão diretamente do teu fã para a tua própria conta Stripe.
Não estamos no meio disso. Não há saldo na live.tips, não há calendário de
pagamentos, não há comissão.

Os fluxos da Revolut e da MobilePay funcionam de forma um pouco diferente, e
escrevemos sobre isso em separado em
[como a live.tips lida com o dinheiro](https://live.tips/pt/blog/como-a-live-tips-lida-com-o-dinheiro/) — cinco
minutos bem gastos se és do tipo de pessoa que lê os termos antes de colar seja o
que for ao estojo da guitarra. Deves ser.

## Experimenta

Abre a [app](https://live.tips/app/?lang=pt), deixa a Stripe em modo de demonstração e aponta o
teu próprio telemóvel ao código que ela gera. Acrescenta um segundo método e
digitaliza o mesmo código outra vez. É o mesmo código. É essa a funcionalidade
toda.
