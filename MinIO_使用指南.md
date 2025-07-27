# MinIO 使用指南

## 📋 什么是 MinIO？

MinIO 是一个高性能的分布式对象存储服务，具有以下特点：

### 🎯 核心特性
- **S3 兼容**: 完全兼容 Amazon S3 API
- **高性能**: 支持高并发读写操作
- **分布式**: 支持水平扩展和容错
- **轻量级**: 资源占用少，部署简单
- **开源**: 基于 Apache License 2.0

### 🔄 在 Sorry Cypress 中的作用
- **存储截图**: 保存测试失败时的屏幕截图
- **存储视频**: 保存测试执行过程的视频录制
- **文件管理**: 提供文件上传、下载、删除等操作
- **访问控制**: 管理文件的访问权限

## 🌐 访问 MinIO

### Web 控制台访问
- **地址**: http://localhost:9090
- **用户名**: `minioadmin`
- **密码**: `minioadmin`

### API 访问
- **API 端点**: http://localhost:9000
- **访问密钥**: `minioadmin`
- **秘密密钥**: `minioadmin`

## 🔧 基本操作

### 1. 登录 Web 控制台

1. 打开浏览器访问 http://localhost:9090
2. 输入用户名: `minioadmin`
3. 输入密码: `minioadmin`
4. 点击 "Login"

### 2. 查看存储桶

登录后，您将看到 `sorry-cypress` 存储桶，这是 Sorry Cypress 使用的默认存储桶。

### 3. 浏览文件

在存储桶中，您可以：
- 查看所有上传的文件
- 按文件夹结构浏览
- 搜索特定文件
- 查看文件详细信息

## 📁 文件结构

Sorry Cypress 在 MinIO 中创建的文件结构：

```
sorry-cypress/
├── screenshots/
│   ├── project-id/
│   │   ├── run-id/
│   │   │   ├── spec-name/
│   │   │   │   └── screenshot.png
├── videos/
│   ├── project-id/
│   │   ├── run-id/
│   │   │   ├── spec-name/
│   │   │   │   └── video.mp4
└── uploads/
    └── other-files/
```

## 🛠️ 管理操作

### 上传文件
1. 在 Web 控制台中点击 "Upload"
2. 选择要上传的文件
3. 选择目标文件夹
4. 点击 "Upload"

### 下载文件
1. 找到要下载的文件
2. 点击文件名或右键选择 "Download"
3. 文件将下载到本地

### 删除文件
1. 选择要删除的文件
2. 点击删除图标或右键选择 "Delete"
3. 确认删除操作

### 创建文件夹
1. 点击 "Create Folder"
2. 输入文件夹名称
3. 点击 "Create"

## 🔍 文件类型说明

### 截图文件 (.png)
- **用途**: 测试失败时的屏幕截图
- **命名**: 通常包含测试名称和时间戳
- **位置**: `screenshots/project-id/run-id/spec-name/`

### 视频文件 (.mp4)
- **用途**: 测试执行过程的视频录制
- **命名**: 通常包含测试名称和时间戳
- **位置**: `videos/project-id/run-id/spec-name/`

## 📊 存储统计

### 查看存储使用情况
1. 在 Web 控制台左侧菜单点击 "Dashboard"
2. 查看存储桶使用统计
3. 查看文件数量和总大小

### 监控存储增长
- 定期检查存储使用量
- 清理不需要的旧文件
- 监控存储趋势

## 🔐 权限管理

### 当前配置
- **访问权限**: 公开读取
- **上传权限**: 需要认证
- **删除权限**: 需要认证

### 修改权限
1. 在存储桶设置中修改访问策略
2. 配置 CORS 规则
3. 设置生命周期策略

## 🚀 高级功能

### 1. 版本控制
- 启用文件版本控制
- 查看文件历史版本
- 恢复删除的文件

### 2. 生命周期管理
- 设置文件过期时间
- 自动删除旧文件
- 配置存储策略

### 3. 通知配置
- 设置文件上传通知
- 配置 Webhook
- 集成外部服务

## 🔧 命令行工具 (mc)

### 安装 mc 客户端
```bash
# macOS
brew install minio/stable/mc

# 或者下载二进制文件
wget https://dl.min.io/client/mc/release/darwin-amd64/mc
chmod +x mc
```

### 配置连接
```bash
# 配置 MinIO 服务器
mc config host add myminio http://localhost:9000 minioadmin minioadmin

# 验证连接
mc ls myminio
```

### 常用命令
```bash
# 列出存储桶
mc ls myminio

# 列出文件
mc ls myminio/sorry-cypress

# 上传文件
mc cp local-file.png myminio/sorry-cypress/

# 下载文件
mc cp myminio/sorry-cypress/file.png ./

# 删除文件
mc rm myminio/sorry-cypress/file.png

# 同步文件夹
mc mirror local-folder/ myminio/sorry-cypress/
```

## 🛠️ 故障排除

### 无法访问 Web 控制台
1. **检查服务状态**:
   ```bash
   docker-compose -f docker-compose.local.yml ps storage
   ```

2. **检查端口**:
   ```bash
   lsof -i :9090
   ```

3. **重启服务**:
   ```bash
   docker-compose -f docker-compose.local.yml restart storage
   ```

### 文件上传失败
1. **检查存储空间**:
   - 查看磁盘空间
   - 检查 Docker 存储限制

2. **检查权限**:
   - 验证访问密钥
   - 检查存储桶权限

3. **查看日志**:
   ```bash
   docker-compose -f docker-compose.local.yml logs storage
   ```

### 文件访问权限问题
1. **检查 CORS 配置**
2. **验证访问策略**
3. **检查网络连接**

## 📈 性能优化

### 1. 存储优化
- 定期清理旧文件
- 压缩大文件
- 使用适当的存储策略

### 2. 网络优化
- 配置 CDN
- 优化网络带宽
- 使用就近的存储节点

### 3. 监控和告警
- 设置存储使用告警
- 监控访问性能
- 跟踪错误率

## 🔗 集成示例

### 在 Sorry Cypress 中配置
```javascript
// cypress.config.js
module.exports = {
  env: {
    sorryCypressUrl: 'http://localhost:1234',
    // MinIO 配置会自动从 Sorry Cypress 获取
  }
}
```

### 直接访问 MinIO API
```javascript
// 使用 AWS SDK 访问 MinIO
const AWS = require('aws-sdk');

const s3 = new AWS.S3({
  endpoint: 'http://localhost:9000',
  accessKeyId: 'minioadmin',
  secretAccessKey: 'minioadmin',
  s3ForcePathStyle: true,
  signatureVersion: 'v4'
});

// 列出文件
s3.listObjects({
  Bucket: 'sorry-cypress'
}, (err, data) => {
  if (err) console.log(err);
  else console.log(data);
});
```

## 📚 相关资源

- [MinIO 官方文档](https://docs.min.io/)
- [MinIO GitHub](https://github.com/minio/minio)
- [S3 API 兼容性](https://docs.min.io/docs/minio-gateway-for-s3.html)
- [Sorry Cypress 存储配置](https://docs.sorry-cypress.dev/)

---

**配置时间**: 2025-07-27  
**MinIO 版本**: RELEASE.2025-07-23T15-54-02Z  
**访问地址**: http://localhost:9090  
**API 地址**: http://localhost:9000 