#!/bin/bash
# Atualiza o sistema
yum update -y

# Instala o Docker
yum install -y docker
systemctl start docker
systemctl enable docker

# Instala o Docker Compose
curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Cria diretório para o WordPress e configuração do Docker Compose
mkdir -p /home/ec2-user/wordpress-deploy
cat <<EOL > /home/ec2-user/wordpress-deploy/docker-compose.yml
version: '3.8'

services:
  wordpress:
    image: wordpress:latest
    restart: always
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: wordpress-compass-uol.cnuu0qca6ry4.us-east-1.rds.amazonaws.com
      WORDPRESS_DB_USER: admin
      WORDPRESS_DB_PASSWORD: compassuol2024
      WORDPRESS_DB_NAME: wordpresscompassuol
    volumes:
      - /mnt/efs:/var/www/html

EOL

sudo mkdir -p /mnt/efs

sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-09fbac875a2c32771.efs.us-east-1.amazonaws.com:/ /mnt/efs

docker-compose -f /home/ec2-user/wordpress-deploy/docker-compose.yml -d
# Dá permissão para o diretório
chown -R ec2-user:ec2-user /home/ec2-user/wordpress-deploy

# Cria um serviço do systemd para iniciar o Docker Compose automaticamente
cat <<EOF > /etc/systemd/system/wordpress.service
[Unit]
Description=Docker Compose WordPress Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
WorkingDirectory=/home/ec2-user/wordpress-deploy
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

# Habilita e inicia o serviço
systemctl daemon-reload
systemctl enable wordpress.service
systemctl start wordpress.service
