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

Exposer le back :

```bash
kubectl port-forward svc/pixelwar-back-service 3000:3000 -n pixelwar
```


## Terraform
```bash
cd terraform
terraform init
terraform plan
terraform apply
```
Si vous obtenez une erreur `Cannot create resource that already exists`, vous pouvez tout supprimer avec `kubectl delete namespace pixelwar`


Si vous avez ensuite l'erreur `kind create cluster --name pixel-war --config kind-config.yaml`, vous pouvez `cd ..; kind create cluster --name pixel-war --config kind-config.yaml`

## Tester l'infra

### Vérifier Terraform
```bash
terraform state list
terraform output
kubectl get all -n pixelwar
```

### Faire des requêtes

**Frontend** (nécessite un port-forward) :
```bash
kubectl port-forward svc/pixelwar-front-service 8080:80 -n pixelwar &
curl http://localhost:8080/
# Puis : kill %1  pour arrêter le port-forward
```

**Base de données** (vérification) :
```bash
kubectl exec -it postgresdb-0 -n pixelwar -- psql -U testUser -d testDB -c "SELECT 1;"
```

# Mémo
```bash
kind delete cluster --name pixel-war
kubectl get all -n pixelwar 
terraform state list
```

# Chart Helm

Deploiement des manifests avec une seule commande, avec création du namespace :
```
helm upgrade --install pixelwar ./pixelwar-chart \
  --namespace pixelwar \
  --create-namespace
```