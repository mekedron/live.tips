---
title: Como a live.tips lida com o dinheiro (não lida)
description: Não há saldo na live.tips, não há calendário de pagamentos, não há comissão. Aqui está a arquitetura que torna estas três afirmações enfadonhas em vez de corajosas.
slug: como-a-live-tips-lida-com-o-dinheiro
---

Qualquer mealheiro de gorjetas pode escrever «0% de comissão» na sua página
inicial. A pergunta interessante é o que o software teria de fazer para
*começar* a ficar com uma fatia, e quanto disso conseguirias ver.

No caso da live.tips, a resposta é: teria de ser reconstruído. Isto não é uma
promessa sobre as nossas intenções, é uma descrição de para onde vai o dinheiro.

## O dinheiro nunca passa por nós

Quando um fã toca num valor de cartão, o pagamento é criado na **tua** conta
Stripe, é liquidado no **teu** saldo Stripe e é pago segundo o **teu** calendário
Stripe. A única taxa é a taxa de processamento padrão da própria Stripe, que a
Stripe te cobra diretamente, tal como faria se tivesses integrado a Stripe por ti
próprio.

Não há registo do nosso lado porque não há nada a registar. Não conseguiríamos
tirar uma percentagem sem primeiro construir a coisa que retém o dinheiro — e não
existe tal coisa.

Isto é verdade quer inicies sessão, quer não. O que iniciar sessão muda é o
caminho dos *dados*, não o caminho do dinheiro, e as duas secções seguintes são
honestas sobre exatamente como.

## As tuas chaves, e onde vivem

A configuração pede uma chave de API *restrita* da Stripe, não uma chave secreta
real — essas recusamos por completo. Restrita significa que a chave pode fazer
duas coisas: criar o link de gorjeta paga-o-que-quiseres e observar as gorjetas a
chegar. Não consegue ler o teu saldo, despoletar pagamentos, emitir reembolsos nem
tocar em dados de clientes. Se vazasse amanhã, o raio da explosão é um link de
gorjeta.

**Sem conta, essa chave nunca sai do teu dispositivo.** Fica no porta-chaves do
próprio dispositivo e só alguma vez é enviada para `api.stripe.com` através de TLS.
Não há absolutamente nenhum servidor live.tips no meio.

**Quando inicias sessão, a chave passa para nós** — porque uma chave que só existe
num telemóvel não pode servir também o tablet no palco. Ciframo-la (uma chave
AES-256 por segredo, ela própria envolvida pela Google Cloud KMS) e guardamo-la
onde nada a consegue voltar a ler: nem outra conta, nem nós de relance numa base de
dados, nem sequer tu. Só é aberta dentro das nossas funções, usada para falar com a
Stripe em teu nome, e nunca mais entregue a um dispositivo. Dito às claras: iniciar
sessão coloca um servidor live.tips no caminho entre a Stripe e o teu histórico de
gorjetas. Nunca o dinheiro — os dados.

## Os servidores, e o que não conseguem fazer

São dois, e ambos são mínimos.

**O relé** existe porque a Revolut e a MobilePay não podem ser conduzidas a partir
de um navegador da forma como a Stripe pode. Ativá-las liga um punhado de funções
Firebase que servem a tua página de gorjetas em `tip.live.tips`. Guarda o perfil
público da tua página de gorjetas — o nome de apresentação e os identificadores de
pagamento que escolheste publicar — e, para uma página sem conta por trás, não
mantém histórico de gorjetas: uma gorjeta espera apenas até o teu dispositivo de
palco a mostrar, e tudo aquilo por que ninguém voltou é varrido dentro da hora. Não
vê dinheiro e autoelimina-se após 90 dias de inatividade. Se usares apenas a Stripe
e nunca iniciares sessão, o relé nunca chega a ser contactado.

**O webhook** só existe a partir do momento em que inicias sessão. Como a tua chave
passa agora a viver connosco, a Stripe comunica cada gorjeta a uma pequena função
nossa, que a escreve no teu próprio histórico para que os teus outros dispositivos a
possam mostrar. É uma cópia de um evento, não uma cópia do dinheiro. Não consegue
mover um cêntimo, e só alguma vez consegue escrever na única conta a que pertence.

Nenhum dos servidores consegue ficar com uma fatia, porque nenhum está sequer perto
do dinheiro. O máximo que qualquer deles pode fazer é falhar — e uma configuração
apenas com Stripe e sem conta não depende de nenhum.

## A conta que não tens de criar

A app continua a arrancar num perfil que vive apenas no dispositivo, tal como
sempre foi: o teu mealheiro, a tua chave e o teu histórico de gorjetas estão no
dispositivo e em mais lado nenhum. Não há nada para subscrever.

Iniciar sessão — com a Apple, com a Google ou como convidado — é agora possível, e
existe por uma única razão: um segundo dispositivo. Se o tablet no palco e o
telemóvel no teu bolso têm de mostrar a mesma noite, algo tem de ficar entre eles,
e esse algo é o Firestore, sob um id de utilizador que só tu podes ler. As tuas
bandas, definições, histórico de gorjetas — e, cifrada como acima, a tua chave
Stripe — vivem lá. É uma mudança real na história da privacidade e merece ser dita
às claras em vez de descoberta: sem conta, nenhum servidor vê alguma vez uma
gorjeta; com conta, o teu próprio canto do nosso vê, e é o nosso webhook que a
escreve lá. É o preço do segundo dispositivo, e cabe-te a ti pagá-lo ou recusá-lo.
Aquilo em que nunca toca é o dinheiro — uma conta move os teus dados, não o teu
saldo, e continua a não haver comissão.

## Porque não deves acreditar na nossa palavra

Tudo o que está acima é verificável. O código-fonte tem licença MIT e é público,
e o site é uma compilação estática publicada pelo GitHub Actions no GitHub Pages
— sem infraestrutura escondida, nada compilado atrás de uma porta. Abre o
separador de rede durante uma gorjeta de demonstração e lê os pedidos. São menos
do que esperas.

É essa a verdadeira afirmação do produto. Não que sejamos de confiança, mas que
não precisas que o sejamos.
</content>
