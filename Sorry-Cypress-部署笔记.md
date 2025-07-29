# Sorry Cypress 阿里云部署笔记

## 📋 项目概述

Sorry Cypress 是一个开源的 Cypress 测试结果管理平台，提供测试结果存储、视频录制、截图管理等功能。

## 🎯 部署目标

在阿里云 ECS 服务器上部署 Sorry Cypress，支持：
- 测试结果存储和管理
- 视频录制和播放
- 截图查看
- 多项目支持

## 🛠️ 环境准备

### 系统要求
- 阿里云 ECS 服务器 (Ubuntu/CentOS)
- Docker 和 Docker Compose
- 至少 2GB 内存
- 至少 20GB 存储空间

### 本地环境
- macOS/Linux 系统
- Docker Desktop
- SSH 客户端

## 🚀 部署步骤

### 1. 环境准备

```bash
# 创建 Docker buildx 构建器
docker buildx create --use --name tmpbuilder || true
docker buildx use tmpbuilder
docker buildx inspect --bootstrap
```

### 2. 构建 AMD64 镜像

```bash
# 拉取镜像
docker pull --platform linux/amd64 agoldis/sorry-cypress-director:latest
docker pull --platform linux/amd64 agoldis/sorry-cypress-api:latest
docker pull --platform linux/amd64 agoldis/sorry-cypress-dashboard:latest

# 保存为 tar 文件
docker save --platform linux/amd64 -o sorry-cypress-director.tar agoldis/sorry-cypress-director:latest
docker save --platform linux/amd64 -o sorry-cypress-api.tar agoldis/sorry-cypress-api:latest
docker save --platform linux/amd64 -o sorry-cypress-dashboard.tar agoldis/sorry-cypress-dashboard:latest
```

### 3. 上传到阿里云

```bash
# 创建远程目录
ssh root@47.97.45.91 "mkdir -p /opt/sorry-cypress"

# 上传镜像文件
scp sorry-cypress-*.tar root@47.97.45.91:/opt/sorry-cypress/

# 上传配置文件
scp docker-compose-ecs.yml root@47.97.45.91:/opt/sorry-cypress/docker-compose.yml
```

### 4. 部署服务

```bash
# 加载镜像
ssh root@47.97.45.91 "cd /opt/sorry-cypress && docker load -i sorry-cypress-director.tar && docker load -i sorry-cypress-api.tar && docker load -i sorry-cypress-dashboard.tar"

# 启动服务
ssh root@47.97.45.91 "cd /opt/sorry-cypress && docker compose up -d"
```

## 📁 配置文件

### docker-compose.yml

```yaml
version: '3.8'

services:
  mongo:
    image: mongo:4.4
    environment:
      MONGO_INITDB_ROOT_USERNAME: 'admin'
      MONGO_INITDB_ROOT_PASSWORD: 'password123'
    volumes:
      - ./data/mongo:/data/db
    ports:
      - "27017:27017"
    restart: unless-stopped
    networks:
      - sorry-cypress-network

  director:
    image: agoldis/sorry-cypress-director:latest
    environment:
      DASHBOARD_URL: http://47.97.45.91:8080
      EXECUTION_DRIVER: '../execution/mongo/driver'
      MONGODB_URI: 'mongodb://admin:password123@mongo:27017'
      MONGODB_DATABASE: 'sorry-cypress'
      SCREENSHOTS_DRIVER: '../screenshots/minio.driver'
      MINIO_ACCESS_KEY: 'minioadmin'
      MINIO_SECRET_KEY: 'password123'
      MINIO_ENDPOINT: '47.97.45.91'
      MINIO_URL: 'http://47.97.45.91'
      MINIO_PORT: '9000'
      MINIO_USESSL: 'false'
      MINIO_BUCKET: sorry-cypress
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
      MONGODB_URI: 'mongodb://admin:password123@mongo:27017'
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
      MINIO_ROOT_PASSWORD: 'password123'
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
      /usr/bin/mc alias set myminio http://localhost:9000 minioadmin password123;
      /usr/bin/mc mb myminio/sorry-cypress || true;
      /usr/bin/mc anonymous set download myminio/sorry-cypress;
      /usr/bin/mc anonymous set public myminio/sorry-cypress;
      exit 0;
      "

networks:
  sorry-cypress-network:
    driver: bridge
```

## 🔧 遇到的问题和解决方案

### 问题 1：网络连接超时

**现象：**
```
Error response from daemon: failed to solve: DeadlineExceeded: failed to fetch oauth token
```

**原因：** Docker Hub 网络连接问题

**解决方案：**
- 使用 `--platform linux/amd64` 参数
- 配置国内镜像源
- 使用代理网络

### 问题 2：端口冲突

**现象：**
```
Error response from daemon: failed to set up container networking: Bind for :::9000 failed: port is already allocated
```

**原因：** 端口被其他容器占用

**解决方案：**
```bash
# 停止所有容器
ssh root@47.97.45.91 "docker stop \$(docker ps -q)"

# 删除所有容器
ssh root@47.97.45.91 "docker rm \$(docker ps -aq)"
```

### 问题 3：Dashboard 无法连接 API

**现象：** Dashboard 显示 "Failed to fetch" 错误

**原因：** GraphQL 配置错误

**解决方案：**
```bash
# 修改配置文件
sed -i 's|GRAPHQL_SCHEMA_URL: http://localhost:4000|GRAPHQL_SCHEMA_URL: http://api:4000|' docker-compose.yml

# 重启服务
docker compose restart dashboard
```

### 问题 4：MongoDB runs 集合为空

**现象：** 有 instances 数据但没有 runs 数据

**原因：** Run 记录没有自动创建

**解决方案：**
```bash
# 手动创建 run 记录
docker exec sorry-cypress-mongo-1 mongosh --username admin --password password123 --authenticationDatabase admin sorry-cypress --eval 'db.instances.aggregate([{\$group: {_id: "\$runId", projectId: {\$first: "\$projectId"}, instances: {\$push: "\$_id"}, createdAt: {\$min: "\$_id"}}}, {\$project: {runId: "\$_id", projectId: 1, instances: 1, createdAt: 1, _id: 0}}]).forEach(function(doc) { db.runs.insertOne(doc); })'
```

### 问题 5：MinIO 访问权限问题

**现象：** 视频和截图无法访问，显示 "Access Denied"

**原因：** MinIO 权限配置问题

**解决方案：**
```bash
# 设置 MinIO 为公开访问
docker exec sorry-cypress-minio-1 mc anonymous set public myminio/sorry-cypress

# 设置下载权限
docker exec sorry-cypress-minio-1 mc anonymous set download myminio/sorry-cypress
```

### 问题 6：GraphQL 字段名错误

**现象：** GraphQL 查询返回字段不存在错误

**原因：** 使用了错误的字段名

**解决方案：**
```graphql
# 正确的查询语法
query {
  projects {
    _id
    projectId
    createdAt
    updatedAt
  }
}
```

## 📊 服务配置

### 端口映射

| 服务 | 端口 | 说明 |
|------|------|------|
| Dashboard | 8080 | Web 界面 |
| API | 4000 | GraphQL API |
| Director | 1234 | 测试执行服务 |
| MinIO API | 9000 | 文件存储 API |
| MinIO Console | 9090 | MinIO 管理界面 |
| MongoDB | 27017 | 数据库 |

### 访问地址

- **Dashboard**: http://47.97.45.91:8080
- **API**: http://47.97.45.91:4000
- **Director**: http://47.97.45.91:1234
- **MinIO Console**: http://47.97.45.91:9090

### 数据库连接

```bash
# MongoDB 连接字符串
mongodb://admin:password123@47.97.45.91:27017/sorry-cypress

# MinIO 连接信息
Access Key: minioadmin
Secret Key: password123
Endpoint: http://47.97.45.91:9000
```

## 🔍 常用命令

### 服务管理

```bash
# 启动服务
docker compose up -d

# 停止服务
docker compose down

# 重启服务
docker compose restart

# 查看服务状态
docker ps

# 查看服务日志
docker logs sorry-cypress-dashboard-1
docker logs sorry-cypress-api-1
docker logs sorry-cypress-director-1
```

### 数据库操作

```bash
# 连接 MongoDB
docker exec -it sorry-cypress-mongo-1 mongosh --username admin --password password123 --authenticationDatabase admin sorry-cypress

# 查看集合
show collections

# 查看数据
db.runs.find().pretty()
db.instances.find().pretty()
db.projects.find().pretty()
```

### MinIO 操作

```bash
# 连接 MinIO
docker exec -it sorry-cypress-minio-1 mc alias set myminio http://localhost:9000 minioadmin password123

# 查看文件
docker exec -it sorry-cypress-minio-1 mc ls myminio/sorry-cypress

# 设置权限
docker exec -it sorry-cypress-minio-1 mc anonymous set public myminio/sorry-cypress
```

## 📝 GraphQL 查询示例

### 查询项目

```graphql
query {
  projects {
    _id
    projectId
    createdAt
    updatedAt
  }
}
```

### 查询运行

```graphql
query {
  runs {
    _id
    runId
    projectId
    meta {
      ciBuildId
      projectId
    }
    progress {
      updatedAt
      status
    }
  }
}
```

### 查询实例

```graphql
query {
  instances {
    _id
    instanceId
    spec
    results {
      stats {
        tests
        passes
        failures
      }
    }
  }
}
```

### 查询测试

```graphql
query {
  tests {
    _id
    title
    state
    error {
      message
    }
  }
}
```

## 🎯 客户端配置

### Cypress 配置

```javascript
// cypress.config.js
module.exports = {
  e2e: {
    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
    env: {
      CYPRESS_API_URL: 'http://47.97.45.91:1234'
    }
  }
}
```

### 环境变量

```bash
# .env 文件
CYPRESS_API_URL=http://47.97.45.91:1234
CYPRESS_PROJECT_ID=your-project-id
```

## 🔒 安全配置

### 防火墙设置

```bash
# 开放必要端口
ufw allow 8080
ufw allow 4000
ufw allow 1234
ufw allow 9000
ufw allow 9090
ufw allow 27017
```

### 数据库安全

```bash
# 修改默认密码
# 在 docker-compose.yml 中修改 MONGO_INITDB_ROOT_PASSWORD
# 在 docker-compose.yml 中修改 MINIO_ROOT_PASSWORD
```

## 📈 监控和维护

### 日志监控

```bash
# 查看实时日志
docker logs -f sorry-cypress-dashboard-1
docker logs -f sorry-cypress-api-1
docker logs -f sorry-cypress-director-1
```

### 性能监控

```bash
# 查看容器资源使用
docker stats

# 查看磁盘使用
df -h

# 查看内存使用
free -h
```

### 备份策略

```bash
# 备份 MongoDB 数据
docker exec sorry-cypress-mongo-1 mongodump --username admin --password password123 --authenticationDatabase admin --db sorry-cypress --out /backup

# 备份 MinIO 数据
docker exec sorry-cypress-minio-1 mc mirror myminio/sorry-cypress /backup/minio
```

## 🎉 部署完成

恭喜！Sorry Cypress 已成功部署并运行。现在您可以：

1. 访问 Dashboard 查看测试结果
2. 配置 Cypress 客户端连接到 Director
3. 执行测试并查看结果
4. 查看测试视频和截图

## 📞 故障排除

如果遇到问题，请按以下步骤排查：

1. 检查服务状态：`docker ps`
2. 查看服务日志：`docker logs <container-name>`
3. 检查网络连接：`netstat -tlnp`
4. 检查数据库连接：MongoDB 和 MinIO
5. 查看配置文件：确保所有配置正确

---

**最后更新：** 2025-07-27  
**版本：** 1.0.0  
**作者：** AI Assistant 