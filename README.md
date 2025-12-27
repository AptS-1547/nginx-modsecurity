# Nginx with ModSecurity

English | [简体中文](README.zh-CN.md)

![Docker Image CI](https://github.com/AptS-1547/nginx-modsecurity/workflows/Docker%20Image%20CI/badge.svg)
[![Docker Hub](https://img.shields.io/docker/pulls/e1saps/nginx-modsecurity.svg)](https://hub.docker.com/r/e1saps/nginx-modsecurity)
[![GitHub Container Registry](https://img.shields.io/badge/GitHub%20Container-Registry-blue)](https://github.com/AptS-1547/nginx-modsecurity/pkgs/container/nginx-modsecurity)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A lightweight, secure and high-performance Nginx + ModSecurity WAF Docker image, providing enterprise-grade protection for modern web applications.

## Core Components

This project is built on the following open source projects:

- **[Nginx](https://github.com/nginx/nginx)** - High-performance web server and reverse proxy
- **[ModSecurity](https://github.com/owasp-modsecurity/ModSecurity)** - OWASP Web Application Firewall engine
- **[ModSecurity-nginx](https://github.com/owasp-modsecurity/ModSecurity-nginx)** - ModSecurity connector module for Nginx

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Quick Start](#quick-start)
- [Image Tags](#image-tags)
- [Supported Versions](#supported-versions)
- [Usage Guide](#usage-guide)
- [Version Management](#version-management)
- [Custom Build](#custom-build)
- [Development Guide](#development-guide)
- [Contributing](#contributing)
- [License](#license)

## Introduction

This project provides a ready-to-use Nginx + ModSecurity Web Application Firewall (WAF) solution, designed to protect web applications from common attacks such as SQL injection, XSS, CSRF, and more.

### Why Choose This Image?

- **Lightweight**: Based on Alpine Linux, image size is only ~60MB
- **Security First**: Integrated with OWASP ModSecurity v3 engine for enterprise-grade WAF protection
- **Multi-stage Build**: Uses Docker multi-stage build to reduce attack surface
- **Continuous Updates**: Automated CI/CD pipeline ensures timely security patches
- **Production Ready**: Optimized configuration and runtime dependencies suitable for production deployment

### Use Cases

- Protect web applications and APIs from OWASP Top 10 threats
- Deploy as a reverse proxy WAF to provide unified security protection for backend services
- Edge security gateway in microservices architecture
- Application-layer firewall in containerized environments

## Features

### Core Features

- ✅ **Latest Version Support**: Nginx 1.29.4 + ModSecurity v3.0.14
- ✅ **Alpine Linux Based**: Extremely lightweight with security hardening
- ✅ **Dynamic Module Loading**: ModSecurity compiled as a dynamic module
- ✅ **Complete Runtime Dependencies**: Includes Lua 5.4, LMDB, YAJL, GeoIP, etc.
- ✅ **Multi-Architecture Support**: Native support for AMD64 (x86_64) and ARM64 (aarch64)

## Quick Start

### Pull Image

From Docker Hub:

```bash
docker pull e1saps/nginx-modsecurity:latest
```

Or from GitHub Container Registry:

```bash
docker pull ghcr.io/e1saps/nginx-modsecurity:latest
```

### Basic Run

Start a simple Nginx + ModSecurity container:

```bash
docker run -d \
  --name nginx-modsec \
  -p 80:80 \
  -p 443:443 \
  e1saps/nginx-modsecurity:latest
```

Verify container status:

```bash
docker ps
docker logs nginx-modsec
curl http://localhost
```

## Image Tags

| Tag Format | Example | Description |
|-----------|---------|-------------|
| `latest` | `latest` | Latest mainline version with newest features |
| `mainline` | `mainline` | Latest mainline version, same as `latest` |
| `stable` | `stable` | Latest stable version, focused on bug fixes |
| `<nginx-version>` | `1.29.4` | Specific Nginx version |
| `<nginx-version>-<modsec-version>` | `1.29.4-3.0.14` | Specific version combination (recommended for production) |

**Production Recommendation**: Use specific version tags (e.g., `1.29.4-3.0.14`) to ensure environment consistency. If tracking latest versions, prefer `stable` tag over `latest`/`mainline`.

## Supported Versions

This project maintains images for the following Nginx versions:

| Nginx Version | ModSecurity Version | Status |
|--------------|-------------------|--------|
| 1.29.4 | v3.0.14 | ✅ Latest |
| 1.28.1 | v3.0.14 | ✅ Stable |
| 1.26.3 | v3.0.14 | ✅ LTS |
| 1.24.0 | v3.0.14 | ⚠️ Maintained |
| 1.22.1 | v3.0.14 | ⚠️ Maintained |
| 1.20.2 | v3.0.14 | ⚠️ Legacy |
| 1.18.0 | v3.0.14 | ⚠️ Legacy |
| 1.16.1 | v3.0.14 | ⚠️ Legacy |
| 1.14.2 | v3.0.14 | ⚠️ Legacy |

**Update Strategy**:

- Starting from 2025-10-16, pushing Nginx mainline versions; previous versions remain stable
- ModSecurity version stays on v3.x latest stable branch
- Regular security patch updates
- Mainline versions include latest features and improvements, stable versions focus on bug fixes

## Usage Guide

### Using Custom Configuration

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

### Using Docker Compose

Create a `docker-compose.yml` file:

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

Start services:

```bash
docker-compose up -d
```

### Configuring ModSecurity

#### Module Loading Method

**Important Notice**: Starting from version 1.29.2, the ModSecurity module loading method has changed.

- **Version 1.29.2 and earlier**: Module is automatically loaded into `/etc/nginx/nginx.conf`, no additional configuration needed
- **After version 1.29.2**: Module configuration file is located at `/etc/nginx/modules-available/50-modsecurity.conf`

For newer versions (after 1.29.2), add this to the top of your `nginx.conf`:

```nginx
include /etc/nginx/modules-enabled/*.conf;
```

#### Enabling ModSecurity

Enable ModSecurity in your Nginx configuration:

```nginx
server {
    listen 80;
    server_name example.com;

    # Enable ModSecurity
    modsecurity on;
    modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
}
```

For detailed ModSecurity configuration and OWASP CRS integration, please refer to:

- [ModSecurity Official Documentation](https://github.com/SpiderLabs/ModSecurity/wiki)
- [OWASP CRS Project](https://coreruleset.org/)

## Version Management

This project uses the `update.sh` script to manage builds for different versions.

### Update to New Version

```bash
# Basic usage
./update.sh <NGINX_VERSION> <MODSECURITY_VERSION> <MODSECURITY_NGINX_VERSION>

# Example
./update.sh 1.29.4 v3.0.14 v1.0.4

# Auto commit and push (optional)
./update.sh 1.29.4 v3.0.14 v1.0.4 true
```

### Script Functions

After running the script:

1. Creates versioned directory: `nginx-<version>/mod-<version>/`
2. Generates Dockerfile and README for that version
3. Updates `Dockerfile.latest` in root directory
4. Updates `versions.env` version information file

### View Current Version

```bash
cat versions.env
```

## Custom Build

### Build Specific Version

```bash
cd nginx-1.29.4/mod-3.0.14
docker build -t my-nginx-modsec:1.29.4-3.0.14 .
```

### Build Latest Version

```bash
docker build -t my-nginx-modsec:latest -f Dockerfile.latest .
```

### Multi-Architecture Build

```bash
# Create builder
docker buildx create --name multiarch --use

# Build and push
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t my-registry/nginx-modsecurity:latest \
  -f Dockerfile.latest \
  --push .
```

## Development Guide

### Environment Setup

```bash
git clone https://github.com/AptS-1547/nginx-modsecurity.git
cd nginx-modsecurity
docker build -t nginx-modsecurity:dev -f Dockerfile.latest .
```

### Add New Version

```bash
./update.sh 1.29.0 v3.0.14 v1.0.4
cd nginx-1.29.0/mod-3.0.14
docker build -t test:1.29.0-3.0.14 .
```

### Testing

```bash
# Test image build
docker build -t test:latest -f Dockerfile.latest .

# Test run
docker run -d --name test-waf -p 8080:80 test:latest
curl http://localhost:8080/
docker rm -f test-waf
```

### CI/CD Workflow

This project uses GitHub Actions for automated building and publishing:

- **Trigger Conditions**: Push to master branch or create Tag
- **Build Targets**: Docker Hub and GitHub Container Registry
- **Build Matrix (Future)**: Multi-architecture builds (AMD64, ARM64)

### Contributing Code

1. Fork this repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add some amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Submit a Pull Request

## Contributing

Contributions are welcome in the following ways:

- 🐛 Report Bugs: Submit in [Issues](https://github.com/AptS-1547/nginx-modsecurity/issues)
- 💡 Feature Suggestions: Discuss in [Issues](https://github.com/AptS-1547/nginx-modsecurity/issues)
- 📖 Improve Documentation: Submit Pull Request
- 🔧 Code Contributions: Submit Pull Request

## License

This project is licensed under the [MIT License](LICENSE).

---

## Related Resources

- [Nginx Official Documentation](https://nginx.org/en/docs/)
- [ModSecurity Official Documentation](https://github.com/SpiderLabs/ModSecurity)
- [OWASP CRS Project](https://coreruleset.org/)
- [Docker Official Documentation](https://docs.docker.com/)

## Feedback

For any questions or suggestions, please contact us via:

- GitHub Issues: <https://github.com/AptS-1547/nginx-modsecurity/issues>
- Email: <apts-1547@esaps.net>

If this project helps you, please give it a ⭐️ Star!
