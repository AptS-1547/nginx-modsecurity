# Nginx with ModSecurity

[English](README.md) | 简体中文

![Docker Image CI](https://github.com/AptS-1547/nginx-modsecurity/workflows/Docker%20Image%20CI/badge.svg)
[![Docker Hub](https://img.shields.io/docker/pulls/e1saps/nginx-modsecurity.svg)](https://hub.docker.com/r/e1saps/nginx-modsecurity)
[![GitHub Container Registry](https://img.shields.io/badge/GitHub%20Container-Registry-blue)](https://github.com/AptS-1547/nginx-modsecurity/pkgs/container/nginx-modsecurity)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

用于运行 Nginx + ModSecurity v3 WAF 引擎的生产向 Docker 镜像。本镜像会从源码构建 ModSecurity 和 `modsecurity-nginx` 连接器，将 Nginx 连接器编译为动态模块，并发布 `linux/amd64` 和 `linux/arm64` 多架构镜像。

这个仓库刻意保持简单：每个受支持的版本组合都放在独立的 `nginx-<version>/mod-<version>/Dockerfile` 目录下，当前 CI 实际发布哪些镜像则由 `build-matrix.json` 控制。

## 包含内容

- 基于官方 `nginx:<version>-alpine` 镜像的 Nginx
- 从 OWASP ModSecurity 源码构建的 ModSecurity v3
- 作为 Nginx 动态模块编译的 `modsecurity-nginx`
- ModSecurity 运行时依赖，包括 Lua 5.4、LMDB、YAJL、PCRE2、GeoIP、libxml2 和 curl
- 模块加载文件 `/etc/nginx/modules-available/50-modsecurity.conf`
- 已启用模块的符号链接 `/etc/nginx/modules-enabled/`
- 复制到 `/etc/nginx/modsec/` 的 ModSecurity `unicode.mapping`

镜像提供的是 WAF 引擎和 Nginx 模块，不内置默认的 OWASP Core Rule Set 配置。生产环境需要挂载自己的 ModSecurity 配置和规则集。

## 当前发布矩阵

当前 CI 构建矩阵定义在 [`build-matrix.json`](build-matrix.json)：

| 频道 | Nginx | ModSecurity | modsecurity-nginx | Dockerfile |
| --- | --- | --- | --- | --- |
| `mainline` / `latest` | `1.31.0` | `v3.0.15` | `v1.0.4` | `nginx-1.31.0/mod-3.0.15/Dockerfile` |
| `stable` | `1.30.1` | `v3.0.15` | `v1.0.4` | `nginx-1.30.1/mod-3.0.15/Dockerfile` |

仓库里保留了更早版本目录作为历史构建定义，但当前 GitHub Actions 只会构建并发布 `build-matrix.json` 中列出的条目。

## 镜像仓库

镜像会发布到 Docker Hub 和 GitHub Container Registry：

```bash
docker pull e1saps/nginx-modsecurity:latest
docker pull ghcr.io/apts-1547/nginx-modsecurity:latest
```

没有特殊要求时直接使用 Docker Hub。如果你的部署流程已经接入 GitHub Packages，可以使用 GHCR。

## 镜像标签

每个矩阵条目都会发布完整版本标签和纯 Nginx 版本标签：

| 标签 | 示例 | 说明 |
| --- | --- | --- |
| `<nginx-version>-<modsecurity-version>` | `1.31.0-3.0.15` | 精确的 Nginx 和 ModSecurity 组合 |
| `<nginx-version>` | `1.31.0` | 当前 Nginx 版本对应的 ModSecurity 组合别名 |
| `latest` | `latest` | 当前 `mainline` 构建 |
| `mainline` | `mainline` | 当前 Nginx 主线版本构建 |
| `stable` | `stable` | 当前 Nginx 稳定版本构建 |

生产环境建议使用完整版本标签，例如：

```bash
docker pull e1saps/nginx-modsecurity:1.30.1-3.0.15
```

这样可以避免 `latest`、`mainline` 或 `stable` 变动时发生意外升级。

## 快速开始

运行最新主线版本镜像：

```bash
docker run --rm -p 8080:80 e1saps/nginx-modsecurity:latest
```

检查默认 Nginx 页面：

```bash
curl http://localhost:8080/
```

这只能确认 Nginx 可以启动。要让 ModSecurity 真正检查请求，还需要添加 ModSecurity 配置，并在 Nginx 的 `server` 或 `location` 块中启用它。

## 启用模块

镜像中的模块加载文件位于：

```text
/etc/nginx/modules-enabled/50-modsecurity.conf
```

如果你替换了 `/etc/nginx/nginx.conf`，确保自定义配置在 `events` 块之前包含已启用模块：

```nginx
include /etc/nginx/modules-enabled/*.conf;

events {}

http {
    server {
        listen 80;

        modsecurity on;
        modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;

        location / {
            proxy_pass http://app:3000;
        }
    }
}
```

如果你只挂载 `/etc/nginx/conf.d/` 下的文件，官方 Nginx 镜像的 entrypoint 会继续使用基础 `nginx.conf`，模块加载行为取决于基础配置。拿不准时，直接提供完整的 `nginx.conf`，并加上 `include /etc/nginx/modules-enabled/*.conf;`。

## 自定义规则示例

创建一个最小 ModSecurity 配置：

```apache
# ./modsec/modsecurity.conf
SecRuleEngine On
SecRequestBodyAccess On
SecResponseBodyAccess Off
SecAuditEngine RelevantOnly
SecAuditLog /var/log/nginx/modsec_audit.log

SecRule ARGS:test "@contains attack" "id:1000,phase:2,deny,status:403,msg:'Test ModSecurity rule'"
```

创建一个加载模块并使用该规则文件的 Nginx 配置：

```nginx
# ./nginx.conf
include /etc/nginx/modules-enabled/*.conf;

events {}

http {
    server {
        listen 80;

        modsecurity on;
        modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;

        location / {
            return 200 "nginx-modsecurity is running\n";
        }
    }
}
```

运行容器：

```bash
docker run --rm \
  -p 8080:80 \
  -v "$PWD/nginx.conf:/etc/nginx/nginx.conf:ro" \
  -v "$PWD/modsec:/etc/nginx/modsec:ro" \
  e1saps/nginx-modsecurity:stable
```

测试规则：

```bash
curl "http://localhost:8080/?test=ok"
curl -i "http://localhost:8080/?test=attack"
```

第二个请求在规则生效时应返回 `403`。

## Docker Compose

```yaml
services:
  waf:
    image: e1saps/nginx-modsecurity:1.30.1-3.0.15
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./modsec:/etc/nginx/modsec:ro
      - ./logs:/var/log/nginx
    restart: unless-stopped
```

## 本地构建

从指定 Dockerfile 构建某个版本：

```bash
docker build \
  -t nginx-modsecurity:1.31.0-3.0.15 \
  -f nginx-1.31.0/mod-3.0.15/Dockerfile \
  .
```

运行本地镜像：

```bash
docker run --rm -p 8080:80 nginx-modsecurity:1.31.0-3.0.15
```

如需多架构发布，使用 Buildx：

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t your-registry/nginx-modsecurity:1.31.0-3.0.15 \
  -f nginx-1.31.0/mod-3.0.15/Dockerfile \
  --push \
  .
```

## 添加或更新版本

使用 [`update.sh`](update.sh) 从相同 ModSecurity 版本的最近模板创建新版本目录：

```bash
./update.sh <NGINX_VERSION> <MODSECURITY_VERSION> <MODSECURITY_NGINX_VERSION> [ROLE]
```

示例：

```bash
./update.sh 1.31.1 v3.0.15 v1.0.4 mainline
```

脚本会：

1. 创建 `nginx-<nginx-version>/mod-<modsecurity-version>/Dockerfile`
2. 替换复制得到的 Dockerfile 中的 Nginx 和连接器版本
3. 更新 `build_date` 标签
4. 在 `build-matrix.json` 中替换或追加对应 `role` 的条目

CI 当前识别的角色如下：

| Role | 发布的频道标签 |
| --- | --- |
| `mainline` | `latest`, `mainline` |
| `stable` | `stable` |

运行脚本后先检查生成的 Dockerfile，再提交。不同 Nginx 或 ModSecurity 版本偶尔会需要额外的构建修正。

## CI 发布流程

GitHub Actions 工作流位于 [`.github/workflows/docker-image.yml`](.github/workflows/docker-image.yml)，会在推送到 `master` 且修改了 `build-matrix.json` 或版本化 Dockerfile 时运行，也可以通过 `workflow_dispatch` 手动触发。

对每个矩阵条目，CI 会：

1. 在原生 runner 上分别构建 `linux/amd64` 和 `linux/arm64` 镜像
2. 推送临时的架构专用镜像
3. 为 Docker Hub 和 GHCR 创建多架构 manifest
4. 根据矩阵中的 `role` 发布版本标签和频道标签
5. 如果完整版本标签已存在，则跳过构建；手动触发时可用 `force_rebuild` 强制重建

## 项目结构

```text
.
├── build-matrix.json
├── update.sh
├── nginx-1.31.0/
│   └── mod-3.0.15/
│       └── Dockerfile
├── nginx-1.30.1/
│   └── mod-3.0.15/
│       └── Dockerfile
└── .github/
    └── workflows/
        └── docker-image.yml
```

其他历史 `nginx-*` 目录也遵循同样结构。

## 安全提示

- 生产环境使用精确版本标签。
- 挂载自己的 ModSecurity 规则和审计日志策略。
- 规则变更先用检测模式验证，再切换到阻断模式。
- WAF 日志可能包含请求体、令牌或用户输入，应按敏感数据处理。
- 当上游 Nginx、Alpine 或 ModSecurity 发布与你部署相关的安全更新时，应重新构建。

## 相关项目

- [Nginx](https://nginx.org/)
- [ModSecurity](https://github.com/owasp-modsecurity/ModSecurity)
- [ModSecurity-nginx](https://github.com/owasp-modsecurity/ModSecurity-nginx)
- [OWASP Core Rule Set](https://coreruleset.org/)

## 许可证

本项目采用 [MIT License](LICENSE) 许可证。
