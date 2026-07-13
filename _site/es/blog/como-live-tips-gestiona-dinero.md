# Cómo live.tips gestiona el dinero (no lo hace)

> No hay saldo de live.tips, ni calendario de pagos, ni comisión. Aquí está la arquitectura que vuelve esas tres afirmaciones aburridas en lugar de valientes.

Canonical: https://live.tips/es/blog/como-live-tips-gestiona-dinero/
Published: 2026-07-02
Updated: 2026-07-13
Language: es
Tags: Stripe, privacy, open source

---

Cualquier bote de propinas puede poner «0 % de comisión» en su página de inicio. La
pregunta interesante es qué tendría que hacer el software para *empezar* a llevarse
una parte, y cuánto de ello podrías ver.

Para live.tips la respuesta es: habría que reconstruirlo. Eso no es una promesa sobre
nuestras intenciones, es una descripción de adónde va el dinero.

## Las propinas con tarjeta nunca pasan por nosotros

Cuando un fan toca un importe con tarjeta, su navegador habla con `api.stripe.com`. No
con un servidor de live.tips: no hay ninguno en esa ruta. El pago se crea contra **tu**
cuenta de Stripe, se asienta en **tu** saldo de Stripe y se abona según **tu**
calendario de Stripe. La única comisión es la tarifa de procesamiento estándar de la
propia Stripe, que Stripe te cobra directamente, exactamente como lo haría si hubieras
integrado Stripe tú mismo.

No hay libro de cuentas de nuestro lado porque no hay nada que registrar. No podríamos
quedarnos con un porcentaje sin construir primero aquello que retiene el dinero.

## Tus claves siguen siendo tuyas

La configuración pide una clave de API de Stripe *restringida*, no una clave secreta
de producción: esas las rechazamos de plano. Se guarda en el llavero de tu propio
dispositivo y solo se envía a Stripe, siempre por TLS.

Restringida significa que la clave sabe hacer dos cosas: crear el enlace de propina de
paga-lo-que-quieras y vigilar la llegada de las propinas. No puede leer tu saldo,
iniciar pagos, emitir reembolsos ni tocar datos de clientes. Si se filtrara mañana, el
radio de la explosión es un enlace de propina.

## El único servidor en la ruta del pago

Revolut y MobilePay no se pueden manejar desde un navegador como sí se puede con
Stripe, así que activarlos enciende un relé mínimo: un puñado de funciones de Firebase
que sirven tu página de propinas en `tip.live.tips`. Vale la pena ser preciso sobre lo
que hace ese relé, porque «añadimos un backend» suele ser el punto donde estas
historias se tuercen.

Almacena el perfil público de tu página de propinas: el nombre visible y los
identificadores de pago que elegiste publicar. Eso es todo. No guarda historial de
propinas, no ve dinero, no retiene claves y se autoelimina tras 90 días de
inactividad. Una propina por Revolut o MobilePay espera ahí solo hasta que el
dispositivo que tienes en el escenario la recoge: mostrarla la borra, y lo que nadie
vino a buscar se barre antes de que pase una hora. El dinero sigue moviéndose
directamente entre la aplicación Revolut o MobilePay de tu fan y la tuya.

Si solo usas Stripe, nunca se contacta con el relé en absoluto.

## La cuenta que no tienes que crear

La app sigue arrancando en un perfil local del dispositivo, que es lo que siempre fue:
tu bote, tu clave y tu historial de propinas viven en el dispositivo y en ningún otro
sitio. No hay nada a lo que registrarse.

Iniciar sesión —con Apple, con Google o como invitado— ya es posible, y existe por una
sola razón: un segundo dispositivo. Si la tablet del escenario y el móvil de tu
bolsillo han de mostrar la misma noche, algo tiene que situarse entre ellos, y ese algo
es Firestore, bajo un identificador de usuario que solo tú puedes leer. Tus grupos, tus
ajustes, la clave restringida y el historial de propinas se sincronizan ahí. Eso es un
cambio real en la historia de la privacidad y merece decirse con claridad en vez de
descubrirse: sin cuenta, ningún servidor ve jamás una propina; con cuenta, la ve tu
propio rincón del nuestro. Es el precio del segundo dispositivo, y está en tu mano
pagarlo o rechazarlo. Lo que nunca toca es el dinero: una cuenta mueve tus datos, no tu
saldo, y sigue sin haber comisión.

## Por qué no deberías creernos sin más

Todo lo anterior es comprobable. El código está bajo licencia MIT y es público, y el
sitio es una compilación estática que GitHub Actions despliega en GitHub Pages: ninguna
infraestructura oculta, nada compilado tras una puerta. Abre la pestaña de red durante
una propina de demostración y lee las peticiones. Hay menos de las que esperas.

Esa es la verdadera promesa del producto. No que seamos de fiar, sino que no necesitas
que lo seamos.
