#!/bin/bash
set -euo pipefail

# 用法: ./update.sh <NGINX_VERSION> <MODSECURITY_VERSION> <MODSECURITY_NGINX_VERSION> [ROLE]
# 示例: ./update.sh 1.29.7 v3.0.14 v1.0.4 mainline

NGINX_VERSION="${1:?用法: ./update.sh <NGINX_VERSION> <MODSECURITY_VERSION> <MODSECURITY_NGINX_VERSION> [ROLE]}"
MODSECURITY_VERSION="${2:?缺少 MODSECURITY_VERSION 参数}"
MODSECURITY_NGINX_VERSION="${3:?缺少 MODSECURITY_NGINX_VERSION 参数}"
ROLE="${4:-mainline}"

MOD_VERSION="${MODSECURITY_VERSION#v}"
VERSION_DIR="nginx-${NGINX_VERSION}/mod-${MOD_VERSION}"
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "=== 创建新版本 ==="
echo "Nginx:              ${NGINX_VERSION}"
echo "ModSecurity:        ${MODSECURITY_VERSION}"
echo "ModSecurity-nginx:  ${MODSECURITY_NGINX_VERSION}"
echo "角色:               ${ROLE}"
echo "目录:               ${VERSION_DIR}"
echo

# 查找最近的同 modsecurity 版本目录作为模板
TEMPLATE_DIR=$(ls -d nginx-*/mod-"${MOD_VERSION}" 2>/dev/null | sort -t- -k2 -V | tail -1 || true)

if [ -z "${TEMPLATE_DIR}" ]; then
    echo "错误: 找不到 mod-${MOD_VERSION} 的已有版本目录作为模板"
    echo "请手动创建 ${VERSION_DIR}/Dockerfile"
    exit 1
fi

echo "使用模板: ${TEMPLATE_DIR}/Dockerfile"

# 从模板目录提取旧的 nginx 版本号
OLD_NGINX=$(basename "$(dirname "${TEMPLATE_DIR}")" | sed 's/^nginx-//')

# 创建新目录并复制 Dockerfile，替换版本号
mkdir -p "${VERSION_DIR}"
sed \
    -e "s/${OLD_NGINX}/${NGINX_VERSION}/g" \
    -e "s/MODSECURITY_NGINX_VERSION=.*/MODSECURITY_NGINX_VERSION=${MODSECURITY_NGINX_VERSION}/" \
    -e "s/build_date=\"[^\"]*\"/build_date=\"${BUILD_DATE}\"/" \
    "${TEMPLATE_DIR}/Dockerfile" > "${VERSION_DIR}/Dockerfile"

echo "已生成: ${VERSION_DIR}/Dockerfile"

# 更新 build-matrix.json
if ! command -v jq &> /dev/null; then
    echo "警告: 未安装 jq，请手动更新 build-matrix.json"
else
    DOCKERFILE="${VERSION_DIR}/Dockerfile"

    # 替换同角色的旧条目，或追加新条目
    NEW_ENTRY=$(jq -n \
        --arg nginx "${NGINX_VERSION}" \
        --arg modsec "${MODSECURITY_VERSION}" \
        --arg modsec_nginx "${MODSECURITY_NGINX_VERSION}" \
        --arg role "${ROLE}" \
        --arg dockerfile "${DOCKERFILE}" \
        '{nginx: $nginx, modsecurity: $modsec, modsecurity_nginx: $modsec_nginx, role: $role, dockerfile: $dockerfile}')

    # 检查是否有同角色的条目
    HAS_ROLE=$(jq --arg role "${ROLE}" '[.builds[] | select(.role == $role)] | length' build-matrix.json)

    if [ "${HAS_ROLE}" -gt 0 ]; then
        # 替换同角色的条目
        jq --argjson entry "${NEW_ENTRY}" --arg role "${ROLE}" \
            '.builds = [.builds[] | if .role == $role then $entry else . end]' \
            build-matrix.json > build-matrix.json.tmp
    else
        # 追加新条目
        jq --argjson entry "${NEW_ENTRY}" \
            '.builds += [$entry]' \
            build-matrix.json > build-matrix.json.tmp
    fi

    mv build-matrix.json.tmp build-matrix.json
    echo "已更新: build-matrix.json"
fi

echo
echo "=== 完成 ==="
echo "请检查 ${VERSION_DIR}/Dockerfile 是否需要调整构建步骤"
echo "确认无误后 commit 并 push 即可触发 CI 构建"
