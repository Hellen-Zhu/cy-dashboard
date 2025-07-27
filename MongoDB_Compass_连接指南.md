# MongoDB Compass 连接指南

## 📋 连接信息

### 本地 MongoDB 连接配置

| 配置项 | 值 |
|--------|-----|
| **连接字符串** | `mongodb://admin:password@localhost:27017` |
| **主机地址** | `localhost` |
| **端口** | `27017` |
| **用户名** | `admin` |
| **密码** | `password` |
| **认证数据库** | `admin` |
| **数据库名称** | `sorry-cypress` |

## 🔧 连接步骤

### 方法一：使用连接字符串（推荐）

1. 打开 MongoDB Compass
2. 在连接界面选择 "Advanced Connection Options"
3. 在 "Connection String" 字段中输入：
   ```
   mongodb://admin:password@localhost:27017
   ```
4. 点击 "Connect" 按钮

### 方法二：使用表单配置

1. 打开 MongoDB Compass
2. 选择 "Fill in connection fields individually"
3. 填写以下信息：
   - **Hostname**: `localhost`
   - **Port**: `27017`
   - **Authentication**: 选择 "Username/Password"
   - **Username**: `admin`
   - **Password**: `password`
   - **Authentication Database**: `admin`
4. 点击 "Connect" 按钮

## 📊 数据库结构

连接成功后，您将看到以下数据库：

### sorry-cypress 数据库
这是 Sorry Cypress 的主要数据库，包含以下集合：

#### 主要集合
- **instances** - 测试实例信息
- **projects** - 项目信息
- **runs** - 测试运行记录
- **specs** - 测试规格信息
- **runTimeouts** - 运行超时配置

#### 数据示例

**projects 集合示例**:
```json
{
  "_id": ObjectId("..."),
  "projectId": "your-project-id",
  "inactivityTimeoutMinutes": 10,
  "hooks": [],
  "createdAt": ISODate("2025-07-27T01:45:27.000Z"),
  "updatedAt": ISODate("2025-07-27T01:45:27.000Z")
}
```

**runs 集合示例**:
```json
{
  "_id": ObjectId("..."),
  "runId": "run-id",
  "projectId": "project-id",
  "status": "RUNNING",
  "createdAt": ISODate("2025-07-27T01:45:27.000Z"),
  "updatedAt": ISODate("2025-07-27T01:45:27.000Z"),
  "specs": [...],
  "meta": {...}
}
```

## 🔍 常用查询

### 查看所有项目
```javascript
db.projects.find({})
```

### 查看最近的测试运行
```javascript
db.runs.find({}).sort({createdAt: -1}).limit(10)
```

### 查看特定项目的运行
```javascript
db.runs.find({projectId: "your-project-id"})
```

### 查看失败的测试
```javascript
db.instances.find({results: {$elemMatch: {stats: {failures: {$gt: 0}}}}})
```

## 🛠️ 故障排除

### 连接失败
1. **检查 MongoDB 服务状态**:
   ```bash
   docker-compose -f docker-compose.local.yml ps mongo
   ```

2. **检查端口是否开放**:
   ```bash
   lsof -i :27017
   ```

3. **重启 MongoDB 服务**:
   ```bash
   docker-compose -f docker-compose.local.yml restart mongo
   ```

### 认证失败
1. **验证用户名密码**:
   - 用户名: `admin`
   - 密码: `password`
   - 认证数据库: `admin`

2. **检查认证配置**:
   ```bash
   docker-compose -f docker-compose.local.yml logs mongo
   ```

### 数据库不存在
1. **等待服务完全启动**:
   ```bash
   docker-compose -f docker-compose.local.yml logs mongo
   ```

2. **手动创建数据库**:
   在 Compass 中右键点击数据库列表，选择 "Create Database"

## 📈 监控和性能

### 查看数据库统计
```javascript
db.stats()
```

### 查看集合统计
```javascript
db.runs.stats()
db.instances.stats()
```

### 查看索引
```javascript
db.runs.getIndexes()
db.instances.getIndexes()
```

## 🔐 安全建议

1. **生产环境**:
   - 使用更强的密码
   - 启用 SSL/TLS 连接
   - 限制网络访问

2. **开发环境**:
   - 当前配置适合本地开发
   - 不要在生产环境使用默认密码

## 📚 相关资源

- [MongoDB Compass 官方文档](https://docs.mongodb.com/compass/)
- [MongoDB 查询语言](https://docs.mongodb.com/manual/reference/method/)
- [Sorry Cypress 数据库结构](https://docs.sorry-cypress.dev/)

---

**连接配置时间**: 2025-07-27  
**MongoDB 版本**: 4.4  
**Compass 版本**: 1.46.6 