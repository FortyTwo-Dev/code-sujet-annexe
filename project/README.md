Le README.md doit contenir :
explication de l’architecture
instructions pour lancer l’environnement de développement
instructions pour lancer l’environnement de production
description des services

## nginx

serveur web lancé en mode `daemon off;` (premier plan) pour rester
compatible avec la gestion des processus Docker cat sinon il est en arrière plan.