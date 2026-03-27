# devops_pixelwar

## Initialisation

### Dockerfile

Création des images :

```bash
docker build -t app-frontend:v1 frontend/
docker build -t app-backend:v1 backend/
```

Tailles des images obtenues :

- Frontend : 92MB
- Backend : 207MB

Les images sont relativement optimisées notamment grâce à un découpage des fichiers Dockerfile en plusieurs stages et un choix stratégique dans l'ordre des commandes.

### Kubernetes

Organisation en dossiers et séparation en fichiers :

- Dossier db
- Dossier frontend
- Dossier backend

Création du cluster avec kind puis chargement des images

```bash
kind create cluster --name pixel-war --config kind-config.yaml
kind load docker-image app-frontend:v1 --name pixel-war
kind load docker-image app-backend:v1 --name pixel-war
```

## Déploiement :

Plusieurs manières de déployer la solution :

| Outil              | Rôle                                                                                                                             |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------- |
| Helm (à la racine) | Déploiement direct du chart sur un cluster déjà là et déjà ciblé par ton contexte kubectl.                                       |
| `./run.sh`         | Tout-en-un local : cluster kind + build images + chargement dans kind + Helm. Pratique pour dev.                                 |
| Terraform          | Infra déclarative : applique le chart (et ce que le code Terraform gère) ; utile si tu veux gérer le déploiement avec Terraform. |
| Ansible            | Automatisation / playbook : appelle Helm en CLI ; utile si ton flux passe par Ansible                                            |

Après avoir déployé la solution il faut rediriger les ports avec :

```bash
kubectl port-forward svc/pixelwar-front-service 8080:80 -n pixelwar
kubectl port-forward svc/pixelwar-back-service 3000:3000 -n pixelwar
```

Vous pouvez ensuite vous connecter sur [localhost:8080](http://localhost:8080/).

### Helm

```bash
helm upgrade --install pixelwar ./pixelwar-chart \
  --namespace pixelwar \
  --create-namespace \
  --kube-context kind-pixel-war
```

### `./run.sh`

Script idempotent pour lancer et stopper l'infra.

```bash
./run.sh
./run.sh --skip-build   # réutiliser les images déjà construites
./run.sh --forward      # port-forwards 8080 (front) et 3000 (back) en arrière-plan
```

### Terraform

Déploie le même chart qu'avec `helm`

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Si vous obtenez une erreur `Cannot create resource that already exists`, vous pouvez la supprimer pour la recréer depuis terraform avec `kubectl delete namespace pixelwar`

### Ansible

Déploie le même chart qu'avec `helm`

```bash
cd ansible
ansible-playbook playbooks/deploy.yml
```

Il faut attendre quelques secondes pour que les services se lancent et que le front puisse accéder à l'API.

### ArgoCD

Port-forward argoCD sur localhost

```
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Récupérer le mot de passe d'accès à argoCD pour id = admin

```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

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

Déploiement des manifests avec une seule commande, avec création du namespace :

```
helm upgrade --install pixelwar ./pixelwar-chart \
  --namespace pixelwar \
  --create-namespace
```
