# NGINX reverse proxy with letsencrypt
It will auto generate SSL certificate using https://letsencrypt.org and setup cron job to auto update the certificates.

```bash
mkdir $HOME/nginx-test
echo '
[
   {
      "url": "example.com",
      "proxy": "https://192.168.0.10:8080",
      "email": "mail@example.com",
      "https": false,
      "extra_config": "\\n#Some extra config\\n"
   }
]' > $HOME/nginx-test/nginx.json
docker run -d -p 80:80 -p 443:443 -v $HOME/nginx-test:/app/config sandeshshrestha/nginx-letsencrypt
```

#### /app/config/nginx.json
Config string that describe proxy rules
 - url
   - Public url
   - DNS of this url should be forwarded to this container
 - proxy
   - IP and port of container hosing the website
 - email
   - Email used while calling `certbot` to create SSL certificate
 - https
   - If **true** it will auto create SSL certificate
   - If **false** it will only setup proxy for **http**://example.com
 - extra_config
   - Some text that will be added on nginx conf.
   - It must be valid nginx confix syntax



