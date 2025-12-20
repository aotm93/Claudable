# 部署故障排除指南

## 🚨 当前问题：tailwindcss 模块找不到

### 错误信息
```
Error: Cannot find module 'tailwindcss'
Require stack:
  at async /src/node_modules/next/dist/build/webpack/config/blocks/css/index.js:125:36
```

### 问题原因

1. **依赖安装被跳过**：`npm ci` 或 `npm install` 没有正确执行
2. **devDependencies 未安装**：`tailwindcss` 在 `devDependencies` 中，构建时需要
3. **缓存问题**：Docker 层缓存可能导致旧的依赖状态

---

## ✅ 已实施的修复

### 1. 优化依赖安装逻辑

**修改前：**
```dockerfile
RUN npm ci || npm install
```

**修改后：**
```dockerfile
RUN echo "📦 Installing dependencies..." && \
    if [ -f package-lock.json ]; then \
      echo "✅ package-lock.json found, using npm ci" && \
      npm ci; \
    else \
      echo "⚠️  package-lock.json not found, using npm install" && \
      npm install; \
    fi && \
    echo "✅ Dependencies installed successfully" && \
    echo "📋 Checking for tailwindcss..." && \
    npm list tailwindcss || echo "⚠️  tailwindcss not found in node_modules"
```

**改进点：**
- ✅ 添加详细日志输出
- ✅ 检查 `package-lock.json` 是否存在
- ✅ 验证 `tailwindcss` 是否安装成功
- ✅ 更好的错误诊断

### 2. 创建 .dockerignore 文件

**目的：**
- 排除不必要的文件（如 `node_modules`、`.next`）
- 确保 `package.json` 和 `package-lock.json` 被正确复制
- 减小构建上下文大小，加快构建速度

**内容：**
```
# Dependencies
node_modules

# Next.js
.next
out

# Keep these files for build
!package.json
!package-lock.json
```

---

## 🔧 立即行动步骤

### 步骤 1：清除 Zeabur 构建缓存

在 Zeabur 控制台：
1. 进入项目设置
2. 找到"清除缓存"或"Clear Cache"选项
3. 点击清除构建缓存
4. 重新触发部署

**为什么需要清除缓存？**
- Docker 层缓存可能保留了旧的、不完整的 `node_modules`
- 清除缓存确保从头开始构建

### 步骤 2：验证文件已提交

确保以下文件已提交到 Git：
```bash
git status
git add Dockerfile.api .dockerignore
git commit -m "fix: 修复 Docker 构建依赖安装问题"
git push origin main
```

### 步骤 3：检查构建日志

重新部署后，查看构建日志中的关键信息：

**应该看到：**
```
📦 Installing dependencies...
✅ package-lock.json found, using npm ci
✅ Dependencies installed successfully
📋 Checking for tailwindcss...
tailwindcss@3.4.17
```

**如果看到：**
```
⚠️  package-lock.json not found, using npm install
```
说明 `package-lock.json` 没有被正确复制。

**如果看到：**
```
⚠️  tailwindcss not found in node_modules
```
说明依赖安装失败。

---

## 🐛 如果问题仍然存在

### 方案 A：确保 package-lock.json 存在

在本地运行：
```bash
# 删除旧的 node_modules 和 lock 文件
rm -rf node_modules package-lock.json

# 重新安装依赖
npm install

# 提交新的 package-lock.json
git add package-lock.json
git commit -m "chore: 更新 package-lock.json"
git push
```

### 方案 B：强制使用 npm install

如果 `npm ci` 持续失败，修改 Dockerfile：

```dockerfile
# 强制使用 npm install（不推荐，但可以作为临时方案）
RUN npm install --verbose
```

### 方案 C：将 tailwindcss 移到 dependencies

修改 `package.json`：

```json
{
  "dependencies": {
    // ... 其他依赖
    "tailwindcss": "^3.4.17",
    "postcss": "^8.4.49",
    "autoprefixer": "^10.4.20"
  }
}
```

**注意：** 这不是最佳实践，但可以确保构建时这些包可用。

---

## 📊 完整的 Dockerfile 审查

### 当前 Dockerfile.api 结构

```dockerfile
# Stage 1: 构建
FROM node:22-alpine AS builder
WORKDIR /app

# 1. 安装系统依赖
RUN apk add --no-cache libc6-compat

# 2. 复制 package 文件
COPY package*.json ./
COPY prisma ./prisma/

# 3. 安装依赖（包括 devDependencies）
RUN echo "📦 Installing dependencies..." && \
    if [ -f package-lock.json ]; then \
      echo "✅ package-lock.json found, using npm ci" && \
      npm ci; \
    else \
      echo "⚠️  package-lock.json not found, using npm install" && \
      npm install; \
    fi && \
    echo "✅ Dependencies installed successfully" && \
    echo "📋 Checking for tailwindcss..." && \
    npm list tailwindcss || echo "⚠️  tailwindcss not found in node_modules"

# 4. 生成 Prisma 客户端
RUN npx prisma generate

# 5. 复制源代码
COPY . .

# 6. 构建 Next.js 应用
RUN npm run build

# Stage 2: 运行
FROM node:22-alpine AS runner
# ... 运行时配置
```

### 关键点

1. ✅ **分阶段构建**：builder 和 runner 分离
2. ✅ **依赖缓存**：先复制 package 文件，再复制源代码
3. ✅ **包含 devDependencies**：构建时需要
4. ✅ **详细日志**：便于调试
5. ✅ **验证安装**：检查关键依赖

---

## 🔍 调试技巧

### 本地测试 Docker 构建

```bash
# 构建镜像
docker build -f Dockerfile.api -t claudable:test .

# 如果构建失败，查看具体步骤
docker build -f Dockerfile.api -t claudable:test . --progress=plain

# 进入构建阶段调试
docker build -f Dockerfile.api --target builder -t claudable:builder .
docker run -it claudable:builder sh

# 在容器内检查
ls -la
cat package.json
ls -la node_modules/tailwindcss
```

### 检查 Zeabur 环境

在 Zeabur 控制台查看：
1. **环境变量**：确保没有设置 `NODE_ENV=production`（构建时）
2. **构建命令**：确认使用的是 `Dockerfile.api`
3. **Node 版本**：确认使用 Node 22

---

## 📝 环境变量配置

### 必需的环境变量（Zeabur）

```bash
# 应用域名（用于预览 URL）
APP_DOMAIN=your-app.zeabur.app

# 数据库 URL
DATABASE_URL=file:/app/data/dev.db

# API 密钥
ANTHROPIC_API_KEY=your-key
OPENAI_API_KEY=your-key
GLM_API_KEY=your-key
QWEN_API_KEY=your-key
```

### 可选的环境变量

```bash
# 预览端口范围
PREVIEW_PORT_START=3001
PREVIEW_PORT_END=3100

# 显式设置预览主机
PREVIEW_HOST=your-app.zeabur.app
```

---

## ✅ 成功部署的标志

构建日志应该显示：

```
✅ package-lock.json found, using npm ci
✅ Dependencies installed successfully
📋 Checking for tailwindcss...
tailwindcss@3.4.17

✓ Compiled successfully
✓ Linting and checking validity of types
✓ Collecting page data
✓ Generating static pages
✓ Finalizing page optimization

Route (app)                              Size     First Load JS
┌ ○ /                                    ...      ...
└ ○ /[project_id]/chat                   ...      ...

○  (Static)  prerendered as static content
```

---

## 🆘 仍然无法解决？

### 联系支持

提供以下信息：
1. 完整的构建日志
2. `package.json` 内容
3. 是否有 `package-lock.json`
4. Zeabur 项目配置截图

### 临时解决方案

如果急需部署，可以考虑：
1. 使用 Vercel 或 Netlify（自动处理 Next.js 构建）
2. 使用 Docker Compose 本地部署
3. 使用传统的 VPS + PM2 部署

---

## 📚 相关文档

- [Dockerfile.api 审查报告](./DOCKERFILE_REVIEW.md)
- [Zeabur 部署指南](./ZEABUR_DEPLOYMENT.md)
- [预览 URL 配置](./PREVIEW_URL_CONFIG.md)
- [Next.js Docker 部署](https://nextjs.org/docs/deployment#docker-image)
- [Zeabur 文档](https://zeabur.com/docs)

---

## 📅 更新日志

- **2025-12-20**：添加详细的依赖安装日志
- **2025-12-20**：创建 .dockerignore 文件
- **2025-12-20**：修复 Qwen CLI 安装方式（npm 包）
- **2025-12-20**：添加预览 URL 环境检测（Zeabur 支持）
