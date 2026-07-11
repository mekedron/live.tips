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

## El único lugar donde existe un servidor

Revolut y MobilePay no se pueden manejar desde un navegador como sí se puede con
Stripe, así que activarlos enciende un relé mínimo en `api.live.tips`. Vale la pena ser
preciso sobre lo que hace ese relé, porque «añadimos un backend» suele ser el punto
donde estas historias se tuercen.

Almacena el perfil público de tu página de propinas: el nombre visible y los
identificadores de pago que elegiste publicar. Eso es todo. No guarda historial de
propinas, no ve dinero, no retiene claves y se autoelimina tras 90 días de
inactividad. El dinero sigue moviéndose directamente entre la aplicación Revolut o
MobilePay de tu fan y la tuya.

Si solo usas Stripe, nunca se contacta con el relé en absoluto.

## Por qué no deberías creernos sin más

Todo lo anterior es comprobable. El código está bajo licencia MIT y es público, y el
sitio es una compilación estática que GitHub Actions despliega en GitHub Pages: ninguna
infraestructura oculta, nada compilado tras una puerta. Abre la pestaña de red durante
una propina de demostración y lee las peticiones. Hay menos de las que esperas.

Esa es la verdadera promesa del producto. No que seamos de fiar, sino que no necesitas
que lo seamos.
