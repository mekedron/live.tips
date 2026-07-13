# Un QR code, tous les moyens de paiement

> La plupart des outils de pourboire te donnent un code par prestataire de paiement. Scotches-en trois sur un pied de micro et regarde les gens abandonner. Voici pourquoi live.tips s'en tient à un seul.

Canonical: https://live.tips/fr/blog/un-qr-code-tous-moyens-paiement/
Published: 2026-07-09
Language: fr
Tags: QR codes, Revolut, MobilePay, Stripe

---

À force de passer devant assez de musiciens de rue, on finit par remarquer le scotch.
Un code Revolut sur l'étui de guitare. Un code MobilePay sur l'ampli. Peut-être un de
PayPal, gondolé aux coins, d'une tournée d'il y a deux étés.

Chacun de ces codes est un petit pari sur le fait que quelqu'un dans la foule utilise
précisément cette application. Ensemble, ils forment un mur de devoirs, présenté à une
personne qui s'est déjà arrêtée, a déjà sorti son téléphone, et à qui il reste
peut-être huit secondes de bonne volonté avant que son ami ne dise *allez, viens*.

## Le problème, c'est l'embranchement, pas l'application

Les prestataires de paiement sont régionaux. Revolut voyage bien à travers l'Europe.
MobilePay, c'est ainsi que Finlandais et Danois se paient entre eux. Swish règne sur
la Suède. Un musicien de rue à Helsinki qui joue devant une place pleine de touristes
a réellement besoin de plus d'un — cette partie-là n'est pas une erreur.

L'erreur, c'est de laisser le public la résoudre. Un fan qui scanne un code MobilePay
sans avoir MobilePay installé ne part pas à la recherche de tes autres codes. Il range
son téléphone. Tu n'as pas perdu le pourboire parce qu'il ne voulait pas donner ; tu
l'as perdu parce que tu lui as tendu une décision d'aiguillage à l'instant précis où
il se sentait généreux.

## Ce que nous faisons à la place

live.tips te donne un seul QR code, et il ne change jamais. Active Stripe, Revolut et
MobilePay ensemble, et ce même code ouvre une unique page de pourboires listant chaque
méthode que tu acceptes. Le fan choisit celle qu'il a déjà. Personne ne scanne quoi
que ce soit deux fois.

Si tu ne veux jamais que des paiements par carte, tu ne verras jamais la liste — la
page combinée n'apparaît qu'une fois que tu actives une deuxième méthode. Un code, une
page, et la page s'adapte à toi plutôt qu'au prestataire.

Il y a aussi un bénéfice plus discret. Le code sur ton étui est désormais un objet
permanent. Tu peux l'imprimer une fois, le plastifier, le coller sur le couvercle, et
il continue de fonctionner quand tu ajoutes Revolut au printemps prochain ou que tu
abandonnes MobilePay après un déménagement. Ton attirail de scène cesse d'être une
fonction de ta pile de paiement.

## Où va réellement l'argent

Ça vaut la peine de le dire clairement, car « une page pour chaque méthode » est
exactement la phrase qu'une plateforme prononce juste avant d'expliquer sa commission :
les pourboires par carte vont directement de ton fan vers ton propre compte Stripe.
Nous ne sommes pas au milieu. Il n'y a pas de solde live.tips, pas de calendrier de
versement, aucune commission.

Les flux Revolut et MobilePay fonctionnent un peu différemment, et nous en avons parlé
séparément dans [comment live.tips gère l'argent](https://live.tips/fr/blog/comment-live-tips-gere-argent/) —
cinq minutes bien employées si tu es du genre à lire les conditions avant de scotcher
quoi que ce soit sur ton étui de guitare. Tu devrais l'être.

## Essaie

Ouvre l'[app](https://live.tips/app/?lang=fr), laisse Stripe en mode démo et pointe ton propre
téléphone vers le code qu'elle génère. Ajoute une deuxième méthode et scanne le même
code à nouveau. C'est le même code. C'est toute la fonctionnalité.
