# Nginx with ModSecurity

[English](README.md) | 简体中文

![Docker Image CI](https://github.com/AptS-1547/nginx-modsecurity/workflows/Docker%20Image%20CI/badge.svg)
[![Docker Hub](https://img.shields.io/docker/pulls/e1saps/nginx-modsecurity.svg)](https://hub.docker.com/r/e1saps/nginx-modsecurity)
[![GitHub Container Registry](https://img.shields.io/badge/GitHub%20Container-Registry-blue)](https://github.com/AptS-1547/nginx-modsecurity/pkgs/container/nginx-modsecurity)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

一个轻量级、安全且高性能的 Nginx + ModSecurity WAF Docker 镜像，专为现代 Web 应用提供企业级防护能力。

## 核心组件

本项目基于以下开源项目构建：

- **[Nginx](https://github.com/nginx/nginx)** - 高性能 Web 服务器和反向代理
- **[ModSecurity](https://github.com/owasp-modsecurity/ModSecurity)** - OWASP Web 应用防火墙引擎
- **[ModSecurity-nginx](https://github.com/owasp-modsecurity/ModSecurity-nginx)** - ModSecurity 的 Nginx 连接器模块

## 目录

- [项目简介](#项目简介)
- [功能特点](#功能特点)
- [快速开始](#快速开始)
- [镜像标签](#镜像标签)
- [支持的版本](#支持的版本)
- [使用指南](#使用指南)
- [版本管理](#版本管理)
- [自定义构建](#自定义构建)
- [开发指南](#开发指南)
- [贡献](#贡献)
- [许可证](#许可证)

## 项目简介

本项目提供了一个开箱即用的 Nginx + ModSecurity Web 应用防火墙（WAF）解决方案，专门设计用于保护 Web 应用免受常见攻击，如 SQL 注入、XSS、CSRF 等。

### 为什么选择这个镜像？

- **轻量级**: 基于 Alpine Linux，镜像大小仅约 60MB
- **安全优先**: 集成 OWASP ModSecurity v3 引擎，提供企业级 WAF 防护能力
- **多阶段构建**: 使用 Docker 多阶段构建技术，减少攻击面
- **持续更新**: 自动化 CI/CD 流程，及时跟进安全补丁
- **生产就绪**: 经过优化的配置和运行时依赖，适合直接部署

### 适用场景

- 保护 Web 应用和 API 免受 OWASP Top 10 威胁
- 作为反向代理前置 WAF，为后端服务提供统一安全防护
- 微服务架构中的边缘安全网关
- 容器化环境中的应用层防火墙

## 功能特点

### 核心特性

- ✅ **最新版本支持**: Nginx 1.28.0 + ModSecurity v3.0.14
- ✅ **Alpine Linux 基础**: 极致轻量，安全加固
- ✅ **动态模块加载**: ModSecurity 作为动态模块编译
- ✅ **完整的运行时依赖**: 包含 Lua 5.4、LMDB、YAJL、GeoIP 等
- ✅ **多架构支持**: 原生支持 AMD64 (x86_64) 和 ARM64 (aarch64)

## 快速开始

### 拉取镜像

从 Docker Hub 拉取：

```bash
docker pull e1saps/nginx-modsecurity:latest
```

或从 GitHub Container Registry 拉取：

```bash
docker pull ghcr.io/e1saps/nginx-modsecurity:latest
```

### 基本运行

启动一个简单的 Nginx + ModSecurity 容器：

```bash
docker run -d \
  --name nginx-modsec \
  -p 80:80 \
  -p 443:443 \
  e1saps/nginx-modsecurity:latest
```

验证运行状态：

```bash
docker ps
docker logs nginx-modsec
curl http://localhost
```

## 镜像标签

| 标签格式 | 示例 | 说明 |
|---------|------|------|
| `latest` | `latest` | 最新主线版本（Mainline），包含最新功能 |
| `mainline` | `mainline` | 最新主线版本（Mainline），与 `latest` 相同 |
| `stable` | `stable` | 最新稳定版本（Stable），专注于 bug 修复 |
| `<nginx-version>` | `1.28.0` | 特定 Nginx 版本 |
| `<nginx-version>-<modsec-version>` | `1.28.0-3.0.14` | 特定版本组合（推荐生产使用） |

**生产环境建议**: 使用具体版本标签（如 `1.28.0-3.0.14`）以确保环境一致性。如需跟踪最新版本，建议使用 `stable` 标签而非 `latest`/`mainline`。

## 支持的版本

本项目维护以下 Nginx 版本的镜像：

| Nginx 版本 | ModSecurity 版本 | 状态 |
|-----------|-----------------|------|
| 1.28.0 | v3.0.14 | ✅ 最新 |
| 1.26.3 | v3.0.14 | ✅ 稳定 |
| 1.24.0 | v3.0.14 | ✅ 长期支持 |
| 1.22.1 | v3.0.14 | ⚠️ 维护中 |
| 1.20.2 | v3.0.14 | ⚠️ 维护中 |
| 1.18.0 | v3.0.14 | ⚠️ 旧版本 |
| 1.16.1 | v3.0.14 | ⚠️ 旧版本 |
| 1.14.2 | v3.0.14 | ⚠️ 旧版本 |

**更新策略**:

- 从 2025-10-16 起推送 Nginx 主线版本（Mainline），之前版本保持为稳定版（Stable）
- ModSecurity 版本保持在 v3.x 最新稳定分支
- 定期进行安全补丁更新
- 主线版本包含最新功能和改进，稳定版本专注于 bug 修复

## 使用指南

### 使用自定义配置

```bash
docker run -d \
  --name nginx-modsec \
  -p 80:80 \
  -p 443:443 \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v $(pwd)/modsec:/etc/nginx/modsec:ro \
  -v $(pwd)/logs:/var/log/nginx \
  e1saps/nginx-modsecurity:latest
```

### 使用 Docker Compose

创建 `docker-compose.yml` 文件：

```yaml
version: '3.8'

services:
  nginx-modsecurity:
    image: e1saps/nginx-modsecurity:latest
    container_name: nginx-modsec
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./config/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./config/modsec:/etc/nginx/modsec:ro
      - ./logs:/var/log/nginx
      - ./html:/usr/share/nginx/html:ro
    networks:
      - web
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  web:
    driver: bridge
```

启动服务：

```bash
docker-compose up -d
```

### 配置 ModSecurity

#### 模块加载方式

**重要提示**：从 1.29.2 版本之后的镜像，ModSecurity 模块加载方式有所变化。

- **1.29.2 及之前版本**：模块已自动加载到 `/etc/nginx/nginx.conf`，无需额外配置
- **1.29.2 之后版本**：模块配置文件位于 `/etc/nginx/modules-available/50-modsecurity.conf`

对于新版本（1.29.2 之后），需要在 `nginx.conf` 顶部添加：

```nginx
include /etc/nginx/modules-enabled/*.conf;
```

#### 启用 ModSecurity

在 Nginx 配置中启用 ModSecurity：

```nginx
server {
    listen 80;
    server_name example.com;

    # 启用 ModSecurity
    modsecurity on;
    modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
}
```

关于 ModSecurity 详细配置和 OWASP CRS 规则集成，请参考：

- [ModSecurity 官方文档](https://github.com/SpiderLabs/ModSecurity/wiki)
- [OWASP CRS 项目](https://coreruleset.org/)

## 版本管理

本项目使用 `update.sh` 脚本来管理不同版本的构建。

### 更新到新版本

```bash
# 基本用法
./update.sh <NGINX_VERSION> <MODSECURITY_VERSION> <MODSECURITY_NGINX_VERSION>

# 示例
./update.sh 1.28.0 v3.0.14 v1.0.4

# 自动提交并推送（可选）
./update.sh 1.28.0 v3.0.14 v1.0.4 true
```

### 脚本功能

运行脚本后会：

1. 创建版本化目录：`nginx-<version>/mod-<version>/`
2. 生成该版本的 Dockerfile 和 README
3. 更新根目录的 `Dockerfile.latest`
4. 更新 `versions.env` 版本信息文件

### 查看当前版本

```bash
cat versions.env
```

## 自定义构建

### 构建特定版本

```bash
cd nginx-1.28.0/mod-3.0.14
docker build -t my-nginx-modsec:1.28.0-3.0.14 .
```

### 构建最新版本

```bash
docker build -t my-nginx-modsec:latest -f Dockerfile.latest .
```

### 多架构构建

```bash
# 创建 builder
docker buildx create --name multiarch --use

# 构建并推送
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t my-registry/nginx-modsecurity:latest \
  -f Dockerfile.latest \
  --push .
```

## 开发指南

### 环境准备

```bash
git clone https://github.com/AptS-1547/nginx-modsecurity.git
cd nginx-modsecurity
docker build -t nginx-modsecurity:dev -f Dockerfile.latest .
```

### 添加新版本

```bash
./update.sh 1.29.0 v3.0.14 v1.0.4
cd nginx-1.29.0/mod-3.0.14
docker build -t test:1.29.0-3.0.14 .
```

### 测试

```bash
# 测试镜像构建
docker build -t test:latest -f Dockerfile.latest .

# 测试运行
docker run -d --name test-waf -p 8080:80 test:latest
curl http://localhost:8080/
docker rm -f test-waf
```

### CI/CD 流程

本项目使用 GitHub Actions 进行自动化构建和发布：

- **触发条件**: Push 到 master 分支或创建 Tag
- **发布目标**: Docker Hub 和 GitHub Container Registry
- **构建矩阵（未来）**: 多架构构建（AMD64, ARM64）

### 贡献代码

1. Fork 本仓库
2. 创建特性分支：`git checkout -b feature/amazing-feature`
3. 提交更改：`git commit -m 'Add some amazing feature'`
4. 推送分支：`git push origin feature/amazing-feature`
5. 提交 Pull Request

## 贡献

欢迎通过以下方式为项目做出贡献：

- 🐛 报告 Bug: 在 [Issues](https://github.com/AptS-1547/nginx-modsecurity/issues) 中提交
- 💡 功能建议: 在 [Issues](https://github.com/AptS-1547/nginx-modsecurity/issues) 中讨论
- 📖 改进文档: 提交 Pull Request
- 🔧 代码贡献: 提交 Pull Request

## 许可证

本项目采用 [MIT License](LICENSE) 许可证。

---

## 相关资源

- [Nginx 官方文档](https://nginx.org/en/docs/)
- [ModSecurity 官方文档](https://github.com/SpiderLabs/ModSecurity)
- [OWASP CRS 项目](https://coreruleset.org/)
- [Docker 官方文档](https://docs.docker.com/)

## 问题反馈

如有任何问题或建议，欢迎通过以下方式联系：

- GitHub Issues: <https://github.com/AptS-1547/nginx-modsecurity/issues>
- Email: <apts-1547@esaps.net>

如果这个项目对你有帮助，请给一个 ⭐️ Star 支持！
