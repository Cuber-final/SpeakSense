# Flutter Web 外网资源依赖记录

最后更新: 2026-02-05
目的: 记录当前 Flutter Web 运行时依赖的外网资源，便于后续替换为国内可访问方案。

---

## 当前已识别外网资源（来自启动日志）

1) CanvasKit 运行时
- 域名: `www.gstatic.com`
- 示例:
  - `https://www.gstatic.com/flutter-canvaskit/<engine-hash>/chromium/canvaskit.js`
- 作用:
  - Flutter Web 的 CanvasKit 渲染引擎文件。

2) 默认字体（Roboto）
- 域名: `fonts.gstatic.com`
- 示例:
  - `https://fonts.gstatic.com/s/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2`
- 作用:
  - Flutter Web 默认字体下载资源。

---

## 当前可用规避方案（已验证）

开发启动时禁用外网 CDN：

```bash
flutter run -d chrome --no-web-resources-cdn
```

或：

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8787 --no-web-resources-cdn
```

构建时同样禁用：

```bash
flutter build web --no-web-resources-cdn
```

---

## 字体替换执行结果（已完成）

- [x] 已将字体改为本地打包，不再依赖运行时字体 CDN
  - `frontend/assets/fonts/inter/Inter-Variable.ttf`
  - `frontend/assets/fonts/inter/Inter-Italic-Variable.ttf`
  - `frontend/assets/fonts/noto_sans_sc/NotoSansSC-Variable.ttf`
- [x] 已在 `frontend/pubspec.yaml` 注册字体并纳入 assets
- [x] 已在 `frontend/lib/theme/app_theme.dart` 设置：
  - `fontFamily: Inter`
  - `fontFamilyFallback: [NotoSansSC]`

说明：
- 字体版权文件（OFL）已随字体放入 assets 目录。
- 这一步解决了 `fonts.gstatic.com` 字体请求依赖；`www.gstatic.com` 的 CanvasKit 仍建议配合 `--no-web-resources-cdn` 或后续自托管方案。

---

## 后续替代路线（待执行）

- [ ] 将 CanvasKit 相关资源改为“项目自托管”（静态资源服务/对象存储+CDN），避免直接依赖 `www.gstatic.com`
- [x] 将默认字体替换为本地打包字体（Noto Sans SC / Inter），避免运行时请求 `fonts.gstatic.com`
- [ ] 在 CI 中新增 Web 启动烟测（含 `--no-web-resources-cdn`），确保离线/受限网络可启动
- [ ] 补充部署文档：受限网络环境下的 Web 启动与构建命令
