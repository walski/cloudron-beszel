export APP_URL=$CLOUDRON_APP_DOMAIN
export USER_CREATION=true

mkdir -p /app/data/pb_data
/app/code/beszel serve --http "0.0.0.0:8090" --dir /app/data/pb_data