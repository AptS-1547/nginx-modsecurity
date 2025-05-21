#!/bin/bash

# 设置版本
NGINX_VERSION=${1:-"1.26.3"}
MODSECURITY_VERSION=${2:-"v3.0.14"}
MODSECURITY_NGINX_VERSION=${3:-"v1.0.3"}

# 移除版本号中的 'v' 前缀，便于文件夹命名
MOD_VERSION=${MODSECURITY_VERSION#v}

# 创建版本化目录
VERSION_DIR="nginx-${NGINX_VERSION}/mod-${MOD_VERSION}"
mkdir -p "$VERSION_DIR"

# 当前日期
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 显示版本信息
echo "更新到以下版本:"
echo "Nginx: $NGINX_VERSION"
echo "ModSecurity: $MODSECURITY_VERSION"
echo "ModSecurity-nginx: $MODSECURITY_NGINX_VERSION"
echo "导出目录: $VERSION_DIR"
echo

# 生成版本化目录的 Dockerfile
cat Dockerfile.template | \
  sed "s/{{NGINX_VERSION}}/$NGINX_VERSION/g" | \
  sed "s/{{MODSECURITY_VERSION}}/$MODSECURITY_VERSION/g" | \
  sed "s/{{MODSECURITY_NGINX_VERSION}}/$MODSECURITY_NGINX_VERSION/g" | \
  sed "s/{{BUILD_DATE}}/$BUILD_DATE/g" > "$VERSION_DIR/Dockerfile"

# 同时生成根目录的 Dockerfile.latest 文件
cat Dockerfile.template | \
  sed "s/{{NGINX_VERSION}}/$NGINX_VERSION/g" | \
  sed "s/{{MODSECURITY_VERSION}}/$MODSECURITY_VERSION/g" | \
  sed "s/{{MODSECURITY_NGINX_VERSION}}/$MODSECURITY_NGINX_VERSION/g" | \
  sed "s/{{BUILD_DATE}}/$BUILD_DATE/g" > "Dockerfile.latest"

# 创建版本信息文件，记录当前使用的版本
cat > "versions.env" << EOF
NGINX_VERSION=$NGINX_VERSION
MODSECURITY_VERSION=$MODSECURITY_VERSION
MODSECURITY_NGINX_VERSION=$MODSECURITY_NGINX_VERSION
BUILD_DATE=$BUILD_DATE
EOF

# 复制其他必要文件到版本化目录
cp nginx.conf "$VERSION_DIR/"

# 创建一个README文件，记录版本信息
cat > "$VERSION_DIR/README.md" << EOF
# ModSecurity with Nginx

版本信息:
- Nginx: $NGINX_VERSION
- ModSecurity: $MODSECURITY_VERSION
- ModSecurity-nginx: $MODSECURITY_NGINX_VERSION

创建日期: $BUILD_DATE

## 构建镜像

\`\`\`bash
docker build -t modsecurity:$NGINX_VERSION-$MOD_VERSION .
\`\`\`

## 运行容器

\`\`\`bash
docker run -d -p 80:80 modsecurity:$NGINX_VERSION-$MOD_VERSION
\`\`\`
EOF

echo "更新完成！文件已导出到 $VERSION_DIR 目录"
echo "同时已生成 Dockerfile.latest 和 versions.env 文件在根目录"
echo "您可以运行以下命令构建镜像:"
echo "cd $VERSION_DIR && docker build -t modsecurity:$NGINX_VERSION-$MOD_VERSION ."