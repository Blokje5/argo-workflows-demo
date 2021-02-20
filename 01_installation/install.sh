#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
helm repo add traefik https://helm.traefik.io/traefik && helm repo update && helm install --set ports.traefik.hostPort=9000,ports.web.hostPort=80 traefik traefik/traefik
kubectl apply -f $DIR/traefik/dashboard.yaml
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-workflows/stable/manifests/namespace-install.yaml
kubectl apply -f $DIR/argo/ingress.yaml