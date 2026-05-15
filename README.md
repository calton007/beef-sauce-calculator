# 卤牛肉计算器 iOS App

这是一个私用 SwiftUI iOS App，不需要联网，不需要发布到 App Store。

## 功能

- 输入牛肉重量和目标 NaCl/食盐百分比。
- 三种酱料输入包装上的 `Na mg / 对应重量 g`。
- 甜面酱和豆瓣酱手动拖动。
- 酱油自动补足剩余 NaCl。
- `Na -> NaCl` 使用固定系数 `2.542`。
- 点击“保存配置”后，只保存三种酱料的 Na 配置。

## 用 Xcode 跑到 iPhone

1. 打开 `BeefSauceCalculator.xcodeproj`。
2. 用数据线连接 iPhone，并在 iPhone 上信任这台 Mac。
3. Xcode 顶部设备选择你的 iPhone。
4. 点左侧项目 `BeefSauceCalculator`，进入 target 的 `Signing & Capabilities`。
5. 在 `Team` 里选择你的 Apple ID/Personal Team。
6. 如果 Bundle Identifier 冲突，把它改成一个更独特的值，例如：
   `com.ertiao.BeefSauceCalculator.private`
7. 点击运行按钮。

## 私用安装说明

免费 Apple ID 通常可以直接装到自己的 iPhone，但可能需要隔一段时间重新用 Xcode 运行一次。付费 Apple Developer Program 会更稳定。
