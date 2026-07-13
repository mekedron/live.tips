# Monta un bote de propinas en tu propia cuenta de Stripe

> Tres llamadas a la API te dan una página alojada de precio libre con Apple Pay y Google Pay, sin ningún servidor. Aquí está el montaje completo: la clave restringida, los permisos, cómo leer las propinas sin webhook y las cuentas de comisiones que nadie imprime.

Canonical: https://live.tips/es/blog/monta-un-bote-de-propinas-en-tu-propia-cuenta-de-stripe/
Published: 2026-07-11
Language: es
Tags: Stripe, open source, how-to, API, fees

---

Quieres un bote de propinas. No quieres entregarle a una plataforma el 5 % de la
noche de un músico callejero, y eres perfectamente capaz de hablar con una API. Así
que la pregunta no es *en qué bote de propinas me registro*, sino *cuánto tengo que
construir de verdad*.

Menos de lo que crees. En Stripe la respuesta práctica son tres llamadas a la API:
sin servidor, sin backend, sin endpoint de webhook. El resto de este artículo es ese
montaje, más las dos cosas que todo el mundo hace mal.

## El truco es un Price de precio libre

Stripe tiene un modo de precio en el que el fan escribe la cantidad. Se llama
[pay what you want](https://docs.stripe.com/payments/checkout/pay-what-you-want) y es
la funcionalidad entera. Creas un Product, le enganchas un Price con
`custom_unit_amount[enabled]=true` y encima cuelgas un
[Payment Link](https://docs.stripe.com/payment-links/create).

```sh
# 1. la cosa que "vendes"
curl https://api.stripe.com/v1/products \
  -u "$RK:" \
  -d name="Tips — Mira" \
  -d "metadata[managed_by]"=my-tip-jar

# 2. el precio que elige el fan
curl https://api.stripe.com/v1/prices \
  -u "$RK:" \
  -d product=prod_... \
  -d currency=eur \
  -d "custom_unit_amount[enabled]"=true \
  -d "custom_unit_amount[preset]"=500 \
  -d "custom_unit_amount[minimum]"=200

# 3. la página
curl https://api.stripe.com/v1/payment_links \
  -u "$RK:" \
  -d "line_items[0][price]"=price_... \
  -d "line_items[0][quantity]"=1 \
  -d submit_type=pay
```

Esa tercera llamada devuelve una `url`. Esa URL *es* tu bote de propinas. Es una
página alojada por Stripe: cumple PCI sin que tengas que pensarlo, está localizada y
muestra Apple Pay o Google Pay a cualquier fan cuyo teléfono los tenga configurados
— los [métodos de pago dinámicos](https://docs.stripe.com/payments/payment-methods/dynamic-payment-methods)
lo deciden por ti según el dispositivo y el país. No has escrito ni una línea de
frontend.

Codifica la URL como código QR con la librería que quieras — es solo una cadena de
texto —, imprímela y pégala en la funda. El código no caduca nunca y no apunta a
ningún servidor tuyo, porque no tienes ninguno.

Dos parámetros que conviene conocer:

- **`custom_unit_amount[preset]`** es la cantidad con la que abre la página. `500`
  significa que el fan ve 5,00 € ya rellenados y puede cambiarlo. Ese número hace más
  por tu propina media que cualquier otra cosa de la página.
- **`custom_unit_amount[minimum]`** es un suelo. Ponlo. El motivo está en la sección
  de comisiones, y no es un error de redondeo.

También puedes recoger un nombre y un mensaje. Los Payment Links admiten hasta tres
`custom_fields`, que es como consigues el "¿de quién era eso?" sin construir un
formulario:

```sh
  -d "custom_fields[0][key]"=nickname \
  -d "custom_fields[0][type]"=text \
  -d "custom_fields[0][label][type]"=custom \
  -d "custom_fields[0][label][custom]"="Tu nombre o apodo" \
  -d "custom_fields[0][optional]"=true
```

Stripe tiene [requisitos para aceptar propinas y donaciones](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations):
léelos una vez. El precio libre tampoco se puede combinar con otros line items,
descuentos ni pagos recurrentes. Para un bote de propinas, nada de eso molesta.

Esa distinción conviene tenerla clara. Stripe lo dice así: una propina se da por un bien
o servicio ya prestado, mientras que una donación debe estar ligada a un fin benéfico.
Tocaste el bolo; la propina lo paga. Por eso la llamada de arriba manda `submit_type=pay`
y no `donate` — `donate` alojaría tu enlace en `donate.stripe.com` y pondría *Donar* en el
botón. Es otro negocio, y uno que Stripe revisa mucho más a fondo.

## La clave: da por hecho que se filtrará, y haz que eso sea aburrido

No pongas una clave secreta (`sk_live_…`) en un dispositivo que va a estar en un
escenario. Usa una [clave restringida](https://docs.stripe.com/keys/restricted-api-keys)
(`rk_live_…`): eliges un permiso por recurso, y todo lo que no elijas queda en **None**.

Para el montaje de arriba, la lista completa son cinco filas:

| Recurso | Permiso | Para qué sirve |
| --- | --- | --- |
| Products | Write | crear el Product |
| Prices | Write | crear el Price de precio libre |
| Payment Links | Write | crear el enlace |
| Checkout Sessions | Read | ver las propinas que han entrado |
| Events | Read | el feed en directo (siguiente sección) |

Todo lo demás — Balance, Payouts, Refunds, Customers, PaymentIntents, todo Connect —
se queda en **None**.

Y ahora haz el ejercicio que hace que esto merezca la pena. A la una de la mañana te
roban la tablet de la mesa de merchandising. ¿Qué puede hacer el ladrón con la clave
que hay en su llavero? Leer tu historial de propinas y crear más enlaces de propina en
tu cuenta. Ese es todo el radio de la explosión. No puede ver tu saldo, ni lanzar una
transferencia, ni emitir un reembolso a una tarjeta que controle, ni leer una lista de
clientes. Revocas la clave desde el móvil en el taxi de vuelta a casa y el dispositivo
se apaga. Tu dinero no se ha movido.

Esa asimetría —acceso de escritura al bote de propinas, cero acceso al dinero— es la
única razón por la que un diseño sin servidor y con tu propia clave es defendible. Es
también por lo que "Login with Stripe" no es la respuesta aquí: OAuth necesita un
servidor del desarrollador de la app que guarde tu token, y un servidor es exactamente
lo que no estamos construyendo.

(Una rareza con la que te toparás: el permiso *Prices* se llama internamente
`plan_write`, así que el mensaje de error de Stripe nombra un scope que en el dashboard
no aparece con ese nombre. Es Prices.)

## Leer las propinas sin webhook

Aquí es donde la mayoría de los tutoriales se detienen o echan mano de un webhook, y
donde un escenario es de verdad distinto de una aplicación web.

Un webhook es una petición HTTP entrante. Una tablet detrás de un pie de micro no puede
recibirla. Está en el wifi de invitados de la sala, detrás de un NAT, sin dirección
pública, sin certificado TLS — y no tiene por qué tener nada de eso. Si tomas el camino
del webhook, tienes que levantar un servidor que atrape los eventos y un socket que los
empuje al dispositivo: un backend, una carga de operaciones y un sitio donde ahora viven
los nombres de tus fans. Acabas de reconstruir la plataforma que querías evitar.

Así que tira en lugar de que te empujen. El endpoint
[List all events](https://docs.stripe.com/api/events/list) de Stripe es público, está
documentado y devuelve los eventos del más nuevo al más antiguo:

```sh
curl -G https://api.stripe.com/v1/events \
  -u "$RK:" \
  -d "types[]"=checkout.session.completed \
  -d "types[]"=checkout.session.async_payment_succeeded \
  -d ending_before=evt_EL_ULTIMO_QUE_VI \
  -d limit=100
```

`ending_before` es todo el diseño. Guarda el id del evento más reciente que has
procesado; cada sondeo pide todo lo estrictamente más nuevo y tú avanzas el cursor. Sin
marcas de tiempo, sin desfase de reloj, sin deduplicar por importe. En el primer sondeo
de un set, pide `limit=1` sin cursor para anclarte en lo que ya hay, y así no repetir en
la prueba de sonido las propinas de esta mañana.

Después filtra lo que vuelve. Los dos tipos de evento pueden dispararse para un mismo
pago, así que deduplica por el id de la Checkout Session. Comprueba
`payment_status == "paid"`: una sesión completada no es necesariamente una sesión pagada.
Y comprueba que `payment_link` coincide con *tu* enlace, porque `/v1/events` es de toda
la cuenta y te entregará encantado el tráfico de cualquier otra cosa que haga esa cuenta
de Stripe.

Sé claro con las contrapartidas, porque son reales:

- **Stripe recomienda webhooks.** El polling no es el camino bendecido; es un endpoint
  documentado usado a conciencia. Dilo en tu README y sigue adelante.
- **Los eventos llegan hasta 30 días atrás.** [Palabras de Stripe](https://docs.stripe.com/api/events/list):
  *"List events, going back up to 30 days."* Esto es un feed en directo, no tu libro de
  cuentas. Tu libro son las Checkout Sessions, y el de verdad es el dashboard de Stripe.
- **Vigila la cuota de lectura.** Todo el mundo mira el límite por segundo
  ([rate limits](https://docs.stripe.com/rate-limits): 100 req/s en live) y nadie mira el
  otro: Stripe asigna unas **500 peticiones de lectura por transacción** en una ventana
  móvil de 30 días, con un suelo de 10 000 lecturas al mes. Sondea cada 4 segundos y un
  set de tres horas son ~2 700 lecturas. Cuatro bolos largos en un mes y estás en el
  suelo. Las propinas te compran margen según llegan, pero si sondeas cada segundo porque
  te parecía más ágil, encontrarás el techo. Cuatro segundos no es un número perezoso: es
  *el* número.

Esa es la forma honesta del asunto: el polling te cuesta unos miles de GET y te ahorra un
backend entero.

## Las cuentas de las comisiones, bien hechas

Una plataforma que anuncia 0 % no es gratis, y esto tampoco. La comisión de procesamiento
de Stripe se aplica a cada propina, y Stripe te la cobra directamente. Hoy, según los
[precios en euros de Stripe](https://stripe.com/ie/pricing), una tarjeta estándar del EEE
cuesta **1,5 % + 0,25 €**. Las tarjetas premium del EEE, 1,9 % + 0,25 €; las británicas,
2,5 % + 0,25 €; y el resto, 3,25 % + 0,25 €, más un 2 % si hay que convertir divisa. (En
EE. UU. es 2,9 % + 0,30 $, que es peor exactamente por lo que viene ahora.)

El problema no es el porcentaje. Son los veinticinco céntimos.

| Propina | Stripe se lleva | El artista se queda | Recorte efectivo |
| --- | --- | --- | --- |
| 2 € | 0,28 € | 1,72 € | **14,0 %** |
| 5 € | 0,33 € | 4,67 € | 6,5 % |
| 10 € | 0,40 € | 9,60 € | 4,0 % |
| 20 € | 0,55 € | 19,45 € | 2,8 % |
| 50 € | 1,00 € | 49,00 € | 2,0 % |

Una tarifa plana es un porcentaje disfrazado, y con dinero pequeño se le cae el disfraz.
Los mismos 0,25 € que son invisibles en una propina de 50 € se comen un octavo de una de
2 €. Las propinas son pequeñas por naturaleza —eso es lo que las hace propinas—, así que
esto no es un caso extremo: es el caso mediano.

Por eso pones `custom_unit_amount[minimum]`. Alrededor de los 2 € la transacción deja de
merecer la pena; una propina con tarjeta de 0,50 € llegaría como 0,24 € y le costaría a
Stripe más moverla de lo que vale. Elige tu suelo a conciencia, en vez de descubrirlo en
tu primera transferencia.

Y fíjate en lo que esto le hace a la comparación con la que empezaste. Una plataforma que
cobra 0 % por encima de Stripe te cobra 0 % por encima de **esto**. Su 0 % es real, y es
un 0 % de lo que el procesador ha dejado. El raíl de tarjeta de nadie es gratis: la
afirmación honesta es "ningún recorte más allá del del procesador", y quien afirme más
está mintiendo o no está usando tarjetas.

## Lo que tienes ahora, y lo que no

Tres llamadas a la API y un código QR, y un bote de propinas de verdad: alojado, con
cumplimiento PCI, Apple Pay, Google Pay, propinas que aterrizan en tu propio saldo de
Stripe según tu propio calendario de transferencias, y ningún servidor por el camino. Para
mucha gente ese es literalmente el final del proyecto, y puedes parar aquí y publicarlo.

Lo que no tienes es un escenario. Tienes una página de pago. Entre una cosa y otra están
las aburridas: el bucle de sondeo con su cursor y su backoff; una pantalla que el público
pueda ver, con el objetivo y el último mensaje; un sitio para la clave que no sea
`localStorage`; un bloqueo para que un desconocido no toquetee la tablet entre sets; y la
capa de mil pequeñas decisiones sobre qué pasa cuando el wifi de la sala se cae a mitad
del set.

Eso es [live.tips](https://github.com/mekedron/live.tips): exactamente esta arquitectura,
terminada, con licencia MIT. La clave restringida con esos cinco permisos, el bucle de
cursor sobre `/v1/events`, la creación de Product/Price/Payment Link — todo corriendo en
el dispositivo del artista contra su propia cuenta. No hay ningún servidor de live.tips en
la ruta de Stripe ni ningún saldo de live.tips en ninguna parte, algo que escribimos aparte
en [cómo live.tips maneja el dinero](https://live.tips/es/blog/como-live-tips-gestiona-dinero/).

Lee el código, llévate las piezas que quieras, o simplemente úsalo. La idea de este artículo
es que la arquitectura no es un secreto ni es difícil: **Stripe alojará tu bote de propinas
gratis, y una clave restringida más un bucle de sondeo es todo lo que se interpone entre un
artista y su propio dinero.** Preferimos que lo sepas a que te registres en nada.
