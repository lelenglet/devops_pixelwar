# Terraform
## Prise en main
- Télécharger votre openrc.sh depuis [https://193.49.167.10](https://193.49.167.10)
- Renommer le openrc.sh, puis:
```bash
chmod +x openrc.sh
source openrc.sh   # ou: . openrc.sh  (requis pour exporter OS_* vers terraform)

terraform init
terraform plan
```

# Prise de notes
## Quelques commandes

Connexion à zzcluster

```bash
terraform init
terraform plan
terraform plan -var-file prod.tfvars
terraform apply -auto-approve -var=speudo=lmx

terraform init -upgrade
terraform destroy

terraform graph | dot -Tpng > graph.png
```

Fichiers:
outputs.tf
providers.tf
variables.tf

https://www.youtube.com/watch?v=BZ2TLtf3yFg 1h45
https://search.opentofu.org/provider/cyrilgdn/postgresql/v1.25.0 postgresql
https://www.youtube.com/watch?v=KcE4TirnUBc a voir

## Fichié copié depuis le vidéo proj

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