# ==================================
# Stage 1: 构建
# ==================================
FROM node:22-alpine AS builder

WORKDIR /app

RUN apk add --no-cache libc6-compat

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

# 生成 Prisma 客户端（使用项目中指定的版本）
RUN npx prisma@6.1.0 generate

COPY . .

RUN npm run build

# ==================================
# Stage 2: 运行 (Standalone 模式)
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

ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# 复制 standalone 输出
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

EXPOSE 3000

CMD ["/app/start.sh"]


