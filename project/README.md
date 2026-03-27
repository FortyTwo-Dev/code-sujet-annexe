Le README.md doit contenir :
explication de l’architecture
instructions pour lancer l’environnement de développement
instructions pour lancer l’environnement de production
description des services

# Architecture

## Environnement de Développement

`docker compose -f docker-compose.dev.yml up --build -d`

## Environnement de Production

`docker compose -f docker-compose.prod.yml up -d`

## Services

### Nginx
Nginx est un server web.

**Plus d\'information**

serveur web lancé en mode `daemon off;` (premier plan) pour rester
compatible avec la gestion des processus Docker cat sinon il est en arrière plan.

### Adminer
Adminer est une interface graphique pour les bases de données.

### PostgresSQL
PostgresSQL est un SGBD qui est utilisé des grandes quantitées de données, nous utilisons notre propre image en rajoutant le init.sql dans le dockerfile 

## Traefik
Traefik est un reverse proxy, qui permet de rediriger les requetes vers les bon services avec leur nom

### Frontend
Une image que nous avons build basé sur nginx qui contient le code source de la partie frontend ne notre application

### GO-API
Une image que nous avons build basé sur golang:version-alpine pour le devellopement et alpine pour la production.

## PHP-API
Une image que nous avons build basé sur php-cli pour le devellopement et la production?

