# 🚀 Zeabur 部署快速修复指南

## ⚠️ 问题诊断

您遇到的错误：
```
Error: Cannot find module 'tailwindcss'
```

**根本原因：** Zeabur 没有使用您的 `Dockerfile.api`，而是使用了默认的 Node.js 构建流程，导致依赖安装不完整。

**证据：** 错误日志显示路径为 `/src/node_modules`，而您的 Dockerfile 使用 `/app`。

---

## ✅ 解决方案（已完成）

### 1. 创建标准 Dockerfile ✅
已将 `Dockerfile.api` 复制为 `Dockerfile`，Zeabur 会自动检测。

### 2. 创建 zbpack.json ✅
配置文件告诉 Zeabur 使用 Dockerfile 构建。

### 3. 创建 .dockerignore ✅
优化构建上下文，排除不必要的文件。

---

## 🎯 立即行动（3 步）

### 步骤 1：提交所有更改到 Git

```bash
# 查看更改
git status

# 添加所有新文件
git add Dockerfile zbpack.json .dockerignore ZEABUR_CONFIG.md

# 提交
git commit -m "fix: 添加标准 Dockerfile 和 Zeabur 配置以修复构建问题"

# 推送到远程
git push origin main
```

### 步骤 2：在 Zeabur 控制台配置

#### A. 确认使用 Dockerfile 构建

1. 登录 [Zeabur 控制台](https://zeabur.com)
2. 进入您的项目
3. 点击"设置"或"Settings"
4. 找到"构建方式"或"Build Method"
5. **确保选择了"Docker"或"Dockerfile"**
6. 如果有 Dockerfile 路径选项，填写：`./Dockerfile`

#### B. 清除构建缓存

1. 在项目设置中找到"清除缓存"或"Clear Cache"
2. 点击清除
3. 确认操作

#### C. 设置环境变量（如果还没有）

必需的环境变量：
```bash
APP_DOMAIN=your-app.zeabur.app
DATABASE_URL=file:/app/data/dev.db
ANTHROPIC_API_KEY=your-key
```

### 步骤 3：重新部署

1. 点击"重新部署"或"Redeploy"按钮
2. 或者推送新的提交会自动触发部署

---

## 🔍 验证部署成功

### 查看构建日志

部署时，构建日志应该显示：

**✅ 正确的开始（使用 Dockerfile）：**
```
#1 [internal] load build definition from Dockerfile
#2 [internal] load .dockerignore
#3 [internal] load metadata for docker.io/library/node:22-alpine
```

**✅ 依赖安装成功：**
```
📦 Installing dependencies...
✅ package-lock.json found, using npm ci
✅ Dependencies installed successfully
📋 Checking for tailwindcss...
tailwindcss@3.4.17
```

**✅ 构建成功：**
```
Creating an optimized production build ...
✓ Compiled successfully
✓ Linting and checking validity of types
✓ Collecting page data
✓ Generating static pages
```

### ❌ 如果仍然看到错误

**错误日志显示 `/src` 路径：**
```
Error: Cannot find module 'tailwindcss'
Require stack:
  at async /src/node_modules/...
```

**说明：** Zeabur 仍在使用默认 Node.js 构建，没有使用 Dockerfile。

**解决方案：**
1. 在 Zeabur 控制台手动选择"Docker"构建方式
2. 确认 `Dockerfile` 文件已推送到 Git
3. 联系 Zeabur 支持

---

## 📋 文件清单

确保以下文件已提交到 Git：

- [x] `Dockerfile` - 标准 Dockerfile（从 Dockerfile.api 复制）
- [x] `Dockerfile.api` - 原始备份
- [x] `zbpack.json` - Zeabur 构建配置
- [x] `.dockerignore` - Docker 忽略文件
- [x] `package.json` - 项目依赖
- [x] `package-lock.json` - 锁定依赖版本

---

## 🆘 故障排除

### 问题 1：Zeabur 仍然使用默认构建

**症状：** 构建日志显示 "Detected Node.js project" 而不是 "load build definition from Dockerfile"

**解决方案：**
1. 确认 `Dockerfile` 在项目根目录（不是子目录）
2. 在 Zeabur 项目设置中手动选择"Docker"
3. 删除项目并重新导入（最后手段）

### 问题 2：找不到 package-lock.json

**症状：** 日志显示 "⚠️ package-lock.json not found"

**解决方案：**
```bash
# 确认文件存在
ls -la package-lock.json

# 如果不存在，重新生成
rm -rf node_modules package-lock.json
npm install

# 提交
git add package-lock.json
git commit -m "chore: 添加 package-lock.json"
git push
```

### 问题 3：tailwindcss 仍然找不到

**症状：** 日志显示 "⚠️ tailwindcss not found in node_modules"

**解决方案：**
```bash
# 本地测试 Docker 构建
docker build -f Dockerfile -t claudable:test .

# 如果本地构建成功，问题在 Zeabur 配置
# 如果本地构建失败，检查 package.json
```

---

## 🎉 成功标志

部署成功后，您应该能够：

1. ✅ 访问应用主页
2. ✅ 创建新项目
3. ✅ 选择 AI 模型（Claude、Qwen 等）
4. ✅ 生成代码
5. ✅ 预览生成的应用

---

## 📞 需要帮助？

### 提供以下信息

如果问题仍然存在，请提供：

1. **完整的构建日志**（从开始到错误）
2. **Git 仓库 URL**
3. **Zeabur 项目设置截图**
4. **本地 Docker 构建结果**：
   ```bash
   docker build -f Dockerfile -t claudable:test . 2>&1 | tee build.log
   ```

### 联系方式

- GitHub Issues
- Zeabur 支持
- 项目文档

---

## 📚 相关文档

- [ZEABUR_CONFIG.md](./ZEABUR_CONFIG.md) - 详细的 Zeabur 配置说明
- [DEPLOYMENT_TROUBLESHOOTING.md](./DEPLOYMENT_TROUBLESHOOTING.md) - 部署故障排除
- [DOCKERFILE_REVIEW.md](./DOCKERFILE_REVIEW.md) - Dockerfile 审查报告
- [ZEABUR_DEPLOYMENT.md](./ZEABUR_DEPLOYMENT.md) - Zeabur 部署指南

---

## ⏱️ 预计时间

- 提交代码：2 分钟
- Zeabur 配置：3 分钟
- 构建部署：5-10 分钟
- **总计：10-15 分钟**

---

## ✨ 下一步

部署成功后：

1. 测试所有功能
2. 配置自定义域名（可选）
3. 设置环境变量
4. 监控应用性能

祝您部署顺利！🚀
