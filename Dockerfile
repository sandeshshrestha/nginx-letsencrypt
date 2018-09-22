FROM debian:stable

MAINTAINER Sandesh Shrestha <mail@sandeshshrestha.com>

# Install Required Softwares
RUN apt update                                                                  && \
    apt install -y vim nginx python-certbot-nginx cron git apache2-utils        && \
    mkdir -p /app                                                               && \
    (echo "0 1 * * * /app/src/cron.sh") | crontab -                             && \
    rm -rf /var/lib/apt/lists/*

VOLUME ["/app/config"]

ENV CERTBOT_ARGS ""

WORKDIR "/app"

# Move all executables and config files
ADD src ./src
ADD config /etc/nginx

RUN chmod -R +x ./src

EXPOSE 443 80

ENTRYPOINT ["/app/src/start.sh"]
