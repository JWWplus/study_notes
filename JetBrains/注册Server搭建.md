---
title: JetBrains 注册服务器搭建
tags: 
notebook: 服务器
---

[Server下载地址](https://mega.nz/#!Hs4CEbRR!FteOJmJ0AfuLvTUFs3dn9xH6eESm3io2BZ5neIXTQds)
解压密码：3415E428

``` sh
mv IntelliJIDEALicenseServer_linux_amd64 IdeaServer
/root/IdeaServer -p 12345 -prolongationPeriod 999999999999

命令有以下可选参数


-l 指定绑定监听到哪个IP(私人用)
-u 用户名参数，当未设置-u参数，且计算机用户名为^[a-zA-Z0-9]+$时，使用计算机用户名作为idea用户名
-p 参数，用于指定监听的端口
-prolongationPeriod 指定过期时间参数
-l 指定绑定监听到哪个IP(私人用)
-u 用户名参数，当未设置-u参数，且计算机用户名为^[a-zA-Z0-9]+$时，使用计算机用户名作为idea用户名
-p 参数，用于指定监听的端口
-prolongationPeriod 指定过期时间参数
```

将程序挂在tmux或者supervisior下都可以

配置nginx反向代理
``` conf
    server {
    listen       80;
    server_name  你的服务器名称;
    root         /usr/share/nginx/html;
    index index.php index.html index.htm;

    location /JetBrainsServer/ {
        proxy_pass http://127.0.0.1:12345/;
    }
}

```
**坑:**
1. nginx [反向代理参考](https://www.zybuluo.com/phper/note/90310)

2. 配置转发一定要带/ [带/和不带/区别](http://www.cnblogs.com/gabrielchen/p/5066120.html)