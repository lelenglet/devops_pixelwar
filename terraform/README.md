# Terraform
## Prise en main
```bash
terraform init
terraform plan
terraform apply
```

# Tuto

## Tester l'infra
```bash
terraform init
terraform apply
# ─── Vérifier les ressources ───
# Namespace
kubectl get namespace pixelwar

# Ressources de la base (namespace default)
kubectl get secret db-credentials
kubectl get svc postgresdb
kubectl get statefulset postgresdb

NAME             TYPE     DATA   AGE
db-credentials   Opaque   3      111s
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
postgresdb   ClusterIP   None         <none>        5432/TCP   111s
NAME         READY   AGE
postgresdb   1/1     111s

# Statut des pods
kubectl get pods -l app=postgresdb

# ─── Tester la BDD ───
kubectl exec -it postgresdb-0 -- psql -U testUser -d testDB -c "SELECT 1;"


# ─── Tester la persistance de la BDD ───
# Créer une table de test
kubectl exec -it postgresdb-0 -- psql -U testUser -d testDB -c "
  CREATE TABLE IF NOT EXISTS test (id SERIAL PRIMARY KEY, value TEXT);
  INSERT INTO test (value) VALUES ('persistence test');
"

# Supprimer le pod (le StatefulSet le recréera)
kubectl delete pod postgresdb-0

# Attendre le redémarrage
kubectl wait --for=condition=ready pod -l app=postgresdb --timeout=120s

# Vérifier que les données sont toujours là
kubectl exec -it postgresdb-0 -- psql -U testUser -d testDB -c "SELECT * FROM test;"
```

## Prise de note sur l'install
[Tuto](https://developer.hashicorp.com/terraform/tutorials/kubernetes/kubernetes-provider)
- Installer kind et kubectl sur votre pc puis
```bash
curl https://raw.githubusercontent.com/hashicorp/learn-terraform-deploy-nginx-kubernetes-provider/main/kind-config.yaml --output kind-config.yaml
kind create cluster --name terraform-learn --config kind-config.yaml

kind get clusters
kubectl cluster-info --context kind-terraform-learn
```

On va ensuite mettre à jour les variables de `terraform.tfvars` avec les valeurs de
```bash
kubectl config view --minify --flatten --context=kind-terraform-learn
```

On va lister nos instances:
```bash
kubectl get services
NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
kubernetes      ClusterIP   10.96.0.1      <none>        443/TCP        21m
nginx-example   NodePort    10.96.160.55   <none>        80:30201/TCP   14s
```

On peux accéder à notre Nginx: `curl http://localhost:30201/`

## Fichier copié depuis le vidéo proj

```t
resource "google_compute_instance" "nginx" {
    for_each = var.config.cloud.workload

    machine_type = each.value.machine_typename = "nginx-${each.key}"
    zone = "${each.value.region}-b"

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-12"
        }
    }

    network_interface {
        network = "default"
        access_config {}
    }

    tags = ["public"]

    metadata_startup_script = <<-EOF
        #!/bin/bash
        apt-get update
        apt-get install -y nginx
        echo " <!DOCTYOE html> <html lang="fr"> <head> <meta charset="UTF-8"> <meta name="viewport" content="width=dev....">"

}
```