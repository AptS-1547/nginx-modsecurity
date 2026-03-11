# ModSecurity with Nginx

版本信息:
- Nginx: 1.29.6
- ModSecurity: v3.0.14
- ModSecurity-nginx: v1.0.4

创建日期: 2026-03-11T03:39:35Z

## 构建镜像

```bash
docker build -t modsecurity:1.29.6-3.0.14 .
```

## 运行容器

```bash
docker run -d -p 80:80 modsecurity:1.29.6-3.0.14
```
