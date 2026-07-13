# Gorjetas sem contacto para músicos de rua, com honestidade

> Tap to Pay no telemóvel, um leitor de cartões, um autocolante NFC, um código QR — quatro coisas diferentes a que se chama «sem contacto». Quanto custa realmente cada uma em 2026, o que uma etiqueta NFC faz de facto (não é o que pensas) e quando um toque ganha a uma leitura.

Canonical: https://live.tips/pt/blog/gorjetas-sem-contacto-para-musicos-de-rua/
Published: 2026-07-11
Language: pt
Tags: contactless, NFC, QR codes, Tap to Pay, fees

---

Procura «gorjetas sem contacto para músicos de rua» e a internet devolve-te 2018. Um
protótipo de estudantes da Brunel University chamado Tiptap — um suporte onde
encaixas um telemóvel — teve a sua ronda de imprensa nesse ano, e essa imprensa
continua na primeira página. Era uma ideia bonita. Era também, nas palavras da
própria cobertura, *ainda em fase de desenvolvimento*, e planeava cobrar aos músicos
de rua uma taxa única mais **5% de cada gorjeta**. Nunca chegou a ser algo que se
possa comprar.

(O «tiptap» que encontras se fores procurar agora é uma empresa do Ontário sem
qualquer relação, que vende terminais de donativos sem contacto a instituições de
solidariedade. Mesma palavra, produto diferente, não é para ti.)

Ou seja, o estado honesto da questão passou oito anos sem ser escrito. Aqui está.

Isto é o mergulho fundo no tap. Se a tua pergunta é mesmo a mais ampla — todas as
formas de receber agora que ninguém traz dinheiro, e quanto custa cada uma —, começa
por [como os artistas de rua recebem com
cartão](https://live.tips/pt/blog/pagamentos-com-cartao-artistas-de-rua/) e volta cá depois.

## Quatro coisas diferentes chamam-se todas «sem contacto»

É aqui que vive a maior parte da confusão, por isso vamos separá-las antes de pôr
preço seja no que for.

1. **Tap to Pay no teu próprio telemóvel.** O telemóvel torna-se o terminal. O fã
   encosta o cartão ou o relógio ao *teu* aparelho. Zero hardware extra.
2. **Um leitor de cartões** — um SumUp, um Zettle, um Square. Um pequeno terminal de
   plástico que estendes. O fã toca-lhe.
3. **Uma etiqueta NFC** — o autocolante ou a placa «toca aqui para dar gorjeta». Esta
   é mal compreendida de forma quase universal, e a secção seguinte explica porquê.
4. **Um código QR.** Não é sem contacto no sentido NFC — mas continua a ler, porque do
   lado do fã acaba muitas vezes exatamente no mesmo toque.

Só os dois primeiros são *terminais de pagamento*. Toda esta publicação é sobre essa
distinção.

## A etiqueta NFC não recebe um pagamento

Vamos arrumar isto como deve ser, porque os vendedores adoram deixar-te acreditar no
contrário.

Um autocolante NFC — o tipo barato, o chip NTAG213 que a maioria usa — tem **144
bytes de memória**. Não 144 kilobytes. Não consegue correr código, não tem bateria,
nunca ouviu falar de uma rede de cartões e não conseguiria guardar um protocolo de
pagamento nem que quisesse. O que guarda é uma cadeia curta de texto, formatada como
um registo NDEF, e essa cadeia é esmagadoramente um **URL**.

Tocas-lhe e o teu telemóvel abre uma página web. É essa a funcionalidade toda.

O que significa que uma placa de «toca para dar gorjeta» é um código QR que abres a
tocar em vez de apontar. Mesmo destino, mesma página web, mesmo pagamento a acontecer
no navegador. Até os especialistas o dizem, se os leres com atenção: o próprio site
da tiptap descreve o seu aparelho de valor livre como aquele em que *«quando os
doadores encostam o telemóvel a um dispositivo de donativos personalizado, são
encaminhados para a tua página de angariação online»*. Encaminhados para uma página.
Porque é isso que uma etiqueta consegue fazer.

Isto é genuinamente útil, e é barato — autocolantes NTAG213 em branco começam à volta
de **0,24 $ cada** em pacotes. Se já tens uma página de gorjetas, colar uma etiqueta
no estojo ao lado do código impresso custa-te trocos e dá a alguns fãs uma entrada
mais rápida.

Mas fica claro sobre o que compraste: **uma segunda porta de entrada para a mesma
página.** Não uma máquina de cartões.

### E na rua é uma porta de entrada esquisita

As falhas são reais, e nenhum vendedor de etiquetas as enumera:

- **O telemóvel do fã tem de estar desbloqueado e em uso.** A própria documentação da
  Apple é explícita: a leitura de etiquetas em segundo plano só acontece enquanto o
  iPhone está a ser usado e, se o telemóvel estiver bloqueado, o sistema obriga-o a
  desbloquear primeiro.
- **Não funciona com a câmara aberta.** A Apple enumera a câmara em uso como um dos
  estados em que a leitura de etiquetas em segundo plano não está disponível. Saboreia
  a ironia: um fã que puxa da câmara para ler o teu código QR acabou de desativar a
  tua etiqueta NFC.
- **Precisa de um iPhone XS ou posterior**, e no Android precisa do NFC ligado — que
  alguns modos de poupança de energia desligam.
- **O alcance é de uns 4 cm.** O fã tem mesmo de tocar na coisa. No meio de uma
  multidão, curvando-se sobre um estojo de guitarra, isso é pedir muito.
- **Metal e ímanes matam-na.** Uma etiqueta colada num amplificador, ou um fã com uma
  capa magnética, e não acontece rigorosamente nada.

Uma etiqueta é uma boa segunda opção. É uma má opção única.

## Tap to Pay no telemóvel: a verdadeira novidade de 2026

Eis o que mudou desde os artigos sobre a Tiptap, e de que nenhuma daquela cobertura
velha faz ideia.

**O Tap to Pay no iPhone** transforma o telemóvel que já tens no bolso num terminal
sem contacto. Sem dongle, sem leitor, sem suporte. A Apple dá-o como disponível em
**mais de 70 países e regiões**, e os fornecedores através dos quais o podes usar na
Europa parecem a indústria inteira — só na Alemanha: Adyen, Mollie, myPOS, Nexi,
PAYONE, Rapyd, Revolut, Sparkassen, Stripe, SumUp, Viva.com. O Reino Unido, a França,
os Países Baixos, a Suécia, a Finlândia e a Dinamarca têm listas parecidas. Precisas
de um iPhone XS ou posterior.

**O Tap to Pay no Android** também existe, mas é mais estreito. Através do Stripe,
está geralmente disponível em AT, AU, BE, CA, CH, DE, DK, FI, FR, GB, IE, IT, MY, NL,
NZ, PL, SE, SG e US, com mais dezoito países em pré-visualização pública. O telemóvel
precisa de Android 13 ou posterior, de um sensor NFC, de um bootloader sem root, dos
Google Mobile Services e das opções de programador desligadas — esta última apanha
mais gente do que imaginas.

Na prática: **a SumUp anuncia o Tap to Pay com 0 £ de hardware.** Se tens um iPhone
recente e estás num país suportado, o custo de entrada para estenderes um terminal
sem contacto é agora zero. Só esse facto torna obsoleto qualquer artigo de 2018 do
género «compra este suporte».

## Leitores de cartões, e quanto custam de verdade

Se queres um bocado de plástico à parte — e há boas razões para isso, mais abaixo — o
mercado são três produtos.

| | Hardware | Comissão por pagamento presencial |
| --- | --- | --- |
| **SumUp** (UK) | Tap to Pay 0 £ · Solo Lite 25 £ · Solo 79 £ · Terminal 135 £ | **1,69%**, sem taxa fixa |
| **SumUp** (Alemanha) | — | **1,39%**, sem taxa fixa |
| **Zettle / PayPal POS** (UK) | Leitor a partir de 29 £ na primeira compra, 69 £ depois | **1,75%**, sem taxa fixa |
| **Square** (UK) | Leitor sem contacto e de chip 19 £ | **1,75%**, sem taxa fixa |
| **Square** (US) | Leitor sem contacto e de chip 59 $ | **2,6% + 0,15 $** |

Preços sem IVA e tal como publicados em julho de 2026. Vai confirmá-los; eles mexem-se.

Agora lê a tabela outra vez, porque diz uma coisa que contradiz o que provavelmente te
contaram.

## As contas das comissões, e a coisa que toda a gente tem ao contrário

A sabedoria comum diz que as comissões dos cartões destroem as gorjetas pequenas por
causa do encargo fixo por transação — os vinte e cinco cêntimos que comem um oitavo de
uma gorjeta de 2 €. Isso é verdade, e nós próprios
[escrevemos as contas](https://live.tips/pt/blog/monte-um-pote-de-gorjetas-na-sua-propria-conta-stripe/).

Mas é verdade dos pagamentos com cartão *online*. **Os leitores sem contacto europeus,
na sua maioria, não têm taxa fixa nenhuma.** A SumUp, a Zettle e a Square no Reino
Unido e na UE cobram só percentagem. O que significa:

| Uma gorjeta de 2 € | Comissão | Fica para o artista | Corte efetivo |
| --- | --- | --- | --- |
| Leitor SumUp (DE, 1,39%) | 0,03 € | 1,97 € | **1,4%** |
| Zettle / Square (UK, 1,75%) | 0,04 € | 1,96 € | 1,8% |
| Stripe, cartão online (EEE, 1,5% + 0,25 €) | 0,28 € | 1,72 € | **14,0%** |
| Leitor Square (US, 2,6% + 0,15 $) | 0,20 $ | 1,80 $ | **10,1%** |

Só pela comissão, um terminal de toque europeu ganha a um pagamento com cartão online
numa gorjeta pequena, e nem sequer é renhido. Somos um produto de código QR e estamos
a dizer-te isto: numa gorjeta de 2 €, um leitor SumUp guarda-te 0,25 € que uma página
alojada pelo Stripe não guarda.

Duas coisas põem isso de novo em proporção.

**O hardware é a taxa fixa, apenas mudada de sítio.** Uma poupança de 0,25 € por
gorjeta contra um Solo de 79 £ dá cerca de **trezentos toques até o leitor se ter
pago a si próprio**. É um número real para um músico de rua que trabalha, e um número
ridículo para quem toca duas vezes por verão. (E o Tap to Pay de 0 £ da SumUp
transforma isso em zero toques — que é exatamente por isso que essa opção importa mais
do que os leitores.)

**E os Estados Unidos invertem tudo outra vez.** A tarifa presencial americana da
Square traz uma taxa fixa de 0,15 $, por isso um toque de 2 $ também perde um décimo
de si próprio no terminal. A prenda «sem taxa fixa» é europeia.

Há ainda um piso com que te vais encontrar: a SumUp não aceita um pagamento abaixo de
**1 £ / 1 €**. Escolhas o trilho que escolheres, a gorjeta muito pequena não é
verdadeiramente uma transação com cartão.

## Então, quando é que um toque ganha a uma leitura?

Tira a tecnologia do meio e isto é uma pergunta sobre as mãos do fã.

**Um toque precisa do telemóvel do fã desbloqueado e na mão dele, e precisa que tu
estejas a estender qualquer coisa.** Quando as duas coisas se verificam, é o mais
rápido que existe nos pagamentos. Sem app, sem apontar, sem escrever, feito num
segundo.

**Uma leitura precisa que o fã abra uma câmara** — mais um ato deliberado — mas não
precisa de nada de ti. O código está no estojo. Funciona com um fã que ficou lá atrás.
Funciona com quarenta pessoas ao mesmo tempo. Funciona enquanto ainda estás a tocar.

O que dá uma divisão honesta:

- **O toque ganha quando podes ir ter com as pessoas.** Fim do set, o chapéu a dar a
  volta, um fã de cada vez, tu livre para segurar um terminal. Um toque é um pedido com
  menos atrito do que «tira a câmara», e nesse momento estás fisicamente presente para
  o fechar.
- **A leitura ganha quando não podes.** A meio da canção. Uma multidão de três filas.
  Um sítio de onde não te podes afastar do amplificador. Toda a gente que quer dar de
  passagem. Um terminal serve exatamente uma pessoa; um código impresso serve a praça
  inteira, ao mesmo tempo, e não precisa que pares de tocar para o servires.

Este último ponto é o que os vendedores de terminais nunca fazem, e é o maior de
todos. **Um leitor de cartões é um estrangulamento com fila.** Um código QR não tem
fila.

E aqui está a parte que dissolve metade da discussão: numa página de gorjetas bem
feita, **a leitura acaba num toque na mesma**. O fã lê, a página abre, e o telemóvel
oferece-lhe Apple Pay ou Google Pay. Duplo clique, aproxima o telemóvel do rosto,
está feito. Do lado do fã, isso é um pagamento sem contacto — mesma wallet, mesmo
cartão, os mesmos dois segundos — e tu não compraste hardware nenhum para que
acontecesse.

## Onde fica o live.tips, e quando comprar antes um SumUp

O [live.tips](https://github.com/mekedron/live.tips) é um pote de gorjetas baseado em
QR. Um código, que nunca muda, a apontar diretamente para o link de pagamento Stripe
do próprio artista. Não há saldo live.tips, nem corte, nem plataforma pelo caminho — a
comissão é a do Stripe e o Stripe cobra-a diretamente ao artista. Tem licença MIT, e o
tablet no palco mostra cada gorjeta no momento em que aterra. Escrevemos o percurso do
dinheiro em [como o live.tips lida com o dinheiro](https://live.tips/pt/blog/como-a-live-tips-lida-com-o-dinheiro/),
e porque é [um código em vez de um por fornecedor](https://live.tips/pt/blog/um-codigo-qr-todos-os-metodos/).

Essa página suporta Apple Pay e Google Pay. Portanto o live.tips *é* sem contacto do
lado do fã — o toque que interessa, o do fim, sem terminal para comprar, carregar ou
deixar cair à chuva. Só não é um terminal.

**Se o que queres é estender fisicamente uma coisa e ter um desconhecido a tocar-lhe,
compra um leitor de cartões.** Escolhe o Tap to Pay da SumUp se o teu telemóvel e o
teu país o suportarem, porque não custa nada; escolhe um Solo se preferires não
entregar o teu próprio telemóvel a uma multidão. De qualquer forma, num toque de 2 €
na Europa vai ganhar à nossa comissão, e preferimos dizê-lo a fingir o contrário.

Também podes fazer as duas coisas, e muitos músicos de rua deviam: o código colado ao
estojo a noite toda, a apanhar quem passa enquanto tocas, e o terminal na mão para os
dez segundos depois do último acorde, quando a primeira fila mete a mão ao bolso. Não
estão a competir. Estão a apanhar pessoas diferentes.

O que nenhum deles é: um suporte de 2018 que leva 5%.

Comissões, preços de hardware e disponibilidade por país tal como publicados pela Apple, Stripe, SumUp, Zettle/PayPal e Square em julho de 2026, sem IVA. Preços dos autocolantes NFC segundo a GoToTags. As condições da Tiptap em 2018 tal como noticiadas pela Brunel University e pela Finextra. Tudo aqui muda; confirma junto do vendedor antes de gastares dinheiro.
{: .footnote }
