FROM nginx:1.26.3-alpine AS builder

# 设置 ModSecurity 版本
ENV MODSECURITY_VERSION=v3.0.14
ENV MODSECURITY_NGINX_VERSION=v1.0.3

# 安装构建依赖
RUN apk add --no-cache --virtual .build-deps \
        alpine-sdk \
        autoconf \
        automake \
        bison \
        curl \
        doxygen \
        flex \
        g++ \
        gcc \
        git \
        libtool \
        lmdb-dev \
        lua5.4-dev \
        make \
        pcre-dev \
        ssdeep \
        yajl-dev \
        zlib-dev \
        libxml2-dev \
        geoip-dev \
        pcre2-dev \
        linux-headers \
        wget

# 创建工作目录
WORKDIR /opt

# 下载 Nginx 源码
RUN wget https://nginx.org/download/nginx-1.26.3.tar.gz \
    && tar -xzf nginx-1.26.3.tar.gz \
    && rm nginx-1.26.3.tar.gz

# 下载 ModSecurity
RUN git clone --depth 1 -b ${MODSECURITY_VERSION} https://github.com/owasp-modsecurity/ModSecurity.git

# 下载 ModSecurity-nginx 连接器
RUN git clone --depth 1 -b ${MODSECURITY_NGINX_VERSION} https://github.com/owasp-modsecurity/ModSecurity-nginx.git

# 编译 ModSecurity
RUN cd /opt/ModSecurity \
    && git submodule init \
    && git submodule update \
    && ./build.sh \
    && ./configure --prefix=/usr/local/modsecurity \
    && make \
    && make install \
    && make clean

# 编译 Nginx 与 ModSecurity 模块
RUN cd /opt/nginx-1.26.3 \
    && ./configure --with-compat --add-dynamic-module=/opt/ModSecurity-nginx \
    && make modules \
    && cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules \
    && mkdir -p /etc/nginx/modsec \
    && cp /opt/ModSecurity/unicode.mapping /etc/nginx/modsec/

# 最终镜像
FROM nginx:1.26.3-alpine

# 安装运行时依赖
RUN apk add --no-cache --purge --virtual .runtime-deps \
        lua5.4 \
        yajl \
        libstdc++ \
        pcre \
        libxml2

# 复制配置文件和模块
RUN sed -i '1i load_module modules/ngx_http_modsecurity_module.so;\n' /etc/nginx/nginx.conf
COPY --from=builder /usr/local/modsecurity/ /usr/local/modsecurity/
COPY --from=builder /etc/nginx/modules/ngx_http_modsecurity_module.so /etc/nginx/modules/
COPY --from=builder /etc/nginx/modsec/unicode.mapping /etc/nginx/modsec/

# 添加构建信息标签
LABEL maintainer="AptS-1547 <apts-1547@esaps.net>" \
      nginx_version="1.26.3" \
      modsecurity_version="v3.0.14" \
      modsecurity_nginx_version="v1.0.3" \
      build_date="2025-05-21T04:03:54Z"