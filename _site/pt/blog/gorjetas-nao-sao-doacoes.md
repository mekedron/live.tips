# Gorjetas não são doações — e a Stripe trata-as como dois negócios diferentes

> Um artista de rua que pede um «botão de doações» está a descrever um negócio que a Stripe proíbe em quase toda a Europa. Uma gorjeta paga um serviço que já prestaste; uma doação é angariação de fundos para fins beneficentes. A diferença decide em que categoria cai a tua conta — e há um parâmetro de API que pode escolher a errada por ti.

Canonical: https://live.tips/pt/blog/gorjetas-nao-sao-doacoes/
Published: 2026-07-11
Language: pt
Tags: Stripe, donations, busking, compliance, how-to

---

Todas as ferramentas da internet querem que chames a isto uma doação. Os botões
dizem *Doar*. Os artigos dizem *botão de doações para músicos*. Os diretórios de
plugins dizem *aceita doações*. Se és músico à procura de uma forma de seres pago
por pessoas que não trazem dinheiro vivo, a palavra persegue-te por todo o lado.

Depois abres uma conta Stripe, e a Stripe pergunta-te o que faz o teu negócio. E
nesse momento a palavra deixa de ser texto de marketing e passa a ser uma
**categoria de negócio** — uma que, em quase toda a Europa, a Stripe não permite.

Isto não é pedantice, e não é uma distinção de advogado. É a pergunta com maior
probabilidade de deixar a conta de pagamentos de um artista de rua perfeitamente
vulgar em revisão, atrasada ou recusada. Quase ninguém a escreveu por extenso para
quem toca na rua, por isso aqui vai.

## Duas palavras, dois negócios

A própria Stripe traça a linha, com uma frase de cada lado. De
[Requisitos para aceitar gorjetas ou doações](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations):

> uma gorjeta tem de ser dada por um bem ou serviço que já foi prestado (por
> exemplo, conteúdo)

> uma doação tem de estar ligada a um fim beneficente específico que te
> comprometes a cumprir

As páginas da Stripe estão em inglês; traduzimo-las aqui para ti, e os originais
estão atrás dos links.

Lê estas duas frases devagar, porque tudo o resto neste artigo sai delas.

Uma **gorjeta** olha para trás, para algo que já aconteceu. O serviço foi prestado,
o fã gostou, o fã pagou a mais. O dinheiro é incondicional e tu não deves mais nada
a ninguém. É a linha da gorjeta na conta do restaurante, são as moedas no chapéu, é
a nota de cinco euros enfiada na mão depois da última canção.

Uma **doação** olha para a frente, para algo que prometeste fazer. Há uma causa. Há
um fim que descreveste a quem te está a dar. E — a Stripe é explícita quanto a isto
— o dinheiro tem mesmo de ir para esse fim. Estás a guardá-lo em confiança para uma
coisa que disseste que ias cumprir.

Não são dois tons do mesmo gesto. São duas relações diferentes, com dois conjuntos
de obrigações diferentes, e a Stripe subscreve-as como dois negócios diferentes.

## Um artista de rua está clara e inequivocamente do lado da gorjeta

Estiveste duas horas numa praça a tocar. Pararam quarenta pessoas. Uma delas
digitaliza o teu código e envia-te cinco euros.

**Isso é uma gorjeta.** A atuação é o serviço. Foi prestado — viram-no acontecer.
Não há causa, não há beneficiário, não há fim que te tenhas comprometido a cumprir,
e ninguém te confiou dinheiro para um projeto. És um artista a ser pago por uma
atuação, que é um dos arranjos comerciais mais antigos e menos controversos que
existem.

A confusão nasce do facto de a gorjeta de um artista de rua ser *voluntária*, e de
nos terem treinado a pensar que dinheiro voluntário é dinheiro beneficente. Não é.
Uma gorjeta também é voluntária. Não é a voluntariedade que faz de algo uma doação —
é um **fim beneficente**.

Por isso, quando o teu cartaz diz «aceitam-se doações», não estás a ser modesto nem
educado. Estás a descrever, no vocabulário do processador de pagamentos, um negócio
em que não estás.

## O que a palavra te custa mesmo

É aqui que a abstração se transforma em dinheiro.

A Stripe publica uma
[lista de negócios restritos](https://stripe.com/legal/restricted-businesses) — as
coisas que não podes fazer com uma conta Stripe, ou que só podes fazer em alguns
países. Debaixo do título **Crowdfunding e angariação de fundos** está esta linha,
tal e qual:

> Organizações que angariam fundos para um fim beneficente (Nota: suportado na
> Austrália, no Canadá, no Reino Unido e nos Estados Unidos. Proibido em todos os
> outros países.)

Lê o parêntesis com calma. A angariação de fundos para fins beneficentes é um
**negócio suportado em quatro países** — Austrália, Canadá, Reino Unido, Estados
Unidos — e **proibido em todos os outros.**

Todos os outros incluem Portugal e o Brasil, e incluem a Alemanha, a França, a
Espanha, a Itália, os Países Baixos, a Polónia, a Finlândia e todos os outros países
onde um artista de rua possa razoavelmente estar de pé. O Brasil aparece noutro
ponto da lista da Stripe, mas só a propósito de rifas e sorteios beneficentes — a
angariação de fundos para fins beneficentes é proibida lá tal como em Portugal. A
maior parte dos artistas de rua do mundo vive em «todos os outros países».

A mesma página lista também *«angariação de fundos conduzida por organizações sem
fins lucrativos, instituições de solidariedade, organizações políticas e empresas
que oferecem uma recompensa em troca de donativo»* como restrita, e a página da
Stripe sobre gorjetas e doações acrescenta ainda um conjunto de regras por país: no
Japão os particulares não podem sequer receber doações; em Singapura só o podem
fazer organizações beneficentes ou religiosas registadas junto do Estado; na Índia,
em Hong Kong e na Tailândia as doações não são suportadas.

Portanto, um músico em Lisboa que escreve «doações para a minha música» no
formulário de registo da Stripe acabou de descrever um negócio que a Stripe proíbe
em Portugal. Não porque tocar na rua seja proibido — tocar na rua está
completamente bem —, mas porque as palavras que escolheu pertencem a uma categoria
que é.

## Agora a calibração, porque isto não é uma história de terror

**Os artistas de rua não são um negócio restrito.** As gorjetas não são um negócio
restrito. A atuação ao vivo não está na lista, não te vai pôr na lista, e é das
coisas mais banais que podes fazer com uma conta de pagamentos. Se te descreveres
com rigor, nada disto te toca e a configuração é aborrecida, que é exatamente como
deve ser.

O risco aqui não é a Stripe. O risco é a **auto-classificação errada** — entrares na
sala e anunciares-te como angariador de fundos beneficentes quando és guitarrista.
A Stripe não tem forma de saber que querias dizer «dá-me uma gorjeta, por favor».
Só tem o formulário que preencheste, a descrição de negócio que escreveste e as
palavras na página para onde o teu código QR aponta.

Ninguém na Stripe anda à caça de artistas de rua. Estão simplesmente a ler o que
lhes disseste.

## A armadilha tem a profundidade de um parâmetro

Aqui está a parte que quase ninguém escreve, e é a coisa mais útil deste artigo.

Os Payment Links da Stripe têm um parâmetro chamado `submit_type`. A
[referência da API](https://docs.stripe.com/api/payment-link/object) descreve-o como
algo quase cosmético:

> Indica o tipo de transação a ser efetuada, o que personaliza o texto relevante na
> página, como o botão de submissão.

*Personaliza o texto relevante.* Concluirias, com toda a razão, que aquilo muda a
etiqueta de um botão, e que um pote de gorjetas obviamente devia dizer *Donate*
(«doar») em vez de *Buy* («comprar»), porque *Buy* é uma palavra estranha para se
imprimir debaixo do chapéu de um artista de rua.

Depois lês o que cada valor faz de facto:

> `donate` — Recomendado para aceitar doações. O botão de submissão inclui a
> etiqueta 'Donate' e os URLs usam o nome de anfitrião `donate.stripe.com`

> `pay` — O botão de submissão inclui a etiqueta 'Buy' e os URLs usam o nome de
> anfitrião `buy.stripe.com`

**Não é uma etiqueta. É um nome de anfitrião.** Defines `submit_type=donate` e o
link que a Stripe te entrega — aquele que transformas em código QR, imprimes e colas
na caixa da guitarra — vive em `donate.stripe.com`. Cada fã que o digitaliza vê uma
página de doações. Cada pagamento no teu painel entrou por um fluxo de doações. O
código QR na tua caixa está a dizer à Stripe, a dizer à tua audiência e, a certa
altura, a dizer-te a ti que estás a recolher doações.

Nunca escreveste a palavra «doação» em lado nenhum. Um parâmetro de API escreveu-a
por ti, e imprimiu-a num cartaz de plástico numa praça pública.

É uma armadilha fácil de pisar, e a culpa não é de quem a pisa: o parâmetro está
documentado como uma mudança de texto, *Donate* é claramente a palavra mais simpática
para imprimir debaixo do chapéu de um artista de rua, e a consequência — uma
classificação de negócio — está duas frases mais abaixo do que a maior parte das
pessoas lê.

O live.tips envia `submit_type=pay`. O link de cada artista é um link
`buy.stripe.com`, e o código traz um comentário a dizer porquê, porque é o género de
coisa que um futuro contribuidor, de outro modo, iria «melhorar».

## O que um músico deve mesmo fazer

Nada disto exige um advogado. Exige cinco minutos e algumas palavras simples.

- **Descreve o negócio real** no registo da Stripe. «Atuações de música ao vivo.»
  «Artista de rua.» «Músico — gorjetas do público em atuações ao vivo.» Diz que
  atuas, e que os pagamentos são gorjetas por essas atuações.
- **Escolhe uma categoria que combine.** Entretenimento ao vivo, artes performativas,
  músico. Não caridade, não instituição sem fins lucrativos, não angariação de
  fundos.
- **Usa `submit_type=pay`** se construíres o Payment Link tu mesmo. Se foi uma
  ferramenta que o construiu por ti, olha para o URL que produziu:
  `buy.stripe.com` é um pote de gorjetas, `donate.stripe.com` é uma página de
  doações. É uma verificação de dois segundos, e diz-te o que a tua ferramenta acha
  que tu és.
- **Não lhe chames doação** — nem no cartaz, nem no teu site, nem na descrição de
  negócio da Stripe. «Gorjetas», «pote das gorjetas», «apoia a banda», «paga-nos uma
  cerveja» descrevem todos o que está a acontecer. «Doa» descreve outra coisa.
- **Mantém separada uma angariação a sério.** Se tocas num concerto solidário e o
  dinheiro vai para uma causa, isso *é* genuinamente angariação de fundos para fins
  beneficentes, e as regras acima passam a ser sobre ti — incluindo a lista de
  países. Fá-lo na conta certa, no país certo, depois de leres os termos da Stripe, e
  nunca através do pote de gorjetas que usas nas noites normais.

Este último merece ênfase, porque é a metade honesta do argumento. Não estamos a
dizer que as doações são más nem que um músico nunca pode angariar dinheiro para uma
causa. Estamos a dizer que é uma **atividade diferente**, com regras diferentes, e
que passá-la em silêncio pelo mesmo código QR é a forma de te meteres em sarilhos
com as duas.

Há mais uma linha da página de gorjetas e doações da Stripe que vale a pena conhecer,
já que exclui uma terceira coisa que as pessoas confundem com ambas: a Stripe não
faz *«processamento de pagamentos para transmissão de dinheiro pessoal ou entre
pares (por exemplo, enviar dinheiro entre amigos)»*. Uma gorjeta também não é uma
prenda entre amigos. Se queres esse trilho — um fã a enviar-te dinheiro, de pessoa
para pessoa —, é isso que são o Revolut e o MobilePay, e é por isso que esses vivem
[inteiramente fora da Stripe](https://live.tips/pt/blog/um-codigo-qr-todos-os-metodos/) na nossa app.

## O que este artigo não é

Não é aconselhamento jurídico. Não é aconselhamento fiscal — a forma como as
gorjetas são tributadas varia enormemente de país para país, às vezes de cidade para
cidade, e está completamente fora do âmbito daqui; pergunta a alguém qualificado no
sítio onde vives.

E não é uma promessa sobre a tua conta. **A decisão de te aprovar ou não é apenas da
Stripe.** O live.tips não tem qualquer relação com a Stripe, nem capacidade de
influenciar uma revisão, nem forma de recorrer dela em teu nome. O que o nosso
software pode fazer é evitar pôr-te palavras na boca. O que escreves no formulário
continua a ser teu.

As políticas também mudam. As linhas aqui citadas estavam nas páginas da Stripe em
julho de 2026, e os links estão mesmo ali; vai lê-los tu em vez de confiares num
artigo de blogue, incluindo este.

## A versão curta

Tocaste o teu set. Eles viram-no. Pagaram-te por ele.

Isso é uma gorjeta. Di-lo — no cartaz, no formulário, no URL — e o resultado
aborrecido que queres é o resultado que tens. Construímos o pote de gorjetas em
torno exatamente dessa afirmação, até ao nível de
[para que nome de anfitrião da Stripe aponta o teu código QR](https://live.tips/pt/blog/monte-um-pote-de-gorjetas-na-sua-propria-conta-stripe/),
e se quiseres o quadro mais amplo de para onde vai realmente o dinheiro, está
[aqui](https://live.tips/pt/blog/como-a-live-tips-lida-com-o-dinheiro/).
