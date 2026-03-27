# Terraform

Le déploiement utilise le **provider Helm** et le chart local `../pixelwar-chart`, comme `run.sh` (`helm upgrade --install`). Il n’y a plus de manifests YAML sous `kubernetes/` : une seule source, le chart Helm.

## Prérequis

- Cluster Kubernetes joignable (ex. `kind create cluster --name pixel-war --config ../kind-config.yaml` à la racine du dépôt).
- Images Docker chargées dans kind si vous utilisez des tags locaux (`kind load docker-image …`), comme pour `run.sh`.
- `kubectl` / `helm` disponibles ; le contexte par défaut attendu est `kind-pixel-war` (voir `variables.tf`).

## Prise en main

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Variables utiles (fichier optionnel `terraform.tfvars`) :

- `kube_config_path`, `kube_config_context` — accès au cluster.
- `helm_release_name`, `helm_namespace` — alignés sur `run.sh` (`pixelwar` / `pixelwar`).
- `helm_timeout_seconds` — timeout d’attente Helm (défaut `900`, soit 15 minutes).

## Vérifier que tout va bien

```bash
terraform plan
# Attendu : "No changes" une fois l’état à jour.

terraform state list
# Attendu : helm_release.pixelwar

terraform output
kubectl config get-contexts
```

En cas d’erreur « context does not exist », ajuster `kube_config_context` dans `terraform.tfvars` après `kubectl config get-contexts`.

## Migration depuis l’ancien provider Kubernetes (manifests)

Si un ancien état référençait `kubernetes_manifest.*` et des fichiers sous `kubernetes/`, supprimer ces ressources de l’état ou repartir d’un état propre :

```bash
cd terraform
terraform state list
# Pour chaque ancienne ressource kubernetes_manifest.* :
# terraform state rm 'kubernetes_manifest.namespace'
# … puis terraform init && terraform plan && terraform apply
```

Ou, en environnement jetable : `rm -f terraform.tfstate terraform.tfstate.backup` puis `terraform init` et `terraform apply` (à n’utiliser que si vous acceptez de perdre l’historique d’état).

## Tester l’infra (après apply)

```bash
kubectl get namespace pixelwar
kubectl get secret db-credentials -n pixelwar
kubectl get svc postgresdb -n pixelwar
kubectl get statefulset postgresdb -n pixelwar
kubectl get pods -l app=postgresdb -n pixelwar

kubectl exec -it postgresdb-0 -n pixelwar -- psql -U testUser -d testDB -c "SELECT 1;"
```

Références : [Terraform Helm provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs).
