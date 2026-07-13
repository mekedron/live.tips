---
title: Politique de confidentialité
description: live.tips n’a ni cookies, ni analytics, ni traçage, et fonctionne sans aucun compte. Si vous choisissez de vous connecter, voici exactement ce qui est stocké, où, par qui, et pendant combien de temps.
updated: 2026-07-13
updated_label: Dernière mise à jour le 13 juillet 2026
---

live.tips est un pot à pourboires open source pour artistes. Il est géré par **Nikita
Rabykin**, un développeur indépendant, et non par une société. Si quoi que ce soit
ci-dessous vous importe, écrivez à **[contact@live.tips](mailto:contact@live.tips)** —
cette adresse aboutit à une vraie personne.

Cette politique est honnête, y compris sur les parties ennuyeuses. Nous préférons dire
« nous conservons votre nom pendant une heure au maximum » plutôt que de prétendre ne
rien conserver et avoir tort.

## La version courte

- **Le compte est facultatif.** L’app fonctionne sans aucun compte, et c’est toujours le
  comportement par défaut. Si vous voulez retrouver vos groupes et votre historique sur un
  deuxième appareil, vous pouvez vous connecter — et une partie de tout cela est alors
  stockée sur un serveur. Ce qui relève de l’un et ce qui relève de l’autre est détaillé
  ci-dessous.
- **Pas de cookies.** Aucun, nulle part.
- **Pas d’analytics, pas de traçage, pas de publicité, aucun script tiers** sur ce site.
- **Nous ne touchons jamais à votre argent.** Les pourboires vont directement du fan
  vers le compte Stripe, Revolut, MobilePay ou Monzo de l’artiste. Nous ne sommes pas
  sur ce chemin.
- **Dans la configuration par défaut, l’app ne parle qu’à Stripe** — à aucun serveur
  live.tips.
- Le seul serveur que nous exploitons est un petit relais hébergé sur Firebase, chez
  Google. Il n’existe que si un artiste active Revolut, MobilePay ou Monzo — ou s’il se
  connecte.

## Ce site

Le site est statique et hébergé sur **GitHub Pages**. En tant qu’hébergeur, GitHub
reçoit l’adresse IP et le user-agent du navigateur de toute personne qui charge une page
— c’est de la journalisation de serveur web ordinaire, cela se produit avant que le
moindre bout de notre code ne s’exécute, et nous ne pouvons pas la désactiver. GitHub
traite ces données au titre de sa propre
[déclaration de confidentialité](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement).
Nous ne lisons pas ces journaux et GitHub ne nous les montre pas.

Au-delà de cela, les pages que vous lisez ne chargent **rien depuis qui que ce soit
d’autre** : les polices, icônes et images sont servies par live.tips lui-même. Il n’y a
pas de Google Analytics, pas de tag manager, pas de pixel, aucun widget intégré.

Le site stocke **deux valeurs dans le `localStorage` de votre navigateur**, toutes deux
définies par vous, toutes deux lisibles uniquement par ce site, et aucune n’est jamais
envoyée où que ce soit :

| Clé | Ce qu’elle retient |
| --- | --- |
| `lt-landing-theme` | si vous avez choisi les couleurs claires, sombres ou automatiques |
| `lt-langbar-dismissed` | que vous avez fermé la bannière « aussi disponible dans votre langue » |

Vider le stockage de votre navigateur les supprime. Ce ne sont pas des cookies, elles ne
sont partagées avec personne, et elles n’identifient personne.

## L’app a deux modes, et la différence, c’est toute l’histoire

Tout ce qui suit dépend d’une seule question : **vous êtes-vous connecté ?**

### Mode un — sans compte. Toujours le comportement par défaut, toujours inchangé.

L’app s’exécute **sur l’appareil de l’artiste**, et tout ce qu’elle sait vit là-bas :

- La **clé restreinte Stripe** est stockée dans le trousseau de l’appareil (Keychain
  iOS/macOS, Keystore Android) et n’est jamais transmise qu’à `api.stripe.com`.
- **L’historique des pourboires, l’historique des sessions, l’objectif et les réglages
  de l’app** sont stockés dans le stockage local de l’appareil. Cela inclut les noms et
  les messages que les fans joignent à leurs pourboires.
- Désinstaller l’app supprime tout cela. Il n’y a pas de sauvegarde dans le cloud de
  notre côté, parce que dans ce mode il n’y a pas de cloud de notre côté.

**Nous ne recevons jamais rien de tout cela.** L’app est livrée sans SDK d’analytics,
sans rapporteur de plantages, sans notifications push et sans code publicitaire — aucun,
pas même désactivé.

Deux précisions, pour que l’affirmation « elle ne parle à personne » reste exactement
vraie :

- L’app récupère les **taux de change** une fois par jour auprès d’API publiques de taux
  (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). Ce sont de simples
  requêtes pour une liste publique de taux. Elles ne transportent aucune information sur
  vous, sur l’artiste ou sur un pourboire — mais, comme toute requête web, elles révèlent
  bien votre adresse IP à ces services.
- Si vous utilisez la **version navigateur** de l’app, votre navigateur la télécharge
  depuis notre hébergeur statique (voir *Ce site* ci-dessus).

### Mode deux — vous vous êtes connecté. Des données quittent alors l’appareil, délibérément.

Se connecter est un acte délibéré. Rien ne vous connecte à votre place, et rien dans
l’app ne cesse de fonctionner si vous ne le faites jamais. Vous vous connectez parce que
vous voulez un deuxième appareil : le téléphone dans votre poche et la tablette sur scène
montrant la même soirée, les mêmes groupes, le même historique.

Cela ne marche que si un serveur les détient. **Il les détient donc, et c’est le coût
honnête du deuxième appareil.**

Le serveur, c’est **Firebase**, c’est-à-dire Google. Il y a trois façons d’avoir un
compte :

- **Se connecter avec Apple** ou **se connecter avec Google** — Firebase Auth reçoit ce
  que le fournisseur transmet : un identifiant d’utilisateur (uid) et, généralement, une
  adresse e-mail et un nom. (Avec Apple, vous pouvez masquer votre e-mail ; Apple nous
  donne alors une adresse relais à la place.)
- **Un compte invité** — un compte anonyme sans e-mail et sans nom. Il se synchronise et
  il peut être révoqué, mais il n’y a rien pour le récupérer si vous perdez l’appareil.
  C’est un uid, et rien de plus.

Une fois connecté, le compte reçoit son propre coin privé dans la base de données **Cloud
Firestore** de Google, à l’adresse `users/<your uid>/`. Les règles de sécurité accordent
ce coin à cet uid **et à personne d’autre** — aucun autre compte ne peut le lire, y
compris en devinant des URL. À l’intérieur :

| Quoi | Pourquoi c’est là |
| --- | --- |
| Vos **groupes** — noms, réglages du pot à pourboires et des moyens de paiement, texte de l’affiche, objectifs | pour qu’un groupe existe sur chaque appareil où vous vous connectez |
| Votre **clé restreinte Stripe** et le secret de la page de pourboires du relais | dans un document de secrets que seul votre uid peut lire, et mis en cache dans le trousseau de chacun de vos appareils |
| **Les réglages de l’app** | pour qu’un appareil que vous ajoutez soit déjà configuré |
| **Les enregistrements de sessions et l’historique des pourboires** — y compris **les noms et les messages que les fans joignent à leurs pourboires** | parce que cet historique est exactement ce que vous avez demandé à voir sur l’autre appareil |
| La **session en direct** en cours en ce moment | pour qu’un deuxième écran puisse rejoindre le set de ce soir |
| Vos **appareils** — le nom que chacun se donne (« l’iPhone de Nikita »), sa plateforme et son modèle, la date de première et de dernière apparition | pour que Réglages → Sécurité puisse les lister, et que vous puissiez en révoquer un |
| Un petit **document de profil** — le nom de compte que vous avez choisi, et le fournisseur utilisé | pour que le sélecteur de compte puisse l’étiqueter |

Et maintenant l’essentiel, dit clairement : **sans compte, le nom et le message d’un fan
ne quittent jamais l’appareil de l’artiste. Avec un compte, ils sont stockés sur les
serveurs de Google, sous l’uid de l’artiste, dans le cadre de l’historique synchronisé de
cet artiste.** Aucun autre compte ne peut les lire, nous ne les regardons pas, et rien
n’en est déduit — mais ils sont là, et vous devez le savoir avant de vous connecter.

Se déconnecter remet l’appareil en mode local. Cela ne supprime pas les données du compte
— voir *Supprimer des choses*, ci-dessous.

### Ajouter un appareil avec un QR code

Pour ajouter un appareil, vous affichez un QR code depuis un appareil déjà connecté. Le
code est aléatoire, **à usage unique, et expire au bout de deux minutes**, et le nouvel
appareil n’obtient rien tant que vous n’avez pas appuyé sur *confirmer* sur l’ancien.
Pendant que cette poignée de main est ouverte, nous conservons le code, le nom que le
nouvel appareil s’est donné et sa plateforme — et l’enregistrement est supprimé à
l’expiration. Un QR code photographié ne sert à rien sans votre appui de confirmation.

## Où tout cela vit physiquement

Firebase Auth, Cloud Firestore et nos Cloud Functions s’exécutent dans l’**Union
européenne** — la base de données dans la multirégion `eur3` de Google, les fonctions dans
`europe-west1`. Google agit comme notre sous-traitant au titre des
[conditions de confidentialité et de sécurité de Firebase](https://firebase.google.com/support/privacy)
et de sa propre [politique de confidentialité](https://policies.google.com/privacy).
Comme tout grand fournisseur, Google peut faire intervenir des infrastructures hors de
l’UE pour le support et la sécurité ; cela est régi par ces conditions, pas par nous.

## Stripe

Quand un fan paie par carte, il se trouve sur la page de paiement de **Stripe**, pas sur
la nôtre. Stripe collecte et traite ses données de paiement en tant que responsable de
traitement indépendant, au titre de la
[politique de confidentialité de Stripe](https://stripe.com/privacy). Nous ne voyons
jamais de numéros de carte, et nous n’avons aucun accès au compte Stripe de l’artiste.

L’app de l’artiste lit ses propres pourboires depuis Stripe à l’aide de la clé restreinte
de l’artiste — directement de l’appareil vers `api.stripe.com`. **Il n’y a aucun serveur
live.tips sur ce chemin, et il n’y en a jamais eu.** Le nom et le message d’un fan, s’il
en a laissé, voyagent de Stripe vers l’appareil de l’artiste et s’arrêtent là — sauf si
l’artiste s’est connecté, auquel cas l’appareil les enregistre aussi dans l’historique
Firestore propre à cet artiste, comme décrit ci-dessus.

## Le relais — uniquement si Revolut, MobilePay ou Monzo sont activés

Les configurations Stripe seules n’y touchent jamais.

Revolut, MobilePay et Monzo n’offrent aucun moyen pour une app de confirmer qu’un
paiement a bien eu lieu ; ces pourboires transitent donc par un petit relais open source
que nous exploitons sur **Firebase** — des Cloud Functions et Firestore dans
`europe-west1`, avec la page de pourboires du fan servie depuis
**`tip.live.tips/t/<id>`**. Il ne touche jamais à l’argent. Voici tout ce qu’il traite.

### Ce que l’artiste stocke

Créer une page de pourboires stocke le **nom d’affichage de l’artiste, son message
public, sa devise et les identifiants de paiement qu’il a choisi de publier** (son lien
de paiement Stripe, son nom d’utilisateur Revolut, son Box ID MobilePay, son nom
d’utilisateur Monzo). Tout cela est de l’information que l’artiste publie de toute façon
délibérément à l’intention des fans.

- **Conservation : une page de pourboires sans compte derrière elle est supprimée
  automatiquement après 90 jours d’inactivité.** Une page de pourboires qui appartient à
  un compte connecté vit aussi longtemps que le groupe auquel elle appartient.
- L’artiste peut la supprimer **immédiatement** depuis l’app, à tout moment.
- Aucune adresse e-mail, aucun mot de passe, aucun nom légal, aucune coordonnée bancaire
  n’est collecté ici.
- Le secret de la page n’est stocké **que sous forme de hachage**. Nous ne pourrions pas
  vous dire ce secret si vous le demandiez ; nous pouvons seulement en vérifier un.

### Ce qu’un fan envoie

Le formulaire de pourboire demande un **montant**, et, en option, un **nom** et un
**message**. C’est tout le formulaire. Pas d’e-mail, pas de numéro de téléphone, pas de
compte.

- Le pourboire est écrit dans une **file d’attente de livraison** — un unique document
  qui n’existe que pour être remis à l’écran de l’artiste. Quand l’écran affiche le
  pourboire, **l’appareil de l’artiste supprime ce document.** La suppression *est*
  l’accusé de réception ; il n’y a pas de drapeau « livré », parce qu’il ne reste aucun
  enregistrement à marquer.
- Si l’écran de l’artiste est hors ligne — téléphone verrouillé, pas de réseau — le
  pourboire **attend dans cette file pendant une heure au maximum**, afin de ne pas être
  simplement perdu, et passe dès que l’écran se reconnecte. Si personne ne se reconnecte,
  il est **supprimé sans avoir été vu**, balayé selon une planification, que quelqu’un
  soit revenu le chercher ou non.
- **Cette file est le seul endroit où du texte écrit par un fan est stocké sur notre
  serveur, et une heure en est la limite absolue.** Si l’artiste est connecté, son
  appareil conserve ensuite le pourboire dans *son* historique Firestore — parce que c’est
  son historique, et que c’est pour cela qu’il s’est connecté.
- Votre nom et votre message sont également placés dans la **note de paiement** qui
  s’ouvre dans Revolut, MobilePay ou Monzo — c’est ainsi que l’artiste sait qui a laissé
  un pourboire. Ces sociétés les traitent ensuite au titre de leurs propres politiques de
  confidentialité.
- Le relais ne conserve **aucun historique de pourboires**. Il ne peut montrer, ni à
  vous, ni à nous, ni à personne, une liste de qui a laissé un pourboire à qui.

### Adresses IP et lutte contre les abus

Un formulaire ouvert auquel n’importe qui peut envoyer des données a besoin d’une
protection contre les bots, donc :

- Votre adresse IP est envoyée à **Cloudflare Turnstile** — une vérification anti-bot qui
  s’exécute sur la page de pourboires — pour vérifier que vous n’êtes pas un bot.
  Turnstile est un produit Cloudflare, utilisé à la place d’un CAPTCHA qui vous
  profilerait. Turnstile et notre DNS sont les seules choses que Cloudflare fait encore
  pour nous ; le relais lui-même tourne désormais sur Firebase. Voir la
  [politique de confidentialité de Cloudflare](https://www.cloudflare.com/privacypolicy/).
- Votre IP sert aussi à **limiter le débit** des requêtes — envoyer un pourboire, créer
  une page de pourboires, utiliser un code d’ajout d’appareil. Ce que nous stockons pour
  cela, c’est un **hachage cryptographique salé de l’IP**, jamais l’IP elle-même, pendant
  environ **deux heures**, puis il est supprimé. Le sel est un secret du serveur : sans
  lui, le code refuse de stocker quoi que ce soit, plutôt que de garder un hachage qui
  pourrait être inversé.
- Les **journaux d’exploitation de Google** enregistrent les détails techniques des
  requêtes adressées au relais — URL, horodatage, statut — pendant quelques jours. Notre
  code ne journalise délibérément aucun nom, aucun message, aucun secret et aucun en-tête.
  Google agit comme notre sous-traitant.

### Compteurs

Le relais compte **combien de pourboires** une page de pourboires donnée a relayés, afin
que nous puissions repérer les abus et savoir si la chose sert à quelque chose. C’est un
nombre. Il ne contient aucune donnée de fan.

## Qui traite quoi

| Qui | Ce qu’ils reçoivent | Pourquoi |
| --- | --- | --- |
| **Google (Firebase)** | Les comptes, les données synchronisées d’un artiste connecté, le relais, les journaux serveur | Le compte facultatif et le relais facultatif |
| **Stripe** | Les données de paiement du fan, en tant que responsable de traitement indépendant | Les pourboires par carte |
| **Cloudflare** | L’IP du fan, pour la vérification Turnstile sur la page de pourboires. Et notre DNS. | Tenir les bots à l’écart du formulaire de pourboire |
| **GitHub** | L’IP et le user-agent de toute personne qui charge ce site | L’hébergement du site |
| **Revolut / MobilePay / Monzo** | Tout ce que le fan fait dans leur propre app, note de paiement incluse | Ces moyens de paiement |

Nous ne vendons rien à personne, et il n’y a personne d’autre sur cette liste.

## Base légale, si vous en avez besoin (RGPD)

- Faire fonctionner un compte que vous avez demandé, synchroniser vos propres données vers
  vos propres appareils, faire fonctionner le relais pour un artiste qui l’a activé, et
  livrer le pourboire d’un fan à l’écran auquel il était destiné : **exécution d’un
  service que vous avez demandé**.
- Limitation de débit, Turnstile, quotas fondés sur l’IP hachée et révocation d’appareils :
  **intérêt légitime** à empêcher qu’un service gratuit et ouvert ne soit détruit par les
  bots et la fraude, et à garder les comptes des artistes en sécurité.
- Journaux de serveur : **intérêt légitime** à exploiter et sécuriser le service.

## Supprimer des choses

Cela compte plus que n’importe quelle promesse que nous pourrions faire à ce sujet, alors
voici exactement ce qui existe aujourd’hui — y compris ce qui n’existe pas.

- **Sans compte** : désinstallez l’app. Voilà, tout est parti.
- **Un groupe** : supprimer un groupe dans l’app efface les données cloud de ce groupe —
  ses réglages, ses clés, ses sessions, son historique de pourboires — en même temps que
  la copie sur l’appareil.
- **Une page de pourboires** : supprimez-la ou régénérez-la dans l’app et elle est effacée
  du relais aussitôt, pourboires en attente compris.
- **Un appareil** : Réglages → Sécurité liste vos appareils. Vous pouvez en révoquer un,
  ou vous déconnecter partout ailleurs — ce qui met fin à la session de tous les autres
  appareils immédiatement, pas à terme.
- **Votre compte entier, en un seul geste : l’app n’a pas encore ce bouton.** Nous
  préférons l’admettre plutôt que de prétendre le contraire. En attendant qu’il existe,
  écrivez à **[contact@live.tips](mailto:contact@live.tips)** et nous supprimerons le
  compte et tout ce qu’il contient, à la main. Entre-temps, vous pouvez déjà supprimer
  chaque groupe, ce qui enlève tout ce qui a de la substance et laisse derrière un compte
  vide.

## Vos droits

Vous pouvez nous demander une copie, la rectification ou la suppression de tout ce que
nous détenons à votre sujet, et vous pouvez déposer une réclamation auprès de votre
autorité nationale de protection des données. Écrivez à
**[contact@live.tips](mailto:contact@live.tips)**.

En pratique, l’essentiel est déjà entre vos mains : un artiste peut supprimer une page de
pourboires ou un groupe depuis l’app instantanément, les pourboires de fans non livrés
s’évaporent en moins d’une heure, et si vous ne vous connectez jamais, rien de tout cela
n’a jamais été ailleurs que sur votre propre appareil.

## Enfants

live.tips ne s’adresse pas aux enfants et nous ne traitons pas sciemment leurs données.

## Modifications

Nous mettrons cette page à jour quand le logiciel changera. Comme tout le projet est open
source, **chaque version passée de cette politique se trouve dans l’historique git
public** — vous pouvez comparer exactement ce qui a changé et quand.

## Langue

Cette politique est publiée dans toutes les langues prises en charge par le site, par
commodité. En cas de divergence entre une traduction et la version anglaise, **c’est la
version anglaise qui fait foi**.
