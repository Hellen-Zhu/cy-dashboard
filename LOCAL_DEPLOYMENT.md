# Sorry Cypress 本地部署指南

### 主要服务
- **Dashboard (Web界面)**: http://localhost:8081
- **API (GraphQL)**: http://localhost:4000
- **Director (测试协调器)**: http://localhost:1234

### 存储服务
- **MinIO 控制台**: http://localhost:9090
  - 用户名: `minioadmin`
  - 密码: `minioadmin`
- **MinIO API**: http://localhost:9000

### 数据库
- **MongoDB**: localhost:27017
  - 用户名: `admin`
  - 密码: `password`
  - 数据库: `sorry-cypress`

## 服务管理

### 查看服务状态
```bash
docker-compose -f docker-compose.local.yml ps
```

### 查看服务日志
```bash
# 查看所有服务日志
docker-compose -f docker-compose.local.yml logs

# 查看特定服务日志
docker-compose -f docker-compose.local.yml logs dashboard
docker-compose -f docker-compose.local.yml logs api
docker-compose -f docker-compose.local.yml logs director
```

### 停止服务
```bash
docker-compose -f docker-compose.local.yml down
```

### 重启服务
```bash
docker-compose -f docker-compose.local.yml restart
```

## 配置说明

### 环境变量
- **MongoDB**: 使用认证模式，用户名/密码为 admin/password
- **MinIO**: 使用默认凭据 minioadmin/minioadmin
- **Dashboard**: 运行在端口 8081（避免与本地其他服务冲突）

### 数据持久化
- MongoDB 数据存储在: `./data/data-mongo-cypress`
- MinIO 数据存储在: `./data/data-minio-cypress`

## 使用说明

1. **访问 Dashboard**: 打开浏览器访问 http://localhost:8081
2. **创建项目**: 在 Dashboard 中创建新的测试项目
3. **配置 Cypress**: 在您的 Cypress 项目中配置 sorry-cypress
4. **运行测试**: 使用 sorry-cypress 运行您的 Cypress 测试

## Cypress 配置示例

在您的 Cypress 项目中，需要安装和配置 sorry-cypress：

```bash
npm install --save-dev sorry-cypress
```

在 `cypress.config.js` 中添加：

```javascript
const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
  },
  env: {
    sorryCypressUrl: 'http://localhost:1234'
  }
})
```

## 故障排除

### 端口冲突
如果遇到端口冲突，可以修改 `docker-compose.local.yml` 中的端口映射。

### 服务无法启动
检查 Docker 是否正在运行，并确保端口没有被其他服务占用。

### 数据丢失
数据存储在 `./data/` 目录中，重启服务不会丢失数据。如果需要重置，可以删除该目录。

## 开发模式

如果您想要进行开发，可以使用以下命令启动开发模式：

```bash
# 安装依赖
yarn install

# 启动开发模式
yarn dev
```

这将启动所有服务的开发版本，支持热重载。 

### usage
 To migrate with cypress 13.xx
https://docs.currents.dev/resources/reporters/cypress-cloud/migration-to-cypress-13
