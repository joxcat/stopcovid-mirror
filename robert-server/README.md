# Introduction
Ce projet gitlab.inria.fr est un des composants de la solution plus globale [StopCovid](https://gitlab.inria.fr/stopcovid19/accueil/-/blob/master/README.md).

Ce composant propose les services suivants :
* Service Register : permet l’inscription à la solution StopCovid et la récupération d’identifiants anonymisés
* Service Report : permet la remontée de contacts suite à une déclaration volontaire de test positif au Covid-19 et l'analyse de leurs risques d'exposition
* Service Status : permet la vérification par une app donnée de son risque d’exposition au Covid-19 
* Service Unregister : permet la désinscription à la solution StopCovid

Le composant implémente également une fédération des initiatives nationales utilisant le même protocole afin de protéger les utilisateurs se déplaçant à l'étranger.
