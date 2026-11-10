# 图标 / 图形素材来源与许可

本工程使用的外观图形（AppIcon 与 App 内徽标）**复刻自 tiann/KernelSU 上游图标的原版几何**，
不是自创图形。为满足 GPL-3.0 的署名与同源许可要求，特此声明。

## 上游来源

仓库：<https://github.com/tiann/KernelSU>
许可：GNU General Public License v3.0

具体取用的文件：

| 上游文件 | 用途 |
| --- | --- |
| `manager/app/src/main/res/drawable/ic_launcher_foreground.xml` | 图形几何（描边方框 + 两个错位填充方块） |
| `manager/app/src/main/res/drawable/ic_logo_vector.xml` | 同一图形的另一种排布，用于交叉核对坐标 |
| `manager/app/src/main/res/values/colors.xml` | 配色 `#FFFFFFFF` / `#FF1E110D` |

上游 XML 原文（关键部分）：

```xml
<vector viewportWidth="108" viewportHeight="108">
  <group android:scaleX="0.135" android:scaleY="0.135">
    <path android:pathData="M 259 259 H 541 V 541 H 259 Z" android:strokeWidth="18" />
    <path android:fillColor="@color/ic_launcher_foreground"
          android:pathData="M 257 257 H 407 V 407 H 257 V 257 Z" />
    <path android:fillColor="@color/ic_launcher_foreground"
          android:pathData="M 393 393 H 543 V 543 H 393 V 393 Z" />
  </group>
</vector>
```

```xml
<color name="ic_launcher_background">#FFFFFFFF</color>
<color name="ic_launcher_foreground">#FF1E110D</color>
```

## 归一化换算

原始坐标乘以 group scale `0.135` 后除以 viewport `108`，得到 0–1 空间：

| 元素 | 原始 pathData | 归一化 |
| --- | --- | --- |
| 描边方框 | 259 → 541 | 0.32375 → 0.67625 |
| 描边线宽 | 18 | 0.0225 |
| 方块 A（左上） | 257 → 407 | 0.32125 → 0.50875 |
| 方块 B（右下） | 393 → 543 | 0.49125 → 0.67875 |
| 视觉包围盒（含描边半宽） | — | 0.3125 → 0.6875，宽 0.375 |

这套常量同时被两处使用，且有一致性校验脚本：

- `KernelSU/KsuLogo.swift` — App 内徽标（SwiftUI 按上述常量绘制）
- `tools/make_icon.py` — 生成 `AppIcon.appiconset/icon-1024.png`
- `tools/verify_logo.py` — 校验 Swift 常量与上游换算值逐项相等

`python tools/verify_logo.py` 输出全部 `OK` 才说明两边没有跑偏。

## 与上游的差异

1. **背景**：iOS 图标不支持自适应图标分层，因此白色 `#FFFFFFFF` 作为不透明底直接烘焙进 PNG。
2. **尺寸**：iOS 要求 1024×1024 且无圆角，圆角由系统裁切；图形按 `UPSCALE = 1.70`
   相对原始映射放大，使视觉占比接近 iOS 惯例（约 61% 画面宽度）。
3. **动效**：上游 `ic_logo_vector.xml` 里的 `trimPathEnd` 动画未实现，iOS 侧为静态图形。

## 许可义务

上游图形为 GPL-3.0 素材。本工程整体以 MIT 发布（见 `README.md`），**但图标与徽标图形部分
不适用 MIT，仍随上游按 GPL-3.0 授权**。若要商用或闭源分发，需自行替换为可商用图形，
或遵守 GPL-3.0 的开源义务。
