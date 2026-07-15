---
title: Comment live.tips gère l'argent (il ne le gère pas)
description: Il n'y a pas de solde live.tips, pas de calendrier de versement et aucune commission. Voici l'architecture qui rend ces trois affirmations ennuyeuses plutôt que courageuses.
slug: comment-live-tips-gere-argent
---

N'importe quelle cagnotte à pourboires peut afficher « 0 % de commission » sur sa
page d'accueil. La question intéressante, c'est ce que le logiciel devrait faire pour
*commencer* à prélever une part, et quelle proportion tu pourrais en voir.

Pour live.tips, la réponse est : il faudrait le reconstruire. Ce n'est pas une
promesse sur nos intentions, c'est une description de l'endroit où va l'argent.

## L'argent ne passe jamais par nous

Quand un fan touche un montant par carte, le paiement est créé sur **ton** compte
Stripe, arrive sur **ton** solde Stripe et est versé selon **ton** calendrier Stripe. La
seule commission est le frais de traitement standard de Stripe lui-même, que Stripe te
facture directement, exactement comme il le ferait si tu avais intégré Stripe toi-même.

Il n'y a pas de registre de notre côté parce qu'il n'y a rien à consigner. Nous ne
pourrions pas prélever un pourcentage sans d'abord construire la chose qui détient
l'argent — et cette chose n'existe pas.

C'est vrai que tu te connectes ou non. Ce que la connexion change, c'est le chemin des
*données*, pas celui de l'argent, et les deux sections suivantes sont honnêtes sur la
façon exacte dont cela se passe.

## Tes clés, et où elles vivent

La configuration demande une clé d'API Stripe *restreinte*, pas une clé secrète de
production — celles-là, nous les refusons d'emblée. Restreinte signifie que la clé sait
faire deux choses : créer le lien de pourboire à prix libre et surveiller l'arrivée des
pourboires. Elle ne peut pas lire ton solde, déclencher des versements, émettre des
remboursements ni toucher aux données clients. Si elle fuitait demain, le rayon de
l'explosion serait un lien de pourboire.

**Sans compte, cette clé ne quitte jamais ton appareil.** Elle réside dans le trousseau
de ton propre appareil et n'est jamais envoyée qu'à `api.stripe.com`, en TLS. Aucun
serveur live.tips n'est dans le tableau.

**Quand tu te connectes, la clé passe chez nous** — parce qu'une clé qui n'existe que sur
un seul téléphone ne peut pas servir aussi la tablette sur scène. Nous la chiffrons (une
clé AES-256 propre à chaque secret, elle-même enveloppée par Google Cloud KMS) et la
stockons là où rien ne peut la relire : ni un autre compte, ni nous jetant un œil à une
base de données, ni même toi. Elle n'est déscellée qu'à l'intérieur de nos fonctions,
utilisée pour dialoguer avec Stripe en ton nom, et n'est plus jamais remise à un appareil.
Disons-le franchement : se connecter place un serveur live.tips sur le chemin entre Stripe
et ton historique de pourboires. Jamais l'argent — les données.

## Les serveurs, et ce qu'ils ne peuvent pas faire

Il y en a deux, et tous deux sont minimaux.

**Le relais** existe parce que Revolut et MobilePay ne peuvent pas être pilotés depuis un
navigateur comme Stripe. Les activer met en marche une poignée de fonctions Firebase qui
servent ta page de pourboires à `tip.live.tips`. Il stocke le profil public de ta page de
pourboires — le nom affiché et les identifiants de paiement que tu as choisi de publier —
et, pour une page sans compte derrière elle, ne conserve aucun historique de pourboires :
un pourboire n'attend que le temps que ton appareil de scène l'affiche, et tout ce que
personne n'est venu récupérer est balayé dans l'heure. Il ne voit aucun argent et
s'autodétruit après 90 jours d'inactivité. Si tu n'utilises que Stripe et ne te connectes
jamais, le relais n'est jamais contacté du tout.

**Le webhook** n'existe qu'une fois que tu te connectes. Parce que ta clé vit désormais
chez nous, Stripe rapporte chaque pourboire à une petite fonction à nous, qui l'écrit dans
ton propre historique pour que tes autres appareils puissent l'afficher. C'est une copie
d'un événement, pas une copie de l'argent. Elle ne peut pas déplacer un centime, et elle
ne peut jamais écrire que dans l'unique compte auquel elle appartient.

Aucun des deux serveurs ne peut prélever une part, parce qu'aucun n'est où que ce soit
près de l'argent. Le maximum que l'un ou l'autre puisse faire, c'est tomber en panne — et
une configuration Stripe seule, sans compte, ne dépend d'aucun des deux.

## Le compte que tu n'es pas obligé de créer

L'application démarre toujours sur un profil local à l'appareil, ce qu'elle a toujours
été : ta cagnotte, ta clé et ton historique de pourboires vivent sur l'appareil et
nulle part ailleurs. Il n'y a rien à créer.

Se connecter — avec Apple, avec Google ou en tant qu'invité — est désormais possible,
et cela n'existe que pour une seule raison : un deuxième appareil. Si la tablette sur
scène et le téléphone dans ta poche doivent afficher la même soirée, il faut bien que
quelque chose se place entre les deux, et ce quelque chose est Firestore, sous un
identifiant d'utilisateur que toi seul peux lire. Tes groupes, tes réglages, ton
historique de pourboires — et, chiffrée comme ci-dessus, ta clé Stripe — vivent là. C'est
un vrai changement dans l'histoire de la confidentialité, et cela mérite d'être dit
franchement plutôt que découvert : sans compte, aucun serveur ne voit jamais un pourboire ;
avec un compte, ton propre coin du nôtre le voit, et c'est notre webhook qui l'y écrit.
C'est le prix du deuxième appareil, et c'est à toi de le payer ou de le refuser. Ce à quoi
cela ne touche jamais, c'est l'argent — un compte déplace tes données, pas ton solde, et
il n'y a toujours aucune commission.

## Pourquoi tu ne devrais pas nous croire sur parole

Tout ce qui précède est vérifiable. Le code source est sous licence MIT et public, et
le site est un build statique déployé par GitHub Actions sur GitHub Pages — aucune
infrastructure cachée, rien de compilé derrière une porte. Ouvre l'onglet réseau
pendant un pourboire de démonstration et lis les requêtes. Il y en a moins que tu ne
le penses.

Voilà la véritable promesse du produit. Non pas que nous soyons dignes de confiance,
mais que tu n'as pas besoin que nous le soyons.
