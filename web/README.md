# 迷你塔防下载页

把下面两个文件放到服务器同一目录即可：

1. `index.html`（本目录里的网页）
2. `MiniTD.apk`（游戏安装包，和网页同级）

## 示例（Nginx）

```nginx
server {
    listen 80;
    server_name your.domain.com;
    root /var/www/minitd;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    # APK 强制下载
    location ~* \.apk$ {
        add_header Content-Type application/vnd.android.package-archive;
        add_header Content-Disposition 'attachment; filename="迷你塔防.apk"';
    }
}
```

上传后访问：`http://你的域名/` 或 `http://IP/`

若 APK 文件名不是 `MiniTD.apk`，改 `index.html` 里 `href` 即可。
