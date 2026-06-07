# AGENTS.md (Project)

## 规则优先级
- 本文件高于仓库级规则，覆盖 `/Users/ertiao/.codex/AGENTS.md` 中通用指引中的冲突项。

## Git 与构建规则
- `git commit` 时使用本地 `.githooks/pre-commit`：
  - 代码/构建相关文件（`BeefSauceCalculator.xcodeproj/project.pbxproj`）与其他提交内容统一归一为 `com.ertiao`。
  - 本地调试/测试构建应使用 `com.calton`（`xcodebuild`/本地运行脚本中覆盖为 `com.calton.BeefSauceCalculator`）。
  - 文档文件（`README.md`）默认保持 `com.ertiao`。
  - `git push` 与本地开发流程不变。

## Git 忽略策略
- `.gitignore` 至少包含：
  - `DerivedData/`、`build/`、`.build/`、`.swiftpm/`
  - `*.ipa`、`*.xcarchive`、`*.dSYM`、`*.dSYM.zip`
  - `*.mobileprovision`、`*.provisionprofile`、`*.p12`、`*.cer`、`*.pem`、`*.key`
  - `.env`、`.env.*`
  - `*.xcuserstate`、`xcuserdata/`、`*.xcodeproj/xcuserdata/`、`*.xcworkspace/xcuserdata/`
  - `*.xcodeproj/xcshareddata/`

## 约束
- 不追踪敏感签名文件与构建产物；不在 `README` 频繁回写 Bundle ID 示例。
