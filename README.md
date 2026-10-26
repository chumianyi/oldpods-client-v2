# 老豆荚 OldPods 客户端

## 本次完整源码交付：1.2.0+3

包含完整 Flutter 源码、Android 原生下载实现、字体及许可证、既有测试源文件和云端构建配置，不是补丁包。已修改签到榜时间/天数分离、蓝奏主解析与备用入口、取消启动更新弹窗，并完善排行榜、下载区域和共用按钮状态。账号、收藏、评论、消息、签到、积分商店等既有功能保留。

**本轮仅源码交付，没有运行测试、分析或编译，也没有上传仓库。** 下方构建章节是接收方后续操作说明，不代表本次已构建。签名私钥和 Token 不包含在 ZIP 中；若自行云端构建需配置自己的签名 Secrets。备用解析使用指定 HTTP 服务，只用于公开分享链接；服务在线可用性和真实网盘下载尚未运行验证。详见 CHANGELOG.md。

基于 Flutter 的「老豆荚」（oldpods.cn）第三方 Android 客户端，采用 **暖白 / 墨绿卡片设计与霞鹜文楷细体**，最低支持 **Android 7.0（API 24）**，通过 GitHub Actions 自动构建可安装的签名 Release APK。

## 下载安装

在私有仓库 Actions 的成功运行中下载 `oldpods-release-apk` 构件，内含签名 APK 和 SHA256 校验文件。

安装时需允许“安装未知来源应用”。本仓库使用固定签名 Secret；旧版密钥未包含在原始源码中，旧 APK 可能无法直接覆盖安装，详见 CHANGELOG.md。

## 功能特性

- **首页与浏览**：轮播 Banner、公告、分类导航、热门应用、发现与搜索入口
- **应用列表**：多维度排序（最新 / 最热 / 评分 / 下载）、分类筛选、下拉刷新、上拉分页加载
- **应用详情**：截图查看器、评分、收藏、内部网页下载检测与确认弹窗、评论（分组渲染、发评论、删评论）
- **搜索**：应用搜索 + 用户搜索、搜索历史记录
- **账号体系**：登录 / 注册 / 找回密码、邮箱验证码、个人中心、资料编辑、头像上传
- **消息中心**：私信会话（实时轮询）、发消息、屏蔽/取消屏蔽、删除会话、系统消息
- **社区互动**：评论回复列表（@我的）、删除回复
- **积分商店**：商品列表、购买、我的背包、头像框更换
- **任务与排行**：每日签到、贡献排行榜、我的投稿
- **设置**：主题切换（跟随系统 / 浅色 / 深色）、设备过滤、检查更新、清除缓存、退出登录、注销账号
- **下载管理**：后台队列、进度、网络等待、取消、来源网页重试、安装、持久记录、筛选

## 技术栈

| 项目 | 说明 |
| --- | --- |
| 框架 | Flutter 3.24.5 / Dart 3 |
| 主题 | 浅色暖白 / 深色墨绿、翡翠强调、轻阴影、全局 LXGW WenKai Light |
| 网络 | `http` 包 + 自建 ApiClient（Cookie 会话管理、统一错误处理、防御式 JSON 解析） |
| 状态 | 自写 AppState 单例 + AnimatedBuilder（零第三方状态管理依赖） |
| 存储 | `shared_preferences`（登录态、主题、搜索历史、下载记录） |
| 平台能力 | Kotlin MethodChannel 实现设备信息、APK 安装、浏览器打开、图片选择，无需额外插件 |
| 下载 | 内置 WebView 检测与确认 + Android 系统 DownloadManager 后台队列 |

## 构建

推送代码到 `main` 分支或手动触发 Workflow 即可自动构建：

1. 配置自己的仓库 Secrets：`SIGNING_KEY`（JKS Base64，alias 为 `oldpods`）、`KEYSTORE_PASSWORD`。源码包不含这些秘密。
2. 云端安装 Flutter 3.24.5 与 Java 17。
3. 云端获取依赖，执行 Dart 分析、单元与 Widget 测试。
4. 云端构建并验签 Release APK，检查字体与许可证资源。
5. 上传 APK 与 SHA256（保留 30 天）。
6. 云端 Android 模拟器执行 WebView 检测、取消、确认与系统下载完成测试，上传测试报告。

本次交付没有本地编译。字体采用官方 v1.530 Light 原文件，OFL 许可证位于 `assets/fonts/OFL.txt`。

## 项目结构

```
lib/
├── main.dart                  # 入口
├── app.dart                   # MaterialApp 与路由表
├── models/models.dart         # 全部数据模型（防御式解析）
├── services/                  # API 客户端、接口封装、存储、下载、平台通道、下载请求校验
├── state/app_state.dart       # 全局状态
├── theme/neu_theme.dart       # 全局调色板、字体与主题
├── widgets/                   # NeuBox / NeuButton / NeuTextField 等新拟态组件
└── screens/                   # 27 个功能页面
android/
└── app/src/main/kotlin/       # MainActivity、DownloadBrowserActivity、NativeDownloads
```

## 声明

本项目为个人学习作品，基于老豆荚开放接口制作，与老豆荚官方无关。所有数据版权归原站点所有。
