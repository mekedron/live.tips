---
title: Política de privacidad
description: live.tips no tiene cuentas, ni cookies, ni analíticas, ni rastreo. Aquí tienes la lista breve de lo que sí se trata, quién lo trata y durante cuánto tiempo.
updated: 2026-07-13
updated_label: Última actualización 13 de julio de 2026
---

live.tips es un bote de propinas de código abierto para artistas. Lo gestiona **Nikita Rabykin**, un
desarrollador individual, no una empresa. Si algo de lo que sigue te importa, escribe a
**[contact@live.tips](mailto:contact@live.tips)** — esa dirección llega a una persona.

Esta política es honesta en las partes aburridas. Preferimos decir «guardamos tu nombre
hasta una hora» antes que afirmar que no guardamos nada y estar equivocados.

## La versión corta

- **Sin cuentas.** No hay nada en lo que registrarse.
- **Sin cookies.** Ni una, en ninguna parte.
- **Sin analíticas, sin rastreo, sin anuncios, sin scripts de terceros** en este sitio web.
- **Nunca tocamos tu dinero.** Las propinas van directamente del fan a la cuenta propia del
  artista en Stripe, Revolut, MobilePay o Monzo. Nosotros no estamos en ese camino.
- **En la configuración por defecto, la app solo habla con Stripe** — con ningún servidor de live.tips.
- El único servidor que ejecutamos es un pequeño relé, y solo existe si un artista
  activa Revolut, MobilePay o Monzo.

## Este sitio web

El sitio es estático y está alojado en **GitHub Pages**. Como proveedor de alojamiento, GitHub recibe la dirección IP
y el user-agent del navegador de todo el que carga una página — esto es registro ordinario de servidor
web, ocurre antes de que se ejecute nada de nuestro código y no podemos desactivarlo.
GitHub lo trata bajo su propia
[declaración de privacidad](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement).
Nosotros no leemos esos registros y GitHub no nos los muestra.

Más allá de eso, las páginas que estás leyendo **no cargan nada de nadie más**: las fuentes, los iconos
y las imágenes se sirven desde el propio live.tips. No hay Google Analytics, ni gestor de
etiquetas, ni píxel, ni widget incrustado.

El sitio guarda **dos valores en el `localStorage` de tu navegador**, ambos establecidos por ti, ambos
legibles solo por este sitio, y ninguno se envía nunca a ninguna parte:

| Clave | Qué recuerda |
| --- | --- |
| `lt-landing-theme` | si elegiste colores claros, oscuros o automáticos |
| `lt-langbar-dismissed` | que cerraste el aviso de «también disponible en tu idioma» |

Borrar el almacenamiento de tu navegador los elimina. No son cookies, no se comparten
y no identifican a nadie.

## La app

La app de live.tips se ejecuta **en el propio dispositivo del artista**. Todo lo que sabe vive ahí:

- La **clave restringida de Stripe** se guarda en el llavero del dispositivo (Keychain de iOS/macOS,
  Keystore de Android) y solo se envía a `api.stripe.com`.
- El **historial de propinas, el historial de sesiones, la meta y los ajustes de la app** se guardan en el
  almacenamiento local del dispositivo. Esto incluye los nombres y mensajes que los fans adjuntan a sus propinas.
- Desinstalar la app lo borra todo. No hay copia de seguridad en la nube por nuestra parte, porque
  por nuestra parte no hay nube.

**Nosotros nunca recibimos nada de esto.** La app se distribuye sin SDK de analíticas, sin informador
de fallos, sin notificaciones push y sin código publicitario — ninguno, ni siquiera desactivados.

Dos aclaraciones, para que la afirmación de «no habla con nadie» siga siendo exactamente cierta:

- La app descarga los **tipos de cambio de divisas** una vez al día desde APIs públicas de tipos
  (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). Son simples
  peticiones de una lista pública de tipos. No llevan información sobre ti, sobre el artista
  ni sobre ninguna propina — pero, como cualquier petición web, sí revelan tu dirección IP a esos
  servicios.
- Si usas la **versión de navegador** de la app, tu navegador la descarga desde nuestro
  alojamiento estático (véase *Este sitio web*, más arriba).

## Stripe

Cuando un fan paga con tarjeta, está en la página de pago de **Stripe**, no en la nuestra. Stripe
recoge y trata sus datos de pago como responsable independiente, bajo la
[Política de privacidad de Stripe](https://stripe.com/privacy). Nosotros nunca vemos números de tarjeta, y no
tenemos acceso a la cuenta de Stripe del artista.

La app del artista lee sus propias propinas de Stripe usando la clave restringida del propio artista.
El nombre y el mensaje de un fan, si dejó alguno, viajan de Stripe al dispositivo del artista
y ahí se detienen.

## El relé — solo si Revolut, MobilePay o Monzo están activados

Las configuraciones que solo usan Stripe nunca lo tocan, y pueden dejar de leer aquí.

Revolut, MobilePay y Monzo no ofrecen ninguna forma de que una app confirme que un pago ha ocurrido,
así que esas propinas se encaminan a través de un pequeño relé de código abierto que ejecutamos en **Cloudflare** en
`api.live.tips`. Nunca toca dinero. Esto es todo lo que gestiona.

### Qué guarda el artista

Crear una página de propinas guarda el **nombre público del artista, su mensaje público, su
moneda y los identificadores de pago que eligió publicar** (su enlace de pago de Stripe, su
usuario de Revolut, su Box ID de MobilePay, su usuario de Monzo). Todo ello es información que el artista
está publicando deliberadamente para los fans de todos modos.

- **Conservación: se borra automáticamente tras 90 días de inactividad.**
- El artista puede borrarla **de inmediato** desde la app, en cualquier momento.
- Nunca se recoge dirección de correo electrónico, ni contraseña, ni nombre legal, ni datos bancarios.

### Qué envía un fan

El formulario de propina pide un **importe** y, opcionalmente, un **nombre** y un **mensaje**. Ese es
todo el formulario. Sin correo, sin teléfono, sin cuenta.

- Si la pantalla del artista está **en línea**, la propina se le pasa directamente y
  **nunca se escribe en disco**.
- Si la pantalla del artista está **desconectada** — móvil bloqueado, sin cobertura — la propina se **retiene en
  almacenamiento hasta una hora** para que no se pierda sin más, y se entrega en cuanto la
  pantalla se reconecta. Si nadie se reconecta, se **borra sin haber sido vista**. Este es el único
  texto escrito por un fan que el relé llega a guardar, y una hora es su límite absoluto.
- Tu nombre y tu mensaje también se colocan en la **nota de pago** que se abre en Revolut,
  MobilePay o Monzo — así es como el artista sabe quién dejó la propina. Esas empresas lo tratan
  después bajo sus propias políticas de privacidad.
- El relé no guarda **ningún historial de propinas**. No puede mostrarte a ti, ni a nosotros, ni a nadie una lista de
  quién dio propina a quién.

### Direcciones IP y antiabuso

Un formulario abierto al que cualquiera puede enviar datos necesita algo de protección frente a bots, así que:

- Tu dirección IP se usa para **limitar la frecuencia** de las peticiones, y se envía a **Cloudflare
  Turnstile** (una comprobación antibot que se ejecuta en la página de propinas) para verificar que no eres un bot.
  Turnstile es un producto de Cloudflare y se usa en lugar de un CAPTCHA que te perfile.
- Para impedir que alguien cree miles de páginas de propinas, se conserva un **hash criptográfico de la IP** de
  quien crea una durante unas **dos horas**, y luego se descarta.
- Los **registros operativos de Cloudflare** anotan los detalles técnicos de las peticiones al relé
  — URL, tiempos, estado — durante unos pocos días. No contienen nombres ni mensajes de fans.
  Cloudflare actúa como nuestro encargado del tratamiento; véase la
  [Política de privacidad de Cloudflare](https://www.cloudflare.com/privacypolicy/).

### Contadores

El relé cuenta **cuántas propinas** ha retransmitido una página de propinas dada, para que podamos detectar abusos y
saber si esto se usa siquiera. Es un número. No contiene ningún dato de fans.

## Base jurídica, por si la necesitas (RGPD)

- Ejecutar el relé para un artista que lo activó, y entregar la propina de un fan a la
  pantalla a la que iba dirigida: **ejecución de un servicio que has solicitado**.
- Limitación de frecuencia, Turnstile y cuotas por IP con hash: **interés legítimo** en evitar que un
  servicio libre y gratuito sea destruido por bots y fraude.
- Registros del servidor: **interés legítimo** en operar y proteger el servicio.

## Tus derechos

Puedes pedirnos una copia de cualquier dato que tengamos sobre ti, o que lo corrijamos o lo borremos, y
puedes reclamar ante tu autoridad nacional de protección de datos. Escribe a
**[contact@live.tips](mailto:contact@live.tips)**.

En la práctica, casi todo está ya en tus manos: los artistas pueden borrar su página de propinas desde
la app al instante, las propinas de los fans se evaporan en una hora y todo lo demás vive en tu
propio dispositivo.

## Menores

live.tips no está dirigido a menores y no tratamos sus datos a sabiendas.

## Cambios

Actualizaremos esta página cuando cambie el software. Como todo el proyecto es de código
abierto, **todas las versiones anteriores de esta política están en el historial público de git** — puedes
ver exactamente qué cambió y cuándo.

## Idioma

Esta política se publica en todos los idiomas que admite el sitio, por comodidad. Si una
traducción y la versión en inglés no coinciden, **la versión en inglés es la que cuenta**.
