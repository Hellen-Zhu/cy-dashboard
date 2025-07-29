#!/bin/bash

echo "🔨 开始构建 AMD64 架构的 Sorry Cypress 镜像..."

# 等待 Docker 启动
echo "⏳ 等待 Docker 启动..."
while ! docker info > /dev/null 2>&1; do
    sleep 2
done
echo "✅ Docker 已启动"

# 构建 AMD64 架构的镜像
echo "🔨 构建 Director 镜像 (AMD64)..."
docker build --platform linux/amd64 -t sorry-cypress-director:amd64 packages/director

echo "🔨 构建 API 镜像 (AMD64)..."
docker build --platform linux/amd64 -t sorry-cypress-api:amd64 packages/api

echo "🔨 构建 Dashboard 镜像 (AMD64)..."
docker build --platform linux/amd64 -t sorry-cypress-dashboard:amd64 packages/dashboard

# 保存镜像为 tar 文件
echo "💾 保存镜像为 tar 文件..."
docker save -o sorry-cypress-director-amd64.tar sorry-cypress-director:amd64
docker save -o sorry-cypress-api-amd64.tar sorry-cypress-api:amd64
docker save -o sorry-cypress-dashboard-amd64.tar sorry-cypress-dashboard:amd64

echo "✅ 构建完成！"
echo "📦 生成的镜像文件："
ls -lh *-amd64.tar

echo ""
echo "🚀 下一步：运行 ./transfer-amd64-images.sh 传输到阿里云" 