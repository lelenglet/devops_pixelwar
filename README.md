# devops_pixelwar

## Dockerfile

Création des images :
```bash
docker build -t app-frontend:v1 frontend/
docker build -t app-backend:v1 backend/
```

Tailles des images obtenues :
- Frontend : 92MB
- Backend : 207MB

Les images sont relativement optimisées notamment grâce à un découpage des fichiers Dockerfile en plusieurs stages et un choix statégique dans l'ordre des commandes.

## Kubernetes

Organisation en dossiers et séparation en fichiers :
- Dossier db
- Dossier frontend
- Dossier backend

Création du cluster avec kind :
```bash
kind create cluster --name pixel-war --config kind-config.yaml
```

Chargement des images :
```bash
kind load docker-image app-frontend:v1 --name pixel-war
kind load docker-image app-backend:v1 --name pixel-war
```

Deploiement des manifests (le namespace doit être déployé en premier car il est utilisé par les autres fichiers) :
```bash
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/db/
kubectl apply -f kubernetes/backend/
kubectl apply -f kubernetes/frontend/
```

Front accésible sur le [localhost:8080](http://localhost:8080/) avec la commande :
```bash
kubectl port-forward svc/pixelwar-front-service 8080:80 -n pixelwar
```

# Mémo
```bash
kind delete cluster --name pixel-war
kubectl get all -n pixelwar 
```