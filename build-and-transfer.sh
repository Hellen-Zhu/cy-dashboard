#!/bin/bash

echo "🐳 开始构建 Sorry Cypress Docker 镜像..."

# 等待 Docker 启动
echo "⏳ 等待 Docker 启动..."
while ! docker info > /dev/null 2>&1; do
    sleep 2
done
echo "✅ Docker 已启动"

# 构建镜像
echo "🔨 构建 Director 镜像..."
docker build -t sorry-cypress-director:latest packages/director

echo "🔨 构建 API 镜像..."
docker build -t sorry-cypress-api:latest packages/api

echo "🔨 构建 Dashboard 镜像..."
docker build -t sorry-cypress-dashboard:latest packages/dashboard

# 保存镜像为 tar 文件
echo "💾 保存镜像为 tar 文件..."
docker save -o sorry-cypress-director.tar sorry-cypress-director:latest
docker save -o sorry-cypress-api.tar sorry-cypress-api:latest
docker save -o sorry-cypress-dashboard.tar sorry-cypress-dashboard:latest

# 创建传输脚本
echo "📝 创建传输脚本..."
cat > transfer-to-aliyun.sh << 'EOF'
#!/bin/bash

# 阿里云 ECS 信息
ECS_IP="47.97.45.91"
ECS_USER="root"
REMOTE_DIR="/opt/sorry-cypress"

echo "🚀 开始传输 Docker 镜像到阿里云 ECS..."

# 创建远程目录
ssh ${ECS_USER}@${ECS_IP} "mkdir -p ${REMOTE_DIR}"

# 传输镜像文件
echo "📤 传输 Director 镜像..."
scp sorry-cypress-director.tar ${ECS_USER}@${ECS_IP}:${REMOTE_DIR}/

echo "📤 传输 API 镜像..."
scp sorry-cypress-api.tar ${ECS_USER}@${ECS_IP}:${REMOTE_DIR}/

echo "📤 传输 Dashboard 镜像..."
scp sorry-cypress-dashboard.tar ${ECS_USER}@${ECS_IP}:${REMOTE_DIR}/

# 传输 docker-compose 文件
echo "📤 传输 docker-compose 文件..."
scp docker-compose.prod.yml ${ECS_USER}@${ECS_IP}:${REMOTE_DIR}/docker-compose.yml

# 在远程服务器上加载镜像
echo "📥 在远程服务器上加载镜像..."
ssh ${ECS_USER}@${ECS_IP} "cd ${REMOTE_DIR} && \
    docker load -i sorry-cypress-director.tar && \
    docker load -i sorry-cypress-api.tar && \
    docker load -i sorry-cypress-dashboard.tar"

echo "✅ 传输完成！"
echo "🌐 现在可以在 ECS 上运行: cd ${REMOTE_DIR} && docker compose up -d"
EOF

chmod +x transfer-to-aliyun.sh

echo "✅ 构建完成！"
echo "📦 生成的镜像文件："
ls -lh *.tar

echo ""
echo "🚀 下一步：运行 ./transfer-to-aliyun.sh 传输到阿里云" 