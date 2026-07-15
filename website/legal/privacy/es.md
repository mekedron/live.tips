---
title: Política de privacidad
description: live.tips no tiene cookies, ni analíticas, ni rastreo, y funciona sin ninguna cuenta. Si eliges iniciar sesión, aquí tienes exactamente qué se guarda, dónde, quién lo guarda y durante cuánto tiempo.
updated: 2026-07-15
updated_label: Última actualización 15 de julio de 2026
---

live.tips es un bote de propinas de código abierto para artistas. Lo gestiona **Nikita
Rabykin**, un desarrollador individual, no una empresa. Si algo de lo que sigue te importa,
escribe a **[contact@live.tips](mailto:contact@live.tips)** — esa dirección llega a una
persona.

Esta política es honesta en las partes aburridas. Preferimos decir «guardamos tu nombre
mientras mantengas la banda» antes que afirmar que no guardamos nada y estar equivocados.

## La versión corta

- **La cuenta es opcional.** La app funciona sin ninguna cuenta, y eso sigue siendo lo
  predeterminado. Si quieres tus bandas y tu historial en un segundo dispositivo, puedes
  iniciar sesión — y entonces parte de ello se guarda en un servidor, y más de lo que antes
  se guardaba. Qué es qué, se explica más abajo.
- **Sin cookies.** Ni una, en ninguna parte.
- **Sin analíticas, sin rastreo, sin anuncios, sin scripts de terceros** en este sitio web.
- **Nunca tocamos tu dinero.** Las propinas van directamente del fan a la cuenta propia del
  artista en Stripe, Revolut, MobilePay o Monzo. Nunca hay ningún saldo de live.tips.
- **Sin cuenta, la app solo habla con Stripe** — con ningún servidor de live.tips. Si inicias
  sesión, eso cambia: tu clave de Stripe se traslada a nuestro servidor y Stripe nos informa
  de tus propinas, para que podamos ponerlas en tus otros dispositivos. Ese es el precio
  honesto de iniciar sesión, y se explica por completo más abajo.
- **Las notificaciones push son nuevas, opcionales y solo para cuentas con sesión iniciada.**
  No se envía nada a un dispositivo que nunca las activó, y a un dispositivo sin cuenta nunca
  se le envía ninguna.
- Los servidores que ejecutamos están en Firebase, de Google. Existen si un artista activa
  Revolut, MobilePay o Monzo — o si inicia sesión.

## Este sitio web

El sitio es estático y está alojado en **GitHub Pages**. Como proveedor de alojamiento, GitHub
recibe la dirección IP y el user-agent del navegador de todo el que carga una página — esto es
registro ordinario de servidor web, ocurre antes de que se ejecute nada de nuestro código y no
podemos desactivarlo. GitHub lo trata bajo su propia
[declaración de privacidad](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement).
Nosotros no leemos esos registros y GitHub no nos los muestra.

Más allá de eso, las páginas que estás leyendo **no cargan nada de nadie más**: las fuentes,
los iconos y las imágenes se sirven desde el propio live.tips. No hay Google Analytics, ni
gestor de etiquetas, ni píxel, ni widget incrustado.

El sitio guarda **dos valores en el `localStorage` de tu navegador**, ambos establecidos por
ti, ambos legibles solo por este sitio, y ninguno se envía nunca a ninguna parte:

| Clave | Qué recuerda |
| --- | --- |
| `lt-landing-theme` | si elegiste colores claros, oscuros o automáticos |
| `lt-langbar-dismissed` | que cerraste el aviso de «también disponible en tu idioma» |

Borrar el almacenamiento de tu navegador los elimina. No son cookies, no se comparten
y no identifican a nadie.

## La app tiene dos modos, y la diferencia entre ambos lo es todo

Todo lo que sigue depende de una pregunta: **¿has iniciado sesión?**

### Modo uno — sin cuenta. Sigue siendo lo predeterminado, sigue sin cambiar.

La app se ejecuta **en el propio dispositivo del artista**, y todo lo que sabe vive ahí:

- La **clave restringida de Stripe** se guarda en el llavero del dispositivo (Keychain de
  iOS/macOS, Keystore de Android) y solo se envía a `api.stripe.com`.
- El **historial de propinas, el historial de sesiones, la meta, la lista de peticiones de
  canciones y los ajustes de la app** se guardan en el almacenamiento local del dispositivo.
  Esto incluye los nombres y mensajes que los fans adjuntan a sus propinas.
- Desinstalar la app lo borra todo. No hay copia de seguridad en la nube por nuestra parte,
  porque en este modo, por nuestra parte, no hay nube.

**Nosotros nunca recibimos nada de esto.** La app se distribuye sin SDK de analíticas, sin
informador de fallos y sin código publicitario — ninguno, ni siquiera desactivados. (Las
notificaciones push existen, pero son una función para cuentas con sesión iniciada y están
apagadas hasta que las activas — véase *Modo dos*. A un dispositivo sin cuenta nunca se le
envía ninguna.)

Dos aclaraciones, para que la afirmación de «no habla con nadie» siga siendo exactamente cierta:

- La app descarga los **tipos de cambio de divisas** una vez al día desde APIs públicas de
  tipos (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). Son simples
  peticiones de una lista pública de tipos. No llevan información sobre ti, sobre el artista
  ni sobre ninguna propina — pero, como cualquier petición web, sí revelan tu dirección IP a
  esos servicios.
- Si usas la **versión de navegador** de la app, tu navegador la descarga desde nuestro
  alojamiento estático (véase *Este sitio web*, más arriba).

### Modo dos — has iniciado sesión. Entonces algunos datos salen del dispositivo, a propósito.

Iniciar sesión es un acto deliberado. Nada te inicia sesión por ti, y nada de la app deja de
funcionar si no lo haces nunca. Inicias sesión porque quieres un segundo dispositivo: el móvil
en tu bolsillo y la tablet en el escenario mostrando la misma noche, las mismas bandas, el
mismo historial.

Eso solo funciona si un servidor los guarda. **Así que los guarda, y ese es el precio honesto
del segundo dispositivo.**

El servidor es **Firebase**, que es Google. Hay tres maneras de tener una cuenta:

- **Iniciar sesión con Apple** o **iniciar sesión con Google** — Firebase Auth recibe lo que
  el proveedor entregue: un identificador de usuario (uid) y, normalmente, una dirección de
  correo y un nombre. (Con Apple puedes ocultar tu correo; entonces Apple nos da una dirección
  de reenvío en su lugar, y solo entrega tu nombre la primerísima vez que inicias sesión.)
- **Una cuenta de invitado** — una cuenta anónima sin correo y sin nombre. Sincroniza y se
  puede revocar, pero no hay nada con lo que recuperarla si pierdes el dispositivo. Es un uid
  y nada más. Una cuenta de invitado no puede usar la custodia de la clave de Stripe en el
  servidor ni las notificaciones push que se describen más abajo, porque ambas necesitan una
  cuenta que podamos devolverte.

Una vez has iniciado sesión, la cuenta recibe su propio rincón privado en la base de datos
**Cloud Firestore** de Google, en `users/<your uid>/`. Las reglas de seguridad conceden ese
rincón a ese uid **y a nadie más** — ninguna otra cuenta puede leerlo, ni adivinando URLs.
Dentro de él:

| Qué | Por qué está ahí |
| --- | --- |
| Tus **bandas** — nombres, ajustes del bote de propinas y de los métodos de pago, texto del cartel, metas y tu **lista de peticiones de canciones** | para que una banda exista en todos los dispositivos en los que inicies sesión |
| Los **ajustes de la app**, incluidas tus preferencias de notificación | para que un dispositivo que añadas ya esté configurado |
| **Registros de sesiones e historial de propinas** — incluidos **los nombres y los mensajes que los fans adjuntan a sus propinas**, y cualquier **canción que un fan haya pedido** | porque ese historial es exactamente lo que pediste ver en el otro dispositivo |
| La **sesión en directo** que se está ejecutando ahora mismo | para que una segunda pantalla pueda unirse al concierto de esta noche |
| Tus **dispositivos** — el nombre que cada uno se da a sí mismo («iPhone de Nikita»), su plataforma y su modelo, su idioma de interfaz, cuándo se vio por primera y última vez y (si activaste las notificaciones) un **token push** | para que Ajustes → Seguridad pueda listarlos, para que una notificación llegue al dispositivo correcto en el idioma correcto, y para que puedas revocar uno |
| Un pequeño **documento de perfil** — el nombre de cuenta que elegiste y qué proveedor usaste | para que el selector de cuentas pueda etiquetarla |
| Un **buzón de avisos** — una lista limitada de propinas y peticiones de canciones recientes que llegaron mientras no había ninguna sesión en marcha | para que puedas ponerte al día de lo que te perdiste |

Y ahora lo importante, sin rodeos: **sin cuenta, el nombre y el mensaje de un fan nunca salen
del dispositivo del artista. Con cuenta, se guardan en los servidores de Google bajo el uid del
artista, como parte del historial sincronizado de ese mismo artista**, y — como explican las
dos secciones siguientes — **ahora es nuestro servidor el que los escribe ahí.** Ninguna otra
cuenta puede leerlos, nosotros no los miramos y de ellos no se deriva nada — pero ahí están, y
ahí permanecen mientras la banda exista, y conviene que lo sepas antes de iniciar sesión.

Cerrar sesión devuelve el dispositivo al modo local. No borra los datos de la cuenta — véase
*Cómo se borra cada cosa*, más abajo.

#### Tu clave de Stripe, al iniciar sesión, se traslada a nuestro servidor

Este es el cambio más grande, y el que más vale la pena leer.

**Sin cuenta, tu clave restringida de Stripe nunca sale de tu dispositivo.** Ese es el Modo
uno, y no ha cambiado.

**Al iniciar sesión, sí sale — hacia nosotros.** La clave se cifra (una clave AES-256 por
secreto, envuelta a su vez por Google Cloud KMS) y se guarda en el servidor en un lugar que
**nadie puede volver a leer — ni otra cuenta, ni siquiera tú.** Solo se descifra dentro de
nuestras Cloud Functions, se usa para hablar con Stripe en tu nombre, y no se vuelve a entregar
nunca a un dispositivo.

Como la clave vive ahora con nosotros, **Stripe informa de tus propinas directamente a nuestro
servidor**: registramos un webhook en tu propia cuenta de Stripe, y Stripe avisa a ese webhook
cada vez que se paga una propina. Nuestra función escribe la propina en el historial de tu
cuenta (véase más abajo). Tu app ya no consulta a Stripe periódicamente para una cuenta con
sesión iniciada; llega a Stripe solo a través de una lista estrecha y fija de operaciones en
nuestro servidor (crear tu enlace de propina, generar un enlace de petición de canción y volver
a leer tus propias propinas para conciliarlas).

Así que, dicho sin eufemismos: **para una cuenta con sesión iniciada ahora hay un servidor de
live.tips en el camino entre Stripe y tu historial.** Seguimos sin tocar nunca el dinero — una
propina con tarjeta se crea contra tu cuenta de Stripe, se asienta en tu saldo de Stripe y se
abona según tu calendario de Stripe, exactamente como antes. Lo que cambió es el camino de los
*datos*, no el del *dinero*. Si nunca inicias sesión, nada de esto se aplica y la app sigue
hablando directamente con `api.stripe.com` y con nadie más.

#### Añadir un dispositivo con un código QR

Para añadir un dispositivo muestras un código QR desde un dispositivo en el que ya has iniciado
sesión. El código es aleatorio, **de un solo uso, y caduca a los dos minutos**, y el nuevo
dispositivo no recibe nada hasta que tocas *confirmar* en el antiguo. Mientras ese apretón de
manos está abierto, conservamos el código, el nombre que el nuevo dispositivo se dio a sí mismo
y su plataforma — y el registro se borra cuando caduca. Un código QR fotografiado no sirve de
nada sin tu toque de confirmación.

## Peticiones de canciones

Una banda puede activar las **peticiones de canciones**: los fans eligen entonces una canción
de la lista del artista y, opcionalmente, pagan para subirla en la cola. Una petición no es más
que una propina que además lleva **qué canción** se pidió — así que el mismo nombre y mensaje
que un fan puede adjuntar a una propina se aplican también aquí, y se guarda y se conserva
exactamente igual que cualquier otra propina (más abajo). La cola pública que ve un fan muestra
solo **los totales por canción** — cuánto ha recaudado una canción y en qué puesto está — y no
lleva **ningún nombre de fan**. Sin cuenta, toda la lista de peticiones de canciones y su
historial viven solo en el dispositivo.

## Notificaciones push

Cuando has iniciado sesión, la app puede enviarte una **notificación push** — pero solo si la
activas, por dispositivo, y solo después de que el sistema operativo de tu dispositivo conceda
permiso. Existe para una sola cosa: una propina o una petición de canción que llega **mientras
no tienes una sesión en marcha**, para que te enteres de la propina que de otro modo te habrías
perdido. Una propina que llega mientras tu escenario está en directo no envía nada — ya la
estás viendo.

- Para entregar una push, **Firebase Cloud Messaging (FCM)** de Google necesita un **token
  push** del dispositivo. Guardamos ese token, y el idioma de interfaz del dispositivo, en el
  propio registro del dispositivo bajo tu cuenta, y se borra en el momento en que apagas las
  notificaciones, revocas el dispositivo o cierras sesión. Los tokens muertos se depuran
  automáticamente.
- La notificación en sí dice qué llegó — un importe, y el nombre de un fan o el título de una
  canción si lo dejaron. La misma lista breve se conserva en el **buzón de avisos** de tu
  cuenta, limitado a las cien entradas más recientes, para que puedas desplazarte hacia atrás
  por lo que llegó mientras estabas ausente.
- En la web, entregar una push requiere un pequeño **service worker** en la raíz del sitio y el
  SDK de mensajería de Firebase, que tu navegador descarga de Google (`gstatic.com`) la primera
  vez. La push web la transporta luego el propio servicio de push de tu navegador (en el caso
  de Chrome, el de Google). Nada de esto se carga a menos que hayas activado las notificaciones.
- **Una cuenta de invitado y un dispositivo sin cuenta no reciben ninguna push**, porque una
  push necesita una cuenta a la que podamos entregarla y un token que elegiste dar.

## Dónde vive todo esto, físicamente

Firebase Auth, Cloud Firestore, nuestras Cloud Functions y la clave de Cloud KMS que envuelve
tu secreto de Stripe se ejecutan todas en la **Unión Europea** — la base de datos en la
multirregión `eur3` de Google, las funciones y el anillo de claves en `europe-west1`. Google
actúa como nuestro encargado del tratamiento bajo los
[términos de privacidad y seguridad de Firebase](https://firebase.google.com/support/privacy) y
su propia [política de privacidad](https://policies.google.com/privacy). Como cualquier gran
proveedor, Google puede implicar infraestructura fuera de la UE para soporte y seguridad; eso
se rige por esos términos, no por nosotros. Las notificaciones push, una vez entregadas a
Firebase Cloud Messaging y al servicio de push de tu navegador o teléfono, viajan por la
infraestructura de esas empresas para llegar a tu dispositivo.

## Stripe

Cuando un fan paga con tarjeta, está en la página de pago de **Stripe**, no en la nuestra.
Stripe recoge y trata sus datos de pago como responsable independiente, bajo la
[Política de privacidad de Stripe](https://stripe.com/privacy). Nosotros nunca vemos números de
tarjeta.

Cómo te llegan tus propinas depende del modo:

- **Sin cuenta**, la app del artista lee sus propias propinas de Stripe usando la clave
  restringida del propio artista — directamente del dispositivo a `api.stripe.com`. **No hay
  ningún servidor de live.tips en ese camino.**
- **Con sesión iniciada**, la clave vive en nuestro servidor (cifrada, como se ha explicado), y
  Stripe informa de cada propina a nuestro webhook, que la escribe en el propio historial de
  Firestore de ese artista. **En este modo sí hay un servidor de live.tips en el camino** —
  para los datos de la propina, nunca para el dinero. El nombre y el mensaje de un fan, si dejó
  alguno, viajan con la propina hasta el propio historial de ese artista y ahí se detienen.

## El relé — solo si Revolut, MobilePay o Monzo están activados

Las configuraciones que solo usan Stripe nunca lo tocan.

Revolut, MobilePay y Monzo no ofrecen ninguna forma de que una app confirme que un pago ha
ocurrido, así que esas propinas se encaminan a través de un pequeño relé de código abierto que
ejecutamos en **Firebase** — Cloud Functions y Firestore en `europe-west1`, con la página de
propinas del fan servida desde **`tip.live.tips/t/<id>`**. Nunca toca dinero. Esto es todo lo
que gestiona.

### Qué guarda el artista

Crear una página de propinas guarda el **nombre público del artista, su mensaje público, su
moneda y los identificadores de pago que eligió publicar** (su enlace de pago de Stripe, su
usuario de Revolut, su Box ID de MobilePay, su usuario de Monzo) y, si las peticiones de
canciones están activadas, **su lista pública de canciones y sus precios por canción**. Todo
ello es información que el artista está publicando deliberadamente para los fans de todos modos.

- **Conservación: una página de propinas sin ninguna cuenta detrás se borra automáticamente
  tras 90 días de inactividad.** Una página de propinas que pertenece a una cuenta con sesión
  iniciada vive tanto como la banda a la que pertenece.
- El artista puede borrarla **de inmediato** desde la app, en cualquier momento.
- Aquí no se recoge dirección de correo electrónico, ni contraseña, ni nombre legal, ni datos
  bancarios.
- El secreto de la página se guarda **solo como hash**. No podríamos decirte el secreto ni
  aunque nos lo pidieras; solo podemos comprobar uno.

### Qué envía un fan

El formulario de propina pide un **importe** y, opcionalmente, un **nombre** y un **mensaje** —
y, en el caso de una petición de canción, qué canción. Ese es todo el formulario. Sin correo,
sin teléfono, sin cuenta.

Adónde va ese texto escrito por el fan, y durante cuánto tiempo, depende de si el artista ha
iniciado sesión:

- **Si la página de propinas no tiene ninguna cuenta detrás**, la propina se escribe en una
  **cola de entrega** — un único documento que existe para ser entregado a la pantalla del
  artista. Cuando la pantalla muestra la propina, **el dispositivo del artista borra ese
  documento.** El borrado *es* el acuse de recibo. Si la pantalla del artista está desconectada
  — móvil bloqueado, sin cobertura — la propina **espera en esa cola hasta una hora**, para que
  no se pierda sin más, y se entrega en cuanto la pantalla se reconecta. Si nadie se reconecta,
  se **borra sin haber sido vista**, barrida por una tarea programada. Para un artista sin
  cuenta, **esa cola es el único lugar donde se llega a guardar texto escrito por un fan en
  nuestro servidor, y una hora es su límite absoluto.**
- **Si la página de propinas pertenece a una cuenta con sesión iniciada**, no hay cola. Nuestro
  servidor escribe la propina **directamente en el propio historial de ese artista** bajo su
  uid — en la sesión de esta noche si hay una en marcha, o en el archivo de la propia banda si
  no. Ahí permanece **mientras la banda exista**; es el propio historial del artista, y es
  justo para lo que inició sesión. Es el mismo historial en el que escribe el webhook de
  Stripe, más arriba.
- Tu nombre y tu mensaje también se colocan en la **nota de pago** que se abre en Revolut,
  MobilePay o Monzo — así es como el artista sabe quién dejó la propina. Esas empresas lo tratan
  después bajo sus propias políticas de privacidad.
- El relé no guarda **ningún libro de propinas entre artistas**. No puede mostrarte a ti, ni a
  nosotros, ni a nadie una lista de quién dio propina a quién entre distintos artistas.

### Direcciones IP y antiabuso

Un formulario abierto al que cualquiera puede enviar datos necesita algo de protección frente a
bots, así que:

- Tu dirección IP se envía a **Cloudflare Turnstile** — una comprobación antibot que se ejecuta
  en la página de propinas — para verificar que no eres un bot. Turnstile es un producto de
  Cloudflare y se usa en lugar de un CAPTCHA que te perfile. Turnstile y nuestro DNS son lo
  único que Cloudflare sigue haciendo por nosotros; el relé en sí ahora se ejecuta en Firebase.
  Véase la [Política de privacidad de Cloudflare](https://www.cloudflare.com/privacypolicy/).
- Tu IP se usa también para **limitar la frecuencia** de las peticiones — enviar una propina,
  crear una página de propinas, canjear un código para añadir un dispositivo. Lo que guardamos
  para eso es un **hash criptográfico de la IP con sal**, nunca la IP en sí, durante unas **dos
  horas**, y luego se borra. La sal es un secreto del servidor: sin ella, el código se niega a
  guardar absolutamente nada, en lugar de conservar un hash que pudiera revertirse.
- Los **registros operativos de Google** anotan los detalles técnicos de las peticiones al relé
  — URL, tiempos, estado — durante unos pocos días. Nuestro código no registra deliberadamente
  ningún nombre, ningún mensaje, ningún secreto y ninguna cabecera. Google actúa como nuestro
  encargado del tratamiento.

### Contadores

El relé cuenta **cuántas propinas** ha retransmitido una página de propinas dada, para que
podamos detectar abusos y saber si esto se usa siquiera. Es un número. No contiene ningún dato
de fans.

## Quién trata qué

| Quién | Qué recibe | Por qué |
| --- | --- | --- |
| **Google (Firebase)** | Las cuentas, los datos sincronizados de un artista con sesión iniciada, la clave de Stripe cifrada, el relé, los tokens push y su entrega, los registros del servidor | La cuenta opcional, el relé opcional y las notificaciones push |
| **Google Cloud KMS** | La clave que envuelve el secreto de Stripe de un artista con sesión iniciada (nunca el secreto en claro) | Mantener ilegible en reposo la clave de Stripe guardada |
| **Stripe** | Los datos de pago del fan, como responsable independiente; y, para un artista con sesión iniciada, los eventos de propina enviados a nuestro webhook | Las propinas con tarjeta |
| **Cloudflare** | La IP del fan, para la comprobación de Turnstile en la página de propinas. Y nuestro DNS. | Mantener a los bots fuera del formulario de propinas |
| **GitHub** | La IP y el user-agent de quien cargue este sitio web | Alojar el sitio web |
| **El servicio de push de tu navegador / teléfono** (p. ej., el de Google para Chrome) | Un token push y el contenido de la notificación, si activaste las notificaciones | Entregar las notificaciones push |
| **Revolut / MobilePay / Monzo** | Lo que el fan haga en su propia app, incluida la nota de pago | Esos métodos de pago |

No vendemos nada a nadie, y no hay nadie más en esa lista.

## Base jurídica, por si la necesitas (RGPD)

- Gestionar una cuenta que has pedido, sincronizar tus propios datos en tus propios
  dispositivos, custodiar tu clave de Stripe para que tus propinas lleguen a tu historial,
  ejecutar el relé para un artista que lo activó, entregar la propina de un fan a la pantalla a
  la que iba dirigida y enviar una push que activaste: **ejecución de un servicio que has
  solicitado**.
- Limitación de frecuencia, Turnstile, cuotas por IP con hash y revocación de dispositivos:
  **interés legítimo** en evitar que un servicio libre y gratuito sea destruido por bots y
  fraude, y en mantener seguras las cuentas de los artistas.
- Registros del servidor: **interés legítimo** en operar y proteger el servicio.

## Cómo se borra cada cosa

Esto importa más que cualquier promesa que pudiéramos hacer al respecto, así que aquí está
exactamente lo que existe hoy — incluido lo que no existe.

- **Sin cuenta**: desinstala la app. Eso es todo, se acabó.
- **Una banda**: eliminar una banda en la app borra los datos de esa banda en la nube — sus
  ajustes, sus claves, sus sesiones, su historial de propinas — junto con la copia del
  dispositivo.
- **Una página de propinas**: bórrala o regenérala en la app y queda eliminada del relé al
  instante, incluidas las propinas pendientes.
- **Las notificaciones push**: apágalas en un dispositivo y su token push se borra. El buzón de
  avisos se vacía junto con la banda o la cuenta.
- **Un dispositivo**: Ajustes → Seguridad lista tus dispositivos. Puedes revocar uno, o cerrar
  sesión en todos los demás — lo que termina la sesión de todos los demás dispositivos de
  inmediato, no a la larga.
- **Tu cuenta entera, con un solo toque: la app todavía no tiene ese botón.** Preferimos
  admitirlo antes que fingir lo contrario. Hasta que exista, escribe a
  **[contact@live.tips](mailto:contact@live.tips)** y borraremos la cuenta y todo lo que
  contiene, a mano. Mientras tanto, ya puedes borrar todas las bandas, lo que elimina todo lo
  sustancial — incluida la clave de Stripe guardada — y deja atrás una cuenta vacía.

## Tus derechos

Puedes pedirnos una copia de cualquier dato que tengamos sobre ti, o que lo corrijamos o lo
borremos, y puedes reclamar ante tu autoridad nacional de protección de datos. Escribe a
**[contact@live.tips](mailto:contact@live.tips)**.

En la práctica, casi todo está ya en tus manos: un artista puede borrar una página de propinas
o una banda desde la app al instante, las propinas de los fans no entregadas en una página sin
cuenta se evaporan en una hora y, si nunca inicias sesión, nada de ello estuvo jamás en otro
sitio que tu propio dispositivo.

## Menores

live.tips no está dirigido a menores y no tratamos sus datos a sabiendas.

## Cambios

Actualizaremos esta página cuando cambie el software. Como todo el proyecto es de código
abierto, **todas las versiones anteriores de esta política están en el historial público de
git** — puedes ver exactamente qué cambió y cuándo.

## Idioma

Esta política se publica en todos los idiomas que admite el sitio, por comodidad. Si una
traducción y la versión en inglés no coinciden, **la versión en inglés es la que cuenta**.
</content>
</invoke>
