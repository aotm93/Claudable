# Zeabur 部署修复方案

## 🚨 问题诊断

### 错误信息分析
```
Error: Cannot find module 'tailwindcss'
Require stack: at async /src/node_modules/next/dist/build/webpack/config/blocks/css/index.js:125:36
```

### 根本原因
1. **依赖安装不完整**：`tailwindcss` 在 `devDependencies` 中，构建时需要但可能被跳过
2. **Qwen CLI 安装问题**：npm 包名与可执行文件名不匹配
3. **Docker 构建缓存**：可能使用了不完整的缓存层

## 🔧 完整的修复 Dockerfile

### 改进的 Dockerfile 内容

```dockerfile
# ==================================
# Stage 1: 构建
# ==================================
FROM node:22-alpine AS builder

WORKDIR /app

# 安装系统依赖
RUN apk add --no-cache libc6-compat

# 复制 package 文件和 Prisma schema
COPY package*.json ./
COPY prisma ./prisma/

# 🔧 修复：强制安装所有依赖，包括 devDependencies
# 这是构建阶段，需要 tailwindcss、postcss、autoprefixer 等构建工具
RUN echo "📦 Installing all dependencies (including devDependencies)..." && \
    npm install --include=dev && \
    echo "✅ Dependencies installed successfully" && \
    echo "📋 Verifying critical build dependencies..." && \
    npm list tailwindcss postcss autoprefixer && \
    echo "✅ All critical build dependencies verified"

# 生成 Prisma 客户端
RUN npx prisma generate

# 复制源代码
COPY . .

# 构建 Next.js 应用
RUN npm run build

# ==================================
# Stage 2: 运行
# ==================================
FROM node:22-alpine AS runner

WORKDIR /app

# 安装运行时系统依赖
RUN apk add --no-cache \
    libc6-compat \
    curl \
    bash \
    gcompat

# 🔧 修复：正确安装 Qwen CLI
# 安装 npm 包并确保可执行文件名正确
RUN echo "📦 Installing Qwen CLI..." && \
    npm install -g @qwen-code/qwen-code@latest && \
    echo "✅ Qwen CLI npm package installed" && \
    echo "🔍 Checking available executables..." && \
    (which qwen-code && echo "Found qwen-code executable") || echo "qwen-code not found" && \
    (which qwen && echo "Found qwen executable") || echo "qwen not found" && \
    # 创建符号链接确保 'qwen' 命令可用
    if which qwen-code > /dev/null 2>&1; then \
        echo "Creating symlink: qwen-code -> qwen"; \
        ln -sf $(which qwen-code) /usr/local/bin/qwen; \
    fi && \
    # 验证最终的 qwen 命令
    which qwen && echo "✅ qwen command is available" || \
    (echo "❌ ERROR: qwen command not available after installation" && exit 1)

# 设置环境变量
ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# 复制构建产物
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

# 复制 Prisma 相关文件
COPY --from=builder /app/prisma ./prisma

# 🔧 修复：复制运行时需要的 node_modules
# 包含 Prisma 客户端和其他运行时依赖
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma

# 复制启动脚本
COPY --from=builder /app/start.sh ./start.sh
RUN chmod +x /app/start.sh

# 创建数据目录
RUN mkdir -p /app/data

# 暴露端口
EXPOSE 3000

# 启动应用
CMD ["/app/start.sh"]
```

## 🔧 关键修复点

### 修复 1：依赖安装逻辑
**问题：** 当前使用 `npm install` 可能跳过 `devDependencies`
**解决：** 使用 `npm install --include=dev` 强制安装所有依赖

### 修复 2：Qwen CLI 安装
**问题：** npm 包名 `@qwen-code/qwen-code` 与代码期望的 `qwen` 命令不匹配
**解决：** 创建符号链接 `qwen-code -> qwen`

### 修复 3：运行时依赖
**问题：** Prisma 客户端在运行时缺失
**解决：** 复制必要的 `node_modules` 子目录

### 修复 4：系统兼容性
**问题：** Alpine Linux 与预编译二进制文件兼容性
**解决：** 添加 `gcompat` 包提供 glibc 兼容层

## 🚀 备选方案

### 方案 A：修改 package.json（如果 Dockerfile 修复不够）

将关键构建依赖移到 `dependencies`：

```json
{
  "dependencies": {
    // 现有依赖...
    "tailwindcss": "^3.4.17",
    "postcss": "^8.4.49",
    "autoprefixer": "^10.4.20"
  },
  "devDependencies": {
    // 其他开发依赖...
  }
}
```

### 方案 B：使用 npm ci（如果有锁文件问题）

```dockerfile
# 替代安装命令
RUN echo "📦 Installing dependencies with npm ci..." && \
    npm ci --include=dev && \
    echo "✅ Dependencies installed successfully"
```

## 📋 详细实施步骤

### 步骤 1：更新 Dockerfile

1. **备份当前 Dockerfile**
   ```bash
   cp Dockerfile Dockerfile.backup
   ```

2. **应用修复的 Dockerfile**
   - 将上述改进的 Dockerfile 内容替换当前的 [`Dockerfile`](Dockerfile)
   - 关键修复点：
     - 使用 `npm install --include=dev` 确保安装 devDependencies
     - 添加 Qwen CLI 符号链接 `qwen-code -> qwen`
     - 复制必要的 Prisma 运行时文件
     - 添加 `gcompat` 系统包

3. **提交更改**
   ```bash
   git add Dockerfile
   git commit -m "fix: 修复 Zeabur 部署中的 tailwindcss 和 Qwen CLI 问题"
   git push origin main
   ```

### 步骤 2：清除 Zeabur 缓存并重新部署

1. **进入 Zeabur 控制台**
   - 登录 [Zeabur Dashboard](https://dash.zeabur.com)
   - 选择您的项目

2. **清除构建缓存**
   - 进入项目设置 (Settings)
   - 找到"构建缓存"或"Build Cache"选项
   - 点击"清除缓存"或"Clear Cache"
   - 确认操作

3. **重新触发部署**
   - 返回项目概览页面
   - 点击"重新部署"或"Redeploy"
   - 或者推送新的 commit 自动触发部署

### 步骤 3：监控构建过程

1. **查看实时构建日志**
   - 在 Zeabur 控制台中点击"日志"或"Logs"
   - 选择"构建日志"或"Build Logs"

2. **关键检查点**
   - 确认使用了 Dockerfile 而不是默认 Node.js 构建
   - 查看依赖安装过程
   - 验证 Qwen CLI 安装

### 步骤 4：验证部署成功

1. **检查应用状态**
   - 确认容器状态为"运行中"
   - 检查应用 URL 是否可访问

2. **功能测试**
   - 访问应用主页
   - 创建测试项目
   - 尝试使用不同的 AI 模型
   - 验证 Tailwind CSS 样式

## 🔍 构建日志验证清单

### ✅ 成功的构建日志应包含：

**依赖安装阶段：**
```
📦 Installing all dependencies (including devDependencies)...
✅ Dependencies installed successfully
📋 Verifying critical build dependencies...
tailwindcss@3.4.17
postcss@8.4.49
autoprefixer@10.4.20
✅ All critical build dependencies verified
```

**Qwen CLI 安装阶段：**
```
📦 Installing Qwen CLI...
✅ Qwen CLI npm package installed
🔍 Checking available executables...
Found qwen-code executable
Creating symlink: qwen-code -> qwen
✅ qwen command is available
```

**Next.js 构建阶段：**
```
Creating an optimized production build ...
✓ Compiled successfully
✓ Linting and checking validity of types
✓ Collecting page data
✓ Generating static pages
✓ Finalizing page optimization
```

### ❌ 需要注意的错误信号：

- `Cannot find module 'tailwindcss'`
- `qwen command not available after installation`
- `ERROR: Critical dependencies missing`
- 构建过程中的任何 `exit code: 1`

## 🆘 详细故障排除指南

### 问题 1：依赖安装仍然失败

**症状：** 仍然看到 "Cannot find module 'tailwindcss'" 错误

**解决步骤：**
1. **检查 package-lock.json**
   ```bash
   # 本地验证
   ls -la package-lock.json
   git status package-lock.json
   ```

2. **重新生成锁文件**（如果需要）
   ```bash
   rm -rf node_modules package-lock.json
   npm install
   git add package-lock.json
   git commit -m "chore: 重新生成 package-lock.json"
   git push
   ```

3. **使用备选安装方法**
   - 修改 Dockerfile 使用 `npm ci --include=dev`
   - 或者将 tailwindcss 移到 dependencies

### 问题 2：Qwen CLI 不可用

**症状：** 应用启动但 Qwen 模型选择时报错

**解决步骤：**
1. **检查容器内的可执行文件**
   ```bash
   # 本地测试 Docker 镜像
   docker build -t claudable:test .
   docker run -it claudable:test sh
   # 在容器内执行
   which qwen
   which qwen-code
   ls -la /usr/local/bin/qwen*
   ```

2. **手动创建符号链接**（如果自动创建失败）
   ```dockerfile
   # 在 Dockerfile 中添加强制链接
   RUN ln -sf /usr/local/bin/qwen-code /usr/local/bin/qwen || \
       ln -sf $(npm root -g)/@qwen-code/qwen-code/bin/qwen-code /usr/local/bin/qwen
   ```

### 问题 3：构建仍然使用旧缓存

**症状：** 修改后的 Dockerfile 似乎没有生效

**解决步骤：**
1. **添加缓存破坏层**
   ```dockerfile
   # 在 Dockerfile 开头添加
   ARG CACHE_BUST=1
   RUN echo "Cache bust: $CACHE_BUST"
   ```

2. **使用不同的构建参数**
   ```bash
   # 本地测试时
   docker build --no-cache -t claudable:test .
   ```

3. **联系 Zeabur 支持**
   - 如果问题持续，可能需要 Zeabur 团队清除深层缓存

### 问题 4：应用启动但功能异常

**症状：** 容器启动成功但页面样式错误或功能缺失

**解决步骤：**
1. **检查运行时日志**
   - 在 Zeabur 控制台查看"应用日志"
   - 查找 JavaScript 错误或模块缺失

2. **验证文件复制**
   ```dockerfile
   # 确保所有必要文件都被复制
   COPY --from=builder /app/.next/standalone ./
   COPY --from=builder /app/.next/static ./.next/static
   COPY --from=builder /app/public ./public
   COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
   ```

## 📊 预期结果和成功指标

### 🎯 部署成功的标志

1. **构建阶段**
   - ✅ 无 tailwindcss 相关错误
   - ✅ Qwen CLI 安装成功
   - ✅ Next.js 构建完成
   - ✅ 总构建时间 < 10 分钟

2. **运行阶段**
   - ✅ 容器启动成功（状态：运行中）
   - ✅ 应用响应 HTTP 请求
   - ✅ 健康检查通过（如果配置）

3. **功能验证**
   - ✅ 主页正确加载，样式完整
   - ✅ 可以创建新项目
   - ✅ 所有 AI 模型（Claude、Cursor、Qwen 等）可选择
   - ✅ 聊天功能正常工作
   - ✅ 预览功能可用

### 📈 性能指标

- **冷启动时间**：< 30 秒
- **首次响应时间**：< 5 秒
- **内存使用**：< 1GB
- **CPU 使用**：正常负载下 < 50%

## 🔄 持续监控和维护

### 日常检查
- 监控应用健康状态
- 检查错误日志
- 验证所有功能正常

### 定期更新
- 更新依赖版本
- 监控安全漏洞
- 优化 Docker 镜像大小

## 📞 获取支持

### 如果问题仍然存在，请提供：

1. **完整的构建日志**
   - 从 Zeabur 控制台复制完整日志
   - 包括错误发生前后的上下文

2. **项目配置信息**
   - Zeabur 项目设置截图
   - 环境变量配置
   - 构建方式选择

3. **本地测试结果**
   ```bash
   # 运行这些命令并提供输出
   docker --version
   node --version
   npm --version
   
   # 本地构建测试
   docker build -t claudable:test . 2>&1 | tee build.log
   
   # 检查关键文件
   ls -la package*.json
   head -20 Dockerfile
   ```

4. **错误复现步骤**
   - 详细描述如何触发错误
   - 提供错误截图或日志片段

### 联系方式
- **GitHub Issues**：在项目仓库创建 issue
- **Zeabur 支持**：通过 Zeabur 控制台联系技术支持
- **社区论坛**：在相关技术社区寻求帮助

## 🚀 快速修复命令

### 一键应用修复（如果您有 Git 访问权限）

```bash
# 1. 备份当前 Dockerfile
cp Dockerfile Dockerfile.backup

# 2. 应用修复的 Dockerfile（需要手动复制上述内容）
# 编辑 Dockerfile 文件，替换为上述改进版本

# 3. 提交并推送
git add Dockerfile
git commit -m "fix: 修复 Zeabur 部署中的 tailwindcss 和 Qwen CLI 问题

- 使用 npm install --include=dev 确保安装 devDependencies
- 添加 Qwen CLI 符号链接 qwen-code -> qwen
- 复制必要的 Prisma 运行时文件
- 添加 gcompat 系统包提供兼容性"
git push origin main
```

### 本地测试命令

```bash
# 测试 Docker 构建
docker build -t claudable:test .

# 运行容器测试
docker run -p 3000:3000 -e DATABASE_URL="file:/app/data/dev.db" claudable:test

# 检查容器内的依赖
docker run -it claudable:test sh -c "npm list tailwindcss && which qwen"
```

---

## 📝 总结

这个修复方案解决了 Zeabur 部署中的核心问题：

1. **✅ 修复了 tailwindcss 依赖安装问题**
2. **✅ 解决了 Qwen CLI 可执行文件名不匹配**
3. **✅ 优化了 Docker 构建缓存策略**
4. **✅ 提供了详细的故障排除指南**

按照这个计划执行，您的 Claudable 应用应该能够在 Zeabur 上成功部署并正常运行。