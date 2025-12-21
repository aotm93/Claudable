# Zeabur 部署指导 - Claudable 项目

## 🚀 快速部署步骤

### 1. 确认修复已应用
✅ **双重修复方案已应用**：

**Dockerfile 修复**：
- 使用 `npm install --include=dev` 确保安装 devDependencies
- 添加 Qwen CLI 符号链接处理
- 添加 `gcompat` 系统包
- 优化运行时依赖复制

**Package.json 修复**：
- 将关键构建依赖移到 `dependencies`：
  - `tailwindcss`: `^3.4.17`
  - `postcss`: `^8.4.49`
  - `autoprefixer`: `^10.4.20`

### 2. 提交更改到 Git
```bash
git add Dockerfile package.json
git commit -m "fix: 修复 Zeabur 部署中的 tailwindcss 和 Qwen CLI 问题

- 将 tailwindcss、postcss、autoprefixer 移到 dependencies
- 使用 npm install --include=dev 确保安装 devDependencies
- 添加 Qwen CLI 符号链接 qwen-code -> qwen
- 复制必要的 Prisma 运行时文件
- 添加 gcompat 系统包提供兼容性"
git push origin main
```

### 3. 在 Zeabur 控制台操作
1. **登录 Zeabur Dashboard**: https://dash.zeabur.com
2. **选择您的项目**
3. **清除构建缓存**:
   - 进入项目设置 (Settings)
   - 点击"清除缓存"或"Clear Cache"
   - 确认操作
4. **重新部署**:
   - 返回项目概览
   - 点击"重新部署"或推送新 commit 自动触发

### 4. 监控构建日志
查看构建日志中的关键成功信息：
```
📦 Installing all dependencies (including devDependencies)...
✅ Dependencies installed successfully
📋 Verifying critical build dependencies...
tailwindcss@3.4.17
✅ All critical build dependencies verified

📦 Installing Qwen CLI...
✅ Qwen CLI npm package installed
Creating symlink: qwen-code -> qwen
✅ qwen command is available

Creating an optimized production build ...
✓ Compiled successfully
```

## 🔍 验证部署成功

### 应用功能检查
- [ ] 主页正确加载，Tailwind CSS 样式完整
- [ ] 可以创建新项目
- [ ] 所有 AI 模型（Claude、Cursor、Qwen 等）可选择
- [ ] 聊天功能正常工作
- [ ] 预览功能可用

## 🆘 如果仍有问题

### 常见问题解决
1. **仍然看到 tailwindcss 错误**:
   - 确认 Zeabur 使用的是 Dockerfile 而不是默认 Node.js 构建
   - 检查构建日志是否显示 `#1 [internal] load build definition from Dockerfile`

2. **Qwen CLI 不可用**:
   - 查看构建日志中的 Qwen CLI 安装部分
   - 确认看到 "✅ qwen command is available"

3. **构建仍然失败**:
   - 联系支持并提供完整构建日志
   - 参考详细的故障排除指南: [`plans/zeabur-deployment-fix-plan.md`](plans/zeabur-deployment-fix-plan.md)

## 📞 获取帮助
- **详细修复方案**: [`plans/zeabur-deployment-fix-plan.md`](plans/zeabur-deployment-fix-plan.md)
- **Dockerfile 审查报告**: [`DOCKERFILE_REVIEW.md`](DOCKERFILE_REVIEW.md)
- **部署故障排除**: [`DEPLOYMENT_TROUBLESHOOTING.md`](DEPLOYMENT_TROUBLESHOOTING.md)