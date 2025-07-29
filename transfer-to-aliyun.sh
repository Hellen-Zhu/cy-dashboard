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
