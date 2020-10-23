# Introduction
Ce projet permet de rendre public le processus de développement de
l’application TousAntiCovid. Il est par ailleurs ouvert à toute
contribution pertinente visant à l’améliorer (débug, ajout de
fonctionnalités, …). Dans ce contexte l'ensemble des composants de
l'application seront rendus public pour répondre à l'impératif de
transparence et d'auditabilité tel que recommandé par la CNIL. Par
ailleurs une partie du code, a minima celle qui met en œuvre le
protocole ROBERT, sera mise à disposition sous licence open source et
le dépôt de code sera rendu public et ouvert à contribution.

Étant donnée l’urgence sanitaire et les contraintes projets, ce
mécanisme de publication et d’ouverture large à contribution se met en
place progressivement. 
* Jusqu'à la publication effective de l'application et les quelques
  jours nécessaires à la stabiliser, tout un chacun pourra consulter
  le code de l'application. Durant cette phase, les développeurs
  actuels pourront inviter des personnes ayant fait des critiques
  constructives à contribuer directement au projet. La planification
  initiale prévoit que cette phase pourrait durer jusqu'au 15 juin.
* Dans un second temps, une procédure explicite sera mise en place
  pour permettre à tout contributeur d'accéder à l'outil de
  collaboration pour ouvrir des _issues_ et proposer des _merge
  request_ pour les sous-projets qui exposent leur dépôt de code.

Les audits de code pour les différentes contributions, notamment pour
les aspects sécurité, sont prévus de façon itérative de manière à
fluidifier au maximum l’intégration de ces contributions. Les
recommendations initiales de l'ANSSI peuvent être consultés dans
[le pdf visible dans le dépôt](documentation/Stopcovid%20-%20Recommandation%20ANSSI.pdf), et celles qui sont toujours valides ou qui ont été ajoutées depuis sont suivies dans le système de
suivi de chaque sous-projet sous forme d'_issues_.

# Description des sous-projets et de la façon dont ils interagissent
Une description textuelle suit cette présentation des sous-projets
sous forme de schéma résumé. Elle permet de faire le lien entre les
sous-projets publiés sous gitlab et les composants de TousAntiCovid.
![alt text](../documentation/composants.png "Liens entre les composants de TousAntiCovid et
les sous-projets sous gitlab")
* ROBERT API Specs : définition des SPEC de l’API ROBERT entre
  l’application mobile et le backend. Définit les services :
  * register (l’application s’enregistre, échange et partage ses
    clefs, récupère ses premiers EBIDs),
  * status (l’application récupère son statut et un lot de EBIDs),
  * report (l’application uplaod son historique de proximité), 
  * unregister (l’application se désenregistre et efface toutes ses
    données sur le serveur).
* ROBERT-server : code serveur du protocole ROBERT. Intègre le code pour l’API
  et les composants de gestion des clefs, de crypto, du service de
  transaction, plateforme de donnée et fonction de de calcul de
  risque.
* Submission Code Server Client API spec : définition des SPEC de
  l’API côté serveur sous swagger pour le server de code/token. Permet d’émettre un
  code/token à destination d’un tiers médical. Permet de tester/brûler
  un token depuis le backend TousAntiCovid.
* Submission-code-server : code de la l’API pour le serveur de code/token. 
* stopcovid-robertsdk-android : code pour le protocole ROBERT sur l’App
  mobile Android. Intègre les composants de gestion de clefs, gestion des
  données, mode bg, composant crypto et l’API de connexion avec le
  backend.
* stopcovid-robertsdk-ios : code pour le protocole ROBERT sur l’App
  mobile iOS. Intègre les composants de gestion de clefs, gestion des
  données, mode bg, composant crypto et l’API de connexion avec le
  backend.
* stopcovid-BLEsdk-android : code pour les échanges de paquet et
  calibration des contacts à partir de BLE sur Android.
* stopcovid-BLEsdk-ios : code pour les échanges de paquet et
  calibration des contacts à partir de BLE sur iOS.
* stopcovid-strings : labels des écrans, pour chaque langage (fr, en,
  es, pt, it, ar).
* stopcovid-android : UX/UI, front end de l’application Android. 
* stopcovid-ios : UX/UI, front end de l’application iOS.

# Gouvernance et processus de décision
La gouvernance est structurée comme suit :
* Un _core group_ du projet TousAntiCovid, réunissant les entités qui
  contribuent au projet ; Ce groupe délègue la maintenance du projet
  au quotidien au _comité des mainteneurs_ ;
* Une cellule sécurité, composée de membres de l’ANSSI, de
  prestataires PASSI - qualifiés pour l'audit de sécurité par l’ANSSI - et d’autres
  auditeurs sécurité privés
* Une cellule juridique et Propriété Intellectuelle ;
* Par sous-projets, des _mainteneurs_ du sous-projet dont au moins un
  est dans le _comité des mainteneurs_.

Les propositions de contribution seront systématiquement soumises à
audit afin d’obtenir les avis suivants (non bloquants) :
* Un avis technique ;
* Un avis PI et juridique ;
* Un avis sécurité.

Le _comité des mainteneurs_ se réunira de façon régulière pour décider
du traitement à apporter à chaque demande de contribution de façon à
assurer la vivacité du processus de développement open source. Il aura
de facto vocation à catégoriser chaque demande de contribution
(e.g. fonctionnalité, bug fix, ergonomie, …). Pour cela, le _comité
des mainteneurs_ pourra se faire assister par des développeurs et/ou
par un outil dédié.

La composition initiale de ce _comité des mainteneurs_ est constitué
des responsables techniques des structures qui ont assumées le
développement intial (cf [AUTHORS.md](AUTHORS.md)). Il évoluera après
la publication selon les choix pour la maintenance fait par la
gouvernance du projet (le _core group_).

# Gestion des contributions
Les personnes qui contribueront au code devront s'engager à le céder
au mainteneur du sous-projet auquel elles auront contribué. Il sera diffusé
avec la licence de ce dernier. Il le font via un mécanisme concret qui
n'a pas été figé à ce jour. Le principe est d'utiliser un DCO
(Developer Certificate of Origin)
