#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
helm repo add minio https://helm.min.io/ && helm repo update
helm install --namespace default -f $DIR/minio/values.yaml minio minio/minio
kubectl patch deployment $(kubectl get deployment --selector=app=minio -o json | jq -r '.items[].metadata.name')  --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/ports/0", "value": {"name": http, "containerPort": 9000, "hostPort": 9000}}]'