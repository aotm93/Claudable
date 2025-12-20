# ==================================
# Stage 1: 构建
# ==================================
FROM node:22-alpine AS builder

WORKDIR /app

RUN apk add --no-cache libc6-compat

COPY package*.json ./
COPY prisma ./prisma/

# 安装所有依赖（包括 devDependencies，构建时需要）
# 添加详细日志以便调试
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

RUN npx prisma generate

COPY . .

RUN npm run build

# ==================================
# Stage 2: 运行 (Standalone 模式)
# ==================================
FROM node:22-alpine AS runner

WORKDIR /app

# 安装必要的系统依赖
RUN apk add --no-cache \
    libc6-compat \
    curl \
    bash

# 安装 Qwen Code CLI（通过 npm 全局安装）
# 注意：Qwen CLI 是 npm 包，不是独立的二进制文件
RUN npm install -g @qwen-code/qwen-code@latest && \
    echo "✅ Qwen CLI installed via npm"

# 验证 Qwen CLI 安装
RUN which qwen && qwen --version || \
    (echo "❌ ERROR: Qwen CLI not found in PATH" && exit 1)

ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# 复制 standalone 输出
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

# 复制 Prisma 相关文件
COPY --from=builder /app/prisma ./prisma
# ✅ 复制完整的 node_modules（包含所有依赖）
COPY --from=builder /app/node_modules ./node_modules

# 复制启动脚本
COPY --from=builder /app/start.sh ./start.sh
RUN chmod +x /app/start.sh

# 创建数据目录
RUN mkdir -p /app/data

EXPOSE 3000

CMD ["/app/start.sh"]


