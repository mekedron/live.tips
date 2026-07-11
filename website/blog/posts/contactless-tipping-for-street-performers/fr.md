---
title: Le pourboire sans contact pour musiciens de rue, en toute honnêteté
description: Le Tap to Pay sur un téléphone, un lecteur de carte, un sticker NFC, un QR code — quatre choses différentes qu'on appelle toutes « sans contact ». Ce que chacune coûte vraiment en 2026, ce qu'un tag NFC fait réellement (ce n'est pas ce que tu crois), et quand un tap bat un scan.
slug: pourboire-sans-contact-pour-musiciens-de-rue
---

Cherche « pourboire sans contact pour musicien de rue » et internet te renvoie en
2018. Un prototype d'étudiants de la Brunel University appelé Tiptap — un support
dans lequel on glisse un téléphone — a eu droit à sa tournée de presse cette
année-là, et cette presse trône toujours en première page. C'était une jolie idée.
C'était aussi, selon les mots des articles eux-mêmes, *encore au stade du
développement*, et il était prévu de facturer aux musiciens de rue des frais
uniques plus **5 % de chaque pourboire**. Ça n'est jamais devenu quelque chose
qu'on peut acheter.

(Le « tiptap » que tu trouveras si tu cherches aujourd'hui est une entreprise
ontarienne sans aucun rapport, qui vend des terminaux de don sans contact à des
associations. Même mot, autre produit, pas pour toi.)

L'état honnête de la question n'a donc pas été écrit depuis huit ans. Le voici.

Ceci est le plongeon en profondeur dans le tap. Si ta vraie question est la plus
large — toutes les façons d'être payé maintenant que personne n'a de liquide, et ce
que chacune coûte —, commence par [comment les musiciens de rue encaissent la
carte](post:how-buskers-take-card-payments), puis reviens ici.

## Quatre choses différentes s'appellent toutes « sans contact »

C'est là que vit l'essentiel de la confusion, alors séparons-les avant de chiffrer
quoi que ce soit.

1. **Le Tap to Pay sur ton propre téléphone.** Ton téléphone devient le terminal.
   Le fan approche sa carte ou sa montre de *ton* appareil. Zéro matériel
   supplémentaire.
2. **Un lecteur de carte** — un SumUp, un Zettle, un Square. Un petit terminal en
   plastique que tu tends. Le fan le touche.
3. **Un tag NFC** — le sticker ou la plaque « touchez ici pour donner ». Celui-là
   est presque universellement mal compris, et la section suivante explique
   pourquoi.
4. **Un QR code.** Pas sans contact au sens NFC — mais lis la suite, car du côté du
   fan, il finit très souvent par exactement le même tap.

Seuls les deux premiers sont des *terminaux de paiement*. Toute la question est là.

## Le tag NFC n'encaisse pas de paiement

Réglons ça proprement, parce que les vendeurs sont ravis de te laisser croire le
contraire.

Un sticker NFC — le modèle bon marché, la puce NTAG213 que la plupart utilisent —
a **144 octets de mémoire**. Pas 144 kilo-octets. Il ne peut pas exécuter de code,
il n'a pas de batterie, il n'a jamais entendu parler d'un réseau de cartes, et il
ne pourrait pas contenir un protocole de paiement même s'il le voulait. Ce qu'il
contient, c'est une courte chaîne de caractères, au format NDEF, et cette chaîne
est très majoritairement une **URL**.

On le touche, et le téléphone ouvre une page web. C'est toute la fonctionnalité.

Ce qui veut dire qu'une plaque « tap to tip » est un QR code qu'on ouvre en le
touchant au lieu de le viser. Même destination, même page web, même paiement qui
se joue dans le navigateur. Même les spécialistes le disent, si on les lit de
près : le site de tiptap décrit son appareil à montant libre comme celui où
*« lorsque les donateurs approchent leur téléphone d'un appareil de don
personnalisé, ils sont dirigés vers votre page de collecte en ligne. »* Dirigés
vers une page. Parce que c'est ce que sait faire un tag.

C'est réellement utile, et c'est bon marché — les stickers NTAG213 vierges partent
autour de **0,24 $ pièce** en lot. Si tu as déjà une page de pourboire, coller un
tag sur ton étui à côté du code imprimé te coûte trois fois rien et donne à
certains fans une entrée plus rapide.

Mais sois clair sur ce que tu as acheté : **une deuxième porte d'entrée vers la
même page.** Pas une machine à cartes.

### Et dehors, c'est une porte capricieuse

Les cas d'échec sont réels, et aucun vendeur de tags ne les liste :

- **Le téléphone du fan doit être déverrouillé et en cours d'utilisation.** La
  documentation d'Apple est explicite : la lecture de tag en arrière-plan n'a lieu
  que pendant que l'iPhone est utilisé, et si le téléphone est verrouillé, le
  système lui demande d'abord de le déverrouiller.
- **Ça ne marche pas quand l'appareil photo est ouvert.** Apple cite l'appareil
  photo en cours d'utilisation parmi les états où la lecture de tag en
  arrière-plan est indisponible. Savoure l'ironie : un fan qui dégaine son appareil
  photo pour scanner ton QR code vient de désactiver ton tag NFC.
- **Il faut un iPhone XS ou plus récent**, et sur Android il faut que le NFC soit
  activé — ce que certains modes d'économie d'énergie désactivent.
- **La portée est d'environ 4 cm.** Le fan doit vraiment toucher la chose. Dans une
  foule, penché sur un étui de guitare, c'est beaucoup demander.
- **Le métal et les aimants le tuent.** Un tag scotché sur un ampli, ou un fan avec
  une coque magnétique, et il ne se passe strictement rien.

Un tag est une bonne deuxième option. C'est une mauvaise seule option.

## Le Tap to Pay sur ton téléphone : la vraie nouvelle de 2026

Voici ce qui a changé depuis les articles sur Tiptap, et dont aucune de ces
couvertures périmées n'a connaissance.

**Le Tap to Pay sur iPhone** transforme le téléphone déjà dans ta poche en terminal
sans contact. Pas de dongle, pas de lecteur, pas de support. Apple l'annonce
disponible dans **plus de 70 pays et régions**, et les prestataires par lesquels tu
peux y accéder en Europe ressemblent à toute l'industrie — rien qu'en Allemagne :
Adyen, Mollie, myPOS, Nexi, PAYONE, Rapyd, Revolut, Sparkassen, Stripe, SumUp,
Viva.com. Le Royaume-Uni, la France, les Pays-Bas, la Suède, la Finlande et le
Danemark ont des listes similaires. Il te faut un iPhone XS ou plus récent.

**Le Tap to Pay sur Android** existe aussi, mais plus étroit. Via Stripe, il est
disponible en général en AT, AU, BE, CA, CH, DE, DK, FI, FR, GB, IE, IT, MY, NL,
NZ, PL, SE, SG et US, avec dix-huit pays de plus en aperçu public. Ton téléphone a
besoin d'Android 13 ou plus récent, d'un capteur NFC, d'un bootloader non rooté, de
Google Mobile Services, et des options de développeur désactivées — ce dernier
point piège plus de monde qu'on ne croit.

En pratique : **SumUp affiche le Tap to Pay à 0 £ de matériel.** Si tu as un iPhone
récent et que tu es dans un pays pris en charge, le coût d'entrée pour tendre un
terminal sans contact est désormais nul. Ce seul fait rend obsolète chaque article
« achète ce support » de 2018.

## Les lecteurs de carte, et ce qu'ils coûtent vraiment

Si tu veux un bout de plastique à part — et il y a de bonnes raisons pour ça,
plus bas — le marché tient en trois produits.

| | Matériel | Frais par paiement en personne |
| --- | --- | --- |
| **SumUp** (UK) | Tap to Pay 0 £ · Solo Lite 25 £ · Solo 79 £ · Terminal 135 £ | **1,69 %**, sans frais fixes |
| **SumUp** (Allemagne) | — | **1,39 %**, sans frais fixes |
| **Zettle / PayPal POS** (UK) | Lecteur à partir de 29 £ pour une première commande, 69 £ ensuite | **1,75 %**, sans frais fixes |
| **Square** (UK) | Lecteur sans contact + puce 19 £ | **1,75 %**, sans frais fixes |
| **Square** (US) | Lecteur sans contact + puce 59 $ | **2,6 % + 0,15 $** |

Prix hors TVA, tels que publiés en juillet 2026. Va les vérifier ; ils bougent.

Maintenant relis ce tableau, parce qu'il dit quelque chose qui contredit ce qu'on
t'a probablement raconté.

## Le calcul des frais, et ce que tout le monde prend à l'envers

La sagesse reçue veut que les frais de carte détruisent les petits pourboires à
cause des frais fixes par transaction — les vingt-cinq centimes qui avalent un
huitième d'un pourboire de 2 €. C'est vrai, et nous avons
[écrit le calcul nous-mêmes](post:build-a-tip-jar-on-your-own-stripe).

Mais c'est vrai des paiements par carte *en ligne*. **Les lecteurs sans contact
européens n'ont le plus souvent aucun frais fixe.** SumUp, Zettle et Square au
Royaume-Uni et dans l'UE facturent uniquement au pourcentage. Ce qui donne :

| Un pourboire de 2 € | Frais | Il reste à l'artiste | Prélèvement réel |
| --- | --- | --- | --- |
| Lecteur SumUp (DE, 1,39 %) | 0,03 € | 1,97 € | **1,4 %** |
| Zettle / Square (UK, 1,75 %) | 0,04 € | 1,96 € | 1,8 % |
| Stripe, carte en ligne (EEE, 1,5 % + 0,25 €) | 0,28 € | 1,72 € | **14,0 %** |
| Lecteur Square (US, 2,6 % + 0,15 $) | 0,20 $ | 1,80 $ | **10,1 %** |

Sur les seuls frais, un terminal sans contact européen bat un paiement par carte en
ligne sur un petit pourboire, et de loin. Nous sommes un produit à QR code et nous
te le disons quand même : sur un pourboire de 2 €, un lecteur SumUp te garde
0,25 € qu'une page hébergée par Stripe ne te laisse pas.

Deux choses remettent cela en proportion.

**Le matériel, c'est les frais fixes, déplacés.** Une économie de 0,25 € par
pourboire face à un Solo à 79 £, cela fait environ **trois cents taps avant que le
lecteur se soit remboursé**. C'est un chiffre réel pour un musicien de rue qui
travaille, et un chiffre absurde pour quelqu'un qui joue deux fois par été. (Et le
Tap to Pay à 0 £ de SumUp ramène ça à zéro tap — ce qui est précisément pourquoi
cette option compte plus que les lecteurs.)

**Et les États-Unis renversent la vapeur.** Le tarif américain en personne de Square
porte 0,15 $ de frais fixes, donc un tap de 2 $ perd lui aussi un dixième de
lui-même au terminal. Le cadeau « pas de frais fixes » est européen.

Il y a aussi un plancher que tu rencontreras : SumUp n'accepte pas de paiement en
dessous de **1 £ / 1 €**. Quelle que soit la voie choisie, le tout petit pourboire
n'est pas vraiment une transaction par carte.

## Alors, quand un tap bat-il un scan ?

Enlève la technologie, et c'est une question sur les mains du fan.

**Un tap exige que le téléphone du fan soit déverrouillé et dans sa main, et que toi
tu tendes quelque chose.** Quand les deux sont vrais, c'est la chose la plus rapide
du paiement. Pas d'appli, pas de visée, pas de saisie, réglé en une seconde.

**Un scan exige que le fan ouvre un appareil photo** — un geste délibéré de plus —
mais il n'exige absolument rien de toi. Le code reste sur l'étui. Il marche pour un
fan resté au fond. Il marche pour quarante personnes à la fois. Il marche pendant
que tu joues encore.

D'où un partage honnête :

- **Le tap gagne quand tu peux aller vers les gens.** Fin du set, chapeau qui
  tourne, un fan à la fois, toi libre de tenir un terminal. Un tap est une demande
  moins coûteuse que « sors ton appareil photo », et à cet instant tu es
  physiquement là pour conclure.
- **Le scan gagne quand tu ne peux pas.** En plein morceau. Une foule sur trois
  rangs. Un emplacement où tu ne peux pas quitter l'ampli. Tous ceux qui veulent
  donner en passant. Un terminal sert exactement une personne ; un code imprimé sert
  toute la place, simultanément, et n'a pas besoin que tu t'arrêtes de jouer pour le
  servir.

Ce dernier point est celui que les vendeurs de terminaux ne font jamais, et c'est
le plus gros. **Un lecteur de carte est un goulot d'étranglement avec une file
d'attente.** Un QR code n'a pas de file d'attente.

Et voici ce qui dissout la moitié du débat : sur une page de pourboire bien faite,
**le scan finit de toute façon en tap**. Le fan scanne, la page s'ouvre, et son
téléphone lui propose Apple Pay ou Google Pay. Double-clic, il approche le téléphone
de son visage, c'est fait. De son point de vue, c'est un paiement sans contact —
même wallet, même carte, mêmes deux secondes — et tu n'as acheté aucun matériel pour
que ça arrive.

## Où se situe live.tips, et quand acheter un SumUp à la place

[live.tips](https://github.com/mekedron/live.tips) est une cagnotte à pourboires
fondée sur un QR code. Un code, qui ne change jamais, qui pointe droit sur le
propre lien de paiement Stripe de l'artiste. Il n'y a pas de solde live.tips, pas
de commission, et pas de plateforme sur le chemin — les frais sont ceux de Stripe,
et Stripe les facture directement à l'artiste. C'est sous licence MIT, et la
tablette sur scène affiche chaque pourboire au moment où il arrive. Nous avons
détaillé le parcours de l'argent dans
[comment live.tips gère l'argent](post:how-live-tips-handles-money), et pourquoi
c'est [un seul code plutôt qu'un par prestataire](post:one-qr-code-every-payment-method).

Cette page prend en charge Apple Pay et Google Pay. Donc live.tips *est* sans
contact du côté du fan — le tap qui compte, celui de la fin, sans terminal à
acheter, à charger ou à faire tomber sous la pluie. Ce n'est simplement pas un
terminal.

**Si ce que tu veux, c'est tendre physiquement un objet et qu'un inconnu le touche,
achète un lecteur de carte.** Prends le Tap to Pay de SumUp si ton téléphone et ton
pays le permettent, parce qu'il ne coûte rien ; prends un Solo si tu préfères ne
pas tendre ton propre téléphone à une foule. Dans les deux cas, sur un tap de 2 € en
Europe, il battra nos frais, et nous préférons le dire que faire semblant du
contraire.

Tu peux aussi faire les deux, et beaucoup de musiciens de rue le devraient : le code
scotché sur l'étui toute la soirée, qui attrape les passants pendant que tu joues,
et le terminal dans ta main pour les dix secondes après le dernier accord, quand le
premier rang plonge la main dans sa poche. Ils ne se concurrencent pas. Ils
attrapent des gens différents.

Ce qu'aucun des deux n'est : un support de 2018 qui prend 5 %.

Frais, prix du matériel et disponibilité par pays tels que publiés par Apple, Stripe, SumUp, Zettle/PayPal et Square en juillet 2026, hors TVA. Prix des stickers NFC d'après GoToTags. Les conditions de Tiptap en 2018 telles que rapportées par la Brunel University et Finextra. Tout cela change ; vérifie-le auprès du vendeur avant de dépenser de l'argent.
{: .footnote }
