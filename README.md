# Nginx with ModSecurity

English | [简体中文](README.zh-CN.md)

![Docker Image CI](https://github.com/AptS-1547/nginx-modsecurity/workflows/Docker%20Image%20CI/badge.svg)
[![Docker Hub](https://img.shields.io/docker/pulls/e1saps/nginx-modsecurity.svg)](https://hub.docker.com/r/e1saps/nginx-modsecurity)
[![GitHub Container Registry](https://img.shields.io/badge/GitHub%20Container-Registry-blue)](https://github.com/AptS-1547/nginx-modsecurity/pkgs/container/nginx-modsecurity)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Production-oriented Docker images for running Nginx with the ModSecurity v3 WAF engine. The image builds ModSecurity and the `modsecurity-nginx` connector from source, compiles the Nginx connector as a dynamic module, and publishes multi-architecture images for `linux/amd64` and `linux/arm64`.

This repository is intentionally small: each supported version pair lives in its own `nginx-<version>/mod-<version>/Dockerfile`, while `build-matrix.json` controls which images are currently published by CI.

## What Is Included

- Nginx based on the official `nginx:<version>-alpine` image
- ModSecurity v3 built from the OWASP ModSecurity source tree
- `modsecurity-nginx` compiled as an Nginx dynamic module
- Runtime libraries required by ModSecurity, including Lua 5.4, LMDB, YAJL, PCRE2, GeoIP, libxml2, and curl
- Module loader file at `/etc/nginx/modules-available/50-modsecurity.conf`
- Enabled module symlink under `/etc/nginx/modules-enabled/`
- ModSecurity `unicode.mapping` copied to `/etc/nginx/modsec/`

The image provides the WAF engine and Nginx module. It does not bundle a default OWASP Core Rule Set configuration, so production deployments should mount their own ModSecurity configuration and rules.

## Current Published Matrix

The current CI build matrix is defined in [`build-matrix.json`](build-matrix.json):

| Channel | Nginx | ModSecurity | modsecurity-nginx | Dockerfile |
| --- | --- | --- | --- | --- |
| `mainline` / `latest` | `1.31.0` | `v3.0.15` | `v1.0.4` | `nginx-1.31.0/mod-3.0.15/Dockerfile` |
| `stable` | `1.30.1` | `v3.0.15` | `v1.0.4` | `nginx-1.30.1/mod-3.0.15/Dockerfile` |

Older version directories remain in the repository as historical build definitions, but only entries listed in `build-matrix.json` are built and published by the current GitHub Actions workflow.

## Image Registries

Images are published to both Docker Hub and GitHub Container Registry:

```bash
docker pull e1saps/nginx-modsecurity:latest
docker pull ghcr.io/apts-1547/nginx-modsecurity:latest
```

Use Docker Hub if you do not have a registry preference. Use GHCR when your deployment workflow already authenticates against GitHub Packages.

## Tags

Each matrix entry is published with a version tag and a plain Nginx version tag:

| Tag | Example | Meaning |
| --- | --- | --- |
| `<nginx-version>-<modsecurity-version>` | `1.31.0-3.0.15` | Exact Nginx and ModSecurity pair |
| `<nginx-version>` | `1.31.0` | Alias for the Nginx version's current ModSecurity pair |
| `latest` | `latest` | Current `mainline` build |
| `mainline` | `mainline` | Current Nginx mainline build |
| `stable` | `stable` | Current Nginx stable build |

For production, prefer the full version tag, for example:

```bash
docker pull e1saps/nginx-modsecurity:1.30.1-3.0.15
```

That avoids accidental upgrades when `latest`, `mainline`, or `stable` move.

## Quick Start

Run the latest mainline image:

```bash
docker run --rm -p 8080:80 e1saps/nginx-modsecurity:latest
```

Then check the default Nginx page:

```bash
curl http://localhost:8080/
```

This confirms that Nginx starts. To actually inspect traffic with ModSecurity, add a ModSecurity configuration and enable it in your Nginx server or location block.

## Enabling The Module

The image places the module loader at:

```text
/etc/nginx/modules-enabled/50-modsecurity.conf
```

If you replace `/etc/nginx/nginx.conf`, make sure your custom file includes enabled modules before the `events` block:

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

If you only mount files under `/etc/nginx/conf.d/`, the default Nginx image entrypoint keeps the base `nginx.conf`, so the loader behavior depends on that base configuration. When in doubt, provide a complete `nginx.conf` with the `include /etc/nginx/modules-enabled/*.conf;` line.

## Example With Custom Rules

Create a minimal ModSecurity configuration:

```apache
# ./modsec/modsecurity.conf
SecRuleEngine On
SecRequestBodyAccess On
SecResponseBodyAccess Off
SecAuditEngine RelevantOnly
SecAuditLog /var/log/nginx/modsec_audit.log

SecRule ARGS:test "@contains attack" "id:1000,phase:2,deny,status:403,msg:'Test ModSecurity rule'"
```

Create an Nginx config that loads the module and uses that rules file:

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

Run the container:

```bash
docker run --rm \
  -p 8080:80 \
  -v "$PWD/nginx.conf:/etc/nginx/nginx.conf:ro" \
  -v "$PWD/modsec:/etc/nginx/modsec:ro" \
  e1saps/nginx-modsecurity:stable
```

Test the rule:

```bash
curl "http://localhost:8080/?test=ok"
curl -i "http://localhost:8080/?test=attack"
```

The second request should return `403` when the rule is active.

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

## Build Locally

Build a specific version from its Dockerfile:

```bash
docker build \
  -t nginx-modsecurity:1.31.0-3.0.15 \
  -f nginx-1.31.0/mod-3.0.15/Dockerfile \
  .
```

Run it:

```bash
docker run --rm -p 8080:80 nginx-modsecurity:1.31.0-3.0.15
```

For multi-architecture publishing, use Buildx:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t your-registry/nginx-modsecurity:1.31.0-3.0.15 \
  -f nginx-1.31.0/mod-3.0.15/Dockerfile \
  --push \
  .
```

## Adding Or Updating A Version

Use [`update.sh`](update.sh) to create a new version directory from the nearest existing template with the same ModSecurity version:

```bash
./update.sh <NGINX_VERSION> <MODSECURITY_VERSION> <MODSECURITY_NGINX_VERSION> [ROLE]
```

Example:

```bash
./update.sh 1.31.1 v3.0.15 v1.0.4 mainline
```

The script:

1. Creates `nginx-<nginx-version>/mod-<modsecurity-version>/Dockerfile`
2. Replaces the Nginx and connector versions in the copied Dockerfile
3. Updates the `build_date` label
4. Replaces or appends the matching `role` entry in `build-matrix.json`

Valid roles are currently interpreted by CI as:

| Role | Published channel tags |
| --- | --- |
| `mainline` | `latest`, `mainline` |
| `stable` | `stable` |

After running the script, review the generated Dockerfile before committing. Different Nginx or ModSecurity versions sometimes require small build fixes.

## CI Publishing Flow

The GitHub Actions workflow at [`.github/workflows/docker-image.yml`](.github/workflows/docker-image.yml) runs on pushes to `master` that modify `build-matrix.json` or versioned Dockerfiles. It can also be started manually with `workflow_dispatch`.

For each matrix entry, CI:

1. Builds `linux/amd64` and `linux/arm64` images on native runners
2. Pushes temporary architecture-specific images
3. Creates a multi-architecture manifest for Docker Hub and GHCR
4. Publishes version tags and channel tags based on the matrix role
5. Skips an existing full version tag unless the manual `force_rebuild` input is enabled

## Project Layout

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

Older `nginx-*` directories follow the same layout.

## Security Notes

- Keep production deployments on exact version tags.
- Mount your own ModSecurity rules and audit-log policy.
- Test rule changes in detection-only mode before switching to blocking mode.
- Treat WAF logs as sensitive data because they may contain request bodies, tokens, or user input.
- Rebuild when upstream Nginx, Alpine, or ModSecurity security updates matter to your deployment.

## Related Projects

- [Nginx](https://nginx.org/)
- [ModSecurity](https://github.com/owasp-modsecurity/ModSecurity)
- [ModSecurity-nginx](https://github.com/owasp-modsecurity/ModSecurity-nginx)
- [OWASP Core Rule Set](https://coreruleset.org/)

## License

This project is licensed under the [MIT License](LICENSE).
