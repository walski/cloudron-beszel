#!/bin/bash

set -eu

echo "🔐 Setting up OIDC Auth"

echo "🤓 Adding admin user"
/app/code/beszel superuser create --dir /app/data/pb_data admin@example.com cloudron

# 1) Grab a temporary admin token
echo "🔌 Starting background server"
/app/code/beszel serve --http "0.0.0.0:8091" --dir /app/data/pb_data &
sleep 3

# 1) Grab a temporary admin token
echo "🗝️ Authenticating as admin..."
TOKEN=$(curl -s -X POST -H "Content-Type: application/json" -d '{"identity": "admin@example.com", "password": "cloudron"}' "localhost:8091/api/collections/_superusers/auth-with-password" | jq -r .token)

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "❌ Failed to authenticate as admin"
  exit 1
fi

# 2) Ensure Cloudron OIDC env vars are present
: "${CLOUDRON_OIDC_ISSUER:?Need to set CLOUDRON_OIDC_ISSUER}"
: "${CLOUDRON_OIDC_CLIENT_ID:?Need to set CLOUDRON_OIDC_CLIENT_ID}"
: "${CLOUDRON_OIDC_CLIENT_SECRET:?Need to set CLOUDRON_OIDC_CLIENT_SECRET}"

# optional display name and endpoints (fall back to issuer URLs)
DISPLAY_NAME="${CLOUDRON_OIDC_PROVIDER_NAME:-Cloudron}"
AUTH_URL="${CLOUDRON_OIDC_AUTH_ENDPOINT:-${CLOUDRON_OIDC_ISSUER}/authorize}"
TOKEN_URL="${CLOUDRON_OIDC_TOKEN_ENDPOINT:-${CLOUDRON_OIDC_ISSUER}/token}"
USER_API_URL="${CLOUDRON_OIDC_PROFILE_ENDPOINT:-${CLOUDRON_OIDC_ISSUER}/userinfo}"

# 3) Build the JSON payload
PAYLOAD=$(cat <<EOF
{
  "oauth2": {
    "enabled": true,
    "providers": [
      {
        "name": "oidc",
        "displayName": "${DISPLAY_NAME}",
        "authUrl": "${AUTH_URL}",
        "tokenUrl": "${TOKEN_URL}",
        "userApiUrl": "${USER_API_URL}",
        "clientId": "${CLOUDRON_OIDC_CLIENT_ID}",
        "clientSecret": "${CLOUDRON_OIDC_CLIENT_SECRET}",
        "pkce": true
      }
    ]
  }
}
EOF
)

# 4) PATCH the “users” collection
echo "⚙️  Patching users collection with OIDC provider..."
curl -s -X PATCH "localhost:8091/api/collections/users" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${PAYLOAD}" \
  | jq .

echo "🙅‍♂️ Deleting admin user"
/app/code/beszel superuser delete --dir /app/data/pb_data admin@example.com

echo "👋 Stopping server"
kill %1

echo "✅ Done."