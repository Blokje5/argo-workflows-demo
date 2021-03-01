#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
helm repo add minio https://helm.min.io/ && helm repo update
helm install --namespace default -f $DIR/minio/values.yaml minio minio/minio --wait
kubectl patch deployment $(kubectl get deployment --selector=app=minio -o json | jq -r '.items[].metadata.name')  --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/ports/0", "value": {"name": http, "containerPort": 9000, "hostPort": 9000}}]'
kubectl apply -f $DIR/argo/workflow-controller-configmap.yaml
ACCESS_KEY=$(kubectl get secret minio -o jsonpath="{.data.accesskey}" | base64 --decode) && SECRET_KEY=$(kubectl get secret minio -o jsonpath="{.data.secretkey}" | base64 --decode)
mc alias set minio-local http://localhost:9000 "$ACCESS_KEY" "$SECRET_KEY" --api s3v4