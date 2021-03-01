#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
mc mb minio-local/csv-orders
mc cp $DIR/orders.csv minio-local/csv-orders