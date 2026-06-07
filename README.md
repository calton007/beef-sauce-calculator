# 卤牛肉计算器 iOS App

这是一个 SwiftUI iOS App，不需要联网。当前仓库目标是准备 TestFlight 内测版本，不包含 App Store 正式公开发布所需的完整商品页材料。

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
6. 当前 Bundle Identifier 是 `com.ertiao.BeefSauceCalculator`。如果仍然冲突，把它改成一个更独特的值，例如：
   `com.ertiao.BeefSauceCalculator.private`
7. 点击运行按钮。

## 私用安装说明

免费 Apple ID 通常可以直接装到自己的 iPhone，但可能需要隔一段时间重新用 Xcode 运行一次。付费 Apple Developer Program 会更稳定。

## TestFlight 内测准备

1. 确认 Apple Developer Team 可用，并已在 Xcode 登录。
2. 打开 `BeefSauceCalculator.xcodeproj`。
3. 在 target 的 `Signing & Capabilities` 里确认 `Team` 和 Bundle Identifier `com.ertiao.BeefSauceCalculator` 可用于 App Store Connect。
4. 运行测试：
   ```bash
   xcodebuild test -project BeefSauceCalculator.xcodeproj -scheme BeefSauceCalculator -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
   ```
5. 运行无签名构建检查：
   ```bash
   xcodebuild -project BeefSauceCalculator.xcodeproj -scheme BeefSauceCalculator -configuration Debug -sdk iphoneos CODE_SIGNING_ALLOWED=NO build
   ```
6. 在 Xcode 里选择 `Any iOS Device`，执行 `Product > Archive`。
7. 在 Organizer 中上传 Archive 到 App Store Connect，并在 TestFlight 中分发给内测用户。

当前版本保留现有图标；正式公开发布前建议重新检查图标、截图、隐私信息、支持 URL、年龄分级和 App Store 文案。
