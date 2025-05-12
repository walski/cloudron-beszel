#!/bin/bash

set -eu

if [[ ! -f /app/data/env.sh ]]; then
    cp /app/pkg/env.sh.template /app/data/env.sh
fi

export USER_CREATION=true
export DISABLE_PASSWORD_AUTH=true

source /app/data/env.sh

mkdir -p /app/data/pb_data

if [ ! -f /app/data/.pg_admin_setup ]; then
  ./setup-oidc.sh

  touch /app/data/.pg_admin_setup
fi

/app/code/beszel serve --http "0.0.0.0:8090" --dir /app/data/pb_data