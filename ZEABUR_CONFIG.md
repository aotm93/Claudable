# Zeabur 部署配置说明

## 🚨 重要：Zeabur 需要标准的 Dockerfile

Zeabur 会自动检测项目根目录下的 `Dockerfile`（不是 `Dockerfile.api`）。

## 📁 文件说明

- **`Dockerfile`** - Zeabur 使用的标准 Dockerfile（从 Dockerfile.api 复制）
- **`Dockerfile.api`** - 原始的 API Dockerfile（保留作为备份）
- **`zbpack.json`** - Zeabur 构建配置（可选）

## ⚙️ Zeabur 配置

### zbpack.json 配置

```json
{
  "build_command": "npm run build",
  "install_command": "npm ci || npm install",
  "start_command": "npm start"
}
```

这个文件告诉 Zeabur：
- 如何安装依赖
- 如何构建项目
- 如何启动应用

## 🔧 Zeabur 环境变量

在 Zeabur 控制台设置以下环境变量：

### 必需的环境变量

```bash
# 应用域名（用于预览 URL）
APP_DOMAIN=your-app.zeabur.app

# 数据库 URL（SQLite）
DATABASE_URL=file:/app/data/dev.db

# API 密钥
ANTHROPIC_API_KEY=sk-ant-xxx
OPENAI_API_KEY=sk-xxx
GLM_API_KEY=xxx
QWEN_API_KEY=xxx
```

### 可选的环境变量

```bash
# Node 环境
NODE_ENV=production

# 端口（Zeabur 会自动设置）
PORT=3000

# 预览端口范围
PREVIEW_PORT_START=3001
PREVIEW_PORT_END=3100

# 显式设置预览主机
PREVIEW_HOST=your-app.zeabur.app
```

## 🚀 部署步骤

### 1. 确保文件已提交

```bash
git add Dockerfile zbpack.json .dockerignore
git commit -m "feat: 添加 Zeabur 部署配置"
git push origin main
```

### 2. 在 Zeabur 控制台配置

1. **选择 Dockerfile 构建**
   - Zeabur 应该自动检测到 `Dockerfile`
   - 如果没有，手动选择"Docker"作为构建方式

2. **设置环境变量**
   - 进入项目设置 → 环境变量
   - 添加上述必需的环境变量

3. **清除缓存并重新部署**
   - 点击"清除缓存"
   - 触发新的部署

### 3. 验证部署

查看构建日志，应该看到：

```
📦 Installing dependencies...
✅ package-lock.json found, using npm ci
✅ Dependencies installed successfully
📋 Checking for tailwindcss...
tailwindcss@3.4.17

Creating an optimized production build ...
✓ Compiled successfully
```

## 🐛 故障排除

### 问题：Zeabur 仍然使用默认构建

**解决方案：**
1. 确认 `Dockerfile` 在项目根目录
2. 在 Zeabur 控制台手动选择"Docker"构建方式
3. 清除缓存并重新部署

### 问题：找不到 tailwindcss

**检查清单：**
- [ ] `Dockerfile` 存在于项目根目录
- [ ] `package-lock.json` 已提交到 Git
- [ ] Zeabur 使用的是 Dockerfile 而不是默认 Node.js 构建
- [ ] 构建日志显示依赖安装成功

### 问题：构建日志显示 /src 而不是 /app

这说明 Zeabur 没有使用您的 Dockerfile。

**解决方案：**
1. 在 Zeabur 项目设置中，找到"构建方式"或"Build Method"
2. 选择"Docker"或"Dockerfile"
3. 确认 Dockerfile 路径为 `./Dockerfile`

## 📊 Dockerfile 与默认构建的区别

### 使用 Dockerfile（推荐）

**优点：**
- ✅ 完全控制构建过程
- ✅ 多阶段构建，优化镜像大小
- ✅ 包含 Qwen CLI 安装
- ✅ 自定义启动脚本

**工作目录：** `/app`

### 使用默认 Node.js 构建

**缺点：**
- ❌ 无法自定义构建步骤
- ❌ 可能缺少必要的系统依赖
- ❌ 无法安装 Qwen CLI
- ❌ 依赖安装可能不完整

**工作目录：** `/src`（Zeabur 默认）

## 🔍 如何确认使用了 Dockerfile

查看构建日志的开头：

**使用 Dockerfile：**
```
#1 [internal] load build definition from Dockerfile
#2 [internal] load .dockerignore
#3 [internal] load metadata for docker.io/library/node:22-alpine
```

**使用默认构建：**
```
Detected Node.js project
Installing dependencies...
```

## 📝 更新 Dockerfile 后的操作

每次修改 Dockerfile 后：

```bash
# 1. 同步到标准 Dockerfile
cp Dockerfile.api Dockerfile

# 2. 提交更改
git add Dockerfile Dockerfile.api
git commit -m "chore: 更新 Dockerfile"
git push

# 3. 在 Zeabur 清除缓存并重新部署
```

## 🆘 仍然无法解决？

### 联系 Zeabur 支持

提供以下信息：
1. 完整的构建日志
2. 项目 Git 仓库 URL
3. Zeabur 项目 ID
4. 截图显示构建配置

### 备选方案

如果 Zeabur 持续出现问题，考虑：
1. **Vercel**：自动处理 Next.js 项目
2. **Railway**：支持 Dockerfile
3. **Render**：支持 Docker 部署
4. **Fly.io**：完整的 Docker 支持

## 📚 相关文档

- [Zeabur 官方文档](https://zeabur.com/docs)
- [Zeabur Docker 部署](https://zeabur.com/docs/deploy/dockerfile)
- [部署故障排除](./DEPLOYMENT_TROUBLESHOOTING.md)
- [Dockerfile 审查报告](./DOCKERFILE_REVIEW.md)
