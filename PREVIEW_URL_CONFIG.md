# 预览 URL 配置指南

## 问题描述

前端对话生成页面的预览中显示 "localhost 拒绝链接" 错误。这通常发生在远程开发环境中，如 GitHub Codespaces、GitHub Dev、Zeabur 或其他云开发环境。

## 原因

预览服务默认使用 `localhost` 作为主机名，但在远程环境中，应该使用实际的主机名或域名来访问预览服务器。

## 解决方案

### 1. 自动检测（推荐）

系统已配置为自动检测环境并使用正确的主机名。支持以下环境：

#### Zeabur 部署 ⭐
- 自动检测 `ZEABUR` 或 `ZEABUR_SERVICE_ID` 环境变量
- 自动从 `ZEABUR_URL` 提取域名
- 如果未设置 `ZEABUR_URL`，使用 `APP_DOMAIN`

#### GitHub Codespaces
- 自动检测 `CODESPACES` 和 `CODESPACE_NAME` 环境变量
- 生成格式：`{CODESPACE_NAME}-{PORT}.preview.app.github.dev`

#### GitHub Dev
- 自动检测 `GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN` 环境变量

#### 本地开发
- 默认使用 `localhost`

### 2. 手动配置

如果自动检测不工作，可以通过环境变量手动配置：

#### 选项 A：设置 `PREVIEW_HOST`
```bash
export PREVIEW_HOST=your-domain.com
```

#### 选项 B：设置 `APP_DOMAIN`
```bash
export APP_DOMAIN=your-domain.com
```

### 3. 在 Zeabur 中配置 ⭐

#### 方法 1：使用 Zeabur 提供的域名（推荐）

在 Zeabur 项目的环境变量设置中添加：

```bash
APP_DOMAIN=your-app.zeabur.app
```

或者使用更明确的：

```bash
PREVIEW_HOST=your-app.zeabur.app
```

**获取 Zeabur 域名的步骤：**
1. 登录 Zeabur 控制台
2. 进入您的项目
3. 查看 "Domains" 或"域名"标签
4. 复制分配给您的域名（例如：`my-app-abc123.zeabur.app`）
5. 将该域名设置为 `APP_DOMAIN` 环境变量

#### 方法 2：使用自定义域名

如果您在 Zeabur 上配置了自定义域名：

```bash
APP_DOMAIN=your-custom-domain.com
```

#### 方法 3：通过 `.env` 文件（本地测试）

在项目根目录创建 `.env` 文件：
```env
APP_DOMAIN=your-app.zeabur.app
NODE_ENV=production
```

**注意**：Zeabur 会自动注入 `ZEABUR=1` 和 `ZEABUR_URL` 环境变量，系统会自动检测。

### 4. 在 Codespaces 中配置

#### 方法 1：通过 `.env` 文件
在项目根目录创建 `.env` 文件：
```env
PREVIEW_HOST=your-codespace-name-3000.preview.app.github.dev
```

#### 方法 2：通过 Codespaces 设置
在 `.devcontainer/devcontainer.json` 中添加：
```json
{
  "remoteEnv": {
    "PREVIEW_HOST": "${containerEnv:CODESPACE_NAME}-3000.preview.app.github.dev"
  }
}
```

#### 方法 3：通过 GitHub Codespaces 环境变量
在 GitHub 仓库设置中添加 Codespaces 环境变量：
- 名称：`PREVIEW_HOST`
- 值：`{CODESPACE_NAME}-3000.preview.app.github.dev`

## 预览 URL 生成优先级

系统按以下优先级生成预览 URL：

1. **`PREVIEW_HOST`** - 显式设置的主机名（最高优先级）
2. **Zeabur 自动检测** - 检测 `ZEABUR=1` 并从 `ZEABUR_URL` 提取域名
3. **Codespaces 自动检测** - 如果在 GitHub Codespaces 中
4. **`GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN`** - GitHub Dev 环境
5. **`APP_DOMAIN`** - 自定义应用域名
6. **生产环境回退** - 如果 `NODE_ENV=production` 但未设置域名，使用 `0.0.0.0`
7. **`localhost`** - 本地开发默认值（最低优先级）

## 故障排除

### 问题：在 Zeabur 上预览仍然显示 "localhost 拒绝连接"

**解决步骤：**

1. **检查 Zeabur 环境变量**
   
   在 Zeabur 控制台中检查以下环境变量是否已设置：
   ```bash
   APP_DOMAIN=your-app.zeabur.app
   NODE_ENV=production
   ```

2. **验证 Zeabur 域名**
   
   - 登录 Zeabur 控制台
   - 确认您的应用已分配域名
   - 确保域名可以正常访问主应用
   - 将该域名设置为 `APP_DOMAIN`

3. **检查端口配置**
   
   Zeabur 通常会自动处理端口映射，但确保：
   - 主应用端口：3000（或 `PORT` 环境变量指定的端口）
   - 预览端口：动态分配（通常从 3001 开始）

4. **查看应用日志**
   
   在 Zeabur 控制台查看日志：
   - 搜索 `[PreviewManager]` 关键字
   - 检查预览服务器启动信息
   - 查看生成的预览 URL

5. **重新部署**
   
   如果环境变量刚刚添加：
   - 在 Zeabur 控制台触发重新部署
   - 或推送新的提交到仓库

### 问题：预览仍然显示 "localhost 拒绝连接"（通用）

**解决步骤：**

1. **检查环境变量**
   ```bash
   echo $ZEABUR
   echo $ZEABUR_URL
   echo $CODESPACE_NAME
   echo $PREVIEW_HOST
   echo $APP_DOMAIN
   echo $NODE_ENV
   ```

2. **检查预览服务器日志**
   - 查看服务器是否正确启动
   - 检查端口是否被占用
   - 查看生成的预览 URL

3. **验证预览 URL**
   - 打开浏览器开发者工具（F12）
   - 查看 Network 标签中 iframe 的 src 属性
   - 确认 URL 格式正确（不应该是 `http://localhost:xxxx`）

4. **重启预览服务器**
   - 点击预览面板中的 "Stop" 按钮
   - 等待 2-3 秒
   - 点击 "Play" 按钮重新启动

### 问题：跨域访问被拒绝

**解决方案：**

iframe 已配置了必要的 sandbox 属性和 allow 属性来支持跨域访问：

```html
allow="accelerometer; ambient-light-sensor; autoplay; battery; camera; 
       display-capture; document-domain; encrypted-media; 
       execution-while-not-rendered; execution-while-out-of-viewport; 
       fullscreen; geolocation; gyroscope; magnetometer; microphone; 
       midi; navigation-override; payment; picture-in-picture; 
       publickey-credentials-get; sync-xhr; usb; vr; xr-spatial-tracking"

sandbox="allow-same-origin allow-scripts allow-forms allow-popups 
         allow-popups-to-escape-sandbox allow-presentation 
         allow-top-navigation allow-top-navigation-by-user-activation"
```

## 相关文件

- **后端配置**：`/lib/services/preview.ts` - 预览 URL 生成逻辑
- **前端配置**：`/app/[project_id]/chat/page.tsx` - iframe 实现
- **环境变量**：`.env` 或 `.env.local`

## 更多信息

- [GitHub Codespaces 文档](https://docs.github.com/en/codespaces)
- [GitHub Dev 文档](https://github.dev)
- [Next.js 部署指南](https://nextjs.org/docs/deployment)
