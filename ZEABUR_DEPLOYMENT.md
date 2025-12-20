# Zeabur 部署指南

## 快速修复：预览显示 "localhost 拒绝链接"

### 问题原因

在 Zeabur 上部署后，前端预览 iframe 尝试访问 `http://localhost:3000`，但浏览器无法访问到 Zeabur 服务器上的预览端口。

### 解决方案

#### 步骤 1：获取 Zeabur 域名

1. 登录 [Zeabur 控制台](https://zeabur.com)
2. 进入您的项目
3. 点击 "Domains" 或 "域名" 标签
4. 复制分配的域名（例如：`my-app-abc123.zeabur.app`）

#### 步骤 2：配置环境变量

在 Zeabur 项目设置中添加以下环境变量：

```bash
APP_DOMAIN=your-app.zeabur.app
NODE_ENV=production
```

**重要**：将 `your-app.zeabur.app` 替换为您在步骤 1 中获取的实际域名。

#### 步骤 3：重新部署

1. 保存环境变量后，Zeabur 会自动触发重新部署
2. 或者，您可以推送新的提交到仓库触发部署

#### 步骤 4：验证修复

1. 等待部署完成
2. 访问您的应用
3. 创建或打开一个项目
4. 检查预览面板是否正常显示

---

## 完整部署配置

### 必需的环境变量

```bash
# 应用域名（必需）
APP_DOMAIN=your-app.zeabur.app

# 运行环境
NODE_ENV=production

# 数据库 URL（如果使用 Prisma）
DATABASE_URL=postgresql://user:password@host:port/database

# API 密钥（根据您的配置）
ANTHROPIC_API_KEY=your-anthropic-key
OPENAI_API_KEY=your-openai-key
GLM_API_KEY=your-glm-key
QWEN_API_KEY=your-qwen-key
```

### 可选的环境变量

```bash
# 显式设置预览主机（覆盖自动检测）
PREVIEW_HOST=your-app.zeabur.app

# 预览端口范围
PREVIEW_PORT_START=3001
PREVIEW_PORT_END=3100

# 应用端口（Zeabur 通常自动设置）
PORT=3000
```

---

## 架构说明

### 端口分配

- **主应用端口**：3000（或 `PORT` 环境变量）
- **预览端口范围**：3001-3100（可通过 `PREVIEW_PORT_START` 和 `PREVIEW_PORT_END` 配置）

### URL 生成逻辑

系统按以下优先级生成预览 URL：

1. `PREVIEW_HOST` 环境变量（最高优先级）
2. Zeabur 自动检测（`ZEABUR=1` + `ZEABUR_URL`）
3. `APP_DOMAIN` 环境变量
4. 生产环境回退（`NODE_ENV=production` 时使用 `0.0.0.0`）
5. `localhost`（仅用于本地开发）

### 预览服务器工作原理

1. 用户在对话中请求生成或修改项目
2. AI 生成代码并保存到项目目录
3. 系统自动启动 Next.js 开发服务器（`npm run dev`）
4. 预览服务器监听动态分配的端口（例如 3001）
5. 前端 iframe 加载预览 URL：`http://your-app.zeabur.app:3001`

---

## 故障排除

### 问题 1：预览仍然显示 "localhost 拒绝连接"

**检查清单：**

- [ ] 确认 `APP_DOMAIN` 环境变量已设置
- [ ] 确认域名与 Zeabur 分配的域名一致
- [ ] 确认应用已重新部署
- [ ] 检查浏览器控制台是否有错误信息

**调试步骤：**

1. 打开浏览器开发者工具（F12）
2. 切换到 "Network" 标签
3. 查找 iframe 请求
4. 检查 iframe 的 `src` 属性是否仍然是 `localhost`
5. 如果是，说明环境变量未生效，需要重新部署

### 问题 2：预览加载缓慢或超时

**可能原因：**

- 预览服务器启动时间较长
- 依赖安装失败
- 端口被占用

**解决方案：**

1. 查看应用日志，搜索 `[PreviewManager]` 关键字
2. 检查是否有依赖安装错误
3. 尝试重启预览服务器（点击 Stop 然后 Play）

### 问题 3：跨域访问被拒绝

**解决方案：**

iframe 已配置了必要的跨域属性，但如果仍有问题：

1. 确认 Zeabur 域名配置正确
2. 检查是否有自定义的 CORS 配置
3. 确认预览服务器正确启动

### 问题 4：端口冲突

**症状：**
- 预览服务器无法启动
- 日志显示 "port already in use"

**解决方案：**

配置不同的端口范围：

```bash
PREVIEW_PORT_START=4001
PREVIEW_PORT_END=4100
```

---

## 性能优化

### 1. 使用构建缓存

在 `Dockerfile.api` 中已配置多阶段构建，确保：

```dockerfile
# 缓存依赖层
COPY package*.json ./
RUN npm install

# 缓存 Prisma 生成
COPY prisma ./prisma/
RUN npx prisma generate
```

### 2. 预热依赖

在应用启动时自动安装依赖，避免首次预览时等待：

```typescript
// 已在代码中实现
await previewManager.installDependencies(projectId);
```

### 3. 限制日志大小

预览服务器日志会自动限制大小（默认 1000 行），避免内存溢出。

---

## 安全建议

### 1. 环境变量保护

不要在代码中硬编码敏感信息，使用 Zeabur 的环境变量功能。

### 2. 端口访问控制

预览端口仅用于内部访问，不应暴露给公网。Zeabur 会自动处理端口映射。

### 3. 资源限制

考虑限制每个项目的预览服务器数量，避免资源耗尽：

```typescript
// 可以在代码中添加限制
const MAX_PREVIEW_SERVERS = 10;
```

---

## 相关文档

- [完整预览配置指南](./PREVIEW_URL_CONFIG.md)
- [Zeabur 官方文档](https://zeabur.com/docs)
- [Next.js 部署指南](https://nextjs.org/docs/deployment)

---

## 支持

如果问题仍未解决，请：

1. 查看应用日志（Zeabur 控制台 → Logs）
2. 检查 GitHub Issues
3. 联系技术支持
