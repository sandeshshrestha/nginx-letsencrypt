FROM nginx:alpine

LABEL org.opencontainers.image.authors="Sandesh Shrestha <mail@sandeshshrestha.com>"


WORKDIR "/app"

VOLUME ["/app/config", "/etc/nginx/generated.conf.d", "/etc/letsencrypt"]

RUN apk add --update --no-cache certbot-nginx jq                          && \
    rm -rf /var/cache/apk/*                                               && \
    (echo "0 1 * * * /app/src/cron.sh") | crontab -

# Move all executables and config files
ADD src ./src
ADD config /etc/nginx

RUN chmod -R +x ./src

EXPOSE 443 80

ENTRYPOINT ["/app/src/start.sh"]
