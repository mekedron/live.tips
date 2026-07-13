# Un pourboire n'est pas un don — et Stripe en fait deux activités différentes

> Un musicien de rue qui réclame un « bouton de don » décrit une activité que Stripe interdit dans la plus grande partie de l'Europe. Un pourboire paie un service que tu as déjà rendu ; un don est une collecte de fonds à but caritatif. La différence décide de la catégorie dans laquelle atterrit ton compte — et un seul paramètre d'API peut choisir la mauvaise à ta place.

Canonical: https://live.tips/fr/blog/un-pourboire-nest-pas-un-don/
Published: 2026-07-11
Language: fr
Tags: Stripe, donations, busking, compliance, how-to

---

Chaque outil sur internet veut que tu appelles ça un don. Les boutons disent
*Donate*. Les articles de blog disent *bouton de don pour musiciens*. Les
annuaires de plugins disent *accepter les dons*. Si tu es musicien et que tu
cherches un moyen d'être payé par des gens qui n'ont pas de liquide, le mot te
suit partout.

Puis tu ouvres un compte Stripe, et Stripe te demande ce que fait ton activité. À
cet instant précis, le mot cesse d'être un argument marketing et devient une
**catégorie d'activité** — une catégorie que, dans la plus grande partie de
l'Europe, Stripe n'autorise pas.

Ce n'est pas du pédantisme, et ce n'est pas une subtilité d'avocat. C'est la
question la plus susceptible de faire examiner, retarder ou refuser le compte de
paiement d'un musicien de rue parfaitement ordinaire. Presque personne ne l'a
écrit clairement pour les artistes de scène, alors le voici.

## Deux mots, deux activités

Stripe trace la frontière lui-même, en une phrase chacune. Extrait de
[Conditions pour accepter des pourboires ou des dons](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations) :

> un pourboire doit être donné pour un bien ou un service qui a été fourni (par
> exemple, du contenu)

> un don doit être lié à un but caritatif précis que vous vous engagez à réaliser

Les pages de Stripe sont en anglais ; les citations sont traduites ici, et
l'original se trouve derrière le lien.

Relis ces deux phrases, parce que tout le reste de cet article en découle.

Un **pourboire** regarde en arrière, vers quelque chose qui a déjà eu lieu. Le
service a été rendu, le fan a aimé, le fan a payé en plus. L'argent est
inconditionnel et tu ne dois plus rien après. C'est la ligne « pourboire » sur
l'addition d'un restaurant, les pièces dans le chapeau, le billet de cinq glissé
dans une main après le dernier morceau.

Un **don** regarde en avant, vers quelque chose que tu as promis de faire. Il y a
une cause. Il y a un but que tu as décrit à la personne qui donne. Et — Stripe est
explicite là-dessus — l'argent doit réellement aller à ce but. Tu le détiens en
fiducie pour une chose que tu as dit que tu accomplirais.

Ce ne sont pas deux nuances du même geste. Ce sont deux relations différentes,
avec deux jeux d'obligations différents, et Stripe les assure comme deux activités
différentes.

## Un musicien de rue est carrément, sans ambiguïté, du côté du pourboire

Tu es resté deux heures sur une place et tu as joué. Quarante personnes se sont
arrêtées. L'une d'elles scanne ton code et t'envoie cinq euros.

**C'est un pourboire.** La prestation est le service. Il a été fourni — les gens
l'ont vu se produire. Il n'y a pas de cause, pas de bénéficiaire, pas de but que
tu t'es engagé à réaliser, et personne ne t'a confié de l'argent pour un projet.
Tu es un artiste interprète payé pour une prestation, ce qui est l'un des
arrangements commerciaux les plus anciens et les moins controversés qui soient.

La confusion vient du fait que le pourboire d'un musicien de rue est *volontaire*,
et qu'on nous a appris à croire que l'argent volontaire est de l'argent caritatif.
Il ne l'est pas. Un pourboire aussi est volontaire. Ce n'est pas le caractère
volontaire qui fait un don — c'est un **but caritatif**.

Alors quand ton panneau dit « dons bienvenus », tu n'es pas modeste ni poli. Tu
décris, dans le vocabulaire du processeur de paiement, une activité qui n'est pas
la tienne.

## Ce que ce mot te coûte vraiment

C'est ici que l'abstraction se transforme en argent.

Stripe publie une
[liste des activités restreintes](https://stripe.com/legal/restricted-businesses)
— les choses que tu n'as pas le droit de faire avec un compte Stripe, ou que tu ne
peux faire que dans certains pays. Sous la rubrique **Financement participatif et
collecte de fonds** figure cette ligne, mot pour mot :

> Organisations collectant des fonds à but caritatif (remarque : pris en charge en
> Australie, au Canada, au Royaume-Uni et aux États-Unis. Interdit dans tous les
> autres pays.)

Lis la parenthèse lentement. La collecte de fonds à but caritatif est une
**activité prise en charge dans quatre pays** — l'Australie, le Canada, le
Royaume-Uni, les États-Unis — et **interdite partout ailleurs.**

Et ici, la géographie francophone se coupe en deux, alors autant le dire
franchement. Si tu joues à Montréal ou à Québec, tu es dans l'un des quatre pays
pris en charge : la catégorie existe, elle est simplement examinée de très près, et
elle n'est de toute façon pas ce que fait un musicien de rue. Si tu joues à Paris,
à Lyon, à Bruxelles ou à Genève, tu es dans « tous les autres pays », et la
collecte de fonds à but caritatif y est purement et simplement interdite. La France,
la Belgique et la Suisse ne sont pas sur la liste des quatre. La plupart des
musiciens de rue du monde vivent dans « tous les autres pays ».

La même page classe aussi comme restreinte la *« collecte de fonds menée par des
organisations à but non lucratif, des associations caritatives, des organisations
politiques et des entreprises offrant une contrepartie en échange d'un don »*, et
la page de Stripe sur les pourboires et les dons ajoute par-dessus une série de
règles propres à chaque pays : au Japon, les particuliers ne peuvent pas recevoir
de dons du tout ; à Singapour, seules les organisations caritatives ou religieuses
enregistrées auprès de l'État le peuvent ; en Inde, à Hong Kong et en Thaïlande,
les dons ne sont pas pris en charge.

Ainsi, un musicien à Paris qui tape « dons pour ma musique » dans le formulaire
d'inscription de Stripe vient de décrire une activité que Stripe interdit en
France. Non pas parce que jouer dans la rue serait interdit — jouer dans la rue va
parfaitement bien — mais parce que les mots qu'il a choisis appartiennent à une
catégorie qui l'est.

## Maintenant le calibrage, parce que ce n'est pas une histoire d'horreur

**Les musiciens de rue ne sont pas une activité restreinte.** Le pourboire n'est
pas une activité restreinte. La prestation live n'est pas sur la liste, ne t'y
mettra pas, et c'est à peu près la chose la plus ordinaire qu'on puisse faire avec
un compte de paiement. Si tu te décris avec exactitude, rien de tout ceci ne te
touche et la configuration est ennuyeuse, ce qui est exactement ce qu'il faut.

Le risque, ici, ce n'est pas Stripe. Le risque, c'est **l'auto-classement erroné**
— entrer dans la pièce en te présentant comme un collecteur de fonds caritatif
alors que tu es guitariste. Stripe n'a aucun moyen de savoir que tu voulais dire
« laisse-moi un pourboire ». Il n'a que le formulaire que tu as rempli, la
description d'activité que tu as écrite, et les mots inscrits sur la page vers
laquelle pointe ton QR code.

Personne chez Stripe ne fait la chasse aux musiciens de rue. Ils lisent simplement
ce que tu leur as dit.

## Le piège tient dans un seul paramètre

Voici la partie que presque personne n'écrit, et c'est la chose la plus utile de
cet article.

Les Payment Links de Stripe ont un paramètre appelé `submit_type`. La
[référence de l'API](https://docs.stripe.com/api/payment-link/object) le décrit
comme quelque chose de presque cosmétique :

> Indique le type de transaction effectuée, ce qui personnalise le texte
> correspondant sur la page, comme le bouton d'envoi.

*Personnalise le texte correspondant.* Tu en conclurais raisonnablement que cela
change une étiquette de bouton, et qu'une cagnotte à pourboires devrait évidemment
dire 'Donate' (donner) plutôt que 'Buy' (acheter), parce que *Buy* est un mot
étrange à imprimer sous le chapeau d'un musicien de rue.

Puis tu lis ce que font réellement les valeurs :

> `donate` — Recommandé pour accepter des dons. Le bouton d'envoi porte l'étiquette
> 'Donate' et les URL utilisent le nom d'hôte `donate.stripe.com`

> `pay` — Le bouton d'envoi porte l'étiquette 'Buy' et les URL utilisent le nom
> d'hôte `buy.stripe.com`

**Ce n'est pas une étiquette. C'est un nom d'hôte.** Mets `submit_type=donate`, et
le lien que Stripe te donne — celui que tu transformes en QR code, que tu imprimes
et que tu scotches sur ton étui de guitare — vit sur `donate.stripe.com`. Chaque
fan qui le scanne voit une page de don. Chaque paiement dans ton tableau de bord
est passé par un parcours de don. Le QR code sur ton étui est en train de dire à
Stripe, de dire à ton public et, à la longue, de te dire à toi que tu collectes des
dons.

Tu n'as écrit le mot « don » nulle part. Un seul paramètre d'API l'a écrit pour toi,
et l'a imprimé sur un panneau en plastique posé sur une place publique.

C'est un piège dans lequel il est facile de tomber, et ce n'est pas la faute du
lecteur quand il y tombe : le paramètre est documenté comme un changement de texte,
*Donate* est manifestement le mot le plus joli à imprimer sous le chapeau d'un
musicien de rue, et la conséquence — une classification d'activité — se trouve deux
phrases plus bas que là où s'arrêtent la plupart des gens.

live.tips envoie `submit_type=pay`. Le lien de chaque artiste est un lien
`buy.stripe.com`, et le code porte un commentaire qui explique pourquoi, parce que
c'est typiquement le genre de chose qu'un futur contributeur « améliorerait » sans
cela.

## Ce qu'un musicien devrait faire concrètement

Rien de tout cela ne demande un avocat. Cela demande cinq minutes et quelques mots
simples.

- **Décris l'activité réelle** dans l'inscription Stripe. « Prestation de musique
  live. » « Musicien de rue. » « Musicienne — pourboires du public lors de
  prestations live. » Dis que tu joues, et que les paiements sont des pourboires
  pour ces prestations.
- **Choisis une catégorie qui correspond.** Divertissement live, arts du spectacle,
  musicien. Pas association caritative, pas organisme à but non lucratif, pas
  collecte de fonds.
- **Utilise `submit_type=pay`** si tu construis toi-même le Payment Link. Si un
  outil l'a construit pour toi, regarde l'URL qu'il a produite : `buy.stripe.com`
  est une cagnotte à pourboires, `donate.stripe.com` est une page de don. C'est une
  vérification de deux secondes, et elle te dit ce que ton outil croit que tu es.
- **Ne l'appelle pas un don** — ni sur le panneau, ni sur ton site, ni dans la
  description d'activité chez Stripe. « Pourboires », « cagnotte à pourboires »,
  « soutiens le groupe », « offre-nous un verre » décrivent tous ce qui se passe
  réellement. « Faire un don » décrit autre chose.
- **Garde une vraie collecte de fonds à part.** Si tu joues un concert de soutien et
  que l'argent va à une cause, c'est authentiquement une *collecte de fonds à but
  caritatif*, et les règles ci-dessus te concernent désormais — liste des pays
  comprise. Fais-le sur le bon compte, dans le bon pays, après avoir lu les
  conditions de Stripe, et jamais via la cagnotte à pourboires que tu utilises les
  soirs ordinaires.

Ce dernier point mérite qu'on insiste, parce que c'est la moitié honnête de
l'argument. Nous ne disons pas que les dons sont mauvais, ni qu'un musicien ne peut
jamais lever de l'argent pour une cause. Nous disons que c'est une **activité
différente**, avec des règles différentes, et que la faire passer discrètement par
le même QR code est le meilleur moyen de te mettre en difficulté sur les deux.

Une autre ligne de la page de Stripe sur les pourboires et les dons vaut d'être
connue, car elle exclut une troisième chose que les gens confondent avec les deux
autres : Stripe ne fait pas de *« traitement de paiement pour la transmission
d'argent personnelle ou de pair à pair (par exemple, envoyer de l'argent entre
amis) »*. Un pourboire n'est pas non plus un cadeau entre amis. Si tu veux ce canal
— un fan qui t'envoie simplement de l'argent, de personne à personne — c'est
exactement ce que sont Revolut et MobilePay, et c'est pourquoi ils vivent
[entièrement en dehors de Stripe](https://live.tips/fr/blog/un-qr-code-tous-moyens-paiement/) dans notre
app.

## Ce que cet article n'est pas

Ce n'est pas un conseil juridique. Ce n'est pas un conseil fiscal — la façon dont
les pourboires sont imposés varie énormément d'un pays à l'autre, parfois d'une
ville à l'autre, et c'est complètement hors sujet ici ; demande à quelqu'un de
qualifié là où tu vis.

Et ce n'est pas une promesse sur ton compte. **Que Stripe t'accepte ou non est la
décision de Stripe seul.** live.tips n'a aucune relation avec Stripe, aucune
capacité d'influencer un examen, et aucun moyen d'en faire appel à ta place. Ce que
notre logiciel peut faire, c'est éviter de te mettre des mots dans la bouche. Ce que
tu écris sur le formulaire, c'est toujours à toi de l'écrire.

Les règles changent aussi. Les lignes citées ici figuraient sur les pages de Stripe
en juillet 2026, et les liens sont juste là ; va les lire toi-même plutôt que de
faire confiance à un article de blog, celui-ci compris.

## La version courte

Tu as joué le set. Ils l'ont regardé. Ils t'ont payé pour ça.

C'est un pourboire. Dis-le — sur le panneau, dans le formulaire, dans l'URL — et le
résultat ennuyeux que tu veux est celui que tu obtiens. Nous construisons la
cagnotte autour de cette affirmation exacte, jusqu'au
[nom d'hôte Stripe vers lequel pointe ton QR code](https://live.tips/fr/blog/construire-une-cagnotte-sur-votre-propre-compte-stripe/),
et si tu veux le tableau plus large de l'endroit où va réellement l'argent, c'est
[ici](https://live.tips/fr/blog/comment-live-tips-gere-argent/).
