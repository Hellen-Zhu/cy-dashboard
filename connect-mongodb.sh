#!/bin/bash

echo "🔗 MongoDB Compass 连接助手"
echo "================================"
echo ""

# 检查 MongoDB 服务状态
echo "📊 检查 MongoDB 服务状态..."
if docker-compose -f docker-compose.local.yml ps mongo | grep -q "Up"; then
    echo "✅ MongoDB 服务正在运行"
else
    echo "❌ MongoDB 服务未运行"
    echo "请先启动服务: docker-compose -f docker-compose.local.yml up -d"
    exit 1
fi

# 检查端口
echo "🔍 检查端口 27017..."
if lsof -i :27017 > /dev/null 2>&1; then
    echo "✅ 端口 27017 已开放"
else
    echo "❌ 端口 27017 未开放"
    exit 1
fi

echo ""
echo "📋 连接信息"
echo "============"
echo "连接字符串: mongodb://admin:password@localhost:27017"
echo "主机地址:   localhost"
echo "端口:       27017"
echo "用户名:     admin"
echo "密码:       password"
echo "认证数据库: admin"
echo ""

echo "🔧 连接步骤"
echo "============"
echo "1. 打开 MongoDB Compass"
echo "2. 选择 'Advanced Connection Options'"
echo "3. 在连接字符串字段输入:"
echo "   mongodb://admin:password@localhost:27017"
echo "4. 点击 'Connect' 按钮"
echo ""

echo "📊 数据库信息"
echo "============="
echo "主要数据库: sorry-cypress"
echo "主要集合:"
echo "  - instances (测试实例)"
echo "  - projects (项目信息)"
echo "  - runs (测试运行)"
echo "  - specs (测试规格)"
echo "  - runTimeouts (超时配置)"
echo ""

echo "🔍 常用查询"
echo "==========="
echo "查看所有项目:"
echo "  db.projects.find({})"
echo ""
echo "查看最近的测试运行:"
echo "  db.runs.find({}).sort({createdAt: -1}).limit(10)"
echo ""
echo "查看特定项目的运行:"
echo "  db.runs.find({projectId: 'your-project-id'})"
echo ""

echo "📚 更多信息请查看: MongoDB_Compass_连接指南.md"
echo ""
echo "🎉 连接配置完成！" 