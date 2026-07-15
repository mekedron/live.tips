---
title: Cómo live.tips gestiona el dinero (no lo hace)
description: No hay saldo de live.tips, ni calendario de pagos, ni comisión. Aquí está la arquitectura que vuelve esas tres afirmaciones aburridas en lugar de valientes.
slug: como-live-tips-gestiona-dinero
---

Cualquier bote de propinas puede poner «0 % de comisión» en su página de inicio. La
pregunta interesante es qué tendría que hacer el software para *empezar* a llevarse
una parte, y cuánto de ello podrías ver.

Para live.tips la respuesta es: habría que reconstruirlo. Eso no es una promesa sobre
nuestras intenciones, es una descripción de adónde va el dinero.

## El dinero nunca pasa por nosotros

Cuando un fan toca un importe con tarjeta, el pago se crea contra **tu** cuenta de
Stripe, se asienta en **tu** saldo de Stripe y se abona según **tu** calendario de
Stripe. La única comisión es la tarifa de procesamiento estándar de la propia Stripe,
que Stripe te cobra directamente, exactamente como lo haría si hubieras integrado Stripe
tú mismo.

No hay libro de cuentas de nuestro lado porque no hay nada que registrar. No podríamos
quedarnos con un porcentaje sin construir primero aquello que retiene el dinero — y no
existe tal cosa.

Eso es cierto tanto si inicias sesión como si no. Lo que cambia al iniciar sesión es el
camino de los *datos*, no el del dinero, y las dos secciones siguientes son honestas
sobre cómo exactamente.

## Tus claves, y dónde viven

La configuración pide una clave de API de Stripe *restringida*, no una clave secreta de
producción — esas las rechazamos de plano. Restringida significa que la clave sabe hacer
dos cosas: crear el enlace de propina de paga-lo-que-quieras y vigilar la llegada de las
propinas. No puede leer tu saldo, iniciar pagos, emitir reembolsos ni tocar datos de
clientes. Si se filtrara mañana, el radio de la explosión es un enlace de propina.

**Sin cuenta, esa clave nunca sale de tu dispositivo.** Se aloja en el llavero del propio
dispositivo y solo se envía a `api.stripe.com`, siempre por TLS. No hay ningún servidor
de live.tips en escena en absoluto.

**Al iniciar sesión, la clave se traslada a nosotros** — porque una clave que solo existe
en un móvil no puede servir también a la tablet del escenario. La ciframos (una clave
AES-256 por secreto, envuelta a su vez por Google Cloud KMS) y la guardamos donde nada
pueda volver a leerla: ni otra cuenta, ni nosotros echando un vistazo a una base de
datos, ni siquiera tú. Solo se descifra dentro de nuestras funciones, se usa para hablar
con Stripe en tu nombre, y no se vuelve a entregar nunca a un dispositivo. Dígase con
claridad: iniciar sesión pone un servidor de live.tips en el camino entre Stripe y tu
historial de propinas. Nunca el dinero — los datos.

## Los servidores, y lo que no pueden hacer

Son dos, y ambos son mínimos.

**El relé** existe porque Revolut y MobilePay no se pueden manejar desde un navegador
como sí se puede con Stripe. Activarlos enciende un puñado de funciones de Firebase que
sirven tu página de propinas en `tip.live.tips`. Almacena el perfil público de tu página
de propinas — el nombre visible y los identificadores de pago que elegiste publicar — y,
para una página sin ninguna cuenta detrás, no guarda historial de propinas: una propina
espera solo hasta que el dispositivo que tienes en el escenario la muestra, y lo que nadie
vino a buscar se barre antes de que pase una hora. No ve dinero y se autoelimina tras 90
días de inactividad. Si solo usas Stripe y nunca inicias sesión, nunca se contacta con el
relé en absoluto.

**El webhook** existe solo en cuanto inicias sesión. Como tu clave vive ahora con
nosotros, Stripe informa de cada propina a una pequeña función nuestra, que la escribe en
tu propio historial para que tus otros dispositivos puedan mostrarla. Es una copia de un
evento, no una copia del dinero. No puede mover ni un céntimo, y solo puede escribir en la
única cuenta a la que pertenece.

Ninguno de los dos servidores puede llevarse una parte, porque ninguno está ni cerca del
dinero. Lo máximo que cualquiera de ellos puede hacer es fallar — y una configuración que
solo usa Stripe y sin cuenta no depende de ninguno.

## La cuenta que no tienes que crear

La app sigue arrancando en un perfil local del dispositivo, que es lo que siempre fue:
tu bote, tu clave y tu historial de propinas viven en el dispositivo y en ningún otro
sitio. No hay nada a lo que registrarse.

Iniciar sesión —con Apple, con Google o como invitado— ya es posible, y existe por una
sola razón: un segundo dispositivo. Si la tablet del escenario y el móvil de tu
bolsillo han de mostrar la misma noche, algo tiene que situarse entre ellos, y ese algo
es Firestore, bajo un identificador de usuario que solo tú puedes leer. Tus grupos, tus
ajustes, tu historial de propinas — y, cifrada como se ha dicho, tu clave de Stripe —
viven ahí. Eso es un cambio real en la historia de la privacidad y merece decirse con
claridad en vez de descubrirse: sin cuenta, ningún servidor ve jamás una propina; con
cuenta, la ve tu propio rincón del nuestro, y es nuestro webhook el que la escribe ahí. Es
el precio del segundo dispositivo, y está en tu mano pagarlo o rechazarlo. Lo que nunca
toca es el dinero: una cuenta mueve tus datos, no tu saldo, y sigue sin haber comisión.

## Por qué no deberías creernos sin más

Todo lo anterior es comprobable. El código está bajo licencia MIT y es público, y el
sitio es una compilación estática que GitHub Actions despliega en GitHub Pages: ninguna
infraestructura oculta, nada compilado tras una puerta. Abre la pestaña de red durante
una propina de demostración y lee las peticiones. Hay menos de las que esperas.

Esa es la verdadera promesa del producto. No que seamos de fiar, sino que no necesitas
que lo seamos.
</content>
