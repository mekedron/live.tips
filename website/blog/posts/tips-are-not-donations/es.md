---
title: Las propinas no son donaciones — y Stripe las trata como dos negocios distintos
description: Un músico callejero que pide un «botón de donaciones» está describiendo un negocio que Stripe prohíbe en casi toda Europa. Una propina paga un servicio que ya prestaste; una donación es recaudación de fondos con fines benéficos. La diferencia decide en qué categoría cae tu cuenta — y un solo parámetro de la API puede elegir la equivocada por ti.
slug: las-propinas-no-son-donaciones
---

Todas las herramientas de internet quieren que lo llames donación. Los botones
dicen *Donate*. Los artículos dicen *botón de donaciones para músicos*. Los
directorios de plugins dicen *acepta donaciones*. Si eres músico y buscas una
forma de cobrar de gente que no lleva efectivo, la palabra te persigue a todas
partes.

Luego abres una cuenta de Stripe, y Stripe te pregunta a qué se dedica tu negocio.
Y en ese momento la palabra deja de ser texto publicitario y se convierte en una
**categoría de negocio** — una que, en casi toda Europa, Stripe no permite.

Esto no es pedantería, ni es una distinción de abogado. Es la pregunta con más
probabilidades de que la cuenta de pagos de un músico callejero perfectamente
corriente acabe revisada, retrasada o rechazada. Casi nadie lo ha escrito con
claridad para los artistas que actúan, así que aquí está.

## Dos palabras, dos negocios

Stripe traza la línea él mismo, en una frase cada una. De
[Requisitos para aceptar propinas o donaciones](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations):

> una propina debe darse por un bien o servicio que se haya prestado (por ejemplo,
> contenido)

> una donación debe estar vinculada a un fin benéfico concreto que te comprometes a
> cumplir

Las páginas de Stripe están en inglés; aquí las citas van traducidas y el original
queda detrás del enlace.

Léelas dos veces, porque todo lo demás en este artículo se desprende de ellas.

Una **propina** mira hacia atrás, a algo que ya ocurrió. El servicio se prestó, al
aficionado le gustó, el aficionado pagó de más. El dinero es incondicional y tú no
debes nada más. Es la línea de propina en la cuenta de un restaurante, las monedas
en el sombrero, el billete de cinco que te ponen en la mano después de la última
canción.

Una **donación** mira hacia adelante, a algo que has prometido hacer. Hay una
causa. Hay un fin que le has descrito a quien te da el dinero. Y — Stripe es
explícito en esto — el dinero tiene que ir realmente a ese fin. Lo tienes en
custodia para algo que dijiste que ibas a lograr.

No son dos matices del mismo acto. Son dos relaciones distintas, con dos conjuntos
distintos de obligaciones, y Stripe las asegura como dos negocios distintos.

## Un músico callejero está de lleno, sin ambigüedad, en el lado de la propina

Estuviste dos horas en una plaza tocando. Se pararon cuarenta personas. Una de
ellas escanea tu código y te manda cinco euros.

**Eso es una propina.** La actuación es el servicio. Se prestó — lo vieron ocurrir.
No hay causa, ni beneficiario, ni fin que te hayas comprometido a cumplir, y nadie
te ha confiado dinero para un proyecto. Eres un artista intérprete al que le pagan
por una actuación, uno de los arreglos comerciales más antiguos y menos polémicos
que existen.

La confusión viene de que la propina de un músico callejero es *voluntaria*, y nos
han enseñado a pensar que el dinero voluntario es dinero benéfico. No lo es. Una
propina también es voluntaria. Lo que convierte algo en donación no es la
voluntariedad — es un **fin benéfico**.

Así que cuando tu cartel dice «se aceptan donaciones», no estás siendo modesto ni
educado. Estás describiendo, en el vocabulario del procesador de pagos, un negocio
en el que no estás.

## Lo que esa palabra te cuesta de verdad

Aquí es donde la abstracción se convierte en dinero.

Stripe publica una
[lista de negocios restringidos](https://stripe.com/legal/restricted-businesses) —
las cosas que no puedes hacer con una cuenta de Stripe, o que solo puedes hacer en
algunos países. Bajo el epígrafe **Crowdfunding y recaudación de fondos** está esta
línea, textual:

> Organizaciones que recaudan fondos con fines benéficos (Nota: admitido en
> Australia, Canadá, el Reino Unido y los Estados Unidos. Prohibido en todos los
> demás países.)

Lee el paréntesis despacio. La recaudación de fondos con fines benéficos es un
**negocio admitido en cuatro países** — Australia, Canadá, el Reino Unido, Estados
Unidos — y **prohibido en todos los demás.**

Todos los demás incluye España, Alemania, Francia, Italia, los Países Bajos,
Polonia, Finlandia y cualquier otro país donde un músico callejero pueda
razonablemente estar de pie. Si tocas en Madrid, en Barcelona o en Sevilla, estás
de lleno dentro de «todos los demás países». Y seamos honestos con la otra mitad de
quienes leen esto en español: si tocas en Estados Unidos, sí estás en uno de los
cuatro países admitidos — la categoría existe allí, pero se revisa a fondo, y sigue
sin ser lo que hace un músico callejero. La mayoría de los artistas de calle del
mundo viven en «todos los demás países».

La misma página también incluye como restringida la *«recaudación de fondos
realizada por organizaciones sin ánimo de lucro, entidades benéficas,
organizaciones políticas y empresas que ofrecen una recompensa a cambio de un
donativo»*, y la página de Stripe sobre propinas y donaciones añade encima un
conjunto de reglas por país: en Japón los particulares no pueden recibir donaciones
en absoluto; en Singapur solo pueden las organizaciones benéficas o religiosas
registradas ante el gobierno; en India, Hong Kong y Tailandia las donaciones no
están admitidas.

Así que una música en Madrid que escribe «donaciones para mi música» en el
formulario de alta de Stripe acaba de describir un negocio que Stripe prohíbe en
España. No porque tocar en la calle esté prohibido — tocar en la calle está
perfectamente bien — sino porque las palabras que eligió pertenecen a una categoría
que sí lo está.

## Ahora la calibración, porque esto no es una historia de terror

**Los músicos callejeros no son un negocio restringido.** Las propinas no son un
negocio restringido. La actuación en directo no está en la lista, no te va a meter
en la lista, y es más o menos la cosa más corriente que se puede hacer con una
cuenta de pagos. Si te describes con precisión, nada de esto te toca y la
configuración es aburrida, que es exactamente como debe ser.

El riesgo aquí no es Stripe. El riesgo es la **autoclasificación errónea** — entrar
en la sala y presentarte como recaudador de fondos benéficos cuando eres
guitarrista. Stripe no tiene forma de saber que querías decir «déjame una propina».
Solo tiene el formulario que rellenaste, la descripción de negocio que escribiste, y
las palabras de la página a la que apunta tu código QR.

Nadie en Stripe está a la caza de músicos callejeros. Simplemente están leyendo lo
que tú les contaste.

## La trampa tiene un solo parámetro de profundidad

Aquí viene la parte que casi nadie escribe, y es lo más útil de este artículo.

Los Payment Links de Stripe tienen un parámetro llamado `submit_type`. La
[referencia de la API](https://docs.stripe.com/api/payment-link/object) lo describe
como algo casi cosmético:

> Indica el tipo de transacción que se realiza, lo que personaliza el texto
> correspondiente de la página, como el botón de envío.

*Personaliza el texto correspondiente.* Concluirías razonablemente que eso cambia
la etiqueta de un botón, y que un bote de propinas obviamente debería decir
'Donate' (donar) en lugar de 'Buy' (comprar), porque *Buy* es una palabra rara para
imprimir bajo el sombrero de un músico callejero.

Luego lees lo que hacen de verdad los valores concretos:

> `donate` — Recomendado al aceptar donaciones. El botón de envío incluye la
> etiqueta 'Donate' y las URL usan el nombre de host `donate.stripe.com`

> `pay` — El botón de envío incluye la etiqueta 'Buy' y las URL usan el nombre de
> host `buy.stripe.com`

**No es una etiqueta. Es un nombre de host.** Pon `submit_type=donate` y el enlace
que Stripe te entrega — el que conviertes en código QR, imprimes y pegas en la
funda de tu guitarra — vive en `donate.stripe.com`. Cada aficionado que lo escanea
ve una página de donaciones. Cada pago de tu panel llegó por un flujo de donación.
El código QR de tu funda le está diciendo a Stripe, le está diciendo a tu público y,
con el tiempo, te está diciendo a ti que estás recogiendo donativos.

Tú no escribiste la palabra «donación» en ninguna parte. Un solo parámetro de la
API la escribió por ti, y la imprimió en un cartel de plástico en una plaza pública.

Es una trampa fácil de pisar, y no es culpa de quien la pisa: el parámetro está
documentado como un cambio de texto, *Donate* es evidentemente la palabra más bonita
para imprimir bajo el sombrero de un músico callejero, y la consecuencia — una
clasificación de negocio — está dos frases más abajo de donde llega casi todo el
mundo leyendo.

live.tips envía `submit_type=pay`. El enlace de cada artista es un enlace
`buy.stripe.com`, y el código lleva un comentario que explica por qué, porque es de
esas cosas que un futuro colaborador «mejoraría» si no estuviera.

## Lo que un músico debería hacer de verdad

Nada de esto requiere un abogado. Requiere cinco minutos y unas cuantas palabras
claras.

- **Describe el negocio real** en el alta de Stripe. «Actuaciones de música en
  directo.» «Músico callejero.» «Música — propinas del público en actuaciones en
  directo.» Di que actúas, y que los pagos son propinas por esas actuaciones.
- **Elige una categoría que encaje.** Entretenimiento en directo, artes escénicas,
  músico. Ni beneficencia, ni entidad sin ánimo de lucro, ni recaudación de fondos.
- **Usa `submit_type=pay`** si construyes tú mismo el Payment Link. Si te lo
  construyó una herramienta, mira la URL que produjo: `buy.stripe.com` es un bote de
  propinas, `donate.stripe.com` es una página de donaciones. Es una comprobación de
  dos segundos, y te dice qué cree tu herramienta que eres.
- **No lo llames donación** — ni en el cartel, ni en tu web, ni en la descripción de
  negocio de Stripe. «Propinas», «bote de propinas», «apoya a la banda», «invítanos
  a una caña» describen todas lo que está pasando. «Dona» describe otra cosa.
- **Mantén aparte una recaudación de verdad.** Si tocas un concierto benéfico y el
  dinero va a una causa, eso *sí* es genuinamente recaudación de fondos con fines
  benéficos, y las reglas de arriba ahora van sobre ti — incluida la lista de
  países. Hazlo con la cuenta correcta, en el país correcto, habiendo leído los
  términos de Stripe, y nunca a través del bote de propinas que usas las noches
  normales.

Ese último punto merece énfasis, porque es la mitad honesta del argumento. No
estamos diciendo que las donaciones sean malas, ni que un músico nunca pueda
recaudar dinero para una causa. Estamos diciendo que es una **actividad distinta**,
con reglas distintas, y que colarla en silencio por el mismo código QR es la manera
de meterte en problemas con las dos.

Merece la pena conocer otra línea de la página de propinas y donaciones de Stripe,
porque descarta una tercera cosa que la gente confunde con ambas: Stripe no hace
*«procesamiento de pagos para transmisión de dinero personal o entre pares (por
ejemplo, enviar dinero entre amigos)»*. Una propina tampoco es un regalo entre
amigos. Si quieres esa vía — un aficionado que simplemente te manda dinero, de
persona a persona — eso es exactamente lo que son Revolut y MobilePay, y por eso
viven [enteramente fuera de Stripe](post:one-qr-code-every-payment-method) en
nuestra app.

## Lo que este artículo no es

No es asesoramiento legal. No es asesoramiento fiscal — cómo tributan las propinas
varía enormemente según el país, a veces según la ciudad, y queda completamente
fuera del alcance de esto; pregúntale a alguien cualificado donde vivas.

Y no es una promesa sobre tu cuenta. **Que Stripe te apruebe es decisión exclusiva
de Stripe.** live.tips no tiene relación con Stripe, ni capacidad de influir en una
revisión, ni forma de recurrirla en tu nombre. Lo que nuestro software sí puede
hacer es no ponerte palabras en la boca. Lo que escribas en el formulario lo sigues
escribiendo tú.

Las políticas también cambian. Las líneas citadas aquí estaban en las páginas de
Stripe en julio de 2026, y los enlaces están ahí mismo; ve a leerlas tú en lugar de
fiarte de un artículo de blog, incluido este.

## La versión corta

Tocaste el set. Lo vieron. Te pagaron por él.

Eso es una propina. Dilo así — en el cartel, en el formulario, en la URL — y el
resultado aburrido que quieres es el que obtienes. Construimos el bote de propinas
exactamente en torno a esa afirmación, hasta el detalle de
[a qué nombre de host de Stripe apunta tu código QR](post:build-a-tip-jar-on-your-own-stripe),
y si quieres el panorama completo de a dónde va realmente el dinero, está
[aquí](post:how-live-tips-handles-money).
