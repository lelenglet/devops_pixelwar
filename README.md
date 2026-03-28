# devops_pixelwar
Ce projet a été réalisé par Chassefeyre Alexandre, Creton Evan, Lenglet Léa, Louis-Max Harter

Le déploiement par ArgoCD est notre méthode principale. Les autres méthodes sont décrites plus précisément dans la partie déploiement

## Déploiement par ArgoCD 

Comme argoCD se base uniquement sur la récupération de packages créés par la CI dans notre projet, nous n'utilisons plus le déploiement par Helm. Nous avons donc mis en place un script qui déploie le cluster kind et qui appelle ensuite le ansible pour le déployer via argoCD.
```bash
./argoDeploy.sh
```

La durée de la commande est de environ 8 minutes pour attendre la disponibilités des différents services sur le cluster.

Pour accéder au argoCD UI, le script va vous renvoyer les identifiants sous le forme 
```bash 
Login: admin 
Password: ...
```
Le bon fonctionnement du système nécessite la création d'un secret Github (Personal Access Token (Classic)) avec les accès `read:packages` et `repo` en ligne de commande :
```bash
 kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=$Github_username \
  --docker-password=$Github_PAT \
  --namespace=pixelwar
```

Enfin vous devez port-forward argoCD : 
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Pour accéder à notre application vous pouvez rentrer directement dans votre navigateur l'adresse :
[localhost](http://localhost:30201/)

Lorsque vous avez terminé vous pouvez exécuté `./stop.sh --cluster` pour supprimer tous les éléments précédemment initialisés.



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

Après avoir déployé la solution (sauf pour argoCD) il faut rediriger les ports avec :
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
