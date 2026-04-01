#!/bin/bash

# Fonction pour attendre une touche
wait_for_key() {
    echo -e "\n\033[1;36mAppuie sur une touche pour passer à la slide suivante...\033[0m"
    read -n 1 -s
}

# Fonction pour afficher un titre de slide
title() {
    clear
    echo -e "\033[1;34m======================================================\033[0m"
    echo -e "\033[1;34m$1\033[0m"
    echo -e "\033[1;34m======================================================\033[0m"
}

# Slide 0 : Introduction
title "Présentation du projet : Plateforme de gestion de commandes restaurant"
echo -e "\033[1;33mContexte : Dockeriser une application multi-services pour un restaurant.\033[0m"
echo "Services : Frontend (HTML/JS), API PHP, API Go, PostgreSQL, Traefik (reverse proxy) et Adminer"
wait_for_key

# Slide 1 : Architecture de la partie Développement
title "1. Architecture de la partie développement"
echo -e "\033[1;35mSchéma : Frontend → API PHP, Frontend → API Go, API PHP/Go → PostgreSQL\033[0m"
echo "Reverse Proxy (Traefik) : route les requêtes vers les APIs."
echo ""
echo "Commande pour vérifier l'architecture réseau (si déjà lancé) :"
echo -e "\033[1;32mdocker network ls\033[0m"
docker network ls | grep "database-*"
wait_for_key

# Slide 2 : Dockerisation des services
title "2. Dockerisation des services"
echo -e "\033[1;35mChaque service a son Dockerfile : frontend/, api-php/, api-go/, postgres/\033[0m"
echo ""
echo -e "\033[1;32m API Go :\033[0m"
cat project/api-go/Dockerfile
wait_for_key
echo -e "\033[1;32m API PHP :\033[0m"
cat project/api-php/Dockerfile
wait_for_key
echo -e "\033[1;32m Frontend :\033[0m"
cat project/frontend/Dockerfile
wait_for_key
echo -e "\033[1;32m Postgres :\033[0m"
cat project/postgres/Dockerfile
wait_for_key

echo -e "\n\033[1;35mVérification des images générées :\033[0m"
echo -e "\033[1;32mdocker images\033[0m"
docker images | grep "IMAGE\|api-php\|api-go\|frontend\|postgres"
wait_for_key

# Slide 3 : Docker Compose (mode développement)
title "3. Docker Compose (mode développement)"
echo -e "\033[1;35mdocker-compose.dev.yml :\033[0m"
echo "Services : frontend, api-php, api-go, postgres, traefik"
echo "Volumes montés pour le développement."
echo ""
echo -e "\033[1;32mCommande pour lancer l'environnement dev :\033[0m"
echo "docker compose -f docker-compose.dev.yml up --build -d"
wait_for_key

# lancer les service -> docker compose -f docker-compose.dev.yml up --build -d

# Slide 4 : Vérification du mode développement
title "4. Vérification du mode développement"
echo -e "\033[1;35mServices en cours d'exécution :\033[0m"
echo -e "\033[1;32mdocker compose -f docker-compose.dev.yml ps\033[0m"

docker compose -f project/docker-compose.dev.yml ps
wait_for_key

echo -e "\n\033[1;35mAccès aux APIs (exemple) :\033[0m"
echo "- Frontend : http://localhost:80"
echo "- API PHP : http://localhost:8000"
echo "- API Go : http://localhost:8080"
echo "- Adminer : http://localhost:8888"
wait_for_key

# Slide 5 : Docker Compose (mode production)
title "5. Docker Compose (mode production)"
echo -e "\033[1;35mdocker-compose.prod.yml :\033[0m"
echo "Pas de volumes de code, images construites, sécurité renforcée."
echo ""
echo -e "\033[1;32mCommande pour lancer l'environnement prod :\033[0m"
echo "docker compose -f docker-compose.prod.yml up -d"
wait_for_key

# Slide 6 : Vérification du mode production
title "6. Vérification du mode production"
echo -e "\033[1;35mServices en cours d'exécution :\033[0m"
echo -e "\033[1;32mdocker compose -f docker-compose.prod.yml ps\033[0m"
docker compose -f project/docker-compose.prod.yml ps
#ctrl + C
docker compose -f project/reverse-proxy/docker-compose.yml ps
wait_for_key

# Slide 7 : Architecture réseau et Traefik
title "7. Architecture réseau et Reverse Proxy (Traefik)"
echo -e "\033[1;35mTraefik :\033[0m"
echo "Route les requêtes vers les APIs en fonction des règles définies."
echo ""
echo -e "\033[1;32mVoir la configuration Traefik (exemple) :\033[0m"
cat << 'EOF'
# Exemple de labels dans docker-compose.dev.yml pour Traefik
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.api-php.rule=Host(\`api-php.localhost\`)"
  - "traefik.http.routers.api-go.rule=Host(\`api-go.localhost\`)"
EOF
wait_for_key

echo -e "\n\033[1;35mAccès via Traefik :\033[0m"
echo "- Frontend : https://app.docker.localhost"
echo "- API PHP : https://php-api.docker.localhost"
echo "- API Go : https://go-api.docker.localhost"
echo "- Traefik Dashboard : https://dashboard.docker.localhost"
wait_for_key

# Slide 8 : Utilisation d'un registre d'images (Bonus)
title "8. Utilisation d'un registre d'images (Bonus)"
echo -e "\033[1;35mPousser les images sur Scaleway Container Registry :\033[0m"
echo -e "\033[1;32mExemple de commandes :\033[0m"
echo "docker tag api-php:latest registry.scaleway.com/ton-compte/api-php:v1"
echo "docker push registry.scaleway.com/ton-compte/api-php:v1"
wait_for_key

# Slide 9 : Critères d'évaluation
title "9. Critères d'évaluation"
echo -e "\033[1;35mPoints clés :\033[0m"
echo "- Dockerfiles fonctionnels"
echo "- Docker Compose dev et prod"
echo "- Architecture réseau correcte"
echo "- Schéma d'architecture produit"
echo "- Documentation (README.md)"
echo "- Bonus : Traefik, registre d'images, optimisations"
wait_for_key

# Slide 10 : Démo finale
title "10. Démo finale"
echo -e "\033[1;32mLancement de l'environnement :\033[0m"
echo "docker compose -f docker-compose.dev.yml up -d"
wait_for_key

echo -e "\n\033[1;35mVérification des services :\033[0m"
docker compose -f docker-compose.dev.yml ps
wait_for_key

echo -e "\n\033[1;35mAccès aux interfaces :\033[0m"
echo "- Frontend : http://frontend.localhost"
echo "- API PHP : http://api-php.localhost/products"
echo "- API Go : http://api-go.localhost/stats/overview"
echo "- Traefik Dashboard : http://traefik.localhost"
echo -e "\n\033[1;32mFélicitations ! Ta plateforme est prête ! 🎉\033[0m"
wait_for_key

echo -e "\n\033[1;36m=== Fin de la présentation ===\033[0m"

echo "arrêt des services..."
docker compose -f project/docker-compose.prod.yml down
docker compose -f project/reverse-proxy/docker-compose.yml down