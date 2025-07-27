#!/bin/bash

echo "🗄️  MinIO 存储服务访问助手"
echo "================================"
echo ""

# 检查 MinIO 服务状态
echo "📊 检查 MinIO 服务状态..."
if docker-compose -f docker-compose.local.yml ps storage | grep -q "Up"; then
    echo "✅ MinIO 服务正在运行"
else
    echo "❌ MinIO 服务未运行"
    echo "请先启动服务: docker-compose -f docker-compose.local.yml up -d"
    exit 1
fi

# 检查 Web 控制台端口
echo "🔍 检查 Web 控制台端口 9090..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:9090 | grep -q "200"; then
    echo "✅ Web 控制台可访问"
else
    echo "❌ Web 控制台无法访问"
fi

# 检查 API 端口
echo "🔍 检查 API 端口 9000..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:9000 | grep -q "200\|403"; then
    echo "✅ API 服务可访问"
else
    echo "❌ API 服务无法访问"
fi

echo ""
echo "🌐 访问信息"
echo "============"
echo "Web 控制台: http://localhost:9090"
echo "API 端点:   http://localhost:9000"
echo "用户名:     minioadmin"
echo "密码:       minioadmin"
echo "存储桶:     sorry-cypress"
echo ""

echo "🔧 快速操作"
echo "============"
echo "1. 打开浏览器访问: http://localhost:9090"
echo "2. 使用用户名/密码登录: minioadmin/minioadmin"
echo "3. 查看 sorry-cypress 存储桶"
echo "4. 浏览测试截图和视频文件"
echo ""

echo "📁 文件结构"
echo "============"
echo "sorry-cypress/"
echo "├── screenshots/     # 测试截图"
echo "│   └── project-id/"
echo "│       └── run-id/"
echo "│           └── spec-name/"
echo "├── videos/          # 测试视频"
echo "│   └── project-id/"
echo "│       └── run-id/"
echo "│           └── spec-name/"
echo "└── uploads/         # 其他文件"
echo ""

echo "🛠️  管理命令"
echo "============"
echo "查看服务状态:"
echo "  docker-compose -f docker-compose.local.yml ps storage"
echo ""
echo "查看服务日志:"
echo "  docker-compose -f docker-compose.local.yml logs storage"
echo ""
echo "重启服务:"
echo "  docker-compose -f docker-compose.local.yml restart storage"
echo ""

echo "📊 存储信息"
echo "============"
echo "数据存储位置: ./data/data-minio-cypress"
echo "文件类型:"
echo "  - .png (截图文件)"
echo "  - .mp4 (视频文件)"
echo "  - .json (元数据文件)"
echo ""

echo "🔗 相关文档"
echo "============"
echo "详细使用指南: MinIO_使用指南.md"
echo ""

echo "🎉 MinIO 配置完成！"
echo ""
echo "💡 提示: 在 Sorry Cypress Dashboard 中查看测试结果时，"
echo "   截图和视频文件会自动从 MinIO 加载显示。" 