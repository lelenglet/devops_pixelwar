#!/bin/bash

echo "--- 1. Lancement du déploiement Ansible ---"
cd ansible
ansible-playbook playbooks/deploy.yml
cd ..

sleep 180

echo "--- 2. Récupération du mot de passe ArgoCD ---"
PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Login: admin"
echo "Password: $PASS"

echo "--- 3. Nettoyage des anciens services ---"
kubectl delete svc pixelwar-back-service pixelwar-front-service -n pixelwar --ignore-not-found

echo "--- 4. Accès à l'interface (Port-Forward) ---"
echo "L'interface sera disponible sur https://localhost:8080"
echo "Appuie sur Ctrl+C pour arrêter le tunnel et quitter le script."
kubectl port-forward svc/argocd-server -n argocd 8080:443