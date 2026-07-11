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

## As gorjetas por cartão nunca passam por nós

Quando um fã toca num valor de cartão, o navegador dele fala com `api.stripe.com`.
Não com um servidor da live.tips — não existe nenhum nesse percurso. O pagamento
é criado na **tua** conta Stripe, é liquidado no **teu** saldo Stripe e é pago
segundo o **teu** calendário Stripe. A única taxa é a taxa de processamento
padrão da própria Stripe, que a Stripe te cobra diretamente, tal como faria se
tivesses integrado a Stripe por ti próprio.

Não há registo do nosso lado porque não há nada a registar. Não conseguiríamos
tirar uma percentagem sem primeiro construir a coisa que retém o dinheiro.

## As tuas chaves continuam a ser tuas

A configuração pede uma chave de API *restrita* da Stripe, não uma chave secreta
real — essas recusamos por completo. É guardada no porta-chaves do teu próprio
dispositivo e só alguma vez é enviada à Stripe através de TLS.

Restrita significa que a chave pode fazer duas coisas: criar o link de gorjeta
paga-o-que-quiseres e observar as gorjetas a chegar. Não consegue ler o teu
saldo, despoletar pagamentos, emitir reembolsos nem tocar em dados de clientes.
Se vazasse amanhã, o raio da explosão é um link de gorjeta.

## O único sítio onde existe um servidor

A Revolut e a MobilePay não podem ser conduzidas a partir de um navegador da
forma como a Stripe pode, por isso ativá-las liga um relé mínimo em
`api.live.tips`. Vale a pena ser preciso sobre o que esse relé faz, porque
«acrescentámos um backend» é normalmente onde estas histórias correm mal.

Guarda o perfil público da tua página de gorjetas — o nome de apresentação e os
identificadores de pagamento que escolheste publicar. É tudo. Não mantém
histórico de gorjetas, não vê dinheiro, não guarda chaves e autoelimina-se após
90 dias de inatividade. O dinheiro continua a mover-se diretamente entre a app
Revolut ou MobilePay do teu fã e a tua.

Se usares apenas a Stripe, o relé nunca chega a ser contactado.

## Porque não deves acreditar na nossa palavra

Tudo o que está acima é verificável. O código-fonte tem licença MIT e é público,
e o site é uma compilação estática publicada pelo GitHub Actions no GitHub Pages
— sem infraestrutura escondida, nada compilado atrás de uma porta. Abre o
separador de rede durante uma gorjeta de demonstração e lê os pedidos. São menos
do que esperas.

É essa a verdadeira afirmação do produto. Não que sejamos de confiança, mas que
não precisas que o sejamos.
