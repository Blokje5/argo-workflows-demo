#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-workflows/stable/manifests/namespace-install.yaml
kubectl apply -f $DIR/argo/ingress.yaml
kubectl create rolebinding argo-server-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=argo-server:default \
  --namespace=default
kubectl apply -f $DIR/argo/workflow-executor.yaml

# Makes live easy for workflows, no need to specify a seperate service account
kubectl create rolebinding default-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=default:default \
  --namespace=default