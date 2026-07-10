---
title: Un código QR, todos los métodos de pago
description: La mayoría de las herramientas de propinas te dan un código por cada proveedor de pago. Pega tres a un pie de micrófono y observa cómo la gente se rinde. Aquí está por qué live.tips se queda con uno.
slug: un-codigo-qr-todos-metodos-pago
---

Pasa junto a suficientes músicos callejeros y empezarás a fijarte en la cinta
adhesiva. Un código Revolut en el estuche de la guitarra. Un código MobilePay en el
amplificador. Quizá uno de PayPal, curvado por las esquinas, de una gira de hace dos
veranos.

Cada uno de esos códigos es una pequeña apuesta a que alguien entre el público usa
justo esa aplicación. Juntos son un muro de deberes, presentado a una persona que ya se
ha detenido, que ya ha sacado el teléfono y a la que le quedan quizá ocho segundos de
buena voluntad antes de que su amiga diga *venga, vamos*.

## El problema es la bifurcación, no la aplicación

Los proveedores de pago son regionales. Revolut viaja bien por toda Europa. Con
MobilePay se pagan entre sí finlandeses y daneses. Swish es el dueño de Suecia. Un
músico callejero en Helsinki que toca ante una plaza llena de turistas necesita de
verdad más de uno: esa parte no es el error.

El error es hacer que el público lo resuelva. Un fan que escanea un código MobilePay
sin tener MobilePay instalado no se pone a buscar tus otros códigos. Guarda el
teléfono. No perdiste la propina porque no quisiera dar; la perdiste porque le pusiste
en las manos una decisión de enrutamiento en el momento exacto en que se sentía
generoso.

## Lo que hacemos en su lugar

live.tips te da un solo código QR, y nunca cambia. Activa Stripe, Revolut y MobilePay a
la vez, y ese mismo código abre una única página de propinas que enumera cada método
que aceptas. El fan elige el que ya tiene. Nadie escanea nada dos veces.

Si solo quieres pagos con tarjeta, nunca verás la lista: la página combinada solo
aparece cuando activas un segundo método. Un código, una página, y la página se adapta
a ti en lugar de al proveedor.

Hay también un beneficio más silencioso. El código de tu estuche es ahora un objeto
permanente. Puedes imprimirlo una vez, plastificarlo, pegarlo en la tapa, y sigue
funcionando cuando añadas Revolut la primavera que viene o dejes MobilePay tras una
mudanza. Tu equipo de escenario deja de ser una función de tu pila de pagos.

## Adónde va realmente el dinero

Vale la pena decirlo sin rodeos, porque «una página para cada método» es exactamente la
frase que usa una plataforma justo antes de explicar su comisión: las propinas con
tarjeta van directas de tu fan a tu propia cuenta de Stripe. No estamos en medio de
eso. No hay saldo de live.tips, ni calendario de pagos, ni comisión.

Los flujos de Revolut y MobilePay funcionan de un modo algo distinto, y escribimos
sobre ello por separado en [cómo live.tips gestiona el dinero](post:how-live-tips-handles-money) —
cinco minutos bien invertidos si eres de esas personas que leen las condiciones antes
de pegar algo en el estuche de la guitarra. Deberías serlo.

## Pruébalo

Abre la [app](/app/?lang=es), deja Stripe en modo demo y apunta tu propio teléfono al
código que genera. Añade un segundo método y escanea el mismo código otra vez. Es el
mismo código. Esa es toda la funcionalidad.
