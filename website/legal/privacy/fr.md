---
title: Politique de confidentialité
description: live.tips n’a ni comptes, ni cookies, ni analytics, ni traçage. Voici la courte liste de ce qui est réellement traité, par qui, et pendant combien de temps.
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

- **Pas de comptes.** Il n’y a rien à créer.
- **Pas de cookies.** Aucun, nulle part.
- **Pas d’analytics, pas de traçage, pas de publicité, aucun script tiers** sur ce site.
- **Nous ne touchons jamais à votre argent.** Les pourboires vont directement du fan
  vers le compte Stripe, Revolut, MobilePay ou Monzo de l’artiste. Nous ne sommes pas
  sur ce chemin.
- **Dans la configuration par défaut, l’app ne parle qu’à Stripe** — à aucun serveur
  live.tips.
- Le seul serveur que nous exploitons est un petit relais, et il n’existe que si un
  artiste active Revolut, MobilePay ou Monzo.

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

## L’app

L’app live.tips s’exécute **sur l’appareil de l’artiste**. Tout ce qu’elle sait vit
là-bas :

- La **clé restreinte Stripe** est stockée dans le trousseau de l’appareil (Keychain
  iOS/macOS, Keystore Android) et n’est jamais transmise qu’à `api.stripe.com`.
- **L’historique des pourboires, l’historique des sessions, l’objectif et les réglages
  de l’app** sont stockés dans le stockage local de l’appareil. Cela inclut les noms et
  les messages que les fans joignent à leurs pourboires.
- Désinstaller l’app supprime tout cela. Il n’y a pas de sauvegarde dans le cloud de
  notre côté, parce qu’il n’y a pas de cloud de notre côté.

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

## Stripe

Quand un fan paie par carte, il se trouve sur la page de paiement de **Stripe**, pas sur
la nôtre. Stripe collecte et traite ses données de paiement en tant que responsable de
traitement indépendant, au titre de la
[politique de confidentialité de Stripe](https://stripe.com/privacy). Nous ne voyons
jamais de numéros de carte, et nous n’avons aucun accès au compte Stripe de l’artiste.

L’app de l’artiste lit ses propres pourboires depuis Stripe à l’aide de la clé restreinte
de l’artiste. Le nom et le message d’un fan, s’il en a laissé, voyagent de Stripe vers
l’appareil de l’artiste et s’arrêtent là.

## Le relais — uniquement si Revolut, MobilePay ou Monzo sont activés

Les configurations Stripe seules n’y touchent jamais, et peuvent s’arrêter de lire ici.

Revolut, MobilePay et Monzo n’offrent aucun moyen pour une app de confirmer qu’un
paiement a bien eu lieu ; ces pourboires transitent donc par un petit relais open source
que nous exploitons sur **Cloudflare** à l’adresse `api.live.tips`. Il ne touche jamais à
l’argent. Voici tout ce qu’il traite.

### Ce que l’artiste stocke

Créer une page de pourboires stocke le **nom d’affichage de l’artiste, son message
public, sa devise et les identifiants de paiement qu’il a choisi de publier** (son lien
de paiement Stripe, son nom d’utilisateur Revolut, son Box ID MobilePay, son nom
d’utilisateur Monzo). Tout cela est de l’information que l’artiste publie de toute façon
délibérément à l’intention des fans.

- **Conservation : supprimé automatiquement après 90 jours d’inactivité.**
- L’artiste peut le supprimer **immédiatement** depuis l’app, à tout moment.
- Aucune adresse e-mail, aucun mot de passe, aucun nom légal, aucune coordonnée bancaire
  n’est jamais collecté.

### Ce qu’un fan envoie

Le formulaire de pourboire demande un **montant**, et, en option, un **nom** et un
**message**. C’est tout le formulaire. Pas d’e-mail, pas de numéro de téléphone, pas de
compte.

- Si l’écran de l’artiste est **en ligne**, le pourboire lui est transmis directement et
  **n’est jamais écrit sur disque**.
- Si l’écran de l’artiste est **hors ligne** — téléphone verrouillé, pas de réseau — le
  pourboire est **conservé en stockage pendant une heure au maximum** afin de ne pas être
  simplement perdu, puis remis dès que l’écran se reconnecte. Si personne ne se
  reconnecte, il est **supprimé sans avoir été vu**. C’est le seul texte écrit par un fan
  que le relais stocke, et une heure en est la limite absolue.
- Votre nom et votre message sont également placés dans la **note de paiement** qui
  s’ouvre dans Revolut, MobilePay ou Monzo — c’est ainsi que l’artiste sait qui a laissé
  un pourboire. Ces sociétés les traitent ensuite au titre de leurs propres politiques de
  confidentialité.
- Le relais ne conserve **aucun historique de pourboires**. Il ne peut montrer, ni à
  vous, ni à nous, ni à personne, une liste de qui a laissé un pourboire à qui.

### Adresses IP et lutte contre les abus

Un formulaire ouvert auquel n’importe qui peut envoyer des données a besoin d’une
protection contre les bots, donc :

- Votre adresse IP sert à **limiter le débit** des requêtes, et elle est envoyée à
  **Cloudflare Turnstile** (une vérification anti-bot qui s’exécute sur la page de
  pourboire) pour vérifier que vous n’êtes pas un bot. Turnstile est un produit
  Cloudflare, utilisé à la place d’un CAPTCHA qui vous profilerait.
- Pour empêcher quelqu’un de créer des milliers de pages de pourboires, un **hachage
  cryptographique de l’adresse IP** de la personne qui en crée une est conservé pendant
  environ **deux heures**, puis jeté.
- Les **journaux d’exploitation de Cloudflare** enregistrent les détails techniques des
  requêtes adressées au relais — URL, horodatage, statut — pendant quelques jours. Ils ne
  contiennent ni noms ni messages de fans. Cloudflare agit comme notre sous-traitant ;
  voir la [politique de confidentialité de Cloudflare](https://www.cloudflare.com/privacypolicy/).

### Compteurs

Le relais compte **combien de pourboires** une page de pourboires donnée a relayés, afin
que nous puissions repérer les abus et savoir si la chose sert à quelque chose. C’est un
nombre. Il ne contient aucune donnée de fan.

## Base légale, si vous en avez besoin (RGPD)

- Faire fonctionner le relais pour un artiste qui l’a activé, et livrer le pourboire d’un
  fan à l’écran auquel il était destiné : **exécution d’un service que vous avez
  demandé**.
- Limitation de débit, Turnstile et quotas fondés sur l’IP hachée : **intérêt légitime**
  à empêcher qu’un service gratuit et ouvert ne soit détruit par les bots et la fraude.
- Journaux de serveur : **intérêt légitime** à exploiter et sécuriser le service.

## Vos droits

Vous pouvez nous demander une copie, la rectification ou la suppression de tout ce que
nous détenons à votre sujet, et vous pouvez déposer une réclamation auprès de votre
autorité nationale de protection des données. Écrivez à
**[contact@live.tips](mailto:contact@live.tips)**.

En pratique, l’essentiel est déjà entre vos mains : les artistes peuvent supprimer leur
page de pourboires depuis l’app instantanément, les pourboires des fans s’évaporent en
moins d’une heure, et tout le reste vit sur votre propre appareil.

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
