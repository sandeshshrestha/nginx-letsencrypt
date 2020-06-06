#!/usr/bin/env sh

INPUT_FILE="/app/config/nginx.json"

if [ ! -f "$INPUT_FILE" ]; then
    printf "\n%s does not exist\n" "$INPUT_FILE"
	exit 1;
fi

mkdir /etc/nginx/generated.conf.d

INPUT_FILE_CONTENT=$(cat $INPUT_FILE)
OUTPUT_FILE_DIR="/etc/nginx/generated.conf.d"

printf "\n- Stopping nginx\n"
nginx -s stop

printf "\n- Received following configs\n"
echo "$INPUT_FILE_CONTENT" | jq -r .

for site in $(echo "$INPUT_FILE_CONTENT" | jq -r '.[] | @base64'); do
  url=$(echo "$site" | base64 -d | jq -r '.url')
  proxy=$(echo "$site" | base64 -d | jq -r '.proxy')

  if [[ -f "$OUTPUT_FILE_DIR/$url.http.conf" || -f "$OUTPUT_FILE_DIR/$url.https.conf" ]]; then
    # We do not want to generate if the nginx config already exists
	  printf "\n- Nginx config already found for $url.\n"
  else
    printf "\n- Created HTTP NGINX config for %s\n" "$url"
    mkdir -p "/var/www/$url/.well-known"
    sh /app/src/getBasic.sh "$url" "$proxy" >> "$OUTPUT_FILE_DIR/$url.http.conf"
  fi
done

printf "\n- Starting nginx\n"
nginx

# Generate ssl certificate and change nginx conig
for site in $(echo "$INPUT_FILE_CONTENT" | jq -r '.[] | @base64'); do
	url=$(echo "$site" | base64 -d | jq -r '.url')
	proxy=$(echo "$site" | base64 -d | jq -r '.proxy')
	email=$(echo "$site" | base64 -d | jq -r '.email')
	https=$(echo "$site" | base64 -d | jq -r '.https')
	extra_config=$(echo "$site" | base64 -d | jq -r '.extra_config')

	if [ "$extra_config" = null ]; then
		extra_config=""
	fi

	printf "\n- Processing %s -> %s\n" "$url" "$proxy"

	if [ "$https" = true ]; then
    if [[ -f "$OUTPUT_FILE_DIR/$url.https.conf" && -f "/etc/letsencrypt/live/$url/fullchain.pem" ]]; then
      printf "\n- Nginx config and certificate already exists for $url.\n"
    else
      if [[ -f "/etc/letsencrypt/live/$url/fullchain.pem" ]]; then
        printf "\n- Certificate already exists for %s\n" "$url"
      else
        # Proxy Reachable
        printf "\n- Creating new certificate for %s\n" "$url"
        certbot certonly --webroot -w "/var/www/$url" -d "$url" -m "$email" --agree-tos --non-interactive

        if [ $? -eq 0 ]; then
          printf "\n- Created certificate for %s\n" "$url"
        else
          printf "\n- Failed to create certificate for %s\n" "$url"
        fi
      fi

      if [[ -f "$OUTPUT_FILE_DIR/$url.https.conf" ]]; then
        printf "\n- HTTPS NGINX config already exists for %s\n" "$url"
      else
        printf "\n- Created HTTPS NGINX config for %s\n" "$url"
        sh /app/src/getExtended.sh "$url" "$proxy" "$extra_config" >> "$OUTPUT_FILE_DIR/$url.https.conf"
        rm "$OUTPUT_FILE_DIR/$url.http.conf"
      fi
    fi
  fi
done

# Stop nginx
printf "\n- Stopping nginx\n"
nginx -s quit
