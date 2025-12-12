# ModSecurity with Nginx

版本信息:
- Nginx: 1.29.4
- ModSecurity: v3.0.14
- ModSecurity-nginx: v1.0.4

创建日期: 2025-12-12T03:35:33Z

## 构建镜像

```bash
docker build -t modsecurity:1.29.4-3.0.14 .
```

## 运行容器

```bash
docker run -d -p 80:80 modsecurity:1.29.4-3.0.14
```
