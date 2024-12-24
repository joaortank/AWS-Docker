# Deploy de WordPress com Docker na AWS

Este projeto implementa o deploy de uma aplicação WordPress utilizando Docker Compose na AWS, com integração ao RDS MySQL, Elastic File System (EFS) e Application Load Balancer (ALB). O ambiente foi configurado para oferecer escalabilidade, segurança e alta disponibilidade.

---

## Etapas do Projeto

### 1. Configurar uma Nova VPC
1. No console da AWS, acesse o serviço **VPC** e crie uma nova VPC:
   - Nome: `wordpress-vpc`.
   - Intervalo CIDR: `10.0.0.0/16`.
2. Crie uma sub-rede pública e uma sub-rede privada associadas à VPC:
   - Sub-rede pública: `10.0.1.0/24`.
   - Sub-rede privada: `10.0.2.0/24`.

---

### 2. Criar um Grupo de Segurança (Security Group)
1. No console AWS, vá até **EC2 > Security Groups** e crie um novo grupo de segurança:
   - Nome: `wordpress-sg`.
   - Regras de entrada:
     - Porta **3306** (MySQL): Permitir acesso somente da sub-rede privada.
     - Porta **22** (SSH): Permitir acesso ao seu IP local.
     - Porta **80** (HTTP): Permitir acesso de qualquer lugar (para o Load Balancer).

---

### 3. Criar um NAT Gateway
1. Crie um **NAT Gateway** na sub-rede pública:
   - Nome: `wordpress-nat`.
   - Associe um Elastic IP (EIP) ao NAT Gateway.
2. Atualize as tabelas de rota:
   - Sub-rede pública: Direcione tráfego para a Internet via Internet Gateway.
   - Sub-rede privada: Direcione tráfego de saída para o NAT Gateway.

---

### 4. Criar o Banco de Dados MySQL no RDS
1. Antes de configurar a instância EC2, crie uma instância RDS MySQL:
   - Nome do banco: `wordpresscompassuol`.
   - Usuário administrador: `admin`.
   - Senha: `compassuol2024`.
   - Endpoint: `wordpress-compass-uol.cnuu0qca6ry4.us-east-1.rds.amazonaws.com`.
   - Associe a instância à sub-rede privada e ao grupo de segurança criado.

---

### 5. Criar a Instância EC2
1. Crie uma instância EC2 utilizando as seguintes configurações:
   - AMI: Amazon Linux 2.
   - Tipo: `t2.micro`.
   - Rede: VPC criada anteriormente, sem IP público.
   - Grupo de segurança: `wordpress-sg`.
2. No campo **User Data**, insira o script abaixo para automatizar a configuração do Docker Compose e montagem do EFS:
   ```bash
   #!/bin/bash
   yum update -y
   yum install -y docker
   systemctl start docker
   systemctl enable docker
   sudo usermod -aG docker ec2-user
   newgrp docker
   curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   chmod +x /usr/local/bin/docker-compose

   sudo mkdir /app

   cat <<EOF > /app/compose.yml
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
   EOF

   sudo mkdir -p /mnt/efs

   sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-09fbac875a2c32771.efs.us-east-1.amazonaws.com:/ /mnt/efs

   docker-compose -f /app/compose.yml up -d


## 6 - Criar um Load Balancer
1. No console AWS, crie um Application Load Balancer (ALB):
 - Nome: wordpress-lb.
 - Tipo: Internet-facing.
 - Listener: Porta 80.
2. Associe o Load Balancer ao grupo de segurança criado.
3. Configure um Target Group e adicione as instâncias EC2 criadas ao grupo.
