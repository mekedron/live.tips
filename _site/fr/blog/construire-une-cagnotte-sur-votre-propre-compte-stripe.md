# Construisez une cagnotte à pourboires sur votre propre compte Stripe

> Trois appels d'API suffisent pour obtenir une page hébergée « prix libre » avec Apple Pay et Google Pay, sans le moindre serveur. Voici le montage complet : la clé restreinte, les permissions, comment récupérer les pourboires sans webhook, et le calcul des frais que personne n'imprime.

Canonical: https://live.tips/fr/blog/construire-une-cagnotte-sur-votre-propre-compte-stripe/
Published: 2026-07-11
Language: fr
Tags: Stripe, open source, how-to, API, fees

---

Vous voulez une cagnotte à pourboires. Vous ne voulez pas céder 5 % de la soirée
d'un musicien de rue à une plateforme, et vous savez parfaitement parler à une API.
La question n'est donc pas *à quelle cagnotte dois-je m'inscrire*, mais *combien
dois-je réellement construire*.

Moins que vous ne le pensez. Sur Stripe, la réponse concrète tient en trois appels
d'API : pas de serveur, pas de backend, pas de point de terminaison webhook. Le
reste de cet article, c'est ce montage — plus les deux choses que tout le monde rate.

## L'astuce, c'est un Price « prix libre »

Stripe propose un mode de tarification où le fan saisit lui-même le montant. Cela
s'appelle [pay what you want](https://docs.stripe.com/payments/checkout/pay-what-you-want),
et c'est toute la fonctionnalité. Vous créez un Product, vous y attachez un Price
avec `custom_unit_amount[enabled]=true`, puis vous accrochez un
[Payment Link](https://docs.stripe.com/payment-links/create) par-dessus.

```sh
# 1. la chose que vous « vendez »
curl https://api.stripe.com/v1/products \
  -u "$RK:" \
  -d name="Tips — Mira" \
  -d "metadata[managed_by]"=my-tip-jar

# 2. le prix que le fan choisit
curl https://api.stripe.com/v1/prices \
  -u "$RK:" \
  -d product=prod_... \
  -d currency=eur \
  -d "custom_unit_amount[enabled]"=true \
  -d "custom_unit_amount[preset]"=500 \
  -d "custom_unit_amount[minimum]"=200

# 3. la page
curl https://api.stripe.com/v1/payment_links \
  -u "$RK:" \
  -d "line_items[0][price]"=price_... \
  -d "line_items[0][quantity]"=1 \
  -d submit_type=pay
```

Le troisième appel renvoie une `url`. Cette URL *est* votre cagnotte. C'est une page
hébergée par Stripe : conforme PCI sans que vous y pensiez, localisée, et elle affiche
Apple Pay ou Google Pay à tout fan dont le téléphone les a configurés — les
[moyens de paiement dynamiques](https://docs.stripe.com/payments/payment-methods/dynamic-payment-methods)
décident pour vous selon l'appareil et le pays. Vous n'avez écrit aucun frontend.

Encodez l'URL en QR code avec la bibliothèque de votre choix — ce n'est qu'une chaîne
de caractères — imprimez-le, scotchez-le sur l'étui. Le code n'expire jamais, et il
ne pointe vers aucun serveur à vous, puisque vous n'en avez pas.

Deux paramètres à connaître :

- **`custom_unit_amount[preset]`** est le montant affiché à l'ouverture. `500`
  signifie que le fan voit déjà 5,00 € pré-rempli et peut le modifier. Ce chiffre
  fait plus pour votre pourboire moyen que tout le reste de la page.
- **`custom_unit_amount[minimum]`** est un plancher. Mettez-en un. La raison est
  dans la section sur les frais, et ce n'est pas une erreur d'arrondi.

Vous pouvez aussi collecter un nom et un message. Les Payment Links acceptent jusqu'à
trois `custom_fields` — c'est comme ça que vous obtenez le « c'était de qui ? » sans
construire de formulaire :

```sh
  -d "custom_fields[0][key]"=nickname \
  -d "custom_fields[0][type]"=text \
  -d "custom_fields[0][label][type]"=custom \
  -d "custom_fields[0][label][custom]"="Votre nom ou pseudo" \
  -d "custom_fields[0][optional]"=true
```

Stripe a des [exigences pour accepter pourboires et dons](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations) —
lisez-les une fois. Le prix libre ne se combine pas non plus avec d'autres line items,
des remises ou des paiements récurrents. Pour une cagnotte, rien de tout cela ne gêne.

Cette distinction mérite d'être juste. Stripe le dit ainsi : un pourboire récompense un
bien ou un service déjà rendu, tandis qu'un don doit être lié à une cause caritative. Vous
avez joué le set ; le pourboire le paie. C'est aussi pourquoi l'appel ci-dessus envoie
`submit_type=pay` et non `donate` — `donate` hébergerait votre lien sur
`donate.stripe.com` et afficherait *Faire un don* sur le bouton. C'est un autre métier, et
Stripe l'examine bien plus sévèrement.

## La clé : partez du principe qu'elle fuitera, et rendez ça banal

Ne mettez pas une clé secrète (`sk_live_…`) sur un appareil posé sur une scène.
Utilisez une [clé restreinte](https://docs.stripe.com/keys/restricted-api-keys)
(`rk_live_…`) : vous choisissez une permission par ressource, et tout ce que vous
n'avez pas choisi reste sur **None**.

Pour le montage ci-dessus, la liste complète tient en cinq lignes :

| Ressource | Permission | Ce que ça vous donne |
| --- | --- | --- |
| Products | Write | créer le Product |
| Prices | Write | créer le Price à prix libre |
| Payment Links | Write | créer le lien |
| Checkout Sessions | Read | voir les pourboires arrivés |
| Events | Read | le flux en direct (section suivante) |

Tout le reste — Balance, Payouts, Refunds, Customers, PaymentIntents, tout Connect —
reste sur **None**.

Maintenant, faites l'exercice qui rend tout cela utile. Votre tablette disparaît de la
table de merch à 1 h du matin. Que peut faire le voleur avec la clé dans son trousseau ?
Lire votre historique de pourboires et créer d'autres liens de pourboire dans votre
compte. C'est tout le rayon de l'explosion. Il ne voit pas votre solde, ne peut
déclencher aucun virement, ne peut rembourser aucune carte qu'il contrôle, ne peut
lire aucune liste de clients. Vous révoquez la clé depuis un téléphone dans le taxi du
retour et l'appareil s'éteint. Rien de votre argent n'a bougé.

Cette asymétrie — accès en écriture à la cagnotte, zéro accès à l'argent — est la
seule raison pour laquelle une architecture sans serveur, avec votre propre clé, se
défend. C'est aussi pourquoi « Login with Stripe » n'est pas la réponse ici : OAuth
exige un serveur appartenant au développeur de l'app pour détenir votre jeton — et un
serveur, c'est précisément ce que nous ne construisons pas.

(Une bizarrerie que vous rencontrerez : la permission *Prices* s'appelle en interne
`plan_write`, si bien que le message d'erreur de Stripe nomme un scope qui n'apparaît
pas sous ce nom dans le dashboard. Il s'agit bien de Prices.)

## Relire les pourboires sans webhook

C'est là que la plupart des tutoriels s'arrêtent ou dégainent un webhook — et c'est là
qu'une scène diffère vraiment d'une application web.

Un webhook est une requête HTTP entrante. Une tablette derrière un pied de micro ne
peut pas en recevoir. Elle est sur le wifi invité d'une salle, derrière un NAT, sans
adresse publique, sans certificat TLS — et elle n'a rien à faire avec tout ça. Si vous
prenez la voie du webhook, il vous faut monter un serveur pour attraper les événements
et une socket pour les pousser vers l'appareil : un backend, une charge d'exploitation,
et un endroit où vivent désormais les noms de vos fans. Vous venez de reconstruire la
plateforme que vous vouliez éviter.

Alors tirez au lieu de vous faire pousser. Le point de terminaison
[List all events](https://docs.stripe.com/api/events/list) de Stripe est public,
documenté, et renvoie les événements du plus récent au plus ancien :

```sh
curl -G https://api.stripe.com/v1/events \
  -u "$RK:" \
  -d "types[]"=checkout.session.completed \
  -d "types[]"=checkout.session.async_payment_succeeded \
  -d ending_before=evt_LE_DERNIER_VU \
  -d limit=100
```

`ending_before`, c'est tout le design. Gardez l'id du plus récent événement traité ;
chaque sondage demande tout ce qui est strictement plus récent, et vous avancez le
curseur. Pas d'horodatage, pas de dérive d'horloge, pas de déduplication par montant.
Au premier sondage d'un set, demandez `limit=1` sans curseur pour vous ancrer sur ce
qui existe déjà, afin de ne pas rejouer les pourboires de ce matin pendant les balances.

Filtrez ensuite ce qui revient. Les deux types d'événements peuvent se déclencher pour
un seul paiement : dédupliquez sur l'id de la Checkout Session. Vérifiez
`payment_status == "paid"` — une session terminée n'est pas forcément une session payée.
Et vérifiez que `payment_link` correspond bien à *votre* lien, car `/v1/events` porte
sur tout le compte et vous servira volontiers le trafic de tout ce que ce compte Stripe
fait par ailleurs.

Soyez honnête sur les compromis, car ils sont réels :

- **Stripe recommande les webhooks.** Le polling n'est pas la voie bénie ; c'est un
  point de terminaison documenté employé délibérément. Dites-le dans votre README et
  passez à la suite.
- **Les événements remontent à 30 jours.** [Les mots de Stripe](https://docs.stripe.com/api/events/list) :
  *« List events, going back up to 30 days. »* C'est un flux en direct, pas votre
  grand livre. Votre grand livre, ce sont les Checkout Sessions — et le vrai, c'est le
  dashboard Stripe.
- **Surveillez le quota de lecture.** Tout le monde regarde la limite par seconde
  ([rate limits](https://docs.stripe.com/rate-limits) : 100 req/s en live) et personne
  ne regarde l'autre : Stripe alloue environ **500 requêtes de lecture par transaction**
  sur 30 jours glissants, avec un plancher de 10 000 lectures par mois. Sondez toutes
  les 4 secondes et un set de trois heures fait ~2 700 lectures. Quatre longs concerts
  dans le mois et vous êtes au plancher. Les pourboires vous achètent de la marge en
  arrivant — mais si vous sondez chaque seconde parce que ça semblait plus réactif,
  vous trouverez le plafond. Quatre secondes n'est pas un chiffre paresseux ; c'est *le*
  chiffre.

Voilà la forme honnête de la chose : le polling vous coûte quelques milliers de GET et
vous fait gagner la suppression d'un backend entier.

## Le calcul des frais, fait correctement

Une plateforme qui annonce 0 % n'est pas gratuite, et ceci non plus. Les frais de
traitement de Stripe s'appliquent à chaque pourboire, et Stripe vous les facture
directement. Aujourd'hui, selon les [tarifs en euros de Stripe](https://stripe.com/ie/pricing),
une carte EEE standard coûte **1,5 % + 0,25 €**. Les cartes EEE premium : 1,9 % + 0,25 € ;
les cartes britanniques : 2,5 % + 0,25 € ; tout le reste : 3,25 % + 0,25 €, plus 2 % s'il
faut convertir une devise. (Aux États-Unis c'est 2,9 % + 0,30 $, ce qui est pire pour la
raison qui suit.)

Le problème n'est pas le pourcentage. Ce sont les vingt-cinq centimes.

| Pourboire | Stripe prend | L'artiste garde | Ponction réelle |
| --- | --- | --- | --- |
| 2 € | 0,28 € | 1,72 € | **14,0 %** |
| 5 € | 0,33 € | 4,67 € | 6,5 % |
| 10 € | 0,40 € | 9,60 € | 4,0 % |
| 20 € | 0,55 € | 19,45 € | 2,8 % |
| 50 € | 1,00 € | 49,00 € | 2,0 % |

Un frais fixe est un pourcentage déguisé, et sur les petites sommes le déguisement
tombe. Les mêmes 0,25 € invisibles sur un pourboire de 50 € dévorent un huitième d'un
pourboire de 2 €. Les pourboires sont petits par nature — c'est ce qui en fait des
pourboires — donc ce n'est pas un cas limite, c'est le cas médian.

D'où le `custom_unit_amount[minimum]`. Vers 2 €, la transaction cesse d'avoir un sens ;
un pourboire de 0,50 € par carte arriverait à 0,24 € et coûterait à Stripe plus cher à
déplacer qu'il ne vaut. Choisissez votre plancher délibérément, plutôt que de le
découvrir à votre premier virement.

Et voyez ce que cela fait à la comparaison de départ. Une plateforme qui prend 0 % en
plus de Stripe prend 0 % de **ceci**. Leur 0 % est réel — et c'est 0 % de ce que le
processeur a laissé. Le rail carte de personne n'est gratuit ; l'affirmation honnête est
« aucune commission au-delà de celle du processeur », et quiconque prétend davantage ment
ou n'utilise pas de cartes.

## Ce que vous avez maintenant, et ce qui manque

Trois appels d'API et un QR code, et une vraie cagnotte : hébergée, conforme PCI, Apple
Pay, Google Pay, des pourboires qui atterrissent sur votre propre solde Stripe selon
votre propre calendrier de virements, sans serveur sur le trajet. Pour beaucoup de gens,
c'est réellement la fin du projet, et vous pouvez tout à fait vous arrêter là et livrer.

Ce que vous n'avez pas, c'est une scène. Vous avez une page de paiement. Entre les deux
se tiennent les choses ennuyeuses : la boucle de sondage avec son curseur et son backoff,
un écran que le public peut voir avec l'objectif et le dernier message, un endroit pour
la clé qui ne s'appelle pas `localStorage`, un verrou pour qu'un inconnu ne tripote pas
la tablette entre deux sets, et la couche des mille petites décisions sur ce qui se passe
quand le wifi de la salle lâche en plein set.

C'est exactement ce qu'est [live.tips](https://github.com/mekedron/live.tips) : cette
architecture-là, finie, sous licence MIT. La clé restreinte avec ces cinq permissions, la
boucle à curseur sur `/v1/events`, la création Product/Price/Payment Link — le tout
tournant sur l'appareil de l'artiste, contre son propre compte. Aucun serveur live.tips
sur le chemin Stripe, aucun solde live.tips nulle part, ce que nous avons détaillé dans
[comment live.tips gère l'argent](https://live.tips/fr/blog/comment-live-tips-gere-argent/).

Lisez le code, prenez ce qui vous intéresse, ou utilisez-le simplement. Le but de cet
article est que l'architecture n'est ni un secret ni difficile : **Stripe hébergera votre
cagnotte gratuitement, et une clé restreinte plus une boucle de sondage sont tout ce qui
sépare un artiste de son propre argent.** Nous préférons que vous le sachiez plutôt que
vous vous inscriviez où que ce soit.
