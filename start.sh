#!/bin/sh
set -e

echo "========================================="
echo "🚀 Claudable Startup Script"
echo "========================================="

# 确保数据目录存在
echo "📁 Ensuring /app/data directory exists..."
mkdir -p /app/data

# 显示数据库路径
echo "📊 Database URL: ${DATABASE_URL}"

# 运行 Prisma 迁移
echo "🔄 Running Prisma database migrations..."
cd /app

if [ -f "node_modules/prisma/build/index.js" ]; then
  node node_modules/prisma/build/index.js db push --accept-data-loss --skip-generate 2>&1 | tee /tmp/prisma-migration.log
  
  if [ $? -eq 0 ]; then
    echo "✅ Database migration completed successfully!"
  else
    echo "⚠️  Database migration failed, but continuing..."
    echo "📋 Migration log:"
    cat /tmp/prisma-migration.log
  fi
else
  echo "⚠️  Prisma CLI not found at node_modules/prisma/build/index.js"
  echo "📋 Checking node_modules structure..."
  ls -la node_modules/ 2>/dev/null || echo "node_modules not found"
fi

# 检查数据库文件
if [ -f "/app/data/dev.db" ]; then
  echo "✅ Database file exists: /app/data/dev.db"
  ls -lh /app/data/dev.db
else
  echo "⚠️  Database file not found: /app/data/dev.db"
fi

echo "========================================="
echo "🚀 Starting Next.js Application..."
echo "========================================="

# 启动应用
exec node server.js
