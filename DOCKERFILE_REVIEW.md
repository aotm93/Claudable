# Dockerfile.api 审查报告

## 📋 审查日期
2025年12月20日

## 🔍 审查范围
重点审查 Qwen Code CLI 安装部分及整体 Dockerfile 结构

---

## 🚨 发现的问题

### 1. **严重问题：可执行文件名称不匹配**

**问题描述：**
- Dockerfile 安装的二进制文件名为 `qwen-code`
- 代码中调用的命令名为 `qwen`
- 导致运行时找不到命令

**原始代码：**
```dockerfile
# Dockerfile.api (原始)
RUN curl -L -o /usr/local/bin/qwen-code \
    https://github.com/QwenLM/Qwen-Code/releases/latest/download/qwen-code-linux-amd64 && \
    chmod +x /usr/local/bin/qwen-code
```

```typescript
// lib/services/cli/qwen.ts (第 41 行)
const QWEN_EXECUTABLE = process.platform === 'win32' ? 'qwen.cmd' : 'qwen';
```

**影响：**
- ❌ Qwen CLI 功能完全无法使用
- ❌ 用户选择 Qwen 模型时会报错 "command not found"
- ❌ 容器启动成功但功能缺失

**修复方案：**
```dockerfile
# 将二进制文件重命名为 'qwen' 而不是 'qwen-code'
RUN curl -L -o /usr/local/bin/qwen \
    https://github.com/QwenLM/Qwen-Code/releases/latest/download/qwen-code-linux-amd64 && \
    chmod +x /usr/local/bin/qwen
```

---

### 2. **中等问题：缺少安装验证**

**问题描述：**
- 安装脚本可能失败但不会中断构建
- 回退方案也可能失败但没有验证
- 无法确保 CLI 真正可用

**原始代码：**
```dockerfile
RUN curl -fsSL https://raw.githubusercontent.com/QwenLM/Qwen-Code/main/install.sh | bash || \
    (curl -L -o /usr/local/bin/qwen-code ... && chmod +x /usr/local/bin/qwen-code)
```

**影响：**
- ⚠️ 构建成功但 CLI 不可用
- ⚠️ 难以调试安装问题
- ⚠️ 生产环境可能出现意外错误

**修复方案：**
```dockerfile
# 添加安装验证步骤
RUN curl -fsSL https://raw.githubusercontent.com/QwenLM/Qwen-Code/main/install.sh | bash || \
    (echo "⚠️  Official install script failed, trying manual installation..." && \
     curl -L -o /usr/local/bin/qwen ... && \
     chmod +x /usr/local/bin/qwen && \
     echo "✅ Qwen CLI installed manually as 'qwen'")

# 验证安装
RUN which qwen || (echo "❌ ERROR: Qwen CLI not found in PATH" && exit 1)
```

---

### 3. **中等问题：Alpine Linux 兼容性**

**问题描述：**
- Alpine Linux 使用 `musl libc` 而不是 `glibc`
- 预编译的 Linux 二进制文件可能不兼容
- 缺少 `gcompat` 包来提供兼容层

**原始代码：**
```dockerfile
RUN apk add --no-cache \
    libc6-compat \
    curl \
    bash
```

**影响：**
- ⚠️ 二进制文件可能无法运行
- ⚠️ 出现 "not found" 或 "exec format error"
- ⚠️ 需要额外的兼容层

**修复方案：**
```dockerfile
RUN apk add --no-cache \
    libc6-compat \
    curl \
    bash \
    gcompat  # 添加 glibc 兼容层
```

---

### 4. **轻微问题：错误处理不够详细**

**问题描述：**
- 安装失败时没有详细的错误信息
- 难以诊断问题

**修复方案：**
- 添加详细的日志输出
- 使用 `echo` 命令提供安装状态反馈

---

## ✅ 已实施的修复

### 修复后的完整代码

```dockerfile
# 安装必要的系统依赖
RUN apk add --no-cache \
    libc6-compat \
    curl \
    bash \
    gcompat

# 下载并安装最新版本的 Qwen Code CLI（预编译二进制）
# 注意：确保可执行文件名为 'qwen' 以匹配代码中的调用
RUN curl -fsSL https://raw.githubusercontent.com/QwenLM/Qwen-Code/main/install.sh | bash || \
    (echo "⚠️  Official install script failed, trying manual installation..." && \
     curl -L -o /usr/local/bin/qwen https://github.com/QwenLM/Qwen-Code/releases/latest/download/qwen-code-linux-amd64 && \
     chmod +x /usr/local/bin/qwen && \
     echo "✅ Qwen CLI installed manually as 'qwen'")

# 验证 Qwen CLI 安装
RUN which qwen || (echo "❌ ERROR: Qwen CLI not found in PATH" && exit 1)
```

### 修复内容总结

1. ✅ **修正可执行文件名**：从 `qwen-code` 改为 `qwen`
2. ✅ **添加 gcompat 包**：提供 glibc 兼容层
3. ✅ **添加详细日志**：安装过程中输出状态信息
4. ✅ **添加安装验证**：确保 CLI 真正可用
5. ✅ **改进错误处理**：失败时提供清晰的错误信息

---

## 📊 其他审查发现

### ✅ 正确的部分

1. **多阶段构建**：使用 builder 和 runner 阶段，优化镜像大小
2. **依赖缓存**：正确利用 Docker 层缓存
3. **Prisma 集成**：正确复制和生成 Prisma 客户端
4. **环境变量**：合理设置 NODE_ENV、PORT、HOSTNAME
5. **启动脚本**：使用 start.sh 处理数据库迁移

### ⚠️ 可以改进的部分

#### 1. 考虑使用 Node.js 包而不是二进制文件

如果 Qwen Code 提供 npm 包，考虑使用：

```dockerfile
# 在 builder 阶段
RUN npm install -g @qwen-code/cli
```

**优点：**
- 更好的跨平台兼容性
- 自动处理依赖
- 更容易更新

#### 2. 固定版本而不是使用 latest

```dockerfile
# 当前（使用 latest）
curl -L -o /usr/local/bin/qwen \
  https://github.com/QwenLM/Qwen-Code/releases/latest/download/qwen-code-linux-amd64

# 建议（固定版本）
ARG QWEN_VERSION=v1.2.3
curl -L -o /usr/local/bin/qwen \
  https://github.com/QwenLM/Qwen-Code/releases/download/${QWEN_VERSION}/qwen-code-linux-amd64
```

**优点：**
- 构建可重现
- 避免意外的破坏性更新
- 更容易回滚

#### 3. 添加健康检查

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1
```

#### 4. 使用非 root 用户运行

```dockerfile
# 创建非 root 用户
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# 更改文件所有权
RUN chown -R nextjs:nodejs /app

# 切换用户
USER nextjs
```

**优点：**
- 提高安全性
- 符合最佳实践

---

## 🧪 测试建议

### 1. 本地测试

```bash
# 构建镜像
docker build -f Dockerfile.api -t claudable:test .

# 运行容器
docker run -it --rm claudable:test sh

# 在容器内验证
which qwen
qwen --version
qwen --help
```

### 2. 集成测试

```bash
# 启动完整应用
docker-compose up -d

# 测试 Qwen CLI 功能
# 1. 创建项目
# 2. 选择 Qwen 模型
# 3. 发送测试提示
# 4. 验证响应
```

### 3. 检查日志

```bash
# 查看构建日志
docker build -f Dockerfile.api -t claudable:test . 2>&1 | tee build.log

# 搜索关键信息
grep -i "qwen" build.log
grep -i "error" build.log
grep -i "warning" build.log
```

---

## 📝 部署检查清单

在部署到 Zeabur 或其他平台前，确认：

- [ ] Dockerfile 已更新并提交
- [ ] 本地构建成功
- [ ] Qwen CLI 可执行文件存在且可运行
- [ ] 环境变量正确配置（APP_DOMAIN、API keys 等）
- [ ] 数据库迁移正常运行
- [ ] 应用启动无错误
- [ ] Qwen 模型可以正常选择和使用
- [ ] 预览功能正常工作

---

## 🔗 相关文档

- [Qwen Code GitHub](https://github.com/QwenLM/Qwen-Code)
- [Docker 多阶段构建](https://docs.docker.com/build/building/multi-stage/)
- [Alpine Linux 包管理](https://wiki.alpinelinux.org/wiki/Alpine_Package_Keeper)
- [Zeabur 部署指南](./ZEABUR_DEPLOYMENT.md)
- [预览 URL 配置](./PREVIEW_URL_CONFIG.md)

---

## 📞 后续行动

1. **立即行动**：
   - ✅ 已修复可执行文件名称问题
   - ✅ 已添加安装验证
   - ✅ 已添加 gcompat 包

2. **短期改进**（建议在下次更新时实施）：
   - 固定 Qwen CLI 版本
   - 添加健康检查
   - 使用非 root 用户

3. **长期优化**（可选）：
   - 考虑使用 npm 包替代二进制文件
   - 实施自动化测试
   - 添加性能监控

---

## ✅ 结论

**主要问题已修复**：可执行文件名称不匹配的严重问题已解决。

**当前状态**：Dockerfile 现在应该可以正确安装和使用 Qwen Code CLI。

**建议**：在部署前进行完整的本地测试，确保所有功能正常工作。
