# Terraform
## Prise en main
- Télécharger votre openrc.sh depuis [https://193.49.167.10](https://193.49.167.10)
- Renomer le openrc.sh, `chmod +x openrc.sh`

## Prise de notes

Connexion à zzcluster

```bash
tofu init
tofu plan
tofu plan
tofu plan -var-file prod.tfvars
tofu apply -auto-approve -var=speudo=lmx

tofu init -upgrade
tofu destroy

tofu graph | dot -Tpng > graph.png
```

Fichiers:
outputs.tf
providers.tf
variables.tf

https://www.youtube.com/watch?v=BZ2TLtf3yFg 1h45
https://search.opentofu.org/provider/cyrilgdn/postgresql/v1.25.0 postgresql
https://www.youtube.com/watch?v=KcE4TirnUBc a voir