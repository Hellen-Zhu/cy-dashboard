#!/bin/bash

echo "🚀 启动 Sorry Cypress 本地服务..."

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker 未运行，请先启动 Docker"
    exit 1
fi

# 创建数据目录
echo "📁 创建数据目录..."
mkdir -p data/data-mongo-cypress data/data-minio-cypress

# 启动服务
echo "🔧 启动 Docker 服务..."
docker-compose -f docker-compose.local.yml up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
echo "📊 检查服务状态..."
docker-compose -f docker-compose.local.yml ps

echo ""
echo "✅ Sorry Cypress 本地服务已启动！"
echo ""
echo "🌐 访问地址："
echo "   Dashboard: http://localhost:8081"
echo "   API:       http://localhost:4000"
echo "   Director:  http://localhost:1234"
echo "   MinIO:     http://localhost:9090 (用户名: minioadmin, 密码: minioadmin)"
echo ""
echo "📖 详细说明请查看 LOCAL_DEPLOYMENT.md"
echo ""
echo "🛑 停止服务: docker-compose -f docker-compose.local.yml down" 