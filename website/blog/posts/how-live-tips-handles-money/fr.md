---
title: Comment live.tips gère l'argent (il ne le gère pas)
description: Il n'y a pas de solde live.tips, pas de calendrier de versement et aucune commission. Voici l'architecture qui rend ces trois affirmations ennuyeuses plutôt que courageuses.
slug: comment-live-tips-gere-argent
---

N'importe quelle cagnotte à pourboires peut afficher « 0 % de commission » sur sa
page d'accueil. La question intéressante, c'est ce que le logiciel devrait faire pour
*commencer* à prélever une part, et quelle proportion tu pourrais en voir.

Pour live.tips, la réponse est : il faudrait le reconstruire. Ce n'est pas une
promesse sur nos intentions, c'est une description de l'endroit où va l'argent.

## Les pourboires par carte ne passent jamais par nous

Quand un fan touche un montant par carte, son navigateur dialogue avec
`api.stripe.com`. Pas avec un serveur live.tips — il n'y en a aucun sur ce chemin. Le
paiement est créé sur **ton** compte Stripe, arrive sur **ton** solde Stripe et est
versé selon **ton** calendrier Stripe. La seule commission est le frais de traitement
standard de Stripe lui-même, que Stripe te facture directement, exactement comme il
le ferait si tu avais intégré Stripe toi-même.

Il n'y a pas de registre de notre côté parce qu'il n'y a rien à consigner. Nous ne
pourrions pas prélever un pourcentage sans d'abord construire la chose qui détient
l'argent.

## Tes clés restent les tiennes

La configuration demande une clé d'API Stripe *restreinte*, pas une clé secrète de
production — celles-là, nous les refusons d'emblée. Elle est stockée dans le trousseau
de ton propre appareil et n'est jamais envoyée qu'à Stripe, en TLS.

Restreinte signifie que la clé sait faire deux choses : créer le lien de pourboire à
prix libre et surveiller l'arrivée des pourboires. Elle ne peut pas lire ton solde,
déclencher des versements, émettre des remboursements ni toucher aux données clients.
Si elle fuitait demain, le rayon de l'explosion serait un lien de pourboire.

## Le seul endroit où un serveur existe

Revolut et MobilePay ne peuvent pas être pilotés depuis un navigateur comme Stripe,
donc les activer met en marche un relais minimal à `api.live.tips`. Il vaut la peine
d'être précis sur ce que fait ce relais, car « nous avons ajouté un backend » est en
général le moment où ces histoires tournent mal.

Il stocke le profil public de ta page de pourboires — le nom affiché et les
identifiants de paiement que tu as choisi de publier. C'est tout. Il ne conserve aucun
historique de pourboires, ne voit aucun argent, ne détient aucune clé et s'autodétruit après
90 jours d'inactivité. L'argent circule toujours directement entre l'application
Revolut ou MobilePay de ton fan et la tienne.

Si tu n'utilises que Stripe, le relais n'est jamais contacté du tout.

## Pourquoi tu ne devrais pas nous croire sur parole

Tout ce qui précède est vérifiable. Le code source est sous licence MIT et public, et
le site est un build statique déployé par GitHub Actions sur GitHub Pages — aucune
infrastructure cachée, rien de compilé derrière une porte. Ouvre l'onglet réseau
pendant un pourboire de démonstration et lis les requêtes. Il y en a moins que tu ne
le penses.

Voilà la véritable promesse du produit. Non pas que nous soyons dignes de confiance,
mais que tu n'as pas besoin que nous le soyons.
