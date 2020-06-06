FROM nginx:alpine

MAINTAINER Sandesh Shrestha <mail@sandeshshrestha.com>

WORKDIR "/app"

VOLUME ["/app/config"]

RUN apk add --update --no-cache certbot-nginx jq                                && \
    rm -rf /var/cache/apk/*                                               && \
    (echo "0 1 * * * /app/src/cron.sh") | crontab -

# Move all executables and config files
ADD src ./src
ADD config /etc/nginx

RUN chmod -R +x ./src

EXPOSE 443 80

ENTRYPOINT ["/app/src/start.sh"]
