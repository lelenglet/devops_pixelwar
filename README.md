# devops_pixelwar

## Dockerfile

Création des images :

docker build -t app-frontend:v1 . 

docker build -t app-backend:v1 .

Tailles des images obtenues :

Frontend : 92MB

Backend : 207MB

Les images sont relativement optimisées notamment grâce à un découpage des fichiers Dockerfile en plusieurs stages et un choix statégique dans l'ordre des commandes. 

## Kubernetes

Organisation en dossiers et séparation en fichiers.

Déploiement de tous les fichiers avec la commande :
```
kubectl apply -f infra/ --recursive
```