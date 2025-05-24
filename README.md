# Nginx with ModSecurity

![Docker Image CI](https://github.com/AptS-1547/nginx-modsecurity/workflows/Docker%20Image%20CI/badge.svg)
[![Docker Hub](https://img.shields.io/docker/pulls/e1saps/nginx-modsecurity.svg)](https://hub.docker.com/r/e1saps/nginx-modsecurity)
[![GitHub Container Registry](https://img.shields.io/badge/GitHub%20Container-Registry-blue)](https://github.com/e1saps/nginx-modsecurity/pkgs/container/nginx-modsecurity)

这个项目提供了一个集成了 ModSecurity Web 应用防火墙的 Nginx Docker 镜像。镜像基于 Alpine Linux，轻量且安全。

## 可用标签

- `latest`: 最新稳定版本
- `<nginx-version>`: 特定 Nginx 版本，例如 `1.26.3`
- `<nginx-version>-<modsecurity-version>`: 特定 Nginx 和 ModSecurity 版本组合，例如 `1.26.3-3.0.14`

## 功能特点

- 基于最新的 Alpine Linux 基础镜像
- 包含最新版本的 Nginx 和 ModSecurity
- 可自定义 ModSecurity 规则
- 多架构支持 (AMD64, ARM64)
- 定期更新以应对安全漏洞

## 快速开始

### 拉取镜像

```bash
docker pull e1saps/nginx-modsecurity:latest
```

或者使用 GitHub Container Registry:

```bash
docker pull ghcr.io/e1saps/nginx-modsecurity:latest
```

### 运行容器

```bash
docker run -d -p 80:80 -p 443:443 e1saps/nginx-modsecurity:latest
```

### 使用自定义配置

```bash
docker run -d -p 80:80 -p 443:443 \
  -v /path/to/nginx.conf:/etc/nginx/nginx.conf \
  -v /path/to/modsec:/etc/nginx/modsec \
  e1saps/nginx-modsecurity:latest
```

## 版本管理

本项目使用 update.sh 脚本来管理不同版本的 Nginx 和 ModSecurity 组合:

```bash
# 格式: ./update.sh <NGINX_VERSION> <MODSECURITY_VERSION> <MODSECURITY_NGINX_VERSION>
./update.sh 1.26.3 v3.0.14 v1.0.3
```

这将生成:
1. 特定版本目录下的 Dockerfile 和配置文件
2. 根目录的 `Dockerfile.latest` 和 `versions.env` 文件

## 自定义构建

您可以手动构建特定版本:

```bash
# 进入版本目录
cd nginx-1.26.3/mod-3.0.14
# 构建镜像
docker build -t nginx-modsecurity:1.26.3-3.0.14 .
```

或者直接使用最新版本:

```bash
docker build -t nginx-modsecurity:latest -f Dockerfile.latest .
```

## ModSecurity 规则配置

默认情况下，镜像只包含 ModSecurity 引擎，但没有激活任何规则。您可以添加 OWASP Core Rule Set (CRS) 或自定义规则:

```bash
# 挂载自定义 ModSecurity 配置
docker run -d -p 80:80 \
  -v /path/to/modsecurity.conf:/etc/nginx/modsec/modsecurity.conf \
  -v /path/to/crs:/etc/nginx/modsec/crs \
  e1saps/nginx-modsecurity:latest
```

## 贡献

欢迎提交 Pull Request 或 Issue 来改进这个项目！

## 许可证

MIT License
