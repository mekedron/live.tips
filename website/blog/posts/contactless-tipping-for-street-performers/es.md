---
title: Propinas sin contacto para músicos callejeros, con honestidad
description: Tap to Pay en el móvil, un lector de tarjetas, una pegatina NFC, un código QR — cuatro cosas distintas a las que se llama «sin contacto». Lo que cuesta de verdad cada una en 2026, lo que hace realmente una etiqueta NFC (no es lo que crees), y cuándo un toque gana al escaneo.
slug: propinas-sin-contacto-para-musicos-callejeros
---

Busca «propinas sin contacto para músicos callejeros» e internet te devuelve al
2018. Un prototipo estudiantil de la Brunel University llamado Tiptap — un soporte
en el que encajas un móvil — tuvo su ronda de prensa aquel año, y esa prensa sigue
en la primera página de resultados. Era una idea bonita. También estaba, en palabras
de la propia cobertura, *todavía en fase de desarrollo*, y planeaba cobrar a los
músicos callejeros una cuota única más un **5 % de cada propina**. Nunca llegó a ser
algo que puedas comprar.

(El «tiptap» que encontrarás si lo buscas ahora es una empresa de Ontario sin
relación alguna, que vende terminales de donación sin contacto a organizaciones
benéficas. Misma palabra, otro producto, no es para ti.)

Así que el estado honesto de la cuestión lleva ocho años sin escribirse. Aquí está.

Esto es la inmersión en el tap. Si tu pregunta de verdad es la más amplia — todas
las formas de cobrar ahora que nadie lleva efectivo, y lo que cuesta cada una —,
empieza por [cómo cobran con tarjeta los músicos
callejeros](post:how-buskers-take-card-payments) y vuelve luego aquí.

## Cuatro cosas distintas se llaman todas «sin contacto»

Aquí es donde vive casi toda la confusión, así que separémoslas antes de ponerle
precio a nada.

1. **Tap to Pay en tu propio móvil.** Tu teléfono se convierte en el terminal. El fan
   acerca su tarjeta o su reloj a *tu* aparato. Cero hardware extra.
2. **Un lector de tarjetas** — un SumUp, un Zettle, un Square. Un pequeño terminal de
   plástico que le tiendes. El fan lo toca.
3. **Una etiqueta NFC** — la pegatina o la placa de «toca aquí para dejar propina».
   Esta se malinterpreta de forma casi universal, y la siguiente sección explica por
   qué.
4. **Un código QR.** No es sin contacto en el sentido NFC — pero sigue leyendo, porque
   desde el lado del fan acaba muy a menudo en exactamente el mismo toque.

Solo los dos primeros son *terminales de pago*. Toda esta entrada trata de esa
distinción.

## La etiqueta NFC no cobra un pago

Rematemos esto como es debido, porque a los vendedores les encanta dejar que creas
lo contrario.

Una pegatina NFC — la barata, el chip NTAG213 que usan casi todas — tiene **144
bytes de memoria**. No 144 kilobytes. No puede ejecutar código, no tiene batería,
jamás ha oído hablar de una red de tarjetas, y no podría albergar un protocolo de
pago aunque quisiera. Lo que sí alberga es una cadena corta, con formato de registro
NDEF, y esa cadena es abrumadoramente una **URL**.

La tocas y tu móvil abre una página web. Esa es toda la funcionalidad.

Lo que significa que una placa de «toca para dejar propina» es un código QR que
abres tocando en lugar de apuntando. Mismo destino, misma página web, mismo pago
ocurriendo en el navegador. Hasta los especialistas lo dicen si los lees con
atención: la propia web de tiptap describe su dispositivo de importe libre como uno
en el que *«cuando los donantes acercan el móvil a un dispositivo de donación
personalizado, se les dirige a tu página de recaudación online»*. Dirigidos a una
página. Porque eso es lo que una etiqueta puede hacer.

Esto es genuinamente útil, y además es barato — las pegatinas NTAG213 vírgenes
parten de unos **0,24 $ cada una** en packs. Si ya tienes una página de propinas,
pegar una etiqueta en el estuche junto al código impreso te cuesta calderilla y le
da a algunos fans una entrada más rápida.

Pero ten claro lo que has comprado: **una segunda puerta de entrada a la misma
página.** No una máquina de tarjetas.

### Y a la intemperie es una puerta quisquillosa

Los modos de fallo son reales, y nadie que venda etiquetas los enumera:

- **El móvil del fan tiene que estar desbloqueado y en uso.** La documentación de
  Apple es explícita: la lectura de etiquetas en segundo plano solo ocurre mientras
  el iPhone está en uso, y si el teléfono está bloqueado el sistema le obliga a
  desbloquearlo primero.
- **No funciona con la cámara abierta.** Apple enumera la cámara en uso como uno de
  los estados en que la lectura de etiquetas en segundo plano no está disponible.
  Saborea la ironía: un fan que echa mano de la cámara para escanear tu código QR
  acaba de desactivar tu etiqueta NFC.
- **Necesita un iPhone XS o posterior**, y en Android necesita el NFC encendido — que
  algunos modos de ahorro de energía apagan.
- **El alcance es de unos 4 cm.** El fan tiene que tocar la cosa de verdad. Entre la
  multitud, agachándose hacia un estuche de guitarra, eso es pedir mucho.
- **El metal y los imanes lo matan.** Una etiqueta pegada a un amplificador, o un fan
  con una funda magnética, y no pasa absolutamente nada.

Una etiqueta es una buena segunda opción. Es una mala opción única.

## Tap to Pay en el móvil: la noticia real de 2026

Esto es lo que ha cambiado desde los artículos de Tiptap, y de lo que ninguna de esa
cobertura rancia se ha enterado.

**Tap to Pay en el iPhone** convierte el teléfono que ya llevas en el bolsillo en un
terminal sin contacto. Sin dongle, sin lector, sin soporte. Apple lo da por
disponible en **más de 70 países y regiones**, y los proveedores a través de los que
puedes usarlo en Europa se parecen al sector entero — solo en Alemania: Adyen,
Mollie, myPOS, Nexi, PAYONE, Rapyd, Revolut, Sparkassen, Stripe, SumUp, Viva.com. El
Reino Unido, Francia, los Países Bajos, Suecia, Finlandia y Dinamarca tienen listas
parecidas. Necesitas un iPhone XS o posterior.

**Tap to Pay en Android** también existe, pero es más estrecho. A través de Stripe,
está disponible de forma general en AT, AU, BE, CA, CH, DE, DK, FI, FR, GB, IE, IT,
MY, NL, NZ, PL, SE, SG y US, con otros dieciocho países en vista previa pública. Tu
móvil necesita Android 13 o posterior, un sensor NFC, un bootloader sin rootear,
Google Mobile Services y las opciones de desarrollador desactivadas — lo último pilla
a más gente de la que crees.

La versión práctica: **SumUp ofrece Tap to Pay con 0 £ de hardware.** Si tienes un
iPhone reciente y estás en un país compatible, el coste de entrada para tender un
terminal sin contacto es ahora cero. Ese solo hecho vuelve obsoleto cada artículo de
«cómprate este soporte» de 2018.

## Los lectores de tarjetas, y lo que cuestan de verdad

Si quieres un trozo de plástico aparte — y hay buenas razones para ello, más abajo —
el mercado son tres productos.

| | Hardware | Comisión por pago presencial |
| --- | --- | --- |
| **SumUp** (UK) | Tap to Pay 0 £ · Solo Lite 25 £ · Solo 79 £ · Terminal 135 £ | **1,69 %**, sin cuota fija |
| **SumUp** (Alemania) | — | **1,39 %**, sin cuota fija |
| **Zettle / PayPal POS** (UK) | Lector desde 29 £ la primera vez, 69 £ después | **1,75 %**, sin cuota fija |
| **Square** (UK) | Lector sin contacto y de chip 19 £ | **1,75 %**, sin cuota fija |
| **Square** (US) | Lector sin contacto y de chip 59 $ | **2,6 % + 0,15 $** |

Precios sin IVA y tal como estaban publicados en julio de 2026. Ve a comprobarlos; se
mueven.

Ahora lee la tabla otra vez, porque dice algo que contradice lo que probablemente te
han contado.

## Las cuentas de las comisiones, y lo que todo el mundo entiende al revés

La sabiduría recibida dice que las comisiones de tarjeta destrozan las propinas
pequeñas por culpa del cargo fijo por transacción — los veinticinco céntimos que se
comen un octavo de una propina de 2 €. Eso es cierto, y nosotros mismos
[hemos escrito las cuentas](post:build-a-tip-jar-on-your-own-stripe).

Pero es cierto de los pagos con tarjeta *online*. **Los lectores sin contacto
europeos, en su mayoría, no tienen cuota fija ninguna.** SumUp, Zettle y Square en el
Reino Unido y la UE cobran solo un porcentaje. Lo que significa:

| Una propina de 2 € | Comisión | Le queda al artista | Recorte efectivo |
| --- | --- | --- | --- |
| Lector SumUp (DE, 1,39 %) | 0,03 € | 1,97 € | **1,4 %** |
| Zettle / Square (UK, 1,75 %) | 0,04 € | 1,96 € | 1,8 % |
| Stripe, tarjeta online (EEE, 1,5 % + 0,25 €) | 0,28 € | 1,72 € | **14,0 %** |
| Lector Square (US, 2,6 % + 0,15 $) | 0,20 $ | 1,80 $ | **10,1 %** |

Solo por la comisión, un terminal de toque europeo le gana a un pago con tarjeta
online en una propina pequeña, y no está ni cerca. Somos un producto de código QR y
te lo estamos diciendo: en una propina de 2 €, un lector SumUp te deja 0,25 € que una
página alojada por Stripe no te deja.

Dos cosas devuelven eso a su proporción.

**El hardware es la cuota fija, cambiada de sitio.** Un ahorro de 0,25 € por propina
frente a un Solo de 79 £ significa aproximadamente **trescientos toques hasta que el
lector se haya pagado solo**. Es una cifra real para un músico callejero que trabaja,
y una tontería para quien toca dos veces al verano. (Y el Tap to Pay de 0 £ de SumUp
lo deja en cero toques — que es exactamente por qué esa opción importa más que los
lectores.)

**Y Estados Unidos le da la vuelta otra vez.** La tarifa presencial americana de
Square lleva 0,15 $ de cuota fija, así que un toque de 2 $ también pierde una décima
parte de sí mismo en el terminal. El regalo de «sin cuota fija» es europeo.

Hay además un suelo con el que te encontrarás: SumUp no acepta un pago por debajo de
**1 £ / 1 €**. Elijas la vía que elijas, la propina muy pequeña no es realmente una
transacción con tarjeta.

## Entonces, ¿cuándo gana un toque a un escaneo?

Quítale la tecnología y esto es una pregunta sobre las manos del fan.

**Un toque necesita el móvil del fan desbloqueado y en su mano, y necesita que tú
tiendas algo.** Cuando ambas cosas se cumplen, es lo más rápido que existe en los
pagos. Sin app, sin apuntar, sin teclear, resuelto en un segundo.

**Un escaneo necesita que el fan abra una cámara** — un acto deliberado más — pero no
necesita nada de ti. El código está en el estuche. Funciona con un fan que está al
fondo. Funciona con cuarenta personas a la vez. Funciona mientras tú sigues tocando.

Lo que da un reparto honesto:

- **El toque gana cuando puedes acercarte a la gente.** Final del set, la gorra
  dando la vuelta, un fan cada vez, tú libre para sostener un terminal. Un toque es
  una petición con menos fricción que «saca la cámara», y en ese momento estás
  físicamente presente para cerrarla.
- **El escaneo gana cuando no puedes.** A mitad de canción. Un público de tres filas
  de fondo. Un sitio del que no puedes separarte del amplificador. Cualquiera que
  quiera dar de paso. Un terminal atiende exactamente a una persona; un código
  impreso atiende a la plaza entera, a la vez, y no necesita que dejes de tocar para
  atenderlo.

Ese último punto es el que los vendedores de terminales nunca hacen, y es el más
grande. **Un lector de tarjetas es un cuello de botella con cola.** Un código QR no
tiene cola.

Y aquí está lo que disuelve la mitad de la discusión: en una página de propinas bien
construida, **el escaneo acaba igualmente en un toque**. El fan escanea, se abre la
página, y su móvil le ofrece Apple Pay o Google Pay. Doble clic, se acerca el
teléfono a la cara, hecho. Desde el lado del fan eso es un pago sin contacto — misma
wallet, misma tarjeta, los mismos dos segundos — y tú no compraste hardware alguno
para que ocurriera.

## Dónde encaja live.tips, y cuándo comprar un SumUp en su lugar

[live.tips](https://github.com/mekedron/live.tips) es un bote de propinas basado en
QR. Un código, que nunca cambia, apuntando directo al propio enlace de pago de Stripe
del artista. No hay saldo de live.tips, ni recorte, ni plataforma en el camino — la
comisión es la de Stripe y Stripe se la cobra al artista directamente. Tiene licencia
MIT, y la tablet del escenario muestra cada propina en el momento en que aterriza.
Escribimos el recorrido del dinero en
[cómo live.tips gestiona el dinero](post:how-live-tips-handles-money), y por qué es
[un código en lugar de uno por proveedor](post:one-qr-code-every-payment-method).

Esa página admite Apple Pay y Google Pay. Así que live.tips *sí* es sin contacto
desde el lado del fan — el toque que importa, el del final, sin terminal que comprar,
cargar ni dejar caer bajo la lluvia. Simplemente no es un terminal.

**Si lo que quieres es tender algo físicamente y que un desconocido lo toque, compra
un lector de tarjetas.** Coge el Tap to Pay de SumUp si tu móvil y tu país lo
soportan, porque no cuesta nada; coge un Solo si prefieres no ponerle tu propio móvil
en las manos a una multitud. Sea como sea, en un toque de 2 € en Europa le ganará a
nuestra comisión, y preferimos decirlo antes que fingir lo contrario.

También puedes hacer las dos cosas, y muchos músicos callejeros deberían: el código
pegado al estuche toda la noche, cazando a los que pasan mientras tocas, y el
terminal en la mano para los diez segundos después del último acorde, cuando la
primera fila se lleva la mano al bolsillo. No compiten. Cazan a gente distinta.

Lo que ninguno de los dos es: un soporte de 2018 que se lleva el 5 %.

Comisiones, precios de hardware y disponibilidad por países tal como los publican Apple, Stripe, SumUp, Zettle/PayPal y Square en julio de 2026, sin IVA. Precios de las pegatinas NFC según GoToTags. Las condiciones de Tiptap en 2018 según lo informado por la Brunel University y Finextra. Todo esto cambia; contrástalo con el proveedor antes de gastar dinero.
{: .footnote }
