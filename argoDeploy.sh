#!/bin/bash

echo "--- 1. Mise en place du cluster Kind ---"
./runArgo.sh

sleep 30

echo "--- 2. Lancement du déploiement Ansible ---"
cd ansible
ansible-playbook playbooks/deployArgo.yml
cd ..

sleep 300 

echo "--- 2. Récupération du mot de passe ArgoCD ---"
PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Login: admin"
echo "Password: $PASS"

echo "--- 3. Accès à l'interface ---"
echo "Ajouter votre secret pour pouvoir accéder correctement à l'infrastructure. (README)"

echo "Veuillez exécuter cette commande pour pouvoir accéder à argoCD"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
