# ModSecurity with Nginx

版本信息:
- Nginx: 1.24.0
- ModSecurity: v3.0.14
- ModSecurity-nginx: v1.0.3

创建日期: 2025-05-21T07:57:23Z

## 构建镜像

```bash
docker build -t modsecurity:1.24.0-3.0.14 .
```

## 运行容器

```bash
docker run -d -p 80:80 modsecurity:1.24.0-3.0.14
```
