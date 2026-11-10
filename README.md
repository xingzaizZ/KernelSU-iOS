# KernelSU · iOS 外观外壳

一个 iOS 端的 KernelSU 界面复刻工程：**只做界面，不做真实提权，也不含模块加载器**。
打开即显示 `uid=0(root)` 已授权状态，用于展示 / 装逼；无法刷入、安装或启用任何模块。

> 上游参考：[tiann/KernelSU](https://github.com/tiann/KernelSU)（Android，GPL-3.0）。
> 本仓库为独立的 SwiftUI 实现，不含上游任何**代码**；**图标图形按上游原版几何复刻**，
> 该图形部分仍属 GPL-3.0，详见 [ASSETS-NOTICE.md](ASSETS-NOTICE.md)。

---

## 一、它做了什么

| 页面 | 内容 |
| --- | --- |
| 首页 | 原版徽标、`已获取 Root 权限 / WORKING` 状态卡、`uid=0` / SELinux / 设备 / 系统版本、KernelPatch + SuSFS 徽章、四个指标格、内核信息表 |
| 超级用户 | 应用授权列表（可点按切换开关）、su 调用日志、可疑提权拦截记录，带搜索 |
| 模块 | 六个模块卡片、启用开关、`从本地安装模块` 入口（点击明确提示不可用）、空仓库占位 |
| 终端 | 内置命令解释器：`id / whoami / su / uname / hostname / ls / cat / mount / ps / ksu / clear / help`，全部本地字符串模拟，不启动进程、不读文件 |
| 设置 | 挂载模式（OverlayFS / Magic Mount / 未挂载）、安全模式、详细日志、路径表、版本信息、重置授权 |

技术栈：SwiftUI + XcodeGen + GitHub Actions，目标 iOS 16.0，仅 iPhone 竖屏，深色主题。

## 二、它没做什么

- 没有 kernel patch、没有 `kexec`、没有 `su` 二进制、没有 setuid，**不存在任何真实提权路径**。
- 没有 magiskd 等价物、没有 OverlayFS 挂载后端，**模块开关只改本地布尔值**。
- 终端所有输出是硬编码字符串，`ls` 不列真实目录，`ps` 不查真实进程。
- 没有网络请求、没有后台常驻、没有私有 API 调用。

## 三、目录结构

```
KernelSU-iOS/
├── project.yml                     # XcodeGen 工程定义
├── KernelSU/
│   ├── App.swift                   # @main 入口 + BootOverlay 引导
│   ├── BootOverlay.swift           # 启动伪内核日志动画
│   ├── RootView.swift              # 五标签容器 + 自定义 TabBar
│   ├── HomeView.swift              # 首页
│   ├── SuperUserView.swift         # 超级用户
│   ├── ModulesView.swift           # 模块
│   ├── TerminalView.swift          # 终端 + ShellSimulator
│   ├── SettingsView.swift          # 设置
│   ├── KsuLogo.swift               # 原版图标图形（按上游 pathData 复刻）
│   ├── Theme.swift                 # 配色 / 卡片 / 通用组件
│   ├── Models.swift                # 状态与演示数据
│   ├── Info.plist
│   └── Resources/Assets.xcassets   # AppIcon + 启动背景色
├── tools/make_icon.py              # 图标生成脚本（Pillow）
├── tools/verify_logo.py            # 校验图形常量与上游一致
├── tools/_upstream/                 # 上游原始 XML（换算依据）
├── ASSETS-NOTICE.md                # 图形来源与 GPL-3.0 说明
├── tools/check_swift.py            # 括号/字符串平衡自检
├── tools/push_to_github.ps1        # 无 git 环境下的上传脚本
└── .github/workflows/build-ipa.yml # CI：构建未签名 ipa
```

## 四、本地构建（macOS）

```bash
brew install xcodegen
cd KernelSU-iOS
xcodegen generate
xcodebuild -project KernelSU-iOS.xcodeproj \
           -scheme KernelSU \
           -configuration Release \
           -sdk iphoneos \
           -destination 'generic/platform=iOS' \
           CODE_SIGNING_ALLOWED=NO \
           CODE_SIGNING_REQUIRED=NO \
           build
```

产物在 `build/Build/Products/Release-iphoneos/KernelSU.app`，手动打成 ipa：

```bash
mkdir -p Payload && cp -R KernelSU.app Payload/
zip -qr KernelSU-unsigned.ipa Payload
```

## 五、GitHub Actions 打包 ipa

推送到 `main` 或手动触发 `Build unsigned IPA`：

1. GitHub 仓库 → **Actions** → 左侧 `Build unsigned IPA` → **Run workflow**
2. 跑完在 **Artifacts** 下载 `KernelSU-ios-ipa`，里面是 `KernelSU-ios-1.0.0-1024-unsigned.ipa`

打 tag 会自动建 Release 并挂上 ipa：

```bash
git tag v1.0.0 && git push origin v1.0.0
```

工作流要点：
- `runs-on: macos-14`，Xcode 15/16 自带
- `brew install xcodegen` → `xcodegen generate`
- `CODE_SIGNING_ALLOWED=NO` 产出纯未签名 `.app`
- 打包前删除 `_CodeSignature` 与 `embedded.mobileprovision`，并有一道 `Verify IPA is unsigned` 校验
- 产物 artifact 保留 30 天

## 六、未签名 ipa 怎么装到手机上

| 方式 | 说明 |
| --- | --- |
| TrollStore | 直接安装 ipa，需设备支持（iOS 14.0–16.6.1 等特定版本） |
| AltStore / Sidekick | 用 Apple ID 自签，7 天有效，需重签 |
| Sideloadly | 同上，可配 7 天自动重签 |
| 自有开发者证书 | `codesign -f -s "iPhone Developer: xxx" --entitlements ent.plist` 后重打包 |
| Xcode 直装 | 打开 `KernelSU-iOS.xcodeproj`，填自己的 Team，真机 Run |

自签示例（需要一个 `entitlements.plist`）：

```bash
unzip KernelSU-ios-1.0.0-1024-unsigned.ipa -d out
codesign -f -s "Apple Development: you@example.com (TEAMID)" \
         --entitlements ent.plist \
         out/Payload/KernelSU.app
cd out && zip -qr ../KernelSU-signed.ipa Payload
```

## 七、想改哪里

- 换配色：`KernelSU/Theme.swift` 顶部的 `Color(hex:)` 常量
- 换演示数据：`KernelSU/Models.swift` 里的 `SampleData`
- 换图标：跑 `python tools/make_icon.py`（改了 `KsuLogo.swift` 常量后记得跑 `verify_logo.py` 校验）
- 换 Bundle ID：`project.yml` 的 `PRODUCT_BUNDLE_IDENTIFIER` 与 workflow 的 `BUNDLE_ID`
- 加页面：`RootView.Tab` 加一个 case + `icon`，再在 `RootView` 的 ZStack 里挂上视图

## 八、许可

MIT，**但图标与徽标图形除外** —— 该图形复刻自 tiann/KernelSU 上游图标的原版几何，
随上游按 GPL-3.0 授权，详见 [ASSETS-NOTICE.md](ASSETS-NOTICE.md)。

## 九、图标

AppIcon 与原版图形一致：白色底 `#FFFFFF`，深棕黑图形 `#1E110D`，
内容为「描边方框 + 左上/右下两个错位填充方块」。

两处共用同一套归一化常量：

| 文件 | 作用 |
| --- | --- |
| `KernelSU/KsuLogo.swift` | App 内徽标（SwiftUI 绘制） |
| `tools/make_icon.py` | 生成 1024×1024 AppIcon PNG |
| `tools/verify_logo.py` | 校验 Swift 常量与上游换算值逐项相等 |

重出图标：

```bash
python tools/make_icon.py     # 重绘 icon-1024.png
python tools/verify_logo.py   # 校验常量没跑偏，应全部 OK
```

上游原始素材留在 `tools/_upstream/`（4 个 XML，仅作换算依据，不参与编译）。
