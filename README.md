# Terraform insfrastuture modules


## vpcs multiple nics nginx

- Edit local variables (main.tf)

```bash
cd vpcs_nginx; 
terraform init;
terraform plan;
terraform apply;
```
- complete nginx
```bash
echo 'server {
        listen 8080;
        listen [::]:8080;

        access_log /var/log/nginx/reverse-access.log;
        error_log /var/log/nginx/reverse-error.log;

        location / {
                    proxy_pass http://10.1.0.2:8080;
                    proxy_set_header X-Forwarded-For $remote_addr;
  }
}' > /etc/nginx/sites-available/reverse-proxy.conf;
ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/reverse-proxy.conf;
nginx -t;
systemctl restart nginx;
```