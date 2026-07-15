---
title: Politique de confidentialité
description: live.tips n’a ni cookies, ni analytics, ni traçage, et fonctionne sans aucun compte. Si vous choisissez de vous connecter, voici exactement ce qui est stocké, où, par qui, et pendant combien de temps.
updated: 2026-07-15
updated_label: Dernière mise à jour le 15 juillet 2026
---

live.tips est un pot à pourboires open source pour artistes. Il est géré par **Nikita
Rabykin**, un développeur indépendant, et non par une société. Si quoi que ce soit
ci-dessous vous importe, écrivez à **[contact@live.tips](mailto:contact@live.tips)** —
cette adresse aboutit à une vraie personne.

Cette politique est honnête, y compris sur les parties ennuyeuses. Nous préférons dire
« nous conservons votre nom aussi longtemps que vous conservez le groupe » plutôt que de
prétendre ne rien conserver et avoir tort.

## La version courte

- **Le compte est facultatif.** L’app fonctionne sans aucun compte, et c’est toujours le
  comportement par défaut. Si vous voulez retrouver vos groupes et votre historique sur un
  deuxième appareil, vous pouvez vous connecter — et une partie de tout cela est alors
  stockée sur un serveur, et davantage qu’auparavant. Ce qui relève de l’un et ce qui
  relève de l’autre est détaillé ci-dessous.
- **Pas de cookies.** Aucun, nulle part.
- **Pas d’analytics, pas de traçage, pas de publicité, aucun script tiers** sur ce site.
- **Nous ne touchons jamais à votre argent.** Les pourboires vont directement du fan
  vers le compte Stripe, Revolut, MobilePay ou Monzo de l’artiste. Il n’y a jamais de
  solde live.tips.
- **Sans compte, l’app ne parle qu’à Stripe** — à aucun serveur live.tips. Si vous vous
  connectez, cela change : votre clé Stripe passe sur notre serveur et Stripe nous
  rapporte vos pourboires, pour que nous puissions les mettre sur vos autres appareils.
  C’est le coût honnête de la connexion, et il est détaillé en entier ci-dessous.
- **Les notifications push sont nouvelles, facultatives, et réservées aux comptes
  connectés.** Rien n’est poussé vers un appareil qui ne les a jamais activées, et un
  appareil sans compte n’en reçoit jamais aucune.
- Les serveurs que nous exploitons sont chez Firebase, chez Google. Ils n’existent que si
  un artiste active Revolut, MobilePay ou Monzo — ou s’il se connecte.

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
- **L’historique des pourboires, l’historique des sessions, l’objectif, la liste de
  demandes de chansons et les réglages de l’app** sont stockés dans le stockage local de
  l’appareil. Cela inclut les noms et les messages que les fans joignent à leurs
  pourboires.
- Désinstaller l’app supprime tout cela. Il n’y a pas de sauvegarde dans le cloud de
  notre côté, parce que dans ce mode il n’y a pas de cloud de notre côté.

**Nous ne recevons jamais rien de tout cela.** L’app est livrée sans SDK d’analytics,
sans rapporteur de plantages et sans code publicitaire — aucun, pas même désactivé. (Les
notifications push existent, mais c’est une fonctionnalité réservée aux comptes connectés
et désactivée tant que vous ne l’activez pas — voir *Mode deux*. Un appareil sans compte
n’en reçoit jamais aucune.)

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
  donne alors une adresse relais à la place, et il ne transmet votre nom que la toute
  première fois où vous vous connectez.)
- **Un compte invité** — un compte anonyme sans e-mail et sans nom. Il se synchronise et
  il peut être révoqué, mais il n’y a rien pour le récupérer si vous perdez l’appareil.
  C’est un uid, et rien de plus. Un compte invité ne peut pas utiliser la conservation de
  la clé Stripe côté serveur ni les notifications push décrites ci-dessous, car les deux
  nécessitent un compte que nous puissions vous restituer.

Une fois connecté, le compte reçoit son propre coin privé dans la base de données **Cloud
Firestore** de Google, à l’adresse `users/<your uid>/`. Les règles de sécurité accordent
ce coin à cet uid **et à personne d’autre** — aucun autre compte ne peut le lire, y
compris en devinant des URL. À l’intérieur :

| Quoi | Pourquoi c’est là |
| --- | --- |
| Vos **groupes** — noms, réglages du pot à pourboires et des moyens de paiement, texte de l’affiche, objectifs, et votre **liste de demandes de chansons** | pour qu’un groupe existe sur chaque appareil où vous vous connectez |
| **Les réglages de l’app**, y compris vos préférences de notifications | pour qu’un appareil que vous ajoutez soit déjà configuré |
| **Les enregistrements de sessions et l’historique des pourboires** — y compris **les noms et les messages que les fans joignent à leurs pourboires**, et **toute chanson qu’un fan a demandée** | parce que cet historique est exactement ce que vous avez demandé à voir sur l’autre appareil |
| La **session en direct** en cours en ce moment | pour qu’un deuxième écran puisse rejoindre le set de ce soir |
| Vos **appareils** — le nom que chacun se donne (« l’iPhone de Nikita »), sa plateforme et son modèle, sa langue d’interface, la date de première et de dernière apparition, et (si vous avez activé les notifications) un **jeton push** | pour que Réglages → Sécurité puisse les lister, qu’une notification atteigne le bon appareil dans la bonne langue, et que vous puissiez en révoquer un |
| Un petit **document de profil** — le nom de compte que vous avez choisi, et le fournisseur utilisé | pour que le sélecteur de compte puisse l’étiqueter |
| Un **fil de notifications** — une liste plafonnée des pourboires et demandes de chansons récents arrivés alors qu’aucun set n’était en cours | pour que vous puissiez rattraper ce que vous avez manqué |

Et maintenant l’essentiel, dit clairement : **sans compte, le nom et le message d’un fan
ne quittent jamais l’appareil de l’artiste. Avec un compte, ils sont stockés sur les
serveurs de Google, sous l’uid de l’artiste, dans le cadre de l’historique synchronisé de
cet artiste, et — comme l’expliquent les deux sections suivantes — c’est désormais notre
serveur qui les y écrit.** Aucun autre compte ne peut les lire, nous ne les regardons pas,
et rien n’en est déduit — mais ils sont là, et ils y restent aussi longtemps que le
groupe, et vous devez le savoir avant de vous connecter.

Se déconnecter remet l’appareil en mode local. Cela ne supprime pas les données du compte
— voir *Supprimer des choses*, ci-dessous.

#### Votre clé Stripe, quand vous vous connectez, passe sur notre serveur

C’est le plus grand changement, et celui qui mérite le plus d’être lu.

**Sans compte, votre clé restreinte Stripe ne quitte jamais votre appareil.** C’est le
Mode un, et il est inchangé.

**Quand vous vous connectez, elle quitte bien l’appareil — vers nous.** La clé est
chiffrée (une clé AES-256 propre à chaque secret, elle-même enveloppée par Google Cloud
KMS) et stockée côté serveur dans un endroit que **personne ne peut relire — ni un autre
compte, ni même vous.** Elle n’est déscellée qu’à l’intérieur de nos Cloud Functions,
utilisée pour dialoguer avec Stripe en votre nom, et n’est plus jamais remise à un
appareil.

Parce que la clé vit désormais chez nous, **Stripe rapporte vos pourboires directement à
notre serveur** : nous enregistrons un webhook sur votre propre compte Stripe, et Stripe
prévient ce webhook chaque fois qu’un pourboire est payé. Notre fonction écrit le
pourboire dans l’historique de votre compte (voir plus bas). Votre app n’interroge plus
Stripe pour un compte connecté ; elle n’atteint Stripe qu’au travers d’une liste étroite
et fixe d’opérations sur notre serveur (créer votre lien de pourboire, générer un lien de
demande de chanson, et relire vos propres pourboires pour le rapprochement).

Donc, dit sans euphémisme : **pour un compte connecté, il y a désormais un serveur
live.tips sur le chemin entre Stripe et votre historique.** Nous ne touchons toujours
jamais à l’argent — un pourboire par carte est créé sur votre compte Stripe, arrive sur
votre solde Stripe et est versé selon votre calendrier Stripe, exactement comme avant. Ce
qui a changé, c’est le chemin des *données*, pas celui de l’*argent*. Si vous ne vous
connectez jamais, rien de tout cela ne s’applique et l’app parle toujours directement à
`api.stripe.com` et à personne d’autre.

#### Ajouter un appareil avec un QR code

Pour ajouter un appareil, vous affichez un QR code depuis un appareil déjà connecté. Le
code est aléatoire, **à usage unique, et expire au bout de deux minutes**, et le nouvel
appareil n’obtient rien tant que vous n’avez pas appuyé sur *confirmer* sur l’ancien.
Pendant que cette poignée de main est ouverte, nous conservons le code, le nom que le
nouvel appareil s’est donné et sa plateforme — et l’enregistrement est supprimé à
l’expiration. Un QR code photographié ne sert à rien sans votre appui de confirmation.

## Demandes de chansons

Un groupe peut activer les **demandes de chansons** : les fans choisissent alors une
chanson dans la liste de l’artiste et, en option, paient pour la faire remonter dans la
file. Une demande n’est qu’un pourboire qui indique en plus **quelle chanson** a été
demandée — le même nom et le même message qu’un fan peut joindre à un pourboire
s’appliquent donc ici aussi, et elle est stockée et conservée exactement comme n’importe
quel autre pourboire (ci-dessous). La file publique que voit un fan n’affiche que **les
totaux par chanson** — combien une chanson a rapporté et où elle se situe — et ne porte
**aucun nom de fan**. Sans compte, toute la liste de demandes de chansons et son
historique ne vivent que sur l’appareil.

## Notifications push

Quand vous êtes connecté, l’app peut vous envoyer une **notification push** — mais
seulement si vous l’activez, par appareil, et seulement après que le système
d’exploitation de votre appareil en a accordé l’autorisation. Elle n’existe que pour une
chose : un pourboire ou une demande de chanson qui arrive **alors que vous n’êtes pas en
train de faire un set**, afin que vous soyez au courant du pourboire que vous auriez
sinon manqué. Un pourboire qui arrive pendant que votre scène est en direct n’envoie rien
— vous êtes déjà en train de le regarder.

- Pour délivrer une push, le **Firebase Cloud Messaging (FCM)** de Google a besoin d’un
  **jeton push** pour l’appareil. Nous stockons ce jeton, ainsi que la langue d’interface
  de l’appareil, sur l’enregistrement propre à cet appareil sous votre compte, et il est
  supprimé dès l’instant où vous désactivez les notifications, révoquez l’appareil ou vous
  déconnectez. Les jetons morts sont élagués automatiquement.
- La notification elle-même indique ce qui est arrivé — un montant, et le nom d’un fan ou
  le titre d’une chanson s’il en a laissé un. La même courte liste est conservée dans le
  **fil de notifications** de votre compte, plafonné aux cent entrées les plus récentes,
  pour que vous puissiez faire défiler ce qui est arrivé pendant votre absence.
- Sur le web, délivrer une push nécessite un petit **service worker** à la racine du site
  et le SDK de messagerie Firebase, que votre navigateur récupère auprès de Google
  (`gstatic.com`) la première fois. La push web est ensuite acheminée par le propre
  service push de votre navigateur (pour Chrome, c’est celui de Google). Rien de tout cela
  ne se charge tant que vous n’avez pas activé les notifications.
- **Un compte invité et un appareil sans compte ne reçoivent aucune push**, car une push
  nécessite un compte auquel nous puissions délivrer et un jeton que vous avez choisi de
  donner.

## Où tout cela vit physiquement

Firebase Auth, Cloud Firestore, nos Cloud Functions et la clé Cloud KMS qui enveloppe
votre secret Stripe s’exécutent tous dans l’**Union européenne** — la base de données
dans la multirégion `eur3` de Google, les fonctions et le trousseau de clés dans
`europe-west1`. Google agit comme notre sous-traitant au titre des
[conditions de confidentialité et de sécurité de Firebase](https://firebase.google.com/support/privacy)
et de sa propre [politique de confidentialité](https://policies.google.com/privacy).
Comme tout grand fournisseur, Google peut faire intervenir des infrastructures hors de
l’UE pour le support et la sécurité ; cela est régi par ces conditions, pas par nous. Les
notifications push, une fois remises au Firebase Cloud Messaging et au service push de
votre navigateur ou de votre téléphone, transitent par l’infrastructure de ces sociétés
pour atteindre votre appareil.

## Stripe

Quand un fan paie par carte, il se trouve sur la page de paiement de **Stripe**, pas sur
la nôtre. Stripe collecte et traite ses données de paiement en tant que responsable de
traitement indépendant, au titre de la
[politique de confidentialité de Stripe](https://stripe.com/privacy). Nous ne voyons
jamais de numéros de carte.

La façon dont vos pourboires vous parviennent dépend du mode :

- **Sans compte**, l’app de l’artiste lit ses propres pourboires depuis Stripe à l’aide
  de la clé restreinte de l’artiste — directement de l’appareil vers `api.stripe.com`.
  **Il n’y a aucun serveur live.tips sur ce chemin.**
- **Quand vous êtes connecté**, la clé vit sur notre serveur (chiffrée, comme ci-dessus),
  et Stripe rapporte chaque pourboire à notre webhook, qui l’écrit dans l’historique
  Firestore propre à cet artiste. **Dans ce mode, il y a un serveur live.tips sur le
  chemin** — pour les données du pourboire, jamais pour l’argent. Le nom et le message
  d’un fan, s’il en a laissé, voyagent avec le pourboire jusque dans l’historique propre à
  cet artiste et s’arrêtent là.

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
d’utilisateur Monzo), et, si les demandes de chansons sont activées, **sa liste publique
de chansons et ses prix par chanson**. Tout cela est de l’information que l’artiste publie
de toute façon délibérément à l’intention des fans.

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
**message** — et, pour une demande de chanson, quelle chanson. C’est tout le formulaire.
Pas d’e-mail, pas de numéro de téléphone, pas de compte.

Où va ce texte écrit par un fan, et pour combien de temps, dépend de si l’artiste est
connecté :

- **Si la page de pourboires n’a aucun compte derrière elle**, le pourboire est écrit dans
  une **file d’attente de livraison** — un unique document qui n’existe que pour être
  remis à l’écran de l’artiste. Quand l’écran affiche le pourboire, **l’appareil de
  l’artiste supprime ce document.** La suppression *est* l’accusé de réception. Si l’écran
  de l’artiste est hors ligne — téléphone verrouillé, pas de réseau — le pourboire
  **attend dans cette file pendant une heure au maximum**, afin de ne pas être simplement
  perdu, et passe dès que l’écran se reconnecte. Si personne ne se reconnecte, il est
  **supprimé sans avoir été vu**, balayé selon une planification. Pour un artiste sans
  compte, **cette file est le seul endroit où du texte écrit par un fan est stocké sur
  notre serveur, et une heure en est la limite absolue.**
- **Si la page de pourboires appartient à un compte connecté**, il n’y a pas de file.
  Notre serveur écrit le pourboire **directement dans l’historique propre à cet artiste**
  sous son uid — dans la session de ce soir si un set est en cours, ou dans les archives
  propres au groupe sinon. Il y reste **aussi longtemps que le groupe** ; c’est
  l’historique propre à l’artiste, et c’est ce pour quoi il s’est connecté. C’est le même
  historique que celui où écrit le webhook Stripe, ci-dessus.
- Votre nom et votre message sont également placés dans la **note de paiement** qui
  s’ouvre dans Revolut, MobilePay ou Monzo — c’est ainsi que l’artiste sait qui a laissé
  un pourboire. Ces sociétés les traitent ensuite au titre de leurs propres politiques de
  confidentialité.
- Le relais ne conserve **aucun registre de pourboires inter-artistes**. Il ne peut
  montrer, ni à vous, ni à nous, ni à personne d’autre, une liste de qui a laissé un
  pourboire à qui, tous artistes confondus.

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
| **Google (Firebase)** | Les comptes, les données synchronisées d’un artiste connecté, la clé Stripe chiffrée, le relais, les jetons push et leur livraison, les journaux serveur | Le compte facultatif, le relais facultatif et les notifications push |
| **Google Cloud KMS** | La clé qui enveloppe le secret Stripe d’un artiste connecté (jamais le secret en clair) | Garder la clé Stripe stockée illisible au repos |
| **Stripe** | Les données de paiement du fan, en tant que responsable de traitement indépendant ; et, pour un artiste connecté, les événements de pourboire envoyés à notre webhook | Les pourboires par carte |
| **Cloudflare** | L’IP du fan, pour la vérification Turnstile sur la page de pourboires. Et notre DNS. | Tenir les bots à l’écart du formulaire de pourboire |
| **GitHub** | L’IP et le user-agent de toute personne qui charge ce site | L’hébergement du site |
| **Votre navigateur / le service push de votre téléphone** (p. ex. celui de Google pour Chrome) | Un jeton push et le contenu de la notification, si vous avez activé les notifications | Délivrer les notifications push |
| **Revolut / MobilePay / Monzo** | Tout ce que le fan fait dans leur propre app, note de paiement incluse | Ces moyens de paiement |

Nous ne vendons rien à personne, et il n’y a personne d’autre sur cette liste.

## Base légale, si vous en avez besoin (RGPD)

- Faire fonctionner un compte que vous avez demandé, synchroniser vos propres données vers
  vos propres appareils, conserver votre clé Stripe pour que vos pourboires parviennent à
  votre historique, faire fonctionner le relais pour un artiste qui l’a activé, livrer le
  pourboire d’un fan à l’écran auquel il était destiné, et envoyer une push que vous avez
  activée : **exécution d’un service que vous avez demandé**.
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
- **Les notifications push** : désactivez-les sur un appareil et son jeton push est
  supprimé. Le fil de notifications se vide avec le groupe ou le compte.
- **Un appareil** : Réglages → Sécurité liste vos appareils. Vous pouvez en révoquer un,
  ou vous déconnecter partout ailleurs — ce qui met fin à la session de tous les autres
  appareils immédiatement, pas à terme.
- **Votre compte entier, en un seul geste : l’app n’a pas encore ce bouton.** Nous
  préférons l’admettre plutôt que de prétendre le contraire. En attendant qu’il existe,
  écrivez à **[contact@live.tips](mailto:contact@live.tips)** et nous supprimerons le
  compte et tout ce qu’il contient, à la main. Entre-temps, vous pouvez déjà supprimer
  chaque groupe, ce qui enlève tout ce qui a de la substance — y compris la clé Stripe
  stockée — et laisse derrière un compte vide.

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
