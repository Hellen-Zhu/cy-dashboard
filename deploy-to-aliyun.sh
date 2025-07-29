#!/bin/bash

echo "🚀 Sorry Cypress 阿里云一键部署脚本"
echo "======================================"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
DOMAIN=""
PROJECT_KEYS=""
MONGO_PASSWORD=""
MINIO_SECRET=""

# 获取用户输入
echo -e "${BLUE}请输入配置信息:${NC}"
read -p "域名 (例如: cypress.yourdomain.com): " DOMAIN
read -p "项目密钥 (用逗号分隔多个key): " PROJECT_KEYS
read -s -p "MongoDB 密码: " MONGO_PASSWORD
echo ""
read -s -p "MinIO 密钥: " MINIO_SECRET
echo ""

# 验证输入
if [ -z "$DOMAIN" ] || [ -z "$PROJECT_KEYS" ] || [ -z "$MONGO_PASSWORD" ] || [ -z "$MINIO_SECRET" ]; then
    echo -e "${RED}❌ 所有字段都必须填写${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ 配置信息已获取${NC}"
echo "域名: $DOMAIN"
echo "项目密钥: $PROJECT_KEYS"
echo ""

# 1. 更新系统
echo -e "${BLUE}📦 更新系统...${NC}"
sudo apt update && sudo apt upgrade -y

# 2. 安装 Docker
echo -e "${BLUE}🐳 安装 Docker...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo -e "${GREEN}✅ Docker 安装完成${NC}"
else
    echo -e "${YELLOW}⚠️  Docker 已安装${NC}"
fi

# 3. 安装 Docker Compose
echo -e "${BLUE}📋 安装 Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}✅ Docker Compose 安装完成${NC}"
else
    echo -e "${YELLOW}⚠️  Docker Compose 已安装${NC}"
fi

# 4. 安装 Nginx
echo -e "${BLUE}🌐 安装 Nginx...${NC}"
if ! command -v nginx &> /dev/null; then
    sudo apt install nginx -y
    sudo systemctl enable nginx
    sudo systemctl start nginx
    echo -e "${GREEN}✅ Nginx 安装完成${NC}"
else
    echo -e "${YELLOW}⚠️  Nginx 已安装${NC}"
fi

# 5. 创建项目目录
echo -e "${BLUE}📁 创建项目目录...${NC}"
sudo mkdir -p /opt/sorry-cypress
sudo chown $USER:$USER /opt/sorry-cypress
cd /opt/sorry-cypress

# 创建数据目录
mkdir -p data/{mongo,minio}

# 6. 生成生产环境配置文件
echo -e "${BLUE}⚙️  生成配置文件...${NC}"

# 生成 docker-compose.prod.yml
cat > docker-compose.prod.yml << EOF
version: '3.8'

services:
  mongo:
    image: mongo:4.4
    environment:
      MONGO_INITDB_ROOT_USERNAME: 'admin'
      MONGO_INITDB_ROOT_PASSWORD: '$MONGO_PASSWORD'
    volumes:
      - ./data/mongo:/data/db
    restart: unless-stopped
    networks:
      - sorry-cypress-network

  director:
    image: agoldis/sorry-cypress-director:latest
    environment:
      DASHBOARD_URL: https://$DOMAIN
      EXECUTION_DRIVER: '../execution/mongo/driver'
      MONGODB_URI: 'mongodb://admin:$MONGO_PASSWORD@mongo:27017'
      MONGODB_DATABASE: 'sorry-cypress'
      SCREENSHOTS_DRIVER: '../screenshots/minio.driver'
      MINIO_ACCESS_KEY: 'minioadmin'
      MINIO_SECRET_KEY: '$MINIO_SECRET'
      MINIO_ENDPOINT: 'minio'
      MINIO_URL: 'http://minio:9000'
      MINIO_PORT: '9000'
      MINIO_USESSL: 'false'
      MINIO_BUCKET: sorry-cypress
      ALLOWED_KEYS: '$PROJECT_KEYS'
      PROBE_LOGGER: "false"
    ports:
      - "1234:1234"
    depends_on:
      - mongo
      - minio
    restart: unless-stopped
    networks:
      - sorry-cypress-network

  api:
    image: agoldis/sorry-cypress-api:latest
    environment:
      MONGODB_URI: 'mongodb://admin:$MONGO_PASSWORD@mongo:27017'
      MONGODB_DATABASE: 'sorry-cypress'
      APOLLO_PLAYGROUND: 'false'
    ports:
      - "4000:4000"
    depends_on:
      - mongo
    restart: unless-stopped
    networks:
      - sorry-cypress-network

  dashboard:
    image: agoldis/sorry-cypress-dashboard:latest
    environment:
      GRAPHQL_SCHEMA_URL: http://api:4000
      GRAPHQL_CLIENT_CREDENTIALS: ''
      PORT: 8080
      CI_URL: ''
    ports:
      - "8080:8080"
    depends_on:
      - api
    restart: unless-stopped
    networks:
      - sorry-cypress-network

  minio:
    image: minio/minio
    environment:
      MINIO_ROOT_USER: 'minioadmin'
      MINIO_ROOT_PASSWORD: '$MINIO_SECRET'
    volumes:
      - ./data/minio:/data
    command: minio server --console-address ":9090" /data
    ports:
      - "9000:9000"
      - "9090:9090"
    restart: unless-stopped
    networks:
      - sorry-cypress-network

  createbuckets:
    image: minio/mc
    network_mode: service:minio
    depends_on:
      - minio
    entrypoint: >
      /bin/sh -c "
      sleep 5;
      /usr/bin/mc alias set myminio http://localhost:9000 minioadmin $MINIO_SECRET;
      /usr/bin/mc mb myminio/sorry-cypress || true;
      /usr/bin/mc anonymous set download myminio/sorry-cypress;
      /usr/bin/mc anonymous set public myminio/sorry-cypress;
      exit 0;
      "

networks:
  sorry-cypress-network:
    driver: bridge
EOF

# 7. 生成 Nginx 配置
echo -e "${BLUE}🌐 生成 Nginx 配置...${NC}"

sudo tee /etc/nginx/sites-available/sorry-cypress > /dev/null << EOF
server {
    listen 80;
    server_name $DOMAIN;

    # 重定向到 HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    # SSL 证书配置 (稍后配置)
    # ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # SSL 配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Dashboard
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # API
    location /api/ {
        proxy_pass http://localhost:4000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Director
    location /director/ {
        proxy_pass http://localhost:1234/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # MinIO Console
    location /minio/ {
        proxy_pass http://localhost:9090/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# 启用站点配置
sudo ln -sf /etc/nginx/sites-available/sorry-cypress /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# 测试 Nginx 配置
sudo nginx -t
if [ $? -eq 0 ]; then
    sudo systemctl restart nginx
    echo -e "${GREEN}✅ Nginx 配置完成${NC}"
else
    echo -e "${RED}❌ Nginx 配置错误${NC}"
    exit 1
fi

# 8. 启动服务
echo -e "${BLUE}🚀 启动 Sorry Cypress 服务...${NC}"
docker-compose -f docker-compose.prod.yml up -d

# 等待服务启动
echo -e "${BLUE}⏳ 等待服务启动...${NC}"
sleep 30

# 9. 检查服务状态
echo -e "${BLUE}📊 检查服务状态...${NC}"
docker-compose -f docker-compose.prod.yml ps

# 10. 配置 SSL 证书
echo -e "${BLUE}🔒 配置 SSL 证书...${NC}"
echo -e "${YELLOW}⚠️  请确保域名 $DOMAIN 已指向此服务器${NC}"
read -p "是否现在配置 SSL 证书? (y/n): " configure_ssl

if [ "$configure_ssl" = "y" ] || [ "$configure_ssl" = "Y" ]; then
    # 安装 Certbot
    sudo apt install certbot python3-certbot-nginx -y
    
    # 获取 SSL 证书
    sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN
    
    # 设置自动续期
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    
    echo -e "${GREEN}✅ SSL 证书配置完成${NC}"
else
    echo -e "${YELLOW}⚠️  请稍后手动配置 SSL 证书${NC}"
fi

# 11. 生成客户端配置
echo -e "${BLUE}📋 生成客户端配置...${NC}"

cat > cypress.config.prod.js << EOF
const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
  },
  env: {
    sorryCypressUrl: 'https://$DOMAIN/director',
    recordKey: '${PROJECT_KEYS%%,*}'
  }
})
EOF

# 12. 显示部署结果
echo ""
echo -e "${GREEN}🎉 部署完成！${NC}"
echo "======================================"
echo -e "${BLUE}🌐 访问地址:${NC}"
echo "  Dashboard: https://$DOMAIN"
echo "  API: https://$DOMAIN/api"
echo "  Director: https://$DOMAIN/director"
echo "  MinIO Console: https://$DOMAIN/minio"
echo ""
echo -e "${BLUE}🔑 登录信息:${NC}"
echo "  MinIO Console:"
echo "    用户名: minioadmin"
echo "    密码: $MINIO_SECRET"
echo ""
echo -e "${BLUE}📁 项目密钥:${NC}"
echo "  $PROJECT_KEYS"
echo ""
echo -e "${BLUE}📋 客户端配置:${NC}"
echo "  使用 cypress.config.prod.js 配置文件"
echo ""
echo -e "${BLUE}🛠️  管理命令:${NC}"
echo "  查看服务状态: docker-compose -f docker-compose.prod.yml ps"
echo "  查看日志: docker-compose -f docker-compose.prod.yml logs -f"
echo "  重启服务: docker-compose -f docker-compose.prod.yml restart"
echo "  停止服务: docker-compose -f docker-compose.prod.yml down"
echo ""
echo -e "${YELLOW}⚠️  重要提醒:${NC}"
echo "  1. 请保存好密码和密钥信息"
echo "  2. 定期备份 /opt/sorry-cypress/data 目录"
echo "  3. 监控服务器资源使用情况"
echo "  4. 配置防火墙和安全组"
echo ""
echo -e "${GREEN}✅ 部署脚本执行完成！${NC}" 