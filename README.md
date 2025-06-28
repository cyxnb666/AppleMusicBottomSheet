# Apple Music Bottom Sheet

一个模仿 Apple Music 风格的底部弹出式播放器界面的 iOS 应用，使用 SwiftUI 构建。

## 功能特性

- 🎵 Apple Music 风格的底部播放器界面
- 📱 可展开的全屏播放器视图
- 🎨 流畅的动画过渡效果
- 📑 标签栏导航（Listen Now、Browse、Radio、Music、Search）
- 🎭 匹配几何动画效果
- 🌗 支持深色/浅色主题

## 界面预览

应用包含以下主要界面：
- **Home**: 主界面，包含标签栏和底部播放器
- **ExpandedBottomSheet**: 展开的全屏播放器界面
- **MusicInfo**: 音乐信息组件

## 技术实现

### 核心技术
- **SwiftUI**: 用户界面框架
- **Namespace**: 几何匹配动画
- **TabView**: 标签栏导航
- **GeometryReader**: 手势处理和布局

### 动画效果
- 底部播放器展开/收起动画
- 标签栏隐藏/显示动画
- 匹配几何效果 (matchedGeometryEffect)
- 自定义拖拽手势

## 项目结构

```
AppleMusicBottomSheet/
├── AppleMusicBottomSheetApp.swift    # 应用入口
├── ContentView.swift                 # 根视图
├── View/
│   ├── Home.swift                   # 主界面
│   ├── ExpandedBottomSheet.swift    # 展开的播放器
│   ├── MusicInfo.swift              # 音乐信息组件
│   └── Helpers/
│       ├── DragGesture+Extensions.swift  # 拖拽手势扩展
│       └── View+Extensions.swift         # 视图扩展
└── Assets.xcassets/                 # 资源文件
    ├── Cards/                       # 卡片图片
    ├── Colors/                      # 颜色资源
    └── Others/                      # 其他资源
```

## 环境要求

- iOS 16.0+
- Xcode 14.0+
- Swift 5.7+

## 安装运行

1. 克隆或下载项目
2. 使用 Xcode 打开 `AppleMusicBottomSheet.xcodeproj`
3. 选择目标设备或模拟器
4. 点击运行按钮 (⌘+R)

## 主要组件说明

### Home.swift
- 主界面视图，包含标签栏和底部播放器
- 管理展开状态和标签栏隐藏逻辑
- 实现自定义底部弹出式播放器

### ExpandedBottomSheet.swift
- 全屏播放器界面
- 包含音乐控制按钮和播放进度
- 支持拖拽手势关闭

### MusicInfo.swift
- 音乐信息显示组件
- 包含专辑封面、歌曲名和艺术家信息
- 支持展开播放器的交互

## 自定义扩展

项目包含多个有用的 SwiftUI 扩展：
- `setTabItem`: 设置标签栏项目
- `setTabBarBackground`: 设置标签栏背景
- `hideTabBar`: 控制标签栏显示/隐藏

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目。

## 许可证

本项目仅供学习和参考使用。