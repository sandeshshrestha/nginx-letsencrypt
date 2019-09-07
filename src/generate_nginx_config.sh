#!/usr/bin/env sh

INPUT_FILE="/app/config/nginx.json"

if [ ! -f "$INPUT_FILE" ]; then
    printf "\n%s does not exist\n" "$INPUT_FILE"
	exit 1;
fi

INPUT_FILE_CONTENT=$(cat $INPUT_FILE)
OUTPUT_FILE="/etc/nginx/conf.d/nginx-letsencrypt.conf"
TEMP_OUTPUT_FILE="/tmp/nginx-letsencrypt.conf"

printf "\n- Stopping nginx\n"
nginx -s stop

printf "\n- Received following configs\n"
echo "$INPUT_FILE_CONTENT" | jq -r .

# if file is not there we are running it for the first time.
# So We need to create basic config for all site where all http points to its respective proxy
# It will be required while authenticating with certbot
if [ -f "$OUTPUT_FILE" ]; then
	printf "\n- Initial config found.\n"
else
	# Generate basic nginx config
	printf "\n- Initial config not found. (Creating)\n"
	rm $TEMP_OUTPUT_FILE
	touch $TEMP_OUTPUT_FILE
	for site in $(echo "$INPUT_FILE_CONTENT" | jq -r '.[] | @base64'); do
		url=$(echo "$site" | base64 -d | jq -r '.url')
		proxy=$(echo "$site" | base64 -d | jq -r '.proxy')

		mkdir -p "/var/www/$url/.well-known"

		sh /app/src/getBasic.sh "$url" "$proxy" >> $TEMP_OUTPUT_FILE
	done

	# Save the generated config into file
	printf "\n- Created following initial config\n"
	mv $TEMP_OUTPUT_FILE $OUTPUT_FILE
	cat $OUTPUT_FILE;
fi

printf "\n- Starting nginx\n"
nginx

# Generate ssl certificate and change nginx conig
rm $TEMP_OUTPUT_FILE
touch $TEMP_OUTPUT_FILE
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
		if [ -f "/etc/letsencrypt/live/$url/fullchain.pem" ]; then
			printf "\n- Certificate already exists for %s\n" "$url"
			sh /app/src/getExtended.sh "$url" "$proxy" "$extra_config" >> $TEMP_OUTPUT_FILE
		else
			# Proxy Reachable
			printf "\n- Creating new certificate for %s\n" "$url"
			certbot certonly --webroot -w "/var/www/$url" -d "$url" -m "$email" --agree-tos --non-interactive
			if [ $? -eq 0 ]; then
				printf "\n- Created certificate for %s\n" "$url"
				sh /app/src/getExtended.sh "$url" "$proxy" "$extra_config" >> $TEMP_OUTPUT_FILE
			else
				printf "\n- Failed to create certificate for %s\n" "$url"
				sh /app/src/getBasic.sh "$url" "$proxy" >> $TEMP_OUTPUT_FILE
			fi
		fi
	else
		sh /app/src/getBasic.sh "$url" "$proxy" >> $TEMP_OUTPUT_FILE
	fi
done

printf "\n- Created following final config\n"
mv $TEMP_OUTPUT_FILE $OUTPUT_FILE
cat $OUTPUT_FILE;

# Stop nginx
printf "\n- Stopping nginx\n"
nginx -s quit
