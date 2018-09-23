# NGINX reverse proxy with letsencrypt
It does the following..

* Install 'bot blocker' https://github.com/mariusv/nginx-badbot-blocker
* Generate and configure SSL certificate https://letsencrypt.org
* Setup cron job to auto update certificates

### Example
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
